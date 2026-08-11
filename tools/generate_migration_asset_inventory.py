#!/usr/bin/env python3
"""Build the deterministic Mac-Win migration asset inventory."""

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath, PureWindowsPath
import re
import subprocess
import sys
import unicodedata


ROOT = Path(__file__).resolve().parents[1]
POLICY_PATH = ROOT / "migration" / "assets" / "metadata-policy.json"

SCHEMA_VERSION = 1
REPOSITORY = "a1112/Mac-Win"
SOURCE_COMMIT = "db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527"
SOURCE_TAG = "mw-migration-baseline-db12d5e"
MAX_DOCUMENT_BYTES = 64 * 1024
MAX_JSON_DEPTH = 128
MAX_JSON_INTEGER_DIGITS = 128
MAX_ASSET_BYTES = 1024 * 1024
MAX_GIT_CONFIG_LIST_BYTES = 64 * 1024

GOVERNED_TREE_PATHS = (
    "MacWinManager/Sources/MacWinManagerApp/Resources/Catalog",
    "patches",
    "scripts",
    "MacWinManager/Tools/build-native-ui-probe.sh",
    "MacWinManager/Tools/native-ui-probe.c",
    "MacWinManager/Tools/native-ui-probe.manifest",
    "MacWinManager/Tools/native-ui-probe.rc",
    "MacWinManager/Sources/MacWinCore/BottleService.swift",
    "MacWinManager/Sources/MacWinCore/JSONStore.swift",
    "MacWinManager/Sources/MacWinCore/MacWinPaths.swift",
    "MacWinManager/Sources/MacWinCore/Models.swift",
)
_OID_PATTERN = re.compile(rb"(?:[0-9a-f]{40}|[0-9a-f]{64})\Z")

CATEGORIES = frozenset(
    ("catalog", "patches", "probes", "fixtures", "bottle-schema")
)
KINDS = frozenset(
    ("catalog-record", "source-patch", "probe", "test-fixture", "bottle-schema")
)
CATEGORY_KINDS = {
    "catalog": "catalog-record",
    "patches": "source-patch",
    "probes": "probe",
    "fixtures": "test-fixture",
    "bottle-schema": "bottle-schema",
}
CATEGORY_OWNERS = {
    "catalog": frozenset(("compatforge/catalog",)),
    "patches": frozenset(
        ("compatforge/patches", "quarantine/unresolved")
    ),
    "probes": frozenset(("compatforge/probes", "macwin/archive")),
    "fixtures": frozenset(("compatforge/probes",)),
    "bottle-schema": frozenset(("compatforge/bottle-schema",)),
}
LICENSE_STATUSES = frozenset(("unresolved",))
PROVENANCE_STATUSES = frozenset(("unresolved",))
INTENDED_OWNERS = frozenset(
    owner for owners in CATEGORY_OWNERS.values() for owner in owners
)

ROOT_FIELDS = frozenset(
    (
        "schemaVersion",
        "repository",
        "sourceCommit",
        "sourceTag",
        "groups",
        "dependencyPolicy",
    )
)
GROUP_FIELDS = frozenset(
    (
        "category",
        "kind",
        "license",
        "provenance",
        "intendedOwner",
        "externalRefs",
        "developmentDependencies",
        "paths",
    )
)
DEPENDENCY_POLICY_FIELDS = frozenset(
    ("externalRefs", "developmentDependencies")
)
DEPENDENCY_GROUP_FIELDS = frozenset(
    ("sourcePath", "kind", "status", "locators")
)
EXTERNAL_DEPENDENCY_CONTRACT = {"url": "external-unverified"}
DEVELOPMENT_DEPENDENCY_CONTRACT = {
    "absolute-path": "development-machine-only",
    "environment-path": "unexpanded",
    "repository-path": "not-in-baseline",
}

_URL_LOCATOR_PATTERN = re.compile(r"https?://[^\x00-\x20\"'<>`{}|]+")
_ABSOLUTE_PATH_LOCATOR_PATTERN = re.compile(r"/Users/a1-6/[^\r\n\"'}]+")
_HOME_PATH_LOCATOR_PATTERN = re.compile(r"\$HOME/[^\r\n\"'}]+")
_REPOSITORY_PATH_LOCATOR_PATTERN = re.compile(
    r"(?:\$(?:PROJECT_ROOT|ROOT_DIR|ROOT)/refs/[^\x00-\x20\"'<>`\\]+"
    r"|(?<![/A-Za-z0-9_$.-])refs/[^\x00-\x20\"'<>`\\]+)"
)
_ENVIRONMENT_PATH_LOCATORS = frozenset(
    (
        "MACWIN_APP_PATH",
        "MACWIN_DXVK_MACOS_DIR",
        "MACWIN_JASP_CONAN_BIN",
        "MACWIN_JASP_CONAN_HOME",
        "MACWIN_JASP_CONAN_VENV",
        "MACWIN_JASP_DESKTOP_EXE_OVERRIDE",
        "MACWIN_JASP_LIBARCHIVE_PREFIX",
        "MACWIN_JASP_PATCHED_BUILD_DIR",
        "MACWIN_JASP_PATCHED_CONFIGURE_LOG",
        "MACWIN_JASP_PATCHED_SOURCE_DIR",
        "MACWIN_JASP_RENV_PACKAGE",
        "MACWIN_JASP_RENV_PACKAGE_URL",
        "MACWIN_JASP_WINDOWS_QT_PREFIX",
        "MACWIN_JASP_WINDOWS_R_HOME",
        "MACWIN_LENOVO_APPSTORE_SOURCE_DIR",
        "MACWIN_ONLYOFFICE_ALLFONTS_SOURCE",
        "MACWIN_PDFINFO_BIN",
        "MACWIN_PGADMIN_RESOURCES",
        "MACWIN_POWETOYS_EVENT_PROBE",
        "MACWIN_POWETOYS_EXE",
        "MACWIN_POWETOYS_PREFIX",
        "MACWIN_POWETOYS_WINDOW_PROBE",
        "MACWIN_QET_FIXTURE_PATH",
        "MACWIN_ROOT",
        "MACWIN_ROSETTA_X87_BUILD",
        "MACWIN_ROSETTA_X87_PATH",
        "MACWIN_ROSETTA_X87_SOURCE",
        "MACWIN_SMOKE_PREFIX",
        "MACWIN_VISUAL_ANALYSIS_JSON",
        "MACWIN_VISUAL_OUTPUT_DIR",
        "MACWIN_VISUAL_PROBE",
        "MACWIN_VISUAL_SCREENSHOT",
        "MACWIN_VISUAL_RESULT_JSON",
        "MACWIN_WINE_BUILD_DIR",
        "MACWIN_WINE_LOADER",
        "MACWIN_WINE_MONO_MSI",
    )
)
_ENVIRONMENT_PATH_PATTERN = re.compile(
    r"(?<![A-Z0-9_])(?:"
    + "|".join(sorted(_ENVIRONMENT_PATH_LOCATORS))
    + r")(?![A-Z0-9_])"
)


class InventoryError(ValueError):
    """A stable, non-reflective inventory validation failure."""


def validate_json_depth(text, maximum=MAX_JSON_DEPTH):
    """Reject excessive JSON container nesting before object allocation."""
    depth = 0
    in_string = False
    escaped = False
    for character in text:
        if in_string:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            continue

        if character == '"':
            in_string = True
        elif character in "[{":
            depth += 1
            if depth > maximum:
                raise InventoryError(
                    "inventory document nesting exceeds the limit"
                )
        elif character in "]}":
            depth -= 1


def _reject_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise InventoryError("inventory document contains duplicate object keys")
        result[key] = value
    return result


def _reject_non_json_constant(_value):
    raise InventoryError("inventory document is not valid JSON")


def _parse_bounded_integer(value):
    digits = value[1:] if value.startswith("-") else value
    if len(digits) > MAX_JSON_INTEGER_DIGITS:
        raise InventoryError("inventory document integer is invalid")
    try:
        return int(value)
    except ValueError as error:
        raise InventoryError("inventory document integer is invalid") from error


def _parse_json_document(raw):
    if type(raw) is not bytes:
        raise InventoryError("inventory document value type is invalid")
    if len(raw) > MAX_DOCUMENT_BYTES:
        raise InventoryError("inventory document exceeds the byte limit")
    try:
        text = raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise InventoryError("inventory document is not valid UTF-8") from error

    validate_json_depth(text, MAX_JSON_DEPTH)
    try:
        return json.loads(
            text,
            object_pairs_hook=_reject_duplicate_keys,
            parse_constant=_reject_non_json_constant,
            parse_int=_parse_bounded_integer,
        )
    except InventoryError:
        raise
    except (json.JSONDecodeError, RecursionError, ValueError) as error:
        raise InventoryError("inventory document is not valid JSON") from error


def _require_object(value):
    if type(value) is not dict:
        raise InventoryError("inventory policy value type is invalid")
    return value


def _require_list(value):
    if type(value) is not list:
        raise InventoryError("inventory policy value type is invalid")
    return value


def _require_string(value, invalid_message="inventory policy string is invalid"):
    if type(value) is not str:
        raise InventoryError("inventory policy value type is invalid")
    if any(
        unicodedata.category(character) in ("Cc", "Cf", "Cs")
        for character in value
    ):
        raise InventoryError(invalid_message)
    return value


def _require_exact_fields(value, expected):
    obj = _require_object(value)
    if frozenset(obj) != expected:
        raise InventoryError("inventory policy schema is invalid")
    return obj


def _validate_tagged_status(value, statuses):
    obj = _require_exact_fields(value, frozenset(("status",)))
    status = _require_string(obj["status"])
    if status not in statuses:
        raise InventoryError("inventory policy enum value is invalid")


def _validate_path(value):
    path = _require_string(value, "inventory policy path is invalid")
    try:
        path.encode("ascii", errors="strict")
    except UnicodeEncodeError as error:
        raise InventoryError("inventory policy path is invalid") from error

    posix = PurePosixPath(path)
    windows = PureWindowsPath(path)
    if (
        not path
        or "\0" in path
        or "\\" in path
        or ":" in path
        or path.startswith("/")
        or "//" in path
        or posix.is_absolute()
        or windows.is_absolute()
        or bool(windows.drive)
        or bool(windows.root)
        or not posix.parts
        or any(part in ("", ".", "..") for part in path.split("/"))
        or str(posix) != path
    ):
        raise InventoryError("inventory policy path is invalid")
    return path


def _validate_string_list(value):
    entries = _require_list(value)
    seen = set()
    for entry in entries:
        text = _require_string(
            entry, "inventory policy dependency reference is invalid"
        )
        if not text:
            raise InventoryError("inventory policy dependency reference is invalid")
        if text in seen:
            raise InventoryError("inventory policy dependency reference is duplicated")
        seen.add(text)


def _dependency_sort_key(value):
    return value.encode("utf-8")


def _validate_dependency_locator(locator, kind):
    text = _require_string(locator, "inventory policy dependency is invalid")
    if not text or any(
        character in text for character in ('"', "'", "<", ">", "`", "\n", "\r")
    ):
        raise InventoryError("inventory policy dependency is invalid")
    if kind == "url":
        if _URL_LOCATOR_PATTERN.fullmatch(text) is None:
            raise InventoryError("inventory policy dependency is invalid")
    elif kind == "absolute-path":
        if _ABSOLUTE_PATH_LOCATOR_PATTERN.fullmatch(text) is None:
            raise InventoryError("inventory policy dependency is invalid")
    elif kind == "environment-path":
        if not (
            _HOME_PATH_LOCATOR_PATTERN.fullmatch(text)
            or text in _ENVIRONMENT_PATH_LOCATORS
        ):
            raise InventoryError("inventory policy dependency is invalid")
    elif kind == "repository-path":
        if _REPOSITORY_PATH_LOCATOR_PATTERN.fullmatch(text) is None:
            raise InventoryError("inventory policy dependency is invalid")
    return text


def _validate_dependency_groups(entries, contract, governed_paths):
    previous_group_key = None
    for entry in _require_list(entries):
        dependency = _require_exact_fields(entry, DEPENDENCY_GROUP_FIELDS)
        source_path = _validate_path(dependency["sourcePath"])
        kind = _require_string(dependency["kind"])
        status = _require_string(dependency["status"])
        if source_path not in governed_paths:
            raise InventoryError("inventory policy dependency is invalid")
        if kind not in contract or status != contract.get(kind):
            raise InventoryError("inventory policy enum value is invalid")

        group_key = (source_path.encode("ascii"), kind.encode("ascii"))
        if previous_group_key is not None and group_key <= previous_group_key:
            if group_key == previous_group_key:
                raise InventoryError("inventory policy dependency is duplicated")
            raise InventoryError("inventory policy dependency is invalid")
        previous_group_key = group_key

        locators = _require_list(dependency["locators"])
        if not locators:
            raise InventoryError("inventory policy dependency is invalid")
        previous_locator = None
        folded_locators = set()
        for raw_locator in locators:
            locator = _validate_dependency_locator(raw_locator, kind)
            locator_key = _dependency_sort_key(locator)
            if previous_locator is not None and locator_key <= previous_locator:
                if locator_key == previous_locator:
                    raise InventoryError("inventory policy dependency is duplicated")
                raise InventoryError("inventory policy dependency is invalid")
            previous_locator = locator_key
            folded = locator.casefold()
            if folded in folded_locators:
                raise InventoryError(
                    "inventory policy dependency has a case-fold collision"
                )
            folded_locators.add(folded)


def validate_policy(policy):
    """Validate the closed v1 manual metadata policy in place."""
    root = _require_exact_fields(policy, ROOT_FIELDS)

    if type(root["schemaVersion"]) is not int:
        raise InventoryError("inventory policy value type is invalid")
    for field in ("repository", "sourceCommit", "sourceTag"):
        _require_string(root[field])
    if (
        root["schemaVersion"] != SCHEMA_VERSION
        or root["repository"] != REPOSITORY
        or root["sourceCommit"] != SOURCE_COMMIT
        or root["sourceTag"] != SOURCE_TAG
    ):
        raise InventoryError("inventory policy identity is invalid")

    groups = _require_list(root["groups"])
    if not groups:
        raise InventoryError("inventory policy schema is invalid")

    governed_paths = set()
    folded_paths = {}
    for raw_group in groups:
        group = _require_exact_fields(raw_group, GROUP_FIELDS)
        category = _require_string(group["category"])
        kind = _require_string(group["kind"])
        owner = _require_string(group["intendedOwner"])
        if (
            category not in CATEGORIES
            or kind not in KINDS
            or owner not in INTENDED_OWNERS
            or CATEGORY_KINDS.get(category) != kind
            or owner not in CATEGORY_OWNERS.get(category, ())
        ):
            raise InventoryError("inventory policy enum value is invalid")

        _validate_tagged_status(group["license"], LICENSE_STATUSES)
        _validate_tagged_status(group["provenance"], PROVENANCE_STATUSES)
        _validate_string_list(group["externalRefs"])
        _validate_string_list(group["developmentDependencies"])

        paths = _require_list(group["paths"])
        if not paths:
            raise InventoryError("inventory policy schema is invalid")
        for raw_path in paths:
            path = _validate_path(raw_path)
            if path in governed_paths:
                raise InventoryError("inventory policy path is duplicated")
            folded = path.casefold()
            if folded in folded_paths:
                raise InventoryError(
                    "inventory policy path has a case-fold collision"
                )
            governed_paths.add(path)
            folded_paths[folded] = path

    dependency_policy = _require_exact_fields(
        root["dependencyPolicy"], DEPENDENCY_POLICY_FIELDS
    )
    _validate_dependency_groups(
        dependency_policy["externalRefs"],
        EXTERNAL_DEPENDENCY_CONTRACT,
        governed_paths,
    )
    _validate_dependency_groups(
        dependency_policy["developmentDependencies"],
        DEVELOPMENT_DEPENDENCY_CONTRACT,
        governed_paths,
    )
    return policy


def parse_policy_bytes(raw):
    """Parse and validate one bounded strict-UTF-8 policy document."""
    return validate_policy(_parse_json_document(raw))


def _dependency_policy_evidence(policy):
    """Expand the bounded source-grouped policy to canonical evidence rows."""
    result = {"externalRefs": [], "developmentDependencies": []}
    for field in result:
        for group in policy["dependencyPolicy"][field]:
            for locator in group["locators"]:
                result[field].append(
                    {
                        "sourcePath": group["sourcePath"],
                        "locator": locator,
                        "kind": group["kind"],
                        "status": group["status"],
                    }
                )
    return result


def _evidence_record(source_path, locator, kind, status):
    return {
        "sourcePath": source_path,
        "locator": locator,
        "kind": kind,
        "status": status,
    }


def _evidence_record_sort_key(record):
    return (
        record["sourcePath"].encode("ascii"),
        record["kind"].encode("ascii"),
        record["status"].encode("ascii"),
        record["locator"].encode("utf-8"),
    )


def _extract_blob_dependency_evidence(source_path, raw):
    """Extract closed literal evidence from one bounded frozen text blob."""
    if type(raw) is not bytes or len(raw) > MAX_ASSET_BYTES:
        raise InventoryError("inventory dependency source is invalid")
    try:
        text = raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise InventoryError("inventory dependency source is invalid") from error

    external = {
        locator: _evidence_record(
            source_path, locator, "url", "external-unverified"
        )
        for locator in _URL_LOCATOR_PATTERN.findall(text)
    }
    development = {}

    def add_development(locator, kind, status):
        identity = (kind, locator)
        development[identity] = _evidence_record(
            source_path, locator, kind, status
        )

    for locator in _ABSOLUTE_PATH_LOCATOR_PATTERN.findall(text):
        add_development(locator, "absolute-path", "development-machine-only")
    for locator in _HOME_PATH_LOCATOR_PATTERN.findall(text):
        add_development(locator, "environment-path", "unexpanded")
    for locator in _ENVIRONMENT_PATH_PATTERN.findall(text):
        add_development(locator, "environment-path", "unexpanded")
    for locator in _REPOSITORY_PATH_LOCATOR_PATTERN.findall(text):
        if locator.endswith("}") and "${" not in locator:
            locator = locator[:-1]
        add_development(locator, "repository-path", "not-in-baseline")

    return {
        "externalRefs": sorted(external.values(), key=_evidence_record_sort_key),
        "developmentDependencies": sorted(
            development.values(), key=_evidence_record_sort_key
        ),
    }


def _extract_dependency_evidence(repository_root, records):
    """Read only the already-bound raw blobs and combine their evidence."""
    result = {"externalRefs": [], "developmentDependencies": []}
    for record in records:
        evidence = _extract_blob_dependency_evidence(
            record["sourcePath"],
            _read_blob(repository_root, record["gitBlobOid"]),
        )
        for field in result:
            result[field].extend(evidence[field])
    for field in result:
        result[field].sort(key=_evidence_record_sort_key)
    return result


def _require_dependency_policy_match(policy, evidence):
    """Fail closed unless extracted evidence equals the reviewed policy."""
    expected = _dependency_policy_evidence(policy)
    for field in expected:
        expected[field].sort(key=_evidence_record_sort_key)
    if evidence != expected:
        raise InventoryError(
            "inventory dependency evidence does not match policy"
        )


def load_policy(path=POLICY_PATH):
    """Read and validate a bounded policy file."""
    try:
        with Path(path).open("rb") as stream:
            raw = stream.read(MAX_DOCUMENT_BYTES + 1)
    except OSError as error:
        raise InventoryError("inventory policy could not be read") from error
    return parse_policy_bytes(raw)


def _git_environment(source=None):
    """Copy the process environment while removing Git repository overrides."""
    environment = dict(os.environ if source is None else source)
    for key in tuple(environment):
        if key.upper().startswith("GIT_"):
            del environment[key]
    environment.update(
        {
            "GIT_NO_LAZY_FETCH": "1",
            "GIT_NO_REPLACE_OBJECTS": "1",
            "GIT_TERMINAL_PROMPT": "0",
        }
    )
    return environment


def _run_git(repository_root, *arguments, allowed_returncodes=(0,)):
    """Run one local Git plumbing command with a fixed repository boundary."""
    root = Path(repository_root).resolve()
    try:
        result = subprocess.run(
            ["git", "-c", f"safe.directory={root}", *arguments],
            cwd=root,
            stdin=subprocess.DEVNULL,
            capture_output=True,
            check=False,
            shell=False,
            env=_git_environment(),
        )
    except OSError as error:
        raise InventoryError("inventory Git command failed") from error
    if allowed_returncodes is not None and result.returncode not in allowed_returncodes:
        raise InventoryError("inventory Git command failed")
    return result


def _absolute_git_path(repository_root, *arguments):
    raw = _run_git(
        repository_root, "rev-parse", "--path-format=absolute", *arguments
    ).stdout
    if not raw or len(raw) > 4096 or b"\0" in raw:
        raise InventoryError("inventory Git object database is invalid")
    try:
        return Path(raw.rstrip(b"\r\n").decode("utf-8", errors="strict")).resolve()
    except (OSError, UnicodeError, ValueError) as error:
        raise InventoryError("inventory Git object database is invalid") from error


def _validate_primary_object_database(repository_root):
    """Reject alternates and partial-clone stores outside the primary object DB."""
    root = Path(repository_root).resolve()
    common_directory = _absolute_git_path(root, "--git-common-dir")
    object_directory = _absolute_git_path(root, "--git-path", "objects")
    try:
        if object_directory != (common_directory / "objects").resolve():
            raise InventoryError("inventory Git object database is not self-contained")
        for sentinel in (
            object_directory / "info" / "alternates",
            object_directory / "info" / "http-alternates",
        ):
            if sentinel.exists():
                raise InventoryError(
                    "inventory Git object database is not self-contained"
                )
        pack_directory = object_directory / "pack"
        if pack_directory.exists() and any(
            path.is_file() and path.suffix.casefold() == ".promisor"
            for path in pack_directory.iterdir()
        ):
            raise InventoryError("inventory Git object database is not self-contained")
    except OSError as error:
        raise InventoryError("inventory Git object database is invalid") from error

    _validate_promisor_configuration(root)


def _validate_promisor_configuration(repository_root):
    scopes = ["local"]
    if _worktree_config_enabled(repository_root):
        scopes.append("worktree")
    for scope in scopes:
        for key in _git_config_scope_keys(repository_root, scope):
            folded = key.casefold()
            if folded == "extensions.partialclone" or (
                folded.startswith("remote.") and folded.endswith(".promisor")
            ):
                raise InventoryError(
                    "inventory Git object database is not self-contained"
                )


def _worktree_config_enabled(repository_root):
    result = _run_git(
        repository_root,
        "config",
        "--local",
        "--type=bool",
        "--get",
        "extensions.worktreeConfig",
        allowed_returncodes=None,
    )
    if result.returncode == 1 and result.stdout == b"":
        return False
    if result.returncode != 0:
        raise InventoryError("inventory Git worktree config state is invalid")
    if result.stdout in (b"true", b"true\n", b"true\r\n"):
        return True
    if result.stdout in (b"false", b"false\n", b"false\r\n"):
        return False
    raise InventoryError("inventory Git worktree config state is invalid")


def _git_config_scope_keys(repository_root, scope):
    result = _run_git(
        repository_root,
        "config",
        f"--{scope}",
        "--name-only",
        "--list",
        allowed_returncodes=None,
    )
    if result.returncode != 0 or result.stderr:
        raise InventoryError("inventory Git config scope is invalid")
    if len(result.stdout) > MAX_GIT_CONFIG_LIST_BYTES or b"\0" in result.stdout:
        raise InventoryError("inventory Git config scope is invalid")
    try:
        keys = result.stdout.decode("utf-8", errors="strict").splitlines()
    except UnicodeDecodeError as error:
        raise InventoryError("inventory Git config scope is invalid") from error
    if any(not key or any(unicodedata.category(char) == "Cc" for char in key) for key in keys):
        raise InventoryError("inventory Git config scope is invalid")
    return tuple(keys)


def _tag_git_runner(repository_root, arguments):
    """Adapt the hardened inventory runner to the audited tag validator API."""
    return _run_git(
        repository_root, *arguments, allowed_returncodes=None
    )


def _validate_source_tag(repository_root, source_tag, source_commit):
    """Lazily reuse the audited baseline tag validator in package or script mode."""
    try:
        from tools.validate_migration_baseline import (
            BaselineValidationError,
            validate_baseline_tag,
        )
    except ModuleNotFoundError as error:
        if error.name != "tools":
            raise InventoryError("inventory source Git identity is invalid") from error
        try:
            from validate_migration_baseline import (
                BaselineValidationError,
                validate_baseline_tag,
            )
        except ModuleNotFoundError as fallback_error:
            raise InventoryError(
                "inventory source Git identity is invalid"
            ) from fallback_error
    try:
        validate_baseline_tag(
            repository_root,
            source_tag,
            source_commit,
            run_git=_tag_git_runner,
        )
    except BaselineValidationError as error:
        raise InventoryError("inventory source Git identity is invalid") from error


def _verify_source_identity(repository_root, source_commit, source_tag):
    """Require a local commit, a direct annotated tag, and HEAD ancestry."""
    try:
        commit_type = _run_git(
            repository_root, "cat-file", "-t", source_commit
        ).stdout.strip()
        if commit_type != b"commit":
            raise InventoryError("inventory source Git identity is invalid")
        _run_git(repository_root, "cat-file", "-e", f"{source_commit}^{{commit}}")

        _run_git(
            repository_root,
            "merge-base",
            "--is-ancestor",
            source_commit,
            "HEAD",
        )
        _validate_source_tag(repository_root, source_tag, source_commit)
    except (InventoryError, UnicodeError, ValueError) as error:
        raise InventoryError("inventory source Git identity is invalid") from error


def _list_governed_tree(repository_root, source_commit):
    """Resolve all governed tree entries once at the frozen commit."""
    try:
        raw = _run_git(
            repository_root,
            "ls-tree",
            "-rz",
            "--full-tree",
            source_commit,
            "--",
            *GOVERNED_TREE_PATHS,
        ).stdout
    except InventoryError as error:
        raise InventoryError("inventory governed Git tree is invalid") from error

    entries = []
    for raw_entry in raw.split(b"\0"):
        if not raw_entry:
            continue
        try:
            header, raw_path = raw_entry.split(b"\t", 1)
            mode, object_type, oid = header.split(b" ", 2)
            path = raw_path.decode("ascii", errors="strict")
            mode_text = mode.decode("ascii", errors="strict")
            type_text = object_type.decode("ascii", errors="strict")
            oid_text = oid.decode("ascii", errors="strict")
        except (ValueError, UnicodeError) as error:
            raise InventoryError("inventory governed Git tree is invalid") from error
        if not _OID_PATTERN.fullmatch(oid):
            raise InventoryError("inventory governed Git tree is invalid")
        entries.append((mode_text, type_text, oid_text, path))
    return entries


def _read_blob(repository_root, oid):
    """Read a bounded raw blob by immutable object ID and verify its length."""
    try:
        object_format = _run_git(
            repository_root, "rev-parse", "--show-object-format=storage"
        ).stdout.strip()
        format_contract = {b"sha1": (hashlib.sha1, 40), b"sha256": (hashlib.sha256, 64)}
        if object_format not in format_contract:
            raise InventoryError("inventory governed Git object is invalid")
        hash_constructor, oid_length = format_contract[object_format]
        if len(oid) != oid_length or re.fullmatch(r"[0-9a-f]+", oid) is None:
            raise InventoryError("inventory governed Git object is invalid")
        if _run_git(repository_root, "cat-file", "-t", oid).stdout.strip() != b"blob":
            raise InventoryError("inventory governed Git object is invalid")
        raw_size = _run_git(repository_root, "cat-file", "-s", oid).stdout.strip()
        if not raw_size or not raw_size.isdigit():
            raise InventoryError("inventory governed Git object is invalid")
        size = int(raw_size)
    except InventoryError as error:
        if str(error) == "inventory governed Git object is invalid":
            raise
        raise InventoryError("inventory governed Git object is invalid") from error
    if size > MAX_ASSET_BYTES:
        raise InventoryError("inventory governed Git object exceeds the byte limit")
    try:
        content = _run_git(repository_root, "cat-file", "blob", oid).stdout
    except InventoryError as error:
        raise InventoryError("inventory governed Git object is invalid") from error
    if len(content) != size:
        raise InventoryError("inventory governed Git object length is invalid")
    framed = b"blob " + str(size).encode("ascii") + b"\0" + content
    if hash_constructor(framed).hexdigest() != oid:
        raise InventoryError("inventory governed Git object identity is invalid")
    return content


def _policy_assets(policy):
    assets = {}
    for group in policy["groups"]:
        metadata = {
            "kind": group["kind"],
            "license": group["license"],
            "provenance": group["provenance"],
            "intendedOwner": group["intendedOwner"],
            "externalRefs": group["externalRefs"],
            "developmentDependencies": group["developmentDependencies"],
            "category": group["category"],
        }
        for path in group["paths"]:
            if path in assets:
                raise InventoryError("inventory governed path coverage is invalid")
            assets[path] = metadata
    return assets


def _bind_governed_assets(repository_root, policy, source_commit, source_tag):
    """Bind reviewed policy paths to raw objects from one immutable Git tree."""
    root = Path(repository_root).resolve()
    _validate_primary_object_database(root)
    _verify_source_identity(root, source_commit, source_tag)
    expected = _policy_assets(policy)
    entries = _list_governed_tree(root, source_commit)

    actual = {}
    folded = set()
    for mode, object_type, oid, path in entries:
        if mode not in ("100644", "100755"):
            raise InventoryError("inventory governed Git entry mode is invalid")
        if object_type != "blob":
            raise InventoryError("inventory governed Git object is invalid")
        if path in actual:
            raise InventoryError("inventory governed path coverage is invalid")
        casefolded = path.casefold()
        if casefolded in folded:
            raise InventoryError("inventory governed path coverage is invalid")
        folded.add(casefolded)
        actual[path] = (mode, oid)

    if set(actual) != set(expected):
        raise InventoryError("inventory governed path coverage is invalid")

    records = []
    for path in sorted(expected, key=lambda value: value.encode("ascii")):
        mode, oid = actual[path]
        content = _read_blob(root, oid)
        record = {
            "sourcePath": path,
            "sourceCommit": source_commit,
            "gitBlobOid": oid,
            "sha256": hashlib.sha256(content).hexdigest(),
            "byteSize": len(content),
            "gitMode": mode,
        }
        record.update(expected[path])
        records.append(record)
    return records


class _StableArgumentParser(argparse.ArgumentParser):
    """Keep CLI failures stable without reflecting untrusted arguments."""

    def error(self, _message):
        self.print_usage(sys.stderr)
        self.exit(2, f"{self.prog}: error: invalid command-line arguments\n")


def _argument_parser():
    parser = _StableArgumentParser(
        prog="generate_migration_asset_inventory.py",
        add_help=False,
        allow_abbrev=False,
    )
    parser.add_argument("--list", action="store_true")
    return parser


def main(arguments=()):
    options = _argument_parser().parse_args(arguments)
    try:
        policy = load_policy()
        if options.list:
            records = _bind_governed_assets(
                ROOT, policy, SOURCE_COMMIT, SOURCE_TAG
            )
            dependency_evidence = _extract_dependency_evidence(ROOT, records)
            _require_dependency_policy_match(policy, dependency_evidence)
            counts = {
                category: sum(
                    record["category"] == category for record in records
                )
                for category in sorted(CATEGORIES)
            }
            print(
                "Mac-Win migration assets: "
                + str(len(records))
                + " ("
                + ", ".join(
                    f"{category}={counts[category]}" for category in sorted(counts)
                )
                + ")"
            )
            for record in records:
                print(record["sourcePath"])
            return 0
    except InventoryError as error:
        print(f"migration asset inventory failed: {error}", file=sys.stderr)
        return 1
    print("Mac-Win migration asset metadata policy is valid.")
    return 0


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""Build the deterministic Mac-Win migration asset inventory."""

import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path, PurePosixPath, PureWindowsPath
import re
import secrets
import stat
import subprocess
import sys
import tempfile
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

OUTPUT_RELATIVE_PATHS = (
    "migration/assets/index.json",
    "migration/assets/bottle-schema.json",
    "migration/assets/catalog.json",
    "migration/assets/fixtures.json",
    "migration/assets/patches.json",
    "migration/assets/probes.json",
    "migration/assets/dependencies.json",
)
CATEGORY_OUTPUT_PATHS = {
    "bottle-schema": "migration/assets/bottle-schema.json",
    "catalog": "migration/assets/catalog.json",
    "fixtures": "migration/assets/fixtures.json",
    "patches": "migration/assets/patches.json",
    "probes": "migration/assets/probes.json",
}
ASSET_OUTPUT_FIELDS = (
    "sourcePath",
    "sourceCommit",
    "gitBlobOid",
    "sha256",
    "byteSize",
    "gitMode",
    "kind",
    "license",
    "provenance",
    "intendedOwner",
    "externalRefs",
    "developmentDependencies",
)

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


def _is_reparse(status):
    return bool(
        getattr(status, "st_file_attributes", 0)
        & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
    )


def _component_identity(status):
    return (
        getattr(status, "st_dev", None),
        getattr(status, "st_ino", None),
        stat.S_IFMT(status.st_mode),
        _is_reparse(status),
    )


def _leaf_identity(status):
    return (
        *_component_identity(status),
        getattr(status, "st_size", None),
        getattr(status, "st_mtime_ns", None),
    )


def _inspect_reviewed_file(repository_root, relative_path):
    root = Path(os.path.abspath(os.fspath(repository_root)))
    try:
        relative = _validate_path(relative_path)
    except InventoryError as error:
        raise InventoryError("inventory reviewed file is invalid") from error
    components = [root]
    current = root
    for part in relative.split("/"):
        current = current / part
        components.append(current)
    statuses = []
    for index, component in enumerate(components):
        try:
            status = component.lstat()
        except OSError as error:
            raise InventoryError("inventory reviewed file is invalid") from error
        is_leaf = index == len(components) - 1
        if stat.S_ISLNK(status.st_mode) or _is_reparse(status):
            raise InventoryError("inventory reviewed file is invalid")
        if is_leaf:
            if not stat.S_ISREG(status.st_mode):
                raise InventoryError("inventory reviewed file is invalid")
        elif not stat.S_ISDIR(status.st_mode):
            raise InventoryError("inventory reviewed file is invalid")
        statuses.append(status)
    return components[-1], statuses


def _read_bounded_reviewed_file(repository_root, relative_path, maximum_bytes):
    """Read a regular reviewed file without following linked path components."""
    if type(maximum_bytes) is not int or maximum_bytes < 0:
        raise InventoryError("inventory reviewed file is invalid")
    reviewed, initial = _inspect_reviewed_file(repository_root, relative_path)
    flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
    descriptor = None
    try:
        descriptor = os.open(reviewed, flags)
        with os.fdopen(descriptor, "rb") as stream:
            descriptor = None
            opened = os.fstat(stream.fileno())
            if (
                not stat.S_ISREG(opened.st_mode)
                or _is_reparse(opened)
                or _component_identity(opened) != _component_identity(initial[-1])
            ):
                raise InventoryError("inventory reviewed file is invalid")
            raw = stream.read(maximum_bytes + 1)
            opened_after = os.fstat(stream.fileno())
        _, final = _inspect_reviewed_file(repository_root, relative_path)
    except InventoryError:
        raise
    except OSError as error:
        raise InventoryError("inventory reviewed file is invalid") from error
    finally:
        if descriptor is not None:
            os.close(descriptor)
    if (
        len(raw) > maximum_bytes
        or len(initial) != len(final)
        or any(
            _component_identity(before) != _component_identity(after)
            for before, after in zip(initial, final)
        )
        or _leaf_identity(initial[-1]) != _leaf_identity(opened_after)
        or _leaf_identity(initial[-1]) != _leaf_identity(final[-1])
    ):
        raise InventoryError("inventory reviewed file is invalid")
    return raw


def load_policy(path=POLICY_PATH, repository_root=None):
    """Read and validate a bounded policy file."""
    candidate = Path(os.path.abspath(os.fspath(path)))
    root = (
        Path(os.path.abspath(os.fspath(repository_root)))
        if repository_root is not None
        else (
            ROOT
            if candidate == Path(os.path.abspath(os.fspath(POLICY_PATH)))
            else candidate.parent
        )
    )
    try:
        relative_path = candidate.relative_to(root).as_posix()
        raw = _read_bounded_reviewed_file(
            root, relative_path, MAX_DOCUMENT_BYTES
        )
    except (InventoryError, ValueError) as error:
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
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
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
        text = raw.rstrip(b"\r\n").decode("utf-8", errors="strict")
        if not text or "\0" in text:
            raise ValueError("invalid Git path")
        path = Path(os.path.abspath(text))
        if not path.is_absolute():
            raise ValueError("non-absolute Git path")
        _validate_git_directory_path(path)
        return path
    except (OSError, UnicodeError, ValueError, InventoryError) as error:
        raise InventoryError("inventory Git object database is invalid") from error


def _validate_git_directory_path(path):
    """Reject linked/reparse Git directory components without resolving them."""
    candidate = Path(path)
    parts = candidate.parts
    if not parts:
        raise InventoryError("inventory Git object database is invalid")
    current = Path(parts[0])
    components = (current,)
    for part in parts[1:]:
        current = current / part
        components += (current,)
    for component in components:
        try:
            status = component.lstat()
        except OSError as error:
            raise InventoryError("inventory Git object database is invalid") from error
        reparse = bool(
            getattr(status, "st_file_attributes", 0)
            & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
        )
        if not stat.S_ISDIR(status.st_mode) or stat.S_ISLNK(status.st_mode) or reparse:
            raise InventoryError("inventory Git object database is invalid")


def _validate_primary_object_database(repository_root):
    """Reject alternates and partial-clone stores outside the primary object DB."""
    root = Path(repository_root).resolve()
    common_directory = _absolute_git_path(root, "--git-common-dir")
    object_directory = _absolute_git_path(root, "--git-path", "objects")
    try:
        if object_directory != common_directory / "objects":
            raise InventoryError("inventory Git object database is not self-contained")
        info_directory = object_directory / "info"
        pack_directory = object_directory / "pack"
        _validate_git_directory_path(info_directory)
        _validate_git_directory_path(pack_directory)
        for sentinel in (
            info_directory / "alternates",
            info_directory / "http-alternates",
        ):
            if sentinel.exists():
                raise InventoryError(
                    "inventory Git object database is not self-contained"
                )
        if any(
            path.is_file() and path.suffix.casefold() == ".promisor"
            for path in pack_directory.iterdir()
        ):
            raise InventoryError("inventory Git object database is not self-contained")
    except InventoryError as error:
        raise InventoryError(
            "inventory Git object database is not self-contained"
        ) from error
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


def _validate_output_value(value):
    """Iteratively enforce the closed JSON v1 value and depth contract."""
    active = set()
    stack = [(value, 0, False)]
    while stack:
        current, depth, exiting = stack.pop()
        if exiting:
            active.remove(id(current))
            continue
        if current is None or type(current) in (str, bool):
            continue
        if type(current) is int:
            digits = str(current).removeprefix("-")
            if len(digits) > MAX_JSON_INTEGER_DIGITS:
                raise InventoryError("inventory output document is invalid")
            continue
        if type(current) not in (dict, list):
            raise InventoryError("inventory output document is invalid")
        container_depth = depth + 1
        if container_depth > MAX_JSON_DEPTH or id(current) in active:
            raise InventoryError("inventory output document is invalid")
        active.add(id(current))
        stack.append((current, depth, True))
        if type(current) is dict:
            if any(type(key) is not str for key in current):
                raise InventoryError("inventory output document is invalid")
            children = tuple(current.values())
        else:
            children = tuple(current)
        for child in reversed(children):
            stack.append((child, container_depth, False))


def canonical_json_bytes(value):
    """Render one canonical, bounded ASCII JSON document."""
    _validate_output_value(value)
    try:
        raw = (
            json.dumps(
                value,
                ensure_ascii=True,
                sort_keys=False,
                separators=(",", ":"),
                indent=2,
                allow_nan=False,
            ).encode("ascii")
            + b"\n"
        )
    except (TypeError, ValueError, UnicodeError, RecursionError) as error:
        raise InventoryError("inventory output document is invalid") from error
    if len(raw) > MAX_DOCUMENT_BYTES:
        raise InventoryError("inventory output document exceeds the byte limit")
    return raw


def _group_dependency_evidence(entries):
    """Losslessly group sorted evidence by source, kind, and status."""
    groups = []
    current_key = None
    current = None
    for record in sorted(entries, key=_evidence_record_sort_key):
        key = (record["sourcePath"], record["kind"], record["status"])
        if key != current_key:
            current = {
                "sourcePath": key[0],
                "kind": key[1],
                "status": key[2],
                "locators": [],
            }
            groups.append(current)
            current_key = key
        current["locators"].append(record["locator"])
    return groups


def expand_dependency_groups(document):
    """Expand one closed dependency shard to individual evidence identities."""
    if type(document) is not dict or frozenset(document) != frozenset(
        (
            "schemaVersion",
            "repository",
            "sourceCommit",
            "sourceTag",
            "externalRefs",
            "developmentDependencies",
        )
    ):
        raise InventoryError("inventory dependency document is invalid")
    if (
        document["schemaVersion"] != SCHEMA_VERSION
        or type(document["schemaVersion"]) is not int
        or document["repository"] != REPOSITORY
        or document["sourceCommit"] != SOURCE_COMMIT
        or document["sourceTag"] != SOURCE_TAG
    ):
        raise InventoryError("inventory dependency document is invalid")

    result = {"externalRefs": [], "developmentDependencies": []}
    contracts = {
        "externalRefs": EXTERNAL_DEPENDENCY_CONTRACT,
        "developmentDependencies": DEVELOPMENT_DEPENDENCY_CONTRACT,
    }
    for field, contract in contracts.items():
        groups = document[field]
        if type(groups) is not list:
            raise InventoryError("inventory dependency document is invalid")
        previous_group = None
        identities = set()
        for raw_group in groups:
            if type(raw_group) is not dict or tuple(raw_group) != (
                "sourcePath",
                "kind",
                "status",
                "locators",
            ):
                raise InventoryError("inventory dependency document is invalid")
            source_path = raw_group["sourcePath"]
            kind = raw_group["kind"]
            status = raw_group["status"]
            try:
                _validate_path(source_path)
            except InventoryError as error:
                raise InventoryError("inventory dependency document is invalid") from error
            if (
                type(kind) is not str
                or type(status) is not str
                or kind not in contract
                or status != contract[kind]
            ):
                raise InventoryError("inventory dependency document is invalid")
            group_key = (source_path.encode("ascii"), kind.encode("ascii"))
            if previous_group is not None and group_key <= previous_group:
                raise InventoryError("inventory dependency document is invalid")
            previous_group = group_key
            locators = raw_group["locators"]
            if type(locators) is not list or not locators:
                raise InventoryError("inventory dependency document is invalid")
            previous_locator = None
            for locator in locators:
                try:
                    validated = _validate_dependency_locator(locator, kind)
                except InventoryError as error:
                    raise InventoryError("inventory dependency document is invalid") from error
                locator_key = validated.encode("utf-8")
                if previous_locator is not None and locator_key <= previous_locator:
                    raise InventoryError("inventory dependency document is invalid")
                previous_locator = locator_key
                identity = (source_path, validated, kind, status)
                if identity in identities:
                    raise InventoryError("inventory dependency document is invalid")
                identities.add(identity)
                result[field].append(
                    _evidence_record(source_path, validated, kind, status)
                )
        result[field].sort(key=_evidence_record_sort_key)
    return result


def _identity_header():
    return {
        "schemaVersion": SCHEMA_VERSION,
        "repository": REPOSITORY,
        "sourceCommit": SOURCE_COMMIT,
        "sourceTag": SOURCE_TAG,
    }


def _dependency_counts(evidence):
    development = evidence["developmentDependencies"]
    return {
        "externalRefs": len(evidence["externalRefs"]),
        "developmentDependencies": len(development),
        "absolutePath": sum(entry["kind"] == "absolute-path" for entry in development),
        "environmentPath": sum(
            entry["kind"] == "environment-path" for entry in development
        ),
        "repositoryPath": sum(
            entry["kind"] == "repository-path" for entry in development
        ),
    }


def _asset_dependency_evidence(evidence):
    """Index reviewed dependency locators by governed asset path."""
    result = {}
    for field, entries in evidence.items():
        for entry in entries:
            by_field = result.setdefault(
                entry["sourcePath"],
                {"externalRefs": [], "developmentDependencies": []},
            )
            by_field[field].append(entry["locator"])
    for by_field in result.values():
        for locators in by_field.values():
            locators.sort(key=_dependency_sort_key)
    return result


def generate_inventory_documents(repository_root=ROOT, policy=None):
    """Generate all reviewed output bytes only from policy and frozen Git blobs."""
    root = Path(repository_root).resolve()
    if policy is None:
        policy = load_policy(
            root / POLICY_PATH.relative_to(ROOT), repository_root=root
        )
    else:
        validate_policy(policy)
    records = _bind_governed_assets(root, policy, SOURCE_COMMIT, SOURCE_TAG)
    evidence = _extract_dependency_evidence(root, records)
    _require_dependency_policy_match(policy, evidence)
    evidence_by_asset = _asset_dependency_evidence(evidence)

    documents = {}
    for category, relative_path in CATEGORY_OUTPUT_PATHS.items():
        assets = []
        for record in records:
            if record["category"] == category:
                asset = {field: record[field] for field in ASSET_OUTPUT_FIELDS}
                dependencies = evidence_by_asset.get(
                    record["sourcePath"],
                    {"externalRefs": [], "developmentDependencies": []},
                )
                asset["externalRefs"] = dependencies["externalRefs"]
                asset["developmentDependencies"] = dependencies[
                    "developmentDependencies"
                ]
                assets.append(asset)
        shard = _identity_header()
        shard.update(
            {
                "category": category,
                "assetCount": len(assets),
                "assets": assets,
            }
        )
        documents[relative_path] = canonical_json_bytes(shard)

    dependency = _identity_header()
    dependency.update(
        {
            "externalRefs": _group_dependency_evidence(evidence["externalRefs"]),
            "developmentDependencies": _group_dependency_evidence(
                evidence["developmentDependencies"]
            ),
        }
    )
    dependency_path = "migration/assets/dependencies.json"
    documents[dependency_path] = canonical_json_bytes(dependency)

    counts = _dependency_counts(evidence)
    shards = []
    for relative_path in OUTPUT_RELATIVE_PATHS[1:]:
        if relative_path == dependency_path:
            category = "dependencies"
            record_count = counts["externalRefs"] + counts["developmentDependencies"]
        else:
            category = next(
                key for key, value in CATEGORY_OUTPUT_PATHS.items() if value == relative_path
            )
            record_count = sum(record["category"] == category for record in records)
        shards.append(
            {
                "path": relative_path,
                "sha256": hashlib.sha256(documents[relative_path]).hexdigest(),
                "category": category,
                "recordCount": record_count,
            }
        )

    index = _identity_header()
    index.update(
        {
            "digestAlgorithm": "sha256",
            "order": "ascii-posix-path",
            "assetCount": len(records),
            "dependencyCounts": counts,
            "shards": shards,
        }
    )
    documents["migration/assets/index.json"] = canonical_json_bytes(index)
    ordered = {path: documents[path] for path in OUTPUT_RELATIVE_PATHS}
    if tuple(ordered) != OUTPUT_RELATIVE_PATHS:
        raise InventoryError("inventory output path set is invalid")
    return ordered


def _validate_output_path_set(documents):
    if type(documents) is not dict or tuple(documents) != OUTPUT_RELATIVE_PATHS:
        raise InventoryError("inventory output path set is invalid")
    if any(type(raw) is not bytes or len(raw) > MAX_DOCUMENT_BYTES for raw in documents.values()):
        raise InventoryError("inventory output document is invalid")


def _check_inventory_documents(repository_root, documents):
    """Compare exact bounded worktree bytes without writing anything."""
    _validate_output_path_set(documents)
    root = Path(repository_root).resolve()
    for relative_path, expected in documents.items():
        try:
            actual = _read_bounded_reviewed_file(
                root, relative_path, MAX_DOCUMENT_BYTES
            )
        except InventoryError as error:
            raise InventoryError("inventory output is missing or unsafe") from error
        if actual != expected:
            raise InventoryError("inventory output does not match generated bytes")


def _prepare_output_directory(repository_root):
    """Create and verify the fixed output directory without following links."""
    root = Path(repository_root)
    components = (root, root / "migration", root / "migration" / "assets")
    for position, component in enumerate(components):
        if position:
            try:
                component.mkdir()
            except FileExistsError:
                pass
            except OSError as error:
                raise InventoryError("inventory output path is invalid") from error
        try:
            status = component.lstat()
        except OSError as error:
            raise InventoryError("inventory output path is invalid") from error
        reparse = bool(
            getattr(status, "st_file_attributes", 0)
            & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
        )
        if not stat.S_ISDIR(status.st_mode) or stat.S_ISLNK(status.st_mode) or reparse:
            raise InventoryError("inventory output path is invalid")
    return components[-1]


def _snapshot_output_directory(repository_root):
    """Capture stable identities for the fixed output directory chain."""
    root = Path(repository_root)
    assets = _prepare_output_directory(root)
    components = (root, root / "migration", assets)
    identities = []
    for component in components:
        try:
            status = component.lstat()
        except OSError as error:
            raise InventoryError("inventory output path is invalid") from error
        if not stat.S_ISDIR(status.st_mode) or stat.S_ISLNK(status.st_mode) or _is_reparse(status):
            raise InventoryError("inventory output path is invalid")
        identities.append(_component_identity(status))
    return tuple(identities)


def _verify_output_directory_identity(repository_root, snapshot):
    """Fail before path operations if any output directory was replaced."""
    root = Path(repository_root)
    components = (root, root / "migration", root / "migration" / "assets")
    try:
        current = tuple(_component_identity(path.lstat()) for path in components)
    except OSError as error:
        raise InventoryError("inventory output path changed") from error
    if current != snapshot or any(
        not stat.S_ISDIR(path.lstat().st_mode)
        or stat.S_ISLNK(path.lstat().st_mode)
        or _is_reparse(path.lstat())
        for path in components
    ):
        raise InventoryError("inventory output path changed")


@contextmanager
def _hold_output_directory_chain(repository_root, snapshot):
    """Hold verified directory capabilities for the complete transaction."""
    if os.name != "nt":
        root = Path(repository_root)
        flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
        descriptors = []
        try:
            root_descriptor = os.open(root, flags)
            descriptors.append(root_descriptor)
            migration_descriptor = os.open(
                "migration", flags, dir_fd=root_descriptor
            )
            descriptors.append(migration_descriptor)
            assets_descriptor = os.open(
                "assets", flags, dir_fd=migration_descriptor
            )
            descriptors.append(assets_descriptor)
            opened = tuple(
                _component_identity(os.fstat(descriptor))
                for descriptor in descriptors
            )
            if opened != snapshot:
                raise InventoryError("inventory output path changed")
            _verify_output_directory_identity(root, snapshot)
            yield assets_descriptor
            _verify_output_directory_identity(root, snapshot)
        except OSError as error:
            raise InventoryError("inventory output path changed") from error
        finally:
            for descriptor in reversed(descriptors):
                os.close(descriptor)
        return

    import ctypes
    from ctypes import wintypes

    create_file = ctypes.WinDLL("kernel32", use_last_error=True).CreateFileW
    create_file.argtypes = (
        wintypes.LPCWSTR,
        wintypes.DWORD,
        wintypes.DWORD,
        wintypes.LPVOID,
        wintypes.DWORD,
        wintypes.DWORD,
        wintypes.HANDLE,
    )
    create_file.restype = wintypes.HANDLE
    close_handle = ctypes.WinDLL("kernel32", use_last_error=True).CloseHandle
    close_handle.argtypes = (wintypes.HANDLE,)
    close_handle.restype = wintypes.BOOL

    file_share_read = 0x00000001
    file_share_write = 0x00000002
    delete_access = 0x00010000
    file_read_attributes = 0x00000080
    open_existing = 3
    file_flag_backup_semantics = 0x02000000
    file_flag_open_reparse_point = 0x00200000
    invalid_handle = ctypes.c_void_p(-1).value
    root = Path(repository_root)
    components = (root, root / "migration", root / "migration" / "assets")
    handles = []
    try:
        for component in components:
            handle = create_file(
                os.fspath(component),
                delete_access | file_read_attributes,
                file_share_read | file_share_write,
                None,
                open_existing,
                file_flag_backup_semantics | file_flag_open_reparse_point,
                None,
            )
            if handle == invalid_handle:
                raise InventoryError("inventory output path changed")
            handles.append(handle)
        _verify_output_directory_identity(root, snapshot)
        yield None
        _verify_output_directory_identity(root, snapshot)
    finally:
        for handle in reversed(handles):
            close_handle(handle)


def _create_output_temp(assets, destination, purpose, directory_fd):
    if directory_fd is None:
        descriptor, name = tempfile.mkstemp(
            prefix=f".{destination.name}.{purpose}.", suffix=".tmp", dir=assets
        )
        return descriptor, Path(name)
    flags = (
        os.O_WRONLY
        | os.O_CREAT
        | os.O_EXCL
        | getattr(os, "O_CLOEXEC", 0)
        | getattr(os, "O_NOFOLLOW", 0)
    )
    for _attempt in range(128):
        name = f".{destination.name}.{purpose}.{secrets.token_hex(8)}.tmp"
        try:
            return os.open(name, flags, 0o600, dir_fd=directory_fd), name
        except FileExistsError:
            continue
    raise OSError("could not allocate inventory transaction file")


def _read_output_file(token, maximum_bytes, directory_fd):
    if directory_fd is None:
        with Path(token).open("rb") as stream:
            raw = stream.read(maximum_bytes + 1)
    else:
        flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | os.O_NOFOLLOW
        descriptor = os.open(token, flags, dir_fd=directory_fd)
        with os.fdopen(descriptor, "rb") as stream:
            status = os.fstat(stream.fileno())
            if not stat.S_ISREG(status.st_mode):
                raise InventoryError("inventory output transaction failed")
            raw = stream.read(maximum_bytes + 1)
    if len(raw) > maximum_bytes:
        raise InventoryError("inventory output transaction failed")
    return raw


def _unlink_output_file(token, directory_fd):
    if directory_fd is None:
        Path(token).unlink(missing_ok=True)
    else:
        try:
            os.unlink(token, dir_fd=directory_fd)
        except FileNotFoundError:
            pass


def _replace_output_file(source, destination, directory_fd):
    if directory_fd is None:
        os.replace(source, destination)
    else:
        os.replace(
            source,
            destination.name,
            src_dir_fd=directory_fd,
            dst_dir_fd=directory_fd,
        )


def _destination_status(destination, directory_fd):
    if directory_fd is None:
        return destination.lstat()
    return os.stat(destination.name, dir_fd=directory_fd, follow_symlinks=False)


def _stage_output_file(
    root, assets, destination, raw, purpose, snapshot, directory_fd
):
    _verify_output_directory_identity(root, snapshot)
    descriptor = None
    temporary = None
    try:
        descriptor, temporary = _create_output_temp(
            assets, destination, purpose, directory_fd
        )
        with os.fdopen(descriptor, "wb") as stream:
            descriptor = None
            stream.write(raw)
            stream.flush()
            os.fsync(stream.fileno())
            if hasattr(os, "fchmod"):
                os.fchmod(stream.fileno(), 0o644)
        if not hasattr(os, "fchmod"):
            os.chmod(temporary, 0o644)
        _verify_output_directory_identity(root, snapshot)
        if _read_output_file(temporary, MAX_DOCUMENT_BYTES, directory_fd) != raw:
            raise InventoryError("inventory output transaction failed")
        return temporary
    except (OSError, ValueError, InventoryError) as error:
        if descriptor is not None:
            os.close(descriptor)
        if temporary is not None:
            try:
                _unlink_output_file(temporary, directory_fd)
            except OSError:
                pass
        if isinstance(error, InventoryError) and str(error) == "inventory output path changed":
            raise
        raise InventoryError("inventory output transaction failed") from error


def _cleanup_transaction_files(root, paths, snapshot, directory_fd):
    for path in tuple(paths):
        try:
            _unlink_output_file(path, directory_fd)
        except OSError as error:
            raise InventoryError("inventory output transaction failed") from error
    _verify_output_directory_identity(root, snapshot)


def _write_inventory_documents(repository_root, documents):
    """Stage all bytes, then replace transactionally with complete rollback."""
    _validate_output_path_set(documents)
    root = Path(repository_root).resolve()
    assets = _prepare_output_directory(root)
    snapshot = _snapshot_output_directory(root)
    staged = {}
    backups = {}
    temporary_paths = set()
    replaced = []
    with _hold_output_directory_chain(root, snapshot) as directory_fd:
        try:
            for relative_path, raw in documents.items():
                destination = root / PurePosixPath(relative_path)
                if destination.parent != assets:
                    raise InventoryError("inventory output path is invalid")
                temporary = _stage_output_file(
                    root,
                    assets,
                    destination,
                    raw,
                    "new",
                    snapshot,
                    directory_fd,
                )
                staged[relative_path] = temporary
                temporary_paths.add(temporary)

            for relative_path in documents:
                destination = root / PurePosixPath(relative_path)
                _verify_output_directory_identity(root, snapshot)
                try:
                    _destination_status(destination, directory_fd)
                except FileNotFoundError:
                    backups[relative_path] = None
                except OSError as error:
                    raise InventoryError("inventory output transaction failed") from error
                else:
                    old = _read_output_file(
                        destination if directory_fd is None else destination.name,
                        MAX_DOCUMENT_BYTES,
                        directory_fd,
                    )
                    backup = _stage_output_file(
                        root,
                        assets,
                        destination,
                        old,
                        "backup",
                        snapshot,
                        directory_fd,
                    )
                    backups[relative_path] = backup
                    temporary_paths.add(backup)

            for relative_path in documents:
                destination = root / PurePosixPath(relative_path)
                _verify_output_directory_identity(root, snapshot)
                _replace_output_file(
                    staged[relative_path], destination, directory_fd
                )
                temporary_paths.remove(staged[relative_path])
                replaced.append(relative_path)
                _verify_output_directory_identity(root, snapshot)
        except (OSError, InventoryError) as error:
            try:
                _verify_output_directory_identity(root, snapshot)
                for relative_path in reversed(replaced):
                    destination = root / PurePosixPath(relative_path)
                    backup = backups.get(relative_path)
                    if backup is None:
                        _unlink_output_file(
                            destination
                            if directory_fd is None
                            else destination.name,
                            directory_fd,
                        )
                    else:
                        _replace_output_file(backup, destination, directory_fd)
                        temporary_paths.discard(backup)
                    _verify_output_directory_identity(root, snapshot)
                _cleanup_transaction_files(
                    root, temporary_paths, snapshot, directory_fd
                )
                temporary_paths.clear()
            except (OSError, InventoryError) as rollback_error:
                raise InventoryError("inventory output transaction failed") from rollback_error
            raise InventoryError("inventory output transaction failed") from error
        else:
            _cleanup_transaction_files(
                root, temporary_paths, snapshot, directory_fd
            )
            temporary_paths.clear()
        finally:
            if temporary_paths:
                try:
                    _cleanup_transaction_files(
                        root, temporary_paths, snapshot, directory_fd
                    )
                except InventoryError:
                    pass


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
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--list", action="store_true")
    modes.add_argument("--check", action="store_true")
    modes.add_argument("--write", action="store_true")
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
        documents = generate_inventory_documents(ROOT)
        if options.write:
            _write_inventory_documents(ROOT, documents)
            print("Mac-Win migration asset inventory was written.")
            return 0
        _check_inventory_documents(ROOT, documents)
    except InventoryError as error:
        print(f"migration asset inventory failed: {error}", file=sys.stderr)
        return 1
    print("Mac-Win migration asset inventory is current.")
    return 0


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main(sys.argv[1:]))

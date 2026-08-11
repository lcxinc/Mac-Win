#!/usr/bin/env python3
"""Build the deterministic Mac-Win migration asset inventory."""

import json
from pathlib import Path, PurePosixPath, PureWindowsPath
import sys


ROOT = Path(__file__).resolve().parents[1]
POLICY_PATH = ROOT / "migration" / "assets" / "metadata-policy.json"

SCHEMA_VERSION = 1
REPOSITORY = "a1112/Mac-Win"
SOURCE_COMMIT = "db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527"
SOURCE_TAG = "mw-migration-baseline-db12d5e"
MAX_DOCUMENT_BYTES = 64 * 1024
MAX_JSON_DEPTH = 128

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
LICENSE_STATUSES = frozenset(("unresolved",))
PROVENANCE_STATUSES = frozenset(("unresolved",))
INTENDED_OWNERS = frozenset(
    (
        "compatforge/catalog",
        "compatforge/patches",
        "compatforge/probes",
        "compatforge/bottle-schema",
        "macwin/archive",
        "quarantine/unresolved",
    )
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
DEPENDENCY_FIELDS = frozenset(("sourcePath", "locator", "kind", "status"))
EXTERNAL_DEPENDENCY_KINDS = frozenset(("url",))
EXTERNAL_DEPENDENCY_STATUSES = frozenset(("external-unverified",))
DEVELOPMENT_DEPENDENCY_KINDS = frozenset(
    ("absolute-path", "environment-path", "repository-path")
)
DEVELOPMENT_DEPENDENCY_STATUSES = frozenset(
    ("not-in-baseline", "development-machine-only", "unexpanded")
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
        )
    except InventoryError:
        raise
    except (json.JSONDecodeError, RecursionError) as error:
        raise InventoryError("inventory document is not valid JSON") from error


def _require_object(value):
    if type(value) is not dict:
        raise InventoryError("inventory policy value type is invalid")
    return value


def _require_list(value):
    if type(value) is not list:
        raise InventoryError("inventory policy value type is invalid")
    return value


def _require_string(value):
    if type(value) is not str:
        raise InventoryError("inventory policy value type is invalid")
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
    path = _require_string(value)
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
        text = _require_string(entry)
        if not text or "\0" in text or any(ord(character) < 0x20 for character in text):
            raise InventoryError("inventory policy dependency reference is invalid")
        if text in seen:
            raise InventoryError("inventory policy dependency reference is duplicated")
        seen.add(text)


def _validate_dependency_entries(entries, kinds, statuses, governed_paths):
    seen = set()
    for entry in _require_list(entries):
        dependency = _require_exact_fields(entry, DEPENDENCY_FIELDS)
        source_path = _validate_path(dependency["sourcePath"])
        locator = _require_string(dependency["locator"])
        kind = _require_string(dependency["kind"])
        status = _require_string(dependency["status"])
        if source_path not in governed_paths or not locator or "\0" in locator:
            raise InventoryError("inventory policy dependency is invalid")
        if any(ord(character) < 0x20 for character in locator):
            raise InventoryError("inventory policy dependency is invalid")
        if kind not in kinds or status not in statuses:
            raise InventoryError("inventory policy enum value is invalid")
        identity = (source_path, locator, kind)
        if identity in seen:
            raise InventoryError("inventory policy dependency is duplicated")
        seen.add(identity)


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
    _validate_dependency_entries(
        dependency_policy["externalRefs"],
        EXTERNAL_DEPENDENCY_KINDS,
        EXTERNAL_DEPENDENCY_STATUSES,
        governed_paths,
    )
    _validate_dependency_entries(
        dependency_policy["developmentDependencies"],
        DEVELOPMENT_DEPENDENCY_KINDS,
        DEVELOPMENT_DEPENDENCY_STATUSES,
        governed_paths,
    )
    return policy


def parse_policy_bytes(raw):
    """Parse and validate one bounded strict-UTF-8 policy document."""
    return validate_policy(_parse_json_document(raw))


def load_policy(path=POLICY_PATH):
    """Read and validate a bounded policy file."""
    try:
        with Path(path).open("rb") as stream:
            raw = stream.read(MAX_DOCUMENT_BYTES + 1)
    except OSError as error:
        raise InventoryError("inventory policy could not be read") from error
    return parse_policy_bytes(raw)


def main(_arguments=()):
    try:
        load_policy()
    except InventoryError as error:
        print(f"migration asset inventory failed: {error}", file=sys.stderr)
        return 1
    print("Mac-Win migration asset metadata policy is valid.")
    return 0


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""Validate the closed Mac-Win migration baseline manifest contract."""

import json
from pathlib import Path
import re
import sys


MAX_MANIFEST_BYTES = 65_536
MAX_JSON_INTEGER_DIGITS = 128
ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "migration" / "baseline.json"

SCHEMA_VERSION = 1
REPOSITORY = "a1112/Mac-Win"
SOURCE_COMMIT = "4e421fbea6f59e73e4f813c1f0a14e8db9e36de7"
TAG = "mw-migration-baseline-4e421fb"
SWIFT_PACKAGE_PATH = "MacWinManager"
EVIDENCE_TARGETS = [
    {"runner": "macos-15", "architecture": "arm64"},
    {"runner": "macos-15-intel", "architecture": "x86_64"},
]
FROZEN_FEATURE_AREAS = ["SwiftUI", "Bridge", "legacy-launcher"]
TOP_LEVEL_FIELDS = (
    "schemaVersion",
    "repository",
    "sourceCommit",
    "tag",
    "swiftPackagePath",
    "evidenceTargets",
    "frozenFeatureAreas",
)


class BaselineValidationError(ValueError):
    """Raised when migration baseline input violates the closed contract."""


def _reject_duplicate_keys(pairs):
    decoded = {}
    for key, value in pairs:
        if key in decoded:
            raise BaselineValidationError("manifest has duplicate JSON key")
        decoded[key] = value
    return decoded


def _parse_bounded_int(value):
    digits = value.removeprefix("-")
    if len(digits) > MAX_JSON_INTEGER_DIGITS:
        raise ValueError("JSON integer exceeds reviewed digit limit")
    return int(value)


def parse_manifest_bytes(raw):
    """Parse bounded strict-UTF-8 JSON while rejecting decoded duplicate keys."""
    if len(raw) > MAX_MANIFEST_BYTES:
        raise BaselineValidationError("manifest exceeds 65536-byte limit")

    try:
        text = raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise BaselineValidationError("manifest is not valid UTF-8") from error

    try:
        return json.loads(
            text,
            object_pairs_hook=_reject_duplicate_keys,
            parse_int=_parse_bounded_int,
        )
    except BaselineValidationError:
        raise
    except (json.JSONDecodeError, RecursionError, ValueError) as error:
        raise BaselineValidationError("manifest is not valid JSON") from error


def validate_manifest(manifest):
    """Validate an already parsed manifest without relying on repository state."""
    if type(manifest) is not dict:
        raise BaselineValidationError("manifest must be a JSON object")

    expected_fields = set(TOP_LEVEL_FIELDS)
    actual_fields = set(manifest)
    missing = [field for field in TOP_LEVEL_FIELDS if field not in actual_fields]
    if missing:
        raise BaselineValidationError(f"manifest is missing field: {missing[0]}")

    unknown = actual_fields - expected_fields
    if unknown:
        raise BaselineValidationError("manifest has unknown field")

    schema_version = manifest["schemaVersion"]
    if type(schema_version) is not int or schema_version != SCHEMA_VERSION:
        raise BaselineValidationError("schemaVersion must be integer 1")

    if manifest["repository"] != REPOSITORY:
        raise BaselineValidationError("repository must equal a1112/Mac-Win")

    source_commit = manifest["sourceCommit"]
    if type(source_commit) is not str or re.fullmatch(r"[0-9a-f]{40}", source_commit) is None:
        raise BaselineValidationError(
            "sourceCommit must be a 40-character lowercase hexadecimal commit"
        )
    if source_commit != SOURCE_COMMIT:
        raise BaselineValidationError(f"sourceCommit must equal {SOURCE_COMMIT}")

    if manifest["tag"] != TAG:
        raise BaselineValidationError(f"tag must equal {TAG}")

    if manifest["swiftPackagePath"] != SWIFT_PACKAGE_PATH:
        raise BaselineValidationError(
            f"swiftPackagePath must equal {SWIFT_PACKAGE_PATH}"
        )

    if manifest["evidenceTargets"] != EVIDENCE_TARGETS:
        raise BaselineValidationError(
            "evidenceTargets must exactly equal the reviewed runner sequence"
        )

    if manifest["frozenFeatureAreas"] != FROZEN_FEATURE_AREAS:
        raise BaselineValidationError(
            "frozenFeatureAreas must exactly equal the reviewed freeze sequence"
        )


def load_manifest(path=MANIFEST_PATH):
    """Read, parse, and validate a manifest with a pre-allocation byte bound."""
    with Path(path).open("rb") as stream:
        raw = stream.read(MAX_MANIFEST_BYTES + 1)
    manifest = parse_manifest_bytes(raw)
    validate_manifest(manifest)
    return manifest


def main():
    try:
        load_manifest()
    except (BaselineValidationError, OSError) as error:
        print(f"migration baseline validation failed: {error}", file=sys.stderr)
        return 1

    print("Mac-Win migration baseline manifest is valid.")
    return 0


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main())

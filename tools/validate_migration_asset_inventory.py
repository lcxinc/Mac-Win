#!/usr/bin/env python3
"""Validate the reviewed deterministic Mac-Win migration asset inventory."""

import argparse
import hashlib
from pathlib import Path
import re
import sys

# This validator's contract is read-only even when invoked without ``python -B``.
# Set the process policy before importing repository-local modules.
sys.dont_write_bytecode = True

try:
    from tools import generate_migration_asset_inventory as generator
except ModuleNotFoundError:
    import generate_migration_asset_inventory as generator


ROOT = Path(__file__).resolve().parents[1]
MAX_DOCUMENT_BYTES = generator.MAX_DOCUMENT_BYTES
OUTPUT_RELATIVE_PATHS = generator.OUTPUT_RELATIVE_PATHS
generate_inventory_documents = generator.generate_inventory_documents


class InventoryValidationError(ValueError):
    """One stable, non-reflective inventory validation failure."""


def _reviewed_relative_path(value):
    """Return one inventory-owned reviewed path without consulting the host."""
    try:
        return generator._validate_path(value)
    except generator.InventoryError as error:
        raise InventoryValidationError(
            "migration asset inventory reviewed file is invalid"
        ) from error


def _index_entry(repository_root, relative_path):
    """Read one exact stage-0 blob identity through the hardened Git runner."""
    path = _reviewed_relative_path(relative_path)
    try:
        listed = generator._run_git(
            repository_root, "ls-files", "--stage", "-z", "--", path
        )
        raw = listed.stdout
        if not raw or not raw.endswith(b"\0") or len(raw[:-1].split(b"\0")) != 1:
            raise InventoryValidationError(
                "migration asset inventory reviewed file is invalid"
            )
        metadata, indexed_path = raw[:-1].split(b"\t", 1)
        mode, object_id, stage = metadata.split(b" ")
        if (
            indexed_path != path.encode("utf-8")
            or mode != b"100644"
            or stage != b"0"
            or re.fullmatch(rb"(?:[0-9a-f]{40}|[0-9a-f]{64})", object_id) is None
            or set(object_id) == {ord("0")}
        ):
            raise InventoryValidationError(
                "migration asset inventory reviewed file is invalid"
            )
        debug = generator._run_git(
            repository_root, "ls-files", "--debug", "-z", "--", path
        )
        flags = re.findall(
            rb"(?:^|[\t ])flags: ([0-9a-fA-F]+)(?:\r?\n|$)", debug.stdout
        )
        if (
            not debug.stdout.startswith(path.encode("utf-8") + b"\0")
            or len(flags) != 1
            or int(flags[0], 16) & 0x20000000
        ):
            raise InventoryValidationError(
                "migration asset inventory reviewed file is invalid"
            )
        return object_id.decode("ascii")
    except InventoryValidationError:
        raise
    except (generator.InventoryError, UnicodeError, ValueError) as error:
        raise InventoryValidationError(
            "migration asset inventory reviewed file is invalid"
        ) from error


def parse_inventory_document(raw):
    """Parse one bounded canonical document with strict UTF-8 and LF bytes."""
    try:
        value = generator._parse_json_document(raw)
        if generator.canonical_json_bytes(value) != raw:
            raise InventoryValidationError(
                "migration asset inventory document is invalid"
            )
        return value
    except InventoryValidationError:
        raise
    except (generator.InventoryError, TypeError, ValueError) as error:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        ) from error


def _exact_object(value, fields):
    if type(value) is not dict or tuple(value) != fields:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )
    return value


def _exact_integer(value):
    if type(value) is not int or value < 0:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )
    return value


def _validate_identity(value):
    if (
        value["schemaVersion"] != generator.SCHEMA_VERSION
        or type(value["schemaVersion"]) is not int
        or value["repository"] != generator.REPOSITORY
        or value["sourceCommit"] != generator.SOURCE_COMMIT
        or value["sourceTag"] != generator.SOURCE_TAG
    ):
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )


def _validate_asset(asset, category, previous_path):
    _exact_object(asset, generator.ASSET_OUTPUT_FIELDS)
    source_path = asset["sourcePath"]
    try:
        generator._validate_path(source_path)
    except generator.InventoryError as error:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        ) from error
    encoded_path = source_path.encode("ascii")
    if previous_path is not None and encoded_path <= previous_path:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )
    try:
        encoded_oid = asset["gitBlobOid"].encode("ascii", errors="strict")
    except (AttributeError, UnicodeEncodeError) as error:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        ) from error
    if (
        asset["sourceCommit"] != generator.SOURCE_COMMIT
        or type(asset["gitBlobOid"]) is not str
        or generator._OID_PATTERN.fullmatch(encoded_oid) is None
        or set(encoded_oid) == {ord("0")}
        or type(asset["sha256"]) is not str
        or len(asset["sha256"]) != 64
        or any(character not in "0123456789abcdef" for character in asset["sha256"])
        or type(asset["byteSize"]) is not int
        or asset["byteSize"] < 0
        or asset["byteSize"] > generator.MAX_ASSET_BYTES
        or asset["gitMode"] not in ("100644", "100755")
        or asset["kind"] != generator.CATEGORY_KINDS[category]
        or asset["intendedOwner"] not in generator.CATEGORY_OWNERS[category]
        or asset["license"] != {"status": "unresolved"}
        or asset["provenance"] != {"status": "unresolved"}
        or type(asset["externalRefs"]) is not list
        or type(asset["developmentDependencies"]) is not list
    ):
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )
    for field in ("externalRefs", "developmentDependencies"):
        previous_reference = None
        for locator in asset[field]:
            try:
                locator = generator._require_string(
                    locator, "inventory dependency document is invalid"
                )
            except generator.InventoryError as error:
                raise InventoryValidationError(
                    "migration asset inventory document is invalid"
                ) from error
            reference_key = locator.encode("utf-8")
            if previous_reference is not None and reference_key <= previous_reference:
                raise InventoryValidationError(
                    "migration asset inventory document is invalid"
                )
            previous_reference = reference_key
    return encoded_path


def validate_inventory_documents(documents, expected_documents=None):
    """Validate the complete closed in-memory document set."""
    if type(documents) is not dict or tuple(documents) != OUTPUT_RELATIVE_PATHS:
        raise InventoryValidationError(
            "migration asset inventory document set is invalid"
        )
    parsed = {
        path: parse_inventory_document(raw) for path, raw in documents.items()
    }

    index = _exact_object(
        parsed["migration/assets/index.json"],
        (
            "schemaVersion",
            "repository",
            "sourceCommit",
            "sourceTag",
            "digestAlgorithm",
            "order",
            "assetCount",
            "dependencyCounts",
            "shards",
        ),
    )
    _validate_identity(index)
    if index["digestAlgorithm"] != "sha256" or index["order"] != "ascii-posix-path":
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )
    if _exact_integer(index["assetCount"]) != 90:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )
    dependency_counts = _exact_object(
        index["dependencyCounts"],
        (
            "externalRefs",
            "developmentDependencies",
            "absolutePath",
            "environmentPath",
            "repositoryPath",
        ),
    )
    expected_counts = {
        "externalRefs": 277,
        "developmentDependencies": 108,
        "absolutePath": 23,
        "environmentPath": 50,
        "repositoryPath": 35,
    }
    if dependency_counts != expected_counts:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )

    expected_categories = (
        "bottle-schema",
        "catalog",
        "fixtures",
        "patches",
        "probes",
        "dependencies",
    )
    expected_record_counts = (4, 19, 30, 11, 26, 385)
    shards = index["shards"]
    if type(shards) is not list or len(shards) != 6:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )
    for position, shard in enumerate(shards):
        _exact_object(shard, ("path", "sha256", "category", "recordCount"))
        expected_path = OUTPUT_RELATIVE_PATHS[position + 1]
        if (
            shard["path"] != expected_path
            or shard["category"] != expected_categories[position]
            or shard["recordCount"] != expected_record_counts[position]
            or type(shard["recordCount"]) is not int
            or type(shard["sha256"]) is not str
            or len(shard["sha256"]) != 64
        ):
            raise InventoryValidationError(
                "migration asset inventory document is invalid"
            )
        if hashlib.sha256(documents[expected_path]).hexdigest() != shard["sha256"]:
            raise InventoryValidationError(
                "migration asset inventory shard digest is invalid"
            )

    all_paths = []
    asset_locators = {"externalRefs": {}, "developmentDependencies": {}}
    for category, relative_path, expected_count in zip(
        expected_categories[:-1], OUTPUT_RELATIVE_PATHS[1:-1], expected_record_counts[:-1]
    ):
        shard = _exact_object(
            parsed[relative_path],
            (
                "schemaVersion",
                "repository",
                "sourceCommit",
                "sourceTag",
                "category",
                "assetCount",
                "assets",
            ),
        )
        _validate_identity(shard)
        if (
            shard["category"] != category
            or type(shard["assetCount"]) is not int
            or shard["assetCount"] != expected_count
            or type(shard["assets"]) is not list
            or len(shard["assets"]) != expected_count
        ):
            raise InventoryValidationError(
                "migration asset inventory document is invalid"
            )
        previous = None
        for asset in shard["assets"]:
            previous = _validate_asset(asset, category, previous)
            all_paths.append(asset["sourcePath"])
            for field in asset_locators:
                asset_locators[field][asset["sourcePath"]] = asset[field]
    if len(all_paths) != 90 or len(set(all_paths)) != 90:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )

    dependency = parsed["migration/assets/dependencies.json"]
    try:
        expanded = generator.expand_dependency_groups(dependency)
    except generator.InventoryError as error:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        ) from error
    actual_counts = generator._dependency_counts(expanded)
    if actual_counts != expected_counts:
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )
    governed = set(all_paths)
    if any(
        entry["sourcePath"] not in governed
        for field in expanded.values()
        for entry in field
    ):
        raise InventoryValidationError(
            "migration asset inventory document is invalid"
        )
    for field in asset_locators:
        expected_locators = {path: [] for path in all_paths}
        for entry in expanded[field]:
            expected_locators[entry["sourcePath"]].append(entry["locator"])
        for locators in expected_locators.values():
            locators.sort(key=lambda value: value.encode("utf-8"))
        if asset_locators[field] != expected_locators:
            raise InventoryValidationError(
                "migration asset inventory document is invalid"
            )

    if expected_documents is not None:
        if type(expected_documents) is not dict or tuple(expected_documents) != OUTPUT_RELATIVE_PATHS:
            raise InventoryValidationError(
                "migration asset inventory expected document set is invalid"
            )
        if documents != expected_documents:
            raise InventoryValidationError(
                "migration asset inventory does not match generated bytes"
            )
    return parsed


def _read_exact_worktree_bytes(repository_root, relative_path):
    """Read one reviewed file through the shared hardened bounded reader."""
    try:
        return generator._read_bounded_reviewed_file(
            repository_root, relative_path, MAX_DOCUMENT_BYTES
        )
    except generator.InventoryError as error:
        raise InventoryValidationError(
            "migration asset inventory reviewed file is invalid"
        ) from error


def _read_reviewed_document(repository_root, relative_path, expected):
    """Bind exact expected bytes to both worktree and stage-0 local Git blob."""
    worktree = _read_exact_worktree_bytes(repository_root, relative_path)
    try:
        object_id = _index_entry(repository_root, _reviewed_relative_path(relative_path))
        indexed = _read_index_document_bytes(repository_root, object_id)
    except (InventoryValidationError, generator.InventoryError) as error:
        raise InventoryValidationError(
            "migration asset inventory reviewed file is invalid"
        ) from error
    if worktree != expected or indexed != expected or worktree != indexed:
        raise InventoryValidationError(
            "migration asset inventory reviewed file is invalid"
        )
    return worktree


def _read_index_document_bytes(repository_root, object_id):
    """Bound an index blob at 64 KiB before reading or allocating its content."""
    try:
        if generator._run_git(
            repository_root, "cat-file", "-t", object_id
        ).stdout.strip() != b"blob":
            raise InventoryValidationError(
                "migration asset inventory reviewed file is invalid"
            )
        raw_size = generator._run_git(
            repository_root, "cat-file", "-s", object_id
        ).stdout.strip()
        if not raw_size or len(raw_size) > 20 or not raw_size.isdigit():
            raise InventoryValidationError(
                "migration asset inventory reviewed file is invalid"
            )
        if int(raw_size) > MAX_DOCUMENT_BYTES:
            raise InventoryValidationError(
                "migration asset inventory reviewed file is invalid"
            )
        raw = generator._read_blob(repository_root, object_id)
    except InventoryValidationError:
        raise
    except generator.InventoryError as error:
        raise InventoryValidationError(
            "migration asset inventory reviewed file is invalid"
        ) from error
    if len(raw) != int(raw_size):
        raise InventoryValidationError(
            "migration asset inventory reviewed file is invalid"
        )
    return raw


def _read_reviewed_policy(repository_root):
    """Bind the manual policy exactly to its worktree and stage-0 Git blob."""
    relative_path = generator.POLICY_PATH.relative_to(generator.ROOT).as_posix()
    worktree = _read_exact_worktree_bytes(repository_root, relative_path)
    try:
        object_id = _index_entry(
            repository_root, _reviewed_relative_path(relative_path)
        )
        indexed = _read_index_document_bytes(repository_root, object_id)
    except (
        generator.InventoryError,
        InventoryValidationError,
    ) as error:
        raise InventoryValidationError(
            "migration asset inventory reviewed policy is invalid"
        ) from error
    if worktree != indexed:
        raise InventoryValidationError(
            "migration asset inventory reviewed policy is invalid"
        )
    try:
        return generator.parse_policy_bytes(worktree)
    except generator.InventoryError as error:
        raise InventoryValidationError(
            "migration asset inventory reviewed policy is invalid"
        ) from error


def validate_inventory(repository_root=ROOT):
    """Regenerate in memory and verify exact reviewed worktree/index bytes."""
    try:
        generator._validate_primary_object_database(repository_root)
    except generator.InventoryError as error:
        raise InventoryValidationError(
            "migration asset inventory repository is unsafe"
        ) from error
    policy = _read_reviewed_policy(repository_root)
    try:
        expected = generate_inventory_documents(repository_root, policy=policy)
    except generator.InventoryError as error:
        raise InventoryValidationError(
            "migration asset inventory generation failed"
        ) from error
    actual = {
        path: _read_reviewed_document(repository_root, path, raw)
        for path, raw in expected.items()
    }
    validate_inventory_documents(actual, expected_documents=expected)
    return actual


class _StableArgumentParser(argparse.ArgumentParser):
    def error(self, _message):
        self.print_usage(sys.stderr)
        self.exit(2, f"{self.prog}: error: invalid command-line arguments\n")


def _argument_parser():
    return _StableArgumentParser(
        prog="validate_migration_asset_inventory.py",
        add_help=False,
        allow_abbrev=False,
    )


def main(arguments=()):
    _argument_parser().parse_args(arguments)
    try:
        validate_inventory(ROOT)
    except InventoryValidationError as error:
        print(f"migration asset inventory failed: {error}", file=sys.stderr)
        return 1
    print("Mac-Win migration asset inventory is valid.")
    return 0


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main(sys.argv[1:]))

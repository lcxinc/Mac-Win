"""Tests for the canonical migration asset inventory contract."""

import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from tools.generate_migration_asset_inventory import (
    InventoryError,
    MAX_DOCUMENT_BYTES,
    MAX_JSON_DEPTH,
    POLICY_PATH,
    parse_policy_bytes,
    validate_json_depth,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE_COMMIT = "db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527"
INVENTORY_DIRECTORY = ROOT / "migration" / "assets"
GENERATOR_PATH = ROOT / "tools" / "generate_migration_asset_inventory.py"
NATIVE_LINE_ENDING = os.linesep.encode("ascii")


class MigrationAssetInventoryEntrypointTests(unittest.TestCase):
    def test_frozen_contract_constants_are_stable(self):
        self.assertEqual(
            SOURCE_COMMIT,
            "db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527",
        )
        self.assertEqual(
            INVENTORY_DIRECTORY.relative_to(ROOT).as_posix(),
            "migration/assets",
        )

    def test_cli_accepts_only_an_empty_argument_list(self):
        expected_stderr = (
            b"usage: generate_migration_asset_inventory.py"
            + NATIVE_LINE_ENDING
            + b"generate_migration_asset_inventory.py: error: "
            + b"invalid command-line arguments"
            + NATIVE_LINE_ENDING
        )
        for arguments in (
            ("extra",),
            ("extra", "second"),
            ("--write",),
            ("--wri",),
            ("--",),
            ("-h",),
            ("hostile\nargument",),
        ):
            with self.subTest(arguments=arguments):
                result = subprocess.run(
                    [sys.executable, "-B", str(GENERATOR_PATH), *arguments],
                    cwd=ROOT,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 2)
                self.assertEqual(result.stdout, b"")
                self.assertEqual(result.stderr, expected_stderr)
                for argument in arguments:
                    self.assertNotIn(argument.encode("utf-8"), result.stderr)


class AssetPolicyTests(unittest.TestCase):
    def setUp(self):
        self.policy = {
            "schemaVersion": 1,
            "repository": "a1112/Mac-Win",
            "sourceCommit": SOURCE_COMMIT,
            "sourceTag": "mw-migration-baseline-db12d5e",
            "groups": [
                {
                    "category": "probes",
                    "kind": "probe",
                    "license": {"status": "unresolved"},
                    "provenance": {"status": "unresolved"},
                    "intendedOwner": "compatforge/probes",
                    "externalRefs": [],
                    "developmentDependencies": [],
                    "paths": ["scripts/example.sh"],
                }
            ],
            "dependencyPolicy": {
                "externalRefs": [],
                "developmentDependencies": [],
            },
        }

    def parse(self, policy=None):
        value = self.policy if policy is None else policy
        raw = json.dumps(value, ensure_ascii=True, separators=(",", ":")).encode(
            "ascii"
        )
        return parse_policy_bytes(raw)

    def assert_policy_error(self, expected, policy=None, raw=None):
        if raw is None:
            value = self.policy if policy is None else policy
            raw = json.dumps(value, ensure_ascii=True).encode("ascii")
        with self.assertRaisesRegex(InventoryError, f"^{expected}$"):
            parse_policy_bytes(raw)

    def policy_with_schema_integer(self, digits):
        raw = json.dumps(self.policy, ensure_ascii=True).encode("ascii")
        marker = b'"schemaVersion": 1'
        self.assertIn(marker, raw)
        return raw.replace(marker, b'"schemaVersion": ' + digits, 1)

    def test_accepts_the_closed_policy_shape(self):
        self.assertEqual(self.parse(), self.policy)

    def test_requires_exact_root_fields_and_frozen_identity(self):
        for field in self.policy:
            with self.subTest(missing=field):
                candidate = copy.deepcopy(self.policy)
                del candidate[field]
                self.assert_policy_error("inventory policy schema is invalid", candidate)

        candidate = copy.deepcopy(self.policy)
        candidate["hostile-unknown-key"] = "hostile-unknown-value"
        self.assert_policy_error("inventory policy schema is invalid", candidate)

        for field, replacement in (
            ("schemaVersion", 2),
            ("repository", "someone/else"),
            ("sourceCommit", "0" * 40),
            ("sourceTag", "moved-tag"),
        ):
            with self.subTest(field=field):
                candidate = copy.deepcopy(self.policy)
                candidate[field] = replacement
                self.assert_policy_error("inventory policy identity is invalid", candidate)

    def test_rejects_duplicate_keys_after_json_escape_decoding(self):
        self.assert_policy_error(
            "inventory document contains duplicate object keys",
            raw=b'{"groups":[],"groups":[]}',
        )
        self.assert_policy_error(
            "inventory document contains duplicate object keys",
            raw=b'{"groups":[],"gr\\u006fups":[]}',
        )

    def test_rejects_unknown_and_missing_group_fields_without_reflection(self):
        group = self.policy["groups"][0]
        for field in group:
            with self.subTest(missing=field):
                candidate = copy.deepcopy(self.policy)
                del candidate["groups"][0][field]
                self.assert_policy_error("inventory policy schema is invalid", candidate)

        candidate = copy.deepcopy(self.policy)
        candidate["groups"][0]["hostile\nkey"] = "hostile\nvalue"
        self.assert_policy_error("inventory policy schema is invalid", candidate)

    def test_rejects_type_substitution_including_bool_for_int(self):
        mutations = (
            ("schemaVersion", True),
            ("schemaVersion", 1.0),
            ("schemaVersion", "1"),
            ("repository", 1),
            ("groups", {}),
            ("dependencyPolicy", []),
        )
        for field, replacement in mutations:
            with self.subTest(field=field):
                candidate = copy.deepcopy(self.policy)
                candidate[field] = replacement
                self.assert_policy_error("inventory policy value type is invalid", candidate)

        for field, replacement in (
            ("category", 1),
            ("license", []),
            ("externalRefs", {}),
            ("paths", "scripts/example.sh"),
        ):
            with self.subTest(group_field=field):
                candidate = copy.deepcopy(self.policy)
                candidate["groups"][0][field] = replacement
                self.assert_policy_error("inventory policy value type is invalid", candidate)

    def test_rejects_non_utf8_oversized_and_deep_documents(self):
        self.assert_policy_error(
            "inventory document is not valid UTF-8", raw=b'{}\xff'
        )
        self.assert_policy_error(
            "inventory document exceeds the byte limit",
            raw=b" " * (MAX_DOCUMENT_BYTES + 1),
        )
        raw_at_limit = json.dumps(self.policy).encode("ascii")
        raw_at_limit += b" " * (MAX_DOCUMENT_BYTES - len(raw_at_limit))
        self.assertEqual(parse_policy_bytes(raw_at_limit), self.policy)
        self.assert_policy_error(
            "inventory document nesting exceeds the limit",
            raw=(b"[" * (MAX_JSON_DEPTH + 1)) + (b"]" * (MAX_JSON_DEPTH + 1)),
        )

        validate_json_depth("[" * MAX_JSON_DEPTH + "]" * MAX_JSON_DEPTH)

    def test_rejects_oversized_json_integer_with_stable_direct_error(self):
        self.assert_policy_error(
            "inventory document integer is invalid",
            raw=self.policy_with_schema_integer(b"9" * 129),
        )

    def test_rejects_oversized_json_integer_with_stable_cli_error(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            temporary_root = Path(temporary_directory)
            script = temporary_root / "tools" / GENERATOR_PATH.name
            policy = temporary_root / "migration" / "assets" / POLICY_PATH.name
            script.parent.mkdir(parents=True)
            policy.parent.mkdir(parents=True)
            shutil.copyfile(GENERATOR_PATH, script)
            policy.write_bytes(self.policy_with_schema_integer(b"9" * 129))

            result = subprocess.run(
                [sys.executable, "-B", str(script)],
                cwd=temporary_root,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, b"")
        self.assertEqual(
            result.stderr,
            b"migration asset inventory failed: "
            b"inventory document integer is invalid" + NATIVE_LINE_ENDING,
        )

    def test_rejects_unknown_enums(self):
        for field, replacement in (
            ("category", "unknown"),
            ("kind", "unknown"),
            ("intendedOwner", "person/account"),
        ):
            with self.subTest(field=field):
                candidate = copy.deepcopy(self.policy)
                candidate["groups"][0][field] = replacement
                self.assert_policy_error("inventory policy enum value is invalid", candidate)

        for field in ("license", "provenance"):
            with self.subTest(field=field):
                candidate = copy.deepcopy(self.policy)
                candidate["groups"][0][field]["status"] = "guessed"
                self.assert_policy_error("inventory policy enum value is invalid", candidate)

    def test_enforces_closed_category_owner_combinations(self):
        category_contract = {
            "catalog": ("catalog-record", {"compatforge/catalog"}),
            "patches": (
                "source-patch",
                {"compatforge/patches", "quarantine/unresolved"},
            ),
            "probes": (
                "probe",
                {"compatforge/probes", "macwin/archive"},
            ),
            "fixtures": ("test-fixture", {"compatforge/probes"}),
            "bottle-schema": (
                "bottle-schema",
                {"compatforge/bottle-schema"},
            ),
        }
        all_owners = {
            owner
            for _kind, owners in category_contract.values()
            for owner in owners
        }
        for category, (kind, allowed_owners) in category_contract.items():
            for owner in all_owners:
                with self.subTest(category=category, owner=owner):
                    candidate = copy.deepcopy(self.policy)
                    group = candidate["groups"][0]
                    group["category"] = category
                    group["kind"] = kind
                    group["intendedOwner"] = owner
                    if owner in allowed_owners:
                        self.assertEqual(self.parse(candidate), candidate)
                    else:
                        self.assert_policy_error(
                            "inventory policy enum value is invalid", candidate
                        )

    def test_enforces_closed_development_kind_status_combinations(self):
        kind_contract = {
            "absolute-path": "development-machine-only",
            "environment-path": "unexpanded",
            "repository-path": "not-in-baseline",
        }
        all_statuses = set(kind_contract.values())
        for kind, allowed_status in kind_contract.items():
            for status in all_statuses:
                with self.subTest(kind=kind, status=status):
                    candidate = copy.deepcopy(self.policy)
                    candidate["dependencyPolicy"]["developmentDependencies"] = [
                        {
                            "sourcePath": "scripts/example.sh",
                            "locator": "reviewed-locator",
                            "kind": kind,
                            "status": status,
                        }
                    ]
                    if status == allowed_status:
                        self.assertEqual(self.parse(candidate), candidate)
                    else:
                        self.assert_policy_error(
                            "inventory policy enum value is invalid", candidate
                        )

    def test_rejects_invalid_duplicate_and_case_colliding_paths(self):
        invalid_paths = (
            "",
            "/absolute",
            "C:/drive",
            "https://example.invalid/a",
            "scripts\\probe.sh",
            "scripts//probe.sh",
            "scripts/./probe.sh",
            "scripts/../probe.sh",
            "scripts/probe\x00.sh",
            "scripts/control\x1f.sh",
            "scripts/delete\x7f.sh",
            "scripts/caf\N{LATIN SMALL LETTER E WITH ACUTE}.sh",
        )
        for path in invalid_paths:
            with self.subTest(path=repr(path)):
                candidate = copy.deepcopy(self.policy)
                candidate["groups"][0]["paths"] = [path]
                self.assert_policy_error("inventory policy path is invalid", candidate)

        candidate = copy.deepcopy(self.policy)
        candidate["groups"][0]["paths"] = [
            "scripts/one.sh",
            "scripts/one.sh",
        ]
        self.assert_policy_error("inventory policy path is duplicated", candidate)

        candidate = copy.deepcopy(self.policy)
        candidate["groups"].append(copy.deepcopy(candidate["groups"][0]))
        candidate["groups"][1]["paths"] = ["Scripts/Example.sh"]
        self.assert_policy_error(
            "inventory policy path has a case-fold collision", candidate
        )

    def test_rejects_control_and_surrogate_reviewed_strings(self):
        for hostile in ("\x00", "\x1f", "\x7f", "\u0085", "\ud800"):
            with self.subTest(reviewed_string=ascii(hostile)):
                candidate = copy.deepcopy(self.policy)
                candidate["groups"][0]["intendedOwner"] = hostile
                self.assert_policy_error("inventory policy string is invalid", candidate)

            with self.subTest(group_reference=ascii(hostile)):
                candidate = copy.deepcopy(self.policy)
                candidate["groups"][0]["externalRefs"] = [hostile]
                self.assert_policy_error(
                    "inventory policy dependency reference is invalid", candidate
                )

            with self.subTest(locator=ascii(hostile)):
                candidate = copy.deepcopy(self.policy)
                candidate["dependencyPolicy"]["externalRefs"] = [
                    {
                        "sourcePath": "scripts/example.sh",
                        "locator": hostile,
                        "kind": "url",
                        "status": "external-unverified",
                    }
                ]
                self.assert_policy_error(
                    "inventory policy dependency is invalid", candidate
                )

    def test_rejects_hidden_format_controls_in_refs_and_locators(self):
        for hostile in ("\u202e", "\u2066", "\u200b", "\ufeff"):
            for ensure_ascii in (False, True):
                representation = "escaped" if ensure_ascii else "direct"
                with self.subTest(
                    group_reference=ascii(hostile), representation=representation
                ):
                    candidate = copy.deepcopy(self.policy)
                    candidate["groups"][0]["externalRefs"] = [hostile]
                    raw = json.dumps(candidate, ensure_ascii=ensure_ascii).encode(
                        "utf-8"
                    )
                    self.assert_policy_error(
                        "inventory policy dependency reference is invalid", raw=raw
                    )

                with self.subTest(
                    locator=ascii(hostile), representation=representation
                ):
                    candidate = copy.deepcopy(self.policy)
                    candidate["dependencyPolicy"]["externalRefs"] = [
                        {
                            "sourcePath": "scripts/example.sh",
                            "locator": hostile,
                            "kind": "url",
                            "status": "external-unverified",
                        }
                    ]
                    raw = json.dumps(candidate, ensure_ascii=ensure_ascii).encode(
                        "utf-8"
                    )
                    self.assert_policy_error(
                        "inventory policy dependency is invalid", raw=raw
                    )

    def test_accepts_supplementary_unicode_in_reviewed_locators(self):
        locator = "https://example.invalid/\N{GRINNING FACE}"
        candidate = copy.deepcopy(self.policy)
        candidate["groups"][0]["externalRefs"] = [locator]
        candidate["dependencyPolicy"]["externalRefs"] = [
            {
                "sourcePath": "scripts/example.sh",
                "locator": locator,
                "kind": "url",
                "status": "external-unverified",
            }
        ]
        self.assertEqual(self.parse(candidate), candidate)

    def test_requires_closed_tagged_unions_and_dependency_policy(self):
        for field in ("license", "provenance"):
            candidate = copy.deepcopy(self.policy)
            candidate["groups"][0][field]["extra"] = "not-allowed"
            self.assert_policy_error("inventory policy schema is invalid", candidate)

        candidate = copy.deepcopy(self.policy)
        candidate["dependencyPolicy"]["extra"] = []
        self.assert_policy_error("inventory policy schema is invalid", candidate)

        candidate = copy.deepcopy(self.policy)
        candidate["dependencyPolicy"]["externalRefs"] = [
            {
                "sourcePath": "scripts/example.sh",
                "locator": "https://example.invalid/file",
                "kind": "url",
                "status": "external-unverified",
            }
        ]
        self.assertEqual(self.parse(candidate), candidate)

        dependency = candidate["dependencyPolicy"]["externalRefs"][0]
        for field in dependency:
            with self.subTest(dependency_missing=field):
                missing = copy.deepcopy(candidate)
                del missing["dependencyPolicy"]["externalRefs"][0][field]
                self.assert_policy_error("inventory policy schema is invalid", missing)

        dependency["extra"] = True
        self.assert_policy_error("inventory policy schema is invalid", candidate)

    def test_committed_policy_has_all_approved_assets(self):
        self.assertEqual(POLICY_PATH, INVENTORY_DIRECTORY / "metadata-policy.json")
        policy = parse_policy_bytes(POLICY_PATH.read_bytes())
        paths_by_category = {}
        for group in policy["groups"]:
            paths_by_category.setdefault(group["category"], []).extend(group["paths"])
            self.assertIn("externalRefs", group)
            self.assertIn("developmentDependencies", group)

        self.assertEqual(
            {category: len(paths) for category, paths in paths_by_category.items()},
            {
                "catalog": 19,
                "patches": 11,
                "probes": 26,
                "fixtures": 30,
                "bottle-schema": 4,
            },
        )
        all_paths = [path for paths in paths_by_category.values() for path in paths]
        self.assertEqual(len(all_paths), 90)
        self.assertEqual(len(set(all_paths)), 90)
        owners_by_category = {
            category: {group["intendedOwner"] for group in policy["groups"]
                       if group["category"] == category}
            for category in paths_by_category
        }
        self.assertEqual(owners_by_category["catalog"], {"compatforge/catalog"})
        self.assertLessEqual(
            owners_by_category["patches"],
            {"compatforge/patches", "quarantine/unresolved"},
        )
        self.assertLessEqual(
            owners_by_category["probes"],
            {"compatforge/probes", "macwin/archive"},
        )
        self.assertEqual(owners_by_category["fixtures"], {"compatforge/probes"})
        self.assertEqual(
            owners_by_category["bottle-schema"],
            {"compatforge/bottle-schema"},
        )


if __name__ == "__main__":
    unittest.main()

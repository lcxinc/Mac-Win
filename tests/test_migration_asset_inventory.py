"""Tests for the canonical migration asset inventory contract."""

import copy
import json
from pathlib import Path
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

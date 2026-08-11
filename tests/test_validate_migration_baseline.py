import copy
import importlib.util
import json
from pathlib import Path
import re
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
VALIDATOR_PATH = ROOT / "tools" / "validate_migration_baseline.py"
MANIFEST_PATH = ROOT / "migration" / "baseline.json"

CANONICAL = {
    "schemaVersion": 1,
    "repository": "a1112/Mac-Win",
    "sourceCommit": "4e421fbea6f59e73e4f813c1f0a14e8db9e36de7",
    "tag": "mw-migration-baseline-4e421fb",
    "swiftPackagePath": "MacWinManager",
    "evidenceTargets": [
        {"runner": "macos-15", "architecture": "arm64"},
        {"runner": "macos-15-intel", "architecture": "x86_64"},
    ],
    "frozenFeatureAreas": ["SwiftUI", "Bridge", "legacy-launcher"],
}


def load_validator():
    if not VALIDATOR_PATH.is_file():
        raise AssertionError(f"validator is missing: {VALIDATOR_PATH}")

    spec = importlib.util.spec_from_file_location(
        "validate_migration_baseline", VALIDATOR_PATH
    )
    if spec is None or spec.loader is None:
        raise AssertionError("validator module could not be loaded")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class MigrationBaselineManifestTests(unittest.TestCase):
    def assertInvalid(self, manifest, diagnostic):
        validator = load_validator()
        with self.assertRaisesRegex(
            validator.BaselineValidationError, f"^{re.escape(diagnostic)}$"
        ):
            validator.validate_manifest(manifest)

    def assertRawInvalid(self, raw, diagnostic):
        validator = load_validator()
        with self.assertRaisesRegex(
            validator.BaselineValidationError, f"^{re.escape(diagnostic)}$"
        ):
            validator.parse_manifest_bytes(raw)

    def test_validator_module_exists(self):
        self.assertTrue(VALIDATOR_PATH.is_file(), "validator module is missing")

    def test_accepts_exact_canonical_manifest_object(self):
        validator = load_validator()
        validator.validate_manifest(copy.deepcopy(CANONICAL))

    def test_manifest_file_is_exact_canonical_serialization(self):
        self.assertTrue(MANIFEST_PATH.is_file(), "canonical manifest is missing")
        expected = (json.dumps(CANONICAL, indent=2) + "\n").encode("utf-8")
        self.assertEqual(MANIFEST_PATH.read_bytes(), expected)

        validator = load_validator()
        self.assertEqual(validator.load_manifest(MANIFEST_PATH), CANONICAL)

    def test_rejects_non_object_top_level_value(self):
        self.assertInvalid([], "manifest must be a JSON object")

    def test_rejects_unknown_top_level_field(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["unexpected"] = True
        self.assertInvalid(mutated, "manifest has unknown field: unexpected")

    def test_rejects_each_missing_top_level_field(self):
        for field in CANONICAL:
            with self.subTest(field=field):
                mutated = copy.deepcopy(CANONICAL)
                del mutated[field]
                self.assertInvalid(mutated, f"manifest is missing field: {field}")

    def test_rejects_bool_float_and_string_schema_versions(self):
        for value in (True, 1.0, "1"):
            with self.subTest(value=value):
                mutated = copy.deepcopy(CANONICAL)
                mutated["schemaVersion"] = value
                self.assertInvalid(mutated, "schemaVersion must be integer 1")

    def test_rejects_wrong_repository(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["repository"] = "a1112/Other"
        self.assertInvalid(mutated, "repository must equal a1112/Mac-Win")

    def test_rejects_malformed_source_commits(self):
        malformed = {
            "short": "4e421fb",
            "uppercase": "4E421FBEA6F59E73E4F813C1F0A14E8DB9E36DE7",
            "nonhex": "ge421fbea6f59e73e4f813c1f0a14e8db9e36de7",
        }
        for name, value in malformed.items():
            with self.subTest(name=name):
                mutated = copy.deepcopy(CANONICAL)
                mutated["sourceCommit"] = value
                self.assertInvalid(
                    mutated,
                    "sourceCommit must be a 40-character lowercase hexadecimal commit",
                )

    def test_rejects_well_formed_but_wrong_source_commit(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["sourceCommit"] = "0" * 40
        self.assertInvalid(
            mutated,
            "sourceCommit must equal 4e421fbea6f59e73e4f813c1f0a14e8db9e36de7",
        )

    def test_rejects_wrong_tag(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["tag"] = "mw-migration-baseline-other"
        self.assertInvalid(
            mutated, "tag must equal mw-migration-baseline-4e421fb"
        )

    def test_rejects_unsafe_and_wrong_package_paths(self):
        paths = (
            "OtherPackage",
            "../MacWinManager",
            "/MacWinManager",
            "MacWinManager/../Other",
            r"MacWinManager\Other",
        )
        for path in paths:
            with self.subTest(path=path):
                mutated = copy.deepcopy(CANONICAL)
                mutated["swiftPackagePath"] = path
                self.assertInvalid(
                    mutated, "swiftPackagePath must equal MacWinManager"
                )

    def test_rejects_missing_evidence_target(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["evidenceTargets"] = mutated["evidenceTargets"][:1]
        self.assertInvalid(
            mutated,
            "evidenceTargets must exactly equal the reviewed runner sequence",
        )

    def test_rejects_duplicate_evidence_target(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["evidenceTargets"] = [
            copy.deepcopy(mutated["evidenceTargets"][0]),
            copy.deepcopy(mutated["evidenceTargets"][0]),
        ]
        self.assertInvalid(
            mutated,
            "evidenceTargets must exactly equal the reviewed runner sequence",
        )

    def test_rejects_reordered_evidence_targets(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["evidenceTargets"].reverse()
        self.assertInvalid(
            mutated,
            "evidenceTargets must exactly equal the reviewed runner sequence",
        )

    def test_rejects_unexpected_evidence_target(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["evidenceTargets"][1] = {
            "runner": "macos-14",
            "architecture": "x86_64",
        }
        self.assertInvalid(
            mutated,
            "evidenceTargets must exactly equal the reviewed runner sequence",
        )

    def test_rejects_missing_frozen_feature_area(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["frozenFeatureAreas"] = mutated["frozenFeatureAreas"][:2]
        self.assertInvalid(
            mutated,
            "frozenFeatureAreas must exactly equal the reviewed freeze sequence",
        )

    def test_rejects_duplicate_frozen_feature_area(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["frozenFeatureAreas"] = ["SwiftUI", "Bridge", "Bridge"]
        self.assertInvalid(
            mutated,
            "frozenFeatureAreas must exactly equal the reviewed freeze sequence",
        )

    def test_rejects_reordered_frozen_feature_areas(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["frozenFeatureAreas"] = [
            "Bridge",
            "SwiftUI",
            "legacy-launcher",
        ]
        self.assertInvalid(
            mutated,
            "frozenFeatureAreas must exactly equal the reviewed freeze sequence",
        )

    def test_rejects_unexpected_frozen_feature_area(self):
        mutated = copy.deepcopy(CANONICAL)
        mutated["frozenFeatureAreas"][2] = "launcher"
        self.assertInvalid(
            mutated,
            "frozenFeatureAreas must exactly equal the reviewed freeze sequence",
        )

    def test_rejects_duplicate_raw_json_keys(self):
        self.assertRawInvalid(
            b'{"schemaVersion":1,"schemaVersion":1}',
            "duplicate JSON key: schemaVersion",
        )

    def test_rejects_unicode_escaped_duplicate_json_keys(self):
        self.assertRawInvalid(
            b'{"repository":"a1112/Mac-Win","repos\\u0069tory":"other"}',
            "duplicate JSON key: repository",
        )

    def test_rejects_duplicate_nested_json_keys(self):
        self.assertRawInvalid(
            b'{"evidenceTargets":[{"runner":"macos-15","runn\\u0065r":"other"}]}',
            "duplicate JSON key: runner",
        )

    def test_accepts_exactly_65536_bytes(self):
        validator = load_validator()
        raw = json.dumps(CANONICAL, separators=(",", ":")).encode("utf-8")
        raw += b" " * (validator.MAX_MANIFEST_BYTES - len(raw))
        self.assertEqual(len(raw), 65_536)

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "baseline.json"
            path.write_bytes(raw)
            self.assertEqual(validator.load_manifest(path), CANONICAL)

    def test_rejects_65537_bytes_before_json_allocation(self):
        validator = load_validator()
        raw = json.dumps(CANONICAL, separators=(",", ":")).encode("utf-8")
        raw += b" " * (validator.MAX_MANIFEST_BYTES + 1 - len(raw))
        self.assertEqual(len(raw), 65_537)

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "baseline.json"
            path.write_bytes(raw)
            with self.assertRaisesRegex(
                validator.BaselineValidationError,
                "^manifest exceeds 65536-byte limit$",
            ):
                validator.load_manifest(path)

    def test_rejects_invalid_utf8(self):
        self.assertRawInvalid(b"{\"schemaVersion\":\xff}", "manifest is not valid UTF-8")

    def test_rejects_invalid_json(self):
        self.assertRawInvalid(b"{", "manifest is not valid JSON")


if __name__ == "__main__":
    unittest.main()

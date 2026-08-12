"""Tests for the canonical migration asset inventory contract."""

import copy
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
import tempfile
import unittest
import importlib.util
from unittest import mock
import zlib

import tools.generate_migration_asset_inventory as generator

from tools.generate_migration_asset_inventory import (
    MAX_ASSET_BYTES,
    InventoryError,
    MAX_DOCUMENT_BYTES,
    MAX_JSON_DEPTH,
    POLICY_PATH,
    _bind_governed_assets,
    _git_environment,
    _read_blob,
    _run_git,
    parse_policy_bytes,
    validate_json_depth,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE_COMMIT = "db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527"
SOURCE_TAG_MESSAGE = "Mac-Win migration source baseline db12d5e"
INVENTORY_DIRECTORY = ROOT / "migration" / "assets"
GENERATOR_PATH = ROOT / "tools" / "generate_migration_asset_inventory.py"
VALIDATOR_PATH = ROOT / "tools" / "validate_migration_asset_inventory.py"
NATIVE_LINE_ENDING = os.linesep.encode("ascii")
OUTPUT_RELATIVE_PATHS = (
    "migration/assets/index.json",
    "migration/assets/bottle-schema.json",
    "migration/assets/catalog.json",
    "migration/assets/fixtures.json",
    "migration/assets/patches.json",
    "migration/assets/probes.json",
    "migration/assets/dependencies.json",
)


def load_inventory_validator():
    spec = importlib.util.spec_from_file_location(
        "validate_migration_asset_inventory", VALIDATOR_PATH
    )
    if spec is None or spec.loader is None:
        raise AssertionError("inventory validator could not be loaded")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _fixture_git_environment(source=None):
    """Copy process facilities without inheriting Git repository/config state."""
    environment = dict(os.environ if source is None else source)
    for key in tuple(environment):
        if key.upper().startswith("GIT_"):
            del environment[key]
    environment.update(
        {
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_TERMINAL_PROMPT": "0",
        }
    )
    return environment


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

    def test_cli_rejects_arguments_outside_the_closed_interface(self):
        expected_stderr = (
            b"usage: generate_migration_asset_inventory.py "
            b"[--list | --check | --write]"
            + NATIVE_LINE_ENDING
            + b"generate_migration_asset_inventory.py: error: "
            + b"invalid command-line arguments"
            + NATIVE_LINE_ENDING
        )
        for arguments in (
            ("extra",),
            ("extra", "second"),
            ("--wri",),
            ("--check", "--write"),
            ("--list", "--write"),
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
                for hostile_value in (b"extra", b"second", b"hostile"):
                    self.assertNotIn(hostile_value, result.stderr)

    def test_list_cli_reports_the_frozen_category_counts(self):
        result = subprocess.run(
            [sys.executable, "-B", str(GENERATOR_PATH), "--list"],
            cwd=ROOT,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stderr, b"")
        lines = result.stdout.decode("utf-8").splitlines()
        self.assertEqual(
            lines[0],
            "Mac-Win migration assets: 90 "
            "(bottle-schema=4, catalog=19, fixtures=30, patches=11, probes=26)",
        )
        self.assertEqual(len(lines), 91)


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
                            "kind": kind,
                            "status": status,
                            "locators": [
                                {
                                    "absolute-path": "/Users/a1-6/reviewed-locator",
                                    "environment-path": "MACWIN_APP_PATH",
                                    "repository-path": "refs/reviewed-locator",
                                }[kind]
                            ],
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
                        "kind": "url",
                        "status": "external-unverified",
                        "locators": [hostile],
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
                            "kind": "url",
                            "status": "external-unverified",
                            "locators": [hostile],
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
                "kind": "url",
                "status": "external-unverified",
                "locators": [locator],
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
                "kind": "url",
                "status": "external-unverified",
                "locators": ["https://example.invalid/file"],
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


class AssetDependencyTests(unittest.TestCase):
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
                "externalRefs": [
                    {
                        "sourcePath": "scripts/example.sh",
                        "kind": "url",
                        "status": "external-unverified",
                        "locators": ["https://example.invalid/archive.zip"],
                    }
                ],
                "developmentDependencies": [
                    {
                        "sourcePath": "scripts/example.sh",
                        "kind": "absolute-path",
                        "status": "development-machine-only",
                        "locators": ["/Users/a1-6/project/Mac-Win/refs/tool.exe"],
                    },
                    {
                        "sourcePath": "scripts/example.sh",
                        "kind": "environment-path",
                        "status": "unexpanded",
                        "locators": [
                            "$HOME/Desktop/MacWinVisualAcceptance",
                            "MACWIN_JASP_CONAN_HOME",
                        ],
                    },
                    {
                        "sourcePath": "scripts/example.sh",
                        "kind": "repository-path",
                        "status": "not-in-baseline",
                        "locators": ["$PROJECT_ROOT/refs/exe-tests/bin/probe.exe"],
                    },
                ],
            },
        }

    def parse(self, policy=None):
        value = self.policy if policy is None else policy
        return parse_policy_bytes(
            json.dumps(value, ensure_ascii=True, separators=(",", ":")).encode(
                "ascii"
            )
        )

    def assert_policy_error(self, message, policy):
        with self.assertRaisesRegex(InventoryError, f"^{message}$"):
            self.parse(policy)

    def test_policy_uses_closed_source_grouped_dependency_records(self):
        parsed = self.parse()
        evidence = generator._dependency_policy_evidence(parsed)
        self.assertEqual(len(evidence["externalRefs"]), 1)
        self.assertEqual(len(evidence["developmentDependencies"]), 4)
        self.assertEqual(
            evidence["externalRefs"][0],
            {
                "sourcePath": "scripts/example.sh",
                "locator": "https://example.invalid/archive.zip",
                "kind": "url",
                "status": "external-unverified",
            },
        )

    def test_policy_rejects_legacy_empty_unknown_and_unsorted_dependency_groups(self):
        legacy = copy.deepcopy(self.policy)
        legacy["dependencyPolicy"]["externalRefs"][0] = {
            "sourcePath": "scripts/example.sh",
            "locator": "https://example.invalid/archive.zip",
            "kind": "url",
            "status": "external-unverified",
        }
        self.assert_policy_error("inventory policy schema is invalid", legacy)

        for mutation in ("empty", "unknown", "unsorted"):
            with self.subTest(mutation=mutation):
                candidate = copy.deepcopy(self.policy)
                group = candidate["dependencyPolicy"]["externalRefs"][0]
                if mutation == "empty":
                    group["locators"] = []
                elif mutation == "unknown":
                    group["extra"] = True
                else:
                    group["locators"] = [
                        "https://z.example.invalid/file",
                        "https://a.example.invalid/file",
                    ]
                expected = (
                    "inventory policy schema is invalid"
                    if mutation == "unknown"
                    else "inventory policy dependency is invalid"
                )
                self.assert_policy_error(expected, candidate)

    def test_policy_rejects_duplicate_casefold_and_mixed_kind_status_locators(self):
        mutations = []
        duplicate = copy.deepcopy(self.policy)
        duplicate["dependencyPolicy"]["externalRefs"][0]["locators"] *= 2
        mutations.append(("inventory policy dependency is duplicated", duplicate))

        casefolded = copy.deepcopy(self.policy)
        casefolded["dependencyPolicy"]["externalRefs"][0]["locators"] = [
            "https://EXAMPLE.invalid/archive.zip",
            "https://example.invalid/archive.zip",
        ]
        mutations.append(
            ("inventory policy dependency has a case-fold collision", casefolded)
        )

        mixed = copy.deepcopy(self.policy)
        mixed["dependencyPolicy"]["developmentDependencies"][0]["status"] = (
            "unexpanded"
        )
        mutations.append(("inventory policy enum value is invalid", mixed))

        for message, candidate in mutations:
            with self.subTest(message=message):
                self.assert_policy_error(message, candidate)

    def test_policy_rejects_malformed_and_case_mutated_locator_shapes(self):
        mutations = (
            ("externalRefs", 0, "HTTPS://example.invalid/file"),
            ("externalRefs", 0, "https://example.invalid/file|command"),
            ("developmentDependencies", 0, "/tmp/not-reviewed"),
            ("developmentDependencies", 1, "$HOME"),
            ("developmentDependencies", 1, "MACWIN_UNKNOWN_PATH"),
            ("developmentDependencies", 2, "$PROJECT_ROOT/not-refs/input"),
        )
        for field, index, locator in mutations:
            with self.subTest(field=field, locator=locator):
                candidate = copy.deepcopy(self.policy)
                candidate["dependencyPolicy"][field][index]["locators"] = [
                    locator
                ]
                self.assert_policy_error(
                    "inventory policy dependency is invalid", candidate
                )

    def test_policy_rejects_duplicate_and_unsorted_source_groups(self):
        duplicate = copy.deepcopy(self.policy)
        duplicate["dependencyPolicy"]["externalRefs"].append(
            copy.deepcopy(duplicate["dependencyPolicy"]["externalRefs"][0])
        )
        self.assert_policy_error(
            "inventory policy dependency is duplicated", duplicate
        )

        unsorted = copy.deepcopy(self.policy)
        unsorted["dependencyPolicy"]["developmentDependencies"].reverse()
        self.assert_policy_error("inventory policy dependency is invalid", unsorted)

    def test_extracts_literal_dependencies_from_one_bounded_frozen_blob(self):
        raw = (
            b"https://example.invalid/archive.zip "
            b"https://example.invalid/archive.zip\n"
            b"https://zlib\\.net/fossils/zlib-1\\.2\\.13\\.tar\\.gz|ignored\n"
            b"/Users/a1-6/project/Mac-Win/refs/tool.exe\n"
            b"$PROJECT_ROOT/refs/exe-tests/bin/probe.exe\n"
            b"$HOME/Desktop/MacWinVisualAcceptance\n"
            b"${MACWIN_JASP_CONAN_HOME:-$PROJECT_ROOT/tmp/jasp-conan-home}\n"
            b"${MACWIN_WINE_BUILD_DIR:-$ROOT_DIR/refs/wine-build}\n"
        )
        evidence = generator._extract_blob_dependency_evidence(
            "scripts/example.sh", raw
        )
        self.assertEqual(
            evidence["externalRefs"],
            [
                {
                    "sourcePath": "scripts/example.sh",
                    "locator": "https://example.invalid/archive.zip",
                    "kind": "url",
                    "status": "external-unverified",
                },
                {
                    "sourcePath": "scripts/example.sh",
                    "locator": "https://zlib\\.net/fossils/zlib-1\\.2\\.13\\.tar\\.gz",
                    "kind": "url",
                    "status": "external-unverified",
                },
            ],
        )
        self.assertEqual(
            {
                (entry["kind"], entry["locator"])
                for entry in evidence["developmentDependencies"]
            },
            {
                (
                    "absolute-path",
                    "/Users/a1-6/project/Mac-Win/refs/tool.exe",
                ),
                ("environment-path", "$HOME/Desktop/MacWinVisualAcceptance"),
                ("environment-path", "MACWIN_JASP_CONAN_HOME"),
                ("environment-path", "MACWIN_WINE_BUILD_DIR"),
                (
                    "repository-path",
                    "$PROJECT_ROOT/refs/exe-tests/bin/probe.exe",
                ),
                ("repository-path", "$ROOT_DIR/refs/wine-build"),
            },
        )

    def test_dependency_extraction_is_pure_and_does_not_probe_external_state(self):
        raw = b"https://example.invalid/a $HOME/Desktop/a refs/missing/input\n"
        with mock.patch("socket.socket", side_effect=AssertionError("network")), mock.patch.object(
            generator.subprocess,
            "run",
            side_effect=AssertionError("asset execution"),
        ), mock.patch.object(
            generator.Path,
            "exists",
            side_effect=AssertionError("path probe"),
        ), mock.patch(
            "builtins.open",
            side_effect=AssertionError("Bottle read"),
        ):
            evidence = generator._extract_blob_dependency_evidence(
                "scripts/example.sh", raw
            )
        self.assertEqual(len(evidence["externalRefs"]), 1)
        self.assertEqual(len(evidence["developmentDependencies"]), 2)

    def test_frozen_blob_evidence_must_match_policy_exactly(self):
        records = [{"sourcePath": "scripts/example.sh", "gitBlobOid": "1" * 40}]
        raw = (
            b"https://example.invalid/archive.zip\n"
            b"/Users/a1-6/project/Mac-Win/refs/tool.exe\n"
            b"$PROJECT_ROOT/refs/exe-tests/bin/probe.exe\n"
            b"$HOME/Desktop/MacWinVisualAcceptance\n"
            b"MACWIN_JASP_CONAN_HOME\n"
        )
        with mock.patch.object(generator, "_read_blob", return_value=raw) as read_blob:
            evidence = generator._extract_dependency_evidence(ROOT, records)
        read_blob.assert_called_once_with(ROOT, "1" * 40)
        generator._require_dependency_policy_match(self.policy, evidence)

        mutations = (
            ("missing", lambda value: value["externalRefs"].clear()),
            (
                "extra",
                lambda value: value["externalRefs"].append(
                    {
                        "sourcePath": "scripts/example.sh",
                        "locator": "https://extra.invalid/file",
                        "kind": "url",
                        "status": "external-unverified",
                    }
                ),
            ),
            (
                "changed-case",
                lambda value: value["externalRefs"][0].update(
                    locator="https://EXAMPLE.invalid/archive.zip"
                ),
            ),
        )
        for name, mutate in mutations:
            with self.subTest(name=name):
                candidate = copy.deepcopy(evidence)
                mutate(candidate)
                with self.assertRaisesRegex(
                    InventoryError,
                    "^inventory dependency evidence does not match policy$",
                ):
                    generator._require_dependency_policy_match(
                        self.policy, candidate
                    )

    def test_rejects_unbounded_and_non_utf8_dependency_sources(self):
        for raw in (b"x" * (MAX_ASSET_BYTES + 1), b"\xff"):
            with self.subTest(length=len(raw)):
                with self.assertRaisesRegex(
                    InventoryError, "^inventory dependency source is invalid$"
                ):
                    generator._extract_blob_dependency_evidence(
                        "scripts/example.sh", raw
                    )

    def test_real_frozen_evidence_has_exact_reviewed_counts_and_policy_coverage(self):
        policy = parse_policy_bytes(POLICY_PATH.read_bytes())
        records = _bind_governed_assets(
            ROOT,
            policy,
            SOURCE_COMMIT,
            "mw-migration-baseline-db12d5e",
        )
        evidence = generator._extract_dependency_evidence(ROOT, records)
        external = evidence["externalRefs"]
        development = evidence["developmentDependencies"]

        self.assertEqual(len(external), 277)
        self.assertEqual(len({entry["locator"] for entry in external}), 269)
        self.assertEqual(
            sum(
                entry["sourcePath"] == "scripts/download-software-samples.sh"
                for entry in external
            ),
            234,
        )
        self.assertEqual(
            {
                kind: sum(entry["kind"] == kind for entry in development)
                for kind in (
                    "absolute-path",
                    "environment-path",
                    "repository-path",
                )
            },
            {
                "absolute-path": 23,
                "environment-path": 50,
                "repository-path": 35,
            },
        )
        self.assertIn(
            {
                "sourcePath": "scripts/run-software-smoke.sh",
                "locator": "MACWIN_WINE_MONO_MSI",
                "kind": "environment-path",
                "status": "unexpanded",
            },
            development,
        )
        absolute = [
            entry for entry in development if entry["kind"] == "absolute-path"
        ]
        self.assertEqual(len({entry["locator"] for entry in absolute}), 17)
        generator._require_dependency_policy_match(policy, evidence)

    def test_list_cli_validates_frozen_dependency_evidence_before_reporting(self):
        records = [
            {
                "sourcePath": "scripts/example.sh",
                "category": "probes",
                "gitBlobOid": "1" * 40,
            }
        ]
        evidence = {"externalRefs": [], "developmentDependencies": []}
        with mock.patch.object(generator, "load_policy", return_value=self.policy), mock.patch.object(
            generator, "_bind_governed_assets", return_value=records
        ), mock.patch.object(
            generator, "_extract_dependency_evidence", return_value=evidence
        ) as extract, mock.patch.object(
            generator, "_require_dependency_policy_match"
        ) as require_match, mock.patch(
            "builtins.print"
        ):
            self.assertEqual(generator.main(["--list"]), 0)
        extract.assert_called_once_with(ROOT, records)
        require_match.assert_called_once_with(self.policy, evidence)


class AssetGitBindingTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory(
            prefix="Mac Win inventory [git] "
        )
        self.repository = Path(self.temporary_directory.name).resolve()
        self._fixture_git("init", "-q", "--initial-branch=main")
        self._fixture_git("config", "user.name", "Inventory Tests")
        self._fixture_git("config", "user.email", "inventory@example.invalid")
        self.asset_path = "scripts/example.sh"
        asset = self.repository / self.asset_path
        asset.parent.mkdir(parents=True)
        asset.write_bytes(b"#!/bin/sh\nprintf frozen\\n")
        self._fixture_git("add", "--", self.asset_path)
        self._fixture_git("commit", "-q", "-m", "source")
        self.source_commit = self._fixture_git("rev-parse", "HEAD").stdout.strip()
        self._fixture_git(
            "tag", "-a", "frozen-source", "-m", SOURCE_TAG_MESSAGE, self.source_commit
        )
        self.policy = self._policy([self.asset_path])

    def tearDown(self):
        self.temporary_directory.cleanup()

    def _fixture_git(self, *arguments, check=True, input_bytes=None):
        hooks_directory = self.repository / ".fixture-empty-hooks"
        hooks_directory.mkdir(exist_ok=True)
        result = subprocess.run(
            [
                "git",
                "-c",
                f"safe.directory={self.repository}",
                "-c",
                "commit.gpgSign=false",
                "-c",
                "tag.gpgSign=false",
                "-c",
                f"core.hooksPath={hooks_directory}",
                *arguments,
            ],
            cwd=self.repository,
            input=input_bytes,
            capture_output=True,
            check=False,
            shell=False,
            text=input_bytes is None,
            env=_fixture_git_environment(),
        )
        if check and result.returncode:
            self.fail(f"fixture Git command failed: {arguments!r}: {result.stderr!r}")
        return result

    def _policy(self, paths):
        return {
            "schemaVersion": 1,
            "repository": "a1112/Mac-Win",
            "sourceCommit": self.source_commit,
            "sourceTag": "frozen-source",
            "groups": [
                {
                    "category": "probes",
                    "kind": "probe",
                    "license": {"status": "unresolved"},
                    "provenance": {"status": "unresolved"},
                    "intendedOwner": "compatforge/probes",
                    "externalRefs": [],
                    "developmentDependencies": [],
                    "paths": list(paths),
                }
            ],
            "dependencyPolicy": {
                "externalRefs": [],
                "developmentDependencies": [],
            },
        }

    def bind(self, policy=None, commit=None, tag="frozen-source"):
        return _bind_governed_assets(
            self.repository,
            self.policy if policy is None else policy,
            self.source_commit if commit is None else commit,
            tag,
        )

    def assert_binding_error(self, message, **kwargs):
        with self.assertRaisesRegex(InventoryError, f"^{message}$"):
            self.bind(**kwargs)

    def test_binds_annotated_tagged_commit_to_raw_blob_identity(self):
        records = self.bind()
        blob_oid = self._fixture_git(
            "rev-parse", f"{self.source_commit}:{self.asset_path}"
        ).stdout.strip()
        self.assertEqual(len(records), 1)
        self.assertEqual(
            records[0],
            {
                "sourcePath": self.asset_path,
                "sourceCommit": self.source_commit,
                "gitBlobOid": blob_oid,
                "sha256": "4dc359967546dc8d3c9ccc74bb45d23339ba47523aa6050a6ba1af05041cb4e2",
                "byteSize": 25,
                "gitMode": "100644",
                "kind": "probe",
                "license": {"status": "unresolved"},
                "provenance": {"status": "unresolved"},
                "intendedOwner": "compatforge/probes",
                "externalRefs": [],
                "developmentDependencies": [],
                "category": "probes",
            },
        )

    def test_requires_local_commit_annotated_direct_tag_and_head_ancestry(self):
        blob = self._fixture_git(
            "rev-parse", f"{self.source_commit}:{self.asset_path}"
        ).stdout.strip()
        self.assert_binding_error(
            "inventory source Git identity is invalid", commit=blob
        )
        self.assert_binding_error(
            "inventory source Git identity is invalid", commit="0" * 40
        )

        self._fixture_git("tag", "-d", "frozen-source")
        self._fixture_git("tag", "frozen-source", self.source_commit)
        self.assert_binding_error("inventory source Git identity is invalid")

    def test_rejects_annotated_tag_with_unapproved_message(self):
        self._fixture_git("tag", "-d", "frozen-source")
        self._fixture_git(
            "tag", "-a", "frozen-source", "-m", "wrong message", self.source_commit
        )
        self.assert_binding_error("inventory source Git identity is invalid")

    def test_rejects_wrong_case_and_symbolic_tag_refs(self):
        self.assert_binding_error(
            "inventory source Git identity is invalid", tag="FROZEN-SOURCE"
        )
        self._fixture_git("tag", "-d", "frozen-source")
        self._fixture_git(
            "symbolic-ref", "refs/tags/frozen-source", "refs/heads/main"
        )
        self.assert_binding_error("inventory source Git identity is invalid")

    def test_rejects_oversized_and_wrong_internal_tag_contracts(self):
        raw_tag = (
            f"object {self.source_commit}\n"
            "type commit\n"
            "tag frozen-source\n"
            "tagger Inventory Tests <inventory@example.invalid> 1 +0000\n\n"
        ).encode("ascii") + (b"x" * (2 * 1024 * 1024)) + b"\n"
        huge_oid = self._fixture_git("mktag", input_bytes=raw_tag).stdout.strip().decode("ascii")
        self._fixture_git("update-ref", "refs/tags/frozen-source", huge_oid)
        self.assert_binding_error("inventory source Git identity is invalid")

        self._fixture_git("tag", "-d", "frozen-source")
        self._fixture_git(
            "tag", "-a", "internal-other", "-m", SOURCE_TAG_MESSAGE, self.source_commit
        )
        other_oid = self._fixture_git("rev-parse", "refs/tags/internal-other").stdout.strip()
        self._fixture_git("update-ref", "refs/tags/frozen-source", other_oid)
        self.assert_binding_error("inventory source Git identity is invalid")

    def test_rejects_annotated_tag_that_points_to_another_tag(self):
        self._fixture_git("tag", "-d", "frozen-source")
        self._fixture_git(
            "tag", "-a", "inner", "-m", SOURCE_TAG_MESSAGE, self.source_commit
        )
        self._fixture_git(
            "tag", "-a", "outer", "-m", SOURCE_TAG_MESSAGE, "refs/tags/inner"
        )
        outer_oid = self._fixture_git("rev-parse", "refs/tags/outer").stdout.strip()
        self._fixture_git("update-ref", "refs/tags/frozen-source", outer_oid)
        self.assert_binding_error("inventory source Git identity is invalid")

    def test_rejects_casefold_colliding_stored_tag_refs(self):
        self._fixture_git("pack-refs", "--all")
        tag_oid = self._fixture_git("rev-parse", "refs/tags/frozen-source").stdout.strip()
        packed_refs = self.repository / ".git" / "packed-refs"
        with packed_refs.open("a", encoding="ascii", newline="\n") as stream:
            stream.write(f"{tag_oid} refs/tags/FROZEN-SOURCE\n")
            stream.write(f"^{self.source_commit}\n")
        self.assert_binding_error("inventory source Git identity is invalid")

        self._fixture_git("tag", "-d", "frozen-source")
        (self.repository / self.asset_path).write_bytes(b"different\n")
        self._fixture_git("add", "--", self.asset_path)
        self._fixture_git("commit", "-q", "-m", "other")
        other = self._fixture_git("rev-parse", "HEAD").stdout.strip()
        self._fixture_git("tag", "-a", "frozen-source", "-m", SOURCE_TAG_MESSAGE, other)
        self.assert_binding_error("inventory source Git identity is invalid")

        self._fixture_git("tag", "-d", "frozen-source")
        self._fixture_git("tag", "-a", "frozen-source", "-m", SOURCE_TAG_MESSAGE, self.source_commit)
        self._fixture_git("checkout", "-q", "--orphan", "unrelated")
        self._fixture_git("rm", "-q", "--cached", "--", self.asset_path)
        (self.repository / self.asset_path).write_bytes(b"unrelated\n")
        self._fixture_git("add", "--", self.asset_path)
        self._fixture_git("commit", "-q", "-m", "unrelated")
        self.assert_binding_error("inventory source Git identity is invalid")

    def test_governed_tree_coverage_rejects_added_and_removed_paths(self):
        policy = self._policy([])
        self.assert_binding_error("inventory governed path coverage is invalid", policy=policy)

        extra = self.repository / "scripts" / "extra.sh"
        extra.write_bytes(b"extra\n")
        self._fixture_git("add", "--", "scripts/extra.sh")
        self._fixture_git("commit", "-q", "-m", "extra")
        self.source_commit = self._fixture_git("rev-parse", "HEAD").stdout.strip()
        self._fixture_git("tag", "-f", "-a", "frozen-source", "-m", SOURCE_TAG_MESSAGE, self.source_commit)
        self.policy = self._policy([self.asset_path])
        self.assert_binding_error("inventory governed path coverage is invalid")

    def test_governed_tree_rejects_casefold_collision_when_ordinary_coverage_matches(self):
        colliding_path = "Scripts/Example.sh"
        policy = self._policy([self.asset_path, colliding_path])
        oid = self._fixture_git(
            "rev-parse", f"{self.source_commit}:{self.asset_path}"
        ).stdout.strip()
        entries = [
            ("100644", "blob", oid, self.asset_path),
            ("100644", "blob", oid, colliding_path),
        ]
        with mock.patch.object(generator, "_list_governed_tree", return_value=entries):
            self.assert_binding_error(
                "inventory governed path coverage is invalid", policy=policy
            )

    def _replace_asset_mode(self, mode, oid=None):
        if oid is None:
            oid = self._fixture_git(
                "rev-parse", f"HEAD:{self.asset_path}"
            ).stdout.strip()
        self._fixture_git(
            "update-index", "--add", "--cacheinfo", f"{mode},{oid},{self.asset_path}"
        )
        self._fixture_git("commit", "-q", "-m", f"mode {mode}")
        self.source_commit = self._fixture_git("rev-parse", "HEAD").stdout.strip()
        self._fixture_git("tag", "-f", "-a", "frozen-source", "-m", SOURCE_TAG_MESSAGE, self.source_commit)
        self.policy = self._policy([self.asset_path])

    def test_accepts_executable_and_rejects_symlink_submodule_and_unknown_mode(self):
        self._replace_asset_mode("100755")
        self.assertEqual(self.bind()[0]["gitMode"], "100755")

        for mode, message in (
            ("120000", "inventory governed Git entry mode is invalid"),
            ("160000", "inventory governed Git entry mode is invalid"),
        ):
            with self.subTest(mode=mode):
                self._replace_asset_mode(mode, self.source_commit if mode == "160000" else None)
                self.assert_binding_error(message)

        with mock.patch.object(
            generator,
            "_list_governed_tree",
            return_value=[("100664", "blob", "1" * 40, self.asset_path)],
        ):
            self.assert_binding_error("inventory governed Git entry mode is invalid")

    def test_rejects_tree_tag_missing_oversized_and_truncated_blob_objects(self):
        tree_oid = self._fixture_git("rev-parse", f"{self.source_commit}:scripts").stdout.strip()
        tag_oid = self._fixture_git("rev-parse", "refs/tags/frozen-source").stdout.strip()
        small_oid = self._fixture_git(
            "rev-parse", f"{self.source_commit}:{self.asset_path}"
        ).stdout.strip()
        for oid in (tree_oid, tag_oid, "0" * 40):
            with self.subTest(oid=oid):
                with self.assertRaisesRegex(
                    InventoryError, "^inventory governed Git object is invalid$"
                ):
                    _read_blob(self.repository, oid)

        huge = self.repository / self.asset_path
        huge.write_bytes(b"x" * (MAX_ASSET_BYTES + 1))
        self._fixture_git("add", "--", self.asset_path)
        self._fixture_git("commit", "-q", "-m", "oversized")
        self.source_commit = self._fixture_git("rev-parse", "HEAD").stdout.strip()
        self._fixture_git("tag", "-f", "-a", "frozen-source", "-m", SOURCE_TAG_MESSAGE, self.source_commit)
        self.policy = self._policy([self.asset_path])
        self.assert_binding_error("inventory governed Git object exceeds the byte limit")

        real_run_git = generator._run_git

        def truncated(repository_root, *arguments):
            result = real_run_git(repository_root, *arguments)
            if arguments[:2] == ("cat-file", "blob"):
                return subprocess.CompletedProcess(result.args, 0, b"short", b"")
            return result

        with mock.patch.object(generator, "_run_git", side_effect=truncated):
            with self.assertRaisesRegex(
                InventoryError, "^inventory governed Git object length is invalid$"
            ):
                _read_blob(self.repository, small_oid)

    def test_rejects_same_length_blob_replacement_between_size_and_read(self):
        expected_oid = hashlib.sha1(b"blob 4\0good").hexdigest()

        def replaced(_repository_root, *arguments):
            if arguments == ("rev-parse", "--show-object-format=storage"):
                stdout = b"sha1\n"
            elif arguments[:2] == ("cat-file", "-t"):
                stdout = b"blob\n"
            elif arguments[:2] == ("cat-file", "-s"):
                stdout = b"4\n"
            elif arguments[:2] == ("cat-file", "blob"):
                stdout = b"evil"
            else:
                self.fail(f"unexpected Git arguments: {arguments!r}")
            return subprocess.CompletedProcess(arguments, 0, stdout, b"")

        with mock.patch.object(generator, "_run_git", side_effect=replaced):
            with self.assertRaisesRegex(
                InventoryError, "^inventory governed Git object identity is invalid$"
            ):
                _read_blob(self.repository, expected_oid)

    def test_rejects_same_length_loose_object_corruption(self):
        oid = self._fixture_git(
            "rev-parse", f"{self.source_commit}:{self.asset_path}"
        ).stdout.strip()
        loose_object = self.repository / ".git" / "objects" / oid[:2] / oid[2:]
        stored = zlib.decompress(loose_object.read_bytes())
        self.assertIn(b"frozen", stored)
        corrupted = stored.replace(b"frozen", b"broken", 1)
        self.assertEqual(len(corrupted), len(stored))
        loose_object.chmod(0o600)
        loose_object.write_bytes(zlib.compress(corrupted))
        with self.assertRaisesRegex(
            InventoryError,
            r"^inventory governed Git object (?:is|identity is) invalid$",
        ):
            _read_blob(self.repository, oid)

    def test_git_environment_is_copied_scrubbed_and_forces_offline_object_reads(self):
        hostile = {
            "PATH": os.environ.get("PATH", ""),
            "KEEP_ME": "yes",
            "GIT_DIR": "decoy",
            "GIT_WORK_TREE": "decoy",
            "GIT_COMMON_DIR": "decoy",
            "GIT_INDEX_FILE": "decoy",
            "GIT_OBJECT_DIRECTORY": "decoy",
            "GIT_ALTERNATE_OBJECT_DIRECTORIES": "decoy",
            "GIT_NAMESPACE": "decoy",
            "GIT_CONFIG_COUNT": "1",
            "GIT_CONFIG_KEY_0": "core.sshCommand",
            "GIT_CONFIG_VALUE_0": "hostile",
            "GIT_CONFIG_GLOBAL": "decoy",
            "GIT_CONFIG_SYSTEM": "decoy",
            "GIT_CONFIG_NOSYSTEM": "0",
        }
        cleaned = _git_environment(hostile)
        self.assertEqual(cleaned["PATH"], hostile["PATH"])
        self.assertEqual(cleaned["KEEP_ME"], "yes")
        self.assertEqual(
            {key: cleaned[key] for key in (
                "GIT_CONFIG_GLOBAL",
                "GIT_CONFIG_NOSYSTEM",
                "GIT_NO_LAZY_FETCH",
                "GIT_NO_REPLACE_OBJECTS",
                "GIT_TERMINAL_PROMPT",
            )},
            {
                "GIT_CONFIG_GLOBAL": os.devnull,
                "GIT_CONFIG_NOSYSTEM": "1",
                "GIT_NO_LAZY_FETCH": "1",
                "GIT_NO_REPLACE_OBJECTS": "1",
                "GIT_TERMINAL_PROMPT": "0",
            },
        )
        for key in hostile:
            if key.startswith("GIT_") and key not in (
                "GIT_CONFIG_GLOBAL",
                "GIT_CONFIG_NOSYSTEM",
            ):
                self.assertNotIn(key, cleaned)

    def test_cli_ignores_malformed_home_global_and_system_git_configuration(self):
        with tempfile.TemporaryDirectory(prefix="inventory hostile git config ") as directory:
            hostile_home = Path(directory) / "home"
            hostile_home.mkdir()
            (hostile_home / ".gitconfig").write_text(
                "[malformed\n", encoding="utf-8"
            )
            hostile_system = Path(directory) / "system.gitconfig"
            hostile_system.write_text("[also-malformed\n", encoding="utf-8")
            environment = os.environ.copy()
            environment.update(
                {
                    "HOME": str(hostile_home),
                    "USERPROFILE": str(hostile_home),
                    "GIT_CONFIG_SYSTEM": str(hostile_system),
                }
            )
            result = subprocess.run(
                [sys.executable, "-B", str(GENERATOR_PATH), "--list"],
                cwd=ROOT,
                env=environment,
                capture_output=True,
                check=False,
            )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stderr, b"")
        self.assertTrue(result.stdout.startswith(b"Mac-Win migration assets: 90 "))

    def test_git_wrapper_uses_fixed_argv_shell_false_and_exact_repository_root(self):
        completed = subprocess.CompletedProcess([], 0, b"ok", b"")
        with mock.patch.object(generator.subprocess, "run", return_value=completed) as run:
            result = _run_git(self.repository, "cat-file", "-t", "1" * 40)
        self.assertIs(result, completed)
        _args, kwargs = run.call_args
        argv = _args[0]
        self.assertEqual(argv[:3], ["git", "-c", f"safe.directory={self.repository}"])
        self.assertEqual(argv[3:], ["cat-file", "-t", "1" * 40])
        self.assertEqual(kwargs["cwd"], self.repository)
        self.assertIs(kwargs["shell"], False)
        self.assertEqual(kwargs["stdin"], subprocess.DEVNULL)
        self.assertEqual(kwargs["env"]["PATH"], os.environ["PATH"])

    def test_replace_refs_ambient_git_state_dirty_crlf_worktree_do_not_change_records(self):
        expected = self.bind()
        (self.repository / self.asset_path).write_bytes(b"dirty\r\nworktree\r\n")

        alternate = Path(self.temporary_directory.name) / "alternate objects"
        alternate.mkdir()
        hostile = {
            "GIT_DIR": str(self.repository / "decoy.git"),
            "GIT_WORK_TREE": str(self.repository / "decoy-worktree"),
            "GIT_COMMON_DIR": str(self.repository / "decoy-common"),
            "GIT_INDEX_FILE": str(self.repository / "decoy-index"),
            "GIT_OBJECT_DIRECTORY": str(alternate),
            "GIT_ALTERNATE_OBJECT_DIRECTORIES": str(alternate),
            "GIT_NAMESPACE": "hostile",
            "GIT_CONFIG_COUNT": "1",
            "GIT_CONFIG_KEY_0": "core.replaceRefs",
            "GIT_CONFIG_VALUE_0": "true",
        }
        with mock.patch.dict(os.environ, hostile, clear=False):
            self.assertEqual(self.bind(), expected)

        replacement_asset = self.repository / self.asset_path
        replacement_asset.write_bytes(b"replacement\n")
        self._fixture_git("add", "--", self.asset_path)
        self._fixture_git("commit", "-q", "-m", "replacement")
        replacement = self._fixture_git("rev-parse", "HEAD").stdout.strip()
        self._fixture_git("replace", self.source_commit, replacement)
        self.assertEqual(self.bind(), expected)

    def test_rejects_repository_owned_alternate_and_http_object_databases(self):
        info = self.repository / ".git" / "objects" / "info"
        alternate_objects = self.repository / "alternate-object-database"
        alternate_objects.mkdir()
        for sentinel, content in (
            ("alternates", str(alternate_objects) + "\n"),
            ("http-alternates", "https://example.invalid/objects\n"),
        ):
            with self.subTest(sentinel=sentinel):
                path = info / sentinel
                path.write_text(content, encoding="utf-8")
                self.assert_binding_error(
                    "inventory Git object database is not self-contained"
                )
                path.unlink()

    def test_rejects_symlinked_primary_object_database_before_path_resolution(self):
        objects = self.repository / ".git" / "objects"
        real_objects = self.repository / ".git" / "objects-real"
        objects.rename(real_objects)
        try:
            objects.symlink_to(real_objects, target_is_directory=True)
        except OSError as error:
            real_objects.rename(objects)
            self.skipTest(f"directory symlink creation is unavailable: {error}")
        self.assert_binding_error(
            "inventory Git object database is not self-contained"
        )

    def test_rejects_linked_primary_object_database_child_directories(self):
        objects = self.repository / ".git" / "objects"
        for child_name in ("info", "pack"):
            with self.subTest(child_name=child_name):
                child = objects / child_name
                displaced = objects / f"{child_name}-displaced"
                external = self.repository / f"external-{child_name}"
                child.rename(displaced)
                external.mkdir()
                try:
                    child.symlink_to(external, target_is_directory=True)
                except OSError as error:
                    external.rmdir()
                    displaced.rename(child)
                    self.skipTest(
                        f"directory symlink creation is unavailable: {error}"
                    )
                try:
                    self.assert_binding_error(
                        "inventory Git object database is not self-contained"
                    )
                finally:
                    child.unlink()
                    external.rmdir()
                    displaced.rename(child)

    def test_rejects_promisor_pack_and_partial_clone_configuration(self):
        pack_directory = self.repository / ".git" / "objects" / "pack"
        for filename in ("hostile.promisor", "hostile.PROMISOR"):
            with self.subTest(filename=filename):
                promisor = pack_directory / filename
                promisor.write_bytes(b"")
                self.assert_binding_error(
                    "inventory Git object database is not self-contained"
                )
                promisor.unlink()

        self._fixture_git("config", "extensions.partialClone", "origin")
        self.assert_binding_error("inventory Git object database is not self-contained")
        self._fixture_git("config", "--unset", "extensions.partialClone")
        self._fixture_git("config", "remote.origin.promisor", "true")
        self.assert_binding_error("inventory Git object database is not self-contained")

    def test_rejects_promisor_configuration_from_linked_worktree_scope(self):
        self._fixture_git("config", "extensions.worktreeConfig", "true")
        with tempfile.TemporaryDirectory(prefix="inventory linked parent ") as parent:
            linked = Path(parent) / "linked worktree"
            self._fixture_git(
                "worktree",
                "add",
                "-q",
                "-b",
                "inventory-linked",
                str(linked),
                self.source_commit,
            )
            try:
                self._fixture_git(
                    "-C",
                    str(linked),
                    "config",
                    "--worktree",
                    "remote.origin.promisor",
                    "true",
                )
                with self.assertRaisesRegex(
                    InventoryError,
                    "^inventory Git object database is not self-contained$",
                ):
                    _bind_governed_assets(
                        linked,
                        self.policy,
                        self.source_commit,
                        "frozen-source",
                    )
            finally:
                self._fixture_git(
                    "worktree", "remove", "--force", str(linked), check=False
                )

    def test_worktree_config_enabled_uses_only_machine_readable_boolean_output(self):
        accepted = (
            (1, b"", b"localized or changed diagnostic\n", False),
            (0, b"false", b"localized warning\n", False),
            (0, b"false\n", b"", False),
            (0, b"true", b"localized warning\n", True),
            (0, b"true\r\n", b"", True),
        )
        for returncode, stdout, stderr, expected in accepted:
            with self.subTest(returncode=returncode, stdout=stdout):
                result = subprocess.CompletedProcess([], returncode, stdout, stderr)
                with mock.patch.object(generator, "_run_git", return_value=result):
                    self.assertIs(
                        generator._worktree_config_enabled(self.repository), expected
                    )

        rejected = (
            subprocess.CompletedProcess([], 2, b"", b"localized\n"),
            subprocess.CompletedProcess([], 0, b"", b""),
            subprocess.CompletedProcess([], 0, b"yes\n", b""),
            subprocess.CompletedProcess([], 0, b"true\nfalse\n", b""),
            subprocess.CompletedProcess([], 0, b" true\n", b""),
        )
        for result in rejected:
            with self.subTest(returncode=result.returncode, stdout=result.stdout):
                with mock.patch.object(generator, "_run_git", return_value=result):
                    with self.assertRaisesRegex(
                        InventoryError,
                        "^inventory Git worktree config state is invalid$",
                    ):
                        generator._worktree_config_enabled(self.repository)

    def test_promisor_check_skips_disabled_worktree_scope_and_fails_closed_when_enabled(self):
        for enabled in (False,):
            with mock.patch.object(
                generator, "_worktree_config_enabled", return_value=enabled
            ), mock.patch.object(
                generator, "_git_config_scope_keys", return_value=()
            ) as scope_keys:
                generator._validate_promisor_configuration(self.repository)
            scope_keys.assert_called_once_with(self.repository, "local")

        with mock.patch.object(
            generator, "_worktree_config_enabled", return_value=True
        ), mock.patch.object(
            generator,
            "_git_config_scope_keys",
            side_effect=((), InventoryError("inventory Git config scope is invalid")),
        ) as scope_keys:
            with self.assertRaisesRegex(
                InventoryError, "^inventory Git config scope is invalid$"
            ):
                generator._validate_promisor_configuration(self.repository)
        self.assertEqual(
            [call.args[1] for call in scope_keys.call_args_list],
            ["local", "worktree"],
        )

    def test_reads_the_same_binding_from_packed_objects(self):
        expected = self.bind()
        self._fixture_git("gc", "--prune=now")
        self.assertTrue(any((self.repository / ".git" / "objects" / "pack").glob("*.pack")))
        self.assertEqual(self.bind(), expected)

    def test_fixture_git_ignores_process_local_hostile_signing_configuration(self):
        hostile = {
            "GIT_CONFIG_COUNT": "3",
            "GIT_CONFIG_KEY_0": "commit.gpgSign",
            "GIT_CONFIG_VALUE_0": "true",
            "GIT_CONFIG_KEY_1": "tag.gpgSign",
            "GIT_CONFIG_VALUE_1": "true",
            "GIT_CONFIG_KEY_2": "user.signingKey",
            "GIT_CONFIG_VALUE_2": "missing-inventory-test-signer",
        }
        with mock.patch.dict(os.environ, hostile, clear=False):
            (self.repository / self.asset_path).write_bytes(b"unsigned commit\n")
            self._fixture_git("add", "--", self.asset_path)
            self._fixture_git("commit", "-q", "-m", "unsigned fixture commit")
            commit = self._fixture_git("rev-parse", "HEAD").stdout.strip()
            self._fixture_git(
                "tag", "-a", "unsigned-fixture-tag", "-m", "unsigned", commit
            )

        self.assertEqual(
            self._fixture_git("cat-file", "-t", "unsigned-fixture-tag").stdout.strip(),
            "tag",
        )

    def test_fixture_git_ignores_hostile_home_hooks_and_missing_signer(self):
        hostile_home = self.repository / "hostile-home"
        hooks = hostile_home / "hooks"
        hooks.mkdir(parents=True)
        (hooks / "pre-commit").write_bytes(b"#!/bin/sh\nexit 91\n")
        (hostile_home / ".gitconfig").write_text(
            "[core]\n"
            f"\thooksPath = {hooks.as_posix()}\n"
            "[commit]\n\tgpgSign = true\n"
            "[tag]\n\tgpgSign = true\n"
            "[user]\n\tsigningKey = missing-home-signer\n",
            encoding="utf-8",
        )
        with mock.patch.dict(
            os.environ,
            {"HOME": str(hostile_home), "USERPROFILE": str(hostile_home)},
            clear=False,
        ):
            (self.repository / self.asset_path).write_bytes(b"hook isolated\n")
            self._fixture_git("add", "--", self.asset_path)
            self._fixture_git("commit", "-q", "-m", "isolated fixture commit")

    def test_fixture_git_environment_preserves_path_and_scrubs_git_injection(self):
        source = {
            "PATH": "fixture-path",
            "KEEP_ME": "yes",
            "GIT_DIR": "decoy",
            "GIT_WORK_TREE": "decoy",
            "GIT_COMMON_DIR": "decoy",
            "GIT_INDEX_FILE": "decoy",
            "GIT_OBJECT_DIRECTORY": "decoy",
            "GIT_ALTERNATE_OBJECT_DIRECTORIES": "decoy",
            "GIT_NAMESPACE": "decoy",
            "GIT_CONFIG_COUNT": "1",
            "GIT_CONFIG_KEY_0": "commit.gpgSign",
            "GIT_CONFIG_VALUE_0": "true",
            "GIT_CONFIG_GLOBAL": "decoy",
            "GIT_CONFIG_SYSTEM": "decoy",
            "GIT_CONFIG_NOSYSTEM": "0",
        }
        cleaned = _fixture_git_environment(source)
        self.assertEqual(cleaned["PATH"], "fixture-path")
        self.assertEqual(cleaned["KEEP_ME"], "yes")
        self.assertEqual(cleaned["GIT_CONFIG_GLOBAL"], os.devnull)
        self.assertEqual(cleaned["GIT_CONFIG_NOSYSTEM"], "1")
        self.assertEqual(cleaned["GIT_TERMINAL_PROMPT"], "0")
        self.assertEqual(
            {key for key in cleaned if key.startswith("GIT_")},
            {"GIT_CONFIG_GLOBAL", "GIT_CONFIG_NOSYSTEM", "GIT_TERMINAL_PROMPT"},
        )

    def test_real_frozen_tree_contains_the_approved_ninety_records(self):
        policy = parse_policy_bytes(POLICY_PATH.read_bytes())
        records = _bind_governed_assets(ROOT, policy, SOURCE_COMMIT, "mw-migration-baseline-db12d5e")
        self.assertEqual(len(records), 90)
        self.assertEqual(len({record["sourcePath"] for record in records}), 90)
        counts = {}
        for record in records:
            counts[record["category"]] = counts.get(record["category"], 0) + 1
        self.assertEqual(
            counts,
            {"catalog": 19, "patches": 11, "probes": 26, "fixtures": 30, "bottle-schema": 4},
        )

    def test_list_cli_uses_hardened_runner_for_audited_tag_validation(self):
        hostile_environments = (
            {"GIT_TEST_ASSUME_DIFFERENT_OWNER": "1"},
            {
                "GIT_CONFIG_COUNT": "1",
                "GIT_CONFIG_KEY_0": "core.abbrev",
                "GIT_CONFIG_VALUE_0": "invalid",
            },
        )
        for hostile in hostile_environments:
            with self.subTest(hostile=tuple(sorted(hostile))):
                environment = os.environ.copy()
                environment.update(hostile)
                result = subprocess.run(
                    [sys.executable, "-B", str(GENERATOR_PATH), "--list"],
                    cwd=ROOT,
                    env=environment,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stderr, b"")
                self.assertTrue(result.stdout.startswith(b"Mac-Win migration assets: 90 "))


class AssetCanonicalOutputTests(unittest.TestCase):
    _documents = None

    @classmethod
    def documents(cls):
        if cls._documents is None:
            cls._documents = generator.generate_inventory_documents(ROOT)
        return cls._documents

    @staticmethod
    def decoded(documents, relative_path):
        return json.loads(documents[relative_path].decode("ascii"))

    def test_two_in_memory_generations_are_byte_identical_and_allowlisted(self):
        first = self.documents()
        hostile = {
            "TZ": "Pacific/Kiritimati",
            "LC_ALL": "hostile-locale",
            "GIT_DIR": str(ROOT / "decoy.git"),
            "GIT_WORK_TREE": str(ROOT / "decoy-worktree"),
            "GIT_CONFIG_COUNT": "1",
            "GIT_CONFIG_KEY_0": "core.abbrev",
            "GIT_CONFIG_VALUE_0": "invalid",
        }
        with mock.patch.dict(os.environ, hostile, clear=False):
            second = generator.generate_inventory_documents(ROOT)
        self.assertEqual(first, second)
        self.assertEqual(tuple(first), OUTPUT_RELATIVE_PATHS)

        policy = generator.load_policy()
        reordered = {key: policy[key] for key in reversed(tuple(policy))}
        with mock.patch.object(generator, "load_policy", return_value=reordered):
            self.assertEqual(generator.generate_inventory_documents(ROOT), first)

    def test_canonical_documents_are_bounded_ascii_utf8_lf_json(self):
        for relative_path, raw in self.documents().items():
            with self.subTest(relative_path=relative_path):
                self.assertLessEqual(len(raw), MAX_DOCUMENT_BYTES)
                self.assertTrue(raw.endswith(b"\n"))
                self.assertFalse(raw.endswith(b"\n\n"))
                self.assertNotIn(b"\r", raw)
                raw.decode("ascii").encode("ascii")
                value = generator._parse_json_document(raw)
                self.assertEqual(generator.canonical_json_bytes(value), raw)

    def test_root_binds_exact_counts_order_paths_and_shard_digests(self):
        documents = self.documents()
        root = self.decoded(documents, "migration/assets/index.json")
        self.assertEqual(
            list(root),
            [
                "schemaVersion",
                "repository",
                "sourceCommit",
                "sourceTag",
                "digestAlgorithm",
                "order",
                "assetCount",
                "dependencyCounts",
                "shards",
            ],
        )
        self.assertEqual(root["assetCount"], 90)
        self.assertEqual(
            root["dependencyCounts"],
            {
                "externalRefs": 277,
                "developmentDependencies": 108,
                "absolutePath": 23,
                "environmentPath": 50,
                "repositoryPath": 35,
            },
        )
        self.assertEqual(root["digestAlgorithm"], "sha256")
        self.assertEqual(root["order"], "ascii-posix-path")
        self.assertEqual(
            [entry["path"] for entry in root["shards"]],
            list(OUTPUT_RELATIVE_PATHS[1:]),
        )
        self.assertEqual(
            [entry["category"] for entry in root["shards"]],
            [
                "bottle-schema",
                "catalog",
                "fixtures",
                "patches",
                "probes",
                "dependencies",
            ],
        )
        for entry in root["shards"]:
            self.assertEqual(
                entry["sha256"], hashlib.sha256(documents[entry["path"]]).hexdigest()
            )
        self.assertEqual(
            [entry["recordCount"] for entry in root["shards"]],
            [4, 19, 30, 11, 26, 385],
        )

    def test_every_asset_entry_is_independent_complete_and_ascii_sorted(self):
        expected_fields = [
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
        ]
        paths = []
        for relative_path in OUTPUT_RELATIVE_PATHS[1:-1]:
            shard = self.decoded(self.documents(), relative_path)
            self.assertEqual(shard["assetCount"], len(shard["assets"]))
            shard_paths = [asset["sourcePath"] for asset in shard["assets"]]
            self.assertEqual(
                shard_paths,
                sorted(shard_paths, key=lambda value: value.encode("ascii")),
            )
            for asset in shard["assets"]:
                self.assertEqual(list(asset), expected_fields)
                self.assertEqual(asset["sourceCommit"], SOURCE_COMMIT)
                self.assertRegex(asset["gitBlobOid"], r"^[0-9a-f]{40}$")
                self.assertRegex(asset["sha256"], r"^[0-9a-f]{64}$")
                self.assertIn(asset["gitMode"], ("100644", "100755"))
                self.assertIs(type(asset["byteSize"]), int)
                self.assertIs(type(asset["externalRefs"]), list)
                self.assertIs(type(asset["developmentDependencies"]), list)
                paths.append(asset["sourcePath"])
        self.assertEqual(len(paths), 90)
        self.assertEqual(len(set(paths)), 90)

    def test_grouped_dependency_shard_expands_exactly_without_losing_identity(self):
        dependency = self.decoded(
            self.documents(), "migration/assets/dependencies.json"
        )
        expanded = generator.expand_dependency_groups(dependency)
        policy = generator.load_policy()
        records = generator._bind_governed_assets(
            ROOT, policy, SOURCE_COMMIT, generator.SOURCE_TAG
        )
        frozen = generator._extract_dependency_evidence(ROOT, records)
        self.assertEqual(expanded, frozen)
        self.assertEqual(len(expanded["externalRefs"]), 277)
        self.assertEqual(len(expanded["developmentDependencies"]), 108)
        self.assertEqual(
            sum(
                entry["sourcePath"] == "scripts/download-software-samples.sh"
                for entry in expanded["externalRefs"]
            ),
            234,
        )
        self.assertLessEqual(
            len(self.documents()["migration/assets/dependencies.json"]),
            MAX_DOCUMENT_BYTES,
        )

    def test_asset_dependency_locators_are_sorted_and_exactly_match_dependency_shard(self):
        documents = self.documents()
        dependency = self.decoded(documents, "migration/assets/dependencies.json")
        expected = generator.expand_dependency_groups(dependency)
        actual = {"externalRefs": {}, "developmentDependencies": {}}
        for relative_path in OUTPUT_RELATIVE_PATHS[1:-1]:
            shard = self.decoded(documents, relative_path)
            for asset in shard["assets"]:
                for field in actual:
                    previous = None
                    for locator in asset[field]:
                        self.assertIs(type(locator), str)
                        key = locator.encode("utf-8")
                        if previous is not None:
                            self.assertLess(previous, key)
                        previous = key
                    actual[field][asset["sourcePath"]] = asset[field]
        for field in actual:
            expected_locators = {
                path: []
                for path in {
                    asset["sourcePath"]
                    for relative_path in OUTPUT_RELATIVE_PATHS[1:-1]
                    for asset in self.decoded(documents, relative_path)["assets"]
                }
            }
            for entry in expected[field]:
                expected_locators[entry["sourcePath"]].append(entry["locator"])
            for locators in expected_locators.values():
                locators.sort(key=lambda value: value.encode("utf-8"))
            self.assertEqual(actual[field], expected_locators)

    def test_asset_dependency_forgery_fails_even_with_updated_shard_digest(self):
        validator = load_inventory_validator()
        documents = self.documents()
        candidate = dict(documents)
        probes_path = "migration/assets/probes.json"
        probes = self.decoded(documents, probes_path)
        asset = next(
            entry
            for entry in probes["assets"]
            if entry["sourcePath"] == "scripts/download-software-samples.sh"
        )
        self.assertEqual(len(asset["externalRefs"]), 234)
        asset["externalRefs"].pop()
        candidate[probes_path] = generator.canonical_json_bytes(probes)
        root = self.decoded(documents, "migration/assets/index.json")
        next(entry for entry in root["shards"] if entry["path"] == probes_path)[
            "sha256"
        ] = hashlib.sha256(candidate[probes_path]).hexdigest()
        candidate["migration/assets/index.json"] = generator.canonical_json_bytes(root)
        with self.assertRaisesRegex(
            validator.InventoryValidationError,
            "^migration asset inventory document is invalid$",
        ):
            validator.validate_inventory_documents(candidate)

    def test_dependency_group_validation_rejects_loss_duplicates_and_extensions(self):
        validator = load_inventory_validator()
        documents = self.documents()
        original = self.decoded(documents, "migration/assets/dependencies.json")
        mutations = {}

        empty = copy.deepcopy(original)
        empty["externalRefs"][0]["locators"] = []
        mutations["empty"] = empty
        duplicate = copy.deepcopy(original)
        duplicate["externalRefs"][0]["locators"] *= 2
        mutations["duplicate"] = duplicate
        unsorted = copy.deepcopy(original)
        multi_locator_group = next(
            group
            for group in unsorted["externalRefs"]
            if len(group["locators"]) > 1
        )
        multi_locator_group["locators"].reverse()
        mutations["unsorted"] = unsorted
        missing = copy.deepcopy(original)
        del missing["externalRefs"][0]["status"]
        mutations["missing"] = missing
        extra = copy.deepcopy(original)
        extra["externalRefs"][0]["unknown"] = True
        mutations["extra"] = extra
        unknown = copy.deepcopy(original)
        unknown["externalRefs"][0]["kind"] = "hostile-kind"
        mutations["unknown"] = unknown

        for name, value in mutations.items():
            with self.subTest(name=name):
                candidate = dict(documents)
                dependency_path = "migration/assets/dependencies.json"
                candidate[dependency_path] = generator.canonical_json_bytes(value)
                root = self.decoded(documents, "migration/assets/index.json")
                root["shards"][-1]["sha256"] = hashlib.sha256(
                    candidate[dependency_path]
                ).hexdigest()
                candidate["migration/assets/index.json"] = generator.canonical_json_bytes(root)
                with self.assertRaisesRegex(
                    validator.InventoryValidationError,
                    "^migration asset inventory document is invalid$",
                ):
                    validator.validate_inventory_documents(candidate)

    def test_closed_schema_and_exact_expected_bytes_reject_all_reviewed_drift(self):
        validator = load_inventory_validator()
        documents = self.documents()
        mutations = (
            ("asset-digest", "migration/assets/catalog.json", "sha256"),
            ("asset-oid", "migration/assets/catalog.json", "gitBlobOid"),
            ("asset-size", "migration/assets/catalog.json", "byteSize"),
            ("asset-mode", "migration/assets/catalog.json", "gitMode"),
            ("metadata", "migration/assets/catalog.json", "intendedOwner"),
        )
        for name, path, field in mutations:
            with self.subTest(name=name):
                candidate = dict(documents)
                value = self.decoded(documents, path)
                if field in ("sha256", "gitBlobOid"):
                    value["assets"][0][field] = "0" * len(value["assets"][0][field])
                elif field == "byteSize":
                    value["assets"][0][field] += 1
                elif field == "gitMode":
                    value["assets"][0][field] = "100755"
                else:
                    value["assets"][0][field] = "quarantine/unresolved"
                candidate[path] = generator.canonical_json_bytes(value)
                root = self.decoded(documents, "migration/assets/index.json")
                shard = next(entry for entry in root["shards"] if entry["path"] == path)
                shard["sha256"] = hashlib.sha256(candidate[path]).hexdigest()
                candidate["migration/assets/index.json"] = generator.canonical_json_bytes(root)
                with self.assertRaisesRegex(
                    validator.InventoryValidationError,
                    "^migration asset inventory (?:document is invalid|does not match generated bytes)$",
                ):
                    validator.validate_inventory_documents(
                        candidate, expected_documents=documents
                    )

        candidate = dict(documents)
        root = self.decoded(documents, "migration/assets/index.json")
        root["shards"][0]["sha256"] = "0" * 64
        candidate["migration/assets/index.json"] = generator.canonical_json_bytes(root)
        with self.assertRaisesRegex(
            validator.InventoryValidationError,
            "^migration asset inventory shard digest is invalid$",
        ):
            validator.validate_inventory_documents(candidate)

        candidate = dict(documents)
        catalog_path = "migration/assets/catalog.json"
        catalog = self.decoded(documents, catalog_path)
        catalog["assets"][0]["gitBlobOid"] = "0" * 40
        candidate[catalog_path] = generator.canonical_json_bytes(catalog)
        root = self.decoded(documents, "migration/assets/index.json")
        next(entry for entry in root["shards"] if entry["path"] == catalog_path)[
            "sha256"
        ] = hashlib.sha256(candidate[catalog_path]).hexdigest()
        candidate["migration/assets/index.json"] = generator.canonical_json_bytes(root)
        with self.assertRaisesRegex(
            validator.InventoryValidationError,
            "^migration asset inventory document is invalid$",
        ):
            validator.validate_inventory_documents(candidate)

    def test_parser_rejects_duplicate_deep_crlf_noncanonical_and_oversized_json(self):
        validator = load_inventory_validator()
        invalid = (
            b'{"schemaVersion":1,"schema\\u0056ersion":1}\n',
            (b"[" * 129) + b"0" + (b"]" * 129) + b"\n",
            b'{"schemaVersion":1}\r\n',
            b'{ "schemaVersion": 1 }\n',
            b" " * (MAX_DOCUMENT_BYTES + 1),
            b"\xff",
        )
        for raw in invalid:
            with self.subTest(length=len(raw)):
                with self.assertRaisesRegex(
                    validator.InventoryValidationError,
                    "^migration asset inventory document is invalid$",
                ):
                    validator.parse_inventory_document(raw)

    def test_validator_rejects_oversized_index_blob_before_content_read(self):
        validator = load_inventory_validator()

        def git_result(_root, *arguments, **_kwargs):
            if arguments[:2] == ("cat-file", "-t"):
                output = b"blob\n"
            elif arguments[:2] == ("cat-file", "-s"):
                output = str(MAX_DOCUMENT_BYTES + 1).encode("ascii") + b"\n"
            else:
                self.fail(f"unexpected Git arguments: {arguments!r}")
            return subprocess.CompletedProcess(arguments, 0, output, b"")

        with mock.patch.object(
            validator.generator, "_run_git", side_effect=git_result
        ), mock.patch.object(
            validator.generator,
            "_read_blob",
            side_effect=AssertionError("oversized content was read"),
        ):
            with self.assertRaisesRegex(
                validator.InventoryValidationError,
                "^migration asset inventory reviewed file is invalid$",
            ):
                validator._read_index_document_bytes(ROOT, "1" * 40)

    def test_default_and_check_modes_are_read_only_and_write_is_allowlisted_atomic(self):
        documents = self.documents()
        with mock.patch.object(
            generator, "generate_inventory_documents", return_value=documents
        ), mock.patch.object(generator, "_check_inventory_documents") as check, mock.patch.object(
            generator, "_write_inventory_documents"
        ) as write, mock.patch("builtins.print"):
            self.assertEqual(generator.main([]), 0)
            self.assertEqual(generator.main(["--check"]), 0)
        self.assertEqual(check.call_count, 2)
        write.assert_not_called()

        with tempfile.TemporaryDirectory(prefix="inventory write ") as directory:
            destination = Path(directory).resolve()
            calls = []
            real_replace = os.replace

            def recording_replace(source, target, *args, **kwargs):
                calls.append((Path(source), Path(target), dict(kwargs)))
                return real_replace(source, target, *args, **kwargs)

            with mock.patch.object(generator.os, "replace", side_effect=recording_replace):
                generator._write_inventory_documents(destination, documents)
            self.assertEqual(
                {path.relative_to(destination).as_posix() for path in destination.rglob("*.json")},
                set(OUTPUT_RELATIVE_PATHS),
            )
            self.assertEqual(
                {target.name for _, target, _ in calls},
                {Path(path).name for path in OUTPUT_RELATIVE_PATHS},
            )
            self.assertTrue(
                all(
                    source.parent == target.parent
                    if not kwargs
                    else kwargs.get("src_dir_fd") == kwargs.get("dst_dir_fd")
                    for source, target, kwargs in calls
                )
            )
            self.assertFalse(any(path.suffix == ".tmp" for path in destination.rglob("*")))

        hostile = dict(documents)
        hostile["migration/assets/not-allowlisted.json"] = b"{}\n"
        with self.assertRaisesRegex(
            InventoryError, "^inventory output path set is invalid$"
        ):
            generator._write_inventory_documents(ROOT, hostile)

        with tempfile.TemporaryDirectory(prefix="inventory symlink write ") as directory:
            destination = Path(directory).resolve()
            external = destination / "external"
            external.mkdir()
            try:
                (destination / "migration").symlink_to(
                    external, target_is_directory=True
                )
            except OSError as error:
                self.skipTest(f"directory symlink creation is unavailable: {error}")
            with self.assertRaisesRegex(
                InventoryError, "^inventory output path is invalid$"
            ):
                generator._write_inventory_documents(destination, documents)

    def test_committed_outputs_check_and_validator_cli_are_stable_under_hostile_git_env(self):
        for arguments in ((), ("--check",)):
            result = subprocess.run(
                [sys.executable, "-B", str(GENERATOR_PATH), *arguments],
                cwd=ROOT,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0)
            self.assertEqual(result.stderr, b"")
            self.assertEqual(
                result.stdout,
                b"Mac-Win migration asset inventory is current." + NATIVE_LINE_ENDING,
            )

        for hostile in (
            {"GIT_TEST_ASSUME_DIFFERENT_OWNER": "1"},
            {
                "GIT_DIR": str(ROOT / "decoy.git"),
                "GIT_WORK_TREE": str(ROOT / "decoy-worktree"),
                "GIT_CONFIG_COUNT": "1",
                "GIT_CONFIG_KEY_0": "core.abbrev",
                "GIT_CONFIG_VALUE_0": "invalid",
            },
        ):
            environment = os.environ.copy()
            environment.update(hostile)
            result = subprocess.run(
                [sys.executable, "-B", str(VALIDATOR_PATH)],
                cwd=ROOT,
                env=environment,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0)
            self.assertEqual(result.stderr, b"")
            self.assertEqual(
                result.stdout,
                b"Mac-Win migration asset inventory is valid." + NATIVE_LINE_ENDING,
            )

    def test_validator_rejects_untracked_symlink_index_and_worktree_drift(self):
        validator = load_inventory_validator()
        documents = self.documents()
        policy = generator.load_policy()
        with mock.patch.object(
            validator, "_read_reviewed_policy", return_value=policy
        ) as read_policy, mock.patch.object(
            validator, "generate_inventory_documents", return_value=documents
        ) as generate:
            validator.validate_inventory(ROOT)
        read_policy.assert_called_once_with(ROOT)
        generate.assert_called_once_with(ROOT, policy=policy)

        relative_path = "migration/assets/catalog.json"
        with mock.patch.object(
            validator, "_read_reviewed_policy", return_value=policy
        ), mock.patch.object(
            validator, "generate_inventory_documents", return_value=documents
        ), mock.patch.object(
            validator, "_read_reviewed_document",
            side_effect=validator.InventoryValidationError(
                "migration asset inventory reviewed file is invalid"
            ),
        ):
            with self.assertRaisesRegex(
                validator.InventoryValidationError,
                "^migration asset inventory reviewed file is invalid$",
            ):
                validator.validate_inventory(ROOT)
        self.assertIn(relative_path, documents)


class InventoryGenerationFailureTests(unittest.TestCase):
    def test_validator_normalizes_all_generator_contract_failures_without_reflection(self):
        validator = load_inventory_validator()
        policy = generator.load_policy()
        failures = (
            "inventory governed Git object is invalid",
            "inventory governed Git object identity is invalid",
            "inventory dependency evidence does not match policy",
            "hostile path\n\x1b[31mspoofed diagnostic",
        )
        for diagnostic in failures:
            with self.subTest(diagnostic=diagnostic):
                with mock.patch.object(
                    validator, "_read_reviewed_policy", return_value=policy
                ), mock.patch.object(
                    validator,
                    "generate_inventory_documents",
                    side_effect=validator.generator.InventoryError(diagnostic),
                ):
                    with self.assertRaisesRegex(
                        validator.InventoryValidationError,
                        "^migration asset inventory generation failed$",
                    ) as caught:
                        validator.validate_inventory(ROOT)
                self.assertNotIn("hostile", str(caught.exception))
                self.assertNotIn("spoofed", str(caught.exception))

    def test_validator_does_not_swallow_os_or_programming_errors(self):
        validator = load_inventory_validator()
        policy = generator.load_policy()
        for failure in (OSError("filesystem failure"), RuntimeError("programming bug")):
            with self.subTest(error_type=type(failure).__name__):
                with mock.patch.object(
                    validator, "_read_reviewed_policy", return_value=policy
                ), mock.patch.object(
                    validator,
                    "generate_inventory_documents",
                    side_effect=failure,
                ):
                    with self.assertRaises(type(failure)) as caught:
                        validator.validate_inventory(ROOT)
                self.assertIs(caught.exception, failure)

    def test_isolated_entrypoint_returns_fixed_single_line_failure_without_cache(self):
        source = """
import tools.validate_migration_asset_inventory as validator
validator._read_reviewed_policy = lambda _root: {}
def fail(*_args, **_kwargs):
    raise validator.generator.InventoryError(
        "hostile missing object\\n\\x1b[31mspoofed diagnostic"
    )
validator.generate_inventory_documents = fail
raise SystemExit(validator.main([]))
"""
        with tempfile.TemporaryDirectory(
            prefix="inventory failure cache "
        ) as directory:
            cache = Path(directory) / "cache"
            environment = os.environ.copy()
            environment["PYTHONDONTWRITEBYTECODE"] = "1"
            environment["PYTHONPYCACHEPREFIX"] = str(cache)
            result = subprocess.run(
                [sys.executable, "-B", "-c", source],
                cwd=ROOT,
                env=environment,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, b"")
            self.assertEqual(
                result.stderr,
                b"migration asset inventory failed: "
                b"migration asset inventory generation failed"
                + NATIVE_LINE_ENDING,
            )
            self.assertNotIn(b"Traceback", result.stderr)
            self.assertNotIn(b"hostile", result.stderr)
            self.assertNotIn(b"spoofed", result.stderr)
            self.assertEqual(list(cache.rglob("*.pyc")), [])


class ReviewedInventoryFileTests(unittest.TestCase):
    def test_policy_reader_rejects_parent_and_leaf_links_but_allows_hardlinks(self):
        policy_raw = POLICY_PATH.read_bytes()
        with tempfile.TemporaryDirectory(prefix="inventory reviewed policy ") as directory:
            root = Path(directory).resolve()
            assets = root / "migration" / "assets"
            assets.mkdir(parents=True)
            source = root / "policy-source.json"
            source.write_bytes(policy_raw)
            reviewed = assets / "metadata-policy.json"
            os.link(source, reviewed)
            self.assertEqual(
                generator.load_policy(reviewed, repository_root=root)["schemaVersion"],
                1,
            )

            reviewed.unlink()
            try:
                reviewed.symlink_to(source)
            except OSError as error:
                self.skipTest(f"file symlink creation is unavailable: {error}")
            with self.assertRaisesRegex(
                InventoryError, "^inventory policy could not be read$"
            ):
                generator.load_policy(reviewed, repository_root=root)

        with tempfile.TemporaryDirectory(prefix="inventory reviewed parent ") as directory:
            root = Path(directory).resolve()
            external = root / "external"
            (external / "assets").mkdir(parents=True)
            (external / "assets" / "metadata-policy.json").write_bytes(policy_raw)
            try:
                (root / "migration").symlink_to(external, target_is_directory=True)
            except OSError as error:
                self.skipTest(f"directory symlink creation is unavailable: {error}")
            with self.assertRaisesRegex(
                InventoryError, "^inventory policy could not be read$"
            ):
                generator.load_policy(
                    root / "migration" / "assets" / "metadata-policy.json",
                    repository_root=root,
                )

    def test_check_reader_rejects_linked_parent_even_when_all_bytes_match(self):
        documents = {path: b"{}\n" for path in OUTPUT_RELATIVE_PATHS}
        with tempfile.TemporaryDirectory(prefix="inventory linked output ") as directory:
            root = Path(directory).resolve()
            external = root / "external"
            assets = external / "assets"
            assets.mkdir(parents=True)
            for relative_path, raw in documents.items():
                (assets / Path(relative_path).name).write_bytes(raw)
            try:
                (root / "migration").symlink_to(external, target_is_directory=True)
            except OSError as error:
                self.skipTest(f"directory symlink creation is unavailable: {error}")
            with self.assertRaisesRegex(
                InventoryError, "^inventory output is missing or unsafe$"
            ):
                generator._check_inventory_documents(root, documents)

    def test_validator_worktree_read_delegates_to_shared_hardened_reader(self):
        validator = load_inventory_validator()
        expected = b"reviewed\n"
        with mock.patch.object(
            validator.generator,
            "_read_bounded_reviewed_file",
            return_value=expected,
        ) as read:
            self.assertEqual(
                validator._read_exact_worktree_bytes(
                    ROOT, "migration/assets/index.json"
                ),
                expected,
            )
        read.assert_called_once_with(
            ROOT, "migration/assets/index.json", MAX_DOCUMENT_BYTES
        )


class InventoryTransactionalWriteTests(unittest.TestCase):
    def documents(self, marker):
        return {
            path: f"{marker}:{path}\n".encode("utf-8")
            for path in OUTPUT_RELATIVE_PATHS
        }

    def prepare(self, root, documents):
        assets = root / "migration" / "assets"
        assets.mkdir(parents=True)
        for relative_path, raw in documents.items():
            (root / PurePosixPath(relative_path)).write_bytes(raw)
        return assets

    def assert_documents(self, root, documents):
        for relative_path, raw in documents.items():
            self.assertEqual((root / PurePosixPath(relative_path)).read_bytes(), raw)

    def assert_no_transaction_temps(self, assets):
        self.assertEqual(list(assets.glob("*.tmp")), [])

    def test_all_new_and_backup_files_are_staged_before_first_replace(self):
        old = self.documents("old")
        new = self.documents("new")
        with tempfile.TemporaryDirectory(prefix="inventory staged write ") as directory:
            root = Path(directory).resolve()
            assets = self.prepare(root, old)
            real_replace = os.replace
            observed = []

            def inspect_first_replace(source, target, *args, **kwargs):
                if not observed:
                    observed.append(len(list(assets.glob("*.tmp"))))
                return real_replace(source, target, *args, **kwargs)

            with mock.patch.object(
                generator.os, "replace", side_effect=inspect_first_replace
            ):
                generator._write_inventory_documents(root, new)
            self.assertEqual(observed, [14])
            self.assert_documents(root, new)
            self.assertEqual(list(assets.glob("*.tmp")), [])

    def test_each_replace_failure_rolls_back_all_seven_documents(self):
        old = self.documents("old")
        new = self.documents("new")
        for failure_position in range(1, 8):
            with self.subTest(failure_position=failure_position), tempfile.TemporaryDirectory(
                prefix="inventory rollback write "
            ) as directory:
                root = Path(directory).resolve()
                assets = self.prepare(root, old)
                real_replace = os.replace
                replacements = 0

                def fail_selected_replace(source, target, *args, **kwargs):
                    nonlocal replacements
                    if Path(target).name in {
                        Path(path).name for path in OUTPUT_RELATIVE_PATHS
                    } and Path(source).name.endswith(".tmp"):
                        replacements += 1
                        if replacements == failure_position:
                            raise OSError("injected destination replace failure")
                    return real_replace(source, target, *args, **kwargs)

                with mock.patch.object(
                    generator.os, "replace", side_effect=fail_selected_replace
                ):
                    with self.assertRaisesRegex(
                        InventoryError, "^inventory output transaction failed$"
                    ):
                        generator._write_inventory_documents(root, new)
                self.assert_documents(root, old)
                self.assertEqual(list(assets.glob("*.tmp")), [])

    def test_parent_replacement_is_detected_without_external_writes(self):
        old = self.documents("old")
        with tempfile.TemporaryDirectory(prefix="inventory parent swap ") as directory:
            root = Path(directory).resolve()
            assets = self.prepare(root, old)
            external = root / "external"
            external.mkdir()
            snapshot = generator._snapshot_output_directory(root)
            displaced = root / "assets-displaced"
            assets.rename(displaced)
            try:
                assets.symlink_to(external, target_is_directory=True)
            except OSError as error:
                displaced.rename(assets)
                self.skipTest(f"directory symlink creation is unavailable: {error}")
            try:
                with self.assertRaisesRegex(
                    InventoryError, "^inventory output path changed$"
                ):
                    generator._verify_output_directory_identity(root, snapshot)
                self.assertEqual(list(external.iterdir()), [])
            finally:
                assets.unlink()
                displaced.rename(assets)
            self.assert_documents(root, old)

    def test_full_write_parent_swap_before_first_temp_create_leaves_no_external_files(self):
        old = self.documents("old")
        new = self.documents("new")
        with tempfile.TemporaryDirectory(prefix="inventory write parent swap ") as directory:
            root = Path(directory).resolve()
            assets = self.prepare(root, old)
            external = root / "external"
            external.mkdir()
            displaced = root / "assets-displaced"
            real_create = generator._create_output_temp
            swapped = False

            def swap_before_first_create(*args, **kwargs):
                nonlocal swapped
                if not swapped:
                    assets.rename(displaced)
                    try:
                        assets.symlink_to(external, target_is_directory=True)
                    except OSError as error:
                        displaced.rename(assets)
                        self.skipTest(
                            f"directory symlink creation is unavailable: {error}"
                        )
                    swapped = True
                return real_create(*args, **kwargs)

            try:
                with mock.patch.object(
                    generator,
                    "_create_output_temp",
                    side_effect=swap_before_first_create,
                ):
                    with self.assertRaisesRegex(
                        InventoryError, "^inventory output transaction failed$"
                    ):
                        generator._write_inventory_documents(root, new)
            finally:
                if swapped:
                    assets.unlink()
                    displaced.rename(assets)

            self.assertEqual(list(external.iterdir()), [])
            self.assert_documents(root, old)
            self.assertEqual(list(assets.glob("*.tmp")), [])

    def test_existing_leaf_symlink_is_rejected_without_external_read_or_mutation(self):
        old = self.documents("old")
        new = self.documents("new")
        with tempfile.TemporaryDirectory(prefix="inventory leaf symlink ") as directory:
            root = Path(directory).resolve()
            assets = self.prepare(root, old)
            relative_path = OUTPUT_RELATIVE_PATHS[0]
            destination = root / PurePosixPath(relative_path)
            displaced = root / "index-displaced.json"
            external = root / "external-index.json"
            external_raw = b"external sentinel must remain unread and unchanged\n"
            external.write_bytes(external_raw)
            destination.rename(displaced)
            try:
                destination.symlink_to(external)
            except OSError as error:
                displaced.rename(destination)
                self.skipTest(f"file symlink creation is unavailable: {error}")

            real_path_open = Path.open

            def reject_link_follow(path, *args, **kwargs):
                if Path(path) == destination:
                    raise AssertionError("linked external file was opened")
                return real_path_open(path, *args, **kwargs)

            try:
                with mock.patch.object(Path, "open", reject_link_follow):
                    with self.assertRaisesRegex(
                        InventoryError, "^inventory output transaction failed$"
                    ):
                        generator._write_inventory_documents(root, new)
            finally:
                destination.unlink(missing_ok=True)
                displaced.rename(destination)

            self.assertEqual(external.read_bytes(), external_raw)
            self.assert_documents(root, old)
            self.assert_no_transaction_temps(assets)

    def test_existing_leaf_hardlink_is_an_allowed_regular_file(self):
        old = self.documents("old")
        new = self.documents("new")
        with tempfile.TemporaryDirectory(prefix="inventory leaf hardlink ") as directory:
            root = Path(directory).resolve()
            assets = self.prepare(root, old)
            relative_path = OUTPUT_RELATIVE_PATHS[0]
            destination = root / PurePosixPath(relative_path)
            external = root / "hardlinked-index.json"
            destination.rename(external)
            os.link(external, destination)

            generator._write_inventory_documents(root, new)

            self.assertEqual(external.read_bytes(), old[relative_path])
            self.assert_documents(root, new)
            self.assert_no_transaction_temps(assets)

    def test_leaf_swap_between_status_and_open_is_rejected_before_read(self):
        old = self.documents("old")
        new = self.documents("new")
        with tempfile.TemporaryDirectory(prefix="inventory leaf open swap ") as directory:
            root = Path(directory).resolve()
            assets = self.prepare(root, old)
            relative_path = OUTPUT_RELATIVE_PATHS[0]
            destination = root / PurePosixPath(relative_path)
            displaced = root / "index-displaced.json"
            external = root / "external-index.json"
            external_raw = b"external swap sentinel must remain unread and unchanged\n"
            external.write_bytes(external_raw)
            real_status = generator._destination_status
            real_path_open = Path.open
            swapped = False

            def swap_after_status(path, directory_fd):
                nonlocal swapped
                status = real_status(path, directory_fd)
                if not swapped and Path(path) == destination:
                    destination.rename(displaced)
                    try:
                        destination.symlink_to(external)
                    except OSError as error:
                        displaced.rename(destination)
                        self.skipTest(
                            f"file symlink creation is unavailable: {error}"
                        )
                    swapped = True
                return status

            def reject_link_follow(path, *args, **kwargs):
                if Path(path) == destination:
                    raise AssertionError("swapped external file was opened")
                return real_path_open(path, *args, **kwargs)

            try:
                with mock.patch.object(
                    generator,
                    "_destination_status",
                    side_effect=swap_after_status,
                ), mock.patch.object(Path, "open", reject_link_follow):
                    with self.assertRaisesRegex(
                        InventoryError, "^inventory output transaction failed$"
                    ):
                        generator._write_inventory_documents(root, new)
            finally:
                if swapped:
                    destination.unlink(missing_ok=True)
                    displaced.rename(destination)

            self.assertEqual(external.read_bytes(), external_raw)
            self.assert_documents(root, old)
            self.assert_no_transaction_temps(assets)

    def test_leaf_swap_after_backup_read_is_rejected_before_replace(self):
        old = self.documents("old")
        new = self.documents("new")
        with tempfile.TemporaryDirectory(prefix="inventory leaf replace swap ") as directory:
            root = Path(directory).resolve()
            assets = self.prepare(root, old)
            relative_path = OUTPUT_RELATIVE_PATHS[0]
            destination = root / PurePosixPath(relative_path)
            displaced = root / "index-displaced.json"
            external = root / "external-index.json"
            external_raw = b"external replace sentinel must remain unchanged\n"
            external.write_bytes(external_raw)
            real_read = generator._read_output_file
            swapped = False

            def swap_after_read(token, maximum_bytes, directory_fd, repository_root):
                nonlocal swapped
                raw = real_read(
                    token, maximum_bytes, directory_fd, repository_root
                )
                token_path = Path(token)
                is_destination = token_path == destination or (
                    directory_fd is not None
                    and token_path.name == destination.name
                )
                if not swapped and is_destination:
                    destination.rename(displaced)
                    try:
                        destination.symlink_to(external)
                    except OSError as error:
                        displaced.rename(destination)
                        self.skipTest(
                            f"file symlink creation is unavailable: {error}"
                        )
                    swapped = True
                return raw

            try:
                with mock.patch.object(
                    generator, "_read_output_file", side_effect=swap_after_read
                ):
                    with self.assertRaisesRegex(
                        InventoryError, "^inventory output transaction failed$"
                    ):
                        generator._write_inventory_documents(root, new)
            finally:
                if swapped:
                    destination.unlink(missing_ok=True)
                    displaced.rename(destination)

            self.assertEqual(external.read_bytes(), external_raw)
            self.assert_documents(root, old)
            self.assert_no_transaction_temps(assets)


class InventoryRendererBoundaryTests(unittest.TestCase):
    def assert_renderer_error(self, value):
        with self.assertRaisesRegex(
            InventoryError, "^inventory output document is invalid$"
        ):
            generator.canonical_json_bytes(value)

    def test_iterative_depth_gate_rejects_deep_and_cyclic_values_stably(self):
        deep = 0
        for _ in range(MAX_JSON_DEPTH + 1):
            deep = [deep]
        self.assert_renderer_error(deep)

        very_deep = 0
        for _ in range(2000):
            very_deep = [very_deep]
        self.assert_renderer_error(very_deep)

        cyclic = []
        cyclic.append(cyclic)
        self.assert_renderer_error(cyclic)

    def test_renderer_accepts_only_closed_json_v1_scalars_and_string_keys(self):
        accepted = {
            "null": None,
            "boolean": True,
            "integer": 1,
            "string": "value",
            "array": [False, 0, "x"],
            "object": {"nested": None},
        }
        self.assertTrue(generator.canonical_json_bytes(accepted).endswith(b"\n"))

        for value in (
            1.5,
            float("nan"),
            float("inf"),
            b"bytes",
            ("tuple",),
            {"set"},
            {1: "non-string-key"},
            10 ** (generator.MAX_JSON_INTEGER_DIGITS + 1),
        ):
            with self.subTest(value_type=type(value).__name__):
                self.assert_renderer_error(value)

    def test_integer_digit_limit_is_checked_before_decimal_rendering(self):
        boundary = (10 ** generator.MAX_JSON_INTEGER_DIGITS) - 1
        for accepted in (boundary, -boundary):
            self.assertIn(
                str(accepted).encode("ascii"),
                generator.canonical_json_bytes(accepted),
            )

        for digits in (generator.MAX_JSON_INTEGER_DIGITS + 1, 5001):
            with self.subTest(digits=digits):
                value = 10 ** (digits - 1)
                self.assert_renderer_error(value)
                self.assert_renderer_error(-value)


if __name__ == "__main__":
    unittest.main()

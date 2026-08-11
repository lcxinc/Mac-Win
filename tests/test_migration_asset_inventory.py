"""Tests for the canonical migration asset inventory contract."""

import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
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
NATIVE_LINE_ENDING = os.linesep.encode("ascii")


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
            b"usage: generate_migration_asset_inventory.py [--list]"
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
                    if argument != "--":
                        self.assertNotIn(argument.encode("utf-8"), result.stderr)

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
                "environment-path": 49,
                "repository-path": 35,
            },
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
                "GIT_NO_LAZY_FETCH", "GIT_NO_REPLACE_OBJECTS", "GIT_TERMINAL_PROMPT"
            )},
            {"GIT_NO_LAZY_FETCH": "1", "GIT_NO_REPLACE_OBJECTS": "1", "GIT_TERMINAL_PROMPT": "0"},
        )
        self.assertFalse(any(key.startswith("GIT_CONFIG_") for key in cleaned))
        for key in hostile:
            if key.startswith("GIT_"):
                self.assertNotIn(key, cleaned)

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


if __name__ == "__main__":
    unittest.main()

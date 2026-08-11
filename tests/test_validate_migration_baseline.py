import copy
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


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
HOSTILE_JSON_INPUTS = (
    ("deep nesting", ("[" * 3000 + "0" + "]" * 3000).encode("ascii")),
    ("oversized integer", ("9" * 5000).encode("ascii")),
)
HOSTILE_KEYS = (
    "line\nbreak",
    "escape\x1b[31m",
    "lone-surrogate-\ud800",
    "k" * 10_000,
)


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
        with self.assertRaises(validator.BaselineValidationError) as caught:
            validator.validate_manifest(manifest)
        self.assertEqual(str(caught.exception), diagnostic)

    def assertRawInvalid(self, raw, diagnostic):
        validator = load_validator()
        with self.assertRaises(validator.BaselineValidationError) as caught:
            validator.parse_manifest_bytes(raw)
        self.assertEqual(str(caught.exception), diagnostic)

    def runIsolatedValidator(self, raw):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tools = root / "tools"
            migration = root / "migration"
            tools.mkdir()
            migration.mkdir()
            validator_path = tools / VALIDATOR_PATH.name
            shutil.copyfile(VALIDATOR_PATH, validator_path)
            (migration / "baseline.json").write_bytes(raw)

            environment = os.environ.copy()
            bytecode_variables = {"PYTHONDONTWRITEBYTECODE", "PYTHONPYCACHEPREFIX"}
            for key in tuple(environment):
                if key.upper() in bytecode_variables:
                    del environment[key]
            result = subprocess.run(
                [sys.executable, str(validator_path)],
                cwd=root,
                env=environment,
                capture_output=True,
                text=True,
                check=False,
            )

            self.assertEqual(list(root.rglob("__pycache__")), [])
            self.assertEqual(list(root.rglob("*.pyc")), [])
            return result

    def assertEntrypointInvalid(self, raw, diagnostic):
        result = self.runIsolatedValidator(raw)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertEqual(
            result.stderr,
            f"migration baseline validation failed: {diagnostic}\n",
        )
        self.assertNotIn("Traceback", result.stderr)

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
        self.assertInvalid(mutated, "manifest has unknown field")

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
            "manifest has duplicate JSON key",
        )

    def test_rejects_unicode_escaped_duplicate_json_keys(self):
        self.assertRawInvalid(
            b'{"repository":"a1112/Mac-Win","repos\\u0069tory":"other"}',
            "manifest has duplicate JSON key",
        )

    def test_rejects_duplicate_nested_json_keys(self):
        self.assertRawInvalid(
            b'{"evidenceTargets":[{"runner":"macos-15","runn\\u0065r":"other"}]}',
            "manifest has duplicate JSON key",
        )

    def test_direct_hostile_json_failures_have_one_stable_error(self):
        validator = load_validator()
        for name, raw in HOSTILE_JSON_INPUTS:
            with self.subTest(name=name):
                self.assertLessEqual(len(raw), validator.MAX_MANIFEST_BYTES)
                self.assertRawInvalid(raw, "manifest is not valid JSON")

    def test_entrypoint_hostile_json_failures_have_one_stable_error(self):
        validator = load_validator()
        for name, raw in HOSTILE_JSON_INPUTS:
            with self.subTest(name=name):
                self.assertLessEqual(len(raw), validator.MAX_MANIFEST_BYTES)
                self.assertEntrypointInvalid(raw, "manifest is not valid JSON")

    def test_direct_duplicate_key_diagnostics_never_echo_hostile_keys(self):
        validator = load_validator()
        for key in HOSTILE_KEYS:
            with self.subTest(key=repr(key[:40])):
                encoded_key = json.dumps(key, ensure_ascii=True)
                raw = f"{{{encoded_key}:1,{encoded_key}:2}}".encode("ascii")
                self.assertLessEqual(len(raw), validator.MAX_MANIFEST_BYTES)
                self.assertRawInvalid(raw, "manifest has duplicate JSON key")

    def test_entrypoint_duplicate_key_diagnostics_never_echo_hostile_keys(self):
        validator = load_validator()
        for key in HOSTILE_KEYS:
            with self.subTest(key=repr(key[:40])):
                encoded_key = json.dumps(key, ensure_ascii=True)
                raw = f"{{{encoded_key}:1,{encoded_key}:2}}".encode("ascii")
                self.assertLessEqual(len(raw), validator.MAX_MANIFEST_BYTES)
                self.assertEntrypointInvalid(raw, "manifest has duplicate JSON key")

    def test_direct_unknown_key_diagnostics_never_echo_hostile_keys(self):
        validator = load_validator()
        for key in HOSTILE_KEYS:
            with self.subTest(key=repr(key[:40])):
                mutated = copy.deepcopy(CANONICAL)
                mutated[key] = True
                raw = json.dumps(
                    mutated, ensure_ascii=True, separators=(",", ":")
                ).encode("ascii")
                self.assertLessEqual(len(raw), validator.MAX_MANIFEST_BYTES)
                self.assertInvalid(mutated, "manifest has unknown field")

    def test_entrypoint_unknown_key_diagnostics_never_echo_hostile_keys(self):
        validator = load_validator()
        for key in HOSTILE_KEYS:
            with self.subTest(key=repr(key[:40])):
                mutated = copy.deepcopy(CANONICAL)
                mutated[key] = True
                raw = json.dumps(
                    mutated, ensure_ascii=True, separators=(",", ":")
                ).encode("ascii")
                self.assertLessEqual(len(raw), validator.MAX_MANIFEST_BYTES)
                self.assertEntrypointInvalid(raw, "manifest has unknown field")

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


class MigrationBaselineGitSourceTests(unittest.TestCase):
    GIT_IDENTITY = (
        "-c",
        "user.name=Mac-Win Baseline Tests",
        "-c",
        "user.email=baseline-tests@example.invalid",
    )
    GIT_OVERRIDE_VARIABLES = (
        "GIT_DIR",
        "GIT_WORK_TREE",
        "GIT_COMMON_DIR",
        "GIT_INDEX_FILE",
        "GIT_OBJECT_DIRECTORY",
        "GIT_ALTERNATE_OBJECT_DIRECTORIES",
        "GIT_NAMESPACE",
    )
    GIT_SAFETY_VARIABLES = {
        "GIT_NO_LAZY_FETCH": "1",
        "GIT_TERMINAL_PROMPT": "0",
        "GIT_NO_REPLACE_OBJECTS": "1",
    }

    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.test_root = Path(self.temporary_directory.name)

    def runGit(self, repository, *arguments, environment=None, check=True):
        repository = Path(repository)
        repository.mkdir(parents=True, exist_ok=True)
        command = ["git", *self.GIT_IDENTITY, *arguments]
        result = subprocess.run(
            command,
            cwd=repository,
            env=environment,
            capture_output=True,
            text=True,
            shell=False,
            check=False,
        )
        if check and result.returncode != 0:
            self.fail(
                f"Git fixture command failed ({result.returncode}): "
                f"{command!r}\nstdout: {result.stdout}\nstderr: {result.stderr}"
            )
        return result

    def createRepository(
        self,
        name,
        source_text="source\n",
        descendant_text="descendant\n",
    ):
        repository = self.test_root / name
        self.runGit(repository, "init", "-b", "main")

        tracked = repository / "tracked.txt"
        tracked.write_text(source_text, encoding="utf-8")
        self.runGit(repository, "add", "tracked.txt")
        self.runGit(repository, "commit", "-m", "source")
        source_commit = self.runGit(
            repository, "rev-parse", "HEAD"
        ).stdout.strip()

        tracked.write_text(descendant_text, encoding="utf-8")
        self.runGit(repository, "add", "tracked.txt")
        self.runGit(repository, "commit", "-m", "descendant")
        descendant_commit = self.runGit(
            repository, "rev-parse", "HEAD"
        ).stdout.strip()
        return repository, source_commit, descendant_commit

    def assertSourceInvalid(self, repository, source_commit, diagnostic):
        validator = load_validator()
        with self.assertRaises(validator.BaselineValidationError) as caught:
            validator.validate_source_commit(repository, source_commit)
        self.assertEqual(str(caught.exception), diagnostic)

    def test_accepts_local_commit_that_is_an_ancestor_of_head(self):
        repository, source_commit, _ = self.createRepository("target")
        validator = load_validator()

        validator.validate_source_commit(repository, source_commit)

    def test_rejects_missing_source_object_with_stable_diagnostic(self):
        repository, _, _ = self.createRepository("target")

        self.assertSourceInvalid(
            repository,
            "0" * 40,
            "source commit is not a local commit object",
        )

    def test_rejects_blob_tree_and_tag_objects_as_source_commits(self):
        repository, source_commit, _ = self.createRepository("target")
        blob = self.runGit(
            repository, "rev-parse", f"{source_commit}:tracked.txt"
        ).stdout.strip()
        tree = self.runGit(
            repository, "rev-parse", f"{source_commit}^{{tree}}"
        ).stdout.strip()
        self.runGit(
            repository,
            "tag",
            "-a",
            "source-tag",
            source_commit,
            "-m",
            "tag",
        )
        tag = self.runGit(
            repository, "rev-parse", "refs/tags/source-tag"
        ).stdout.strip()

        objects = (("blob", blob), ("tree", tree), ("tag", tag))
        for object_name, object_id in objects:
            with self.subTest(object_type=object_name):
                self.assertSourceInvalid(
                    repository,
                    object_id,
                    "source commit is not a local commit object",
                )

    def test_rejects_local_commit_that_is_not_an_ancestor_of_head(self):
        repository, source_commit, _ = self.createRepository("target")
        tree = self.runGit(
            repository, "rev-parse", f"{source_commit}^{{tree}}"
        ).stdout.strip()
        unrelated_commit = self.runGit(
            repository, "commit-tree", tree, "-m", "unrelated root"
        ).stdout.strip()

        self.assertSourceInvalid(
            repository,
            unrelated_commit,
            "source commit is not an ancestor of HEAD",
        )

    def test_replace_ref_cannot_supply_a_missing_source_commit(self):
        repository, source_commit, _ = self.createRepository("target")
        replaced_object = "1" * 40
        self.runGit(
            repository,
            "update-ref",
            f"refs/replace/{replaced_object}",
            source_commit,
        )
        unprotected_environment = os.environ.copy()
        unprotected_environment.pop("GIT_NO_REPLACE_OBJECTS", None)
        self.assertEqual(
            self.runGit(
                repository,
                "cat-file",
                "-t",
                replaced_object,
                environment=unprotected_environment,
            ).stdout.strip(),
            "commit",
        )

        self.assertSourceInvalid(
            repository,
            replaced_object,
            "source commit is not a local commit object",
        )

    def test_git_subprocesses_use_target_and_sanitized_environment(self):
        repository, source_commit, _ = self.createRepository("target")
        alternate, _, _ = self.createRepository(
            "alternate",
            source_text="alternate source\n",
            descendant_text="alternate descendant\n",
        )
        alternate_git = alternate / ".git"
        self.assertNotEqual(
            self.runGit(
                alternate,
                "cat-file",
                "-t",
                source_commit,
                check=False,
            ).returncode,
            0,
            "fixture must prove the target source object is absent from the alternate",
        )
        pollution = {
            "GIT_DIR": str(alternate_git),
            "GIT_WORK_TREE": str(alternate),
            "GIT_COMMON_DIR": str(alternate_git),
            "GIT_INDEX_FILE": str(alternate_git / "index"),
            "GIT_OBJECT_DIRECTORY": str(alternate_git / "objects"),
            "GIT_ALTERNATE_OBJECT_DIRECTORIES": str(alternate_git / "objects"),
            "GIT_NAMESPACE": "redirected",
        }
        validator = load_validator()
        real_run = subprocess.run
        recorded_calls = []

        def recording_run(*args, **kwargs):
            recorded_calls.append((args, kwargs))
            return real_run(*args, **kwargs)

        with mock.patch.dict(os.environ, pollution, clear=False):
            with mock.patch.object(
                validator.subprocess, "run", side_effect=recording_run
            ):
                validator.validate_source_commit(repository, source_commit)

        self.assertEqual(len(recorded_calls), 2)
        self.assertEqual(
            [call[0][0] for call in recorded_calls],
            [
                ["git", "cat-file", "-t", source_commit],
                [
                    "git",
                    "merge-base",
                    "--is-ancestor",
                    source_commit,
                    "HEAD",
                ],
            ],
        )
        for positional, keywords in recorded_calls:
            with self.subTest(argv=positional[0]):
                self.assertIsInstance(positional[0], list)
                self.assertEqual(keywords["cwd"], repository.resolve())
                self.assertIs(keywords["shell"], False)
                self.assertIs(keywords["capture_output"], True)
                self.assertIs(keywords["text"], False)
                self.assertIs(keywords["check"], False)
                child_environment = keywords["env"]
                for variable in self.GIT_OVERRIDE_VARIABLES:
                    self.assertNotIn(variable, child_environment)
                for variable, value in self.GIT_SAFETY_VARIABLES.items():
                    self.assertEqual(child_environment.get(variable), value)

    def test_main_validates_source_after_loading_manifest(self):
        validator = load_validator()
        events = []

        def load_manifest():
            events.append("manifest")
            return copy.deepcopy(CANONICAL)

        def validate_source_commit(repository, source_commit):
            events.append(("source", repository, source_commit))

        with mock.patch.object(validator, "load_manifest", side_effect=load_manifest):
            with mock.patch.object(
                validator,
                "validate_source_commit",
                side_effect=validate_source_commit,
            ):
                with mock.patch("builtins.print"):
                    self.assertEqual(validator.main(), 0)

        self.assertEqual(
            events,
            [
                "manifest",
                ("source", validator.ROOT, validator.SOURCE_COMMIT),
            ],
        )


if __name__ == "__main__":
    unittest.main()

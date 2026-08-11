#!/usr/bin/env python3
"""Validate the closed Mac-Win migration baseline manifest contract."""

import hashlib
import json
import os
from pathlib import Path, PurePosixPath, PureWindowsPath
import re
import stat
import subprocess
import sys


MAX_MANIFEST_BYTES = 65_536
MAX_README_BYTES = 4_096
MAX_MIGRATION_DOCUMENT_BYTES = 32_768
MAX_WORKFLOW_BYTES = 16_384
MAX_JSON_INTEGER_DIGITS = 128
ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "migration" / "baseline.json"
MANIFEST_RELATIVE_PATH = "migration/baseline.json"
README_RELATIVE_PATH = "README.md"
MIGRATION_DOCUMENT_RELATIVE_PATH = "docs/migration-baseline.md"
WORKFLOW_RELATIVE_PATH = ".github/workflows/migration-baseline.yml"

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
APPROVED_MANIFEST_TEXT = json.dumps(
    {
        "schemaVersion": SCHEMA_VERSION,
        "repository": REPOSITORY,
        "sourceCommit": SOURCE_COMMIT,
        "tag": TAG,
        "swiftPackagePath": SWIFT_PACKAGE_PATH,
        "evidenceTargets": EVIDENCE_TARGETS,
        "frozenFeatureAreas": FROZEN_FEATURE_AREAS,
    },
    indent=2,
) + "\n"
README_FREEZE_STATEMENT = (
    f"Mac-Win is frozen at {SOURCE_COMMIT} for migration evidence. "
    "New SwiftUI, Bridge, and legacy launcher product features are not accepted."
)
README_DOCUMENT_LINK_STATEMENT = (
    "See [Migration baseline and evidence boundary](docs/migration-baseline.md)."
)
APPROVED_README_TEXT = f"""# Mac-Win

{README_FREEZE_STATEMENT}

{README_DOCUMENT_LINK_STATEMENT}
"""
MIGRATION_DOCUMENT_REQUIRED_STATEMENTS = (
    f"Mac-Win is frozen at `{SOURCE_COMMIT}` for migration evidence.",
    "New SwiftUI, Bridge, and legacy launcher product features are not accepted.",
    f"The immutable annotated baseline tag is `{TAG}`.",
    "Required runner and architecture: `macos-15` / `arm64`.",
    "Required runner and architecture: `macos-15-intel` / `x86_64`.",
    "Required host/test command: `swift --version`.",
    "Required host/test command: `sw_vers`.",
    "Required host/test command: `uname -m`.",
    "Required host/test command: `sysctl -n machdep.cpu.brand_string`.",
    "Required host/test command: `swift test --package-path MacWinManager`.",
    "Windows output is not macOS evidence.",
    "The authoritative macOS evidence is the GitHub Actions run URL plus the "
    "logs and job summary for both required runner and architecture jobs.",
    "Known failures must be recorded in MW-MIG-001 with the affected runner, "
    "observed architecture, command, exit status, and CI run URL; they must not "
    "be converted into passing expectations.",
    "Tag evidence must record both the annotated tag object ID and its peeled "
    "commit ID before MW-MIG-001 closes.",
    "Before tag publication, rollback is a normal revert of the migration-baseline "
    "change; a failed or unavailable target keeps MW-MIG-001 open and prevents "
    "tag publication.",
    f"After publication, `{TAG}` must not be moved or deleted; corrections use "
    "a new superseding annotated tag and an explicit issue record.",
    "MW-MIG-002 is the next owner after MW-MIG-001 completes.",
    "Asset migration and CompatForge publication are explicitly excluded from "
    "MW-MIG-001.",
)
APPROVED_MIGRATION_DOCUMENT_TEXT = f"""# Mac-Win migration baseline

## Baseline identity and freeze

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[0]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[1]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[2]}

## Authoritative macOS evidence

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[3]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[4]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[5]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[6]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[7]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[8]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[9]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[10]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[11]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[12]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[13]}

## Rollback and ownership

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[14]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[15]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[16]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[17]}
"""
APPROVED_WORKFLOW_TEXT = """name: Migration baseline

on:
  pull_request:
  push:
    branches:
      - main

permissions:
  contents: read

jobs:
  repository-contract:
    name: Repository contract
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - name: Check out repository
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
        with:
          persist-credentials: false
          fetch-depth: 0
      - name: Validate repository contract
        shell: bash
        run: |
          set -euo pipefail
          python -B -m unittest discover -s tests -p "test_*.py" -v
          python tools/validate_migration_baseline.py

  swift-evidence:
    name: Swift evidence (${{ matrix.runner }} / ${{ matrix.architecture }})
    strategy:
      fail-fast: false
      matrix:
        include:
          - runner: macos-15
            architecture: arm64
          - runner: macos-15-intel
            architecture: x86_64
    runs-on: ${{ matrix.runner }}
    timeout-minutes: 30
    steps:
      - name: Check out repository
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
        with:
          persist-credentials: false
          fetch-depth: 0
      - name: Record and verify host facts
        shell: bash
        env:
          EVIDENCE_RUNNER: ${{ matrix.runner }}
          EXPECTED_ARCHITECTURE: ${{ matrix.architecture }}
        run: |
          set -euo pipefail
          {
            echo "## Swift evidence: ${EVIDENCE_RUNNER} / ${EXPECTED_ARCHITECTURE}"
            echo
            echo "### swift --version"
          } | tee -a "$GITHUB_STEP_SUMMARY"
          swift --version | tee -a "$GITHUB_STEP_SUMMARY"
          echo "### sw_vers" | tee -a "$GITHUB_STEP_SUMMARY"
          sw_vers | tee -a "$GITHUB_STEP_SUMMARY"
          observed_architecture="$(uname -m)"
          {
            echo "### uname -m"
            echo "$observed_architecture"
          } | tee -a "$GITHUB_STEP_SUMMARY"
          cpu_brand="$(sysctl -n machdep.cpu.brand_string)"
          {
            echo "### sysctl -n machdep.cpu.brand_string"
            echo "$cpu_brand"
          } | tee -a "$GITHUB_STEP_SUMMARY"
          if [[ "$observed_architecture" != "$EXPECTED_ARCHITECTURE" ]]; then
            echo "Architecture mismatch: expected ${EXPECTED_ARCHITECTURE}, observed ${observed_architecture}." | tee -a "$GITHUB_STEP_SUMMARY"
            exit 1
          fi
      - name: Test Swift package
        shell: bash
        run: |
          set -uo pipefail
          {
            echo "### swift test --package-path MacWinManager"
            echo '```text'
          } >> "$GITHUB_STEP_SUMMARY"
          set +e
          swift test --package-path MacWinManager 2>&1 | tee -a "$GITHUB_STEP_SUMMARY"
          swift_status=${PIPESTATUS[0]}
          set -e
          {
            echo '```'
            echo
            echo "Swift test exit status: ${swift_status}"
          } | tee -a "$GITHUB_STEP_SUMMARY"
          exit "$swift_status"
"""
WORKFLOW_SHA256 = "82c8ff0e1023ee51ed3916c114ab6a4cdceb75ee1865e173e1303d438bc172a6"
TOP_LEVEL_FIELDS = (
    "schemaVersion",
    "repository",
    "sourceCommit",
    "tag",
    "swiftPackagePath",
    "evidenceTargets",
    "frozenFeatureAreas",
)
GIT_ENVIRONMENT_OVERRIDES = (
    "GIT_DIR",
    "GIT_WORK_TREE",
    "GIT_COMMON_DIR",
    "GIT_INDEX_FILE",
    "GIT_OBJECT_DIRECTORY",
    "GIT_ALTERNATE_OBJECT_DIRECTORIES",
    "GIT_NAMESPACE",
)
GIT_SAFETY_ENVIRONMENT = {
    "GIT_NO_LAZY_FETCH": "1",
    "GIT_TERMINAL_PROMPT": "0",
    "GIT_NO_REPLACE_OBJECTS": "1",
}


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


def _git_environment():
    """Return a local-only Git environment independent of caller overrides."""
    environment = os.environ.copy()
    for variable in GIT_ENVIRONMENT_OVERRIDES:
        environment.pop(variable, None)
    environment.update(GIT_SAFETY_ENVIRONMENT)
    return environment


def _run_git(repository_root, arguments, check=False):
    """Run Git without a shell at one resolved repository root."""
    try:
        result = subprocess.run(
            ["git", *arguments],
            cwd=Path(repository_root).resolve(),
            env=_git_environment(),
            shell=False,
            capture_output=True,
            text=False,
            check=False,
        )
    except OSError as error:
        raise BaselineValidationError("Git command could not be started") from error

    if check and result.returncode != 0:
        raise BaselineValidationError("Git command failed")
    return result


def validate_source_commit(repository_root, source_commit):
    """Require a local commit object that is an ancestor of the current HEAD."""
    object_type = _run_git(
        repository_root,
        ["cat-file", "-t", source_commit],
    )
    if object_type.returncode != 0 or object_type.stdout.strip() != b"commit":
        raise BaselineValidationError("source commit is not a local commit object")

    ancestor = _run_git(
        repository_root,
        ["merge-base", "--is-ancestor", source_commit, "HEAD"],
    )
    if ancestor.returncode != 0:
        raise BaselineValidationError("source commit is not an ancestor of HEAD")


def _normalize_lf(text):
    """Normalize reviewed CRLF input while preserving every other character."""
    return text.replace("\r\n", "\n")


def _strip_hidden_markdown(text):
    """Remove HTML comments and fenced code before visible-statement checks."""
    without_comments = re.sub(r"<!--.*?(?:-->|$)", "", text, flags=re.DOTALL)
    visible_lines = []
    fence_character = None
    fence_length = 0

    for line in without_comments.split("\n"):
        candidate = line.lstrip(" ")
        indentation = len(line) - len(candidate)
        leading = len(candidate) - len(candidate.lstrip("`~"))
        marker = candidate[:leading]

        if fence_character is None:
            if (
                indentation <= 3
                and len(marker) >= 3
                and len(set(marker)) == 1
            ):
                fence_character = marker[0]
                fence_length = len(marker)
                continue
            visible_lines.append(line)
            continue

        closing = candidate.rstrip(" \t")
        if (
            indentation <= 3
            and closing
            and set(closing) == {fence_character}
            and len(closing) >= fence_length
        ):
            fence_character = None
            fence_length = 0

    return "\n".join(visible_lines)


def _normalize_ascii_whitespace(text):
    """Collapse only ASCII whitespace for wrapped standalone statements."""
    return re.sub(r"[ \t\r\n\f\v]+", " ", text).strip(" ")


def _visible_standalone_statements(text):
    """Return complete visible Markdown blocks, never substring matches."""
    visible = _strip_hidden_markdown(_normalize_lf(text))
    blocks = re.split(r"\n[ \t\f\v]*\n", visible)
    return {
        normalized
        for block in blocks
        if (normalized := _normalize_ascii_whitespace(block))
    }


def validate_readme_document(text):
    """Require a visible, standalone freeze notice and migration-doc link."""
    statements = _visible_standalone_statements(text)
    if README_FREEZE_STATEMENT not in statements:
        raise BaselineValidationError(
            "README is missing the standalone migration freeze statement"
        )
    if README_DOCUMENT_LINK_STATEMENT not in statements:
        raise BaselineValidationError(
            "README is missing the standalone migration document link"
        )


def validate_migration_document(text):
    """Require every approved evidence boundary as a standalone statement."""
    statements = _visible_standalone_statements(text)
    if any(
        statement not in statements
        for statement in MIGRATION_DOCUMENT_REQUIRED_STATEMENTS
    ):
        raise BaselineValidationError(
            "migration document is missing a required standalone evidence statement"
        )


def _workflow_semantic_lines(text):
    """Return active, non-comment YAML lines without interpreting comment decoys."""
    normalized = _normalize_lf(text)
    active_lines = []
    for line in normalized.split("\n"):
        if not line.strip():
            continue
        if line.lstrip(" ").startswith("#"):
            continue
        active_lines.append(line)
    return tuple(active_lines)


def _validate_workflow_semantics(text):
    """Require the complete approved active YAML structure."""
    if type(text) is not str or _workflow_semantic_lines(
        text
    ) != _workflow_semantic_lines(APPROVED_WORKFLOW_TEXT):
        raise BaselineValidationError(
            "migration workflow structure is not approved"
        )


def validate_workflow_document(text):
    """Check the LF-normalized whole-file seal before YAML semantic checks."""
    if type(text) is not str:
        raise BaselineValidationError(
            "migration workflow does not match the approved SHA-256 seal"
        )
    normalized = _normalize_lf(text)
    try:
        digest = hashlib.sha256(normalized.encode("utf-8", errors="strict")).hexdigest()
    except UnicodeEncodeError as error:
        raise BaselineValidationError(
            "migration workflow does not match the approved SHA-256 seal"
        ) from error
    if digest != WORKFLOW_SHA256:
        raise BaselineValidationError(
            "migration workflow does not match the approved SHA-256 seal"
        )
    _validate_workflow_semantics(normalized)


def _reviewed_relative_path(relative_path):
    """Return a closed repository-relative POSIX path."""
    if type(relative_path) is not str or not relative_path or "\0" in relative_path:
        raise BaselineValidationError("reviewed file path is not repository-relative")
    if "\\" in relative_path:
        raise BaselineValidationError("reviewed file path is not repository-relative")

    path = PurePosixPath(relative_path)
    windows_path = PureWindowsPath(relative_path)
    if (
        path.is_absolute()
        or windows_path.is_absolute()
        or bool(windows_path.drive)
        or bool(windows_path.root)
        or ":" in relative_path
        or not path.parts
        or any(part in ("", ".", "..") for part in path.parts)
        or str(path) != relative_path
    ):
        raise BaselineValidationError("reviewed file path is not repository-relative")
    return path


def _is_reparse(status):
    reparse_attribute = getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
    return bool(getattr(status, "st_file_attributes", 0) & reparse_attribute)


def _component_identity(status):
    """Return stable identity fields used to detect path-component replacement."""
    return (
        getattr(status, "st_dev", None),
        getattr(status, "st_ino", None),
        stat.S_IFMT(status.st_mode),
        _is_reparse(status),
    )


def _leaf_identity(status):
    """Include file content metadata when comparing the opened reviewed leaf."""
    return (
        *_component_identity(status),
        getattr(status, "st_size", None),
        getattr(status, "st_mtime_ns", None),
    )


def _inspect_reviewed_path(repository_root, relative_path):
    """lstat every path component without resolving symlinks or reparse points."""
    repository = Path(os.path.abspath(os.fspath(repository_root)))
    components = [repository]
    current = repository
    for part in relative_path.parts:
        current = current / part
        components.append(current)

    statuses = []
    last_index = len(components) - 1
    for index, component in enumerate(components):
        try:
            status = component.lstat()
        except FileNotFoundError as error:
            if index == last_index:
                diagnostic = "reviewed working-tree input is missing"
            else:
                diagnostic = "reviewed parent path component is missing"
            raise BaselineValidationError(diagnostic) from error
        except OSError as error:
            raise BaselineValidationError(
                "reviewed path component could not be inspected"
            ) from error

        is_link = stat.S_ISLNK(status.st_mode) or _is_reparse(status)
        if is_link:
            if index == last_index:
                diagnostic = (
                    "reviewed working-tree input must be a regular non-reparse file"
                )
            else:
                diagnostic = (
                    "reviewed path components must not be symlinks or reparse points"
                )
            raise BaselineValidationError(diagnostic)
        if index < last_index and not stat.S_ISDIR(status.st_mode):
            raise BaselineValidationError(
                "reviewed parent path components must be directories"
            )
        if index == last_index and not stat.S_ISREG(status.st_mode):
            raise BaselineValidationError(
                "reviewed working-tree input must be a regular non-reparse file"
            )
        statuses.append(status)
    return components[-1], statuses


def _read_worktree_text(repository_root, relative_path, maximum_bytes):
    """Read one regular non-reparse working-tree file with a byte bound."""
    reviewed_path, initial_statuses = _inspect_reviewed_path(
        repository_root, relative_path
    )
    flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(reviewed_path, flags)
    except FileNotFoundError as error:
        raise BaselineValidationError(
            "reviewed working-tree input is missing"
        ) from error
    except OSError as error:
        raise BaselineValidationError(
            "reviewed working-tree input could not be opened without following links"
        ) from error

    try:
        with os.fdopen(descriptor, "rb") as stream:
            descriptor = None
            opened_status = os.fstat(stream.fileno())
            if (
                not stat.S_ISREG(opened_status.st_mode)
                or _is_reparse(opened_status)
                or _component_identity(opened_status)
                != _component_identity(initial_statuses[-1])
            ):
                raise BaselineValidationError(
                    "reviewed working-tree input changed before bounded read"
                )
            raw = stream.read(maximum_bytes + 1)
            opened_after_read = os.fstat(stream.fileno())
    except BaselineValidationError:
        raise
    except OSError as error:
        raise BaselineValidationError(
            "reviewed working-tree input could not be read"
        ) from error
    finally:
        if descriptor is not None:
            os.close(descriptor)

    _, final_statuses = _inspect_reviewed_path(repository_root, relative_path)
    if (
        len(initial_statuses) != len(final_statuses)
        or any(
            _component_identity(before) != _component_identity(after)
            for before, after in zip(initial_statuses, final_statuses)
        )
        or _leaf_identity(initial_statuses[-1]) != _leaf_identity(opened_after_read)
        or _leaf_identity(initial_statuses[-1]) != _leaf_identity(final_statuses[-1])
    ):
        raise BaselineValidationError(
            "reviewed working-tree path changed during bounded read"
        )

    if len(raw) > maximum_bytes:
        raise BaselineValidationError(
            f"reviewed working-tree input exceeds {maximum_bytes}-byte limit"
        )
    try:
        return _normalize_lf(raw.decode("utf-8", errors="strict"))
    except UnicodeDecodeError as error:
        raise BaselineValidationError(
            "reviewed working-tree input is not valid UTF-8"
        ) from error


def _index_entry(repository_root, relative_path):
    """Return the mode and non-zero object id of one stage-0 index entry."""
    relative_text = str(relative_path)
    listed = _run_git(
        repository_root,
        ["ls-files", "--stage", "-z", "--", relative_text],
    )
    if listed.returncode != 0:
        raise BaselineValidationError("reviewed file index could not be read")

    raw = listed.stdout
    if not raw or not raw.endswith(b"\0"):
        raise BaselineValidationError(
            "reviewed file must have one stage-0 index entry"
        )
    records = raw[:-1].split(b"\0")
    if len(records) != 1:
        raise BaselineValidationError(
            "reviewed file must have one stage-0 index entry"
        )

    try:
        metadata, indexed_path = records[0].split(b"\t", 1)
        mode, object_id, stage = metadata.split(b" ")
    except ValueError as error:
        raise BaselineValidationError(
            "reviewed file must have one stage-0 index entry"
        ) from error
    if stage != b"0" or indexed_path != relative_text.encode("utf-8"):
        raise BaselineValidationError(
            "reviewed file must have one stage-0 index entry"
        )
    if mode != b"100644":
        raise BaselineValidationError("reviewed file index mode must be 100644")
    if (
        re.fullmatch(rb"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})", object_id)
        is None
        or set(object_id) == {ord("0")}
    ):
        raise BaselineValidationError("reviewed file index object id is invalid")

    debug = _run_git(
        repository_root,
        ["ls-files", "--debug", "-z", "--", relative_text],
    )
    expected_prefix = relative_text.encode("utf-8") + b"\0"
    flags = re.findall(rb"(?:^|[\t ])flags: ([0-9a-fA-F]+)(?:\r?\n|$)", debug.stdout)
    if (
        debug.returncode != 0
        or not debug.stdout.startswith(expected_prefix)
        or len(flags) != 1
    ):
        raise BaselineValidationError("reviewed file index metadata is invalid")
    if int(flags[0], 16) & 0x20000000:
        raise BaselineValidationError(
            "reviewed file index entry must not be intent-to-add"
        )
    return object_id.decode("ascii").lower()


def _read_index_blob_text(repository_root, object_id, maximum_bytes):
    """Read one verified local Git blob only after checking its bounded size."""
    object_type = _run_git(repository_root, ["cat-file", "-t", object_id])
    if object_type.returncode != 0 or object_type.stdout.strip() != b"blob":
        raise BaselineValidationError(
            "reviewed file index object is not a local blob"
        )

    object_size = _run_git(repository_root, ["cat-file", "-s", object_id])
    encoded_size = object_size.stdout.strip()
    if (
        object_size.returncode != 0
        or len(encoded_size) > 20
        or re.fullmatch(rb"[0-9]+", encoded_size) is None
    ):
        raise BaselineValidationError(
            "reviewed file index blob size is invalid"
        )
    size = int(encoded_size)
    if size > maximum_bytes:
        raise BaselineValidationError(
            f"reviewed file index blob exceeds {maximum_bytes}-byte limit"
        )

    blob = _run_git(repository_root, ["cat-file", "blob", object_id])
    if blob.returncode != 0:
        raise BaselineValidationError("reviewed file index blob could not be read")
    if len(blob.stdout) != size:
        raise BaselineValidationError(
            "reviewed file index blob length does not match Git metadata"
        )
    try:
        return _normalize_lf(blob.stdout.decode("utf-8", errors="strict"))
    except UnicodeDecodeError as error:
        raise BaselineValidationError(
            "reviewed file index blob is not valid UTF-8"
        ) from error


def read_reviewed_text(
    repository_root,
    relative_path,
    expected_text,
    maximum_bytes,
):
    """Bind approved text independently to the worktree and stage-0 Git blob."""
    path = _reviewed_relative_path(relative_path)
    if type(expected_text) is not str:
        raise BaselineValidationError("reviewed approved content must be text")
    if type(maximum_bytes) is not int or maximum_bytes < 0:
        raise BaselineValidationError("reviewed byte limit is invalid")

    approved_text = _normalize_lf(expected_text)
    worktree_text = _read_worktree_text(repository_root, path, maximum_bytes)
    if worktree_text != approved_text:
        raise BaselineValidationError(
            "reviewed working-tree content does not match approved content"
        )

    object_id = _index_entry(repository_root, path)
    index_text = _read_index_blob_text(repository_root, object_id, maximum_bytes)
    if index_text != approved_text:
        raise BaselineValidationError(
            "reviewed index content does not match approved content"
        )
    if index_text != worktree_text:
        raise BaselineValidationError("reviewed index and working tree have drifted")
    return worktree_text


def main():
    try:
        reviewed_manifest = read_reviewed_text(
            ROOT,
            MANIFEST_RELATIVE_PATH,
            APPROVED_MANIFEST_TEXT,
            MAX_MANIFEST_BYTES,
        )
        manifest = parse_manifest_bytes(reviewed_manifest.encode("utf-8"))
        validate_manifest(manifest)
        validate_source_commit(ROOT, SOURCE_COMMIT)
        reviewed_readme = read_reviewed_text(
            ROOT,
            README_RELATIVE_PATH,
            APPROVED_README_TEXT,
            MAX_README_BYTES,
        )
        validate_readme_document(reviewed_readme)
        reviewed_migration_document = read_reviewed_text(
            ROOT,
            MIGRATION_DOCUMENT_RELATIVE_PATH,
            APPROVED_MIGRATION_DOCUMENT_TEXT,
            MAX_MIGRATION_DOCUMENT_BYTES,
        )
        validate_migration_document(reviewed_migration_document)
        reviewed_workflow = read_reviewed_text(
            ROOT,
            WORKFLOW_RELATIVE_PATH,
            APPROVED_WORKFLOW_TEXT,
            MAX_WORKFLOW_BYTES,
        )
        validate_workflow_document(reviewed_workflow)
    except (BaselineValidationError, OSError) as error:
        print(f"migration baseline validation failed: {error}", file=sys.stderr)
        return 1

    print("Mac-Win migration baseline manifest is valid.")
    return 0


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main())

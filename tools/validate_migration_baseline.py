#!/usr/bin/env python3
"""Validate the closed Mac-Win migration baseline manifest contract."""

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath, PureWindowsPath
import re
import stat
import subprocess
import sys
import unicodedata


MAX_MANIFEST_BYTES = 65_536
MAX_README_BYTES = 4_096
MAX_MIGRATION_DOCUMENT_BYTES = 32_768
MAX_WORKFLOW_BYTES = 16_384
MAX_TAG_OBJECT_BYTES = 16_384
MAX_JSON_INTEGER_DIGITS = 128
MAX_JSON_NESTING_DEPTH = 128
ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "migration" / "baseline.json"
MANIFEST_RELATIVE_PATH = "migration/baseline.json"
README_RELATIVE_PATH = "README.md"
MIGRATION_DOCUMENT_RELATIVE_PATH = "docs/migration-baseline.md"
WORKFLOW_RELATIVE_PATH = ".github/workflows/migration-baseline.yml"

SCHEMA_VERSION = 1
REPOSITORY = "a1112/Mac-Win"
SOURCE_COMMIT = "db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527"
TAG = "mw-migration-baseline-db12d5e"
TAG_MESSAGE = "Mac-Win migration source baseline db12d5e"
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
    "Before tag creation, run `python tools/validate_migration_baseline.py`; "
    "this pre-tag check intentionally does not require the tag and is not tag "
    "evidence.",
    "After the merge commit passes all three required jobs—the `repository-contract` "
    "job, Apple Silicon `macos-15` / `arm64`, and Intel `macos-15-intel` / "
    f"`x86_64`—create the annotated tag directly at the frozen source with `git "
    f"tag --no-sign -a {TAG} {SOURCE_COMMIT} -m \"{TAG_MESSAGE}\"`.",
    "If any of the three required jobs fails, is cancelled, or is unavailable, "
    "do not create or publish the baseline tag.",
    "Before publication, run `python tools/validate_migration_baseline.py "
    "--require-tag`; this post-tag check requires a local annotated tag that "
    f"directly references and peels to `{SOURCE_COMMIT}`.",
    f"Publish only the verified tag with `git push origin refs/tags/{TAG}` and "
    "record the tag object ID plus peeled commit ID as the authoritative tag "
    "evidence.",
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

## Tag verification procedure

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[14]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[15]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[16]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[17]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[18]}

## Rollback and ownership

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[19]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[20]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[21]}

{MIGRATION_DOCUMENT_REQUIRED_STATEMENTS[22]}
"""
APPROVED_WORKFLOW_TEXT = """name: Migration baseline

on:
  pull_request:
    branches:
      - main
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
    env:
      DEVELOPER_DIR: /Applications/Xcode_16.2.app/Contents/Developer
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
          summary_path="$GITHUB_STEP_SUMMARY"
          export -n summary_path
          unset GITHUB_STEP_SUMMARY
          swift_output_file="$(mktemp "${RUNNER_TEMP}/mac-win-swift-test.XXXXXX")"
          swift_summary_copy_file=""
          trap 'rm -f "$swift_output_file"; if [[ -n "$swift_summary_copy_file" ]]; then rm -f "$swift_summary_copy_file"; fi' EXIT
          swift_summary_copy_file="$(mktemp "${RUNNER_TEMP}/mac-win-swift-summary.XXXXXX")"
          {
            echo "### swift test --package-path MacWinManager"
            echo
          } >> "$summary_path"
          set +e
          swift test --package-path MacWinManager 2>&1 | tee "$swift_output_file"
          swift_pipeline_status=("${PIPESTATUS[@]}")
          swift_status=${swift_pipeline_status[0]}
          swift_tee_status=${swift_pipeline_status[1]}
          set -e
          swift_output_bytes="$(wc -c < "$swift_output_file" | tr -d '[:space:]')"
          swift_summary_raw_limit_bytes=262144
          swift_summary_copy_limit_bytes=524288
          swift_summary_copy_bytes=0
          swift_summary_copy_status="omitted; raw output limit exceeded; not truncated"
          swift_summary_limit_exceeded=0
          swift_capture_failed=0
          swift_format_failed=0
          swift_base64_status=-1
          swift_indent_status=-1
          if (( swift_tee_status != 0 )); then
            swift_summary_copy_status="omitted; complete log capture failed; not truncated"
            swift_capture_failed=1
          fi
          if (( swift_capture_failed != 0 )); then
            :
          elif (( swift_output_bytes > swift_summary_raw_limit_bytes )); then
            swift_summary_limit_exceeded=1
          else
            set +e
            base64 < "$swift_output_file" | sed 's/^/    /' > "$swift_summary_copy_file"
            swift_format_pipeline_status=("${PIPESTATUS[@]}")
            set -e
            swift_base64_status=${swift_format_pipeline_status[0]}
            swift_indent_status=${swift_format_pipeline_status[1]}
            if (( swift_base64_status != 0 || swift_indent_status != 0 )); then
              swift_summary_copy_status="omitted; Markdown-safe formatting failed; not truncated"
              swift_format_failed=1
            else
              swift_summary_copy_bytes="$(wc -c < "$swift_summary_copy_file" | tr -d '[:space:]')"
            fi
            if (( swift_format_failed == 0 && swift_summary_copy_bytes > swift_summary_copy_limit_bytes )); then
              swift_summary_copy_status="omitted; Markdown-safe copy limit exceeded; not truncated"
              swift_summary_limit_exceeded=1
            elif (( swift_format_failed == 0 )); then
              swift_summary_copy_status="complete; Markdown-safe base64 indented code; not truncated"
            fi
          fi
          {
            echo "- Swift test exit status: ${swift_status}"
            echo "- Swift test log capture exit status: ${swift_tee_status}"
            echo "- Swift test base64 formatter exit status: ${swift_base64_status}"
            echo "- Swift test indent formatter exit status: ${swift_indent_status}"
            echo "- Swift test raw output bytes: ${swift_output_bytes}"
            echo "- Swift test raw output limit bytes: ${swift_summary_raw_limit_bytes}"
            echo "- Swift test Markdown-safe copy bytes: ${swift_summary_copy_bytes}"
            echo "- Swift test Markdown-safe copy limit bytes: ${swift_summary_copy_limit_bytes}"
            echo "- Swift test summary copy status: ${swift_summary_copy_status}"
            echo
          } >> "$summary_path"
          if (( swift_summary_limit_exceeded != 0 )); then
            exit 1
          fi
          if (( swift_capture_failed != 0 )); then
            exit 1
          fi
          if (( swift_format_failed != 0 )); then
            exit 1
          fi
          cat "$swift_summary_copy_file" >> "$summary_path"
          echo >> "$summary_path"
          exit "$swift_status"
"""
WORKFLOW_SHA256 = "41d65d01b6c0c308c81253de6b80877d98d4d5748604ac4269e0219e8e449947"
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


def _reject_excessive_json_nesting(text):
    """Reject structural nesting beyond the reviewed bound before decoding."""
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
            if depth > MAX_JSON_NESTING_DEPTH:
                raise BaselineValidationError("manifest is not valid JSON")
        elif character in "]}" and depth > 0:
            depth -= 1


def parse_manifest_bytes(raw):
    """Parse bounded strict-UTF-8 JSON while rejecting decoded duplicate keys."""
    if len(raw) > MAX_MANIFEST_BYTES:
        raise BaselineValidationError("manifest exceeds 65536-byte limit")

    try:
        text = raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise BaselineValidationError("manifest is not valid UTF-8") from error

    _reject_excessive_json_nesting(text)

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


def _validate_tag_tagger_line(raw_line):
    """Validate one conservative, single-line Git tagger identity."""
    diagnostic = "baseline tag object has an invalid tagger identity"
    try:
        line = raw_line.decode("utf-8", errors="strict")
    except (AttributeError, UnicodeDecodeError) as error:
        raise BaselineValidationError(diagnostic) from error

    if any(unicodedata.category(character) == "Cc" for character in line):
        raise BaselineValidationError(diagnostic)
    matched = re.fullmatch(
        r"tagger (?P<name>[^<>]+) <(?P<email>[^<>]+)> "
        r"(?P<timestamp>0|[1-9][0-9]{0,18}) (?P<timezone>[+-][0-9]{4})",
        line,
    )
    if matched is None:
        raise BaselineValidationError(diagnostic)

    name = matched.group("name")
    email = matched.group("email")
    timestamp_text = matched.group("timestamp")
    timezone = matched.group("timezone")
    if (
        not name.strip()
        or name != name.strip()
        or not email
        or not email.isascii()
        or any(character.isspace() for character in email)
        or any(ord(character) < 0x21 or ord(character) > 0x7E for character in email)
        or int(timestamp_text) > 9_223_372_036_854_775_807
    ):
        raise BaselineValidationError(diagnostic)

    timezone_hour = int(timezone[1:3])
    timezone_minute = int(timezone[3:5])
    if (
        timezone_minute >= 60
        or timezone_hour > 14
        or (timezone_hour == 14 and timezone_minute != 0)
    ):
        raise BaselineValidationError(diagnostic)


def validate_baseline_tag(repository_root, tag_name, source_commit, run_git=None):
    """Require one local annotated tag directly bound to the source commit."""
    tag_ref = f"refs/tags/{tag_name}"
    git = _run_git if run_git is None else run_git

    listed_refs = git(
        repository_root,
        ["for-each-ref", "--format=%(refname)", "refs/tags"],
    )
    if listed_refs.returncode != 0:
        raise BaselineValidationError("baseline tag refs could not be enumerated")
    try:
        tag_refs = listed_refs.stdout.decode("utf-8", errors="strict").splitlines()
    except UnicodeDecodeError as error:
        raise BaselineValidationError(
            "baseline tag refs could not be enumerated"
        ) from error
    casefold_matches = [
        ref_name for ref_name in tag_refs if ref_name.casefold() == tag_ref.casefold()
    ]
    if tag_ref not in tag_refs:
        if casefold_matches:
            raise BaselineValidationError(
                "baseline tag ref is not stored with exact canonical spelling"
            )
        raise BaselineValidationError(
            "baseline tag is not a local annotated tag object"
        )
    if casefold_matches != [tag_ref]:
        raise BaselineValidationError(
            "baseline tag ref is not stored with exact canonical spelling"
        )

    symbolic_ref = git(repository_root, ["symbolic-ref", "-q", tag_ref])
    if symbolic_ref.returncode == 0:
        raise BaselineValidationError("baseline tag ref must not be symbolic")
    if symbolic_ref.returncode != 1:
        raise BaselineValidationError("baseline tag ref could not be inspected")

    object_type = git(repository_root, ["cat-file", "-t", tag_ref])
    if object_type.returncode != 0 or object_type.stdout.strip() != b"tag":
        raise BaselineValidationError(
            "baseline tag is not a local annotated tag object"
        )

    peeled = git(repository_root, ["rev-parse", f"{tag_ref}^{{}}"])
    if (
        peeled.returncode != 0
        or peeled.stdout.strip() != source_commit.encode("ascii")
    ):
        raise BaselineValidationError(
            "baseline tag does not peel to the source commit"
        )

    resolved_tag = git(repository_root, ["rev-parse", "--verify", tag_ref])
    encoded_object_id = resolved_tag.stdout.strip()
    if (
        resolved_tag.returncode != 0
        or re.fullmatch(rb"(?:[0-9a-f]{40}|[0-9a-f]{64})", encoded_object_id)
        is None
    ):
        raise BaselineValidationError("baseline tag object id is invalid")
    object_id = encoded_object_id.decode("ascii")

    object_size = git(repository_root, ["cat-file", "-s", object_id])
    encoded_size = object_size.stdout.strip()
    if (
        object_size.returncode != 0
        or len(encoded_size) > 20
        or re.fullmatch(rb"[0-9]+", encoded_size) is None
    ):
        raise BaselineValidationError("baseline tag object size is invalid")
    size = int(encoded_size)
    if size > MAX_TAG_OBJECT_BYTES:
        raise BaselineValidationError(
            f"baseline tag object exceeds {MAX_TAG_OBJECT_BYTES}-byte limit"
        )

    tag_object = git(repository_root, ["cat-file", "tag", object_id])
    if tag_object.returncode != 0:
        raise BaselineValidationError("baseline tag object could not be read")
    if len(tag_object.stdout) != size:
        raise BaselineValidationError(
            "baseline tag object length does not match Git metadata"
        )

    raw_headers, separator, raw_message = tag_object.stdout.partition(b"\n\n")
    header_lines = raw_headers.split(b"\n")
    expected_direct_headers = (
        f"object {source_commit}".encode("ascii"),
        b"type commit",
    )
    expected_message = TAG_MESSAGE.encode("utf-8") + b"\n"
    if (
        separator != b"\n\n"
        or len(header_lines) != 4
        or tuple(header_lines[:2]) != expected_direct_headers
    ):
        raise BaselineValidationError(
            "baseline tag does not directly reference the source commit"
        )
    if (
        header_lines[2] != f"tag {tag_name}".encode("utf-8")
        or raw_message != expected_message
    ):
        raise BaselineValidationError(
            "baseline tag object content does not match the approved source baseline"
        )
    _validate_tag_tagger_line(header_lines[3])


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


class _StableArgumentParser(argparse.ArgumentParser):
    """Preserve argparse usage semantics without reflecting hostile argv."""

    def error(self, _message):
        self.print_usage(sys.stderr)
        self.exit(2, f"{self.prog}: error: invalid command-line arguments\n")


def _argument_parser():
    parser = _StableArgumentParser(
        prog="validate_migration_baseline.py",
        allow_abbrev=False,
        description="Validate the closed Mac-Win migration baseline."
    )
    parser.add_argument(
        "--require-tag",
        action="store_true",
        help="also require the immutable annotated source-baseline tag",
    )
    return parser


def main(arguments=()):
    options = _argument_parser().parse_args(arguments)
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
        if options.require_tag:
            validate_baseline_tag(ROOT, TAG, SOURCE_COMMIT)
    except (BaselineValidationError, OSError) as error:
        print(f"migration baseline validation failed: {error}", file=sys.stderr)
        return 1

    print("Mac-Win migration baseline is valid.")
    return 0


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main(sys.argv[1:]))

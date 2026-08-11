# Mac-Win Migration Baseline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Freeze Mac-Win commit `4e421fbea6f59e73e4f813c1f0a14e8db9e36de7`, prove the Swift package on Intel and Apple Silicon macOS runners, and publish an immutable annotated source-baseline tag.

**Architecture:** A closed JSON manifest and dependency-free Python validator bind the source commit, tag, frozen feature areas, reviewed documents, and exact CI workflow. A GitHub Actions workflow runs repository-contract checks plus the same Swift package suite on `macos-15` and `macos-15-intel`; the tag is created only after the merge commit's three jobs pass.

**Tech Stack:** Python 3 standard library, `unittest`, Git, JSON, GitHub Actions YAML, Bash, Swift Package Manager 6.0, macOS 15 GitHub-hosted runners.

---

### Task 1: Establish the closed baseline manifest contract

**Files:**

- Create: `migration/baseline.json`
- Create: `tools/validate_migration_baseline.py`
- Create: `tests/test_validate_migration_baseline.py`

**Step 1: Write the failing manifest tests**

Load `tools/validate_migration_baseline.py` with `importlib.util` and define the
canonical object:

```python
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
```

Add tests that require the canonical object and reject:

- unknown and missing top-level fields;
- bool/float/string substitutions for `schemaVersion`;
- short, uppercase, non-hex, and wrong source commits;
- unsafe or wrong package paths;
- missing, duplicate, reordered, or unexpected evidence targets;
- missing, duplicate, reordered, or unexpected frozen feature areas;
- duplicate raw JSON keys, including Unicode-escaped key collisions;
- an input of 65,537 bytes when the manifest limit is 65,536 bytes.

Use in-memory mutations so every negative test identifies one boundary.

**Step 2: Run the focused test and verify RED**

Run:

```powershell
python -B -m unittest discover -s tests -p "test_validate_migration_baseline.py" -v
```

Expected: import or assertion failures because the validator and manifest do
not exist.

**Step 3: Implement the minimal manifest parser and validator**

In `tools/validate_migration_baseline.py`:

- define the exact constants from the design;
- use `object_pairs_hook` to reject duplicate JSON keys after escape decoding;
- read at most `MAX_MANIFEST_BYTES + 1` bytes before decoding;
- use strict UTF-8;
- require exact `type(value) is int` for the schema version;
- compare the nested collections to the exact reviewed values;
- raise `BaselineValidationError` with stable, specific diagnostics;
- keep parsing and validation pure so tests do not need a Git repository.

Write `migration/baseline.json` with exactly the canonical object and a final
newline.

**Step 4: Run focused tests and verify GREEN**

Run the focused command again.

Expected: all manifest tests pass.

**Step 5: Commit**

```powershell
git add migration/baseline.json tools/validate_migration_baseline.py tests/test_validate_migration_baseline.py
git commit -s -m "test: define Mac-Win migration baseline contract"
```

### Task 2: Bind the manifest to local Git objects and reviewed files

**Files:**

- Modify: `tools/validate_migration_baseline.py`
- Modify: `tests/test_validate_migration_baseline.py`

**Step 1: Write failing Git-boundary tests**

Create temporary Git repositories and require:

- the source commit exists locally as a commit object;
- the source commit is an ancestor of `HEAD`;
- missing objects fail without a network request;
- replace refs cannot substitute reviewed objects;
- reviewed paths are unique stage-0 `100644` index entries;
- symlinks/reparse points, executable modes, submodules, intent-to-add,
  conflict stages, missing blobs, non-blob objects, oversized blobs, invalid
  UTF-8, and index/worktree drift fail closed;
- ordinary files and CRLF working-tree equivalents pass.

Patch or record each Git subprocess environment and assert:

```text
GIT_NO_LAZY_FETCH=1
GIT_TERMINAL_PROMPT=0
GIT_NO_REPLACE_OBJECTS=1
```

Inject each of these variables with a valid alternate repository, index,
object store, or namespace and prove it cannot redirect validation:

```text
GIT_DIR
GIT_WORK_TREE
GIT_COMMON_DIR
GIT_INDEX_FILE
GIT_OBJECT_DIRECTORY
GIT_ALTERNATE_OBJECT_DIRECTORIES
GIT_NAMESPACE
```

**Step 2: Run the focused test and verify RED**

Expected: the new Git-boundary tests fail because the helpers are absent.

**Step 3: Implement bounded, local-only Git reads**

Add `_run_git`, `read_reviewed_text`, and source-commit validation:

- always pass argument arrays with `shell=False`;
- derive and fix the repository root from the validator file location;
- copy the caller environment, remove all seven repository/index/object/ref
  override variables listed above, and force the three Git safety flags;
- use `git cat-file -t` before `-s` and blob reads;
- enforce size before reading a blob;
- verify the index blob and worktree text independently after LF
  normalization;
- use `lstat` and reject symlink/reparse/non-regular working-tree inputs;
- use `git merge-base --is-ancestor` for the source commit.

**Step 4: Run focused tests and verify GREEN**

Expected: all manifest and Git-boundary tests pass.

**Step 5: Commit**

```powershell
git add tools/validate_migration_baseline.py tests/test_validate_migration_baseline.py
git commit -s -m "fix: bind migration baseline to local Git objects"
```

### Task 3: Publish the visible freeze and evidence boundary

**Files:**

- Create: `README.md`
- Create: `docs/migration-baseline.md`
- Modify: `tools/validate_migration_baseline.py`
- Modify: `tests/test_validate_migration_baseline.py`

**Step 1: Write failing document tests**

Require the README to contain a standalone, visible statement equivalent to:

```text
Mac-Win is frozen at 4e421fbea6f59e73e4f813c1f0a14e8db9e36de7 for migration evidence. New SwiftUI, Bridge, and legacy launcher product features are not accepted.
```

Require `docs/migration-baseline.md` to record:

- the full source commit and tag;
- the two exact runner/architecture pairs;
- the five host/test commands;
- the rule that Windows output is not macOS evidence;
- known failures, CI-run evidence, tag evidence, rollback, and superseding-tag
  handling;
- MW-MIG-002 as the next owner;
- the explicit exclusion of asset migration and CompatForge publication.

Add negative mutations for missing SHA, weakened freeze language, omitted
architecture, omitted known-failure handling, and HTML-comment/negation
wrappers.

**Step 2: Run focused tests and verify RED**

Expected: failures because README, migration documentation, and semantic
checks are absent.

**Step 3: Write the documents and semantic checks**

Keep the README concise and link to `docs/migration-baseline.md`. Normalize
ASCII whitespace only where required and validate complete standalone
statements rather than independent keywords. Run document validation only
after `read_reviewed_text` has bound the index and working-tree bytes.

**Step 4: Run focused tests and verify GREEN**

Expected: canonical documents pass and every weakened mutation fails.

**Step 5: Commit**

```powershell
git add README.md docs/migration-baseline.md tools/validate_migration_baseline.py tests/test_validate_migration_baseline.py
git commit -s -m "docs: freeze Mac-Win product development"
```

### Task 4: Add the sealed dual-architecture workflow

**Files:**

- Create: `.github/workflows/migration-baseline.yml`
- Modify: `tools/validate_migration_baseline.py`
- Modify: `tests/test_validate_migration_baseline.py`

**Step 1: Write failing workflow tests**

Require the exact reviewed workflow to have:

- top-level `permissions: contents: read` and no write permission;
- `pull_request` and `push` on `main`;
- a repository-contract job on `ubuntu-24.04`;
- two explicit Swift matrix entries, `macos-15`/`arm64` and
  `macos-15-intel`/`x86_64`;
- pinned `actions/checkout` SHA, `persist-credentials: false`, and
  `fetch-depth: 0` on every checkout that runs the validator;
- bounded timeouts and `fail-fast: false`;
- the exact five environment/test commands;
- an architecture equality check;
- no `continue-on-error`, artifact upload, release, package, write token,
  download, Bottle mutation, or product-launch step.

Start with mutation tests for a missing Intel row, swapped architecture,
mutable action ref, write permission, changed Swift command, hidden fallback,
and comment-only decoys. Deleting `fetch-depth` or changing it from `0` to `1`
must also fail.

**Step 2: Run focused tests and verify RED**

Expected: failures because the workflow and seal do not exist.

**Step 3: Add the exact workflow**

Use the pinned checkout action already approved in sibling repositories:

```text
actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
```

Every checkout step uses:

```yaml
with:
  persist-credentials: false
  fetch-depth: 0
```

The Swift job records host facts and test output in the GitHub log and
`GITHUB_STEP_SUMMARY`. Record all host facts first. For the Swift test step,
use `set -uo pipefail`, temporarily disable immediate exit around the `tee`
pipeline, save `PIPESTATUS[0]`, append that exact exit status to the summary,
and exit with the saved status. Do not upload artifacts or allow a failing
Swift command to look successful.

**Step 4: Seal the reviewed workflow**

Compute its LF-normalized SHA-256 once, place that single digest in the
validator, and validate the digest before semantic helpers. Tests must prove
CRLF equivalence and reject every one-byte semantic drift.

**Step 5: Run focused tests and verify GREEN**

Expected: canonical and CRLF workflow inputs pass; all mutations fail.

**Step 6: Commit**

```powershell
git add .github/workflows/migration-baseline.yml tools/validate_migration_baseline.py tests/test_validate_migration_baseline.py
git commit -s -m "ci: prove Mac-Win baseline on Intel and Apple Silicon"
```

### Task 5: Add annotated-tag verification and the repository entry point

**Files:**

- Modify: `tools/validate_migration_baseline.py`
- Modify: `tests/test_validate_migration_baseline.py`
- Modify: `docs/migration-baseline.md`

**Step 1: Write failing tag tests**

In temporary repositories require:

- default validation passes before the tag exists;
- `--require-tag` rejects a missing tag;
- a lightweight tag is rejected;
- an annotated tag at the wrong commit is rejected;
- an annotated tag at the exact source commit passes;
- a replace ref cannot change the peeled result;
- extra CLI arguments fail with usage status.

**Step 2: Run focused tests and verify RED**

Expected: failures because the CLI and tag verifier are incomplete.

**Step 3: Implement the CLI**

Use `argparse` with only `--require-tag`. The default entry point validates
manifest, Git source, reviewed documents, and workflow. Tag mode additionally
requires:

```text
git cat-file -t refs/tags/mw-migration-baseline-4e421fb == tag
git rev-parse refs/tags/mw-migration-baseline-4e421fb^{} == 4e421f...
```

Emit one stable success line and send failures to stderr with exit status 1.
Set `sys.dont_write_bytecode = True` only under `if __name__ == "__main__"`.

**Step 4: Run focused and full dependency-free tests**

Run:

```powershell
python -B -m unittest discover -s tests -p "test_validate_migration_baseline.py" -v
python -B -m unittest discover -s tests -p "test_*.py" -v
python tools\validate_migration_baseline.py
```

Expected: all pass; the ordinary validator command leaves no `.pyc` or
`__pycache__` files.

**Step 5: Commit**

```powershell
git add tools/validate_migration_baseline.py tests/test_validate_migration_baseline.py docs/migration-baseline.md
git commit -s -m "feat: verify immutable Mac-Win baseline tag"
```

### Task 6: Review and publish the implementation PR

**Files:**

- Review all files changed from `origin/main`.

**Step 1: Run final local verification**

Run:

```powershell
python -B -m unittest discover -s tests -p "test_*.py" -v
python tools\validate_migration_baseline.py
git diff --check origin/main...HEAD
git status --short --branch
```

Record that Swift execution is unavailable on the Windows host and is deferred
to the two authoritative macOS jobs.

**Step 2: Perform two-stage review**

First request specification compliance review against MW-MIG-001 and the
approved design. After fixes and re-review, request code-quality/security
review. Reviewers are read-only and must not modify the implementation
worktree.

**Step 3: Push and open a Draft PR**

Push `agent/macwin-migration-baseline` and open a Draft PR against `main` with
the source SHA, freeze boundary, local test evidence, tag policy, and explicit
macOS evidence dependency.

**Step 4: Wait for all three jobs**

Require success for:

- repository contract;
- Apple Silicon Swift baseline;
- Intel Swift baseline.

Inspect the run logs and summaries for the expected architecture, Swift
version, macOS version, CPU identity, and full Swift test outcome. Failed or
cancelled jobs leave the PR unmerged.

**Step 5: Mark Ready and merge with an expected head SHA**

Confirm no unresolved reviews or threads, then merge with a merge commit. Fetch
the new `main`, verify the exact merge SHA, and require post-merge CI success on
that SHA.

### Task 7: Publish the source-baseline tag and close MW-MIG-001

**Files:**

- No source changes.

**Step 1: Prove the tag is absent**

Run a local tag query, remote `git ls-remote`, and GitHub tag lookup. Stop if
the name already exists.

**Step 2: Create the annotated tag at the source commit**

Inspect repository signing policy and key configuration first. If none is
configured, create an explicitly non-signed annotated tag so ambient global
configuration cannot enable signing:

```powershell
git tag -a --no-sign mw-migration-baseline-4e421fb 4e421fbea6f59e73e4f813c1f0a14e8db9e36de7 -m "Mac-Win migration source baseline 4e421fb"
```

Push only that tag. Verify the remote tag object and peeled SHA independently.
Do not move or delete it.

**Step 3: Validate the published tag from current main**

Run:

```powershell
python -B tools\validate_migration_baseline.py --require-tag
```

Expected: the annotated tag is present and peels to the exact source commit.

**Step 4: Complete the issue audit**

Update MW-MIG-001 only after checking each acceptance item against:

- source and manifest;
- merged README and migration documentation;
- the post-merge dual-architecture CI run and host facts;
- local and remote annotated-tag identities;
- known failures and rollback policy.

Add one evidence comment with links and exact SHAs, check all satisfied boxes,
and close with reason `completed`. If any architecture lacks evidence, leave the
issue open and do not claim completion.

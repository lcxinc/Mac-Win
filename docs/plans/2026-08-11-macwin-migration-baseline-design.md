# Mac-Win Migration Baseline Design

## Purpose

MW-MIG-001 freezes Mac-Win commit
`4e421fbea6f59e73e4f813c1f0a14e8db9e36de7` as the migration source
baseline. The repository remains available as evidence and as an input to
later asset extraction, but it stops accepting new SwiftUI, Bridge, or legacy
launcher product features.

This slice does not resume product development, migrate assets, publish
CompatForge artifacts, or make compatibility claims that have not been
observed on macOS.

## Approved approach

The baseline is represented in three complementary forms:

1. A closed, machine-readable manifest records the repository, complete source
   commit, immutable tag name, Swift package path, supported evidence runners,
   and frozen feature areas.
2. Public documentation explains the freeze, the evidence boundary, known
   failures, rollback policy, and the next migration owner.
3. A GitHub Actions workflow runs the same Swift package test command on an
   Apple Silicon runner and an Intel runner and records the host facts in the
   run summary and logs.

The baseline tag is `mw-migration-baseline-4e421fb`. It is an annotated tag
whose peeled commit must be exactly
`4e421fbea6f59e73e4f813c1f0a14e8db9e36de7`. The tag intentionally identifies
the source snapshot, not the later commit that adds freeze documentation and
CI. After publication it must not be moved or deleted; corrections use a new
superseding tag.

## Repository layout

The implementation adds:

- `README.md` with a prominent migration-freeze notice.
- `migration/baseline.json` as the closed baseline contract.
- `docs/migration-baseline.md` as the human-readable evidence and rollback
  record.
- `tools/validate_migration_baseline.py` as a dependency-free, fail-closed
  validator.
- `tests/test_validate_migration_baseline.py` for positive and negative
  contract cases.
- `.github/workflows/migration-baseline.yml` for repository-contract and
  dual-architecture Swift evidence.

The existing Swift package and product sources are not modified.

## Manifest contract

`migration/baseline.json` uses schema version 1 and exactly these fields:

- `schemaVersion`: integer `1`.
- `repository`: exact string `a1112/Mac-Win`.
- `sourceCommit`: exact 40-character lowercase SHA-1
  `4e421fbea6f59e73e4f813c1f0a14e8db9e36de7`.
- `tag`: exact string `mw-migration-baseline-4e421fb`.
- `swiftPackagePath`: exact relative path `MacWinManager`.
- `evidenceTargets`: exactly one `macos-15`/`arm64` entry and one
  `macos-15-intel`/`x86_64` entry.
- `frozenFeatureAreas`: exactly `SwiftUI`, `Bridge`, and `legacy-launcher`.

Unknown fields, duplicate JSON keys, type substitutions, unsafe paths,
duplicate targets, missing targets, and malformed identities fail closed. The
serialized manifest is bounded before JSON allocation.

## Validator boundary

The validator uses only the Python standard library and performs no network
access. It:

- reads each reviewed input with an explicit byte limit and strict UTF-8;
- rejects duplicate JSON keys and closed-schema violations;
- verifies that the source commit exists in the local Git object database and
  is an ancestor of the current checkout;
- requires the exact freeze notice and migration evidence statements;
- seals the reviewed workflow with an LF-normalized SHA-256 digest so YAML
  comments or alternate structures cannot satisfy substring checks;
- rejects linked/reparse-point reviewed inputs and unexpected Git index modes;
- defaults to validating the pre-tag repository state;
- under `--require-tag`, requires an annotated local tag object and verifies
  that it peels to the exact source commit.

All Git subprocesses run at the repository root derived from the validator's
own path, use argument arrays, disable prompts, lazy fetch, and replace
objects, and never invoke a shell. They discard inherited repository, index,
object-store, alternates, and namespace overrides before reading Git state.

## CI and evidence flow

The workflow has `contents: read`, pinned first-party actions, bounded job
timeouts, and no artifact publication or release permissions. Every checkout
that runs the validator uses `fetch-depth: 0`; full local history is required
to prove that the frozen source commit exists and is an ancestor of the
current PR or merge commit.

The repository-contract job runs the Python unit tests and validator. The
Swift matrix has two explicit entries:

- `macos-15`, expected `arm64`;
- `macos-15-intel`, expected `x86_64`.

Each matrix job records:

- `swift --version`;
- `sw_vers`;
- `uname -m`;
- `sysctl -n machdep.cpu.brand_string`;
- `swift test --package-path MacWinManager` output and exit status.

The job fails if the observed architecture differs from the matrix contract or
if any Swift test fails. It records all host facts before testing, temporarily
captures the Swift pipeline status, writes that status to the job summary even
on failure, and finally exits with the original Swift status. GitHub run logs
and summaries are the authoritative macOS execution evidence. The issue
receives the final run URL, job results, host facts, known failures, and tag
object/peeled commit before closure.

GitHub-hosted macOS runners in this private repository consume the account's
Actions minutes. That cost and the `macos-15`/`macos-15-intel` labels were
explicitly approved for this slice.

## Failure and rollback behavior

- If either architecture cannot provision, has an unexpected architecture, or
  fails Swift tests, MW-MIG-001 remains open and no tag is published.
- Known failures are recorded as evidence; they are not silently converted to
  passing expectations.
- Before tag publication, the PR can be reverted normally.
- After tag publication, the tag remains immutable. If repository signing is
  not configured, tag creation explicitly disables automatic signing. A
  baseline error is
  corrected with a new superseding tag and an explicit issue record.
- The validator never downloads missing commits or tags and never mutates a
  Bottle, runtime, source asset, or product state.

## Scope exclusions and follow-up

MW-MIG-002 remains blocked until this baseline is complete. Asset inventory,
patch licensing, portable recipe conversion, Bottle migration, and CompatForge
runtime work are separate issues.

CompatForge documentation that still names the older `4282ed9` ancestor will
be corrected in a separate documentation-only change. Mixing that cross-
repository correction into this PR would blur ownership and rollback.

## Acceptance

The slice is complete only when:

1. Local dependency-free tests and validator pass without leaving bytecode.
2. The GitHub Actions repository-contract, Apple Silicon Swift, and Intel Swift
   jobs all pass on the merge commit.
3. The annotated tag exists remotely and peels to the exact frozen source
   commit.
4. README and migration documentation expose the freeze and evidence boundary.
5. MW-MIG-001 contains the CI, environment, known-failure, tag, and rollback
   evidence before its acceptance boxes are checked and the issue is closed.

# Mac-Win migration baseline

## Baseline identity and freeze

Mac-Win is frozen at `4e421fbea6f59e73e4f813c1f0a14e8db9e36de7` for migration evidence.

New SwiftUI, Bridge, and legacy launcher product features are not accepted.

The immutable annotated baseline tag is `mw-migration-baseline-4e421fb`.

## Authoritative macOS evidence

Required runner and architecture: `macos-15` / `arm64`.

Required runner and architecture: `macos-15-intel` / `x86_64`.

Required host/test command: `swift --version`.

Required host/test command: `sw_vers`.

Required host/test command: `uname -m`.

Required host/test command: `sysctl -n machdep.cpu.brand_string`.

Required host/test command: `swift test --package-path MacWinManager`.

Windows output is not macOS evidence.

The authoritative macOS evidence is the GitHub Actions run URL plus the logs and job summary for both required runner and architecture jobs.

Known failures must be recorded in MW-MIG-001 with the affected runner, observed architecture, command, exit status, and CI run URL; they must not be converted into passing expectations.

Tag evidence must record both the annotated tag object ID and its peeled commit ID before MW-MIG-001 closes.

## Tag verification procedure

Before tag creation, run `python tools/validate_migration_baseline.py`; this pre-tag check intentionally does not require the tag and is not tag evidence.

After the merge commit passes both macOS evidence jobs, create the annotated tag directly at the frozen source with `git tag --no-sign -a mw-migration-baseline-4e421fb 4e421fbea6f59e73e4f813c1f0a14e8db9e36de7 -m "Mac-Win migration baseline 4e421fb"`.

Before publication, run `python tools/validate_migration_baseline.py --require-tag`; this post-tag check requires a local annotated tag that directly references and peels to `4e421fbea6f59e73e4f813c1f0a14e8db9e36de7`.

Publish only the verified tag with `git push origin refs/tags/mw-migration-baseline-4e421fb` and record the tag object ID plus peeled commit ID as the authoritative tag evidence.

## Rollback and ownership

Before tag publication, rollback is a normal revert of the migration-baseline change; a failed or unavailable target keeps MW-MIG-001 open and prevents tag publication.

After publication, `mw-migration-baseline-4e421fb` must not be moved or deleted; corrections use a new superseding annotated tag and an explicit issue record.

MW-MIG-002 is the next owner after MW-MIG-001 completes.

Asset migration and CompatForge publication are explicitly excluded from MW-MIG-001.

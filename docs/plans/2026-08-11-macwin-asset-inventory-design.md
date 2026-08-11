# Mac-Win Migration Asset Inventory Design

## Purpose

MW-MIG-002 exports the migration inputs frozen by MW-MIG-001 as a
deterministic, digest-pinned inventory. The inventory is evidence about the
legacy repository; it does not resume Mac-Win product development, convert the
assets, download external inputs, execute probes, or inspect or mutate a user
Bottle.

The immutable source is commit
`db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527`, identified by annotated tag
`mw-migration-baseline-db12d5e`. Inventory code may live in later commits, but
all asset paths, Git object identities, sizes, and content digests are derived
only from that frozen Git tree.

## Approved approach

Use a root index, five category shards, one dependency-evidence document, and
a compact manual metadata policy. This is preferred over one large JSON file,
which would be difficult to review and likely exceed the bounded-document
limit, and over one file per asset, which would add unnecessary schema and
global-uniqueness complexity.

The generator expands the reviewed policy, reads the frozen Git tree and blobs,
and produces canonical JSON in memory. Validation regenerates the same bytes
and compares them with the committed index and shards. No timestamp, locale,
worktree content, environment-dependent path, network response, or executable
output participates in generation.

## Inventory scope

The v1 inventory is a broad closure over the migration-relevant tracked assets
at the frozen commit. It contains exactly 90 asset records:

| Category | Frozen source paths | Count |
| --- | --- | ---: |
| Catalog | 17 recipe JSON files plus `catalog.index.json` and `catalog.signature.json` | 19 |
| Patches | All `patches/*.patch`, including seven Wine and four JASP patches | 11 |
| Probes | All 22 non-fixture files under `scripts/` plus the four native UI probe files under `MacWinManager/Tools/` | 26 |
| Fixtures | All files under `scripts/fixtures/`, including the Godot fixture subtree | 30 |
| Bottle schema | `Models.swift`, `MacWinPaths.swift`, `BottleService.swift`, and `JSONStore.swift` | 4 |

UI icons, asset catalogs, generated build products, ignored directories, and
real Bottle contents are excluded. The Bottle category inventories only the
four source files that define the legacy manifest, paths, persistence, and
layout behavior. It documents format facts such as `manifest.json`, `drive_c/`,
registry files, `fonts.conf`, and sentinels without walking any Bottle
directory.

The dependency evidence also records:

- all external URLs referenced by the frozen assets, including the 234 unique
  download entries in `scripts/download-software-samples.sh`;
- ignored or absent `refs/` inputs;
- frozen development-machine absolute paths and environment-derived paths;
- whether each dependency is in the baseline, unresolved, or explicitly
  unavailable.

These references are evidence records, not additional downloadable assets.

## Repository layout

The implementation adds:

- `migration/assets/metadata-policy.json` for reviewed human classifications;
- `migration/assets/index.json` as the root inventory contract;
- `migration/assets/catalog.json`;
- `migration/assets/patches.json`;
- `migration/assets/probes.json`;
- `migration/assets/fixtures.json`;
- `migration/assets/bottle-schema.json`;
- `migration/assets/dependencies.json` for external and development-machine
  dependencies;
- `tools/generate_migration_asset_inventory.py` as the dependency-free,
  deterministic generator;
- `tools/validate_migration_asset_inventory.py` as the fail-closed validator;
- `tests/test_migration_asset_inventory.py` for contract, Git, security, and
  determinism tests;
- `docs/migration-asset-inventory.md` for the human-readable ownership and
  evidence boundary.

The existing repository-contract job runs the new tests and validator. The
Swift product sources and the published baseline tag are not modified.

## Root and shard contracts

All JSON contracts use schema version `1`, strict UTF-8, LF endings, unique
keys, closed object shapes, and canonical serialization. The root index binds:

- repository `a1112/Mac-Win`;
- the complete frozen source commit and annotated tag;
- digest algorithm `sha256`;
- ordering rule `ascii-posix-path`;
- each shard path, SHA-256, category, and asset count;
- the total asset and dependency counts.

Every generated asset entry contains:

- `sourcePath`;
- `sourceCommit`;
- `gitBlobOid`;
- raw-byte `sha256`;
- `byteSize`;
- `gitMode`;
- `kind`;
- `license`;
- `provenance`;
- `intendedOwner`;
- `externalRefs`;
- `developmentDependencies`.

Paths are ASCII POSIX-relative paths sorted by their encoded bytes. They may
not contain a leading slash, drive or URI syntax, backslashes, `..`, NUL,
duplicate separators, or case-fold collisions. Each v1 asset must be a regular
`100644` or executable `100755` blob. Symbolic links, submodules, missing
objects, unknown modes, duplicate paths, and unclassified governed files fail
closed.

## Manual metadata policy

The policy explicitly lists every governed source path, grouped only to avoid
repeating identical metadata. Generation expands the groups so every output
entry independently records its license, provenance, owner, and dependency
fields. A new file under a governed root without a policy entry is an error;
removing a governed file without updating the policy is also an error.

License and provenance are closed tagged unions. `unresolved` is a valid and
visible state; publisher names, download terms, or upstream project reputation
must not be treated as asset-license evidence. Patches whose upstream base or
license is not proven remain unresolved for MW-ASSET-002 rather than being
silently classified.

`intendedOwner` is a stable migration-domain identifier, not a personal
account. The v1 enum is:

- `compatforge/catalog`;
- `compatforge/patches`;
- `compatforge/probes`;
- `compatforge/bottle-schema`;
- `macwin/archive`;
- `quarantine/unresolved`.

Adding a kind, owner, license state, provenance state, or field requires a
schema-version change. Unknown values and fields fail closed.

The unpublished v1 dependency policy uses a bounded source-grouped encoding:
each closed record contains `sourcePath`, `kind`, `status`, and a non-empty,
sorted `locators` list. The parser expands those groups to individual evidence
identities `(sourcePath, literal locator, kind, status)` before exact
comparison. Repeating `sourcePath`, `kind`, and `status` for every download URL
would exceed the 64 KiB policy limit before the other dependency classes were
included; the grouped encoding keeps the reviewed policy at 50,227 bytes
without dropping or summarizing any locator.

## Deterministic generation

The generator locates its repository from its own file, validates the frozen
commit and tag locally, enumerates only the approved Git tree paths, and reads
objects by resolved object ID. It uses fixed argument arrays and never invokes
a shell. Every Git subprocess:

- preserves required process facilities such as `PATH`;
- removes inherited repository, index, object-store, alternates, namespace,
  and config-injection overrides;
- sets `GIT_NO_LAZY_FETCH=1`, `GIT_NO_REPLACE_OBJECTS=1`, and
  `GIT_TERMINAL_PROMPT=0`;
- performs no network operation and writes no Git state.

SHA-256 is computed over raw Git blob bytes with no CRLF normalization.
Generated documents and policy inputs are bounded to 64 KiB each before JSON
allocation. Asset objects are type-checked and size-checked before reading;
v1 permits at most 1 MiB per asset and hashes the bounded raw bytes. The current
largest governed blob is below that limit.

Canonical generation run twice against the same Git objects must produce
byte-identical output. Policy ordering, locale, timezone, worktree CRLF,
ignored files, dirty files, and ambient Git configuration cannot change it.

## Dependency evidence

External references use explicit statuses such as `external-unverified` and
`not-in-baseline`. Development-machine dependencies record their literal or
normalized locator, the asset that references them, and why they are not
portable. The generator may scan frozen text blobs with closed extraction
rules and requires the result to match the reviewed dependency policy.

It does not resolve DNS, make HTTP requests, inspect local ignored `refs/`,
expand `$HOME`, read user application support, or test whether a local path
exists. This keeps absent dependencies visible without making output depend on
the development machine.

The frozen 90-asset scan has the following exact evidence counts. Counts are
evidence identities, so the same locator referenced by two assets remains two
records:

- 302 URL occurrences become 277 unique evidence identities and 269 distinct
  literal locators; `scripts/download-software-samples.sh` contributes exactly
  234 identities and 234 distinct locators;
- 25 `/Users/a1-6/...` occurrences become 23 unique evidence identities and 17
  distinct literal locators;
- development evidence contains 107 identities: 23 `absolute-path`, 49
  `environment-path`, and 35 `repository-path` records.

The URL grammar preserves the complete regex-escaped
`https://zlib\\.net/fossils/zlib-1\\.2\\.13\\.tar\\.gz` locator as evidence
instead of truncating it to `https://zlib`. Development locators are neither
expanded nor rewritten, and files outside the 90 governed assets do not
participate in these counts.

## Validation and threat boundary

Validation fails before generation or comparison when it encounters:

- oversized, deeply nested, duplicate-key, malformed, or non-UTF-8 policy or
  inventory JSON;
- unknown, missing, duplicate, or type-substituted fields;
- an unexpected source commit, tag, repository, category, owner, or state;
- a governed-path coverage mismatch;
- a missing, replaced, wrong-type, oversized, linked, or wrong-mode Git object;
- a Git OID, size, SHA-256, shard digest, count, or canonical-byte mismatch;
- undeclared external references or development-machine dependencies;
- any generated or validation-time filesystem mutation outside an explicitly
  caller-selected temporary output directory.

Tests use temporary Git repositories for missing objects, replace refs,
symlinks, submodules, index/worktree drift, alternate object databases,
case-fold collisions, and dirty checkouts. Repository and representative
Bottle-directory snapshots before and after generation prove that the default
generator and validator are read-only.

## CI and line endings

The repository-contract job on Ubuntu checks out full history, runs all Python
tests, runs the baseline validator, and runs the asset-inventory validator in
check mode. It needs no macOS runner and performs no Swift execution.

`.gitattributes` fixes `migration/**/*.json` to LF. This both makes generated
canonical documents reviewable across platforms and closes the existing
Windows false failure where `migration/baseline.json` was checked out as CRLF
while its test compared LF bytes. Git blob digests remain raw and immutable.

## Failure, rollback, and future changes

- Before merge, the inventory branch and generated files can be reverted
  normally.
- After merge, the source tag remains immutable; inventory corrections modify
  policy or generator code in a new reviewed commit and never move the tag.
- A source-snapshot correction requires a new superseding annotated baseline
  tag and explicit issue record.
- MW-MIG-002 does not decide patch licensing, apply patches, convert recipes,
  migrate Bottles, or publish CompatForge assets. Those remain follow-up
  issues.

## Acceptance

MW-MIG-002 is complete only when:

1. All 90 governed source assets have exact raw Git blob identities and
   expanded metadata records.
2. Missing external references and development-machine dependencies are
   explicit and deterministic.
3. Two generation runs are byte-identical and committed outputs match the
   regenerated bytes.
4. Tests prove fail-closed Git, JSON, path, size, environment, and coverage
   boundaries.
5. Generation and validation perform no network access, execute no asset, and
   do not read or mutate a Bottle.
6. Repository-contract CI passes and issue #3 contains the final inventory,
   commit, test, and rollback evidence.

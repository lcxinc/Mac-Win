# Mac-Win migration asset inventory

## Evidence identity and scope

The immutable source is commit
`db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527`, identified by annotated tag
`mw-migration-baseline-db12d5e`.

This inventory is evidence, not a portability, compatibility, or license attestation.

The frozen inventory contains exactly 90 assets:

| Category | Assets |
| --- | ---: |
| Catalog | 19 |
| Patches | 11 |
| Probes | 26 |
| Fixtures | 30 |
| Bottle schema | 4 |
| **Total** | **90** |

Each record binds its frozen source path and commit to a Git blob OID, raw-byte
SHA-256, byte size, Git mode, kind, reviewed policy metadata, and dependency
evidence. Worktree contents do not supply asset bytes.

## Generated documents and bounds

`migration/assets/index.json` binds five category shards and
`migration/assets/dependencies.json`, for seven generated JSON documents in
total. `migration/assets/metadata-policy.json` is the reviewed input policy,
not an eighth generated output. Every policy or generated JSON document is
bounded to 64 KiB, uses strict UTF-8 and LF, has a closed schema, and is
serialized canonically.

Generation is deterministic from the frozen local Git objects and the reviewed
policy. `--check` regenerates in memory and compares exact committed bytes.
`--write` is the only write mode and atomically replaces only the seven
generated JSON documents after all validation succeeds.

## Dependency evidence

The inventory records 277 URL evidence identities, including 234 identities
from `scripts/download-software-samples.sh`. These are literal unresolved
references; they are not fetched or treated as additional assets.

It also records 108 development-machine dependency identities: 23
`absolute-path`, 50 `environment-path`, and 35 `repository-path` records.
Ignored or absent `refs/` inputs, frozen `/Users/a1-6/...` paths, and unexpanded
environment locators remain explicit evidence rather than host-dependent facts.

## Policy, owners, and quarantine

License and provenance remain `unresolved` for the governed assets; publisher
names, download terms, or project reputation are not substituted for evidence.
An intended owner is routing metadata, not publication approval. Unresolved assets remain quarantined from publication.

The closed intended-owner taxonomy is:

- `compatforge/catalog`
- `compatforge/patches`
- `compatforge/probes`
- `compatforge/bottle-schema`
- `macwin/archive`
- `quarantine/unresolved`

The CompatForge domains own later reviewed conversion in their named areas;
`macwin/archive` owns archive-only material, and `quarantine/unresolved` is the
fail-closed route when a migration domain cannot be assigned. MW-ASSET-002 owns license, provenance, and quarantine resolution.
MW-MIG-002 owns corrections to this inventory contract until its evidence is
recorded on the merged issue.

## Safety boundary

Generation and validation do not download dependencies or resolve URLs.
They do not execute inventoried assets or probes.
They do not read, inspect, create, or mutate a user Bottle.
They also do not expand development-machine locators, inspect ignored `refs/`,
apply patches, convert recipes, or publish CompatForge assets.

## Local review commands

Run from the repository root with the annotated baseline tag available locally:

```text
python -B tools/generate_migration_asset_inventory.py --list
python -B tools/generate_migration_asset_inventory.py --check
python -B tools/generate_migration_asset_inventory.py --write
python -B tools/validate_migration_asset_inventory.py
python -B tools/validate_migration_baseline.py --require-tag
git diff --check
git diff --exit-code -- migration/assets
```

Use `--write` only for an intentional reviewed regeneration. The final diff
commands prove formatting is valid and regenerated inventory outputs have no
unreviewed drift.

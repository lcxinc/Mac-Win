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
total.

`migration/assets/metadata-policy.json` is a bounded, closed, manually reviewed
input, not an eighth generated output. It is limited to 64 KiB and parsed as
strict UTF-8 JSON with duplicate-key rejection and a closed schema. No canonical
serialization claim is made for the manual policy.

Canonical LF serialization and exact-output comparison apply only to the seven
generated JSON documents. Each generated document is limited to 64 KiB,
serialized in the approved schema order, encoded as ASCII-compatible UTF-8
JSON, and terminated with one LF newline.

Generation is deterministic from the frozen local Git objects and the reviewed
policy. `--check` compares the seven current worktree output files with
in-memory expected bytes; it does not bind the stage-0 index. `--write` is the
only write mode and atomically replaces only the seven generated JSON documents
after all validation succeeds.

`validate_migration_asset_inventory.py` binds the manual policy's current
worktree bytes to its stage-0 index blob and validates the closed policy. It
then requires the worktree bytes and stage-0 index blob for each of the seven
generated documents to equal the in-memory expected bytes before validating the
inventory schema, counts, and digests.

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

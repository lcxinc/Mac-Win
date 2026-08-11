# Mac-Win Migration Asset Inventory Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Export and continuously verify a deterministic, digest-pinned inventory of the 90 migration assets frozen at `db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527` without executing assets, accessing the network, or reading or mutating a Bottle.

**Architecture:** A dependency-free Python generator expands a compact reviewed metadata policy, enumerates only approved paths from the immutable Git tree, reads raw blobs by object ID, and emits a canonical root index plus category and dependency shards. A separate validator regenerates all documents in memory and compares exact bytes with reviewed Git-bound files. Existing baseline validation remains authoritative for the frozen tag and workflow, while the repository-contract job adds the inventory check.

**Tech Stack:** Python 3 standard library, Git plumbing commands invoked with argument arrays, canonical JSON, SHA-256, `unittest`, GitHub Actions YAML, Markdown.

---

## Global execution rules

- Work only in `L:\project\FOS\.worktrees\macwin-asset-inventory` on branch `agent/macwin-asset-inventory`.
- Use @superpowers:test-driven-development for every behavior change: first run the focused failing test, then implement the minimum, then rerun.
- Use `apply_patch` for hand-written edits. Generated canonical JSON may be written only by the reviewed generator in explicit `--write` mode.
- Every commit uses `git commit -s`; never change global Git configuration.
- Every Git subprocess in tests uses process-local exact `safe.directory` when required.
- Do not modify Swift product sources, execute scripts or fixtures, download URLs, inspect ignored `refs/`, or read a real Bottle.
- Preserve the immutable tag `mw-migration-baseline-db12d5e`; no task moves, recreates, or deletes it.

### Task 1: Pin migration JSON line endings and establish the test entrypoint

**Files:**
- Modify: `.gitattributes`
- Modify: `tests/test_validate_migration_baseline.py`
- Create: `tests/test_migration_asset_inventory.py`

**Step 1: Write the failing line-ending tests**

Add a baseline regression that runs:

```python
result = run_git("check-attr", "eol", "--", "migration/baseline.json")
self.assertEqual(result.stdout.strip(), "migration/baseline.json: eol: lf")
```

Add an inventory test skeleton that proves the planned generator, validator,
policy, index, and six shards do not yet exist. Keep the test import-safe so the
only RED reason is the missing contract.

**Step 2: Run the focused RED**

Run:

```powershell
$env:PYTHONDONTWRITEBYTECODE='1'
python -B -m unittest tests.test_validate_migration_baseline.MigrationBaselineManifestTests.test_migration_json_is_lf_pinned -v
python -B -m unittest tests.test_migration_asset_inventory -v
```

Expected: the attribute is unspecified and inventory paths are missing.

**Step 3: Add the minimal line-ending contract**

Append:

```gitattributes
migration/*.json text eol=lf
migration/**/*.json text eol=lf
```

Change the existing physical-worktree serialization assertion so it accepts
only LF or CRLF presentation while still comparing canonical LF content:

```python
raw = MANIFEST_PATH.read_bytes()
self.assertNotIn(b"\r\r\n", raw)
self.assertEqual(raw.replace(b"\r\n", b"\n"), expected)
```

Do not weaken index/blob verification in the production validator.

**Step 4: Run GREEN and the known baseline suite**

Run:

```powershell
python -B -m unittest tests.test_validate_migration_baseline.MigrationBaselineManifestTests -v
python -B -m unittest discover -s tests -p 'test_*.py' -v
```

Expected: the previous Windows CRLF failure is gone; the new inventory skeleton
remains intentionally RED until Task 2 only if separated by a skipped contract
marker. Prefer keeping Task 1 independently green by asserting only the new
entrypoint test module loads.

**Step 5: Commit**

```powershell
git add .gitattributes tests/test_validate_migration_baseline.py tests/test_migration_asset_inventory.py
git commit -s -m "test: pin migration contract line endings"
```

### Task 2: Implement bounded policy parsing and the closed schema

**Files:**
- Create: `migration/assets/metadata-policy.json`
- Create: `tools/generate_migration_asset_inventory.py`
- Modify: `tests/test_migration_asset_inventory.py`

**Step 1: Write policy parser RED tests**

Cover:

- exact schema version, repository, source commit, source tag, groups, and
  dependency policy;
- raw duplicate keys, including Unicode-escaped key collisions;
- unknown/missing fields and bool/int/string substitutions;
- strict UTF-8, maximum 64 KiB before JSON allocation, and JSON nesting 128;
- closed enums for category, kind, license/provenance status, and intendedOwner;
- ASCII POSIX-relative paths, uniqueness, and case-fold collision rejection;
- all `externalRefs` and `developmentDependencies` fields present even when
  empty.

Use stable messages that never echo hostile keys or values.

**Step 2: Run RED**

Run:

```powershell
python -B -m unittest discover -s tests -p 'test_migration_asset_inventory.py' -k AssetPolicyTests -v
```

Expected: import failure because the generator module and policy parser do not
exist.

**Step 3: Implement the minimal parser**

Create constants for the exact repository, frozen source commit, tag, limits,
and enums. The JSON loader must:

```python
if len(raw) > MAX_DOCUMENT_BYTES:
    raise InventoryError("inventory document exceeds the byte limit")
text = raw.decode("utf-8", errors="strict")
validate_json_depth(text, MAX_JSON_DEPTH)
value = json.loads(text, object_pairs_hook=reject_duplicate_keys)
```

Use exact-key helpers for every object. Do not accept extensions in v1.

Populate the policy with the approved 90 paths grouped as:

- 19 catalog assets owned by `compatforge/catalog`;
- 11 patches owned by `compatforge/patches` or explicitly
  `quarantine/unresolved`;
- 26 probes owned by `compatforge/probes` or `macwin/archive`;
- 30 fixtures owned by `compatforge/probes`;
- four Bottle schema sources owned by `compatforge/bottle-schema`.

License and provenance may be explicitly unresolved; do not infer SPDX values.

**Step 4: Run GREEN**

Run:

```powershell
python -B -m unittest discover -s tests -p 'test_migration_asset_inventory.py' -k AssetPolicyTests -v
```

Expected: all policy tests pass.

**Step 5: Commit**

```powershell
git add migration/assets/metadata-policy.json tools/generate_migration_asset_inventory.py tests/test_migration_asset_inventory.py
git commit -s -m "feat: define migration asset metadata policy"
```

### Task 3: Bind governed paths to immutable Git objects

**Files:**
- Modify: `tools/generate_migration_asset_inventory.py`
- Modify: `tests/test_migration_asset_inventory.py`

**Step 1: Write Git-bound RED tests**

Use temporary repositories to cover:

- frozen commit and annotated tag exist locally and match exactly;
- source commit is a commit and tag peels directly to it;
- governed roots contain exactly the policy paths;
- added or removed governed files fail closed;
- regular `100644` and `100755` blobs pass;
- symlink `120000`, submodule `160000`, tree, tag, missing object, and unknown
  mode fail;
- replace refs, lazy fetch, prompts, alternate object databases, namespaces,
  index/worktree overrides, and config-injection variables cannot change reads;
- dirty or CRLF worktrees cannot change generated asset records.

Assert every subprocess uses `shell=False`, the exact repository root, a copied
environment with hostile Git variables removed, and the three forced safety
variables.

**Step 2: Run RED**

```powershell
python -B -m unittest discover -s tests -p 'test_migration_asset_inventory.py' -k AssetGitBindingTests -v
```

Expected: missing Git reader and governed-scope functions.

**Step 3: Implement sanitized Git plumbing**

Implement one `_run_git()` wrapper and use only fixed operations such as:

```text
cat-file -e <oid>^{commit}
cat-file -t <oid>
cat-file -s <oid>
cat-file blob <oid>
ls-tree -rz --full-tree <commit> -- <governed path>
rev-parse --verify <tag>
```

Resolve each tree entry once, assert type and size before content read, reject
assets larger than 1 MiB, verify the returned byte count, and compute SHA-256
over the raw bytes. Never read asset content from the worktree.

**Step 4: Run GREEN and verify the real frozen tree count**

```powershell
python -B -m unittest discover -s tests -p 'test_migration_asset_inventory.py' -k AssetGitBindingTests -v
python -B tools/generate_migration_asset_inventory.py --list
```

Expected: 90 unique governed assets in the approved category counts and no
repository writes.

**Step 5: Commit**

```powershell
git add tools/generate_migration_asset_inventory.py tests/test_migration_asset_inventory.py
git commit -s -m "feat: bind inventory assets to frozen Git blobs"
```

### Task 4: Extract and close external/development dependency evidence

**Files:**
- Modify: `migration/assets/metadata-policy.json`
- Modify: `tools/generate_migration_asset_inventory.py`
- Modify: `tests/test_migration_asset_inventory.py`

**Step 1: Write dependency RED tests**

Cover:

- all unique URLs in frozen governed text assets are declared;
- the 234 download entries in `scripts/download-software-samples.sh` are
  represented and remain unresolved without network access;
- ignored/absent `refs/` inputs and unique `/Users/a1-6/...` dependencies are
  explicit;
- `$HOME`, `MACWIN_JASP_*`, application-support, Desktop, and other dynamic
  locators are explicit and unexpanded;
- undeclared, duplicated, case-mutated, or malformed locators fail;
- no test or generator opens a socket, starts an asset, or probes path
  existence outside the repository.

**Step 2: Run RED**

```powershell
python -B -m unittest discover -s tests -p 'test_migration_asset_inventory.py' -k AssetDependencyTests -v
```

Expected: dependency extraction/comparison functions are missing.

**Step 3: Implement closed extraction and policy comparison**

Scan only bounded frozen text blobs. Return normalized evidence records with a
stable source path, literal locator, kind, and status. Match the extracted set
against the reviewed policy; never fetch URLs, expand variables, inspect
ignored directories, or infer that a host path exists.

Encode reviewed policy records as the unpublished v1 source-grouped closed
shape `{sourcePath, kind, status, locators}`. `locators` is non-empty, sorted,
unique, and expanded by the parser into canonical per-locator evidence rows.
This preserves the 64 KiB policy bound; the reviewed policy is 50,261 bytes.

Product-download licenses are not asset-license evidence. Keep unresolved
license/provenance states visible.

**Step 4: Run GREEN**

```powershell
python -B -m unittest discover -s tests -p 'test_migration_asset_inventory.py' -k AssetDependencyTests -v
python -B -m unittest discover -s tests -p 'test_migration_asset_inventory.py' -k test_real_frozen_evidence_has_exact_reviewed_counts_and_policy_coverage -v
```

Expected: 277 URL evidence rows, including 234 unique rows from the download
manifest; 108 development rows split into 23 absolute, 50 environment, and 35
repository paths; no external side effects. Environment evidence includes the
unexpanded `MACWIN_WINE_MONO_MSI` input from `scripts/run-software-smoke.sh`.
The 23 absolute rows represent 25
occurrences and 17 distinct literal `/Users/a1-6/...` locator strings within
the 90 governed assets only.

**Step 5: Commit**

```powershell
git add migration/assets/metadata-policy.json tools/generate_migration_asset_inventory.py tests/test_migration_asset_inventory.py
git commit -s -m "feat: record unresolved migration dependencies"
```

### Task 5: Generate canonical shards and implement exact validation

**Files:**
- Create: `migration/assets/index.json`
- Create: `migration/assets/catalog.json`
- Create: `migration/assets/patches.json`
- Create: `migration/assets/probes.json`
- Create: `migration/assets/fixtures.json`
- Create: `migration/assets/bottle-schema.json`
- Create: `migration/assets/dependencies.json`
- Create: `tools/validate_migration_asset_inventory.py`
- Modify: `tools/generate_migration_asset_inventory.py`
- Modify: `tests/test_migration_asset_inventory.py`

**Step 1: Write canonical-generation RED tests**

Cover:

- two in-memory generations are byte-identical;
- policy member order, locale, timezone, CRLF worktree, dirty files, and hostile
  environment cannot change output;
- every JSON document is strict UTF-8, LF, at most 64 KiB, closed, and ends with
  one newline;
- root count and shard digests match exact shard bytes;
- every expanded asset independently contains all required fields;
- changing a blob digest, OID, size, mode, count, shard path, or metadata fails;
- default generator/check mode writes nothing;
- explicit `--write` writes only the eight approved JSON outputs atomically;
- validator regenerates in memory and compares committed bytes exactly.

**Step 2: Run RED**

```powershell
python -B -m unittest tests.test_migration_asset_inventory.AssetCanonicalOutputTests -v
```

Expected: output renderer, CLI, and validator are missing.

**Step 3: Implement canonical rendering and CLIs**

Use:

```python
json.dumps(value, ensure_ascii=True, sort_keys=False, separators=(",", ":"), indent=2).encode("ascii") + b"\n"
```

Construct dictionaries in schema order and sort asset paths by ASCII bytes.
The generator defaults to `--check`; `--write` is explicit and confined to the
reviewed output directory. The validator has no write mode.

Generate the reviewed JSON files only after all in-memory validation succeeds.

**Step 4: Run GREEN and generate reviewed outputs**

```powershell
python -B -m unittest tests.test_migration_asset_inventory.AssetCanonicalOutputTests -v
python -B tools/generate_migration_asset_inventory.py --write
python -B tools/generate_migration_asset_inventory.py --check
python -B tools/validate_migration_asset_inventory.py
```

Expected: both CLIs report success; a second `--write` produces no Git diff.

**Step 5: Commit**

```powershell
git add migration/assets/index.json migration/assets/catalog.json migration/assets/patches.json migration/assets/probes.json migration/assets/fixtures.json migration/assets/bottle-schema.json migration/assets/dependencies.json tools/generate_migration_asset_inventory.py tools/validate_migration_asset_inventory.py tests/test_migration_asset_inventory.py
git commit -s -m "feat: export deterministic migration asset inventory"
```

### Task 6: Prove no execution, network, Bottle, or repository mutation

**Files:**
- Modify: `tests/test_migration_asset_inventory.py`
- Modify if required: `tools/generate_migration_asset_inventory.py`
- Modify if required: `tools/validate_migration_asset_inventory.py`

**Step 1: Write hostile side-effect RED tests**

Create sentinels and before/after snapshots for:

- repository files, index, refs, object database, and config;
- a fake Bottle directory outside the repository;
- ignored `refs/` and Downloads-like paths;
- subprocess creation and network/socket calls.

Assert default generation and validation do not mutate any snapshot, invoke an
asset path, open a network connection, or read the fake Bottle. Include hostile
policy values that resemble commands, URLs, paths, and environment syntax and
verify they remain inert data.

**Step 2: Run RED**

```powershell
python -B -m unittest tests.test_migration_asset_inventory.AssetSideEffectTests -v
```

Expected: the initial instrumentation exposes any unbounded or overly broad
read/write path; if already green, introduce a controlled mutant that calls
`Path.exists()` on a dependency and prove the test turns red before restoring.

**Step 3: Apply the minimum hardening**

Keep all asset reads content-addressed through Git. Ensure explicit `--write`
uses a validated output-root allowlist, writes temporary sibling files, and
atomically replaces only the eight generated JSON targets. Validation remains
strictly read-only.

**Step 4: Run GREEN and the complete focused suite**

```powershell
python -B -m unittest tests.test_migration_asset_inventory -v
```

Expected: all inventory tests pass with no cache or temporary files left.

**Step 5: Commit**

```powershell
git add tests/test_migration_asset_inventory.py tools/generate_migration_asset_inventory.py tools/validate_migration_asset_inventory.py
git commit -s -m "test: prove inventory generation is inert"
```

### Task 7: Document the inventory and integrate repository-contract CI

**Files:**
- Create: `docs/migration-asset-inventory.md`
- Modify: `README.md`
- Modify: `.github/workflows/migration-baseline.yml`
- Modify: `tools/validate_migration_baseline.py`
- Modify: `tests/test_validate_migration_baseline.py`
- Modify: `tests/test_migration_asset_inventory.py`

**Step 1: Write documentation and workflow RED tests**

Require visible statements for:

- frozen source/tag and exact inventory counts;
- unresolved license/provenance and quarantine boundaries;
- 234 external URL evidence and development-machine dependencies;
- no download, execution, Bottle read/write, or portability claim;
- intended-owner taxonomy and follow-up issue ownership;
- canonical local `--check`, validator, and diff commands.

Require the repository-contract job, after full-history checkout, to run:

```yaml
python -B -m unittest discover -s tests -p 'test_*.py' -v
python tools/validate_migration_baseline.py
python tools/validate_migration_asset_inventory.py
```

Preserve permissions, pinned actions, macOS matrix evidence, Xcode 16.2 pin,
bounded summaries, and failure propagation. The existing workflow whole-file
seal must reject the changed workflow until intentionally updated.

**Step 2: Run RED**

```powershell
python -B -m unittest tests.test_validate_migration_baseline.MigrationBaselineWorkflowTests -v
python -B -m unittest tests.test_migration_asset_inventory.AssetDocumentationTests -v
```

Expected: missing docs/README statement and workflow command/seal mismatch.

**Step 3: Add the minimum docs and workflow integration**

Write the human evidence document, add a README link without weakening the
freeze notice, insert the validator command into repository-contract, and
update the approved workflow LF SHA-256 only after all semantic checks are in
place. Add focused mutations for deletion, reordering, comment decoys, and
permission/toolchain regressions.

**Step 4: Run GREEN**

```powershell
python -B -m unittest tests.test_validate_migration_baseline.MigrationBaselineWorkflowTests -v
python -B -m unittest tests.test_migration_asset_inventory.AssetDocumentationTests -v
python -B tools/validate_migration_baseline.py
python -B tools/validate_migration_asset_inventory.py
```

Expected: both validators and focused tests pass.

**Step 5: Commit**

```powershell
git add README.md docs/migration-asset-inventory.md .github/workflows/migration-baseline.yml tools/validate_migration_baseline.py tests/test_validate_migration_baseline.py tests/test_migration_asset_inventory.py
git commit -s -m "docs: publish migration asset inventory boundary"
```

### Task 8: Fresh verification, two-stage review, and PR preparation

**Files:**
- Modify only findings required by review; keep each fix in a separate DCO
  commit.

**Step 1: Run the complete fresh verification matrix**

Run with bytecode disabled and only process-local exact `safe.directory` if
needed:

```powershell
$env:PYTHONDONTWRITEBYTECODE='1'
python -B -m unittest discover -s tests -p 'test_*.py' -v
python -B tools/generate_migration_asset_inventory.py --check
python -B tools/validate_migration_asset_inventory.py
python -B tools/validate_migration_baseline.py
git diff --check main...HEAD
git status --short --branch
```

Also prove:

- a second generation is byte-identical;
- no `__pycache__`, `.pyc`, temporary output, Bottle mutation, or repository
  mutation exists;
- all commits contain DCO trailers;
- the published baseline tag object and peeled source are unchanged;
- Swift product-source diff from `main` is empty.

**Step 2: Request specification review**

Use @superpowers:requesting-code-review. The reviewer must compare every issue
#3 acceptance criterion and this plan against the exact branch diff and report
Critical/Important/Minor findings with commands.

**Step 3: Request code-quality and threat review**

Use a separate reviewer for Git object integrity, JSON/path bounds,
determinism, external dependency extraction, side effects, diagnostics, and CI
semantics. Do not ask either reviewer to modify files.

**Step 4: Resolve findings with isolated RED→GREEN commits**

For each accepted finding, use @superpowers:receiving-code-review and
@superpowers:test-driven-development. Re-run the focused reproducer, implement
the minimum, run focused and full verification, commit with DCO, and return the
same reviewer to the new HEAD.

**Step 5: Prepare the GitHub handoff**

After both reviewers report zero Critical/Important and fresh verification is
green, push `agent/macwin-asset-inventory`, open a draft PR tracking issue #3,
and require repository-contract plus existing macOS jobs to pass before merge.
Do not auto-close issue #3 until the merged main commit and inventory evidence
are recorded.

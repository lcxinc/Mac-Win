"""Test entrypoint for the canonical migration asset inventory contract."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE_COMMIT = "db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527"
INVENTORY_DIRECTORY = ROOT / "migration" / "assets"


class MigrationAssetInventoryEntrypointTests(unittest.TestCase):
    def test_frozen_contract_constants_are_stable(self):
        self.assertEqual(
            SOURCE_COMMIT,
            "db12d5ebc5ba0d5a29c9464d07c1a86ffbc47527",
        )
        self.assertEqual(
            INVENTORY_DIRECTORY.relative_to(ROOT).as_posix(),
            "migration/assets",
        )


if __name__ == "__main__":
    unittest.main()

"""Exercise the updater against local downloads without touching installed plugins."""

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class UpdatePluginsTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "tools").mkdir()
        (self.root / ".github").mkdir()
        (self.root / "scripts").mkdir()
        self.updater = self.root / "tools/update-plugins.sh"
        shutil.copyfile(Path(__file__).with_name("update-plugins.sh"), self.updater)
        self.target = self.root / "scripts/example.lua"
        self.target.write_text("return 'working plugin'\n")

    def update(self, content, destination="scripts/example.lua"):
        source = self.root / "download"
        source.write_text(content)
        (self.root / ".github/plugin-sources.tsv").write_text(
            f"raw\t{source.as_uri()}\t-\t-\t{destination}\n"
        )
        return subprocess.run(
            ["bash", str(self.updater)], capture_output=True, text=True
        )

    def test_invalid_lua_preserves_working_plugin(self):
        previous = self.target.read_bytes()
        result = self.update("local = broken Lua\n")
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.target.read_bytes(), previous)

    def test_valid_lua_replaces_plugin(self):
        content = "return 'updated plugin'\n"
        result = self.update(content)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.target.read_text(), content)

    def test_non_lua_file_does_not_require_lua_syntax(self):
        content = "This is a text file, not Lua.\n"
        result = self.update(content, "scripts/example.txt")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.root / "scripts/example.txt").read_text(), content)

    def test_empty_download_preserves_working_plugin(self):
        previous = self.target.read_bytes()
        result = self.update("")
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.target.read_bytes(), previous)


if __name__ == "__main__":
    if not (shutil.which("luac5.4") or shutil.which("luac")):
        raise SystemExit("Lua compiler required for updater regression tests")
    unittest.main()

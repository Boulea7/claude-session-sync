"""Run the real installer with isolated settings and a private snippet copy.

Run with python3 tests/test_install.py. Set SESSION_SYNC_TEST_POWERSHELL to
the PowerShell executable to exercise install.ps1 instead of install.sh.
"""

import copy
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.root = Path(self.temp_dir.name)
        self.hook_dir = self.root / "hook"
        shutil.copytree(Path(__file__).resolve().parents[1] / "hook", self.hook_dir)
        self.home = self.root / "home"
        self.claude_dir = self.home / ".claude"
        self.claude_dir.mkdir(parents=True)
        self.settings_path = self.claude_dir / "settings.json"
        self.snippet_path = self.hook_dir / "settings.snippet.json"
        self.snippet = json.loads(self.snippet_path.read_text(encoding="utf-8"))

    def write_settings(self, settings):
        self.settings_path.write_text(json.dumps(settings), encoding="utf-8")

    def run_installer(self, success=True):
        env = os.environ.copy()
        env.update(HOME=str(self.home), USERPROFILE=str(self.home))
        env["CLAUDE_CODE_GIT_BASH_PATH"] = shutil.which("bash") or "bash"
        powershell = env.get("SESSION_SYNC_TEST_POWERSHELL")
        if powershell:
            command = [powershell, "-NoLogo", "-NoProfile", "-NonInteractive",
                       "-File", str(self.hook_dir / "install.ps1")]
        else:
            command = ["bash", str(self.hook_dir / "install.sh")]
        result = subprocess.run(command, cwd=self.root, env=env, capture_output=True,
                                text=True, timeout=30)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def read_settings(self):
        return json.loads(self.settings_path.read_text(encoding="utf-8-sig"))

    def test_preserves_neighbors_and_removes_old_matcher(self):
        group = self.snippet["hooks"]["PreToolUse"][0]
        handler = group["hooks"][0]
        user_hook = {"type": "command", "command": "echo user", "timeout": 42}
        groups = [
            {"matcher": "mcp__legacy__tool", "label": "old group",
             "hooks": [dict(reversed(list(handler.items()))), user_hook]},
            {"matcher": group["matcher"], "label": "current group",
             "hooks": [user_hook, handler]},
            {"matcher": "mcp__project_only__tool", "hooks": [handler]},
        ]
        settings = {"model": "user-model", "hooks": {"PreToolUse": groups,
                    "PostToolUse": [{"hooks": [user_hook]}]}}
        self.write_settings(settings)
        expected = copy.deepcopy(settings)
        expected["hooks"]["PreToolUse"].pop()
        for old_group in expected["hooks"]["PreToolUse"]:
            old_group["hooks"] = [user_hook]
        expected["hooks"]["PreToolUse"].append(group)

        self.run_installer()

        self.assertTrue(self.read_settings() == expected,
                        "Remove identical handlers across matchers while preserving "
                        "neighboring user handlers, group fields, and unrelated settings")

    def test_reinstall_after_matcher_change(self):
        self.write_settings({"model": "user-model"})
        self.run_installer()
        self.snippet["hooks"]["PreToolUse"][0]["matcher"] += "|mcp__other__tool"
        self.snippet_path.write_text(json.dumps(self.snippet), encoding="utf-8")
        sessions_path = self.claude_dir / "sessions.json"
        sessions_path.write_text('{"tasks":{"existing":{}}}', encoding="utf-8")
        sessions_before = sessions_path.read_bytes()
        expected = {"model": "user-model", "hooks": self.snippet["hooks"]}

        self.run_installer()
        self.run_installer()

        self.assertEqual(self.read_settings(), expected)
        self.assertEqual(sessions_path.read_bytes(), sessions_before)

    def test_preserves_similar_handlers_and_nested_settings(self):
        group = self.snippet["hooks"]["PreToolUse"][0]
        handler = group["hooks"][0]
        variants = [dict(handler, timeout=3001),
                    dict(handler, timeout="3000"),
                    dict(handler, timeout=True),
                    dict(handler, timeout=None),
                    dict(handler, extra={"timestamp": "2026-03-12T10:00:00Z"}),
                    dict(handler, command=handler["command"].upper()),
                    dict(handler, type="COMMAND")]
        renamed = dict(handler)
        renamed["Timeout"] = renamed.pop("timeout")
        variants.append(renamed)
        nested = {"value": "2026-03-12T10:00:00.000Z"}
        for _ in range(15):
            nested = {"child": nested}
        settings = {"custom": nested, "hooks": {"PreToolUse": [
            {"matcher": group["matcher"], "metadata": {"Name": "user"},
             "hooks": variants},
            {"hooks": [{"type": "command", "command": "echo other"}],
             "metadata": [None, False, 0, ""]},
        ], "PostToolUse": [{"hooks": [{"type": "command", "command": "echo post"}]}]}}
        self.write_settings(settings)
        original_bytes = self.settings_path.read_bytes()
        expected = copy.deepcopy(settings)
        expected["hooks"]["PreToolUse"].append(group)

        self.run_installer()

        self.assertTrue(self.read_settings() == expected,
                        "Only complete, case-sensitive handler matches may be removed; "
                        "nested settings and timestamp strings must survive unchanged")
        backups = list((self.claude_dir / "backups").glob("settings.json.*.bak"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), original_bytes)

    def test_initializes_missing_or_null_hooks(self):
        for settings in ({}, {"hooks": None}, {"hooks": {}},
                         {"hooks": {"PreToolUse": None}},
                         {"hooks": {"PreToolUse": []}}):
            with self.subTest(settings=settings):
                self.write_settings(settings)
                self.run_installer()
                self.assertEqual(self.read_settings(), self.snippet)

    def test_rejects_invalid_settings_without_replacing_file(self):
        invalid_settings = [[], None, "settings", {"hooks": []}, {"hooks": False},
                            {"hooks": {"PreToolUse": {}}},
                            {"hooks": {"PreToolUse": False}},
                            {"hooks": {"PreToolUse": [None]}},
                            {"hooks": {"PreToolUse": [{"matcher": "Bash"}]}},
                            {"hooks": {"PreToolUse": [{"hooks": None}]}},
                            {"hooks": {"PreToolUse": [{"hooks": {}}]}},
                            {"hooks": {"PreToolUse": [{"hooks": ["handler"]}]}}]
        for settings in invalid_settings:
            with self.subTest(settings=settings):
                self.write_settings(settings)
                original_bytes = self.settings_path.read_bytes()
                self.run_installer(success=False)
                self.assertEqual(self.settings_path.read_bytes(), original_bytes)
                self.assertEqual(list(self.claude_dir.glob("settings.json.*.tmp")), [])

    def test_rejects_invalid_json_without_replacing_file(self):
        for raw_json in ('{"hooks":', "", "{}\n{}"):
            with self.subTest(raw_json=raw_json):
                self.settings_path.write_text(raw_json, encoding="utf-8")
                original_bytes = self.settings_path.read_bytes()
                self.run_installer(success=False)
                self.assertEqual(self.settings_path.read_bytes(), original_bytes)

    def test_rejects_invalid_snippet_without_replacing_settings(self):
        invalid_snippets = [None, [], {}, {"hooks": []}, {"hooks": {"PreToolUse": []}},
                            {"hooks": {"PreToolUse": [{"hooks": []}]}},
                            {"hooks": {"PreToolUse": [{"hooks": [None]}]}},
                            {"hooks": {"PreToolUse": [{"hooks": {}}]}}]
        for snippet in invalid_snippets:
            with self.subTest(snippet=snippet):
                self.write_settings({"model": "user-model"})
                self.snippet_path.write_text(json.dumps(snippet), encoding="utf-8")
                original_bytes = self.settings_path.read_bytes()
                self.run_installer(success=False)
                self.assertEqual(self.settings_path.read_bytes(), original_bytes)

    def test_refuses_symlinked_settings(self):
        target = self.root / "target.json"
        target.write_text('{"model":"user-model"}', encoding="utf-8")
        try:
            self.settings_path.symlink_to(target)
        except OSError as error:
            self.skipTest(f"Symlinks unavailable: {error}")

        self.run_installer(success=False)

        self.assertTrue(self.settings_path.is_symlink())
        self.assertEqual(target.read_text(encoding="utf-8"), '{"model":"user-model"}')

    @unittest.skipIf(os.environ.get("SESSION_SYNC_TEST_POWERSHELL") or os.name == "nt",
                     "POSIX permissions apply to the Bash installer")
    def test_creates_private_files(self):
        self.claude_dir.rmdir()

        self.run_installer()

        for path in (self.claude_dir, self.claude_dir / "backups"):
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o700)
        for path in (self.settings_path, self.claude_dir / "sessions.json"):
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)


if __name__ == "__main__":
    unittest.main()

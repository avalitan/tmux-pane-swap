"""Integration checks against an isolated tmux server; no user config loaded."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SwapTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="pane-swap-")
        self.addCleanup(self.temp.cleanup)
        self.socket = str(Path(self.temp.name) / "socket")
        self.tm("-f", "/dev/null", "new-session", "-d", "-s", "test")
        self.addCleanup(lambda: self.tm("kill-server"))
        self.source = self.tm("display-message", "-p", "#{pane_id}").strip()
        self.target = self.tm("split-window", "-h", "-P", "-F", "#{pane_id}").strip()
        fzf = Path(self.temp.name) / "fzf"
        fzf.write_text('#!/bin/sh\ncat > "$ROWS"\n[ "$CANCEL" = yes ] && exit 130\nprintf "%s selected\\n" "$TARGET"\n')
        fzf.chmod(0o755)
        self.env = dict(os.environ, PATH=self.temp.name + ":" + os.environ["PATH"],
                        TARGET=self.target, CANCEL="no", ROWS=self.temp.name + "/rows")

    def tm(self, *args):
        return subprocess.check_output(["tmux", "-S", self.socket, *args], text=True)

    def position(self, pane):
        return self.tm("display-message", "-p", "-t", pane,
                       "#{window_id}:#{pane_index}").strip()

    def pick(self):
        subprocess.run([str(ROOT / "scripts/pane-swap.sh"), "pick", self.socket,
                        self.source], env=self.env, check=True)

    def test_same_window_swap(self):
        before = self.position(self.source), self.position(self.target)
        self.pick()
        self.assertEqual((self.position(self.target), self.position(self.source)), before)
        rows = Path(self.env["ROWS"]).read_text().splitlines()
        self.assertTrue(rows)
        self.assertTrue(all(row.split()[0] != self.source for row in rows))

    def test_cross_session_swap(self):
        self.target = self.tm("new-session", "-d", "-s", "other", "-P", "-F", "#{pane_id}").strip()
        self.env["TARGET"] = self.target
        before = self.position(self.source), self.position(self.target)
        self.pick()
        self.assertEqual((self.position(self.target), self.position(self.source)), before)

    def test_cancel_leaves_panes_unchanged(self):
        before = self.position(self.source), self.position(self.target)
        self.env["CANCEL"] = "yes"
        self.pick()
        self.assertEqual((self.position(self.source), self.position(self.target)), before)

    def test_entrypoint_registers_binding(self):
        env = dict(os.environ, TMUX=f"{self.socket},0,0")
        subprocess.run([str(ROOT / "pane-swap.tmux")], env=env, check=True)
        self.assertIn("pane-swap.sh", self.tm("list-keys", "-T", "prefix", "M-s"))


if __name__ == "__main__":
    unittest.main()

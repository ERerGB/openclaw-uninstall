"""Synthetic service-teardown checks; no real scheduler, manager or user state writes."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/uninstall-oneshot.sh"


class ServiceGateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="openclaw-service-gate-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.calls = self.root / "calls"
        self.env = os.environ.copy()
        self.env.update(PATH=str(self.bin) + ":/usr/bin:/bin",
                        OPENCLAW_UNINSTALL_LOG_FILE=str(self.root / "run.log"),
                        OPENCLAW_STATE_DIR=str(Path.home() / (".openclaw-fixture-" + self.root.name)))
        self.env.pop("OPENCLAW_PROFILE", None)
        self.env["FIXTURE_CALLS"] = str(self.calls)
        self.stub("uname", "echo Linux")
        self.stub("rm", 'echo "rm $*" >> "$FIXTURE_CALLS"; exit 0')
        self.stub("npm", 'echo "npm $*" >> "$FIXTURE_CALLS"; exit 1')
        self.stub("pnpm", "exit 1")
        self.stub("bun", "exit 1")
        self.stub("systemctl", 'echo "systemctl $*" >> "$FIXTURE_CALLS"; exit 90')
        self.stub("launchctl", 'echo "launchctl $*" >> "$FIXTURE_CALLS"; exit 90')

    def stub(self, name, body):
        p = self.bin / name
        p.write_text("#!/bin/bash\n" + body + "\n")
        p.chmod(0o755)

    def run_full(self):
        return subprocess.run(["/bin/bash", str(SCRIPT), "--no-backup", "--preserve-state"],
                              env=self.env, text=True, capture_output=True, timeout=10)

    def calls_text(self):
        return self.calls.read_text() if self.calls.exists() else ""

    def native_gate(self):
        # Execute the real native gate block alone: no later state/CLI/app deletion.
        # The synthetic state string is never opened and HOME is never reassigned.
        text = SCRIPT.read_text()
        block = text[text.index("# 1. Service teardown"):text.index("# 3. Delete state")]
        code = 'log() { echo "$*"; }; ALL_PROFILES=false; STATE_DIR_CANON="$HOME/.openclaw"\n' + block + '\necho GATE_PASSED\n'
        # No openclaw stub in these cases; fail rather than accidentally invoking a host install.
        self.assertFalse((self.bin / "openclaw").exists())
        probe = subprocess.run(["/bin/bash", "-c", "command -v openclaw"], env=self.env, capture_output=True)
        self.assertNotEqual(probe.returncode, 0, "native fixture PATH contains a real CLI")
        return subprocess.run(["/bin/bash", "-c", code], env=self.env, text=True, capture_output=True, timeout=10)

    def test_cli_stop_failure_prevents_uninstall_and_other_removal(self):
        self.stub("openclaw", 'echo "openclaw $*" >> "$FIXTURE_CALLS"; exit 7')
        r = self.run_full()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("gateway stop failed", r.stdout)
        self.assertEqual(self.calls_text().splitlines(), ["openclaw gateway stop"])
        self.assertNotIn("Uninstall complete", r.stdout)

    def test_cli_uninstall_failure_prevents_other_removal(self):
        self.stub("openclaw", 'echo "openclaw $*" >> "$FIXTURE_CALLS"; [[ "$*" == "gateway stop" ]]')
        r = self.run_full()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("gateway uninstall failed", r.stdout)
        self.assertEqual(self.calls_text().splitlines(), ["openclaw gateway stop", "openclaw gateway uninstall"])

    def test_cli_success_does_not_run_native_fallback_and_preserves_state(self):
        self.stub("openclaw", 'echo "openclaw $*" >> "$FIXTURE_CALLS"; exit 0')
        r = self.run_full()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        calls = self.calls_text()
        self.assertIn("openclaw gateway uninstall", calls)
        self.assertNotIn("systemctl", calls)
        self.assertNotIn("rm ", calls)

    def test_native_manager_unavailable_is_not_absence(self):
        r = self.native_gate()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("systemd user manager unavailable", r.stdout)
        self.assertNotIn("rm ", self.calls_text())
        self.assertNotIn("GATE_PASSED", r.stdout)

    def test_native_loaded_service_requires_verified_inactive_state(self):
        self.stub("systemctl", '''echo "systemctl $*" >> "$FIXTURE_CALLS"
case "$*" in
 *LoadState*) echo loaded;;
 *ActiveState*) echo "${FIXTURE_ACTIVE:-active}";;
 *) exit 0;;
esac''')
        r = self.native_gate()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertNotIn("rm ", self.calls_text())
        self.env["FIXTURE_ACTIVE"] = "inactive"
        r = self.native_gate()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("GATE_PASSED", r.stdout)
        self.assertIn("disable --now openclaw-gateway.service", self.calls_text())
        self.assertIn("daemon-reload", self.calls_text())

    def test_launchd_failed_bootout_does_not_remove_definition(self):
        self.stub("uname", "echo Darwin")
        self.stub("launchctl", 'echo "launchctl $*" >> "$FIXTURE_CALLS"; [[ "$1" == print ]]')
        r = self.native_gate()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("launchd bootout failed", r.stdout)
        self.assertNotIn("rm ", self.calls_text())


if __name__ == "__main__":
    unittest.main(verbosity=2)

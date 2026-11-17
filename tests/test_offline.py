"""Offline install/argument/backup tests; never run a live uninstall or scheduler."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class OfflineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="uninstall-fixture-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.env = os.environ.copy()
        self.env["PATH"] = str(self.bin) + os.pathsep + self.env["PATH"]
        self.env["OPENCLAW_UNINSTALL_LOG_FILE"] = str(self.root / "uninstall.log")
        # The validator accepts this nonexistent user-owned path; no directory is created.
        self.state = Path.home() / (".openclaw-fixture-" + self.root.name)
        self.env["OPENCLAW_STATE_DIR"] = str(self.state)

    def stub(self, name, body):
        p = self.bin / name
        p.write_text("#!/usr/bin/env bash\n" + body)
        p.chmod(0o755)
        return p

    def run_script(self, name, *args, check=False):
        return subprocess.run(["bash", str(ROOT / "scripts" / name), *map(str, args)],
                              env=self.env, capture_output=True, text=True, timeout=10, check=check)

    def test_unknown_or_missing_options_are_rejected_without_effects(self):
        for script in ("schedule-uninstall.sh", "uninstall-oneshot.sh"):
            for args in (("--dry-run", "--preserve", "all"), ("--dry-run", "--notify-im"),
                         ("--dry-run", "--notify-im", "--no-backup"),
                         ("--dry-run", "--preserve-state", "--all-profiles")):
                with self.subTest(script=script, args=args):
                    self.assertEqual(self.run_script(script, *args).returncode, 2)
        self.assertFalse(self.state.exists())
        self.assertFalse((self.root / "uninstall.log").exists())

    def test_dry_run_validates_without_writing_state(self):
        r = self.run_script("uninstall-oneshot.sh", "--dry-run", "--preserve-state")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("Would preserve", r.stdout)
        self.assertFalse(self.state.exists())
        self.env["OPENCLAW_STATE_DIR"] = str(self.root / ".openclaw")
        self.assertNotEqual(self.run_script("uninstall-oneshot.sh", "--dry-run").returncode, 0)

    def test_scheduler_preserves_literal_arguments_in_all_shell_commands(self):
        copied = self.root / "scripts"
        copied.mkdir()
        shutil.copy2(ROOT / "scripts/schedule-uninstall.sh", copied)
        observed = self.root / "observed.json"
        fake = copied / "uninstall-oneshot.sh"
        fake.write_text("#!" + sys.executable + "\nimport json,sys\nfrom pathlib import Path\n"
                        + "Path(" + repr(str(observed)) + ").write_text(json.dumps(sys.argv[1:]))\n")
        fake.chmod(0o755)
        self.stub("sleep", "exit 0\n")
        marker = self.root / "must-not-exist"
        value = "discord:user:'; touch " + str(marker) + "; # $HOME `id`"
        r = subprocess.run(["bash", str(copied / "schedule-uninstall.sh"), "--dry-run", "--notify-im", value],
                           env=self.env, capture_output=True, text=True, timeout=10, check=True)
        command = r.stdout.strip().removeprefix("DRY_RUN_CMD: ")
        subprocess.run(["bash", "-c", command], env=self.env, capture_output=True, timeout=10, check=True)
        self.assertEqual(json.loads(observed.read_text()), ["--notify-im", value])
        self.assertFalse(marker.exists())

    def test_install_does_not_star_unless_explicit(self):
        calls = self.root / "calls"
        self.stub("clawhub", 'printf "%s\\n" "$*" >> ' + repr(str(calls)) + '\n')
        self.run_script("install.sh", self.root, check=True)
        self.assertEqual(calls.read_text().splitlines(), ["install uninstaller --workdir " + str(self.root)])
        calls.unlink()
        self.run_script("install.sh", "--star", self.root, check=True)
        self.assertEqual(calls.read_text().splitlines()[0], "star uninstaller --yes")

    def test_personal_install_preserves_previous_backups_and_repairs_dead_links(self):
        skills = self.root / "skills"
        original = skills / "uninstaller"
        original.mkdir(parents=True)
        (original / "private.txt").write_text("synthetic local configuration")
        prior = skills / "uninstaller.bak"
        prior.mkdir()
        (prior / "old.txt").write_text("old synthetic backup")
        self.env["CURSOR_SKILLS"] = str(skills)
        self.run_script("install-personal.sh", check=True)
        self.assertTrue(original.is_symlink())
        self.assertEqual((prior / "old.txt").read_text(), "old synthetic backup")
        retained = list(skills.glob("uninstaller.bak.*/private.txt"))
        self.assertEqual(len(retained), 1)
        self.assertEqual(retained[0].read_text(), "synthetic local configuration")
        original.unlink()
        original.symlink_to(self.root / "missing")
        self.run_script("install-personal.sh", check=True)
        self.assertEqual(original.resolve(), ROOT)

    def test_residue_process_check_distinguishes_checker_from_gateway(self):
        self.stub("uname", "echo FixtureOS\n")
        self.stub("npm", "exit 1\n")
        self.stub("pgrep", 'pattern="${@: -1}"; [[ "$FIXTURE_PROCESS" =~ $pattern ]]\n')
        self.env["FIXTURE_PROCESS"] = "/fixture/openclaw-uninstall/scripts/verify-clean.sh"
        checked = self.run_script("verify-clean.sh")
        self.assertIn("[OK] No openclaw process", checked.stdout)
        self.env["FIXTURE_PROCESS"] = "/usr/local/bin/openclaw gateway run"
        active = self.run_script("verify-clean.sh")
        self.assertIn("[RESIDUE] Running openclaw process", active.stdout)
        self.assertEqual(active.returncode, 1)

    def backup_fixture(self):
        source = self.root / "state"
        source.mkdir()
        (source / "openclaw.json").write_text('{"synthetic":true}')
        return source, self.root / "backup"

    def test_manual_backup_failure_is_reported_and_source_survives(self):
        source, dest = self.backup_fixture()
        self.stub("openclaw", "exit 1\n")
        self.stub("cp", "exit 1\n")
        r = self.run_script("backup-state.sh", source, dest)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual((source / "openclaw.json").read_text(), '{"synthetic":true}')
        self.assertIn("Manual backup failed", r.stderr)

    def test_manual_backup_copies_selected_data_privately(self):
        source, dest = self.backup_fixture()
        self.stub("openclaw", "exit 1\n")
        r = self.run_script("backup-state.sh", source, dest)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual((dest / "openclaw.json").read_bytes(), (source / "openclaw.json").read_bytes())
        self.assertEqual(dest.stat().st_mode & 0o077, 0)
        self.assertNotEqual(self.run_script("backup-state.sh", source, dest).returncode, 0)

    def test_native_success_without_archive_is_not_successful_backup(self):
        source, dest = self.backup_fixture()
        self.stub("openclaw", "exit 0\n")
        r = self.run_script("backup-state.sh", source, dest)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("no nonempty archive", r.stderr)
        self.assertTrue((source / "openclaw.json").exists())

if __name__ == "__main__":
    unittest.main(verbosity=2)

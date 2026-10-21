"""Run real child processes through the observer's stall and cancellation boundaries."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest


OBSERVER = Path(__file__).resolve().parents[1] / "ci_ui_observer.py"
LAUNCH = "    t =     0.01s     Launch com.michaelju.glasstable"


class UIObserverTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.device = self.root / "SELECTED-SIM"
        self.diagnostics = self.root / "diagnostics"
        self.log = self.root / "ui-tests.log"
        self.sampler = self.script("sampler", """
import os, pathlib, sys
pathlib.Path(sys.argv[-1]).write_text('sampled pid=' + sys.argv[1])
""")

    def script(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"#!{sys.executable}\n" + body)
        path.chmod(0o755)
        return path

    def command(self, body, extra=()):
        child = self.script("original-command.py", body)
        return [sys.executable, str(OBSERVER), "--simulator", "SELECTED-SIM",
                "--device-path", str(self.device), "--log", str(self.log),
                "--diagnostics", str(self.diagnostics), "--sampler", str(self.sampler),
                "--launch-seconds", "0.18", "--second-checkpoint", "0.48",
                "--helper-timeout", "0.35", "--cancel-grace", "0.15",
                "--inventory-seconds", "0.05", "--poll-seconds", "0.01",
                *extra, "--", sys.executable, str(child)]

    def events(self):
        path = self.diagnostics / "timeline.jsonl"
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def run_command(self, body, extra=()):
        return subprocess.run(self.command(body, extra), capture_output=True, text=True, timeout=8)

    def external_runner(self, device=None, duration=5):
        device = device or self.device
        relative = device.relative_to(self.root) / "data/Containers/Bundle/Application/fixture/GlassTableUITests-Runner.app/GlassTableUITests-Runner"
        script = self.script(str(relative), f"import time\ntime.sleep({duration})\n")
        process = subprocess.Popen([str(script)], start_new_session=True)
        self.addCleanup(self.stop, process)
        return process

    @staticmethod
    def stop(process):
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGKILL)
        process.wait(timeout=2)

    def wait_for(self, condition, timeout=3):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            if condition():
                return
            time.sleep(0.01)
        self.fail("controlled subprocess did not reach the expected boundary")

    def child_wait_for(self, expression):
        return ("\nimport pathlib, time\nend = time.monotonic() + 4\n"
                f"while not ({expression}) and time.monotonic() < end: time.sleep(0.01)\n"
                f"assert {expression}, 'fixture handshake did not complete'\n")

    def wait_event(self, name, count=1):
        expression = (f"pathlib.Path({str(self.diagnostics / 'timeline.jsonl')!r}).read_text()"
                      f".count({json.dumps(chr(34) + 'event' + chr(34) + ': ' + chr(34) + name + chr(34))}) >= {count}")
        return self.child_wait_for(expression)

    def assert_not_running(self, pid):
        def stopped():
            result = subprocess.run(["/bin/ps", "-p", str(pid), "-o", "stat="], capture_output=True, text=True)
            return not result.stdout.strip() or result.stdout.strip().startswith("Z")
        self.wait_for(stopped)

    def blocking_sampler(self):
        self.sampler = self.script("blocking-sampler", f"""
import json, os, pathlib, signal, subprocess, sys, time
signal.signal(signal.SIGTERM, signal.SIG_IGN)
child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'])
pathlib.Path({str(self.root / 'sample-pids.json')!r}).write_text(json.dumps([os.getpid(), child.pid]))
time.sleep(60)
""")

    def test_normal_completion_preserves_original_output_and_zero(self):
        result = self.run_command("import sys\nprint('original stdout', flush=True)\nprint('original stderr', file=sys.stderr, flush=True)\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_bytes(), b"original stdout\noriginal stderr\n")
        self.assertFalse(any(e["event"] == "capture" for e in self.events()))

    def test_nonzero_exit_survives_unavailable_diagnostics(self):
        self.diagnostics.write_text("cannot create a directory here")
        result = self.run_command("import sys\nprint('original failure')\nsys.exit(37)\n")
        self.assertEqual(result.returncode, 37)
        self.assertIn("diagnostics unavailable", result.stderr)
        self.assertEqual(self.log.read_text(), "original failure\n")

    def test_pending_launch_samples_owned_host_before_app_exists_despite_warnings(self):
        result = self.run_command(f"""
import sys, time
print({LAUNCH!r}, flush=True)
for line in ['    t =     0.02s Setting up automation session',
             '    t =     0.03s Wait for com.michaelju.glasstable to idle']:
    print(line, flush=True)
    time.sleep(0.09)
for _ in range(10):
    print('unrelated Xcode warning', flush=True)
    time.sleep(0.035)
""" + self.wait_event("sample_start") + "sys.exit(23)\n")
        self.assertEqual(result.returncode, 23, result.stderr)
        events = self.events()
        captures = [e for e in events if e["event"] == "capture"]
        self.assertEqual([e["reason"] for e in captures], ["pending-launch"])
        host = next(e for e in events if e["event"] == "command_start")["pid"]
        samples = [e for e in events if e["event"] == "sample_start"]
        self.assertEqual([(e["role"], e["identity"]["pid"]) for e in samples], [("host", host)])
        self.assertGreaterEqual(captures[0]["trigger_elapsed"], 0.18)
        self.assertIn("observed_at", captures[0])
        self.assertIn("offset", captures[0])

    def test_postlaunch_control_query_ends_pending_launch(self):
        result = self.run_command(f"""
import time
print({LAUNCH!r}, flush=True)
print('    t =     0.04s Waiting 15.0s for "answer" Button to exist', flush=True)
time.sleep(0.35)
""")
        self.assertEqual(result.returncode, 0, result.stderr + self.log.read_text())
        self.assertFalse(any(e["event"] == "capture" for e in self.events()))
        self.assertTrue(any(e["event"] == "launch_boundary" for e in self.events()))

    def test_silent_selected_runner_two_checkpoints_reserve_explicit_budget(self):
        runner = self.external_runner()
        body = self.wait_event("capture", 2)
        for number in range(2):
            body += f"print(\"Test Case 'controlled' started.\", flush=True)\nprint({LAUNCH!r}, flush=True)\n"
            body += self.wait_event("capture", number + 3)
            body += "print(\"Test Case 'controlled' passed.\", flush=True)\n"
        body += self.child_wait_for(f"any(e['event']=='sample_start' and e.get('role')=='runner' for e in __import__('json').loads('[' + ','.join(pathlib.Path({str(self.diagnostics / 'timeline.jsonl')!r}).read_text().splitlines()) + ']'))")
        result = self.run_command(body)
        self.assertEqual(result.returncode, 0, result.stderr)
        captures = [e for e in self.events() if e["event"] == "capture"]
        self.assertEqual([e["reason"] for e in captures],
                         ["runner-no-progress", "runner-no-progress", "pending-launch", "pending-launch"])
        self.assertIsNone(runner.poll(), "observed runner is not an owned cancellation target")
        roles = {e["role"] for e in self.events() if e["event"] == "sample_start"}
        self.assertEqual(roles, {"host", "runner"})

    def test_progress_resumption_cancels_second_fallback_checkpoint(self):
        self.external_runner()
        result = self.run_command(self.wait_event("capture") +
            "print(\"Test Case 'resumed' started.\", flush=True)\ntime.sleep(0.55)\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len([e for e in self.events() if e["event"] == "capture"]), 1)

    def test_unrelated_simulator_never_arms_or_is_sampled(self):
        runner = self.external_runner(self.root / "OTHER-SIM")
        result = self.run_command("import time\ntime.sleep(0.65)\n")
        self.assertEqual(result.returncode, 0)
        self.assertFalse(any(e["event"] == "capture" for e in self.events()))
        self.assertIsNone(runner.poll())

    def test_runner_disappearance_cancels_second_checkpoint(self):
        runner = self.external_runner()
        result = self.run_command(self.wait_event("capture") +
            f"import os,signal\nos.kill({runner.pid}, signal.SIGTERM)\n" +
            self.wait_event("runner_no_progress_cancelled"))
        runner.wait(timeout=1)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len([e for e in self.events() if e["event"] == "capture"]), 1)
        self.assertTrue(any(e["event"] == "runner_no_progress_cancelled" for e in self.events()))

    def test_sample_failure_cannot_replace_test_failure(self):
        self.sampler = self.script("bad-sampler", "import sys\nsys.exit(19)\n")
        expression = f"'sample_finish' in pathlib.Path({str(self.diagnostics / 'timeline.jsonl')!r}).read_text()"
        result = self.run_command(f"import sys\nprint({LAUNCH!r}, flush=True)\n" +
                                  self.child_wait_for(expression) + "sys.exit(31)\n")
        self.assertEqual(result.returncode, 31)
        self.assertTrue(any(e["event"] == "sample_finish" and e["returncode"] == 19 for e in self.events()))

    def test_sample_timeout_reaps_only_its_created_group(self):
        self.blocking_sampler()
        unrelated = self.external_runner(self.root / "OTHER-SIM")
        result = self.run_command(f"print({LAUNCH!r}, flush=True)\n" + self.wait_event("sample_finish"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(any(e["event"] == "sample_finish" and e["timed_out"] for e in self.events()))
        for pid in json.loads((self.root / "sample-pids.json").read_text()):
            self.assert_not_running(pid)
        self.assertIsNone(unrelated.poll())

    def test_original_exit_during_sampling_cleans_sampler_and_preserves_code(self):
        self.blocking_sampler()
        expression = f"pathlib.Path({str(self.root / 'sample-pids.json')!r}).exists()"
        result = self.run_command(f"import sys\nprint({LAUNCH!r}, flush=True)\n" +
                                  self.child_wait_for(expression) + "sys.exit(41)\n")
        self.assertEqual(result.returncode, 41, result.stderr)
        for pid in json.loads((self.root / "sample-pids.json").read_text()):
            self.assert_not_running(pid)

    def test_observer_exception_cleans_active_sampler_and_keeps_command_result(self):
        self.blocking_sampler()
        original = self.command(f"import sys\nprint({LAUNCH!r}, flush=True)\n" +
                                self.wait_event("observer_error") + "sys.exit(43)\n")
        launcher = self.script("observer-fault.py", f"""
import sys
sys.path.insert(0, {str(OBSERVER.parent)!r})
import ci_ui_observer as observer
original = observer.Observer.poll_helpers
def fail_during_sample(self):
    original(self)
    if __import__('pathlib').Path({str(self.root / 'sample-pids.json')!r}).exists():
        raise RuntimeError('controlled observer exception')
observer.Observer.poll_helpers = fail_during_sample
sys.exit(observer.main(sys.argv[1:]))
""")
        original[1] = str(launcher)
        result = subprocess.run(original, capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 43, result.stderr)
        self.assertIn("controlled observer exception", result.stderr)
        self.assertTrue(any(e["event"] == "observer_error" for e in self.events()))
        for pid in json.loads((self.root / "sample-pids.json").read_text()):
            self.assert_not_running(pid)

    def test_cancellation_interrupts_blocked_sample_and_owned_command_group(self):
        self.blocking_sampler()
        unrelated = self.external_runner(self.root / "OTHER-SIM")
        command = self.command(f"""
import json, os, pathlib, signal, subprocess, sys, time
signal.signal(signal.SIGTERM, signal.SIG_IGN)
child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'])
pathlib.Path({str(self.root / 'original-pids.json')!r}).write_text(json.dumps([os.getpid(), child.pid]))
print({LAUNCH!r}, flush=True)
time.sleep(60)
""")
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.addCleanup(lambda: process.poll() is None and process.kill())
        self.wait_for(lambda: (self.root / "sample-pids.json").exists())
        process.send_signal(signal.SIGTERM)
        _, stderr = process.communicate(timeout=3)
        self.assertEqual(process.returncode, 143, stderr)
        self.assertTrue(any(e["event"] == "cancel" for e in self.events()))
        for name in ("sample-pids.json", "original-pids.json"):
            for pid in json.loads((self.root / name).read_text()):
                self.assert_not_running(pid)
        self.assertIsNone(unrelated.poll())

    def test_completed_sampler_leader_cannot_leave_a_descendant_behind(self):
        self.sampler = self.script("exiting-sampler", f"""
import json, os, pathlib, subprocess, sys
child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'])
pathlib.Path({str(self.root / 'sample-pids.json')!r}).write_text(json.dumps([os.getpid(), child.pid]))
""")
        expression = f"'sample_finish' in pathlib.Path({str(self.diagnostics / 'timeline.jsonl')!r}).read_text()"
        result = self.run_command(f"print({LAUNCH!r}, flush=True)\n" + self.child_wait_for(expression))
        self.assertEqual(result.returncode, 0, result.stderr)
        for pid in json.loads((self.root / "sample-pids.json").read_text()):
            self.assert_not_running(pid)

    def test_long_unterminated_output_is_bounded_without_changing_log_or_offsets(self):
        timeline = str(self.diagnostics / "timeline.jsonl")
        partial_seen = f"'log_line_truncated' in pathlib.Path({timeline!r}).read_text()"
        sample_done = f"'sample_finish' in pathlib.Path({timeline!r}).read_text()"
        result = self.run_command("import sys\nsys.stdout.write('x' * 32768)\nsys.stdout.flush()\n" +
            self.child_wait_for(partial_seen) + f"print()\nprint({LAUNCH!r}, flush=True)\n" +
            self.child_wait_for(sample_done))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_bytes(), b"x" * 32768 + b"\n" + LAUNCH.encode() + b"\n")
        launch = next(e for e in self.events() if e["event"] == "launch_observed")
        self.assertEqual(launch["offset"], 32769)
        self.assertTrue(any(e["event"] == "log_line_truncated" and e["retained_bytes"] == 16384
                            for e in self.events()))


if __name__ == "__main__":
    unittest.main()

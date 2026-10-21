"""Run real child processes through the observer's stall and cancellation boundaries."""
import io
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from types import SimpleNamespace
from unittest.mock import Mock, patch


OBSERVER = Path(__file__).resolve().parents[1] / "ci_ui_observer.py"
sys.path.insert(0, str(OBSERVER.parent))
import ci_ui_observer as observer

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

    def blocking_sampler(self, oversized=False):
        self.sampler = self.script("blocking-sampler", f"""
import json, os, pathlib, signal, subprocess, sys, time
signal.signal(signal.SIGTERM, signal.SIG_IGN)
child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'])
if {oversized!r}:
    pathlib.Path(sys.argv[-1]).write_bytes(b'x' * (2 * 1024 * 1024 + 4096))
pathlib.Path({str(self.root / 'sample-pids.json')!r}).write_text(json.dumps([os.getpid(), child.pid]))
time.sleep(60)
""")

    def run_instrumented(self, body, instrumentation, extra=()):
        command = self.command(body, extra)
        launcher = self.script("instrumented-observer.py", f"""
import sys
sys.path.insert(0, {str(OBSERVER.parent)!r})
import ci_ui_observer as observer
{instrumentation}
sys.exit(observer.main(sys.argv[1:]))
""")
        command[1] = str(launcher)
        return subprocess.run(command, capture_output=True, text=True, timeout=8)

    def test_slow_global_inventory_retries_once_but_host_sample_survives(self):
        slow = self.script("slow-inventory", "import time\ntime.sleep(2)\n")
        body = f"print({LAUNCH!r}, flush=True)\n" + self.wait_event("capture_inventory_failed") + "import sys\nsys.exit(29)\n"
        result = self.run_instrumented(body, f"""
original_helper = observer.Observer.helper
def slow_inventory(self, command, kind, timeout, context=None):
    if kind == 'inventory':
        command = [{str(slow)!r}]
    return original_helper(self, command, kind, timeout, context)
observer.Observer.helper = slow_inventory
""", extra=("--control-timeout", "0.15"))
        self.assertEqual(result.returncode, 29, result.stderr)
        events = self.events()
        self.assertEqual(len([e for e in events if e['event'] == 'capture_inventory_retry']), 1)
        self.assertEqual(len([e for e in events if e['event'] == 'capture_inventory_failed']), 1)
        self.assertLessEqual(len([e for e in events if e['event'] == 'helper_failure' and e['helper_kind'] == 'inventory']), 3)
        sample = next(e for e in events if e['event'] == 'sample_finish')
        self.assertEqual(sample['role'], 'host')
        self.assertTrue(sample['usable'])
        self.assertGreater(sample['retained_bytes'], 0)

    def test_sampler_delayed_file_output_gets_distinct_completion_budget(self):
        self.sampler = self.script("delayed-sampler", """
import pathlib, sys, time
assert sys.argv[2] == '2', 'sampling duration must remain two seconds'
print('Sampling process ' + sys.argv[1] + ' for 2 seconds', flush=True)
time.sleep(5.2)
pathlib.Path(sys.argv[-1]).write_text('symbolicated stack after delayed output')
""")
        body = (f"print({LAUNCH!r}, flush=True)\n" + self.wait_event("sample_finish")).replace(
            "end = time.monotonic() + 4", "end = time.monotonic() + 7")
        command = self.command(body)
        index = command.index("--helper-timeout")
        del command[index:index + 2]  # Exercise the production completion deadline.
        result = subprocess.run(command, capture_output=True, text=True, timeout=8)
        self.assertEqual(result.returncode, 0, result.stderr)
        sample = next(e for e in self.events() if e['event'] == 'sample_finish')
        self.assertGreater(sample['retained_bytes'] or 0, 0)
        self.assertTrue(sample['usable'])
        self.assertFalse(sample['timed_out'])
        self.assertGreaterEqual(sample['duration'], 5.2)

    def test_sample_bytes_and_nonzero_status_are_both_retained(self):
        self.sampler = self.script("oversized-failing-sampler", """
import pathlib, sys
pathlib.Path(sys.argv[-1]).write_bytes(b'x' * (2 * 1024 * 1024 + 4096))
sys.exit(19)
""")
        result = self.run_command(f"print({LAUNCH!r}, flush=True)\n" + self.wait_event("sample_finish") + "import sys\nsys.exit(31)\n")
        self.assertEqual(result.returncode, 31, result.stderr)
        sample = next(e for e in self.events() if e['event'] == 'sample_finish')
        self.assertEqual(sample['returncode'], 19)
        self.assertEqual(sample['retained_bytes'], 2 * 1024 * 1024)
        self.assertFalse(sample['usable'])
        self.assertFalse(sample['output_missing'])
        self.assert_capped_sample()

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
            self.wait_event("runner_no_progress_cancelled"), extra=("--second-checkpoint", "2"))
        runner.wait(timeout=1)
        self.assertEqual(result.returncode, 0, result.stderr + self.log.read_text() + repr(self.events()))
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
        self.exit_during_sample()

    def test_original_exit_caps_interrupted_oversized_sample(self):
        self.exit_during_sample(oversized=True)
        self.assert_capped_sample()

    def assert_capped_sample(self):
        paths = list(self.diagnostics.rglob("*.sample.txt"))
        self.assertEqual(len(paths), 1)
        self.assertEqual(paths[0].stat().st_size, 2 * 1024 * 1024)
        with paths[0].open("rb") as handle:
            self.assertEqual(handle.read(32), b"x" * 32)

    def exit_during_sample(self, oversized=False):
        self.blocking_sampler(oversized=oversized)
        expression = f"pathlib.Path({str(self.root / 'sample-pids.json')!r}).exists()"
        result = self.run_command(f"import sys\nprint({LAUNCH!r}, flush=True)\n" +
                                  self.child_wait_for(expression) + "sys.exit(41)\n",
                                  extra=("--helper-timeout", "2") if oversized else ())
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
        self.cancel_during_sample()

    def test_cancellation_caps_interrupted_oversized_sample(self):
        self.cancel_during_sample(oversized=True)
        self.assert_capped_sample()

    def cancel_during_sample(self, oversized=False):
        self.blocking_sampler(oversized=oversized)
        unrelated = self.external_runner(self.root / "OTHER-SIM")
        command = self.command(f"""
import json, os, pathlib, signal, subprocess, sys, time
signal.signal(signal.SIGTERM, signal.SIG_IGN)
child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'])
pathlib.Path({str(self.root / 'original-pids.json')!r}).write_text(json.dumps([os.getpid(), child.pid]))
print({LAUNCH!r}, flush=True)
time.sleep(60)
""", extra=("--helper-timeout", "2") if oversized else ())
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


class ProviderCaptureTests(unittest.TestCase):
    # The short launcher execs the selected Xcode binary without changing PID/start.
    INITIAL = "2159 2158 Wed Oct 21 15:36:17 2026 xcodebuild -project GlassTable.xcodeproj"
    EXECUTED = "2159 2158 Wed Oct 21 15:36:17 2026 /Applications/Xcode_26.3.0.app/Contents/Developer/usr/bin/xcodebuild -project GlassTable.xcodeproj"

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.device = self.root / "SELECTED-SIM"
        self.observer = observer.Observer(SimpleNamespace(device_path=self.device, sampler="sample",
            sample_seconds=2, helper_timeout=30, control_timeout=5, diagnostics=str(self.root)))
        self.observer.timeline = io.StringIO()
        self.observer.child = SimpleNamespace(pid=2159, poll=lambda: None)
        self.observer.helper = Mock()
        self.observer.metadata = Mock()

    def test_provider_exec_transition_keeps_owned_host_capture(self):
        self.observer.inventory(self.INITIAL, None)
        self.observer.capture("pending-launch", time.monotonic())
        self.observer.inventory(self.EXECUTED, self.root)
        hosts = [t for t in self.observer.sample_queue if t["role"] == "host"]
        self.assertEqual(len(hosts), 1, self.observer.timeline.getvalue())
        self.observer.verify_sample(self.EXECUTED, hosts[0])
        self.assertEqual(self.observer.helper.call_args.args[1], "sample")
        self.assertIn("Xcode_26.3.0", json.loads(self.observer.timeline.getvalue().splitlines()[-1])["identity"]["command"])

    def test_capture_queues_host_before_global_inventory_returns(self):
        self.observer.capture("pending-launch", time.monotonic())
        self.assertEqual([t["role"] for t in self.observer.sample_queue], ["host"])
        self.assertEqual(self.observer.helper.call_args.args[1], "inventory")

    def test_owned_host_disappearance_or_reused_pid_never_samples(self):
        self.observer.inventory(self.INITIAL, None)
        task = dict(role="host", identity=self.observer.host_identity, directory=self.root, queued_at=time.monotonic())
        for output in ("", self.EXECUTED.replace("15:36:17", "15:36:18"),
                       self.EXECUTED.replace("2159 2158", "2159 9999")):
            with self.subTest(output=output):
                self.observer.verify_sample(output, task)
                self.observer.helper.assert_not_called()

    def test_exited_owned_host_never_samples_even_if_ps_still_reports_it(self):
        self.observer.inventory(self.INITIAL, None)
        self.observer.child.poll = lambda: 0
        self.observer.verify_sample(self.INITIAL, dict(role="host", identity=self.observer.host_identity,
            directory=self.root, queued_at=time.monotonic()))
        self.observer.helper.assert_not_called()

    def test_default_sample_completion_and_control_budgets_are_separate(self):
        with patch.object(observer, "Observer") as observer_type:
            observer_type.return_value.run.return_value = 0
            observer.main(["--simulator", "SIM", "--log", "log", "--diagnostics", "diagnostics", "--", "true"])
        args = observer_type.call_args.args[0]
        self.assertEqual((args.sample_seconds, args.helper_timeout, args.control_timeout), (2, 30, 5))

    def test_external_process_still_requires_current_executable_and_simulator_scope(self):
        command = str(self.device / "data/Containers/Bundle/Application/fixture/GlassTable.app/GlassTable")
        line = "99 88 Wed Oct 21 15:36:17 2026 " + command
        expected = observer.identities(line)[99]
        task = dict(role="app", identity=expected, directory=self.root, queued_at=time.monotonic())
        for output in ("", line.replace("15:36:17", "15:36:18"),
                       line.replace("SELECTED-SIM", "OTHER-SIM"), line + " changed-arguments"):
            with self.subTest(output=output):
                self.observer.verify_sample(output, task)
                self.observer.helper.assert_not_called()


if __name__ == "__main__":
    unittest.main()

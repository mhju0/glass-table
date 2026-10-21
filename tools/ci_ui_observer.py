#!/usr/bin/env python3
"""Observe the original UI command without changing its test or simulator policy."""
import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time


APP = "com.michaelju.glasstable"
ACTIVITY = re.compile(r"^\s*t =\s*[\d.]+s\s+(.+)")
QUERY = re.compile(r"^Waiting [\d.]+s for .+ (?:Button|StaticText|Any|Slider|TextField|TextView|Switch|Table|CollectionView)(?:\b|$)")
MAX_FILE = 2 * 1024 * 1024
MAX_LINE = 16384


def utc():
    return datetime.now(timezone.utc).isoformat()


@dataclass(frozen=True)
class Identity:
    pid: int
    parent: int
    started: str
    command: str


def identities(output):
    found = {}
    for line in output.splitlines():
        fields = line.split(None, 7)
        if len(fields) == 8 and fields[0].isdigit() and fields[1].isdigit():
            item = Identity(int(fields[0]), int(fields[1]), " ".join(fields[2:7]), fields[7])
            found[item.pid] = item
    return found


def simulator_role(identity, device_path):
    # The installed executable path, not its display name, proves simulator identity.
    prefix = str(device_path) + "/data/Containers/Bundle/Application/"
    for role, executable in (("runner", "GlassTableUITests-Runner"), ("app", "GlassTable")):
        expected = re.escape(prefix) + r"[^/\s]+/" + executable + r"\.app/" + executable + r"(?:\s|$)"
        if re.search(expected, identity.command):
            return role
    return None


class Observer:
    def __init__(self, args):
        self.args = args
        self.started = time.monotonic()
        self.wall_start = time.time()
        self.cancel_signal = None
        self.child = None
        self.helpers = []
        self.sample_queue = []
        self.pending = None
        self.explicit_rounds = 0
        self.fallback = None
        self.fallback_used = False
        self.last_progress = self.started
        self.last_inventory = 0
        self.selected = {}
        self.host_identity = None
        self.offset = 0
        self.partial = b""
        self.last_test = None
        self.observing = True
        self.rounds = 0
        self.timeline = None
        self.observed_pids = set()

    def event(self, kind, **values):
        try:
            if self.timeline is not None and self.timeline.tell() < MAX_FILE:
                self.timeline.write(json.dumps(dict(event=kind, observed_at=utc(),
                    elapsed=round(time.monotonic() - self.started, 3), **values)) + "\n")
                self.timeline.flush()
        except OSError:
            # A full artifact disk must not replace the original command's result.
            pass

    def notice(self, message):
        print("UI observer: " + message, file=sys.stderr, flush=True)

    def signal(self, number, _frame):
        self.cancel_signal = self.cancel_signal or number

    def helper(self, command, kind, timeout, context=None):
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   start_new_session=True)
        os.set_blocking(process.stdout.fileno(), False)
        self.helpers.append(dict(process=process, output=bytearray(), kind=kind,
            deadline=time.monotonic() + timeout, context=context, stopped=False))

    def kill_group(self, process, number):
        try:
            os.killpg(process.pid, number)
        except ProcessLookupError:
            pass
        except OSError as error:
            self.event("owned_group_signal_error", pid=process.pid, signal=number, error=str(error))

    def read_log(self):
        with Path(self.args.log).open("rb") as handle:
            handle.seek(self.offset)
            block = handle.read(256 * 1024)
        base = self.offset - len(self.partial)
        self.offset += len(block)
        lines = (self.partial + block).split(b"\n")
        self.partial = lines.pop()
        if len(self.partial) > MAX_LINE:
            omitted = len(self.partial) - MAX_LINE
            self.partial = self.partial[-MAX_LINE:]
            self.event("log_line_truncated", omitted_bytes=omitted, retained_bytes=MAX_LINE,
                       offset=self.offset - MAX_LINE)
        for raw in lines:
            line = raw.decode("utf-8", errors="replace")
            self.line(line, base)
            base += len(raw) + 1

    def line(self, line, offset):
        now = time.monotonic()
        activity = ACTIVITY.match(line)
        test_line = line.startswith("Test Case ")
        if activity or test_line:
            self.last_progress = now
            if self.fallback is not None:
                self.event("runner_no_progress_resumed", offset=offset, line=line[:1000])
                self.fallback = None
        if test_line:
            self.last_test = line
            self.event("test", offset=offset, line=line[:1000])
            self.pending = None
        if not activity:
            return
        text = activity.group(1)
        if text == f"Launch {APP}":
            self.pending = dict(start=now, offset=offset, origin=line, sampled=False)
            self.event("launch_observed", offset=offset, origin=line)
        elif self.pending is not None and (QUERY.match(text) or
                re.match(r"(?:Tap|Swipe|Press|Drag|Type text)\b", text) or text == "Tear Down"):
            # Setting up automation and waiting for app-idle remain inside launch.
            self.event("launch_boundary", offset=offset, origin=line)
            self.pending = None

    def snapshot(self, context=None):
        self.helper(["/bin/ps", "-axww", "-o", "pid=,ppid=,lstart=,command="], "inventory", 2, context)

    def inventory(self, output, context):
        current = identities(output)
        host = current.get(self.child.pid)
        if self.host_identity is None and host is not None:
            self.host_identity = host
            self.event("host_identity", identity=host.__dict__, owned=True)
        selected = {}
        for item in current.values():
            role = simulator_role(item, self.args.device_path)
            if role:
                selected.setdefault(role, []).append(item)
        if selected != self.selected:
            self.event("simulator_identities", processes={k: [p.__dict__ for p in v]
                for k, v in selected.items()}, owned=False)
            self.selected = selected
        self.observed_pids.update(p.pid for items in selected.values() for p in items)
        if self.fallback is not None and self.fallback["runner"] not in selected.get("runner", []):
            self.event("runner_no_progress_cancelled", reason="runner identity disappeared")
            self.fallback = None
        if "runner" in selected and not self.fallback_used and self.fallback is None:
            # Presence can precede host stdout by over a minute. This is observation,
            # not a claim that the runner has reached an application launch.
            if len(selected["runner"]) == 1:
                self.fallback = dict(start=time.monotonic(), round=0, runner=selected["runner"][0])
        if context is None:
            return
        self.event("capture_targets", round=context.name, host=host.__dict__ if host else None,
                   simulator_processes={k: [p.__dict__ for p in v] for k, v in selected.items()})
        targets = [("host", self.host_identity)]
        for role in ("runner", "app"):
            items = selected.get(role, [])
            # Ambiguous same-simulator processes are recorded but never guessed.
            if len(items) == 1:
                targets.append((role, items[0]))
        for role, expected in targets:
            if expected is None or current.get(expected.pid) != expected:
                self.event("sample_skipped", role=role, reason="identity absent or changed", round=context.name)
                continue
            self.sample_queue.append(dict(role=role, identity=expected, directory=context))

    def verify_sample(self, output, task):
        expected = task["identity"]
        if identities(output).get(expected.pid) != expected:
            self.event("sample_skipped", role=task["role"], reason="identity absent or changed",
                       round=task["directory"].name)
            return
        path = task["directory"] / f"{task['role']}-{expected.pid}.sample.txt"
        self.event("sample_start", role=task["role"], identity=expected.__dict__,
                   round=task["directory"].name, owned=(task["role"] == "host"))
        self.helper([self.args.sampler, str(expected.pid), str(self.args.sample_seconds), "10",
                     "-mayDie", "-file", str(path)], "sample", self.args.helper_timeout,
                    dict(role=task["role"], path=path, round=task["directory"].name))

    def metadata(self, directory):
        paths = []
        # No simulator data containers or environment snapshots are collected.
        roots = [Path.home() / "Library/Logs/DiagnosticReports"]
        for root in roots:
            if root.exists():
                for path in list(root.iterdir())[:500]:
                    if path.is_file() and path.name.startswith(("GlassTable", "xcodebuild", "XCTest")):
                        stat = path.stat()
                        if stat.st_mtime >= self.wall_start:
                            with path.open("rb") as handle:
                                header = handle.read(65536).decode("utf-8", errors="replace")
                            match = re.search(r'"pid"\s*:\s*(\d+)|^Process:.*\[(\d+)\]', header, re.M)
                            pid = int(next(v for v in match.groups() if v)) if match else None
                            if pid in self.observed_pids | {self.child.pid}:
                                paths.append(dict(path=str(path), pid=pid, size=stat.st_size, modified=stat.st_mtime))
        (directory / "crash-metadata.json").write_text(json.dumps(paths[:30], indent=2))
        with Path(self.args.log).open("rb") as handle:
            handle.seek(max(0, self.offset - 32768))
            (directory / "ui-tests-tail.txt").write_bytes(handle.read(32768))
        # Raw process/open-file inventories stay in memory; only attributed data survives.
        self.helper(["/usr/sbin/lsof", "-p", str(self.child.pid), "-Fn"], "sessions", 2, directory)

    def sessions(self, output, directory):
        records = []
        for line in output.splitlines():
            if not line.startswith("n"):
                continue
            path = Path(line[1:])
            if not path.name.startswith("Session-") or path.suffix != ".log":
                continue
            try:
                stat = path.stat()
                if stat.st_mtime < self.wall_start:
                    continue
                with path.open("rb") as handle:
                    handle.seek(max(0, stat.st_size - 32768))
                    (directory / f"session-{len(records)}.tail.txt").write_bytes(handle.read(32768))
                records.append(dict(path=str(path), size=stat.st_size, modified=stat.st_mtime))
            except OSError as error:
                records.append(dict(path=str(path), error=str(error)))
            if len(records) == 3:
                break
        (directory / "session-metadata.json").write_text(json.dumps(records, indent=2))

    def capture(self, reason, since, origin=None):
        self.rounds += 1
        directory = Path(self.args.diagnostics) / f"capture-{self.rounds}-{reason}"
        directory.mkdir()
        self.event("capture", reason=reason, trigger_elapsed=time.monotonic() - since,
                   offset=self.offset, current_test=self.last_test, origin=origin, round=directory.name)
        self.snapshot(directory)  # Fresh identity check before every PID sample.
        self.metadata(directory)

    def tick(self):
        self.read_log()
        now = time.monotonic()
        if now - self.last_inventory >= self.args.inventory_seconds and not any(h["kind"] == "inventory" for h in self.helpers):
            self.snapshot()
            self.last_inventory = now
        if self.pending is not None:
            if not self.pending["sampled"] and self.explicit_rounds < 2 and now - self.pending["start"] >= self.args.launch_seconds:
                self.pending["sampled"] = True
                self.explicit_rounds += 1
                self.capture("pending-launch", self.pending["start"], self.pending["origin"])
        elif self.fallback is not None:
            threshold = (self.args.launch_seconds, self.args.second_checkpoint)[self.fallback["round"]]
            if now - self.fallback["start"] >= threshold:
                self.capture("runner-no-progress", self.fallback["start"])
                self.fallback["round"] += 1
                self.fallback_used = True
                if self.fallback["round"] == 2:
                    self.fallback = None

    def poll_helpers(self):
        for helper in list(self.helpers):
            process = helper["process"]
            try:
                block = os.read(process.stdout.fileno(), 256 * 1024)
                helper["output"].extend(block)
            except BlockingIOError:
                pass
            expired = time.monotonic() >= helper["deadline"] or len(helper["output"]) >= MAX_FILE
            if expired and process.poll() is None:
                self.kill_group(process, signal.SIGKILL)
                helper["stopped"] = True
            code = process.poll()
            if code is None:
                continue
            # A completed helper leader can leave a descendant holding stdout open.
            # This process group was created by us, unlike any observed simulator PID.
            self.kill_group(process, signal.SIGKILL)
            process.stdout.close()
            self.helpers.remove(helper)
            output = helper["output"][:MAX_FILE].decode("utf-8", errors="replace")
            if helper["kind"] == "sample":
                context = helper["context"]
                path = context["path"]
                if path.exists() and path.stat().st_size > MAX_FILE:
                    with path.open("r+b") as handle:
                        handle.truncate(MAX_FILE)
                path.with_suffix(".command.txt").write_text(output[:32768])
                self.event("sample_finish", role=context["role"], round=context["round"],
                           returncode=code, timed_out=helper["stopped"])
            elif code == 0 and not helper["stopped"]:
                if helper["kind"] == "inventory":
                    self.inventory(output, helper["context"])
                elif helper["kind"] == "verify_sample":
                    self.verify_sample(output, helper["context"])
                else:
                    self.sessions(output, helper["context"])
            else:
                self.event("helper_failure", helper_kind=helper["kind"], returncode=code, timed_out=helper["stopped"])
                if helper["kind"] == "verify_sample":
                    task = helper["context"]
                    self.event("sample_skipped", role=task["role"], identity=task["identity"].__dict__,
                               reason="identity verification unavailable", round=task["directory"].name)
        # Serial samples keep the host first and avoid three simultaneous samplers.
        if self.sample_queue and not any(h["kind"] in ("sample", "verify_sample") for h in self.helpers):
            task = self.sample_queue.pop(0)
            self.helper(["/bin/ps", "-p", str(task["identity"].pid), "-o", "pid=,ppid=,lstart=,command="],
                        "verify_sample", 2, task)

    def clean_helpers(self):
        # Never signal observed simulator PIDs. Only these Popen-created groups are ours.
        for helper in self.helpers:
            self.kill_group(helper["process"], signal.SIGKILL)
        for helper in self.helpers:
            try:
                helper["process"].wait(timeout=1)
            except subprocess.TimeoutExpired:
                self.event("helper_reap_timeout", pid=helper["process"].pid, helper_kind=helper["kind"])
            helper["process"].stdout.close()
        self.helpers.clear()
        self.sample_queue.clear()

    def run(self):
        output = None
        try:
            output = Path(self.args.log).open("wb")
        except OSError as error:
            self.notice(f"log unavailable, command output inherited: {error}")
            self.observing = False
        try:
            Path(self.args.diagnostics).mkdir(parents=True, exist_ok=True)
            self.timeline = (Path(self.args.diagnostics) / "timeline.jsonl").open("w")
        except OSError as error:
            self.notice(f"diagnostics unavailable: {error}")
            self.observing = False
        old = {number: signal.signal(number, self.signal) for number in (signal.SIGINT, signal.SIGTERM)}
        cancel_at = None
        try:
            self.child = subprocess.Popen(self.args.command, stdout=output, stderr=subprocess.STDOUT,
                                          start_new_session=True)
            self.event("command_start", pid=self.child.pid, argv=self.args.command, simulator=self.args.simulator)
            while self.child.poll() is None:
                if self.cancel_signal is not None:
                    if cancel_at is None:
                        cancel_at = time.monotonic()
                        self.event("cancel", signal=self.cancel_signal)
                        self.kill_group(self.child, self.cancel_signal)
                        self.clean_helpers()
                    elif time.monotonic() - cancel_at >= self.args.cancel_grace:
                        self.kill_group(self.child, signal.SIGKILL)
                        if time.monotonic() - cancel_at >= self.args.cancel_grace + 1:
                            self.event("command_reap_timeout", pid=self.child.pid)
                            break
                elif self.observing:
                    try:
                        self.poll_helpers()
                        self.tick()
                    except Exception as error:
                        self.notice(f"observation disabled; original command continues: {error}")
                        self.event("observer_error", error=str(error))
                        self.clean_helpers()
                        self.observing = False
                time.sleep(self.args.poll_seconds)
            code = self.child.returncode
            self.clean_helpers()
            if self.cancel_signal is not None:
                self.kill_group(self.child, signal.SIGKILL)
                code = 128 + self.cancel_signal
            elif code < 0:
                code = 128 - code
            try:
                self.event("command_exit", original_returncode=self.child.returncode, returncode=code)
                (Path(self.args.diagnostics) / "result.json").write_text(json.dumps(dict(
                    observed_at=utc(), command_pid=self.child.pid, original_returncode=self.child.returncode,
                    returncode=code, cancelled_signal=self.cancel_signal, capture_rounds=self.rounds,
                    observation_enabled_at_exit=self.observing), indent=2))
            except OSError:
                pass
            return code
        finally:
            self.clean_helpers()
            for number, handler in old.items():
                signal.signal(number, handler)
            if output is not None:
                output.close()
            if self.timeline is not None:
                try:
                    self.timeline.close()
                except OSError:
                    pass


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--simulator", required=True)
    parser.add_argument("--log", required=True)
    parser.add_argument("--diagnostics", required=True)
    parser.add_argument("--device-path", type=Path)
    parser.add_argument("--sampler", default="/usr/bin/sample")
    parser.add_argument("--launch-seconds", type=float, default=20)
    parser.add_argument("--second-checkpoint", type=float, default=50)
    parser.add_argument("--sample-seconds", type=int, default=2)
    parser.add_argument("--helper-timeout", type=float, default=5)
    parser.add_argument("--cancel-grace", type=float, default=5)
    parser.add_argument("--poll-seconds", type=float, default=0.2)
    parser.add_argument("--inventory-seconds", type=float, default=2)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args(argv)
    if args.command[:1] == ["--"]:
        args.command = args.command[1:]
    if not args.command:
        parser.error("original command is required after --")
    args.device_path = args.device_path or Path.home() / "Library/Developer/CoreSimulator/Devices" / args.simulator
    return Observer(args).run()


if __name__ == "__main__":
    sys.exit(main())

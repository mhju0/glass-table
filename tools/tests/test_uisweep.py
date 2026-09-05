"""Exercise destructive/failure boundaries without booting real simulators."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


FAKE_TOOL = '''#!/usr/bin/env python3
import json, os, pathlib, sys
name, args = pathlib.Path(sys.argv[0]).name, sys.argv[1:]
root = pathlib.Path(os.environ['FAKE_ROOT'])
with (root / 'calls').open('a') as log:
    log.write(json.dumps([name] + args) + '\\n')
stage = args[1] if name == 'xcrun' else name
if stage == os.environ.get('FAIL_STAGE') and args != ['-version']:
    sys.exit(1)
if name == 'xcodebuild':
    if args == ['-version']:
        print('Xcode 26.6')
    else:
        derived = pathlib.Path(args[args.index('-derivedDataPath') + 1])
        (derived / 'Build/Products/Debug-iphonesimulator/GlassTable.app').mkdir(parents=True, exist_ok=True)
elif name == 'xcrun':
    if stage == 'list':
        print(json.dumps({'devices': {'runtime': [{'name': 'iPhone 17', 'deviceTypeIdentifier': 'type'}]}}))
    elif stage == 'create':
        print('DISPOSABLE-DEVICE')
    elif stage == 'io':
        pathlib.Path(args[-1]).write_bytes(b'png')
'''


class UISweepTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'tools').mkdir()
        shutil.copy(Path(__file__).parents[1] / 'uisweep.sh', self.root / 'tools/uisweep.sh')
        for file in ('project.yml', 'GlassTableEngine/Package.swift',
                     'GlassTableDrills/Package.swift', 'GlassTable/Sources/App.swift'):
            path = self.root / file
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('fixture')
        bin_dir = self.root / 'bin'
        bin_dir.mkdir()
        for name in ('xcodebuild', 'xcodegen', 'xcrun', 'sleep'):
            path = bin_dir / name
            path.write_text(FAKE_TOOL)
            path.chmod(0o755)
        self.env = dict(os.environ, PATH=f'{bin_dir}:{os.environ["PATH"]}',
                        FAKE_ROOT=str(self.root), GT_SIM='iPhone 17')

    def run_sweep(self, *args, fail=''):
        return subprocess.run(['bash', str(self.root / 'tools/uisweep.sh'), *args],
                              env=dict(self.env, FAIL_STAGE=fail), capture_output=True, text=True)

    def calls(self):
        path = self.root / 'calls'
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def test_build_failure_never_installs_a_stale_app(self):
        for stage in ('xcodegen', 'xcodebuild'):
            with self.subTest(stage=stage):
                result = self.run_sweep('--screen', 'today', fail=stage)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(any(c[0] == 'xcrun' for c in self.calls()))

    def test_launch_and_capture_failures_delete_only_the_disposable_device(self):
        for stage in ('launch', 'io'):
            with self.subTest(stage=stage):
                result = self.run_sweep('--screen', 'today', fail=stage)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.calls()[-1], ['xcrun', 'simctl', 'delete', 'DISPOSABLE-DEVICE'])
                self.assertFalse(list((self.root / '.uisweep').glob('*/captured.txt')))

    def test_each_capture_starts_with_fresh_data_and_this_checkouts_app(self):
        result = self.run_sweep('--screen', 'today', '--screen', 'today-empty')
        self.assertEqual(result.returncode, 0, result.stderr)
        installs = [c for c in self.calls() if c[:3] == ['xcrun', 'simctl', 'install']]
        self.assertEqual(len(installs), 2)
        self.assertTrue(all(c[-1].startswith(str(self.root / '.build')) for c in installs))
        self.assertIn(['xcrun', 'simctl', 'uninstall', 'DISPOSABLE-DEVICE',
                       'com.michaelju.glasstable'], self.calls())
        self.assertEqual(len(list((self.root / '.uisweep').glob('*/*.png'))), 2)

    def test_no_build_reuses_matching_artifact_and_rejects_edits(self):
        self.assertEqual(self.run_sweep('--screen', 'today').returncode, 0)
        self.assertEqual(self.run_sweep('--no-build', '--screen', 'today').returncode, 0)
        (self.root / 'GlassTable/Sources/App.swift').write_text('edited')
        before = self.calls()
        result = self.run_sweep('--no-build', '--screen', 'today')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('No matching sweep build', result.stderr)
        self.assertEqual(self.calls()[len(before):], [['xcodebuild', '-version']])

    def test_invalid_screen_fails_before_building(self):
        self.assertEqual(self.run_sweep('--screen', 'typo').returncode, 2)
        self.assertEqual(self.calls(), [])


if __name__ == '__main__':
    unittest.main()

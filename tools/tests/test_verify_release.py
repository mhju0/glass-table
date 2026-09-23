import importlib.util
import plistlib
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('verify_release', Path(__file__).parents[1] / 'verify_release.py')
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseBundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.bundle = Path(self.temp.name)
        self.info = {
            'CFBundleIdentifier': 'com.michaelju.glasstable',
            'CFBundleShortVersionString': '1.0', 'CFBundleVersion': '2',
            'CFBundleDevelopmentRegion': 'ko', 'CFBundleLocalizations': ['ko', 'en'],
            'MinimumOSVersion': '17.0', 'CFBundleSupportedPlatforms': ['iPhoneOS'],
            'CFBundleExecutable': 'GlassTable', 'UIAppFonts': ['Font.otf'],
        }
        self.write_info()
        (self.bundle / 'GlassTable').write_bytes(b'release')
        (self.bundle / 'Assets.car').touch()
        (self.bundle / 'Font.otf').touch()
        (self.bundle / 'Pretendard-LICENSE.txt').write_text('SIL OPEN FONT LICENSE')
        (self.bundle / 'FSRS-LICENSE.txt').write_text('Copyright (c) 2022 Open Spaced Repetition')
        (self.bundle / 'PrivacyInfo.xcprivacy').write_bytes(plistlib.dumps({
            'NSPrivacyTracking': False, 'NSPrivacyTrackingDomains': [],
            'NSPrivacyCollectedDataTypes': [], 'NSPrivacyAccessedAPITypes': [{
                'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults',
                'NSPrivacyAccessedAPITypeReasons': ['CA92.1'],
            }, {
                'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategorySystemBootTime',
                'NSPrivacyAccessedAPITypeReasons': ['35F9.1'],
            }],
        }))

    def write_info(self):
        (self.bundle / 'Info.plist').write_bytes(plistlib.dumps(self.info))

    def test_expected_device_bundle_passes(self):
        self.assertEqual(release.verify(self.bundle), [])

    def test_missing_english_or_timer_declaration_is_rejected(self):
        self.info['CFBundleLocalizations'] = ['ko']
        self.write_info()
        self.assertEqual(len(release.verify(self.bundle)), 1)
        self.info['CFBundleLocalizations'] = ['ko', 'en']
        self.write_info()
        path = self.bundle / 'PrivacyInfo.xcprivacy'
        manifest = plistlib.loads(path.read_bytes())
        manifest['NSPrivacyAccessedAPITypes'].pop()
        path.write_bytes(plistlib.dumps(manifest))
        self.assertEqual(len(release.verify(self.bundle)), 1)

    def test_missing_or_expanded_preference_declarations_are_rejected(self):
        path = self.bundle / 'PrivacyInfo.xcprivacy'
        manifest = plistlib.loads(path.read_bytes())
        for declarations in ([], [{
            'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults',
            'NSPrivacyAccessedAPITypeReasons': ['1C8F.1'],
        }]):
            manifest['NSPrivacyAccessedAPITypes'] = declarations
            path.write_bytes(plistlib.dumps(manifest))
            self.assertEqual(len(release.verify(self.bundle)), 1)

    def test_debug_hook_and_test_plugin_are_rejected(self):
        (self.bundle / 'GlassTable').write_bytes(b'binary GT_TEST_STORE_ID')
        (self.bundle / 'PlugIns').mkdir()
        self.assertEqual(len(release.verify(self.bundle)), 2)

    def test_missing_licenses_and_manifest_are_rejected(self):
        for file in ['PrivacyInfo.xcprivacy', 'FSRS-LICENSE.txt', 'Pretendard-LICENSE.txt']:
            (self.bundle / file).unlink()
        self.assertEqual(len(release.verify(self.bundle)), 3)

    def test_unreviewed_permissions_are_rejected(self):
        self.info.update(UIFileSharingEnabled=True, NSCameraUsageDescription='Camera',
                         NSAppTransportSecurity={'NSAllowsArbitraryLoads': True})
        self.write_info()
        self.assertEqual(len(release.verify(self.bundle)), 3)

    def test_simulator_artifact_is_not_distribution_evidence(self):
        self.info['CFBundleSupportedPlatforms'] = ['iPhoneSimulator']
        self.write_info()
        self.assertIn('Expected a device bundle, not Simulator', release.verify(self.bundle))

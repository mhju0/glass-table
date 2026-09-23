#!/usr/bin/env python3
"""Check the built iPhone Release bundle; signing/App Review remain separate gates."""
import argparse
import plistlib
from pathlib import Path


def verify(bundle: Path) -> list[str]:
    failures = []
    def require(condition, message):
        if not condition:
            failures.append(message)

    info = plistlib.loads((bundle / 'Info.plist').read_bytes())
    require(info.get('CFBundleIdentifier') == 'com.michaelju.glasstable', 'Unexpected bundle identifier')
    require(info.get('CFBundleShortVersionString') and info.get('CFBundleVersion'), 'Missing release version')
    require(info.get('CFBundleDevelopmentRegion') == 'ko' and info.get('CFBundleLocalizations') == ['ko'], 'Declared language must match the Korean interface')
    require(info.get('MinimumOSVersion') == '17.0', 'Minimum OS changed; review compatibility')
    require(info.get('CFBundleSupportedPlatforms') == ['iPhoneOS'], 'Expected a device bundle, not Simulator')
    require(not info.get('UIFileSharingEnabled'), 'Application files must not be publicly shared')
    require(not info.get('NSAppTransportSecurity', {}).get('NSAllowsArbitraryLoads'), 'Unrestricted networking exception')
    require(not any(k.endswith('UsageDescription') for k in info), 'New protected-resource permission needs review')
    executable = bundle / info['CFBundleExecutable']
    binary = executable.read_bytes()
    require(b'GT_DEMO_' not in binary and b'GT_TEST_STORE_ID' not in binary, 'Debug launch hooks leaked into release')
    require(not (bundle / 'PlugIns').exists(), 'Test or extension plug-ins present in release')
    manifest_path = bundle / 'PrivacyInfo.xcprivacy'
    if manifest_path.exists():
        manifest = plistlib.loads(manifest_path.read_bytes())
        require(manifest.get('NSPrivacyTracking') is False, 'Tracking declaration changed')
        for field in ('NSPrivacyTrackingDomains', 'NSPrivacyCollectedDataTypes'):
            require(manifest.get(field) == [], f'{field} requires privacy review')
        require(manifest.get('NSPrivacyAccessedAPITypes') == [{
            'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults',
            'NSPrivacyAccessedAPITypeReasons': ['CA92.1'],
        }], 'Expected app-only preferences declaration; other API uses require privacy review')
    else:
        failures.append('Privacy manifest missing')
    for filename, notice in (
        ('Pretendard-LICENSE.txt', 'SIL OPEN FONT LICENSE'),
        ('FSRS-LICENSE.txt', 'Copyright (c) 2022 Open Spaced Repetition'),
    ):
        path = bundle / filename
        require(path.exists() and notice in path.read_text(), f'{filename} notice missing')
    for font in info.get('UIAppFonts', []):
        require((bundle / font).is_file(), f'Bundled font missing: {font}')
    require(bool(info.get('UIAppFonts')), 'No bundled fonts declared')
    require((bundle / 'Assets.car').is_file(), 'Asset catalog missing')
    return failures


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=Path)
    args = parser.parse_args()
    try:
        problems = verify(args.bundle)
    except (OSError, ValueError, KeyError, plistlib.InvalidFileException) as error:
        parser.exit(1, f'Release verification failed: {error}\n')
    if problems:
        parser.exit(1, '\n'.join(problems) + '\n')
    print('Release bundle checks passed. Signing, device testing and App Store validation are separate.')

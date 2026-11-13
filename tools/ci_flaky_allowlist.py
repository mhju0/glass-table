#!/usr/bin/env python3
"""Retry allowlist for the full UI suite (D63).

`.github/flaky-tests.txt` lists one `Class/testMethod #issue` per line. A failed test is
retried once only if it is listed and its issue is open with the `flaky-test` label.

  check --repo owner/name   validate every entry, print the allowed tests on one line
  split                     read failed tests on stdin, print those not allowed
                            (FLAKY_ALLOWED holds the allowed tests, space-separated)
"""
import argparse
import os
import pathlib
import re
import subprocess
import sys

ENTRY = re.compile(r'^([A-Za-z_]\w*)/(test\w*)\s+#([1-9]\d*)$')


def parse(text):
    """Return ([(class, method, issue)], [error]) for the allowlist text."""
    entries, errors, seen = [], [], set()
    for number, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        match = ENTRY.match(line)
        if not match:
            errors.append(f'line {number}: expected "Class/testMethod #issue", got {line!r}')
            continue
        test = f'{match[1]}/{match[2]}'
        if test in seen:
            errors.append(f'line {number}: {test} is listed twice')
            continue
        seen.add(test)
        entries.append((match[1], match[2], int(match[3])))
    return entries, errors


def test_exists(cls, method, sources):
    for path in sorted(pathlib.Path(sources).glob('*.swift')):
        text = path.read_text()
        if (re.search(rf'\bclass\s+{cls}\s*:\s*XCTestCase\b', text)
                and re.search(rf'\bfunc\s+{method}\s*\(', text)):
            return True
    return False


def validate(entries, sources, open_flaky):
    """Errors for entries whose test is missing or whose issue is not an open flaky-test issue."""
    errors = []
    for cls, method, issue in entries:
        if not test_exists(cls, method, sources):
            errors.append(f'{cls}/{method}: no such test in {sources}')
        if issue not in open_flaky:
            errors.append(f'{cls}/{method}: issue #{issue} is not open with the flaky-test label; '
                          'remove the line once the flake is fixed')
    return errors


def not_allowed(failed, allowed):
    """Failed tests that may not be retried, in input order."""
    return [test for test in failed if test not in allowed]


def open_flaky_issues(repo):
    out = subprocess.run(
        ['gh', 'api', '--paginate', f'repos/{repo}/issues?labels=flaky-test&state=open&per_page=100',
         '--jq', '.[] | select(.pull_request == null) | .number'],
        check=True, capture_output=True, text=True).stdout
    return {int(n) for n in out.split()}


def main(argv=None):
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest='command', required=True)
    check = sub.add_parser('check')
    check.add_argument('--repo', required=True)
    check.add_argument('--list', default='.github/flaky-tests.txt')
    check.add_argument('--sources', default='GlassTable/UITests')
    sub.add_parser('split')
    args = parser.parse_args(argv)

    if args.command == 'split':
        allowed = set(os.environ.get('FLAKY_ALLOWED', '').split())
        failed = [line.strip() for line in sys.stdin if line.strip()]
        for test in not_allowed(failed, allowed):
            print(test)
        return 0

    entries, errors = parse(pathlib.Path(args.list).read_text())
    errors += validate(entries, args.sources, open_flaky_issues(args.repo))
    for error in errors:
        print(f'::error file={args.list}::{error}', file=sys.stderr)
    if errors:
        return 1
    print(' '.join(f'{cls}/{method}' for cls, method, _ in entries))
    return 0


if __name__ == '__main__':
    sys.exit(main())

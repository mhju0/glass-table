import io
import os
import pathlib
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import ci_flaky_allowlist as allowlist  # noqa: E402


class ParseTests(unittest.TestCase):
    def test_entries_comments_and_blank_lines(self):
        entries, errors = allowlist.parse('# header\n\nFooTests/testBar #12\n  BazTests/testQux   #3  \n')
        self.assertEqual(errors, [])
        self.assertEqual(entries, [('FooTests', 'testBar', 12), ('BazTests', 'testQux', 3)])

    def test_malformed_lines_are_errors(self):
        for line in ['FooTests #12', 'FooTests/testBar', 'FooTests/bar #12', 'FooTests/testBar 12',
                     'FooTests/testBar #0', 'FooTests/testBar #12 extra']:
            with self.subTest(line=line):
                entries, errors = allowlist.parse(line)
                self.assertEqual(entries, [])
                self.assertEqual(len(errors), 1)
                self.assertIn('line 1', errors[0])

    def test_duplicate_test_is_an_error(self):
        entries, errors = allowlist.parse('FooTests/testBar #1\nFooTests/testBar #2\n')
        self.assertEqual(entries, [('FooTests', 'testBar', 1)])
        self.assertEqual(errors, ['line 2: FooTests/testBar is listed twice'])


class ValidateTests(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        pathlib.Path(self.dir.name, 'Foo.swift').write_text(
            'final class FooTests: XCTestCase {\n    func testBar() {}\n}\n')
        pathlib.Path(self.dir.name, 'Other.swift').write_text(
            'final class OtherTests: XCTestCase {\n    func testElsewhere() {}\n}\n')

    def tearDown(self):
        self.dir.cleanup()

    def test_listed_test_with_open_issue_is_valid(self):
        self.assertEqual(allowlist.validate([('FooTests', 'testBar', 7)], self.dir.name, {7}), [])

    def test_closed_or_unlabelled_issue_is_an_error(self):
        errors = allowlist.validate([('FooTests', 'testBar', 7)], self.dir.name, {8})
        self.assertEqual(len(errors), 1)
        self.assertIn('issue #7 is not open', errors[0])

    def test_missing_method_or_class_is_an_error(self):
        errors = allowlist.validate([('FooTests', 'testGone', 7), ('GoneTests', 'testBar', 7)],
                                    self.dir.name, {7})
        self.assertEqual(len(errors), 2)
        self.assertTrue(all('no such test' in e for e in errors))

    def test_method_must_be_in_the_class_file(self):
        errors = allowlist.validate([('FooTests', 'testElsewhere', 7)], self.dir.name, {7})
        self.assertEqual(len(errors), 1)


class SplitTests(unittest.TestCase):
    def test_not_allowed_keeps_order_and_drops_allowed(self):
        self.assertEqual(allowlist.not_allowed(['A/testA', 'B/testB', 'C/testC'], {'B/testB'}),
                         ['A/testA', 'C/testC'])

    def test_split_cli_prints_only_unlisted_failures(self):
        out = io.StringIO()
        with mock.patch.dict(os.environ, {'FLAKY_ALLOWED': 'A/testA C/testC'}), \
                mock.patch('sys.stdin', io.StringIO('A/testA\nB/testB\n\n')), redirect_stdout(out):
            self.assertEqual(allowlist.main(['split']), 0)
        self.assertEqual(out.getvalue(), 'B/testB\n')

    def test_split_cli_with_empty_allowlist_rejects_everything(self):
        out = io.StringIO()
        with mock.patch.dict(os.environ, {'FLAKY_ALLOWED': ''}), \
                mock.patch('sys.stdin', io.StringIO('A/testA\n')), redirect_stdout(out):
            allowlist.main(['split'])
        self.assertEqual(out.getvalue(), 'A/testA\n')


class CheckedInListTests(unittest.TestCase):
    def test_repository_list_parses_and_names_real_tests(self):
        root = pathlib.Path(__file__).resolve().parents[2]
        entries, errors = allowlist.parse((root / '.github/flaky-tests.txt').read_text())
        self.assertEqual(errors, [])
        issues = {issue for _, _, issue in entries}
        self.assertEqual(allowlist.validate(entries, root / 'GlassTable/UITests', issues), [])


if __name__ == '__main__':
    unittest.main()

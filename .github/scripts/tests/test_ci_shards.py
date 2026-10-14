import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import ci_shards as ci

FIXTURES = Path(__file__).parent / "fixtures"
SHA = "2bab0fd2e07ee26effb3f3aa9ad3bb2aaf05948c"
XCODE = "Xcode 26.3\nBuild version 17C529"
LOG = "Test Suite 'GlassTableTests.xctest' passed at 2026-10-14 10:42:25.607.\n Executed 98 tests, with 0 failures (0 unexpected)\n✔ Test run with 46 tests in 7 suites passed after 1.569 seconds.\n"


class ShardCoverageTests(unittest.TestCase):
    def setUp(self):
        # Captured enumeration and result nodes use real Xcode output; outcomes below
        # are assembled to exercise missing coverage and corruption, not replay tests.
        self.enumeration = ci.read_json(FIXTURES / "xcode-enumeration.json")
        self.nodes = ci.read_json(FIXTURES / "xcode-result-nodes.json")

    def manifest(self, index=0):
        return ci.make_manifest(self.enumeration, index, SHA, XCODE, "18.5", "iPhone 16 Pro")

    def execution(self, manifest):
        targets = manifest["targets"]
        bundles = []
        for target in [ci.UNIT_TARGET, ci.UI_TARGET]:
            groups = []
            classes = targets[target] if target == ci.UNIT_TARGET else {name: targets[target][name] for name in manifest["assignedClasses"]}
            for name, methods in classes.items():
                children = []
                for identifier in methods:
                    method = identifier.rsplit("/", 1)[1]
                    parameterized = ":" in method
                    node = copy.deepcopy(self.nodes["parameterized" if parameterized else "plain" if target == ci.UNIT_TARGET else "ui"])
                    node.update(name=method, nodeIdentifier=f"{name}/{method}", nodeIdentifierURL=f"test://com.apple.xcode/GlassTable/{identifier}", result="Passed")
                    if parameterized:
                        for argument in node["children"]:
                            suffix = argument["nodeIdentifierURL"].split("?args=", 1)[1]
                            argument["nodeIdentifierURL"] = node["nodeIdentifierURL"] + "?args=" + suffix
                    if name == ci.CRAWL_CLASS:
                        node.update(result="Skipped", children=[{"nodeType": "Skip Message", "name": ci.CRAWL_SKIP_REASON}])
                    children.append(node)
                groups.append({"nodeType": "Test Suite", "name": name, "children": children})
            bundles.append({"nodeType": "Unit test bundle" if target == ci.UNIT_TARGET else "UI test bundle", "name": target, "children": groups})
        records = sum(len(group["children"]) for bundle in bundles for group in bundle["children"])
        skips = 11 if ci.CRAWL_CLASS in manifest["assignedClasses"] else 0
        tests = {"devices": [{"modelName": "iPhone 16 Pro", "osVersion": "18.5", "deviceId": "fixture-device"}], "testPlanConfigurations": [{"configurationId": "1"}], "testNodes": [{"nodeType": "Test Plan", "name": "GlassTable", "children": bundles}]}
        summary = {"result": "Passed", "failedTests": 0, "expectedFailures": 0, "totalTestCount": records, "passedTests": records-skips, "skippedTests": skips}
        return tests, summary

    def test_authentic_discovery_balances_all_classes_and_preserves_both_unit_frameworks(self):
        manifest = self.manifest()
        ui = manifest["targets"][ci.UI_TARGET]
        self.assertEqual(30, len(ui))
        self.assertEqual([80, 80, 81], [sum(len(ui[name]) for name in shard) for shard in manifest["assignments"]])
        self.assertEqual(144, sum(map(len, manifest["targets"][ci.UNIT_TARGET].values())))
        self.assertEqual(set(ui), {name for shard in manifest["assignments"] for name in shard})

    def test_assignment_is_stable_when_enumeration_order_changes(self):
        original = self.manifest()
        self.enumeration["values"][0]["children"].reverse()
        for target in self.enumeration["values"][0]["children"]:
            target["children"].reverse()
            for group in target["children"]:
                group["children"].reverse()
        self.assertEqual(original, self.manifest())

    def test_discovery_rejects_errors_missing_target_and_unknown_ui_schema(self):
        for mutation in ["errors", "missing", "unknown", "empty", "duplicate-class", "duplicate-method"]:
            with self.subTest(mutation=mutation):
                document = copy.deepcopy(self.enumeration)
                ui = next(target for target in document["values"][0]["children"] if target["name"] == ci.UI_TARGET)
                if mutation == "errors": document["errors"] = ["Discovery failed"]
                if mutation == "missing": document["values"][0]["children"] = [ui]
                if mutation == "unknown": ui["children"][0]["kind"] = "suite"
                if mutation == "empty": ui["children"][0]["children"] = []
                if mutation == "duplicate-class": ui["children"].append(copy.deepcopy(ui["children"][0]))
                if mutation == "duplicate-method": ui["children"][0]["children"].append(copy.deepcopy(ui["children"][0]["children"][0]))
                with self.assertRaises(ValueError): ci.discovery(document)

    def test_metadata_and_assignment_corruption_fail_closed(self):
        for key, value in [("xcode", "Xcode 27"), ("runtime", "26.5"), ("assignedClasses", []), ("uiDigest", "changed")]:
            with self.subTest(key=key):
                manifest = self.manifest()
                manifest[key] = value
                with self.assertRaises(ValueError): ci.validate_manifest(manifest)

    def test_all_shards_reconcile_methods_frameworks_and_argument_cases(self):
        for index in range(3):
            manifest = self.manifest(index)
            tests, summary = self.execution(manifest)
            report = ci.reconcile(manifest, tests, summary, LOG, "success")
            self.assertEqual({"XCTest": 98, "SwiftTesting": 46}, report["unitFrameworkCounts"])
            self.assertEqual(144, len(report["unitResults"]))
            self.assertEqual(12, len(report["argumentCases"]))

    def test_missing_unit_or_ui_method_and_duplicate_execution_are_rejected(self):
        for target in [ci.UNIT_TARGET, ci.UI_TARGET]:
            for operation in ["missing", "duplicate"]:
                with self.subTest(target=target, operation=operation):
                    manifest = self.manifest()
                    tests, summary = self.execution(manifest)
                    bundle = next(bundle for bundle in tests["testNodes"][0]["children"] if bundle["name"] == target)
                    cases = bundle["children"][0]["children"]
                    if operation == "missing": cases.pop()
                    else: cases.append(copy.deepcopy(cases[0]))
                    with self.assertRaises(ValueError): ci.reconcile(manifest, tests, summary, LOG, "success")

    def test_failed_or_missing_parameterized_cases_are_not_normalized_away(self):
        for operation in ["failed", "missing", "duplicate"]:
            with self.subTest(operation=operation):
                manifest = self.manifest()
                tests, summary = self.execution(manifest)
                cases = next(group for group in tests["testNodes"][0]["children"][0]["children"] if group["name"] == "AppearanceTests")["children"]
                case = next(case for case in cases if ":" in case["name"])
                if operation == "failed": case["children"][0]["result"] = "Failed"
                if operation == "missing": case["children"] = []
                if operation == "duplicate": case["children"].append(copy.deepcopy(case["children"][0]))
                with self.assertRaises(ValueError): ci.reconcile(manifest, tests, summary, LOG, "success")

    def test_unknown_skips_and_changed_crawler_reason_are_rejected(self):
        index = next(index for index, shard in enumerate(self.manifest()["assignments"]) if ci.CRAWL_CLASS in shard)
        for operation in ["unknown-skip", "crawler-reason", "crawler-not-skipped"]:
            with self.subTest(operation=operation):
                manifest = self.manifest(index)
                tests, summary = self.execution(manifest)
                groups = tests["testNodes"][0]["children"][1]["children"]
                crawler = next(group for group in groups if group["name"] == ci.CRAWL_CLASS)["children"][0]
                if operation == "unknown-skip": tests["testNodes"][0]["children"][0]["children"][0]["children"][0]["result"] = "Skipped"
                if operation == "crawler-reason": crawler["children"][0]["name"] = "Other skip"
                if operation == "crawler-not-skipped": crawler["result"] = "Passed"
                with self.assertRaises(ValueError): ci.reconcile(manifest, tests, summary, LOG, "success")

    def test_missing_framework_marker_or_failed_command_is_rejected(self):
        manifest = self.manifest()
        tests, summary = self.execution(manifest)
        for log, status in [(LOG.split("✔")[0], "success"), (LOG, "failure"), (LOG.replace("46 tests", "45 tests"), "success")]:
            with self.assertRaises(ValueError): ci.reconcile(manifest, tests, summary, log, status)

    def test_real_opt_in_skip_message_matches_the_allowed_policy(self):
        self.assertEqual("Skipped", self.nodes["skip"]["result"])
        self.assertEqual([ci.CRAWL_SKIP_REASON], [child["name"] for child in self.nodes["skip"]["children"]])

    def reports(self, root):
        for index in range(3):
            folder = root / f"shard-{index}"
            folder.mkdir()
            manifest = self.manifest(index)
            tests, summary = self.execution(manifest)
            ci.write_json(folder / "manifest.json", manifest)
            ci.write_json(folder / "report.json", ci.reconcile(manifest, tests, summary, LOG, "success"))

    def test_aggregate_requires_complete_disjoint_union_and_all_required_jobs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.reports(root)
            result = ci.aggregate(root, "success", SHA)
            self.assertEqual((241, 230, 11), (result["uiMethods"], result["uiPassed"], result["uiSkipped"]))
            for status in ["failure", "cancelled", "skipped", ""]:
                with self.assertRaises(ValueError): ci.aggregate(root, status, SHA)
            (root / "shard-2" / "report.json").unlink()
            with self.assertRaises(OSError): ci.aggregate(root, "success", SHA)

    def test_aggregate_rejects_missing_duplicate_or_different_shard_manifests(self):
        for operation in ["missing", "duplicate", "different-commit", "missing-unit", "missing-ui"]:
            with self.subTest(operation=operation), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.reports(root)
                path = root / "shard-2" / "manifest.json"
                if operation == "missing": path.unlink()
                elif operation == "duplicate": ci.write_json(path, ci.read_json(root / "shard-1" / "manifest.json"))
                elif operation == "different-commit":
                    value = ci.read_json(path); value["sha"] = "a"*40; ci.write_json(path, value)
                else:
                    report_path = path.with_name("report.json")
                    value = ci.read_json(report_path)
                    key = "unitResults" if operation == "missing-unit" else "uiResults"
                    value[key].pop(next(iter(value[key])))
                    ci.write_json(report_path, value)
                with self.assertRaises(ValueError): ci.aggregate(root, "success", SHA)


if __name__ == "__main__":
    unittest.main()

import copy
import json
from pathlib import Path
import plistlib
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

    def execution(self, manifest, argument_fixture="parameterized"):
        targets = manifest["targets"]
        allowed_skips = ci.allowed_skip_reasons(manifest)
        bundles = []
        for target in [ci.UNIT_TARGET, ci.UI_TARGET]:
            groups = []
            classes = targets[target] if target == ci.UNIT_TARGET else {name: targets[target][name] for name in manifest["assignedClasses"]}
            for name, methods in classes.items():
                children = []
                for identifier in methods:
                    method = identifier.rsplit("/", 1)[1]
                    parameterized = ":" in method
                    node = copy.deepcopy(self.nodes[argument_fixture if parameterized else "plain" if target == ci.UNIT_TARGET else "ui"])
                    node.update(name=method, nodeIdentifier=f"{name}/{method}", nodeIdentifierURL=f"test://com.apple.xcode/GlassTable/{identifier}", result="Passed")
                    if parameterized:
                        for argument in node["children"]:
                            if "nodeIdentifierURL" in argument:
                                suffix = argument["nodeIdentifierURL"].split("?args=", 1)[1]
                                argument["nodeIdentifierURL"] = node["nodeIdentifierURL"] + "?args=" + suffix
                    if identifier in allowed_skips:
                        node.update(result="Skipped", children=[{"nodeType": "Skip Message", "name": allowed_skips[identifier]}])
                    children.append(node)
                groups.append({"nodeType": "Test Suite", "name": name, "children": children})
            bundles.append({"nodeType": "Unit test bundle" if target == ci.UNIT_TARGET else "UI test bundle", "name": target, "children": groups})
        records = sum(len(group["children"]) for bundle in bundles for group in bundle["children"])
        skips = sum(method in allowed_skips for name in manifest["assignedClasses"] for method in targets[ci.UI_TARGET][name])
        tests = {"devices": [{"modelName": "iPhone 16 Pro", "osVersion": "18.5", "deviceId": "fixture-device"}], "testPlanConfigurations": [{"configurationId": "1"}], "testNodes": [{"nodeType": "Test Plan", "name": "GlassTable", "children": bundles}]}
        summary = {"result": "Passed", "failedTests": 0, "expectedFailures": 0, "totalTestCount": records, "passedTests": records-skips, "skippedTests": skips}
        return tests, summary

    def test_authentic_discovery_balances_all_classes_and_preserves_both_unit_frameworks(self):
        manifest = self.manifest()
        ui = manifest["targets"][ci.UI_TARGET]
        self.assertEqual(30, len(ui))
        self.assertEqual(241, sum(len(ui[name]) for shard in manifest["assignments"] for name in shard))
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

    def test_measured_durations_isolate_heavy_class_and_balance_runtime(self):
        timing = ci.read_json(ci.TIMING_FILE)
        classes = {name: entry["methods"] for name, entry in timing["classes"].items()}
        assignments = ci.partition(classes)
        weights = ci.class_weights(classes)
        heavy = "BilingualConsistencyB20Tests"
        self.assertEqual([heavy], next(shard for shard in assignments if heavy in shard))
        loads = [sum(weights[name] for name in shard) for shard in assignments]
        lower_bound = max(max(weights.values()), sum(weights.values()) / ci.SHARD_COUNT)
        self.assertLessEqual(max(loads), lower_bound * 1.03)
        self.assertEqual(243, sum(len(classes[name]) for shard in assignments for name in shard))

    def test_new_classes_and_methods_keep_complete_disjoint_conservative_assignment(self):
        timing = ci.read_json(ci.TIMING_FILE)
        classes = {name: list(entry["methods"]) for name, entry in timing["classes"].items()}
        classes["NewFlowTests"] = [f"{ci.UI_TARGET}/NewFlowTests/testNew{i}()" for i in range(3)]
        name = "AccessibilityAuditTests"
        old_weight = ci.class_weights(classes)[name]
        classes[name].append(f"{ci.UI_TARGET}/{name}/testNew()")
        weights = ci.class_weights(classes)
        fallback = timing["fallbackMillisecondsPerMethod"]
        self.assertGreaterEqual(weights[name], old_weight + fallback)
        self.assertGreaterEqual(weights["NewFlowTests"], 3 * fallback)
        assignments = ci.partition(classes)
        flattened = [name for shard in assignments for name in shard]
        self.assertEqual(set(classes), set(flattened))
        self.assertEqual(len(classes), len(flattened))
        reordered = {name: list(reversed(methods)) for name, methods in reversed(list(classes.items()))}
        self.assertEqual(assignments, ci.partition(reordered))

    def test_manifest_rejects_changed_timing_profile_digest(self):
        manifest = self.manifest()
        manifest["timingDigest"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "timing profile"):
            ci.validate_manifest(manifest)

    def target_enumeration(self, target):
        document = copy.deepcopy(self.enumeration)
        document["values"][0]["children"] = [node for node in document["values"][0]["children"] if node["name"] == target]
        return document

    def test_sequential_target_discoveries_merge_complete_authoritative_inventories(self):
        merged = ci.merge_enumerations(self.target_enumeration(ci.UNIT_TARGET), self.target_enumeration(ci.UI_TARGET))
        self.assertEqual(ci.discovery(self.enumeration), ci.discovery(merged))

    def test_xcode_26_3_both_target_outputs_merge_after_complete_validation(self):
        unit = ci.read_json(FIXTURES / "xcode-26.3-unit-enumeration.json")
        ui = ci.read_json(FIXTURES / "xcode-26.3-ui-enumeration.json")
        self.assertEqual(ci.discovery(self.enumeration), ci.discovery(ci.merge_enumerations(unit, ui)))
        for operation in ["mismatch-unit", "mismatch-ui", "empty-unit", "empty-ui", "errors", "duplicate", "unknown"]:
            with self.subTest(operation=operation):
                changed = copy.deepcopy(ui)
                target_name = ci.UNIT_TARGET if operation.endswith("unit") else ci.UI_TARGET
                target = next(target for target in changed["values"][0]["children"] if target["name"] == target_name)
                if operation.startswith("mismatch"): target["children"][0]["children"].pop()
                if operation.startswith("empty"): target["children"] = []
                if operation == "errors": changed["errors"] = ["Discovery failed"]
                if operation == "duplicate": changed["values"][0]["children"].append(copy.deepcopy(target))
                if operation == "unknown": target["name"] = "UnknownTests"
                with self.assertRaises(ValueError): ci.merge_enumerations(unit, changed)

    def test_merge_checks_overlapping_targets_for_mixed_output_shapes(self):
        full = copy.deepcopy(self.enumeration)
        unit = self.target_enumeration(ci.UNIT_TARGET)
        ui = self.target_enumeration(ci.UI_TARGET)
        self.assertEqual(ci.discovery(full), ci.discovery(ci.merge_enumerations(unit, full)))
        self.assertEqual(ci.discovery(full), ci.discovery(ci.merge_enumerations(full, ui)))
        unit["values"][0]["children"][0]["children"][0]["children"].pop()
        with self.assertRaisesRegex(ValueError, "inventories differ"): ci.merge_enumerations(unit, full)

    def test_merge_rejects_empty_unit_output_even_when_xcode_reports_no_errors(self):
        for mutation in ["empty", "errors", "wrong-target", "duplicate-target", "unexpected-target"]:
            with self.subTest(mutation=mutation):
                unit = self.target_enumeration(ci.UNIT_TARGET)
                if mutation == "empty": unit["values"][0]["children"][0]["children"] = []
                if mutation == "errors": unit["errors"] = ["Early unexpected exit: Lost connection to testmanagerd"]
                if mutation == "wrong-target": unit = self.target_enumeration(ci.UI_TARGET)
                if mutation == "duplicate-target": unit["values"][0]["children"].append(copy.deepcopy(unit["values"][0]["children"][0]))
                if mutation == "unexpected-target": unit["values"][0]["children"][0]["name"] = "UnknownTests"
                with self.assertRaises(ValueError): ci.merge_enumerations(unit, self.target_enumeration(ci.UI_TARGET))

    def test_test_spec_rejects_persisted_filters_and_disabled_configuration_or_missing_targets(self):
        for mutation in ["clean", "only", "skip", "disabled", "missing"]:
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as directory:
                spec = {target: {"BlueprintName": target} for target in [ci.UNIT_TARGET, ci.UI_TARGET]}
                if mutation == "only": spec[ci.UNIT_TARGET]["OnlyTestIdentifiers"] = ["AppFeedbackTests"]
                if mutation == "skip": spec[ci.UI_TARGET]["SkipTestIdentifiers"] = ["UXAuditCrawl"]
                if mutation == "disabled": spec = {"TestConfigurations": [{"Name": "Test Scheme Action", "IsEnabled": False, "TestTargets": list(spec.values())}]}
                if mutation == "missing": del spec[ci.UNIT_TARGET]
                Path(directory, "GlassTable.xctestrun").write_bytes(plistlib.dumps(spec))
                if mutation == "clean": self.assertEqual([ci.UNIT_TARGET, ci.UI_TARGET], ci.check_test_spec(directory)["targets"])
                else:
                    with self.assertRaises(ValueError): ci.check_test_spec(directory)

    def test_documented_configuration_test_spec_structure_is_supported(self):
        with tempfile.TemporaryDirectory() as directory:
            spec = {"TestConfigurations": [{"Name": "Test Scheme Action", "IsEnabled": True, "TestTargets": [
                {"BlueprintName": ci.UNIT_TARGET}, {"BlueprintName": ci.UI_TARGET},
            ]}]}
            Path(directory, "GlassTable.xctestrun").write_bytes(plistlib.dumps(spec))
            self.assertEqual([ci.UNIT_TARGET, ci.UI_TARGET], ci.check_test_spec(directory)["targets"])

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

    def test_xcode_26_3_arguments_without_urls_preserve_descriptions_and_occurrences(self):
        manifest = self.manifest()
        tests, summary = self.execution(manifest, "parameterized_xcode_26_3")
        cases = next(group for group in tests["testNodes"][0]["children"][0]["children"] if group["name"] == "AppearanceTests")["children"]
        case = next(case for case in cases if ":" in case["name"])
        case["children"].append(copy.deepcopy(case["children"][0]))
        report = ci.reconcile(manifest, tests, summary, LOG, "success")
        self.assertEqual(13, len(report["argumentCases"]))
        self.assertTrue(all(row["identifierURL"] is None for row in report["argumentCases"]))
        duplicates = [row for row in report["argumentCases"] if row["parentMethod"].endswith(case["nodeIdentifier"]) and row["name"] == case["children"][0]["name"]]
        self.assertEqual([1, 2], [row["occurrence"] for row in duplicates])
        case["children"].reverse()
        self.assertEqual(report, ci.reconcile(manifest, tests, summary, LOG, "success"))

    def test_argument_rows_support_mixed_observed_formats_and_reject_duplicate_urls(self):
        rows = []
        for fixture in ["parameterized", "parameterized_xcode_26_3"]:
            case = self.nodes[fixture]
            for child in case["children"]:
                rows.append({"parentMethod": f"{ci.UNIT_TARGET}/{case['nodeIdentifier']}", "name": child["name"], "identifierURL": child.get("nodeIdentifierURL"), "result": child["result"]})
        self.assertEqual(4, len(ci.argument_rows(rows)))
        rows.append(copy.deepcopy(rows[0]))
        with self.assertRaisesRegex(ValueError, "duplicate.*URL"): ci.argument_rows(rows)

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

    def test_url_free_argument_rows_still_reject_failed_missing_or_unnamed_results(self):
        for operation in ["failed", "missing", "unnamed"]:
            with self.subTest(operation=operation):
                manifest = self.manifest()
                tests, summary = self.execution(manifest, "parameterized_xcode_26_3")
                cases = next(group for group in tests["testNodes"][0]["children"][0]["children"] if group["name"] == "AppearanceTests")["children"]
                case = next(case for case in cases if ":" in case["name"])
                if operation == "failed": case["children"][0]["result"] = "Failed"
                if operation == "missing": case["children"] = []
                if operation == "unnamed": case["children"][0]["name"] = ""
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

    def test_authentic_failure_message_skip_nodes_reconcile(self):
        # Unmodified nodes from run 38601208079 at 77147cb, artifact IDs
        # 11916149226 (attached sheet) and 11916339061 (crawler).
        nodes = ci.read_json(FIXTURES / "xcode-26.3-skip-nodes.json")
        for fixture in nodes.values():
            method = f"{ci.UI_TARGET}/{fixture['nodeIdentifier']}"
            index = next(i for i, classes in enumerate(self.manifest()["assignments"])
                         if fixture["nodeIdentifier"].split("/")[0] in classes)
            manifest = self.manifest(index)
            tests, summary = self.execution(manifest)
            for group in tests["testNodes"][0]["children"][1]["children"]:
                for i, node in enumerate(group["children"]):
                    if node["nodeIdentifier"] == fixture["nodeIdentifier"]:
                        group["children"][i] = copy.deepcopy(fixture)
            report = ci.reconcile(manifest, tests, summary, LOG, "success")
            self.assertEqual([ci.allowed_skip_reasons(manifest)[method]], report["uiResults"][method]["skipMessages"])

    def test_skip_messages_require_exact_parent_reason_and_single_evidence(self):
        fixture = ci.read_json(FIXTURES / "xcode-26.3-skip-nodes.json")["attached_sheet"]
        index = next(i for i, classes in enumerate(self.manifest()["assignments"]) if "LearningFlowTests" in classes)
        for change in ["missing", "wrong", "duplicate", "generic-failure", "passed-parent", "cross-method", "unknown-kind"]:
            with self.subTest(change=change):
                manifest = self.manifest(index)
                tests, summary = self.execution(manifest)
                group = next(g for g in tests["testNodes"][0]["children"][1]["children"] if g["name"] == "LearningFlowTests")
                node = next(n for n in group["children"] if n["nodeIdentifier"] == fixture["nodeIdentifier"])
                node.update(copy.deepcopy(fixture))
                if change == "missing": node["children"] = []
                if change == "wrong": node["children"][0]["name"] = ci.CRAWL_SKIP_REASON
                if change == "duplicate": node["children"] *= 2
                if change == "generic-failure": node["children"][0]["name"] = "Assertion failed"
                if change == "passed-parent": node["result"] = "Passed"
                if change == "cross-method": node["nodeIdentifier"] = "LearningFlowTests/testUnrelated()"
                if change == "unknown-kind": node["children"][0]["nodeType"] = "Message"
                with self.assertRaises(ValueError): ci.reconcile(manifest, tests, summary, LOG, "success")

    def test_attached_sheet_skip_is_exact_method_and_pre26_only(self):
        manifest = self.manifest()
        self.assertEqual(ci.ATTACHED_SHEET_SKIP_REASON, ci.allowed_skip_reasons(manifest)[ci.ATTACHED_SHEET_METHOD])
        for runtime in ["26", "26.0", "26.5", "27.0"]:
            manifest["runtime"] = runtime
            self.assertNotIn(ci.ATTACHED_SHEET_METHOD, ci.allowed_skip_reasons(manifest))
        manifest["runtime"] = "25.9"
        self.assertIn(ci.ATTACHED_SHEET_METHOD, ci.allowed_skip_reasons(manifest))

    def test_aggregate_rejects_missing_or_wrong_conditional_skip(self):
        for change in ["passed", "wrong-reason"]:
            with self.subTest(change=change), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.reports(root)
                for path in root.glob("*/report.json"):
                    report = ci.read_json(path)
                    if ci.ATTACHED_SHEET_METHOD in report["uiResults"]:
                        record = report["uiResults"][ci.ATTACHED_SHEET_METHOD]
                        if change == "passed": record["result"] = "Passed"
                        else: record["skipMessages"] = [ci.CRAWL_SKIP_REASON]
                        ci.write_json(path, report)
                with self.assertRaises(ValueError): ci.aggregate(root, "success", SHA)

    def reports(self, root, argument_fixture="parameterized"):
        for index in range(3):
            folder = root / f"shard-{index}"
            folder.mkdir()
            manifest = self.manifest(index)
            tests, summary = self.execution(manifest, argument_fixture)
            ci.write_json(folder / "manifest.json", manifest)
            ci.write_json(folder / "report.json", ci.reconcile(manifest, tests, summary, LOG, "success"))

    def test_aggregate_xcode_26_3_argument_rows_require_identical_descriptions_and_occurrences(self):
        for operation in ["unchanged", "changed", "missing", "occurrence", "failed"]:
            with self.subTest(operation=operation), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.reports(root, "parameterized_xcode_26_3")
                path = root / "shard-2" / "report.json"
                report = ci.read_json(path)
                rows = report["argumentCases"]
                if operation == "changed": rows[0]["name"] = "changed argument"
                if operation == "missing": rows.pop(0)
                if operation == "occurrence": rows[0]["occurrence"] = 2
                if operation == "failed": rows[0]["result"] = "Failed"
                ci.write_json(path, report)
                if operation == "unchanged": self.assertEqual(12, ci.aggregate(root, "success", SHA)["unitArgumentCasesPerShard"])
                else:
                    with self.assertRaises(ValueError): ci.aggregate(root, "success", SHA)

    def test_aggregate_rejects_invalid_occurrence_even_when_all_reports_agree(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.reports(root, "parameterized_xcode_26_3")
            for path in root.glob("*/report.json"):
                report = ci.read_json(path)
                report["argumentCases"][0]["occurrence"] = 2
                ci.write_json(path, report)
            with self.assertRaisesRegex(ValueError, "occurrences"): ci.aggregate(root, "success", SHA)

    def test_aggregate_requires_complete_disjoint_union_and_all_required_jobs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.reports(root)
            result = ci.aggregate(root, "success", SHA)
            self.assertEqual((241, 229, 12), (result["uiMethods"], result["uiPassed"], result["uiSkipped"]))
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

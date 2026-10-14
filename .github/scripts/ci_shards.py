#!/usr/bin/env python3
"""Assign compiled XCTest classes and reconcile serial CI shard coverage."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

UI_TARGET = "GlassTableUITests"
UNIT_TARGET = "GlassTableTests"
SHARD_COUNT = 3
CRAWL_CLASS = "UXAuditCrawl"
CRAWL_SKIP_REASON = "Test skipped - UX audit crawl runs only with GT_AUDIT_OUT"


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_json(path):
    return json.loads(Path(path).read_text())


def write_json(path, value):
    Path(path).write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def discovery(document):
    require(set(document) == {"errors", "values"} and document["errors"] == [], "Enumeration errors or unexpected root schema")
    require(len(document["values"]) == 1, "Expected one enumerated test plan")
    plan = document["values"][0]
    require(plan.get("kind") == "plan" and plan.get("name") == "GlassTable", "Unexpected test plan")
    targets = {}
    for target in plan.get("children", []):
        name = target.get("name")
        require(target.get("kind") == "target" and name in {UI_TARGET, UNIT_TARGET}, "Unexpected test target")
        require(name not in targets, "Duplicate test target")
        classes = {}
        for group in target.get("children", []):
            class_name = group.get("name", "")
            require(group.get("kind") == "class" and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", class_name), "Unexpected test class schema")
            require(class_name not in classes, "Duplicate test class")
            methods = []
            for test in group.get("children", []):
                method = test.get("name", "")
                require(test.get("kind") == "test" and not test.get("children") and method.endswith(")") and "/" not in method and "\n" not in method, "Unexpected test method schema")
                methods.append(f"{name}/{class_name}/{method}")
            require(methods and len(set(methods)) == len(methods), "Empty class or duplicate test method")
            classes[class_name] = sorted(methods)
        require(classes, "Empty test target")
        targets[name] = dict(sorted(classes.items()))
    require(set(targets) == {UI_TARGET, UNIT_TARGET}, "Both complete unit and UI targets must be enumerated")
    require(len(targets[UI_TARGET].get(CRAWL_CLASS, [])) == 11, "Expected the eleven opt-in crawler methods")
    return targets


def partition(classes):
    shards = [[] for _ in range(SHARD_COUNT)]
    loads = [0] * SHARD_COUNT
    for name in sorted(classes, key=lambda name: (-len(classes[name]), name)):
        index = min(range(SHARD_COUNT), key=lambda index: (loads[index], index))
        shards[index].append(name)
        loads[index] += len(classes[name])
    require(all(shards), "Every shard must contain whole UI classes")
    require(sorted(name for shard in shards for name in shard) == sorted(classes), "Unassigned or duplicate shard classes")
    return [sorted(shard) for shard in shards]


def make_manifest(document, shard, sha, xcode, runtime, model):
    require(shard in range(SHARD_COUNT), "Invalid shard index")
    require(re.fullmatch(r"[a-f0-9]{40}", sha), "Invalid frozen commit")
    require(xcode == "Xcode 26.3\nBuild version 17C529", "Unexpected Xcode toolchain")
    require(runtime == "18.5" and model == "iPhone 16 Pro", "Unexpected simulator runtime or model")
    targets = discovery(document)
    assignments = partition(targets[UI_TARGET])
    return {
        "schemaVersion": 1, "sha": sha, "xcode": xcode, "runtime": runtime, "model": model,
        "shardIndex": shard, "shardCount": SHARD_COUNT, "targets": targets,
        "uiDigest": digest(targets[UI_TARGET]), "unitDigest": digest(targets[UNIT_TARGET]),
        "assignments": assignments, "assignedClasses": assignments[shard],
    }


def validate_manifest(manifest):
    require(manifest.get("schemaVersion") == 1 and manifest.get("shardCount") == SHARD_COUNT, "Unexpected manifest version or shard count")
    index = manifest.get("shardIndex")
    require(type(index) is int and index in range(SHARD_COUNT), "Invalid manifest shard index")
    targets = manifest["targets"]
    require(set(targets) == {UI_TARGET, UNIT_TARGET}, "Missing manifest targets")
    require(re.fullmatch(r"[a-f0-9]{40}", manifest["sha"]) and manifest["xcode"] == "Xcode 26.3\nBuild version 17C529", "Unexpected manifest commit or Xcode")
    require(manifest["runtime"] == "18.5" and manifest["model"] == "iPhone 16 Pro", "Unexpected manifest runtime")
    for target, classes in targets.items():
        require(classes, "Empty manifest target")
        for name, methods in classes.items():
            require(methods and methods == sorted(set(methods)), "Empty or duplicate manifest methods")
            require(all(method.startswith(f"{target}/{name}/") and method.count("/") == 2 and method.endswith(")") for method in methods), "Unexpected manifest method identifier")
    require(len(targets[UI_TARGET].get(CRAWL_CLASS, [])) == 11, "Missing documented crawler methods")
    require(manifest["uiDigest"] == digest(targets[UI_TARGET]) and manifest["unitDigest"] == digest(targets[UNIT_TARGET]), "Manifest digest mismatch")
    assignments = partition(targets[UI_TARGET])
    require(manifest["assignments"] == assignments and manifest["assignedClasses"] == assignments[index], "Manifest assignment mismatch")


def outcomes(document):
    require(set(document) == {"devices", "testNodes", "testPlanConfigurations"}, "Unexpected result tree schema")
    require(len(document["devices"]) == 1 and len(document["testPlanConfigurations"]) == 1, "Expected one serial device and test configuration")
    device = document["devices"][0]
    require(device.get("modelName") == "iPhone 16 Pro" and device.get("osVersion") == "18.5", "Result device differs from pinned runtime")
    records, arguments = {}, {}
    bundles = set()

    def walk(node, target=None, method=None):
        kind = node.get("nodeType")
        if kind in {"Unit test bundle", "UI test bundle"}:
            target = node.get("name")
            require(target in {UI_TARGET, UNIT_TARGET} and target not in bundles, "Unexpected or duplicate result bundle")
            bundles.add(target)
        if kind == "Test Case":
            require(target is not None and method is None, "Unexpected nested test case")
            identifier = node.get("nodeIdentifier", "")
            require(identifier.count("/") == 1, "Unexpected test identifier")
            method = f"{target}/{identifier}"
            require(method not in records, "Duplicate executed test method")
            status = node.get("result")
            require(status in {"Passed", "Skipped"}, f"Unsuccessful test: {method}: {status}")
            skips = [child.get("name") for child in node.get("children", []) if child.get("nodeType") == "Skip Message"]
            records[method] = {"result": status, "skipMessages": skips}
        if kind == "Arguments":
            identifier = node.get("nodeIdentifierURL", "")
            require(method is not None and "?args=" in identifier and identifier not in arguments, "Unexpected or duplicate parameterized case")
            require(node.get("result") == "Passed", f"Unsuccessful parameterized case: {identifier}")
            arguments[identifier] = method
        for child in node.get("children", []):
            walk(child, target, method)

    for node in document["testNodes"]:
        require(node.get("nodeType") == "Test Plan" and node.get("name") == "GlassTable", "Unexpected result test plan")
        walk(node)
    require(bundles == {UI_TARGET, UNIT_TARGET}, "Both unit and UI execution results are required")
    return records, arguments, device


def reconcile(manifest, tests, summary, log, app_outcome):
    validate_manifest(manifest)
    require(app_outcome == "success", "App test command did not succeed")
    require(summary.get("result") == "Passed" and summary.get("failedTests") == 0 and summary.get("expectedFailures") == 0, "Unsuccessful test summary")
    records, arguments, device = outcomes(tests)
    targets = manifest["targets"]
    expected_units = {method for methods in targets[UNIT_TARGET].values() for method in methods}
    expected_ui = {method for name in manifest["assignedClasses"] for method in targets[UI_TARGET][name]}
    require(set(records) == expected_units | expected_ui, "Executed methods do not equal complete unit target plus assigned UI classes")
    expected_skips = set(targets[UI_TARGET][CRAWL_CLASS]) & expected_ui
    actual_skips = {method for method, record in records.items() if record["result"] == "Skipped"}
    require(actual_skips == expected_skips, "Unexpected or missing crawler skips")
    for method in expected_skips:
        require(records[method]["skipMessages"] == [CRAWL_SKIP_REASON], "Crawler skip reason differs from its opt-in policy")
    require(summary.get("totalTestCount") == len(records) and summary.get("passedTests") == len(records) - len(actual_skips) and summary.get("skippedTests") == len(actual_skips), "Summary count differs from executed methods")
    parameterized = {method for method in expected_units if ":" in method.rsplit("/", 1)[1]}
    require(parameterized == set(arguments.values()), "Parameterized unit method is missing argument case results")
    xctest = re.findall(r"Test Suite 'GlassTableTests\.xctest' passed[^\n]*\n\s*Executed (\d+) tests, with 0 failures", log)
    swift = re.findall(r"Test run with (\d+) tests in \d+ suites passed", log)
    require(len(xctest) == 1 and len(swift) == 1, "Both unit framework completion markers are required")
    require(int(xctest[0]) + int(swift[0]) == len(expected_units), "Unit framework counts differ from discovered unit methods")
    return {
        "shardIndex": manifest["shardIndex"], "sha": manifest["sha"], "uiDigest": manifest["uiDigest"],
        "unitDigest": manifest["unitDigest"], "uiResults": {key: records[key] for key in sorted(expected_ui)},
        "unitResults": {key: records[key] for key in sorted(expected_units)}, "argumentCases": dict(sorted(arguments.items())),
        "unitFrameworkCounts": {"XCTest": int(xctest[0]), "SwiftTesting": int(swift[0])}, "device": device,
    }


def aggregate(reports_dir, job_status, sha):
    require(job_status == "success", f"Required shard jobs were {job_status}, not successful")
    manifest_paths = sorted(Path(reports_dir).glob("*/manifest.json"))
    require(len(manifest_paths) == SHARD_COUNT, "Exactly three shard manifests are required")
    manifests, reports = {}, {}
    for path in manifest_paths:
        manifest = read_json(path)
        validate_manifest(manifest)
        index = manifest["shardIndex"]
        require(index not in manifests, "Duplicate shard manifest")
        report = read_json(path.with_name("report.json"))
        require(report["shardIndex"] == index and report["sha"] == manifest["sha"] == sha, "Shard result commit or index mismatch")
        require(report["uiDigest"] == manifest["uiDigest"] and report["unitDigest"] == manifest["unitDigest"], "Shard result digest mismatch")
        manifests[index], reports[index] = manifest, report
    require(set(manifests) == set(range(SHARD_COUNT)), "Missing shard index")
    first = manifests[0]
    for index in range(1, SHARD_COUNT):
        for key in ["sha", "xcode", "runtime", "model", "targets", "uiDigest", "unitDigest", "assignments"]:
            require(manifests[index][key] == first[key], f"Shard {key} differs")
        for key in ["unitResults", "argumentCases", "unitFrameworkCounts"]:
            require(reports[index][key] == reports[0][key], f"Shard {key} differs")
    actual = {}
    for index, report in reports.items():
        expected = {method for name in manifests[index]["assignedClasses"] for method in first["targets"][UI_TARGET][name]}
        require(set(report["uiResults"]) == expected, "Shard report UI coverage mismatch")
        require(not set(actual) & set(report["uiResults"]), "Duplicate UI execution across shards")
        actual.update(report["uiResults"])
        units = {method for methods in first["targets"][UNIT_TARGET].values() for method in methods}
        require(set(report["unitResults"]) == units, "Aggregate unit coverage is incomplete")
        require(sum(report["unitFrameworkCounts"].values()) == len(units) and set(report["unitFrameworkCounts"]) == {"XCTest", "SwiftTesting"}, "Aggregate unit framework counts differ")
        parameterized = {method for method in units if ":" in method.rsplit("/", 1)[1]}
        require(set(report["argumentCases"].values()) == parameterized and all("?args=" in identifier for identifier in report["argumentCases"]), "Aggregate parameterized coverage is incomplete")
    expected = {method for methods in first["targets"][UI_TARGET].values() for method in methods}
    require(set(actual) == expected, "Aggregate UI coverage is incomplete")
    require(all(record["result"] == "Passed" for record in reports[0]["unitResults"].values()), "Unsuccessful aggregate unit result")
    skipped = {method for method, record in actual.items() if record["result"] == "Skipped"}
    require(skipped == set(first["targets"][UI_TARGET][CRAWL_CLASS]), "Aggregate skip policy mismatch")
    require(all(actual[method]["skipMessages"] == [CRAWL_SKIP_REASON] for method in skipped), "Aggregate crawler skip reason mismatch")
    require(all(record["result"] in {"Passed", "Skipped"} for record in actual.values()), "Unsuccessful aggregate UI result")
    return {"sha": sha, "uiMethods": len(actual), "uiPassed": len(actual) - len(skipped), "uiSkipped": len(skipped), "unitMethodsPerShard": len(reports[0]["unitResults"]), "unitFrameworkCounts": reports[0]["unitFrameworkCounts"], "unitArgumentCasesPerShard": len(reports[0]["argumentCases"]), "uiDigest": first["uiDigest"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    assign = sub.add_parser("assign")
    for name in ["enumeration", "sha", "xcode-version-file", "runtime", "model", "manifest", "skip-file"]:
        assign.add_argument(f"--{name}", required=True)
    assign.add_argument("--shard", type=int, required=True)
    report = sub.add_parser("report")
    for name in ["manifest", "tests", "summary", "log", "app-outcome", "output"]:
        report.add_argument(f"--{name}", required=True)
    combine = sub.add_parser("aggregate")
    for name in ["reports-dir", "job-status", "sha", "output"]:
        combine.add_argument(f"--{name}", required=True)
    args = parser.parse_args()
    if args.command == "assign":
        manifest = make_manifest(read_json(args.enumeration), args.shard, args.sha, Path(args.xcode_version_file).read_text().strip(), args.runtime, args.model)
        write_json(args.manifest, manifest)
        skipped = sorted(set(manifest["targets"][UI_TARGET]) - set(manifest["assignedClasses"]))
        Path(args.skip_file).write_text("".join(f"{UI_TARGET}/{name}\n" for name in skipped))
        print(f"Shard {args.shard}: {manifest['assignedClasses']}; UI digest {manifest['uiDigest']}")
    elif args.command == "report":
        write_json(args.output, reconcile(read_json(args.manifest), read_json(args.tests), read_json(args.summary), Path(args.log).read_text(), args.app_outcome))
    else:
        result = aggregate(args.reports_dir, args.job_status, args.sha)
        write_json(args.output, result)
        print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, TypeError, OSError) as error:
        print(f"CI coverage validation failed: {error}", file=sys.stderr)
        sys.exit(1)

import XCTest
final class HelpCompletionProbeTests: XCTestCase {
 func testPositionExampleCompletion() throws {
  continueAfterFailure = false
  let out = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("C009-probe")
  try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
  print("C009_OUT=\(out.path)")
  var events: [[String:Any]] = []
  func snap(_ app: XCUIApplication, _ name: String, _ data: [String:Any] = [:]) throws {
   try app.screenshot().pngRepresentation.write(to: out.appendingPathComponent(name + ".png"))
   var e = data; e["state"] = name; e["buttons"] = app.buttons.matching(NSPredicate(format: "identifier == %@ OR label == %@ OR label == %@", "walkthrough-reveal", "I understand", "이해했어요")).allElementsBoundByIndex.map { ["label":$0.label,"id":$0.identifier,"enabled":$0.isEnabled,"hittable":$0.isHittable] }; events.append(e)
   try JSONSerialization.data(withJSONObject: events, options: [.prettyPrinted,.sortedKeys]).write(to: out.appendingPathComponent("events.json"))
  }
  for (config,lang,appearance) in [("en-dark","english","dark"),("ko-light","korean","light")] {
   let app = XCUIApplication(); app.launchArguments = ["-glassTable.language",lang,"-appAppearance",appearance]
   app.launchEnvironment = ["GT_TEST_STORE_ID":UUID().uuidString,"GT_TEST_FIRST_LESSON":"0","GT_DEMO_NODE":"u1-position"]
   app.launch(); let info = app.buttons["drill-explain"]; XCTAssertTrue(info.waitForExistence(timeout:15)); info.tap()
   let example = app.buttons["explain-example"]
   for _ in 0..<6 where !example.isHittable { app.swipeUp() }
   XCTAssertTrue(example.isHittable); example.tap()
   let nextLabel = lang == "english" ? "Next" : "다음"
   let finishLabel = lang == "english" ? "I understand" : "이해했어요"
   for step in 0..<12 {
    let finish = app.buttons[finishLabel]; let next = app.buttons[nextLabel]
    let reveal = app.buttons["walkthrough-reveal"]
    try snap(app,"\(config)-step-\(step)",["finishExists":finish.exists,"finishEnabled":finish.exists && finish.isEnabled,"revealExists":reveal.exists,"seedCount":0])
    if reveal.exists { reveal.tap(); try snap(app,"\(config)-step-\(step)-revealed") }
    if finish.exists {
     XCTAssertTrue(finish.isEnabled); finish.tap()
     XCTAssertTrue(example.waitForExistence(timeout:5)); XCTAssertTrue(example.isHittable)
     try snap(app,"\(config)-finished-explanation",["expected":"explain-example hittable","actual":example.isHittable])
     break
    }
    XCTAssertTrue(next.isEnabled); next.tap()
   }
   example.tap(); let back = app.buttons[lang == "english" ? "Back to explanation" : "설명으로"]
   XCTAssertTrue(back.waitForExistence(timeout:5)); back.tap(); XCTAssertTrue(example.waitForExistence(timeout:5)); try snap(app,"\(config)-back-explanation")
   example.tap(); let close = app.buttons.matching(NSPredicate(format: "label == %@", lang == "english" ? "Close" : "닫기")).allElementsBoundByIndex.first(where: { $0.isHittable })!
   XCTAssertTrue(close.waitForExistence(timeout:5)); close.tap(); XCTAssertTrue(info.waitForExistence(timeout:5)); try snap(app,"\(config)-close-question")
   app.terminate()
  }
 }
}

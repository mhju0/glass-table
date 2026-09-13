// Copyright (c) 2026 Michael Ju (github.com/mhju0)
// Release timing sample; measurements are not device-independent pass thresholds.
import Foundation
import GlassTableEngine
import GlassTableDrills
func now() -> UInt64 { DispatchTime.now().uptimeNanoseconds }
func ms(_ n: UInt64) -> Double { Double(n) / 1_000_000 }
func measure(_ name: String, _ body: (UInt64) -> Void) {
    var values: [Double] = []; values.reserveCapacity(1000)
    for i in 0..<1000 { let s = now(); body(UInt64(i)); values.append(ms(now() - s)) }
    let sorted = values.sorted()
    print(String(format: "%@ n=1000 p50=%.3fms p95=%.3fms max=%.3fms total=%.1fms", name, sorted[500], sorted[949], sorted[999], values.reduce(0,+)))
}
let b: UInt64 = 0x5eed
measure("showdown+grade") { let s=ShowdownSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeShowdown(answer:s.winner,spot:s) }
measure("potmath+grade") { let s=PotMathSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradePotMath(answer:s.correctAnswer,spot:s) }
measure("position+grade") { let s=PositionSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradePosition(answer:s.correctAnswer,spot:s) }
measure("equity-sense+grade") { let s=EquitySenseSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeEquitySense(estimate:Estimate(point:50,lo:40,hi:60),spot:s) }
measure("ev-call+grade") { let s=EVCallSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeEVCall(estimate:Estimate(point:50,lo:40,hi:60),spot:s) }
measure("outs+grade") { let s=OutsSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeOuts(estimate:s.outCount,spot:s) }
measure("pot-odds+grade") { let s=BetSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradePotOdds(estimatePct:Int(s.requiredPct.rounded()),spot:s) }
measure("mdf+grade") { let s=BetSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeMDF(estimatePct:Int(s.mdfPct.rounded()),spot:s) }
measure("call-fold+grade") { let s=CallFoldSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeCallFold(userCalls:s.correctIsCall,spot:s) }
measure("range-notation+grade") { let s=RangeNotationSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeRangeNotation(estimate:s.comboCount,spot:s) }
measure("rfi+grade") { let s=RFISpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeRFI(userOpens:s.opens,spot:s) }
measure("range-read+grade") { let s=RangeReadSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeRangeRead(estimate:RangeEstimate(width:s.trueRange.percent),spot:s) }
measure("hit-frequency+grade") { let s=HitFrequencySpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeHitFrequency(estimate:Estimate(point:s.pairOrBetterPct,lo:0,hi:100),spot:s) }
measure("range-advantage+grade") { let s=RangeAdvantageSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeRangeAdvantage(estimate:Estimate(point:s.openerEquityPct,lo:0,hi:100),spot:s) }
measure("ev-loss+grade") { let s=EVLossSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeEVLoss(userCalls:s.callEVbb > 0,spot:s) }
measure("action-read+grade") { let s=ActionReadSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeActionRead(estimate:Estimate(point:s.pairOrBetterPct,lo:0,hi:100),spot:s) }
measure("defend+grade") { let s=DefendSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeDefend(chosen:s.correct,spot:s) }
measure("blocker+grade") { let s=BlockerSpotGenerator.spot(baseSeed:b,index:Int($0)); _=gradeBlocker(estimate:s.count,spot:s) }
var state = ProgressState()
for i in 0..<500 { state.append(AnswerRecord(concept:.potOdds,at:Date(timeIntervalSince1970:TimeInterval(i)),correct:i % 2 == 0)) }
let directory = FileManager.default.temporaryDirectory.appendingPathComponent("glass-table-perf-" + UUID().uuidString)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: directory) }
let store = ProgressionStore(url: directory.appendingPathComponent("progression.json"))
let encoded = try store.exportData(state)
print("state bytes=\(encoded.count)")
measure("encode-500") { _ in _ = try! store.exportData(state) }
measure("atomic-save-500") { _ in try! store.save(state) }

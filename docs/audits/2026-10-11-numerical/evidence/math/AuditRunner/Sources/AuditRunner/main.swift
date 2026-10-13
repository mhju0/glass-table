import Foundation
import GlassTableEngine
import GlassTableDrills

func emit(_ value: [String: Any]) { let d = try! JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]); print(String(decoding: d, as: UTF8.self)) }
// Independent rule classifier: ranks grouped in arrays and compared lexicographically.
func rank5(_ cards: [Card]) -> [Int] {
    let ranks = cards.map(\.rank).sorted(by: >)
    let distinct = Array(Set(ranks)).sorted(by: >)
    let flush = Set(cards.map(\.suit)).count == 1
    var straight = 0
    if distinct.count == 5 {
        if distinct[0] - distinct[4] == 4 { straight = distinct[0] }
        if distinct == [14,5,4,3,2] { straight = 5 }
    }
    // Count with named captures so each group is independent of the engine's bit packing.
    let g = distinct.map { r in (r, ranks.filter { $0 == r }.count) }.sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0 > $1.0 }
    let multiplicities = g.map { $0.1 }
    let category: Int
    if flush && straight > 0 { category = 8 }
    else if multiplicities == [4,1] { category = 7 }
    else if multiplicities == [3,2] { category = 6 }
    else if flush { category = 5 }
    else if straight > 0 { category = 4 }
    else if multiplicities == [3,1,1] { category = 3 }
    else if multiplicities == [2,2,1] { category = 2 }
    else if multiplicities == [2,1,1,1] { category = 1 }
    else { category = 0 }
    return [category] + ((category == 8 || category == 4) ? [straight] : g.map { $0.0 })
}
func greater(_ a: [Int], _ b: [Int]) -> Bool { b.lexicographicallyPrecedes(a) }
func rankAny(_ cards: [Card]) -> [Int] {
    var best = [Int]()
    for a in 0..<(cards.count-4) { for b in (a+1)..<(cards.count-3) { for c in (b+1)..<(cards.count-2) { for d in (c+1)..<(cards.count-1) { for e in (d+1)..<cards.count {
        let x = rank5([cards[a],cards[b],cards[c],cards[d],cards[e]])
        if greater(x,best) { best = x }
    } } } } }
    return best
}
func independentEquity(_ h: [Card], _ v: [Card], _ board: [Card]) -> (Int,Int,Int) {
    let known = Set(h+v+board), left = Deck.all.filter { !known.contains($0) }
    var wins=0,ties=0,n=0
    func score(_ b: [Card]) { let a=rankAny(h+b), z=rankAny(v+b); wins += greater(a,z) ? 1:0; ties += a == z ? 1:0; n += 1 }
    if board.count == 5 { score(board) }
    else if board.count == 4 { for c in left { score(board+[c]) } }
    else { for i in 0..<(left.count-1) { for j in (i+1)..<left.count { score(board+[left[i],left[j]]) } } }
    return (wins,ties,n)
}
var counts = [Int](repeating:0,count:9), mismatch5=0
let deck=Deck.all
for a in 0..<48 { for b in (a+1)..<49 { for c in (b+1)..<50 { for d in (c+1)..<51 { for e in (d+1)..<52 {
    let cs=[deck[a],deck[b],deck[c],deck[d],deck[e]], ref=rank5(cs), got=bestHandOfAny(cs)
    counts[ref[0]] += 1
    if got.category != ref[0] || got.topRank != ref[1] { mismatch5 += 1 }
} } } } }
emit(["gate":"full5","counts":counts,"total":counts.reduce(0,+),"categoryTopMismatches":mismatch5])
var rng=SplitMix64(seed:0xA0D17), mismatch7=0, equityMismatch=0
for i in 0..<1000 {
    let cs=deck.shuffled(using:&rng), h=Array(cs[0..<2]),v=Array(cs[2..<4]),board=Array(cs[4..<9])
    let ref=rankAny(h+board), got=bestHand(h+board)
    if got.category != ref[0] || got.topRank != ref[1] { mismatch7 += 1 }
    let b = i < 10 ? Array(board.prefix(3)) : (i < 110 ? Array(board.prefix(4)) : board)
    let x=independentEquity(h,v,b), y=exactEquityHeadsUp(hero:h,villain:v,board:b)
    if x.0 != y.wins || x.1 != y.ties || x.2 != y.total { equityMismatch += 1 }
}
emit(["gate":"independentEquityAnd7","random7":1000,"flop":10,"turn":100,"river":890,"mismatches7":mismatch7,"mismatchesEquity":equityMismatch])
for seat in Position.preflopOrder {
    let r=RFIChart.range(for:seat), t=DefendChart.threeBetRange(vsOpenFrom:seat), c=DefendChart.callRange(vsOpenFrom:seat)
    emit(["gate":"chart","seat":seat.rawValue,"target":RFIChart.openPercent[seat] ?? 0,"classes":r.classes.count,"combos":r.comboCount,"actualPercent":r.percent,"threeBetCombos":t.comboCount,"callCombos":c.comboCount,"foldCombos":1326-t.comboCount-c.comboCount,"hands":r.classes.map(\.description)])
}
for h in HandClass.all.sorted() {
    var seats=[String:Any]()
    for seat in Position.preflopOrder {seats[seat.rawValue] = ["rfi":RFIChart.range(for:seat).weight(h),"defend":DefendChart.action(for:h.combos()[0],vsOpenFrom:seat).rawValue]}
    emit(["gate":"chartMapping","hand":h.description,"comboCount":h.comboCount,"chen":Chen.score(h),"seats":seats])
}
for arch in Archetype.allCases + [.casual] {
    var vp=0.0,pf=0.0
    for seat in RFIChart.seats {
        let play=arch.playRange(from:seat), raise=arch.raiseRange(from:seat), call=arch.callRange(from:seat), cont=arch.continueRange(vs3BetFrom:seat)
        vp += play.percent; pf += raise.percent
        emit(["gate":"archetype","style":arch.rawValue,"seat":seat.rawValue,"playCombos":play.comboCount,"raiseCombos":raise.comboCount,"callCombos":call.comboCount,"continueCombos":cont.comboCount,"partition":play.comboCount == raise.comboCount+call.comboCount,"nested":cont.subtracting(raise).isEmpty])
    }
    emit(["gate":"archetypeMean","style":arch.rawValue,"targetVPIP":arch.vpip,"actualVPIP":vp/7,"targetPFR":arch.pfr,"actualPFR":pf/7,"checkedToRaisingBuckets":arch.postflop.raises.subtracting(arch.postflop.bets).map(\.rawValue)])
}
var outsMismatch=0, ahead=0, tied=0,excludedTies=0,madeFlushSpots=0
for i in 0..<1000 {
    let s=OutsSpotGenerator.spot(baseSeed:0xA0D17,index:i), a=rankAny(s.hero+s.board),z=rankAny(s.villain+s.board)
    let x=independentEquity(s.hero,s.villain,s.board)
    if x.0 != s.outCount { outsMismatch += 1 }
    if greater(a,z) { ahead += 1; if ahead <= 3 { emit(["gate":"outsAheadExample","index":i,"hero":s.hero.map(\.description),"villain":s.villain.map(\.description),"board":s.board.map(\.description),"heroNow":a,"villainNow":z,"outs":s.outCount]) } }
    if a == z { tied += 1; if tied <= 3 { emit(["gate":"outsTiedExample","index":i,"hero":s.hero.map(\.description),"villain":s.villain.map(\.description),"board":s.board.map(\.description),"currentRank":a,"outs":s.outCount]) } }
    if a[0] == 5 || a[0] == 8 {madeFlushSpots += 1}
    for river in s.excluded where rankAny(s.hero+s.board+[river]) == rankAny(s.villain+s.board+[river]) {
        excludedTies += 1
        if excludedTies <= 3 {emit(["gate":"excludedTieExample","index":i,"hero":s.hero.map(\.description),"villain":s.villain.map(\.description),"board":s.board.map(\.description),"excludedRiver":river.description,"rank":rankAny(s.hero+s.board+[river])])}
    }
}
emit(["gate":"outs","cases":1000,"winningCountMismatches":outsMismatch,"currentlyAhead":ahead,"currentlyTied":tied,"excludedTies":excludedTies,"alreadyMadeFlush":madeFlushSpots])
var checks=0,failures=0
for players in 2...4 { for stack in [2,3,7,40,100] { for seed in 0..<50 {
    var table=PracticeTableState(seed:UInt64(seed),styles:Array([Archetype.casual,.tag,.station].prefix(players-1)),handID:"audit",startingStack:stack)
    let initial=players*stack
    var turn=0
    while table.street != .finished && turn < 200 {
        if table.seats.reduce(0,{$0+$1.stack})+table.pot != initial { failures += 1 }
        let actions=table.legalActions,action=actions[Int(rng.next()%UInt64(actions.count))]
        try! table.apply(action,actionID:"a\(turn)"); turn += 1; checks += 1
    }
    let rev=table.review!
    if rev.endingStacks.reduce(0,+) != initial || rev.contributions.reduce(0,+) != rev.refunds.reduce(0,+)+rev.payouts.reduce(0,+) { failures += 1 }
    for n in 0...table.replaySteps.count { let f=table.frame(after:n); if f.stacks.reduce(0,+)+f.pot != initial { failures += 1 } }
    try! table.validate()
} } }
emit(["gate":"practiceConservation","hands":750,"actions":checks,"failures":failures,"players":[2,3,4],"stacks":[2,3,7,40,100],"replayAndValidate":true])
var headsUp=0,headFail=0
for arch in Archetype.allCases { for i in 0..<100 {
    var t=TableDealer.deal(baseSeed:0xA0D17,index:i,villain:arch)
    var turns=0
    while !t.choices().isEmpty && turns<30 {
        if abs(t.pot+t.heroStack+t.villainStack-201.5)>1e-8 { headFail += 1 }
        let choices=t.choices();t.play(choices[Int(rng.next()%UInt64(choices.count))]);turns += 1
    }
    if case let .over(outcome)=t.phase { if abs((t.heroStack + (outcome.heroNet+t.heroInvested))-100-outcome.heroNet)>1e-8 {headFail += 1} }
    else { headFail += 1 }
    headsUp += 1
} }
emit(["gate":"headsUpConservation","hands":headsUp,"failures":headFail])
var topDifferences=0
for h in HandClass.all {
    let rank=Chen.ranked.firstIndex(of:h)!, prefix=Chen.ranked.prefix(rank+1).reduce(0){$0+$1.comboCount}
    let allTies=HandClass.all.filter{Chen.score($0)>=Chen.score(h)}.reduce(0){$0+$1.comboCount}
    if prefix != allTies { topDifferences += 1 }
    if ["22","76s","A9o","72o","AKs"].contains(h.description) { emit(["gate":"topPercentTies","hand":h.description,"chen":Chen.score(h),"prefixCombos":prefix,"sameOrBetterScoreCombos":allTies,"displayed":Int((100*Double(prefix)/1326).rounded()),"scoreThresholdPercent":100*Double(allTies)/1326]) }
}
emit(["gate":"topPercentTieSummary","differentClasses":topDifferences,"totalClasses":169])
var blockedFailures=0,comboChecks=0
let deadSamples = [[Card]()] + Deck.all.map {[$0]} + (0..<100).map{_ in Array(Deck.all.shuffled(using:&rng).prefix(7))}
for dead in deadSamples {
    let remaining=Deck.all.filter{!dead.contains($0)}
    var independent=[HandClass:Int]()
    for a in 0..<(remaining.count-1) {for b in (a+1)..<remaining.count {independent[HandClass([remaining[a],remaining[b]])!,default:0] += 1}}
    for h in HandClass.all {if h.combos(removing:Set(dead)).count != independent[h,default:0] {blockedFailures += 1};comboChecks += 1}
}
emit(["gate":"blockedCombos","deadSets":deadSamples.count,"classChecks":comboChecks,"mismatches":blockedFailures,"totalClasses":HandClass.all.count,"weightedCombos":HandClass.all.reduce(0){$0+$1.comboCount}])
var mathChecks=0,mathFailures=0
for p in 0...100 {for b in 1...100 {for e in [0.0,0.25,0.5,0.75,1.0] {
    let ev=e*Double(p+2*b)-Double(b)
    if abs(callEV(equity:e,toCall:Double(b),pot:Double(p+b))-ev)>1e-10 {mathFailures += 1}
    if abs(requiredEquity(toCall:Double(b),pot:Double(p+b))-Double(b)/Double(p+2*b))>1e-12 {mathFailures += 1}
    if abs(mdf(bet:Double(b),pot:Double(p))-Double(p)/Double(p+b))>1e-12 {mathFailures += 1}
    mathChecks += 3
}}}
emit(["gate":"potOddsEVmdf","checks":mathChecks,"mismatches":mathFailures])
var sampleMax=0.0,sampleCount=0
for i in 0..<15 {
    let cs=deck.shuffled(using:&rng),h=Array(cs[0..<2]),v=Array(cs[2..<4]),b=Array(cs[4..<7])
    let exact=independentEquity(h,v,b),truth=(Double(exact.0)+Double(exact.1)/2)/Double(exact.2)
    let sampled=monteCarloEquityHeadsUp(hero:h,villain:v,board:b,iterations:100000,seed:UInt64(i))
    let again=monteCarloEquityHeadsUp(hero:h,villain:v,board:b,iterations:100000,seed:UInt64(i))
    if sampled.wins != again.wins || sampled.ties != again.ties {fatalError("MC nondeterminism")}
    sampleMax=max(sampleMax,abs(sampled.equity-truth));sampleCount += 1
}
emit(["gate":"independentMC","spots":sampleCount,"samplesEach":100000,"maxAbsoluteErrorPP":sampleMax*100,"repeatIdentical":true])
let wh=HandClass.all.first{$0.description=="AA"}!,wl=HandClass.all.first{$0.description=="22"}!
let pure=HandRange([wh:1,wl:1]),mixed=HandRange([wh:1,wl:0.01]),heroR=HandRange([HandClass.all.first{$0.description=="KK"}!])
let dry=Card.parse("3c5d7h9sJc")!
emit(["gate":"mixedWeightsIgnored","pureCombos":pure.comboCount,"mixedWeightedCombos":mixed.comboCount,"pureExpandedCombos":pure.combos().count,"mixedExpandedCombos":mixed.combos().count,"pureEquity":rangeEquity(hero:heroR,villain:pure,board:dry,samples:100000,seed:42),"mixedEquity":rangeEquity(hero:heroR,villain:mixed,board:dry,samples:100000,seed:42),"trueMixedEquity":0.01/1.01])

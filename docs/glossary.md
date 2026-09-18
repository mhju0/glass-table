# Korean terminology glossary

The canonical term table promised by decision F (`decisions.md`) — built during the M1
UI-copy pass, applied to all UI strings from here on. Confirmed against real Korean
usage (pokergosu, CoinPoker KR glossary, namu.wiki).

## Rules

1. **Actions & streets: always Hangul.** 콜 · 레이즈 · 폴드 · 체크 · 벳 · 올인 ·
   프리플랍 · 플랍 · 턴 · 리버. Use **플랍**, not 플롭. **3벳/4벳** = digit + Hangul.
2. **Acronyms & positions: always Latin.** GTO · EV · MDF · SB · BB · UTG · HJ · CO ·
   BTN. **TAG/LAG stay Latin** (태그/래그 collide with everyday "tag"/"lag").
3. **Learning-critical concept terms: bilingual at first sight.** Show the Hangul term
   with its English pair (muted caption or English sub-line) the first place a screen
   introduces it — users meet these words in English solver tools.
4. **Grade bands:** 정확 (spot-on) · 근접 (close) · 다시 살펴볼까요? (off).
   The last label invites reviewing the explanation; underlying grading is unchanged.

## Term table

| Korean | English | Class | Note |
|---|---|---|---|
| 콜 / 폴드 / 체크 / 벳 / 레이즈 / 올인 | call / fold / check / bet / raise / all-in | action | Hangul only |
| 프리플랍 / 플랍 / 턴 / 리버 | preflop / flop / turn / river | street | Hangul only; 플랍 not 플롭 |
| 에퀴티 | equity | concept | bilingual |
| 팟 오즈 | pot odds | concept | bilingual |
| 블로커 | blocker | concept | bilingual |
| 아웃 | out(s) | concept | bilingual (아웃 카운팅 · Outs) |
| 콤보 | combo | concept | bilingual on first sight |
| 레인지 | range | concept | bilingual on first sight |
| MDF | minimum defense frequency | acronym | Latin; long form 최소 방어 빈도 as subtitle |
| EV / GTO | — | acronym | Latin only |
| 팟 / 벳 (sizing) | pot / bet | noun | Hangul; `bb` for blind-normalized amounts, 칩 for the pot-counting exercise |
| 보드 / 공용 카드 | board | noun | Use 공용 카드 for the card-zone label |
| 핸드 | hand | noun | Use 내 카드 / 상대 카드 for card-zone labels |
| 룰 오브 2/4 | rule of 2/4 | concept | Hangul transliteration |
| 스트릭 | streak | UI | shown as 🔥 + number, no word |
| 정확 / 근접 / 다시 살펴볼까요? | spot-on / close / off | grade band | display labels; no grading change |
| 따라 배우기 | worked guide | learning mode | replaces 천천히 in mode labels |
| 무승부 | tie / chop | outcome | plain-language answer label |
| VPIP / PFR | voluntarily put in pot / preflop raise | acronym | Latin; archetype stats on the 테이블 picker |
| 3벳 | 3-bet | action | digit + Hangul per decisions.md §F |
| bb | big blind | unit | Latin lowercase; one big blind, never label a 1/2 chip blind structure as 1/2bb |
| 칩 | chips | unit | Pot calculation counts whole chips with 1-chip SB / 2-chip BB; fraction answers round to a whole chip |
| 디펜드 차트 | defend chart | concept | vs an open: 3벳/콜/폴드 bands |
| 최선 / 거의 최선 / 부정확 / 실수 | best / near-best / inaccuracy / mistake | EV-loss display | 0bb is 최선; a positive loss up to 0.5bb is 거의 최선; the first two share the best progression band |

# C002 — More varied start-guide comparisons

Current source has two pair-vs-pair cases: A pair versus K pair, then 8 pair versus 10 pair (`GlassTableDrills/Sources/GlassTableDrills/FirstLesson.swift:4–22`). The existing copy deliberately teaches the higher-pair rule. Preserve the simple first example, then consider three later transfer questions teaching different hand categories.

Proposed seven-card comparisons (not implemented or runtime-validated):

1. Hero 7♥7♣ versus K♦K♣; shared 7♠2♦4♣9♥Q♠. Three sevens beats a pair of kings. EN: Three of a kind beats a higher pair. KO: 트리플이 더 높은 원 페어를 이겨요.
2. Hero 9♥8♦ versus Q♣Q♦; shared 7♠6♥5♣2♦Q♥. A 5–9 straight beats three queens. EN: A straight beats three of a kind. KO: 스트레이트가 트리플보다 높아요.
3. Hero A♦J♦ versus 6♣Q♣; shared 7♦8♦9♦10♦2♣. An ace-high diamond flush beats the opponent's 6–10 straight. EN: A flush beats a straight. KO: 플러시가 스트레이트보다 높아요.

Each spot has nine distinct cards and keeps two private + five shared cards. Verify the exact best five with the existing engine before implementation. Do not disclose winners before answer commitment. Consider whether all three should be required or offered as later transfer/replay to avoid lengthening first launch unnecessarily. Existing HoldemBasicsContent already explains these categories and has a flush-versus-straight check.

Primary sources gathered by the research agent:
- PokerStars rules, hand rankings: https://www.pokerstars.com/poker/games/rules/hand-rankings/
- PokerStars lesson: https://www.pokerstars.com/poker/learn/lesson/poker-hand-rankings/
- WSOP structure sheet, Hold'em format: https://www.wsop.com/pdfs/structuresheets/structure_5219_21748.pdf

These sources support best-five selection and category ordering. Avoid claims that straights/flushes are the most common hands or equating five-card frequencies with Hold'em seven-card frequencies. No frequency claim is needed for this teaching progression. Hand variety and improved beginner understanding still require user testing.

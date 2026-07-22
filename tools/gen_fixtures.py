# Copyright (c) 2026 Michael Ju (github.com/mhju0)
# Dev-time only (NOT shipped). Generates oracle fixtures with the eval7 reference engine.
#   python3 -m pip install --user eval7
#   python3 tools/gen_fixtures.py > GlassTableEngine/Tests/GlassTableEngineTests/Fixtures/random_spots.json
#
# eval7 API notes (verified against eval7 0.1.10, the installed version):
#   * Card string form is "As" via str(card); eval7's internal rank ints (A==12) are unused here.
#   * Hand-vs-hand equity = py_hand_vs_range_monte_carlo(hero_cards, villain_range, board, iters),
#     where villain_range is an eval7.HandRange built from the villain's two-card string ("KsKh").
#   * eval7's py_hand_vs_range_exact is UNRELIABLE for these inputs (returns 0/1 sentinels — e.g.
#     it reports 0.0 where the true one-card-runout equity is 0.0455), so Monte Carlo is the oracle
#     for every spot. This script IS the oracle; its output is trusted and the Swift engine is what
#     gets validated against it. The fixture is frozen once and checked in.
import json, random, eval7

random.seed(20260721)  # reproducible spot selection
ITERS = 200_000
RANKS = "23456789TJQKA"
SUITS = "cdhs"

def make_deck():
    return [eval7.Card(r + s) for r in RANKS for s in SUITS]

spots = []
for _ in range(500):
    deck = make_deck()
    random.shuffle(deck)
    hero = deck[0:2]
    villain = deck[2:4]
    n_board = random.choice([0, 3, 4])  # preflop, flop, turn
    board = deck[4:4 + n_board]
    villain_str = "".join(str(c) for c in villain)
    eq = eval7.py_hand_vs_range_monte_carlo(hero, eval7.HandRange(villain_str), board, ITERS)
    spots.append({
        "hero": "".join(str(c) for c in hero),
        "villain": villain_str,
        "board": "".join(str(c) for c in board),
        "equity": round(eq, 5),
    })

print(json.dumps(spots, indent=0))

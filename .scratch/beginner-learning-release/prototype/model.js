"use strict";

const GTModel = (() => {
  const ranks = "AKQJT98765432".split("");
  const hands = ranks.flatMap((row, r) => ranks.map((col, c) => {
    const label = r === c ? `${row}${col}` : r < c ? `${row}${col}s` : `${col}${row}o`;
    let action = r === c || r + c < 7 ? "raise" : r + c < 12 ? "call" : "fold";
    if (label === "J5o") action = "fold";
    return { label, action, row: r, col: c };
  }));

  const questions = [
    { board: ["A♠", "K♠", "9♦", "5♣", "2♥"], you: ["A♥", "Q♦"], them: ["K♥", "Q♣"], winner: "you", why: { ko: "당신은 에이스 한 쌍, 상대는 킹 한 쌍이에요.", en: "You have a pair of aces. The opponent has a pair of kings." } },
    { board: ["Q♣", "Q♦", "8♥", "5♠", "2♣"], you: ["A♠", "J♣"], them: ["K♥", "K♣"], winner: "them", why: { ko: "상대는 퀸 두 장에 킹 한 쌍까지 있어요.", en: "The opponent has two queens and a pair of kings." } },
    { board: ["A♣", "K♦", "Q♠", "J♥", "10♣"], you: ["2♠", "3♦"], them: ["4♥", "5♣"], winner: "tie", why: { ko: "공용 카드 다섯 장만으로 두 사람 모두 같은 스트레이트예요.", en: "The five shared cards make the same straight for both players." } },
    { board: ["9♣", "9♦", "3♥", "3♠", "K♣"], you: ["A♠", "2♦"], them: ["Q♥", "J♦"], winner: "you", why: { ko: "둘 다 9와 3으로 투페어예요. 내 에이스가 상대가 쓰는 공용 킹보다 높아요.", en: "Both have two pair, nines and threes. Your ace kicker beats the king on the board that your opponent uses." } },
    { board: ["2♣", "6♣", "8♣", "J♦", "K♥"], you: ["A♣", "5♣"], them: ["K♠", "Q♠"], winner: "you", why: { ko: "당신은 클럽 다섯 장으로 플러시예요. 상대는 킹 한 쌍이에요.", en: "You make a club flush. The opponent has a pair of kings." } }
  ];

  const tableEvents = [
    { seat: "a", paid: 1, street: "pre", ko: "작은 블라인드 1칩을 내요", en: "Posts the small blind, 1 chip" },
    { seat: "b", paid: 2, street: "pre", ko: "큰 블라인드 2칩을 내요", en: "Posts the big blind, 2 chips" },
    { seat: "c", paid: 0, street: "pre", ko: "이번 판은 접어요", en: "Folds this hand" },
    { seat: "you", paid: 2, street: "pre", ko: "2칩을 맞춰요", en: "Matches 2 chips" },
    { seat: "a", paid: 1, street: "pre", ko: "1칩을 더 내서 맞춰요", en: "Adds 1 chip to match" },
    { seat: "b", paid: 0, street: "pre", ko: "추가 칩 없이 넘겨요", en: "Checks without adding chips" },
    { seat: "a", paid: 0, street: "flop", ko: "넘겨요", en: "Checks" },
    { seat: "b", paid: 0, street: "flop", ko: "넘겨요", en: "Checks" },
    { seat: "you", paid: 0, street: "flop", ko: "넘겨요", en: "Checks" },
    { seat: "a", paid: 0, street: "turn", ko: "넘겨요", en: "Checks" },
    { seat: "b", paid: 0, street: "turn", ko: "넘겨요", en: "Checks" },
    { seat: "you", paid: 0, street: "turn", ko: "넘겨요", en: "Checks" },
    { seat: "a", paid: 0, street: "river", ko: "넘겨요", en: "Checks" },
    { seat: "b", paid: 0, street: "river", ko: "넘겨요", en: "Checks" },
    { seat: "you", paid: 0, street: "river", ko: "넘겨요", en: "Checks" }
  ];

  function tableAt(index) {
    const paid = { you: 0, a: 0, b: 0, c: 0 };
    for (let i = 0; i <= index; i++) paid[tableEvents[i].seat] += tableEvents[i].paid;
    return paid;
  }

  const sampleStyle = { hands: 120, days: 6, entries: 72, raises: 59, sample: true };

  return Object.freeze({ ranks, hands, questions, tableEvents, tableAt, sampleStyle });
})();

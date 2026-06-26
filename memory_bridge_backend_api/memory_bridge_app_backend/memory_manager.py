"""
memory_manager.py — Spaced-Repetition Memory Weighting

Each known person has a "difficulty weight" that controls how often they
appear as quiz subjects.  Answering correctly lowers the weight (person
is remembered well); answering incorrectly raises it.

This mirrors the SM-2 spaced-repetition algorithm used in Anki / flashcard apps,
adapted for faces rather than cards.
"""

from collections import defaultdict


class MemoryManager:
    """
    Tracks per-person difficulty weights.

    Weight semantics:
        High weight → patient struggles → person appears more often
        Low weight  → patient remembers → person appears less often

    The weight is used as a probability bias in random.choices() inside
    pick_next_face().

    Clinically, "important people" (e.g. spouse, primary caregiver) can be
    force-marked so they always appear with elevated probability regardless
    of correct-answer streaks.
    """

    DEFAULT_WEIGHT   = 1.0
    CORRECT_DECAY    = 0.85    # multiply weight by this on correct answer
    WRONG_BOOST      = 1.30    # multiply weight by this on wrong answer
    MIN_WEIGHT       = 0.3
    MAX_WEIGHT       = 5.0
    IMPORTANT_WEIGHT = 3.0     # minimum weight for important people

    def __init__(self):
        self._weights: dict[str, float]  = defaultdict(lambda: self.DEFAULT_WEIGHT)
        self.important_people: set[str]  = set()

    # ── Weight access ─────────────────────────────────────────────────────────

    def get_weight(self, person: str) -> float:
        w = self._weights[person]
        if person in self.important_people:
            w = max(w, self.IMPORTANT_WEIGHT)
        return w

    def get_all_weights(self) -> dict[str, float]:
        return {p: self.get_weight(p) for p in self._weights}

    # ── Update after each answer ──────────────────────────────────────────────

    def update(self, person: str, correct: bool):
        """Decay weight on correct, boost on wrong (spaced-repetition logic)."""
        w = self._weights[person]
        if correct:
            w *= self.CORRECT_DECAY
        else:
            w *= self.WRONG_BOOST
        w = max(self.MIN_WEIGHT, min(self.MAX_WEIGHT, w))
        self._weights[person] = w

    # ── Session management ────────────────────────────────────────────────────

    def reset_session(self):
        """Reset weights to defaults (but preserve important-people flag)."""
        self._weights = defaultdict(lambda: self.DEFAULT_WEIGHT)

    # ── Important people ──────────────────────────────────────────────────────

    def mark_important(self, person: str):
        self.important_people.add(person)
        self._weights[person] = max(self._weights[person], self.IMPORTANT_WEIGHT)

    def unmark_important(self, person: str):
        self.important_people.discard(person)

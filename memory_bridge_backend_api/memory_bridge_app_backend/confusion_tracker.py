"""
confusion_tracker.py — Face Confusion Pair Analytics

Records every wrong answer as a (guessed, actual) confusion pair.
Used to:
  1. Generate harder MCQ distractors (confusable people)
  2. Display analytics on the result and dashboard pages
  3. Guide caregivers on which people to re-introduce
"""

from collections import defaultdict


class ConfusionTracker:
    def __init__(self):
        # confusion_matrix[actual][guessed] = count
        self._matrix: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))

    def record(self, guessed: str, actual: str):
        """Record that the patient guessed `guessed` when the answer was `actual`."""
        if guessed and actual and guessed != actual:
            self._matrix[actual][guessed] += 1

    def most_confused_with(self, person: str, top_k: int = 5) -> list[str]:
        """Return names most often confused with `person` (sorted by count desc)."""
        confused = self._matrix.get(person, {})
        return sorted(confused, key=confused.get, reverse=True)[:top_k]

    def get_confusion_pairs(self, min_count: int = 1) -> list[dict]:
        """
        Return sorted list of confusion pairs for display.
        Format: [{"actual": ..., "guessed": ..., "count": ...}, ...]
        """
        pairs = []
        for actual, guesses in self._matrix.items():
            for guessed, count in guesses.items():
                if count >= min_count:
                    pairs.append({"actual": actual, "guessed": guessed, "count": count})
        return sorted(pairs, key=lambda x: -x["count"])

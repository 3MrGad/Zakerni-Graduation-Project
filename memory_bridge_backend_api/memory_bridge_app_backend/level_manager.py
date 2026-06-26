"""
level_manager.py — Adaptive Difficulty Controller

Three difficulty levels mirror common Alzheimer assessment stages:
  Level 1 (Gentle)   — easy distractors, longer time limit, hint after 5 s
  Level 2 (Standard) — default; some confusable distractors
  Level 3 (Advanced) — hardest distractors, shortest time limit

Level changes are triggered by performance streaks:
  3 consecutive correct   → level up
  3 consecutive incorrect → level down
"""


class LevelManager:
    LEVELS = {
        1: {"label": "Gentle",   "color": "#4CAF50", "time_limit": 60},
        2: {"label": "Standard", "color": "#FF9800", "time_limit": 45},
        3: {"label": "Advanced", "color": "#F44336", "time_limit": 30},
    }

    UPGRADE_STREAK   = 3
    DOWNGRADE_STREAK = 3

    def __init__(self, initial_level: int = 2):
        self.level          = max(1, min(3, initial_level))
        self._streak        = 0   # positive = correct streak, negative = wrong streak

    # ── Properties ────────────────────────────────────────────────────────────

    @property
    def label(self) -> str:
        return self.LEVELS[self.level]["label"]

    @property
    def color(self) -> str:
        return self.LEVELS[self.level]["color"]

    @property
    def time_limit(self) -> int:
        return self.LEVELS[self.level]["time_limit"]

    # ── Update ────────────────────────────────────────────────────────────────

    def update(self, correct: bool):
        if correct:
            self._streak = max(0, self._streak) + 1
            if self._streak >= self.UPGRADE_STREAK and self.level < 3:
                self.level  += 1
                self._streak = 0
        else:
            self._streak = min(0, self._streak) - 1
            if abs(self._streak) >= self.DOWNGRADE_STREAK and self.level > 1:
                self.level  -= 1
                self._streak = 0

    # ── Serialisation for Flask session ──────────────────────────────────────

    def to_dict(self) -> dict:
        return {"level": self.level, "streak": self._streak}

    @classmethod
    def from_dict(cls, d: dict) -> "LevelManager":
        lm          = cls(initial_level=d.get("level", 2))
        lm._streak  = d.get("streak", 0)
        return lm

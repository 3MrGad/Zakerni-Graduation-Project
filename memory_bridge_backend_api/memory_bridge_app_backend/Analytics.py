"""
analytics.py — Session & Performance Analytics

Persists game sessions to a JSON file and provides query helpers for:
  - Per-person accuracy (hardest / easiest people)
  - Session score history for trend charts
  - Daily score aggregation
  - Overall summary statistics
"""

import json
import os
from collections import defaultdict
from datetime import datetime
from pathlib import Path


ANALYTICS_FILE = Path(__file__).parent / "analytics_data.json"


class Analytics:
    def __init__(self):
        self._data = self._load()

    # ── Persistence ───────────────────────────────────────────────────────────

    def _load(self) -> dict:
        if ANALYTICS_FILE.exists():
            try:
                with open(ANALYTICS_FILE) as f:
                    return json.load(f)
            except Exception:
                pass
        return {"sessions": [], "answers": []}

    def _save(self):
        with open(ANALYTICS_FILE, "w") as f:
            json.dump(self._data, f, indent=2)

    # ── Recording ─────────────────────────────────────────────────────────────

    def record_answer(self, username: str, person: str, correct: bool,
                      response_time: float, guessed: str, level: int):
        """Append a single answer event."""
        self._data["answers"].append({
            "ts":       datetime.now().isoformat(),
            "user":     username,
            "person":   person,
            "correct":  correct,
            "time":     response_time,
            "guessed":  guessed,
            "level":    level,
        })
        self._save()

    def save_session(self, username: str, score: int, total: int,
                     avg_response_time: float, level_at_end: int,
                     confusion_pairs: list) -> dict:
        """Persist a completed game session and return daily score summary."""
        today   = datetime.now().strftime("%Y-%m-%d")
        session = {
            "ts":           datetime.now().isoformat(),
            "date":         today,
            "user":         username,
            "score":        score,
            "total":        total,
            "accuracy":     round(score / total * 100, 1) if total else 0,
            "avg_time":     avg_response_time,
            "level":        level_at_end,
        }
        self._data["sessions"].append(session)
        self._save()

        # Return today's aggregate
        today_sessions = [s for s in self._data["sessions"]
                          if s["user"] == username and s["date"] == today]
        return {
            "sessions_today": len(today_sessions),
            "best_today":     max((s["score"] for s in today_sessions), default=0),
        }

    # ── Query helpers ─────────────────────────────────────────────────────────

    def _person_stats(self) -> dict[str, dict]:
        """Aggregate correct/total per person across all answers."""
        stats: dict[str, dict] = defaultdict(lambda: {"correct": 0, "total": 0})
        for a in self._data["answers"]:
            p = a["person"]
            stats[p]["total"]   += 1
            stats[p]["correct"] += int(a["correct"])
        return stats

    def hardest_people(self, top_n: int = 3) -> list[dict]:
        """People with the lowest accuracy (most errors)."""
        stats = self._person_stats()
        ranked = sorted(
            [{"name": p, **v, "accuracy": round(v["correct"] / v["total"] * 100, 1)}
             for p, v in stats.items() if v["total"] >= 1],
            key=lambda x: x["accuracy"],
        )
        return ranked[:top_n]

    def easiest_people(self, top_n: int = 3) -> list[dict]:
        """People with the highest accuracy."""
        stats = self._person_stats()
        ranked = sorted(
            [{"name": p, **v, "accuracy": round(v["correct"] / v["total"] * 100, 1)}
             for p, v in stats.items() if v["total"] >= 1],
            key=lambda x: -x["accuracy"],
        )
        return ranked[:top_n]

    def daily_scores(self, last_n: int = 7) -> list[dict]:
        """Daily best score for chart display."""
        by_date: dict[str, int] = defaultdict(int)
        for s in self._data["sessions"]:
            by_date[s["date"]] = max(by_date[s["date"]], s["score"])
        sorted_dates = sorted(by_date.keys())[-last_n:]
        return [{"date": d, "score": by_date[d]} for d in sorted_dates]

    def accuracy_over_sessions(self, username: str, last_n: int = 10) -> list[dict]:
        """Per-session accuracy trend for a user."""
        user_sessions = [s for s in self._data["sessions"] if s["user"] == username]
        return [
            {"session": i+1, "accuracy": s["accuracy"]}
            for i, s in enumerate(user_sessions[-last_n:])
        ]

    def summary(self, username: str) -> dict:
        """Overall stats for a user."""
        sessions = [s for s in self._data["sessions"] if s["user"] == username]
        if not sessions:
            return {"total_sessions": 0, "avg_accuracy": 0, "best_score": 0}
        return {
            "total_sessions": len(sessions),
            "avg_accuracy":   round(sum(s["accuracy"] for s in sessions) / len(sessions), 1),
            "best_score":     max(s["score"] for s in sessions),
        }

"""
app.py — Memory Bridge Game - Flask API
متصل بـ MySQL (alzheimers_system_part2)

FIX list:
  1. _build_patient_cache now sets game_logic.KNOWN_DIR (was KNOWN_PEOPLE_DIR — wrong name)
  2. CACHE_FILE is now per-patient so two patients don't share one pickle
  3. Added /api/add_group_photo endpoint for caregiver to upload group photos
  4. _save_session_db / _update_session_db prevent duplicate inserts
  5. image_path returned from pick_next_face now uses patient-scoped URL
"""

import os, time, traceback, uuid, shutil
from pathlib import Path
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import mysql.connector

from memory_manager    import MemoryManager
from level_manager     import LevelManager
from confusion_tracker import ConfusionTracker
from game_logic        import build_cache, pick_next_face, check_answer

app = Flask(__name__)

CORS(app,
     origins="*",
     allow_headers=["Content-Type", "Authorization", "Accept"],
     methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
     supports_credentials=False)


@app.before_request
def handle_preflight():
    from flask import request as req
    if req.method == "OPTIONS":
        from flask import Response
        res = Response()
        res.headers["Access-Control-Allow-Origin"]  = "*"
        res.headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
        res.headers["Access-Control-Allow-Headers"] = "Content-Type,Authorization,Accept"
        return res


# ── MySQL Config ──────────────────────────────────────────────────────────────
DB_CONFIG = {
    "host":     "127.0.0.1",
    "port":     3306,
    "user":     "root",
    "password": "",
    "database": "alzheimers_system_part2",
    "charset":  "utf8mb4",
}

def get_db():
    return mysql.connector.connect(**DB_CONFIG)


# ── Upload folders ────────────────────────────────────────────────────────────
UPLOAD_FOLDER = Path("static/uploads")
UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)

TOTAL_QUESTIONS = 10

# ── Game states ───────────────────────────────────────────────────────────────
_game_states: dict = {}
_managers:    dict = {}

def get_managers(patient_id: int):
    if patient_id not in _managers:
        _managers[patient_id] = (MemoryManager(), ConfusionTracker())
    return _managers[patient_id]

print("\n[app] Starting…\n")


# ═════════════════════════════════════════════════════════════════════════════
#  Helpers
# ═════════════════════════════════════════════════════════════════════════════

def get_state(pid):     return _game_states.get(pid, {})
def save_state(pid, s): _game_states[pid] = s

def get_lm(state):
    return LevelManager.from_dict(state["lm"]) if state.get("lm") else LevelManager(2)

def init_state(patient_id: int) -> dict:
    mm, _ = get_managers(patient_id)
    mm.reset_session()
    state = {
        "patient_id":    patient_id,
        "score":         0,
        "question":      1,
        "feedback":      "",
        "show_hint":     False,
        "answer_times":  [],
        "shown_images":  [],
        "lm":            LevelManager(initial_level=2).to_dict(),
        "current_face":  {},
        "q_start":       time.time(),
        "level_msg":     None,
        "session_id":    None,
        "session_saved": False,
    }
    save_state(patient_id, state)
    return state

def pick_and_store(state: dict, patient_id: int) -> bool:
    try:
        mm, ct = get_managers(patient_id)
        lm     = get_lm(state)
        shown  = state.get("shown_images", [])

        _build_patient_cache(patient_id)

        face = pick_next_face(mm, lm, ct, shown)
        if face is None:
            return False

        shown.append(face.get("group_path", ""))
        state["shown_images"] = shown
        state["current_face"] = face
        state["lm"]           = lm.to_dict()
        return True
    except Exception as e:
        print(f"pick_and_store error: {e}")
        traceback.print_exc()
        return False


def _build_patient_cache(patient_id: int):
    """
    FIX: Sets game_logic.KNOWN_DIR (correct attribute name) and
         game_logic.CACHE_FILE to a per-patient path so multiple patients
         don't share the same pickle file.
    """
    try:
        db  = get_db()
        cur = db.cursor(dictionary=True)

        cur.execute("""
            SELECT kp.person_id, kp.name, pp.photo_path
            FROM known_people kp
            JOIN person_photos pp ON kp.person_id = pp.person_id
            WHERE kp.patient_id = %s
        """, (patient_id,))
        rows = cur.fetchall()
        cur.close()
        db.close()

        # ── Patient-scoped directories ────────────────────────────────────────
        patient_base = Path(f"static/patients/{patient_id}")
        known_dir    = patient_base / "known_people"
        group_dir    = patient_base / "group"
        current_dir  = patient_base / "current"
        models_dir   = Path("models") / f"patient_{patient_id}"

        for d in [known_dir, group_dir, current_dir, models_dir]:
            d.mkdir(parents=True, exist_ok=True)

        # Copy known-people photos into per-person sub-folders
        for row in rows:
            person_dir = known_dir / row["name"]
            person_dir.mkdir(exist_ok=True)
            src = Path(row["photo_path"])
            dst = person_dir / src.name
            if src.exists() and not dst.exists():
                shutil.copy(src, dst)

        # ── FIX: point game_logic globals to correct per-patient paths ────────
        import game_logic
        game_logic.KNOWN_DIR    = known_dir                          # was KNOWN_PEOPLE_DIR (wrong!)
        game_logic.GROUP_DIR    = group_dir
        game_logic.OUTPUT_IMAGE = current_dir / "face.jpg"
        game_logic.CACHE_FILE   = models_dir / "embeddings_cache.pkl"  # FIX: per-patient cache

        build_cache(force=True)

    except Exception as e:
        print(f"_build_patient_cache error: {e}")
        traceback.print_exc()


def _save_session_db(patient_id, state):
    if state.get("session_saved") and state.get("session_id"):
        return state["session_id"]
    try:
        times = state.get("answer_times", [])
        avg_t = round(sum(times) / max(len(times), 1), 2)
        db    = get_db()
        cur   = db.cursor()
        cur.execute("""
            INSERT INTO game_sessions (patient_id, score, total, accuracy, avg_time, level)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            patient_id,
            state.get("score", 0),
            TOTAL_QUESTIONS,
            round(state.get("score", 0) / TOTAL_QUESTIONS * 100, 1),
            avg_t,
            get_lm(state).level,
        ))
        session_id = cur.lastrowid
        db.commit()
        cur.close()
        db.close()
        state["session_id"]    = session_id
        state["session_saved"] = True
        return session_id
    except Exception as e:
        print(f"_save_session_db error: {e}")
        return None


def _update_session_db(session_id, state):
    try:
        times = state.get("answer_times", [])
        avg_t = round(sum(times) / max(len(times), 1), 2)
        db    = get_db()
        cur   = db.cursor()
        cur.execute("""
            UPDATE game_sessions
            SET score=%s, accuracy=%s, avg_time=%s, level=%s
            WHERE session_id=%s
        """, (
            state.get("score", 0),
            round(state.get("score", 0) / TOTAL_QUESTIONS * 100, 1),
            avg_t,
            get_lm(state).level,
            session_id,
        ))
        db.commit()
        cur.close()
        db.close()
    except Exception as e:
        print(f"_update_session_db error: {e}")


def _save_answer_db(session_id, person_id, guessed, correct, response_time):
    try:
        db  = get_db()
        cur = db.cursor()
        cur.execute("""
            INSERT INTO game_answers (session_id, person_id, guessed_name, correct, response_time)
            VALUES (%s, %s, %s, %s, %s)
        """, (session_id, person_id, guessed, correct, response_time))
        db.commit()
        cur.close()
        db.close()
    except Exception as e:
        print(f"_save_answer_db error: {e}")


def _get_person_id(patient_id, name):
    try:
        db  = get_db()
        cur = db.cursor(dictionary=True)
        cur.execute(
            "SELECT person_id FROM known_people WHERE patient_id=%s AND name=%s",
            (patient_id, name),
        )
        row = cur.fetchone()
        cur.close()
        db.close()
        return row["person_id"] if row else None
    except Exception:
        return None


def _get_stats(patient_id):
    try:
        db  = get_db()
        cur = db.cursor(dictionary=True)

        cur.execute("""
            SELECT score, accuracy, avg_time, DATE(played_at) as date
            FROM game_sessions WHERE patient_id=%s
            ORDER BY played_at DESC LIMIT 10
        """, (patient_id,))
        sessions = cur.fetchall()

        cur.execute("""
            SELECT kp.name,
                   COUNT(*) as total,
                   SUM(ga.correct) as correct_count,
                   ROUND(SUM(ga.correct)/COUNT(*)*100, 1) as accuracy
            FROM game_answers ga
            JOIN game_sessions gs ON ga.session_id = gs.session_id
            JOIN known_people  kp ON ga.person_id  = kp.person_id
            WHERE gs.patient_id = %s
            GROUP BY ga.person_id
            ORDER BY accuracy ASC
        """, (patient_id,))
        people_stats = cur.fetchall()

        cur.execute("""
            SELECT ga.guessed_name as guessed, kp.name as actual, COUNT(*) as cnt
            FROM game_answers ga
            JOIN game_sessions gs ON ga.session_id = gs.session_id
            JOIN known_people  kp ON ga.person_id  = kp.person_id
            WHERE gs.patient_id = %s AND ga.correct = 0
              AND ga.guessed_name != '__timeout__'
            GROUP BY ga.guessed_name, kp.name
            HAVING cnt >= 1
            ORDER BY cnt DESC LIMIT 10
        """, (patient_id,))
        confusion_rows = cur.fetchall()

        cur.close()
        db.close()

        total_sess = len(sessions)
        avg_acc    = round(sum(float(s["accuracy"]) for s in sessions) / max(total_sess, 1), 1)
        best_sess  = max(sessions, key=lambda s: s["score"], default=None)
        high_score = best_sess["score"] if best_sess else 0

        hardest = [{"name": p["name"], "accuracy": float(p["accuracy"]), "total": p["total"]}
                   for p in people_stats[:3]]
        easiest = [{"name": p["name"], "accuracy": float(p["accuracy"]), "total": p["total"]}
                   for p in sorted(people_stats, key=lambda x: -float(x["accuracy"]))[:3]]

        trend_sessions = list(reversed(sessions[:7]))
        accuracy_trend = [{"accuracy": float(s["accuracy"]), "date": str(s["date"])}
                          for s in trend_sessions]

        confusion_pairs = [{"guessed": r["guessed"], "actual": r["actual"], "count": r["cnt"]}
                           for r in confusion_rows]

        return {
            "sessions":        [{"score": s["score"], "accuracy": float(s["accuracy"]),
                                 "avg_time": float(s["avg_time"]), "date": str(s["date"])}
                                for s in sessions],
            "hardest":         hardest,
            "easiest":         easiest,
            "accuracy_trend":  accuracy_trend,
            "confusion_pairs": confusion_pairs,
            "total_sessions":  total_sess,
            "avg_accuracy":    avg_acc,
            "best_score":      high_score,
            "high_score":      high_score,
        }
    except Exception as e:
        print(f"_get_stats error: {e}")
        traceback.print_exc()
        return {
            "sessions": [], "hardest": [], "easiest": [],
            "accuracy_trend": [], "confusion_pairs": [],
            "total_sessions": 0, "avg_accuracy": 0,
            "best_score": 0, "high_score": 0,
        }


# ═════════════════════════════════════════════════════════════════════════════
#  Static files
# ═════════════════════════════════════════════════════════════════════════════

@app.route("/static/<path:filename>")
def static_files(filename):
    resp = send_from_directory("static", filename)
    resp.headers["Cache-Control"] = "no-cache"
    resp.headers["Access-Control-Allow-Origin"] = "*"
    return resp

@app.route("/api/ping")
def ping():
    return jsonify({"status": "ok"})


# ═════════════════════════════════════════════════════════════════════════════
#  Caregiver — Known people
# ═════════════════════════════════════════════════════════════════════════════
@app.route("/api/add_person", methods=["POST"])
def add_person():
    try:
        patient_id = request.form.get("patient_id")
        name       = request.form.get("name", "").strip()
        relation   = request.form.get("relation", "").strip()
        photo      = request.files.get("photo")

        if not all([patient_id, name, photo]):
            return jsonify({"error": "patient_id, name, and photo are required"}), 400

        ext       = Path(photo.filename).suffix.lower() or ".jpg"
        filename  = f"{uuid.uuid4().hex}{ext}"
        save_path = UPLOAD_FOLDER / filename
        photo.save(save_path)

        db = get_db()
        cur = db.cursor()

        cur.execute("INSERT IGNORE INTO patients (patient_id) VALUES (%s)", (patient_id,))
        cur.fetchall()
        db.commit()

        cur.execute("""
            INSERT INTO known_people (patient_id, name, relation)
            VALUES (%s, %s, %s)
            ON DUPLICATE KEY UPDATE relation=VALUES(relation)
        """, (patient_id, name, relation))
        cur.fetchall()
        db.commit()

        cur.execute(
            "SELECT person_id FROM known_people WHERE patient_id=%s AND name=%s",
            (patient_id, name),
        )
        row = cur.fetchone()
        person_id = row[0]

        cur.execute(
            "INSERT INTO person_photos (person_id, photo_path) VALUES (%s, %s)",
            (person_id, str(save_path)),
        )
        cur.fetchall()
        db.commit()
        cur.close()
        db.close()

        _build_patient_cache(int(patient_id))

        return jsonify({"status": "ok", "person_id": person_id, "photo": str(save_path)})

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route("/api/get_people/<int:patient_id>")
def get_people(patient_id):
    try:
        db  = get_db()
        cur = db.cursor(dictionary=True)
        cur.execute("""
            SELECT kp.person_id, kp.name, kp.relation,
                   COUNT(pp.photo_id) as photo_count
            FROM known_people kp
            LEFT JOIN person_photos pp ON kp.person_id = pp.person_id
            WHERE kp.patient_id = %s
            GROUP BY kp.person_id
        """, (patient_id,))
        people = cur.fetchall()
        cur.close()
        db.close()
        return jsonify({"people": people})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/delete_person/<int:person_id>", methods=["DELETE"])
def delete_person(person_id):
    try:
        db  = get_db()
        cur = db.cursor()
        cur.execute("DELETE FROM known_people WHERE person_id=%s", (person_id,))
        db.commit()
        cur.close()
        db.close()
        return jsonify({"status": "ok"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ═════════════════════════════════════════════════════════════════════════════
#  Caregiver — Group photos  (NEW)
# ═════════════════════════════════════════════════════════════════════════════

@app.route("/api/add_group_photo", methods=["POST"])
def add_group_photo():
    """
    Upload one or more group photos for a patient.
    Files are saved directly to static/patients/{patient_id}/group/
    so pick_next_face() can use them immediately.
    """
    try:
        patient_id = request.form.get("patient_id")
        photos     = request.files.getlist("photos")   # supports multiple files

        if not patient_id or not photos:
            return jsonify({"error": "patient_id and at least one photo required"}), 400

        group_dir = Path(f"static/patients/{patient_id}/group")
        group_dir.mkdir(parents=True, exist_ok=True)

        saved = []
        for photo in photos:
            if not photo.filename:
                continue
            ext      = Path(photo.filename).suffix.lower() or ".jpg"
            filename = f"{uuid.uuid4().hex}{ext}"
            dst      = group_dir / filename
            photo.save(dst)
            saved.append(filename)

        if not saved:
            return jsonify({"error": "No valid files received"}), 400

        return jsonify({"status": "ok", "saved": saved, "count": len(saved)})

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route("/api/get_group_photos/<int:patient_id>")
def get_group_photos(patient_id):
    """Return list of group photo filenames for a patient."""
    try:
        group_dir = Path(f"static/patients/{patient_id}/group")
        if not group_dir.exists():
            return jsonify({"photos": []})

        photos = [
            p.name for p in sorted(group_dir.iterdir())
            if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
        ]
        return jsonify({"photos": photos})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/delete_group_photo", methods=["DELETE"])
def delete_group_photo():
    """Delete a specific group photo by filename."""
    try:
        data       = request.get_json()
        patient_id = (data or {}).get("patient_id")
        filename   = (data or {}).get("filename", "")

        if not patient_id or not filename:
            return jsonify({"error": "patient_id and filename required"}), 400

        # Security: strip path separators so callers can't escape the folder
        filename = Path(filename).name
        target   = Path(f"static/patients/{patient_id}/group") / filename

        if target.exists():
            target.unlink()
        return jsonify({"status": "ok"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ═════════════════════════════════════════════════════════════════════════════
#  Game endpoints
# ═════════════════════════════════════════════════════════════════════════════

@app.route("/api/game/start", methods=["POST"])
def game_start():
    try:
        data       = request.get_json()
        patient_id = int((data or {}).get("patient_id", 0))
        if not patient_id:
            return jsonify({"error": "patient_id required"}), 400

        state = init_state(patient_id)

        if not pick_and_store(state, patient_id):
            return jsonify({
                "error": "No people added yet or no group photos uploaded. "
                         "Ask your caregiver to add people and group photos first."
            }), 400

        state["q_start"] = time.time()
        save_state(patient_id, state)
        return jsonify({"status": "ok"})

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route("/api/game/question/<int:patient_id>")
def game_question(patient_id):
    try:
        state = get_state(patient_id)
        if not state:
            return jsonify({"error": "Game not started"}), 400

        face      = state.get("current_face", {})
        lm        = get_lm(state)
        hint      = face["name"][0] if state.get("show_hint") and face.get("name") else ""
        level_msg = state.pop("level_msg", None)
        save_state(patient_id, state)

        stats      = _get_stats(patient_id)
        high_score = stats.get("high_score", 0)

        return jsonify({
            "image_path":    face.get("image_path", ""),
            "options":       face.get("options", []),
            "question":      state.get("question", 1),
            "total":         TOTAL_QUESTIONS,
            "score":         state.get("score", 0),
            "high_score":    high_score,
            "level_label":   lm.label,
            "level_color":   lm.color,
            "time_limit":    lm.time_limit,
            "feedback":      state.get("feedback", ""),
            "hint":          hint,
            "level_message": level_msg,
        })

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route("/api/game/answer", methods=["POST"])
def game_answer():
    try:
        data          = request.get_json()
        patient_id    = int((data or {}).get("patient_id", 0))
        user_answer   = (data or {}).get("answer", "").strip()
        response_time = float((data or {}).get("response_time", 0))

        if not patient_id or not user_answer:
            return jsonify({"error": "Missing data"}), 400

        state = get_state(patient_id)
        if not state:
            return jsonify({"error": "Game not started"}), 400

        state["answer_times"].append(response_time)
        mm, ct = get_managers(patient_id)
        lm     = get_lm(state)
        face   = state.get("current_face", {})
        result = check_answer(user_answer, face, mm, lm, ct)
        state["lm"] = lm.to_dict()

        is_correct   = result["correct"]
        correct_name = result["correct_name"]

        if is_correct:
            state["score"]    += 1
            state["feedback"]  = "correct"
        else:
            state["feedback"]  = correct_name

        state["show_hint"] = False

        if not state.get("session_id"):
            _save_session_db(patient_id, state)

        person_id = _get_person_id(patient_id, correct_name)
        if person_id and state.get("session_id"):
            _save_answer_db(state["session_id"], person_id,
                            user_answer, is_correct, response_time)

        lc = result.get("level_change", {})
        if lc.get("level_changed"):
            tag = "🆙 Level Up!" if lc["direction"] == "up" else "⬇️ Level Down"
            state["level_msg"] = f"{tag} Now: {lm.label}"

        current_q = state.get("question", 1)

        if current_q >= TOTAL_QUESTIONS:
            if state.get("session_id"):
                _update_session_db(state["session_id"], state)
            save_state(patient_id, state)
            return jsonify({"game_over": True, "correct": is_correct, "correct_name": correct_name})

        state["question"]  = current_q + 1
        state["feedback"]  = ""

        if not pick_and_store(state, patient_id):
            return jsonify({"error": "Ran out of faces!"}), 500

        state["q_start"] = time.time()
        save_state(patient_id, state)
        return jsonify({"game_over": False, "correct": is_correct, "correct_name": correct_name})

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route("/api/game/hint", methods=["POST"])
def game_hint():
    try:
        data       = request.get_json()
        patient_id = int((data or {}).get("patient_id", 0))
        state      = get_state(patient_id)
        if not state:
            return jsonify({"error": "Game not started"}), 400
        state["show_hint"] = True
        face = state.get("current_face", {})
        hint = face["name"][0] if face.get("name") else ""
        save_state(patient_id, state)
        return jsonify({"hint": hint})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/game/result/<int:patient_id>")
def game_result(patient_id):
    try:
        state    = get_state(patient_id)
        score    = state.get("score", 0) if state else 0
        accuracy = round(score / TOTAL_QUESTIONS * 100, 1)
        stats    = _get_stats(patient_id)

        times = state.get("answer_times", []) if state else []
        avg_t = round(sum(times) / max(len(times), 1), 2)

        high_score = stats.get("high_score", 0)
        new_record = score >= high_score and score > 0

        level = ("Excellent Memory 🧠" if accuracy >= 80 else
                 "Good Memory 🙂"       if accuracy >= 50 else
                 "Needs Improvement ⚠️")

        return jsonify({
            "score":           score,
            "total":           TOTAL_QUESTIONS,
            "accuracy":        accuracy,
            "level":           level,
            "high_score":      high_score,
            "new_record":      new_record,
            "avg_time":        avg_t,
            "hardest":         stats["hardest"],
            "easiest":         stats["easiest"],
            "confusion_pairs": stats["confusion_pairs"],
            "daily_history":   stats["sessions"],
            "summary": {
                "total_sessions": stats["total_sessions"],
                "avg_accuracy":   stats["avg_accuracy"],
                "best_score":     stats["best_score"],
            },
        })
    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route("/api/game/restart", methods=["POST"])
def game_restart():
    try:
        data       = request.get_json()
        patient_id = int((data or {}).get("patient_id", 0))
        state      = init_state(patient_id)
        if not pick_and_store(state, patient_id):
            return jsonify({"error": "No faces available"}), 500
        state["q_start"] = time.time()
        save_state(patient_id, state)
        return jsonify({"status": "ok"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/dashboard/<int:patient_id>")
def dashboard(patient_id):
    try:
        stats  = _get_stats(patient_id)
        mm, ct = get_managers(patient_id)
        return jsonify({
            "hardest":          stats["hardest"],
            "easiest":          stats["easiest"],
            "daily_scores":     stats["sessions"],
            "accuracy_trend":   stats["accuracy_trend"],
            "confusion_pairs":  stats["confusion_pairs"],
            "weights":          mm.get_all_weights(),
            "important_people": [],
            "summary": {
                "total_sessions": stats["total_sessions"],
                "avg_accuracy":   stats["avg_accuracy"],
                "best_score":     stats["best_score"],
            },
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500
@app.route("/api/debug/<int:patient_id>")
def debug_patient(patient_id):
    import game_logic
    patient_base = Path(f"static/patients/{patient_id}")
    known_dir    = patient_base / "known_people"
    group_dir    = patient_base / "group"
    cache_file   = Path("models") / f"patient_{patient_id}" / "embeddings_cache.pkl"

    known_people = []
    if known_dir.exists():
        known_people = [d.name for d in known_dir.iterdir() if d.is_dir()]

    group_photos = []
    if group_dir.exists():
        group_photos = [p.name for p in group_dir.iterdir()]

    cache_names = []
    if cache_file.exists():
        import pickle
        with open(cache_file, "rb") as f:
            cache = pickle.load(f)
        cache_names = list(cache.keys())

    return jsonify({
        "known_people": known_people,
        "group_photos": group_photos,
        "cache_names":  cache_names,
        "backend":      game_logic._backend,
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True, threaded=False)
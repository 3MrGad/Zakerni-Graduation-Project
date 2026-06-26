"""
game_logic.py — Core AI pipeline for Alzheimer Face Memory Game

Architecture (in priority order):
  1. InsightFace buffalo_l: RetinaFace detector + ArcFace ResNet-100 (512-d)
  2. OpenCV DNN (YuNet + SFace): ONNX-based, 128-d embedding
  3. OpenCV Haar + LBPH: Fully built-in, no downloads needed

FIX: KNOWN_DIR, GROUP_DIR, OUTPUT_IMAGE, CACHE_FILE are now mutable globals
     so app.py can point them to the correct per-patient folders before calling
     build_cache() or pick_next_face().
"""

import os
import cv2
import pickle
import random
import numpy as np
from pathlib import Path
from sklearn.metrics.pairwise import cosine_similarity

# ── Paths (defaults — overridden per-patient by app.py) ───────────────────────
BASE_DIR     = Path(__file__).parent
KNOWN_DIR    = BASE_DIR / "static" / "images" / "known_people"   # FIX: was KNOWN_PEOPLE_DIR mismatch
GROUP_DIR    = BASE_DIR / "static" / "images" / "group"
OUTPUT_IMAGE = BASE_DIR / "static" / "images" / "current" / "face.jpg"
CACHE_FILE   = BASE_DIR / "models" / "embeddings_cache.pkl"
MODELS_DIR   = BASE_DIR / "models"

MATCH_THRESHOLD = 0.30

HAAR_XML = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"

_backend     = None
_insight_app = None
_yunet       = None
_sface       = None
_haar        = None


def fix_encoding(text: str) -> str:
    if not text:
        return text
    try:
        return text.encode('latin1').decode('utf-8')
    except Exception:
        try:
            return text.encode('cp1252').decode('utf-8')
        except Exception:
            return text


# ═══════════════════════════════════════════════════════════════════════════════
#  Backend initialisation
# ═══════════════════════════════════════════════════════════════════════════════

def _try_insightface() -> bool:
    global _backend, _insight_app
    try:
        from insightface.app import FaceAnalysis
        fa = FaceAnalysis(name="buffalo_l", providers=["CPUExecutionProvider"])
        fa.prepare(ctx_id=0, det_size=(640, 640))
        _insight_app = fa
        _backend     = "insightface"
        print("[backend] ✅ InsightFace (RetinaFace + ArcFace ResNet-100)")
        return True
    except Exception as e:
        print(f"[backend] InsightFace unavailable: {e}")
        return False


def _try_opencv_dnn() -> bool:
    global _backend, _yunet, _sface
    MODELS_DIR.mkdir(parents=True, exist_ok=True)

    yunet_candidates = list(MODELS_DIR.glob("*yunet*.onnx")) + \
                       list(Path("/").glob("face_detection_yunet*.onnx"))
    sface_candidates = list(MODELS_DIR.glob("*sface*.onnx")) + \
                       list(Path("/").glob("face_recognition_sface*.onnx"))

    yunet_path = yunet_candidates[0] if yunet_candidates else None
    sface_path = sface_candidates[0] if sface_candidates else None

    if yunet_path and sface_path:
        try:
            yn = cv2.FaceDetectorYN.create(str(yunet_path), "", (640, 640), 0.7, 0.3)
            sf = cv2.FaceRecognizerSF.create(str(sface_path), "")
            _yunet   = yn
            _sface   = sf
            _backend = "opencv_dnn"
            print("[backend] ✅ OpenCV DNN (YuNet + SFace)")
            return True
        except Exception as e:
            print(f"[backend] OpenCV DNN failed: {e}")
    return False


def _use_haar_lbph():
    global _backend, _haar
    _haar    = cv2.CascadeClassifier(HAAR_XML)
    _backend = "haar_lbph"
    print("[backend] ✅ OpenCV Haar Cascade + LBP Histograms (built-in, no download)")


def _get_backend() -> str:
    global _backend
    if _backend is None:
        if not _try_insightface():
            if not _try_opencv_dnn():
                _use_haar_lbph()
    return _backend


# ═══════════════════════════════════════════════════════════════════════════════
#  Embedding extraction
# ═══════════════════════════════════════════════════════════════════════════════

def _lbp_embedding(face_gray: np.ndarray) -> np.ndarray:
    face_64 = cv2.resize(face_gray, (64, 64))
    grid    = 8
    cell    = 64 // grid
    hists   = []
    for gy in range(grid):
        for gx in range(grid):
            patch  = face_64[gy*cell:(gy+1)*cell, gx*cell:(gx+1)*cell]
            lbp    = np.zeros_like(patch, dtype=np.uint8)
            shifts = [(-1,-1),(-1,0),(-1,1),(0,1),(1,1),(1,0),(1,-1),(0,-1)]
            for bit, (dy, dx) in enumerate(shifts):
                shifted = np.roll(np.roll(patch, dy, 0), dx, 1)
                lbp    |= ((patch >= shifted).astype(np.uint8) << bit)
            hist, _ = np.histogram(lbp.flatten(), bins=256, range=(0, 256))
            hists.append(hist.astype(np.float32))
    emb  = np.concatenate(hists)
    norm = np.linalg.norm(emb)
    return emb / (norm + 1e-10)


def _extract_embedding(img_bgr: np.ndarray) -> np.ndarray | None:
    backend = _get_backend()

    if backend == "insightface":
        faces = _insight_app.get(img_bgr)
        if not faces:
            return None
        face = max(faces, key=lambda f: (f.bbox[2]-f.bbox[0])*(f.bbox[3]-f.bbox[1]))
        return face.normed_embedding

    if backend == "opencv_dnn":
        h, w = img_bgr.shape[:2]
        _yunet.setInputSize((w, h))
        _, faces = _yunet.detect(img_bgr)
        if faces is None or len(faces) == 0:
            return None
        face    = max(faces, key=lambda f: f[2]*f[3])
        aligned = _sface.alignCrop(img_bgr, face)
        emb     = _sface.feature(aligned).flatten()
        return emb / (np.linalg.norm(emb) + 1e-10)

    if backend == "haar_lbph":
        gray  = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
        gray  = cv2.equalizeHist(gray)
        faces = _haar.detectMultiScale(gray, 1.3, 5, minSize=(40, 40))
        if len(faces) == 0:
            return None
        x, y, fw, fh = max(faces, key=lambda f: f[2]*f[3])
        return _lbp_embedding(gray[y:y+fh, x:x+fw])

    return None


def _detect_all_faces(img_bgr: np.ndarray) -> list[dict]:
    backend = _get_backend()
    results = []

    if backend == "insightface":
        for f in _insight_app.get(img_bgr):
            results.append({"bbox": f.bbox, "embedding": f.normed_embedding})

    elif backend == "opencv_dnn":
        h, w = img_bgr.shape[:2]
        _yunet.setInputSize((w, h))
        _, faces = _yunet.detect(img_bgr)
        if faces is not None:
            for face in faces:
                x, y, fw, fh = [int(v) for v in face[:4]]
                bbox = np.array([x, y, x+fw, y+fh], dtype=float)
                try:
                    aligned = _sface.alignCrop(img_bgr, face)
                    emb     = _sface.feature(aligned).flatten()
                    emb    /= (np.linalg.norm(emb) + 1e-10)
                    results.append({"bbox": bbox, "embedding": emb})
                except Exception:
                    pass

    elif backend == "haar_lbph":
        gray  = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
        gray  = cv2.equalizeHist(gray)
        faces = _haar.detectMultiScale(gray, 1.1, 4, minSize=(60, 60))
        for (x, y, fw, fh) in faces:
            bbox = np.array([x, y, x+fw, y+fh], dtype=float)
            emb  = _lbp_embedding(gray[y:y+fh, x:x+fw])
            results.append({"bbox": bbox, "embedding": emb})

    return results


# ═══════════════════════════════════════════════════════════════════════════════
#  Embedding cache  — FIX: uses module-level KNOWN_DIR / CACHE_FILE so that
#  app.py can redirect them per-patient before calling build_cache()
# ═══════════════════════════════════════════════════════════════════════════════

def build_cache(force: bool = False):
    """
    Walk KNOWN_DIR, extract embeddings per image, average per person → pickle.
    KNOWN_DIR and CACHE_FILE must be set by the caller (app.py) before calling.
    """
    import game_logic as _self   # re-read module globals at call time

    known_dir  = _self.KNOWN_DIR
    cache_file = _self.CACHE_FILE

    _get_backend()

    if cache_file.exists() and not force:
        print("[cache] Using existing embedding cache.")
        return

    print(f"[cache] Building embedding cache from {known_dir} …")
    cache_file.parent.mkdir(parents=True, exist_ok=True)

    if not known_dir.exists():
        known_dir.mkdir(parents=True, exist_ok=True)
        print(f"[cache] Created {known_dir} — add family photos and restart.")
        pickle.dump({}, open(cache_file, "wb"))
        return

    cache: dict[str, np.ndarray] = {}

    for person_dir in sorted(known_dir.iterdir()):
        if not person_dir.is_dir():
            continue

        name       = person_dir.name
        name_fixed = fix_encoding(name)
        print(f"\n  Processing: {name_fixed}")

        embeddings = []

        for img_path in sorted(person_dir.glob("*")):
            if img_path.suffix.lower() not in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}:
                continue
            try:
                img = cv2.imread(str(img_path))
                if img is None:
                    print(f"    [warn] Cannot read {img_path.name}")
                    continue
                emb = _extract_embedding(img)
                if emb is None:
                    print(f"    [warn] No face detected in {img_path.name}")
                    continue
                embeddings.append(emb)
                print(f"    ✓ {img_path.name}")
            except Exception as e:
                print(f"    [error] {img_path.name}: {e}")

        if not embeddings:
            print(f"  [skip] No valid faces for {name_fixed}")
            continue

        mean_emb = np.mean(embeddings, axis=0)
        norm     = np.linalg.norm(mean_emb)
        if norm > 0:
            mean_emb /= norm

        # FIX: store under the fixed name so Arabic names match DB lookup
        cache[name_fixed] = mean_emb
        print(f"  ✓ {name_fixed}: {len(embeddings)} valid face(s)")

    with open(cache_file, "wb") as f:
        pickle.dump(cache, f)

    print(f"\n[cache] Saved {len(cache)} person(s) → {cache_file}\n")
    for n in cache:
        print(f"    - {n}")


def load_cache() -> dict[str, np.ndarray]:
    import game_logic as _self
    cache_file = _self.CACHE_FILE
    if not cache_file.exists():
        return {}
    with open(cache_file, "rb") as f:
        return pickle.load(f)


# ═══════════════════════════════════════════════════════════════════════════════
#  Matching & drawing
# ═══════════════════════════════════════════════════════════════════════════════

def _match_face(embedding: np.ndarray, cache: dict) -> tuple[str | None, float]:
    if not cache:
        return None, 0.0
    names  = list(cache.keys())
    protos = np.stack([cache[n] for n in names])
    scores = cosine_similarity(embedding.reshape(1, -1), protos)[0]
    best   = int(np.argmax(scores))
    score  = float(scores[best])
    return (names[best], score) if score >= MATCH_THRESHOLD else (None, score)


def _draw_highlight(img: np.ndarray, bbox: np.ndarray) -> np.ndarray:
    x1, y1, x2, y2 = [int(v) for v in bbox]
    color  = (0, 200, 83)
    thick  = 3
    corner = max(15, min(40, (x2-x1)//4, (y2-y1)//4))

    for sx, sy, dx, dy in [
        (x1, y1,  corner,  corner), (x2, y1, -corner,  corner),
        (x1, y2,  corner, -corner), (x2, y2, -corner, -corner),
    ]:
        cv2.line(img, (sx, sy), (sx+dx, sy), color, thick)
        cv2.line(img, (sx, sy), (sx, sy+dy), color, thick)

    label       = "Who is this?"
    fs          = cv2.FONT_HERSHEY_SIMPLEX
    sc          = 0.65
    (tw, th), _ = cv2.getTextSize(label, fs, sc, 2)
    pad         = 6
    top         = max(0, y1-th-2*pad-2)
    cv2.rectangle(img, (x1, top), (x1+tw+2*pad, y1), color, -1)
    cv2.putText(img, label, (x1+pad, max(th+pad, y1-pad)),
                fs, sc, (255, 255, 255), 2, cv2.LINE_AA)
    return img


# ═══════════════════════════════════════════════════════════════════════════════
#  Public API
# ═══════════════════════════════════════════════════════════════════════════════

def pick_next_face(memory_manager, level_manager, confusion_tracker,
                   shown_images: list) -> dict | None:
    import game_logic as _self

    cache       = load_cache()
    known_names = list(cache.keys())
    if not known_names:
        print("[pick] No known names in cache")
        return None

    group_dir    = _self.GROUP_DIR
    output_image = _self.OUTPUT_IMAGE

    group_dir.mkdir(parents=True, exist_ok=True)
    group_images = [
        p for p in group_dir.glob("*")
        if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    ]
    fresh = [g for g in group_images if g.name not in shown_images]
    pool  = fresh if fresh else group_images
    if not pool:
        print("[pick] No group images found")
        return None

    random.shuffle(pool)

    for group_path in pool:
        img = cv2.imread(str(group_path))
        if img is None:
            continue

        all_faces  = _detect_all_faces(img)
        candidates = []
        for face in all_faces:
            name, score = _match_face(face["embedding"], cache)
            if name:
                candidates.append({"name": name, "bbox": face["bbox"], "confidence": score})

        if not candidates:
            continue

        weights = [memory_manager.get_weight(c["name"]) for c in candidates]
        chosen  = random.choices(candidates, weights=weights, k=1)[0]

        highlighted = _draw_highlight(img.copy(), chosen["bbox"])
        output_image.parent.mkdir(parents=True, exist_ok=True)
        cv2.imwrite(str(output_image), highlighted)

        distractors = _pick_distractors(
            chosen["name"], known_names, confusion_tracker, level_manager
        )
        options = [chosen["name"]] + distractors
        random.shuffle(options)

        return {
            "name":       chosen["name"],
            "image_path": f"patients/{_self.OUTPUT_IMAGE.parts[-3]}/current/face.jpg",
            "group_path": group_path.name,
            "options":    options,
            "confidence": chosen["confidence"],
        }

    return None


def _pick_distractors(correct, all_names, confusion_tracker, level_manager, n=3):
    others = [x for x in all_names if x != correct]
    if len(others) <= n:
        return others

    level    = level_manager.level
    confused = confusion_tracker.most_confused_with(correct, top_k=5)
    confused = [c for c in confused if c in others]
    hard_n   = 0 if level <= 1 else (1 if level == 2 else min(2, len(confused)))

    hard      = confused[:hard_n]
    easy_pool = [o for o in others if o not in hard]
    easy      = random.sample(easy_pool, min(n-len(hard), len(easy_pool)))
    dist      = hard + easy
    if len(dist) < n:
        rem   = [o for o in others if o not in dist]
        dist += random.sample(rem, min(n-len(dist), len(rem)))
    return dist[:n]


def check_answer(user_answer, face, memory_manager, level_manager, confusion_tracker):
    correct_name = face.get("name", "")
    is_correct   = user_answer.strip().lower() == correct_name.strip().lower()

    memory_manager.update(correct_name, correct=is_correct)
    if not is_correct and user_answer and user_answer != "__timeout__":
        confusion_tracker.record(guessed=user_answer, actual=correct_name)

    old_level = level_manager.level
    level_manager.update(is_correct)
    new_level = level_manager.level

    return {
        "correct":      is_correct,
        "correct_name": correct_name,
        "level_change": {
            "level_changed": new_level != old_level,
            "direction":     "up" if new_level > old_level else "down",
        },
    }
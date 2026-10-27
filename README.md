# Zakerni (ذكرني): Alzheimer's Patient Care Platform

Graduation project, B.Sc. Computer Science (Cyber Security), Ahram Canadian University, 2026.

Zakerni helps people living with Alzheimer's and the caregivers who look after them. Patients get a simple app with reminders, a memory-recognition game and a voice chatbot. Caregivers get a dashboard to manage medication, tasks, memories and live location.

## Architecture

| Component | Stack | Path |
|---|---|---|
| Mobile app (patient, caregiver and admin roles) | Flutter / Dart | [`flutter/my_app`](flutter/my_app) |
| Main REST API (auth, patients, medication, todos, memories, GPS) | Laravel 13, PHP 8.3, MySQL, Sanctum, Firebase (push) | [`Laravel`](Laravel) |
| Memory-recognition game backend (face/person recall, difficulty levels, analytics) | Python, Flask | [`memory_bridge_backend_api`](memory_bridge_backend_api) |
| Patient chatbot with per-patient memory | Cloudflare Workers + KV | [`cloudflare`](cloudflare) |
| Database schema | MySQL | [`database/schema.sql`](database/schema.sql) |

## Features

- **Role-based accounts:** patient, caregiver and admin, using Sanctum token auth and separate password-reset flows.
- **Medication:** schedules, dose logs (taken or missed) and caregiver oversight.
- **Reminders and to-dos:** caregivers can assign tasks that patients tick off.
- **Memories and how-to notes:** caregivers upload photos and step-by-step notes for daily activities.
- **GPS tracking:** the caregiver sees the patient's location.
- **Memory game:** adaptive levels that track accuracy and response time to show cognitive trends.
- **Voice chatbot:** speech-to-text and TTS, with conversation context kept per patient.

## Running locally

**API**
```bash
cd Laravel
cp .env.example .env        # set DB_* and FIREBASE_CREDENTIALS
composer install
php artisan key:generate
php artisan migrate
php artisan serve
```

**Game backend**
```bash
cd memory_bridge_backend_api/memory_bridge_app_backend
pip install -r requirements.txt
python app.py               # http://localhost:5000
```

**Mobile app**
```bash
cd flutter/my_app
flutter pub get
flutter run
```

**Chatbot worker**
```bash
cd cloudflare
npx wrangler kv namespace create PATIENT_MEMORY   # put the id in wrangler.toml
npx wrangler deploy
```

## Security notes

Secrets (`.env`, Firebase service-account JSON, database keys) are loaded from the environment and are never committed. See `.gitignore`.

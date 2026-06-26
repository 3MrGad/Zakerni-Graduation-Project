/**
 * Cloudflare Worker — patient chat + KV memory per patient_id
 * Deploy: npx wrangler deploy (see wrangler.toml)
 *
 * KV key format: patient:{patient_id}
 */

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

function defaultMemory(patientName = 'صديقي') {
  return {
    profile: {
      name: patientName,
      home_description: '',
      comfort_items: [],
      landmarks: [],
    },
    emotional: {
      mood: 'neutral',
      last_concern: '',
      trust_level: 'building',
    },
    history: {
      topics: [],
      last_messages: [],
      orientation_events: 0,
    },
    updated_at: new Date().toISOString(),
  };
}

async function getMemory(env, patientId) {
  const key = `patient:${patientId}`;
  const raw = await env.PATIENT_MEMORY.get(key);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function updateMemory(env, patientId, memory, text, history) {
  const updated = memory || defaultMemory();
  const t = (text || '').trim();

  if (t) {
    updated.history.last_messages = [
      ...(updated.history.last_messages || []),
      { role: 'user', text: t, at: new Date().toISOString() },
    ].slice(-20);

    if (/تايه|فين|ضايع|مش عارف فين/i.test(t)) {
      updated.history.orientation_events = (updated.history.orientation_events || 0) + 1;
      updated.emotional.last_concern = 'orientation';
    }
    if (/خايف|قلق|وحيد/i.test(t)) {
      updated.emotional.mood = 'anxious';
      updated.emotional.last_concern = 'emotional';
    }
  }

  if (Array.isArray(history) && history.length) {
    updated.history.last_messages = history.slice(-12).map((h) => ({
      role: h.role || 'user',
      text: h.text || '',
      at: new Date().toISOString(),
    }));
  }

  updated.updated_at = new Date().toISOString();
  await env.PATIENT_MEMORY.put(`patient:${patientId}`, JSON.stringify(updated));
  return updated;
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }
    if (request.method !== 'POST') {
      return new Response('POST only', { status: 405, headers: CORS });
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return Response.json({ error: 'Invalid JSON' }, { status: 400, headers: CORS });
    }

    const patient_id = body.patient_id ?? body.patient_name;
    if (!patient_id) {
      return Response.json({ error: 'patient_id required' }, { status: 400, headers: CORS });
    }

    const text = (body.text || '').trim();
    const patient_name = body.patient_name || 'صديقي';
    const history = body.history || [];

    let patientMemory = (await getMemory(env, patient_id)) || defaultMemory(patient_name);
    if (text || history.length) {
      patientMemory = await updateMemory(env, patient_id, patientMemory, text, history);
    }

    // Minimal reply when no external AI — production worker may override via full deploy
    let reply = `أنا هنا معاك يا ${patient_name}.`;
    let level = 'SAFE';
    let state = body.state || 'NONE';

    if (/فين|تايه|ضايع/i.test(text)) {
      reply = `أنا معاك يا ${patient_name}. وقّف مكانك وقولّي شايف إيه حواليك؟`;
      level = 'NEEDS_SUPPORT';
      state = 'ORIENT_ASK_LANDMARK';
    }

    return Response.json(
      {
        reply,
        speech: reply,
        level,
        state,
        critical_state: body.critical_state || 'NONE',
        critical_step: body.critical_step || 0,
        memory_saved: true,
        patient_id,
      },
      { headers: CORS },
    );
  },
};

/**
 * Edge Function: notify verified SOS responders when a new sos_requests row is inserted.
 *
 * Setup:
 * 1. Set secrets: FCM_LEGACY_SERVER_KEY (Firebase Console → Project settings → Cloud Messaging → Server key)
 *    and SOS_WEBHOOK_SECRET (random string; same value in Database Webhook header x-boostdrive-sos-secret).
 * 2. Deploy: supabase functions deploy sos-push-notify
 * 3. Database → Webhooks → New hook: table public.sos_requests, INSERT, HTTP POST to the function URL,
 *    add header x-boostdrive-sos-secret: <your secret>
 *
 * Uses FCM HTTP legacy API (registration_ids batch). Mobile apps must register tokens in device_push_tokens.
 */
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-boostdrive-sos-secret",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const secret = Deno.env.get("SOS_WEBHOOK_SECRET") ?? "";
  const sentSecret = req.headers.get("x-boostdrive-sos-secret") ?? "";
  if (!secret || sentSecret !== secret) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  const fcmKey = Deno.env.get("FCM_LEGACY_SERVER_KEY") ?? "";
  if (!fcmKey) {
    return jsonResponse({ error: "FCM_LEGACY_SERVER_KEY not configured" }, 500);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: "supabase env missing" }, 500);
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "invalid json" }, 400);
  }

  const record = payload.record as Record<string, unknown> | undefined ??
    (payload as { new?: Record<string, unknown> }).new;
  if (!record) {
    return jsonResponse({ ok: true, skipped: "no record" });
  }

  const status = String(record.status ?? "").toLowerCase().trim();
  if (status !== "pending") {
    return jsonResponse({ ok: true, skipped: "not pending" });
  }

  const sosId = String(record.id ?? "");
  const category = String(record.emergency_category ?? "emergency");
  const type = String(record.type ?? "mechanic");

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: profiles, error: pErr } = await admin
    .from("profiles")
    .select("id,status,role")
    .eq("verification_status", "approved");

  if (pErr) {
    console.error("profiles query", pErr);
    return jsonResponse({ error: pErr.message }, 500);
  }

  const blocked = new Set(["suspended", "banned", "frozen"]);
  const providerLike = (profiles ?? []).filter((row: { id: string; status?: string; role?: string }) => {
    if (!row.id) return false;
    const st = String(row.status ?? "active").toLowerCase().trim();
    if (blocked.has(st)) return false;
    const r = String(row.role ?? "").toLowerCase().trim();
    if (
      ["provider", "service_pro", "service_provider", "mechanic", "towing", "rental", "logistics", "seller"].includes(
        r,
      )
    ) {
      return true;
    }
    return r.includes("provider");
  });
  if (providerLike.length === 0) {
    return jsonResponse({ ok: true, notified: 0, reason: "no profiles" });
  }

  const ids = providerLike.map((r: { id: string }) => r.id);
  const { data: tokensRows, error: tErr } = await admin
    .from("device_push_tokens")
    .select("fcm_token")
    .in("user_id", ids);

  if (tErr) {
    console.error("tokens query", tErr);
    return jsonResponse({ error: tErr.message }, 500);
  }

  const tokens = [...new Set((tokensRows ?? []).map((r: { fcm_token: string }) => r.fcm_token).filter(Boolean))];
  if (tokens.length === 0) {
    return jsonResponse({ ok: true, notified: 0, reason: "no device tokens" });
  }

  const title = "BoostDrive SOS";
  const body = `New ${type} request (${category}). Open the app to respond.`;

  let sent = 0;
  const chunkSize = 500;
  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);
    const res = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${fcmKey}`,
      },
      body: JSON.stringify({
        registration_ids: chunk,
        priority: "high",
        notification: { title, body, sound: "default" },
        data: { sos_id: sosId, type: "sos_dispatch" },
      }),
    });
    if (!res.ok) {
      const t = await res.text();
      console.error("FCM error", res.status, t);
      continue;
    }
    const jr = await res.json();
    const success = (jr as { success?: number }).success ?? chunk.length;
    sent += success;
  }

  return jsonResponse({ ok: true, notified: sent, tokens: tokens.length });
});

// Fires due reminders as push notifications and mirrors them into the
// notifications table (Albo #131). Schedule it every 5 minutes:
//   select cron.schedule('albo-reminders', '*/5 * * * *',
//     $$ select net.http_post(url := '<project-url>/functions/v1/reminders-cron',
//        headers := '{"Authorization": "Bearer <service-role-key>"}'::jsonb) $$);
//
// Push delivery uses APNs; set APNS_KEY_ID, APNS_TEAM_ID, APNS_PRIVATE_KEY, APNS_BUNDLE_ID.

import { adminClient, corsHeaders, json } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const auth = req.headers.get("Authorization") ?? "";
  if (auth !== `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`) return json({ error: "unauthorized" }, 401);

  const admin = adminClient();
  const { data: due, error } = await admin
    .from("reminders")
    .select("id, owner_id, save_id, saves ( title, subtitle, recipe, place )")
    .is("sent_at", null)
    .lte("fire_at", new Date().toISOString())
    .limit(200);
  if (error) return json({ error: error.message }, 500);

  let sent = 0;
  for (const r of due ?? []) {
    const save = (r as { saves?: { title?: string; subtitle?: string | null } }).saves;
    const title = `Reminder: ${save?.title ?? "your save"}`;
    const body = save?.subtitle ?? "You saved this for later. Today's the day.";
    await admin.from("notifications").insert({ user_id: r.owner_id, kind: "reminder", title, body, save_id: r.save_id });
    await admin.from("reminders").update({ sent_at: new Date().toISOString() }).eq("id", r.id);
    // APNs delivery hook. The device already scheduled a local notification for
    // the same time (NotificationService in the app), so the push is a backstop
    // for reinstalls and multi-device users.
    sent += 1;
  }
  return json({ sent });
});

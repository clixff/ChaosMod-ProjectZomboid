import type { VercelRequest, VercelResponse } from "@vercel/node";
import {
  hashEditToken,
  parseCreateBody,
  publicConfigSelect,
  supabase,
} from "../_lib/sharedConfigs.ts";

export default async function handler(
  req: VercelRequest,
  res: VercelResponse,
) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ error: "Method not allowed" });
  }

  const parsed = parseCreateBody(req.body);
  if (!parsed.ok) {
    return res.status(400).json({ error: parsed.error });
  }
  const body = parsed.body;

  const { data: insertedConfig, error } = await supabase
    .from("shared_configs")
    .insert({
      name: body.name,
      edit_token_hash: hashEditToken(body.edit_token),
      mod_version: body.mod_version,
      rewards: body.rewards,
      bits: body.bits,
      donationalerts: body.donationalerts,
      last_effect: body.last_effect,
      data: body.data,
    })
    .select(publicConfigSelect())
    .single();

  if (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        error: "Config with this name already exists",
      });
    }
    console.error("[shared-configs] create failed:", error);
    return res.status(500).json({ error: "Failed to create config" });
  }

  return res.status(201).json({ ok: true, config: insertedConfig });
}

import type { VercelRequest, VercelResponse } from "@vercel/node";
import {
  hashEditToken,
  isValidConfigName,
  parseUpdateBody,
  publicConfigSelect,
  supabase,
  type UpdateSharedConfigBody,
} from "../_lib/sharedConfigs.ts";

function buildUpdatePatch(
  body: UpdateSharedConfigBody,
): Record<string, unknown> {
  const patch: Record<string, unknown> = {};
  if (body.new_name !== undefined) patch["name"] = body.new_name;
  if (body.mod_version !== undefined) patch["mod_version"] = body.mod_version;
  if (body.rewards !== undefined) patch["rewards"] = body.rewards;
  if (body.bits !== undefined) patch["bits"] = body.bits;
  if (body.donationalerts !== undefined) {
    patch["donationalerts"] = body.donationalerts;
  }
  if (body.last_effect !== undefined) patch["last_effect"] = body.last_effect;
  if (body.data !== undefined) patch["data"] = body.data;
  return patch;
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse,
) {
  const nameParam = req.query["name"];
  const name = Array.isArray(nameParam)
    ? String(nameParam[0] ?? "")
    : String(nameParam ?? "");

  if (!isValidConfigName(name)) {
    return res.status(400).json({ error: "Invalid config name" });
  }

  if (req.method === "GET") {
    const { data: config, error } = await supabase
      .from("shared_configs")
      .select(publicConfigSelect())
      .eq("name", name)
      .maybeSingle();

    if (error) {
      console.error("[shared-configs] read failed:", error);
      return res.status(500).json({ error: "Failed to load config" });
    }
    if (!config) {
      return res.status(404).json({ error: "Config not found" });
    }

    res.setHeader(
      "Cache-Control",
      "public, s-maxage=30, stale-while-revalidate=120",
    );
    return res.status(200).json({ ok: true, config });
  }

  if (req.method === "PUT") {
    const parsed = parseUpdateBody(req.body);
    if (!parsed.ok) {
      return res.status(400).json({ error: parsed.error });
    }
    const body = parsed.body;

    const { data: existing, error: readError } = await supabase
      .from("shared_configs")
      .select("id, edit_token_hash")
      .eq("name", name)
      .maybeSingle();

    if (readError) {
      console.error("[shared-configs] read-for-edit failed:", readError);
      return res.status(500).json({ error: "Failed to load config" });
    }
    if (!existing) {
      return res.status(404).json({ error: "Config not found" });
    }
    if (hashEditToken(body.edit_token) !== existing.edit_token_hash) {
      return res.status(403).json({ error: "Invalid edit token" });
    }

    const patch = buildUpdatePatch(body);
    if (Object.keys(patch).length === 0) {
      return res.status(400).json({ error: "Nothing to update" });
    }

    const { data: updated, error: updateError } = await supabase
      .from("shared_configs")
      .update(patch)
      .eq("id", existing.id)
      .select(publicConfigSelect())
      .single();

    if (updateError) {
      if (updateError.code === "23505") {
        return res.status(409).json({
          error: "Config with this name already exists",
        });
      }
      console.error("[shared-configs] update failed:", updateError);
      return res.status(500).json({ error: "Failed to update config" });
    }

    return res.status(200).json({ ok: true, config: updated });
  }

  res.setHeader("Allow", "GET, PUT");
  return res.status(405).json({ error: "Method not allowed" });
}

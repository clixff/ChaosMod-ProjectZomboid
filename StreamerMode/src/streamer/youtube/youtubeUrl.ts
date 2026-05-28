export function extractYouTubeVideoId(input: string): string | null {
  const trimmed = input.trim();
  if (!trimmed) return null;

  try {
    const url = new URL(trimmed);
    const host = url.hostname.toLowerCase();
    if (host === "youtu.be") {
      const id = url.pathname.slice(1).split("/")[0] ?? "";
      return /^[a-zA-Z0-9_-]{11}$/.test(id) ? id : null;
    }
    if (
      host === "www.youtube.com" ||
      host === "youtube.com" ||
      host === "m.youtube.com" ||
      host === "music.youtube.com" ||
      host === "gaming.youtube.com"
    ) {
      const v = url.searchParams.get("v");
      if (v && /^[a-zA-Z0-9_-]{11}$/.test(v)) return v;

      // Support /live/<id> and /shorts/<id> and /embed/<id>
      const parts = url.pathname.split("/").filter(Boolean);
      const segIndex = parts.findIndex((p) =>
        p === "live" || p === "shorts" || p === "embed" || p === "watch",
      );
      if (segIndex >= 0 && segIndex + 1 < parts.length) {
        const candidate = parts[segIndex + 1] ?? "";
        if (/^[a-zA-Z0-9_-]{11}$/.test(candidate)) return candidate;
      }
    }
    return null;
  } catch {
    if (/^[a-zA-Z0-9_-]{11}$/.test(trimmed)) return trimmed;
    return null;
  }
}

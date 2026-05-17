export function removeEmojis(text: string): string {
  return text
    .replace(/\p{Extended_Pictographic}/gu, "")
    .replace(/\uFE0F/g, "") // remove emoji variation selector
    .replace(/\s+/g, " ")
    .trim();
}

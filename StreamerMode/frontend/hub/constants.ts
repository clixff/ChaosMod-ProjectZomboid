export const VERSION = "1.2.1";

export const GITHUB_REPO_URL =
  "https://github.com/clixff/ChaosMod-ProjectZomboid";

/**
 * Builds the GitHub release download URL for a given version.
 * e.g. "1.2.0" -> ".../releases/download/v1.2.0/ChaosModProjectZomboid_1_2_0.zip"
 */
export function buildDownloadUrl(version: string): string {
  const underscored = version.replace(/\./g, "_");
  return `${GITHUB_REPO_URL}/releases/download/v${version}/ChaosModProjectZomboid_${underscored}.zip`;
}

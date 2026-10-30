import crypto from "crypto";

export const SESSION_COOKIE = "sh_token";
const SESSION_DAYS = 30;
export const SESSION_MAX_AGE = SESSION_DAYS * 24 * 3600;

function secret(): string {
  return (
    process.env.SESSION_SECRET ||
    process.env.SUBMIT_API_KEY ||
    "dev-secret"
  );
}

function hmac(data: string): string {
  return crypto.createHmac("sha256", secret()).update(data).digest("hex");
}

export function signSession(): string {
  const expiresAt = Date.now() + SESSION_DAYS * 24 * 3600 * 1000;
  const payload = `1.${expiresAt}`;
  return `${payload}.${hmac(payload)}`;
}

export function verifySession(token?: string | null): boolean {
  if (!token) return false;
  const parts = token.split(".");
  if (parts.length !== 3) return false;
  const payload = `${parts[0]}.${parts[1]}`;
  if (hmac(payload) !== parts[2]) return false;
  const exp = Number(parts[1]);
  return Number.isFinite(exp) && Date.now() < exp;
}

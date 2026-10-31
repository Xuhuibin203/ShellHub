import crypto from "crypto";

export const SESSION_COOKIE = "sh_token";
const SESSION_DAYS = 30;
export const SESSION_MAX_AGE = SESSION_DAYS * 24 * 3600;
const SESSION_VERSION = "v2";

export const SESSION_COOKIE_OPTIONS = {
  httpOnly: true,
  sameSite: "lax" as const,
  path: "/",
  maxAge: SESSION_MAX_AGE,
};

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

// 会话内容：v2.用户ID.过期时间.HMAC
export function signSession(userId: number): string {
  const expiresAt = Date.now() + SESSION_MAX_AGE * 1000;
  const payload = `${SESSION_VERSION}.${userId}.${expiresAt}`;
  return `${payload}.${hmac(payload)}`;
}

export function verifySession(token?: string | null): { userId: number } | null {
  if (!token) return null;
  const parts = token.split(".");
  if (parts.length !== 4 || parts[0] !== SESSION_VERSION) return null;

  const userId = Number(parts[1]);
  const exp = Number(parts[2]);
  if (!Number.isInteger(userId) || userId <= 0 || !Number.isFinite(exp)) return null;

  const payload = `${parts[0]}.${parts[1]}.${parts[2]}`;
  if (hmac(payload) !== parts[3]) return null;
  return Date.now() < exp ? { userId } : null;
}

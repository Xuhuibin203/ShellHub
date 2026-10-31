import { cookies } from "next/headers";
import { verifySession, SESSION_COOKIE } from "./auth";
import { getDb } from "./db";

export type Role = "admin" | "user";

export type SessionUser = {
  id: number;
  username: string;
  role: Role;
};

export async function getCurrentUser(): Promise<SessionUser | null> {
  const c = await cookies();
  const payload = verifySession(c.get(SESSION_COOKIE)?.value);
  if (!payload) return null;
  const row = getDb()
    .prepare("SELECT id, username, role FROM app_user WHERE id = ?")
    .get(payload.userId) as SessionUser | undefined;
  return row ?? null;
}

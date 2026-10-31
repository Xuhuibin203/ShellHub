import { NextResponse } from "next/server";
import {
  signSession,
  SESSION_COOKIE,
  SESSION_COOKIE_OPTIONS,
} from "@/lib/auth";
import { getDb } from "@/lib/db";
import { verifyPassword } from "@/lib/password";

export async function POST(req: Request) {
  let body: any;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "bad json" }, { status: 400 });
  }

  const username = String(body.username ?? "").trim();
  const password = String(body.password ?? "");
  if (!username || !password) {
    return NextResponse.json({ ok: false, error: "请输入用户名和密码" }, { status: 400 });
  }

  const db = getDb();
  const user = db
    .prepare("SELECT id, password_hash FROM app_user WHERE username = ?")
    .get(username) as { id: number; password_hash: string } | undefined;

  if (!user || !verifyPassword(password, user.password_hash)) {
    return NextResponse.json({ ok: false, error: "用户名或密码错误" }, { status: 401 });
  }

  const res = NextResponse.json({ ok: true });
  res.cookies.set(SESSION_COOKIE, signSession(user.id), SESSION_COOKIE_OPTIONS);
  return res;
}

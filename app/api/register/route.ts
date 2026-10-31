import { NextResponse } from "next/server";
import {
  signSession,
  SESSION_COOKIE,
  SESSION_COOKIE_OPTIONS,
} from "@/lib/auth";
import { getDb } from "@/lib/db";
import { hashPassword } from "@/lib/password";

const USERNAME_RE = /^[A-Za-z0-9_\u4e00-\u9fa5-]{2,20}$/;

export async function POST(req: Request) {
  let body: any;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "bad json" }, { status: 400 });
  }

  const username = String(body.username ?? "").trim();
  const password = String(body.password ?? "");

  if (!USERNAME_RE.test(username)) {
    return NextResponse.json(
      { ok: false, error: "用户名需为 2-20 位中英文、数字、下划线或短横线" },
      { status: 400 }
    );
  }
  if (password.length < 6) {
    return NextResponse.json({ ok: false, error: "密码至少 6 位" }, { status: 400 });
  }

  const db = getDb();
  const exists = db
    .prepare("SELECT id FROM app_user WHERE username = ?")
    .get(username);
  if (exists) {
    return NextResponse.json({ ok: false, error: "用户名已存在" }, { status: 409 });
  }

  const now = Math.floor(Date.now() / 1000);
  let userId: number;
  try {
    const tx = db.transaction(() => {
      const info = db
        .prepare(
          "INSERT INTO app_user (username, password_hash, role, created_at) VALUES (?, ?, 'user', ?)"
        )
        .run(username, hashPassword(password), now);
      const uid = Number(info.lastInsertRowid);

      const row = db
        .prepare("SELECT COALESCE(MAX(sort_order), 0) AS m FROM account_group")
        .get() as { m: number };
      db.prepare(
        "INSERT INTO account_group (name, sort_order, is_public, owner_user_id) VALUES (?, ?, 0, ?)"
      ).run(username, row.m + 1, uid);
      return uid;
    });
    userId = tx();
  } catch {
    return NextResponse.json({ ok: false, error: "注册失败，请重试" }, { status: 500 });
  }

  const res = NextResponse.json({ ok: true });
  res.cookies.set(SESSION_COOKIE, signSession(userId), SESSION_COOKIE_OPTIONS);
  return res;
}

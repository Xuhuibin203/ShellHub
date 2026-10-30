import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { verifySession, SESSION_COOKIE } from "@/lib/auth";
import { getDb } from "@/lib/db";

export async function POST(req: Request) {
  const c = await cookies();
  if (!verifySession(c.get(SESSION_COOKIE)?.value)) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "bad json" }, { status: 400 });
  }

  const name = String(body.name ?? "").trim();
  if (!name) {
    return NextResponse.json({ ok: false, error: "missing name" }, { status: 400 });
  }

  const db = getDb();
  const row = db
    .prepare("SELECT COALESCE(MAX(sort_order), -1) AS m FROM account_group")
    .get() as { m: number };
  const info = db
    .prepare("INSERT INTO account_group (name, sort_order) VALUES (?, ?)")
    .run(name, row.m + 1);

  return NextResponse.json({ ok: true, id: Number(info.lastInsertRowid) });
}

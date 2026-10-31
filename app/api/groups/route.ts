import { NextResponse } from "next/server";
import { getDb } from "@/lib/db";
import { getCurrentUser } from "@/lib/users";

export async function POST(req: Request) {
  const me = await getCurrentUser();
  if (!me) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }
  if (me.role !== "admin") {
    return NextResponse.json({ ok: false, error: "forbidden" }, { status: 403 });
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
    .prepare("SELECT COALESCE(MAX(sort_order), 0) AS m FROM account_group")
    .get() as { m: number };
  const info = db
    .prepare(
      "INSERT INTO account_group (name, sort_order, is_public, owner_user_id) VALUES (?, ?, 0, NULL)"
    )
    .run(name, row.m + 1);

  return NextResponse.json({ ok: true, id: Number(info.lastInsertRowid) });
}

import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { verifySession, SESSION_COOKIE } from "@/lib/auth";
import { getDb } from "@/lib/db";

// 拖拽排序 / 移组：把 accountId 放入 groupId（可为 null=未分组），
// 并按 orderedIds 的顺序重写目标组内账号的 sort_order。
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

  const accountId = Number(body.accountId);
  if (!Number.isInteger(accountId)) {
    return NextResponse.json({ ok: false, error: "invalid accountId" }, { status: 400 });
  }

  const groupId = body.groupId === null ? null : Number(body.groupId);
  if (groupId !== null && !Number.isInteger(groupId)) {
    return NextResponse.json({ ok: false, error: "invalid groupId" }, { status: 400 });
  }

  if (
    !Array.isArray(body.orderedIds) ||
    body.orderedIds.some((x: any) => !Number.isInteger(Number(x)))
  ) {
    return NextResponse.json({ ok: false, error: "invalid orderedIds" }, { status: 400 });
  }
  const orderedIds = body.orderedIds.map((x: any) => Number(x));

  const db = getDb();
  const acc = db.prepare("SELECT id FROM account WHERE id = ?").get(accountId);
  if (!acc) {
    return NextResponse.json({ ok: false, error: "account not found" }, { status: 404 });
  }

  const tx = db.transaction(() => {
    db.prepare("UPDATE account SET group_id = ? WHERE id = ?").run(groupId, accountId);
    orderedIds.forEach((aid: number, i: number) => {
      db.prepare("UPDATE account SET sort_order = ? WHERE id = ?").run(i, aid);
    });
  });
  tx();

  return NextResponse.json({ ok: true });
}

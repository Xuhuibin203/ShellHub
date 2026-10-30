import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { verifySession, SESSION_COOKIE } from "@/lib/auth";
import { getDb } from "@/lib/db";

export async function PATCH(
  req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const c = await cookies();
  if (!verifySession(c.get(SESSION_COOKIE)?.value)) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  const { id } = await ctx.params;
  let body: any;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "bad json" }, { status: 400 });
  }

  const db = getDb();
  if (body.name !== undefined) {
    const name = String(body.name).trim();
    if (!name) {
      return NextResponse.json({ ok: false, error: "missing name" }, { status: 400 });
    }
    db.prepare("UPDATE account SET name = ? WHERE id = ?").run(name, id);
  }

  if (body.groupId !== undefined) {
    const gid = body.groupId === null ? null : Number(body.groupId);
    if (gid !== null && !Number.isInteger(gid)) {
      return NextResponse.json({ ok: false, error: "invalid groupId" }, { status: 400 });
    }
    db.prepare("UPDATE account SET group_id = ? WHERE id = ?").run(gid, id);
  }

  return NextResponse.json({ ok: true });
}

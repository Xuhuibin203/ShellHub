import { NextResponse } from "next/server";
import { getDb } from "@/lib/db";
import { getCurrentUser } from "@/lib/users";

async function requireAdmin() {
  const me = await getCurrentUser();
  if (!me) {
    return { error: NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 }) };
  }
  if (me.role !== "admin") {
    return { error: NextResponse.json({ ok: false, error: "forbidden" }, { status: 403 }) };
  }
  return { me };
}

export async function PATCH(
  req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const guard = await requireAdmin();
  if ("error" in guard) return guard.error;

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
    db.prepare("UPDATE account_group SET name = ? WHERE id = ?").run(name, id);
  }

  return NextResponse.json({ ok: true });
}

// 删除分组：仅限管理员自建的分组；组内账号回到未分组
export async function DELETE(
  _req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const guard = await requireAdmin();
  if ("error" in guard) return guard.error;

  const { id } = await ctx.params;
  const db = getDb();
  const group = db
    .prepare(
      "SELECT id, is_public AS isPublic, owner_user_id AS ownerUserId FROM account_group WHERE id = ?"
    )
    .get(id) as
    | { id: number; isPublic: number; ownerUserId: number | null }
    | undefined;

  if (!group) {
    return NextResponse.json({ ok: false, error: "分组不存在" }, { status: 404 });
  }
  if (group.isPublic || group.ownerUserId != null) {
    return NextResponse.json(
      { ok: false, error: "观赏组和用户组不可删除" },
      { status: 400 }
    );
  }

  const tx = db.transaction(() => {
    db.prepare("UPDATE account SET group_id = NULL WHERE group_id = ?").run(group.id);
    db.prepare("DELETE FROM account_group WHERE id = ?").run(group.id);
  });
  tx();

  return NextResponse.json({ ok: true });
}

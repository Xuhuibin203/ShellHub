import { NextResponse } from "next/server";
import { getDb } from "@/lib/db";
import { getCurrentUser } from "@/lib/users";

export async function GET() {
  const me = await getCurrentUser();
  const isAdmin = me?.role === "admin";
  const db = getDb();

  const groups = db
    .prepare(
      `SELECT g.id, g.name, g.sort_order AS sortOrder, g.is_public AS isPublic,
              g.owner_user_id AS ownerUserId, u.username AS ownerUsername
       FROM account_group g
       LEFT JOIN app_user u ON u.id = g.owner_user_id
       ORDER BY g.sort_order, g.id`
    )
    .all() as {
    id: number;
    name: string;
    sortOrder: number;
    isPublic: number;
    ownerUserId: number | null;
    ownerUsername: string | null;
  }[];

  const accounts = db
    .prepare(
      "SELECT id, login, name, group_id AS groupId, server FROM account ORDER BY sort_order, id"
    )
    .all() as {
    id: number;
    login: string;
    name: string | null;
    groupId: number | null;
    server: string | null;
  }[];

  const latestRows = db
    .prepare(
      `SELECT s.account_id AS accountId, s.equity, s.today_profit AS todayProfit,
              s.week_profit AS weekProfit, s.hold_hours AS holdHours, s.created_at AS createdAt
       FROM submission s
       JOIN (SELECT account_id, MAX(id) AS mid FROM submission GROUP BY account_id) t
         ON s.id = t.mid`
    )
    .all() as {
    accountId: number;
    equity: number;
    todayProfit: number;
    weekProfit: number;
    holdHours: number;
    createdAt: number;
  }[];

  const latestMap = new Map<number, (typeof latestRows)[number]>();
  for (const r of latestRows) latestMap.set(r.accountId, r);

  type Decorated = {
    id: number;
    login: string;
    name: string | null;
    server: string | null;
    groupId: number | null;
    latest: (typeof latestRows)[number] | null;
  };
  const decorate = (acc: (typeof accounts)[number]): Decorated => ({
    id: acc.id,
    login: acc.login,
    name: acc.name,
    server: acc.server,
    groupId: acc.groupId,
    latest: latestMap.get(acc.id) ?? null,
  });

  // 可见分组：管理员看全部；普通用户看观赏组 + 自己的组；游客只看观赏组
  const visibleGroups = groups.filter((g) => {
    if (isAdmin) return true;
    if (g.isPublic) return true;
    return me != null && g.ownerUserId === me.id;
  });

  const groupMap = new Map<
    number,
    { id: number; name: string; sortOrder: number; isPublic: boolean; ownerUserId: number | null; ownerUsername: string | null; accounts: Decorated[] }
  >();
  for (const g of visibleGroups) {
    groupMap.set(g.id, {
      ...g,
      isPublic: g.isPublic === 1,
      accounts: [],
    });
  }

  const ungrouped: Decorated[] = [];
  for (const acc of accounts) {
    const d = decorate(acc);
    if (acc.groupId != null && groupMap.has(acc.groupId)) {
      groupMap.get(acc.groupId)!.accounts.push(d);
    } else if (isAdmin) {
      ungrouped.push(d);
    }
  }

  const summarize = (list: Decorated[]) => {
    let equity = 0;
    let todayProfit = 0;
    let weekProfit = 0;
    for (const a of list) {
      if (!a.latest) continue;
      equity += a.latest.equity;
      todayProfit += a.latest.todayProfit;
      weekProfit += a.latest.weekProfit;
    }
    return { equity, todayProfit, weekProfit };
  };

  return NextResponse.json({
    ok: true,
    me: me ? { id: me.id, username: me.username, role: me.role } : null,
    groups: [...groupMap.values()].map((g) => ({
      ...g,
      summary: summarize(g.accounts),
    })),
    ungrouped: isAdmin
      ? { accounts: ungrouped, summary: summarize(ungrouped) }
      : null,
  });
}

import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { verifySession, SESSION_COOKIE } from "@/lib/auth";
import { getDb } from "@/lib/db";

export async function GET() {
  const c = await cookies();
  if (!verifySession(c.get(SESSION_COOKIE)?.value)) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  const db = getDb();
  const groups = db
    .prepare("SELECT id, name, sort_order AS sortOrder FROM account_group ORDER BY sort_order, id")
    .all() as { id: number; name: string; sortOrder: number }[];

  const accounts = db
    .prepare("SELECT id, login, name, group_id AS groupId, server FROM account ORDER BY sort_order, id")
    .all() as { id: number; login: string; name: string | null; groupId: number | null; server: string | null }[];

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

  const groupMap = new Map<number, { id: number; name: string; sortOrder: number; accounts: Decorated[] }>();
  for (const g of groups) groupMap.set(g.id, { ...g, accounts: [] });

  const ungrouped: Decorated[] = [];
  for (const acc of accounts) {
    const d = decorate(acc);
    if (acc.groupId != null && groupMap.has(acc.groupId)) {
      groupMap.get(acc.groupId)!.accounts.push(d);
    } else {
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
    groups: [...groupMap.values()].map((g) => ({ ...g, summary: summarize(g.accounts) })),
    ungrouped: {
      accounts: ungrouped,
      summary: summarize(ungrouped),
    },
  });
}

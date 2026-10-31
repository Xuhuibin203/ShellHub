import { NextResponse } from "next/server";
import { getDb, maybeCleanupSubmissions } from "@/lib/db";

export async function POST(req: Request) {
  const key = req.headers.get("x-api-key");
  if (!process.env.SUBMIT_API_KEY || key !== process.env.SUBMIT_API_KEY) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "bad json" }, { status: 400 });
  }

  const login = String(body.login ?? "").trim();
  if (!login) {
    return NextResponse.json({ ok: false, error: "missing login" }, { status: 400 });
  }

  const equity = Number(body.equity);
  const todayProfit = Number(body.todayProfit);
  const weekProfit = Number(body.weekProfit);
  const holdHours = Number(body.holdHours ?? 0);
  if (!Number.isFinite(equity) || !Number.isFinite(todayProfit) || !Number.isFinite(weekProfit) || !Number.isFinite(holdHours)) {
    return NextResponse.json({ ok: false, error: "invalid numbers" }, { status: 400 });
  }

  const server = body.server ? String(body.server) : null;
  const db = getDb();
  const now = Math.floor(Date.now() / 1000);

  const existing = db
    .prepare("SELECT id FROM account WHERE login = ?")
    .get(login) as { id: number } | undefined;

  let accountId: number;
  if (existing) {
    accountId = existing.id;
    if (server) {
      db.prepare("UPDATE account SET server = ? WHERE id = ?").run(server, accountId);
    }
  } else {
    const info = db
      .prepare(
        "INSERT INTO account (login, name, group_id, server, created_at) VALUES (?, ?, NULL, ?, ?)"
      )
      .run(login, login, server, now);
    accountId = Number(info.lastInsertRowid);
  }

  db.prepare(
    "INSERT INTO submission (account_id, equity, today_profit, week_profit, hold_hours, created_at) VALUES (?, ?, ?, ?, ?, ?)"
  ).run(accountId, equity, todayProfit, weekProfit, holdHours, now);

  maybeCleanupSubmissions(db);

  return NextResponse.json({ ok: true, accountId });
}

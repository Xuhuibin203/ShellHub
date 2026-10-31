import Database from "better-sqlite3";
import fs from "fs";
import path from "path";
import { hashPassword } from "./password";

let db: Database.Database | null = null;

function resolveDbPath(): string {
  const p = process.env.DB_PATH || "./data/shellhub.db";
  return path.isAbsolute(p) ? p : path.join(process.cwd(), p);
}

function ensureColumn(
  conn: Database.Database,
  table: string,
  column: string,
  ddl: string
) {
  const cols = conn.prepare(`PRAGMA table_info(${table})`).all() as { name: string }[];
  if (!cols.some((c) => c.name === column)) {
    conn.exec(`ALTER TABLE ${table} ADD COLUMN ${ddl}`);
  }
}

export function getDb(): Database.Database {
  if (db) return db;
  const dbPath = resolveDbPath();
  fs.mkdirSync(path.dirname(dbPath), { recursive: true });
  db = new Database(dbPath);
  db.pragma("journal_mode = WAL");
  db.exec(`
    CREATE TABLE IF NOT EXISTS app_user (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'user',
      created_at INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS account_group (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      is_public INTEGER NOT NULL DEFAULT 0,
      owner_user_id INTEGER
    );
    CREATE TABLE IF NOT EXISTS account (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      login TEXT NOT NULL UNIQUE,
      name TEXT,
      group_id INTEGER,
      server TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS submission (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL,
      equity REAL NOT NULL,
      today_profit REAL NOT NULL,
      week_profit REAL NOT NULL,
      hold_hours REAL NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_submission_account
      ON submission(account_id, created_at DESC);
    CREATE TABLE IF NOT EXISTS meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  `);

  // 迁移：老库补列
  ensureColumn(db, "account", "sort_order", "sort_order INTEGER NOT NULL DEFAULT 0");
  ensureColumn(db, "submission", "hold_hours", "hold_hours REAL NOT NULL DEFAULT 0");
  ensureColumn(db, "account_group", "is_public", "is_public INTEGER NOT NULL DEFAULT 0");
  ensureColumn(db, "account_group", "owner_user_id", "owner_user_id INTEGER");

  // 一次性重置：旧版本的分组全部删除，账号回到未分组
  const reset = db
    .prepare("SELECT value FROM meta WHERE key = ?")
    .get("groups_reset_v1");
  if (!reset) {
    const tx = db.transaction(() => {
      db!.exec(
        "DELETE FROM account_group; UPDATE account SET group_id = NULL, sort_order = 0;"
      );
      db!.prepare("INSERT INTO meta (key, value) VALUES (?, ?)").run(
        "groups_reset_v1",
        String(Date.now())
      );
    });
    tx();
  }

  // 种子管理员账号
  const admin = db
    .prepare("SELECT id FROM app_user WHERE role = 'admin' LIMIT 1")
    .get();
  if (!admin) {
    db.prepare(
      "INSERT INTO app_user (username, password_hash, role, created_at) VALUES (?, ?, 'admin', ?)"
    ).run(
      process.env.ADMIN_USERNAME || "ShiBeiHub",
      hashPassword(process.env.ADMIN_PASSWORD || "998877"),
      Math.floor(Date.now() / 1000)
    );
  }

  // 种子观赏组（所有人可见）
  const publicGroup = db
    .prepare("SELECT id FROM account_group WHERE is_public = 1 LIMIT 1")
    .get();
  if (!publicGroup) {
    db.prepare(
      "INSERT INTO account_group (name, sort_order, is_public, owner_user_id) VALUES (?, ?, 1, NULL)"
    ).run("观赏组", -1);
  }

  return db;
}

// 历史只保留最近 60 天；每个账号的最新一条始终保留（保证看板不丢数据）
const RETENTION_DAYS = 60;

export function maybeCleanupSubmissions(conn: Database.Database) {
  const now = Math.floor(Date.now() / 1000);
  const row = conn
    .prepare("SELECT value FROM meta WHERE key = 'submission_cleanup_at'")
    .get() as { value: string } | undefined;
  const last = row ? Number(row.value) : 0;
  if (now - last < 24 * 3600) return;

  const cutoff = now - RETENTION_DAYS * 24 * 3600;
  conn
    .prepare(
      `DELETE FROM submission
       WHERE created_at < ?
         AND id NOT IN (SELECT MAX(id) FROM submission GROUP BY account_id)`
    )
    .run(cutoff);
  conn
    .prepare(
      `INSERT INTO meta (key, value) VALUES (?, ?)
       ON CONFLICT(key) DO UPDATE SET value = excluded.value`
    )
    .run("submission_cleanup_at", String(now));
}

import Database from "better-sqlite3";
import fs from "fs";
import path from "path";

let db: Database.Database | null = null;

function resolveDbPath(): string {
  const p = process.env.DB_PATH || "./data/shellhub.db";
  return path.isAbsolute(p) ? p : path.join(process.cwd(), p);
}

export function getDb(): Database.Database {
  if (db) return db;
  const dbPath = resolveDbPath();
  fs.mkdirSync(path.dirname(dbPath), { recursive: true });
  db = new Database(dbPath);
  db.pragma("journal_mode = WAL");
  db.exec(`
    CREATE TABLE IF NOT EXISTS account_group (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0
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
  `);

  // 迁移：老库补 account.sort_order 列（用于看板拖拽排序）
  const cols = db.prepare("PRAGMA table_info(account)").all() as { name: string }[];
  if (!cols.some((c) => c.name === "sort_order")) {
    db.exec("ALTER TABLE account ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0");
  }

  // 迁移：老库补 submission.hold_hours 列（扛单时长）
  const subCols = db.prepare("PRAGMA table_info(submission)").all() as { name: string }[];
  if (!subCols.some((c) => c.name === "hold_hours")) {
    db.exec("ALTER TABLE submission ADD COLUMN hold_hours REAL NOT NULL DEFAULT 0");
  }

  return db;
}

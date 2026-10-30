"use client";

import { useCallback, useEffect, useState } from "react";

type Latest = {
  accountId: number;
  equity: number;
  todayProfit: number;
  weekProfit: number;
  createdAt: number;
};

type AccountItem = {
  id: number;
  login: string;
  name: string | null;
  server: string | null;
  groupId: number | null;
  latest: Latest | null;
};

type Group = {
  id: number;
  name: string;
  sortOrder: number;
  accounts: AccountItem[];
};

type BoardData = {
  groups: Group[];
  ungrouped: AccountItem[];
};

function fmt(n: number): string {
  return n.toLocaleString("en-US", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

function profitClass(n: number): string {
  if (n > 0) return "pos";
  if (n < 0) return "neg";
  return "";
}

export default function Board() {
  const [data, setData] = useState<BoardData | null>(null);
  const [error, setError] = useState("");
  const [newGroup, setNewGroup] = useState("");

  const reload = useCallback(async () => {
    try {
      const res = await fetch("/api/board", { cache: "no-store" });
      if (res.status === 401) {
        window.location.href = "/login";
        return;
      }
      const json = await res.json();
      if (json.ok) setData(json);
      else setError(json.error || "加载失败");
    } catch {
      setError("网络错误");
    }
  }, []);

  useEffect(() => {
    reload();
    const t = setInterval(reload, 15000);
    return () => clearInterval(t);
  }, [reload]);

  async function createGroup() {
    const name = newGroup.trim();
    if (!name) return;
    try {
      const res = await fetch("/api/groups", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name }),
      });
      if (!res.ok) throw new Error("创建失败");
      setNewGroup("");
      reload();
    } catch (e: any) {
      alert(e.message);
    }
  }

  async function renameGroup(id: number, current: string) {
    const name = window.prompt("分组名称", current);
    if (name == null) return;
    const t = name.trim();
    if (!t) return;
    try {
      await fetch(`/api/groups/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: t }),
      });
      reload();
    } catch (e: any) {
      alert(e.message);
    }
  }

  async function renameAccount(id: number, current: string) {
    const name = window.prompt("账号显示名", current);
    if (name == null) return;
    const t = name.trim();
    if (!t) return;
    try {
      await fetch(`/api/accounts/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: t }),
      });
      reload();
    } catch (e: any) {
      alert(e.message);
    }
  }

  async function moveAccount(id: number, groupId: number | null) {
    try {
      await fetch(`/api/accounts/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ groupId }),
      });
      reload();
    } catch (e: any) {
      alert(e.message);
    }
  }

  async function logout() {
    await fetch("/api/logout", { method: "POST" });
    window.location.href = "/login";
  }

  if (error) {
    return (
      <main className="board">
        <div className="error">{error}</div>
      </main>
    );
  }
  if (!data) {
    return (
      <main className="board">
        <div className="loading">加载中…</div>
      </main>
    );
  }

  const renderCard = (acc: AccountItem) => (
    <div className="card" key={acc.id}>
      <div className="card-head">
        <span
          className="card-name"
          onClick={() => renameAccount(acc.id, acc.name ?? acc.login)}
          title="点击改名"
        >
          {acc.name ?? acc.login}
        </span>
        {acc.server && <span className="card-server">{acc.server}</span>}
      </div>
      <div className="card-login">#{acc.login}</div>

      {acc.latest ? (
        <div className="card-metrics">
          <div className="metric">
            <span className="metric-label">净值</span>
            <span className="metric-value">{fmt(acc.latest.equity)}</span>
          </div>
          <div className="metric">
            <span className="metric-label">今日利润</span>
            <span className={`metric-value ${profitClass(acc.latest.todayProfit)}`}>
              {acc.latest.todayProfit > 0 ? "+" : ""}
              {fmt(acc.latest.todayProfit)}
            </span>
          </div>
          <div className="metric">
            <span className="metric-label">本周利润</span>
            <span className={`metric-value ${profitClass(acc.latest.weekProfit)}`}>
              {acc.latest.weekProfit > 0 ? "+" : ""}
              {fmt(acc.latest.weekProfit)}
            </span>
          </div>
        </div>
      ) : (
        <div className="card-empty">暂无数据</div>
      )}

      <div className="card-foot">
        <select
          className="grp-select"
          value={acc.groupId == null ? "" : String(acc.groupId)}
          onChange={(e) =>
            moveAccount(acc.id, e.target.value === "" ? null : Number(e.target.value))
          }
        >
          <option value="">未分组</option>
          {data.groups.map((g) => (
            <option key={g.id} value={g.id}>
              {g.name}
            </option>
          ))}
        </select>
      </div>
    </div>
  );

  return (
    <main className="board">
      <header className="topbar">
        <div className="brand">ShellHub</div>
        <div className="topbar-actions">
          <div className="new-group">
            <input
              value={newGroup}
              onChange={(e) => setNewGroup(e.target.value)}
              placeholder="新分组名称"
              onKeyDown={(e) => {
                if (e.key === "Enter") createGroup();
              }}
            />
            <button onClick={createGroup}>添加分组</button>
          </div>
          <button className="logout" onClick={logout}>
            退出
          </button>
        </div>
      </header>

      {data.ungrouped.length > 0 && (
        <section className="section">
          <h2 className="section-title">
            未分组 <span className="count">{data.ungrouped.length}</span>
          </h2>
          <div className="grid">{data.ungrouped.map(renderCard)}</div>
        </section>
      )}

      {data.groups.map((g) => (
        <section className="section" key={g.id}>
          <h2
            className="section-title editable"
            onClick={() => renameGroup(g.id, g.name)}
            title="点击重命名"
          >
            {g.name} <span className="count">{g.accounts.length}</span>
          </h2>
          <div className="grid">
            {g.accounts.length === 0 ? (
              <div className="empty-group">暂无账号</div>
            ) : (
              g.accounts.map(renderCard)
            )}
          </div>
        </section>
      ))}
    </main>
  );
}

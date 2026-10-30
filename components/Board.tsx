"use client";

import {
  useCallback,
  useEffect,
  useState,
  type DragEvent as ReactDragEvent,
} from "react";

type Latest = {
  accountId: number;
  equity: number;
  todayProfit: number;
  weekProfit: number;
  holdHours: number;
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

type DropHint = {
  scope: string;
  anchorId: number | null;
  before: boolean;
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
  const [dragId, setDragId] = useState<number | null>(null);
  const [dropHint, setDropHint] = useState<DropHint | null>(null);

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

  function scopeGroupId(scope: string): number | null {
    if (scope === "ungrouped") return null;
    return Number(scope.slice("group-".length));
  }

  function scopeAccounts(scope: string): AccountItem[] {
    if (!data) return [];
    if (scope === "ungrouped") return data.ungrouped;
    const g = data.groups.find((g) => g.id === Number(scope.slice("group-".length)));
    return g?.accounts ?? [];
  }

  async function reorder(accountId: number, groupId: number | null, orderedIds: number[]) {
    try {
      const res = await fetch("/api/accounts/reorder", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ accountId, groupId, orderedIds }),
      });
      if (!res.ok) throw new Error("排序失败");
      reload();
    } catch (e: any) {
      alert(e.message);
    }
  }

  function setHint(hint: DropHint) {
    setDropHint((prev) =>
      prev &&
      prev.scope === hint.scope &&
      prev.anchorId === hint.anchorId &&
      prev.before === hint.before
        ? prev
        : hint
    );
  }

  function dropTo(scope: string, anchorId: number | null, before: boolean) {
    if (dragId == null) return;
    const groupId = scopeGroupId(scope);
    const others = scopeAccounts(scope)
      .filter((a) => a.id !== dragId)
      .map((a) => a.id);

    let idx: number;
    if (anchorId == null) {
      idx = others.length;
    } else {
      idx = others.indexOf(anchorId);
      if (idx === -1) idx = others.length;
      else if (!before) idx = idx + 1;
    }

    const ordered = [...others.slice(0, idx), dragId, ...others.slice(idx)];
    setDragId(null);
    setDropHint(null);
    reorder(dragId, groupId, ordered);
  }

  function cardDragOver(e: ReactDragEvent<HTMLDivElement>, scope: string, acc: AccountItem) {
    if (dragId == null) return;
    e.preventDefault();
    e.stopPropagation();
    const rect = e.currentTarget.getBoundingClientRect();
    const before = e.clientX < rect.left + rect.width / 2;
    setHint({ scope, anchorId: acc.id, before });
  }

  function cardDrop(e: ReactDragEvent<HTMLDivElement>, scope: string, acc: AccountItem) {
    e.preventDefault();
    e.stopPropagation();
    const rect = e.currentTarget.getBoundingClientRect();
    const before = e.clientX < rect.left + rect.width / 2;
    dropTo(scope, acc.id, before);
  }

  function gridDragOver(e: ReactDragEvent<HTMLDivElement>, scope: string) {
    if (dragId == null) return;
    e.preventDefault();
    setHint({ scope, anchorId: null, before: false });
  }

  function gridDrop(e: ReactDragEvent<HTMLDivElement>, scope: string) {
    e.preventDefault();
    dropTo(scope, null, false);
  }

  function gridClass(scope: string): string {
    let cls = "grid";
    if (dropHint && dropHint.scope === scope && dropHint.anchorId === null) {
      cls += " drop-zone";
    }
    return cls;
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

  const renderCard = (acc: AccountItem, scope: string) => {
    const cls = ["card"];
    if (dragId === acc.id) cls.push("dragging");
    if (dropHint && dropHint.scope === scope && dropHint.anchorId === acc.id) {
      cls.push(dropHint.before ? "drop-before" : "drop-after");
    }

    const holdHours = acc.latest?.holdHours ?? 0;
    if (holdHours > 24) cls.push("hold-24");
    else if (holdHours > 12) cls.push("hold-12");
    else if (holdHours > 6) cls.push("hold-6");
    const holdText = holdHours > 1 ? `扛单 ${Math.floor(holdHours)}小时` : "未扛单";

    return (
      <div
        className={cls.join(" ")}
        key={acc.id}
        draggable
        onDragStart={(e) => {
          setDragId(acc.id);
          e.dataTransfer.effectAllowed = "move";
          e.dataTransfer.setData("text/plain", String(acc.id));
        }}
        onDragEnd={() => {
          setDragId(null);
          setDropHint(null);
        }}
        onDragOver={(e) => cardDragOver(e, scope, acc)}
        onDrop={(e) => cardDrop(e, scope, acc)}
      >
        <div className="card-head">
          <span className="card-hold">{holdText}</span>
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
      </div>
    );
  };

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
          <div
            className={gridClass("ungrouped")}
            onDragOver={(e) => gridDragOver(e, "ungrouped")}
            onDrop={(e) => gridDrop(e, "ungrouped")}
          >
            {data.ungrouped.map((a) => renderCard(a, "ungrouped"))}
          </div>
        </section>
      )}

      {data.groups.map((g) => {
        const scope = `group-${g.id}`;
        return (
          <section className="section" key={g.id}>
            <h2
              className="section-title editable"
              onClick={() => renameGroup(g.id, g.name)}
              title="点击重命名"
            >
              {g.name} <span className="count">{g.accounts.length}</span>
            </h2>
            <div
              className={gridClass(scope)}
              onDragOver={(e) => gridDragOver(e, scope)}
              onDrop={(e) => gridDrop(e, scope)}
            >
              {g.accounts.length === 0 ? (
                <div className="empty-group">暂无账号，拖拽到此处加入</div>
              ) : (
                g.accounts.map((a) => renderCard(a, scope))
              )}
            </div>
          </section>
        );
      })}
    </main>
  );
}

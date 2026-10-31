"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function RegisterPage() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });
      if (res.ok) {
        router.replace("/");
        router.refresh();
      } else {
        const json = await res.json().catch(() => ({}));
        setError(json.error || "注册失败");
      }
    } catch {
      setError("网络错误");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="login-wrap">
      <form className="login-card" onSubmit={submit}>
        <img className="login-logo" src="/logo.png" alt="ShellHub" />
        <h1>注册账号</h1>
        <p className="login-sub">注册后将为你生成专属收益组</p>
        <input
          type="text"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          placeholder="用户名（如 LiangWenFeng）"
          autoFocus
        />
        <p className="login-hint">建议使用「驼峰式姓名」注册，例如 LiangWenFeng</p>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="密码（至少 6 位）"
        />
        {error && <div className="login-error">{error}</div>}
        <button type="submit" disabled={loading || !username || !password}>
          {loading ? "注册中…" : "注册并登录"}
        </button>
        <p className="login-alt">
          已有账号？<Link href="/login">去登录</Link>
        </p>
        <p className="login-alt">
          <Link href="/">返回看板</Link>
        </p>
      </form>
    </main>
  );
}

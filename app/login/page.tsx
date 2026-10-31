"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function LoginPage() {
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
      const res = await fetch("/api/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });
      if (res.ok) {
        router.replace("/");
        router.refresh();
      } else {
        const json = await res.json().catch(() => ({}));
        setError(json.error || "登录失败");
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
        <h1>ShellHub</h1>
        <p className="login-sub">黄金策略收益看板</p>
        <input
          type="text"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          placeholder="用户名"
          autoFocus
        />
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="密码"
        />
        {error && <div className="login-error">{error}</div>}
        <button type="submit" disabled={loading || !username || !password}>
          {loading ? "登录中…" : "登录"}
        </button>
        <p className="login-alt">
          还没有账号？<Link href="/register">立即注册</Link>
        </p>
        <p className="login-alt">
          <Link href="/">返回看板</Link>
        </p>
      </form>
    </main>
  );
}

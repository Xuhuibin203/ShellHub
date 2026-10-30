import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { verifySession, SESSION_COOKIE } from "@/lib/auth";
import Board from "@/components/Board";

export default async function Home() {
  const c = await cookies();
  if (!verifySession(c.get(SESSION_COOKIE)?.value)) {
    redirect("/login");
  }
  return <Board />;
}

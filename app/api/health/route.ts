import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({ ok: true, time: Math.floor(Date.now() / 1000) });
}

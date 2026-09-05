import { NextResponse } from "next/server";
import { serverClient } from "@/lib/supabase/server";

/** OAuth return leg for Google and Apple sign-in (Albo web login). */
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/library";
  const sb = await serverClient();
  if (code && sb) {
    const { error } = await sb.auth.exchangeCodeForSession(code);
    if (!error) return NextResponse.redirect(`${origin}${next}`);
  }
  return NextResponse.redirect(`${origin}/login?error=auth`);
}

"use client";

import { signOut } from "@/app/actions";

export function SignOutButton() {
  return (
    <form action={signOut}>
      <button type="submit" className="btn-secondary text-danger">Sign out</button>
    </form>
  );
}

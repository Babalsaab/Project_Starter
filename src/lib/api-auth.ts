/**
 * Shared authentication helper for API routes.
 *
 * Usage in route handlers:
 *   const session = await requireAuth();
 *   if (session instanceof NextResponse) return session; // 401
 */

import { auth } from "@/../../auth";
import { NextResponse } from "next/server";

export type AuthSession = {
  user: {
    id: string;
    email: string;
    name?: string | null;
    role: string;
  };
};

/**
 * Require authentication. Returns the session or a 401 NextResponse.
 * Use in API route handlers:
 *   const result = await requireAuth();
 *   if (result instanceof NextResponse) return result;
 *   // result is AuthSession
 */
export async function requireAuth(): Promise<AuthSession | NextResponse> {
  try {
    const session = await auth();
    if (!session?.user?.email) {
      return NextResponse.json(
        { error: "Unauthorized — sign in required" },
        { status: 401 }
      );
    }
    return session as unknown as AuthSession;
  } catch {
    return NextResponse.json(
      { error: "Authentication error" },
      { status: 401 }
    );
  }
}

/**
 * Require a specific role (ADMIN, MANAGER, or MEMBER).
 */
export async function requireRole(
  ...roles: string[]
): Promise<AuthSession | NextResponse> {
  const result = await requireAuth();
  if (result instanceof NextResponse) return result;

  if (!roles.includes(result.user.role)) {
    return NextResponse.json(
      { error: `Forbidden — requires role: ${roles.join(" or ")}` },
      { status: 403 }
    );
  }
  return result;
}

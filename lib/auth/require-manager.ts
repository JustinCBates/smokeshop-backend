import { createClient } from "@/lib/supabase/server";

type ManagerAuthResult =
  | { ok: true; userId: string; email: string }
  | { ok: false; status: number; error: string };

function parseAllowedManagerEmails(): string[] {
  return (process.env.INVENTORY_MANAGER_EMAILS || "")
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

function extractRole(user: any): string {
  const roleFromAppMetadata = String(user?.app_metadata?.role || "").toLowerCase();
  if (roleFromAppMetadata) return roleFromAppMetadata;

  const roleFromUserMetadata = String(user?.user_metadata?.role || "").toLowerCase();
  if (roleFromUserMetadata) return roleFromUserMetadata;

  return "";
}

export async function requireManagerAccess(): Promise<ManagerAuthResult> {
  const supabase = await createClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return { ok: false, status: 401, error: "Authentication required" };
  }

  const email = (user.email || "").toLowerCase();
  const role = extractRole(user);
  const allowedEmails = parseAllowedManagerEmails();

  const hasManagerRole = role === "manager" || role === "admin" || role === "owner";
  const isAllowedEmail = Boolean(email) && allowedEmails.includes(email);

  if (!hasManagerRole && !isAllowedEmail) {
    return {
      ok: false,
      status: 403,
      error:
        "Manager access required. Set role=manager/admin in Supabase metadata or add email to INVENTORY_MANAGER_EMAILS.",
    };
  }

  return { ok: true, userId: user.id, email };
}

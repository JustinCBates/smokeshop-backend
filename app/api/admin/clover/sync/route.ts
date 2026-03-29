import "server-only";
import { NextRequest, NextResponse } from "next/server";
import { syncCloverSnapshot } from "@/lib/clover/sync";
import type {
  CloverList,
  CloverCustomer,
  CloverEmployee,
  CloverCategory,
  CloverDiscount,
  CloverItem,
  CloverOrder,
  CloverPayment,
  CloverSyncSnapshot,
} from "@/lib/clover/types";

const CLOVER_BASE = "https://api.clover.com/v3";

function requireAdminAuth(req: NextRequest): boolean {
  const authHeader = req.headers.get("authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  const secret = process.env.ADMIN_API_SECRET;
  if (!secret) return false;
  return token === secret;
}

async function cloverGet<T>(path: string, accessToken: string): Promise<T> {
  const res = await fetch(`${CLOVER_BASE}${path}`, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
    },
  });

  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new Error(`Clover API error ${res.status} for ${path}: ${body}`);
  }

  return res.json() as Promise<T>;
}

async function fetchAllPages<T>(
  path: string,
  accessToken: string,
): Promise<T[]> {
  const pageSize = 100;
  let offset = 0;
  const all: T[] = [];

  while (true) {
    const sep = path.includes("?") ? "&" : "?";
    const page = await cloverGet<CloverList<T>>(
      `${path}${sep}limit=${pageSize}&offset=${offset}`,
      accessToken,
    );
    const elements = page.elements ?? [];
    all.push(...elements);
    if (elements.length < pageSize) break;
    offset += pageSize;
  }

  return all;
}

export async function POST(req: NextRequest): Promise<NextResponse> {
  if (!requireAdminAuth(req)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const accessToken = process.env.CLOVER_ACCESS_TOKEN;
  const merchantId = process.env.CLOVER_MERCHANT_ID;

  if (!accessToken || !merchantId) {
    return NextResponse.json(
      { error: "CLOVER_ACCESS_TOKEN and CLOVER_MERCHANT_ID must be set" },
      { status: 500 },
    );
  }

  const mBase = `/merchants/${merchantId}`;

  try {
    const [
      merchantRaw,
      customers,
      employees,
      categories,
      discounts,
      items,
      orders,
      payments,
    ] = await Promise.all([
      cloverGet<{
        id: string;
        name?: string;
        country?: string;
        currency?: string;
        timezone?: string;
      }>(`${mBase}`, accessToken),
      fetchAllPages<CloverCustomer>(
        `${mBase}/customers?expand=emailAddresses,phoneNumbers,addresses`,
        accessToken,
      ),
      fetchAllPages<CloverEmployee>(`${mBase}/employees`, accessToken),
      fetchAllPages<CloverCategory>(`${mBase}/categories`, accessToken),
      fetchAllPages<CloverDiscount>(`${mBase}/discounts`, accessToken),
      fetchAllPages<CloverItem>(
        `${mBase}/items?expand=categories`,
        accessToken,
      ),
      fetchAllPages<CloverOrder>(
        `${mBase}/orders?expand=lineItems`,
        accessToken,
      ),
      fetchAllPages<CloverPayment>(
        `${mBase}/payments?expand=tender`,
        accessToken,
      ),
    ]);

    const snapshot: CloverSyncSnapshot = {
      merchant: merchantRaw,
      customers,
      employees,
      categories,
      discounts,
      items,
      orders,
      payments,
    };

    const result = await syncCloverSnapshot(snapshot);

    return NextResponse.json({ ok: true, result }, { status: 200 });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[clover/sync]", message);
    return NextResponse.json({ error: message }, { status: 502 });
  }
}

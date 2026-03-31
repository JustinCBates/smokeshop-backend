import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/database/client";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ merchantId: string }> },
) {
  const { merchantId } = await params;

  const rows = await query<{
    clover_merchant_id: string;
    merchant_name: string | null;
    country: string | null;
    currency: string | null;
    timezone: string | null;
  }>(
    `
    SELECT
      clover_merchant_id,
      merchant_name,
      country,
      currency,
      timezone
    FROM clover.merchants
    WHERE clover_merchant_id = $1
    LIMIT 1
    `,
    [merchantId],
  );

  const merchant = rows[0];
  if (!merchant) {
    return NextResponse.json({ error: "Merchant not found" }, { status: 404 });
  }

  return NextResponse.json({
    id: merchant.clover_merchant_id,
    name: merchant.merchant_name ?? undefined,
    country: merchant.country ?? undefined,
    currency: merchant.currency ?? undefined,
    timezone: merchant.timezone ?? undefined,
  });
}

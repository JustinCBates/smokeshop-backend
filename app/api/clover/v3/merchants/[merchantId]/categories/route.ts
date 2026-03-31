import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/database/client";

type CategoryRow = {
  clover_category_id: string;
  name: string;
  sort_order: number | null;
  clover_created_time: number | null;
  clover_modified_time: number | null;
};

function getPaging(request: NextRequest) {
  const limitRaw = Number(request.nextUrl.searchParams.get("limit") ?? "100");
  const offsetRaw = Number(request.nextUrl.searchParams.get("offset") ?? "0");
  const limit = Number.isFinite(limitRaw)
    ? Math.min(Math.max(limitRaw, 1), 1000)
    : 100;
  const offset = Number.isFinite(offsetRaw) ? Math.max(offsetRaw, 0) : 0;
  return { limit, offset };
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ merchantId: string }> },
) {
  const { merchantId } = await params;
  const { limit, offset } = getPaging(request);

  const rows = await query<CategoryRow>(
    `
    SELECT
      c.clover_category_id,
      c.name,
      c.sort_order,
      c.clover_created_time,
      c.clover_modified_time
    FROM clover.categories c
    JOIN clover.merchants m ON m.id = c.merchant_id
    WHERE m.clover_merchant_id = $1
    ORDER BY c.name
    LIMIT $2 OFFSET $3
    `,
    [merchantId, limit, offset],
  );

  return NextResponse.json({
    elements: rows.map((row) => ({
      id: row.clover_category_id,
      name: row.name,
      sortOrder: row.sort_order ?? undefined,
      createdTime: row.clover_created_time ?? undefined,
      modifiedTime: row.clover_modified_time ?? undefined,
    })),
    href: `${request.nextUrl.pathname}?limit=${limit}&offset=${offset}`,
  });
}

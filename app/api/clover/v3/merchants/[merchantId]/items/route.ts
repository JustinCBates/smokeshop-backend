import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/database/client";

type CategoryShape = {
  id: string;
  name: string;
  sortOrder?: number;
  createdTime?: number;
  modifiedTime?: number;
};

type ItemRow = {
  clover_item_id: string;
  code: string | null;
  name: string;
  description: string | null;
  price: number;
  hidden: boolean | null;
  stock_count: number | null;
  quantity: number | null;
  clover_created_time: number | null;
  clover_modified_time: number | null;
  categories: CategoryShape[] | null;
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

function buildHref(request: NextRequest, limit: number, offset: number) {
  const url = new URL(request.url);
  url.searchParams.set("limit", String(limit));
  url.searchParams.set("offset", String(offset));
  return `${url.pathname}?${url.searchParams.toString()}`;
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ merchantId: string }> },
) {
  const { merchantId } = await params;
  const { limit, offset } = getPaging(request);
  const expand = request.nextUrl.searchParams.get("expand") || "";
  const includeCategories = expand.includes("categories");

  const rows = await query<ItemRow>(
    `
    SELECT
      i.clover_item_id,
      i.code,
      i.name,
      i.description,
      i.price,
      i.hidden,
      i.stock_count,
      i.quantity,
      i.clover_created_time,
      i.clover_modified_time,
      CASE
        WHEN $4::boolean IS FALSE THEN NULL
        ELSE (
          SELECT COALESCE(
            json_agg(
              json_build_object(
                'id', c.clover_category_id,
                'name', c.name,
                'sortOrder', c.sort_order,
                'createdTime', c.clover_created_time,
                'modifiedTime', c.clover_modified_time
              )
            ),
            '[]'::json
          )
          FROM clover.item_categories ic
          JOIN clover.categories c ON c.id = ic.category_id
          WHERE ic.item_id = i.id
        )
      END AS categories
    FROM clover.items i
    JOIN clover.merchants m ON m.id = i.merchant_id
    WHERE m.clover_merchant_id = $1
    ORDER BY i.name
    LIMIT $2 OFFSET $3
    `,
    [merchantId, limit, offset, includeCategories],
  );

  return NextResponse.json({
    elements: rows.map((row) => ({
      id: row.clover_item_id,
      code: row.code ?? undefined,
      name: row.name,
      description: row.description ?? undefined,
      price: Number(row.price),
      hidden: row.hidden ?? undefined,
      stockCount: row.stock_count ?? undefined,
      quantity: row.quantity ?? undefined,
      createdTime: row.clover_created_time ?? undefined,
      modifiedTime: row.clover_modified_time ?? undefined,
      categories:
        includeCategories && row.categories
          ? { elements: row.categories }
          : undefined,
    })),
    href: buildHref(request, limit, offset),
  });
}

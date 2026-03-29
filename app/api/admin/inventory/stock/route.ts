import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/database/client";
import { requireManagerAccess } from "@/lib/auth/require-manager";

type UpsertStockBody = {
  sku?: string;
  fulfillment_type?: "delivery" | "pickup";
  location_id?: number;
  quantity?: number;
};

export async function POST(req: NextRequest) {
  const auth = await requireManagerAccess();
  if (!auth.ok) {
    return NextResponse.json({ error: auth.error }, { status: auth.status });
  }

  const body = (await req.json()) as UpsertStockBody;
  const sku = (body.sku || "").trim().toUpperCase();
  const fulfillmentType = body.fulfillment_type;
  const locationId = Number(body.location_id);
  const quantity = Number(body.quantity);

  if (!sku || !fulfillmentType || Number.isNaN(locationId) || Number.isNaN(quantity)) {
    return NextResponse.json(
      { error: "sku, fulfillment_type, location_id, and quantity are required" },
      { status: 400 },
    );
  }

  if (quantity < 0) {
    return NextResponse.json({ error: "quantity must be >= 0" }, { status: 400 });
  }

  const product = await query<{ id: number; sku: string }>(
    `SELECT id, sku FROM products WHERE sku = $1 LIMIT 1`,
    [sku],
  );

  if (!product.length) {
    return NextResponse.json({ error: "Product not found" }, { status: 404 });
  }

  if (fulfillmentType === "delivery") {
    const location = await query<{ id: number }>(
      `SELECT id FROM regions WHERE id = $1 LIMIT 1`,
      [locationId],
    );

    if (!location.length) {
      return NextResponse.json({ error: "Region not found" }, { status: 404 });
    }

    const rows = await query(
      `
      INSERT INTO region_inventory (region_id, product_id, quantity)
      VALUES ($1, $2, $3)
      ON CONFLICT (region_id, product_id)
      DO UPDATE SET quantity = EXCLUDED.quantity, updated_at = NOW()
      RETURNING id, region_id, product_id, quantity, updated_at
      `,
      [locationId, product[0].id, quantity],
    );

    return NextResponse.json({ stock: rows[0] });
  }

  const location = await query<{ id: number }>(
    `SELECT id FROM pickup_locations WHERE id = $1 LIMIT 1`,
    [locationId],
  );

  if (!location.length) {
    return NextResponse.json({ error: "Pickup location not found" }, { status: 404 });
  }

  const rows = await query(
    `
    INSERT INTO pickup_inventory (location_id, product_id, quantity)
    VALUES ($1, $2, $3)
    ON CONFLICT (location_id, product_id)
    DO UPDATE SET quantity = EXCLUDED.quantity, updated_at = NOW()
    RETURNING id, location_id, product_id, quantity, updated_at
    `,
    [locationId, product[0].id, quantity],
  );

  return NextResponse.json({ stock: rows[0] });
}

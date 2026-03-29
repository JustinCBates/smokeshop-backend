import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/database/client";
import { requireManagerAccess } from "@/lib/auth/require-manager";

export async function GET() {
  const auth = await requireManagerAccess();
  if (!auth.ok) {
    return NextResponse.json({ error: auth.error }, { status: auth.status });
  }

  const rows = await query(
    `
    SELECT
      p.id,
      p.sku,
      p.name,
      p.description,
      p.category,
      p.price,
      p.image_url,
      p.in_stock,
      p.created_at,
      p.updated_at,
      COALESCE((SELECT SUM(ri.quantity) FROM region_inventory ri WHERE ri.product_id = p.id), 0) AS delivery_stock,
      COALESCE((SELECT SUM(pi.quantity) FROM pickup_inventory pi WHERE pi.product_id = p.id), 0) AS pickup_stock
    FROM products p
    ORDER BY p.created_at DESC
    `,
  );

  return NextResponse.json({ products: rows });
}

type CreateProductBody = {
  sku?: string;
  name?: string;
  description?: string | null;
  category?: string;
  price?: number;
  image_url?: string | null;
  in_stock?: boolean;
};

export async function POST(req: NextRequest) {
  const auth = await requireManagerAccess();
  if (!auth.ok) {
    return NextResponse.json({ error: auth.error }, { status: auth.status });
  }

  const body = (await req.json()) as CreateProductBody;
  const sku = (body.sku || "").trim().toUpperCase();
  const name = (body.name || "").trim();
  const category = (body.category || "").trim();
  const price = Number(body.price);

  if (!sku || !name || !category || Number.isNaN(price)) {
    return NextResponse.json(
      { error: "sku, name, category, and price are required" },
      { status: 400 },
    );
  }

  if (price < 0) {
    return NextResponse.json({ error: "price must be >= 0" }, { status: 400 });
  }

  const created = await query(
    `
    INSERT INTO products (sku, name, description, category, price, image_url, in_stock)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING id, sku, name, description, category, price, image_url, in_stock, created_at, updated_at
    `,
    [
      sku,
      name,
      body.description ?? null,
      category,
      price,
      body.image_url ?? null,
      body.in_stock ?? true,
    ],
  );

  return NextResponse.json({ product: created[0] }, { status: 201 });
}

import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/database/client";
import { requireManagerAccess } from "@/lib/auth/require-manager";

type UpdateProductBody = {
  name?: string;
  description?: string | null;
  category?: string;
  price?: number;
  image_url?: string | null;
  in_stock?: boolean;
};

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ sku: string }> },
) {
  const auth = await requireManagerAccess();
  if (!auth.ok) {
    return NextResponse.json({ error: auth.error }, { status: auth.status });
  }

  const { sku: rawSku } = await params;
  const sku = rawSku.toUpperCase();
  const body = (await req.json()) as UpdateProductBody;

  const updates: string[] = [];
  const values: Array<string | number | boolean | null> = [];

  if (body.name !== undefined) {
    updates.push(`name = $${values.length + 1}`);
    values.push(body.name.trim());
  }
  if (body.description !== undefined) {
    updates.push(`description = $${values.length + 1}`);
    values.push(body.description);
  }
  if (body.category !== undefined) {
    updates.push(`category = $${values.length + 1}`);
    values.push(body.category.trim());
  }
  if (body.price !== undefined) {
    const price = Number(body.price);
    if (Number.isNaN(price) || price < 0) {
      return NextResponse.json({ error: "price must be a number >= 0" }, { status: 400 });
    }
    updates.push(`price = $${values.length + 1}`);
    values.push(price);
  }
  if (body.image_url !== undefined) {
    updates.push(`image_url = $${values.length + 1}`);
    values.push(body.image_url);
  }
  if (body.in_stock !== undefined) {
    updates.push(`in_stock = $${values.length + 1}`);
    values.push(Boolean(body.in_stock));
  }

  if (!updates.length) {
    return NextResponse.json({ error: "No fields provided to update" }, { status: 400 });
  }

  updates.push(`updated_at = NOW()`);
  values.push(sku);

  const updated = await query(
    `
    UPDATE products
    SET ${updates.join(", ")}
    WHERE sku = $${values.length}
    RETURNING id, sku, name, description, category, price, image_url, in_stock, created_at, updated_at
    `,
    values,
  );

  if (!updated.length) {
    return NextResponse.json({ error: "Product not found" }, { status: 404 });
  }

  return NextResponse.json({ product: updated[0] });
}

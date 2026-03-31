import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { createCharge } from "@/lib/coinbase-commerce";
import { query } from "@/lib/database/client";

export async function POST(req: NextRequest) {
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    const body = await req.json();
    const {
      items,
      fulfillment_type,
      region_id,
      pickup_location_id,
      delivery_address,
      delivery_fee_tier_id,
      delivery_fee_cents,
      tax_cents,
      age_verified,
      guest_email,
      guest_phone,
      guest_name,
    } = body;

    // Allow either authenticated user OR guest checkout with email
    if (!user && !guest_email) {
      return NextResponse.json(
        { error: "Authentication or guest email required" },
        { status: 401 },
      );
    }

    if (!items || items.length === 0) {
      return NextResponse.json({ error: "No items in cart" }, { status: 400 });
    }

    if (!age_verified) {
      return NextResponse.json(
        { error: "Age verification required" },
        { status: 400 },
      );
    }

    // Server-side price validation: look up each product from VPS PostgreSQL
    const skus = items.map((i: any) => i.sku);

    // Build parameterized query for product lookup
    const placeholders = skus
      .map((_: any, idx: number) => `$${idx + 1}`)
      .join(",");
    const productQuery = `
      SELECT 
        sku,
        name as product_name,
        (price * 100)::integer as price_in_cents
      FROM products
      WHERE sku IN (${placeholders})
    `;

    const products = await query(productQuery, skus);

    if (!products || products.length !== items.length) {
      return NextResponse.json(
        { error: "Some products not found" },
        { status: 400 },
      );
    }

    const productMap = new Map(products.map((p) => [p.sku, p]));

    const line_items = items.map((item: any) => {
      const product = productMap.get(item.sku)!;
      return {
        price_data: {
          currency: "usd",
          product_data: {
            name: product.product_name,
          },
          unit_amount: product.price_in_cents,
        },
        quantity: item.quantity,
      };
    });

    // Add delivery fee as a line item if applicable
    if (fulfillment_type === "delivery" && delivery_fee_cents > 0) {
      line_items.push({
        price_data: {
          currency: "usd",
          product_data: {
            name: "Delivery Fee",
          },
          unit_amount: delivery_fee_cents,
        },
        quantity: 1,
      });
    }

    // Add tax as a line item
    if (tax_cents > 0) {
      line_items.push({
        price_data: {
          currency: "usd",
          product_data: {
            name: "Sales Tax",
          },
          unit_amount: tax_cents,
        },
        quantity: 1,
      });
    }

    // Calculate server-side subtotal for validation
    const subtotalCents = items.reduce((sum: number, item: any) => {
      const product = productMap.get(item.sku)!;
      return sum + product.price_in_cents * item.quantity;
    }, 0);

    // Prepare order data for authenticated or guest checkout
    const orderData: any = {
      fulfillment_type,
      region_id,
      pickup_location_id,
      delivery_address,
      delivery_fee_tier_id,
      subtotal_cents: subtotalCents,
      delivery_fee_cents: delivery_fee_cents || 0,
      tax_cents: tax_cents || 0,
      total_cents: subtotalCents + (delivery_fee_cents || 0) + (tax_cents || 0),
      status: "pending",
      age_verified,
      payment_method: "crypto",
    };

    // Add user info for authenticated users, guest info for guests
    if (user) {
      orderData.user_id = user.id;
    } else {
      orderData.guest_email = guest_email;
      orderData.guest_phone = guest_phone;
      orderData.guest_name = guest_name;
    }

    // Create the order in our database
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .insert(orderData)
      .select()
      .single();

    if (orderError) {
      console.error("Order creation failed:", orderError);
      return NextResponse.json(
        { error: "Failed to create order" },
        { status: 500 },
      );
    }

    // Insert order items
    const orderItems = items.map((item: any) => {
      const product = productMap.get(item.sku)!;
      return {
        order_id: order.id,
        sku: item.sku,
        product_name: product.product_name,
        quantity: item.quantity,
        price_in_cents: product.price_in_cents,
      };
    });

    await supabase.from("order_items").insert(orderItems);

    // Create Coinbase Commerce charge
    const origin = req.headers.get("origin") || "http://localhost:3000";
    const totalUSD = (order.total_cents / 100).toFixed(2);

    const itemsList = items
      .map((item: any) => `${item.quantity}x ${item.product_name}`)
      .join(", ");

    const charge = await createCharge({
      name: `Order #${order.id.slice(0, 8)}`,
      description: `Smokeshop order: ${itemsList}`,
      pricing_type: "fixed_price",
      local_price: {
        amount: totalUSD,
        currency: "USD",
      },
      metadata: {
        order_id: order.id,
        user_id: user?.id || "guest",
        guest_email: guest_email || "",
      },
      redirect_url: `${origin}/checkout/success?order_id=${order.id}`,
      cancel_url: `${origin}/checkout?canceled=true`,
    });

    // Update order with crypto charge info
    await supabase
      .from("orders")
      .update({
        payment_id: charge.id,
        crypto_charge_code: charge.code,
      })
      .eq("id", order.id);

    // Return the hosted payment URL
    return NextResponse.json({
      url: charge.hosted_url,
      order_id: order.id,
      charge_code: charge.code,
    });
  } catch (err: any) {
    console.error("Checkout error:", err);
    return NextResponse.json(
      { error: err.message || "Internal server error" },
      { status: 500 },
    );
  }
}

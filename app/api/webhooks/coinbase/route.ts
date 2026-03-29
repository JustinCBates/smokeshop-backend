import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import crypto from "crypto";

/**
 * Coinbase Commerce Webhook Handler
 * 
 * Webhook events:
 * - charge:created - New charge created
 * - charge:confirmed - Payment confirmed on blockchain
 * - charge:failed - Payment failed or expired
 * - charge:delayed - Payment detected but delayed
 * - charge:pending - Payment detected but unconfirmed
 * - charge:resolved - Payment completed successfully
 */

export async function POST(req: NextRequest) {
  try {
    const body = await req.text();
    const signature = req.headers.get("x-cc-webhook-signature");
    const webhookSecret = process.env.COINBASE_COMMERCE_WEBHOOK_SECRET;

    // Verify webhook signature if secret is configured
    if (webhookSecret && signature) {
      const computedSignature = crypto
        .createHmac("sha256", webhookSecret)
        .update(body)
        .digest("hex");

      if (computedSignature !== signature) {
        console.error("Invalid webhook signature");
        return NextResponse.json(
          { error: "Invalid signature" },
          { status: 401 }
        );
      }
    }

    const event = JSON.parse(body);
    const { type, data } = event;
    
    console.log("Coinbase webhook event:", type, data.code);

    // Get order_id from metadata
    const orderId = data.metadata?.order_id;
    if (!orderId) {
      console.error("No order_id in webhook metadata");
      return NextResponse.json({ received: true });
    }

    const supabase = await createClient();

    // Update order status based on event type
    switch (type) {
      case "charge:confirmed":
      case "charge:resolved":
        // Payment successful
        await supabase
          .from("orders")
          .update({ 
            status: "confirmed",
          })
          .eq("id", orderId);
        console.log(`Order ${orderId} confirmed via crypto payment`);
        break;

      case "charge:failed":
        // Payment failed or expired
        await supabase
          .from("orders")
          .update({ 
            status: "cancelled",
          })
          .eq("id", orderId);
        console.log(`Order ${orderId} cancelled - payment failed`);
        break;

      case "charge:pending":
        // Payment detected but not confirmed yet
        console.log(`Order ${orderId} - payment pending confirmation`);
        break;

      default:
        console.log(`Unhandled event type: ${type}`);
    }

    return NextResponse.json({ received: true });
  } catch (err: any) {
    console.error("Webhook error:", err);
    return NextResponse.json(
      { error: err.message || "Webhook processing failed" },
      { status: 500 }
    );
  }
}

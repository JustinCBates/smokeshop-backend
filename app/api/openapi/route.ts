import { NextResponse } from "next/server";

export async function GET() {
  const spec = {
    openapi: "3.0.3",
    info: {
      title: "Smokeshop API",
      version: "1.0.0",
      description:
        "Operational API docs for storefront, checkout, and manager inventory endpoints.",
    },
    servers: [
      {
        url: "/",
        description: "Current environment",
      },
    ],
    tags: [
      { name: "Health" },
      { name: "Media" },
      { name: "Checkout" },
      { name: "Inventory" },
      { name: "Admin" },
      { name: "Webhooks" },
    ],
    paths: {
      "/api/health": {
        get: {
          tags: ["Health"],
          summary: "Health check",
          responses: {
            "200": {
              description: "App/env status",
            },
          },
        },
      },
      "/api/product-image/{sku}": {
        get: {
          tags: ["Media"],
          summary: "Resolve product image by SKU",
          parameters: [
            {
              name: "sku",
              in: "path",
              required: true,
              schema: { type: "string" },
            },
          ],
          responses: {
            "200": {
              description: "Image file or generated fallback",
            },
          },
        },
      },
      "/api/checkout": {
        post: {
          tags: ["Checkout"],
          summary: "Create checkout session",
          description:
            "Validates cart prices against DB and creates order + Coinbase charge.",
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  required: ["items", "fulfillment_type", "age_verified"],
                  properties: {
                    items: {
                      type: "array",
                      items: {
                        type: "object",
                        required: ["sku", "quantity"],
                        properties: {
                          sku: { type: "string" },
                          quantity: { type: "integer", minimum: 1 },
                        },
                      },
                    },
                    fulfillment_type: {
                      type: "string",
                      enum: ["delivery", "pickup"],
                    },
                    region_id: { type: "integer" },
                    pickup_location_id: { type: "integer" },
                    delivery_address: { type: "string" },
                    delivery_fee_tier_id: { type: "integer" },
                    delivery_fee_cents: { type: "integer" },
                    tax_cents: { type: "integer" },
                    age_verified: { type: "boolean" },
                    guest_email: { type: "string", format: "email" },
                    guest_phone: { type: "string" },
                    guest_name: { type: "string" },
                  },
                },
              },
            },
          },
          responses: {
            "200": { description: "Hosted payment URL" },
            "400": { description: "Validation failure" },
            "401": { description: "Auth/guest email required" },
            "500": { description: "Server error" },
          },
        },
      },
      "/api/admin/inventory/products": {
        get: {
          tags: ["Inventory"],
          summary: "List products with stock totals",
          description: "Manager-only endpoint.",
          responses: {
            "200": { description: "Products list" },
            "401": { description: "Authentication required" },
            "403": { description: "Manager access required" },
          },
        },
        post: {
          tags: ["Inventory"],
          summary: "Create product",
          description: "Manager-only endpoint.",
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  required: ["sku", "name", "category", "price"],
                  properties: {
                    sku: { type: "string" },
                    name: { type: "string" },
                    description: { type: "string", nullable: true },
                    category: { type: "string" },
                    price: { type: "number", minimum: 0 },
                    image_url: { type: "string", nullable: true },
                    in_stock: { type: "boolean" },
                  },
                },
              },
            },
          },
          responses: {
            "201": { description: "Product created" },
            "400": { description: "Validation failure" },
            "401": { description: "Authentication required" },
            "403": { description: "Manager access required" },
          },
        },
      },
      "/api/admin/inventory/products/{sku}": {
        patch: {
          tags: ["Inventory"],
          summary: "Update product",
          description: "Manager-only endpoint.",
          parameters: [
            {
              name: "sku",
              in: "path",
              required: true,
              schema: { type: "string" },
            },
          ],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    name: { type: "string" },
                    description: { type: "string", nullable: true },
                    category: { type: "string" },
                    price: { type: "number", minimum: 0 },
                    image_url: { type: "string", nullable: true },
                    in_stock: { type: "boolean" },
                  },
                },
              },
            },
          },
          responses: {
            "200": { description: "Product updated" },
            "400": { description: "Validation failure" },
            "401": { description: "Authentication required" },
            "403": { description: "Manager access required" },
            "404": { description: "Product not found" },
          },
        },
      },
      "/api/admin/inventory/stock": {
        post: {
          tags: ["Inventory"],
          summary: "Upsert stock quantity",
          description:
            "Manager-only endpoint. Upserts stock by fulfillment type and location id.",
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  required: ["sku", "fulfillment_type", "location_id", "quantity"],
                  properties: {
                    sku: { type: "string" },
                    fulfillment_type: {
                      type: "string",
                      enum: ["delivery", "pickup"],
                    },
                    location_id: { type: "integer", minimum: 1 },
                    quantity: { type: "integer", minimum: 0 },
                  },
                },
              },
            },
          },
          responses: {
            "200": { description: "Stock upserted" },
            "400": { description: "Validation failure" },
            "401": { description: "Authentication required" },
            "403": { description: "Manager access required" },
            "404": { description: "Product/location not found" },
          },
        },
      },
      "/api/admin/db-status": {
        get: {
          tags: ["Admin"],
          summary: "Database status check",
          responses: {
            "200": { description: "DB status payload" },
          },
        },
      },
      "/api/admin/migrate": {
        post: {
          tags: ["Admin"],
          summary: "Run DB migrations",
          responses: {
            "200": { description: "Migration status" },
          },
        },
      },
      "/api/admin/execute-migration": {
        post: {
          tags: ["Admin"],
          summary: "Execute SQL migration payload",
          responses: {
            "200": { description: "Execution status" },
          },
        },
      },
      "/api/webhooks/coinbase": {
        post: {
          tags: ["Webhooks"],
          summary: "Coinbase Commerce webhook receiver",
          responses: {
            "200": { description: "Webhook accepted" },
          },
        },
      },
    },
  };

  return NextResponse.json(spec);
}

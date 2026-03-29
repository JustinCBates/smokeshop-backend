import { promises as fs } from "fs";
import path from "path";
import { NextRequest } from "next/server";

const PRODUCT_LABELS: Record<string, string> = {
  "GLASS-001": "Crystal Clear Beaker Bong",
  "GLASS-002": "Emerald Spoon Pipe",
  "GLASS-003": "Mini Bubbler",
  "GLASS-004": "Quartz Dab Rig",
  "VAPE-001": "Cloud Chaser Pen",
  "VAPE-002": "Ceramic Cartridge 1g",
  "VAPE-003": "Box Mod 200W",
  "VAPE-004": "Mango E-Liquid 60ml",
  "ROLL-001": "RAW Classic King Size",
  "ROLL-002": "Hemp Blunt Wraps 2-Pack",
  "ROLL-003": "Pre-Rolled Cones 6-Pack",
  "ROLL-004": "Bamboo Rolling Tray",
  "ACC-001": "4-Piece Herb Grinder",
  "ACC-002": "Torch Lighter",
  "ACC-003": "Smell-Proof Stash Jar",
  "ACC-004": "Silicone Ashtray",
  "CBD-001": "CBD Gummies 30ct",
  "CBD-002": "Delta-8 Cartridge 1g",
  "CBD-003": "CBD Tincture 1000mg",
  "CBD-004": "CBD Flower 3.5g",
  "CANN-001": "OG Kush - Indica 3.5g",
  "CANN-002": "Sour Diesel - Sativa 3.5g",
  "CANN-003": "Blue Dream - Hybrid 3.5g",
  "CANN-004": "Pre-Roll Pack 5ct",
};

function escapeXml(text: string): string {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

function getThemeBySku(sku: string): { from: string; to: string; accent: string } {
  if (sku.startsWith("GLASS")) return { from: "#0f172a", to: "#1d4ed8", accent: "#93c5fd" };
  if (sku.startsWith("VAPE")) return { from: "#111827", to: "#0f766e", accent: "#5eead4" };
  if (sku.startsWith("ROLL")) return { from: "#1f2937", to: "#92400e", accent: "#fcd34d" };
  if (sku.startsWith("ACC")) return { from: "#1f2937", to: "#374151", accent: "#d1d5db" };
  if (sku.startsWith("CBD")) return { from: "#052e16", to: "#166534", accent: "#86efac" };
  if (sku.startsWith("CANN")) return { from: "#14532d", to: "#166534", accent: "#a7f3d0" };
  return { from: "#1f2937", to: "#111827", accent: "#d1d5db" };
}

function buildGeneratedSvg(sku: string): string {
  const title = PRODUCT_LABELS[sku] ?? "Product";
  const { from, to, accent } = getThemeBySku(sku);
  const escapedTitle = escapeXml(title);
  const escapedSku = escapeXml(sku);

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" role="img" aria-labelledby="t d">
  <title id="t">${escapedTitle}</title>
  <desc id="d">Generated image card for ${escapedSku}</desc>
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="${from}"/>
      <stop offset="100%" stop-color="${to}"/>
    </linearGradient>
  </defs>
  <rect width="1000" height="1000" fill="url(#g)"/>
  <rect x="70" y="70" width="860" height="860" rx="36" fill="none" stroke="${accent}" stroke-opacity="0.35" stroke-width="4"/>
  <circle cx="500" cy="380" r="145" fill="${accent}" fill-opacity="0.2"/>
  <rect x="410" y="270" width="180" height="220" rx="24" fill="${accent}" fill-opacity="0.3"/>
  <rect x="445" y="235" width="110" height="46" rx="12" fill="${accent}" fill-opacity="0.4"/>
  <text x="500" y="650" fill="#f9fafb" font-family="Arial, sans-serif" font-size="54" font-weight="700" text-anchor="middle">${escapedSku}</text>
  <text x="500" y="715" fill="#e5e7eb" font-family="Arial, sans-serif" font-size="36" text-anchor="middle">${escapedTitle}</text>
  <text x="500" y="770" fill="#d1d5db" font-family="Arial, sans-serif" font-size="26" text-anchor="middle">Product Photo Coming Soon</text>
</svg>`;
}

function getContentType(fileName: string): string {
  const lower = fileName.toLowerCase();
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  return "application/octet-stream";
}

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ sku: string }> },
) {
  const { sku: rawSku } = await params;
  const sku = rawSku.toUpperCase();
  const productsDir = path.join(process.cwd(), "public", "images", "products");

  const candidates = [
    `${sku}.jpg`,
    `${sku}.jpeg`,
    `${sku}.png`,
    `${sku}.webp`,
  ];

  for (const fileName of candidates) {
    const filePath = path.join(productsDir, fileName);
    try {
      const data = await fs.readFile(filePath);
      return new Response(data, {
        headers: {
          "Content-Type": getContentType(fileName),
          "Cache-Control": "public, max-age=300",
        },
      });
    } catch {
      // Try next extension.
    }
  }

  const generated = buildGeneratedSvg(sku);
  return new Response(generated, {
    headers: {
      "Content-Type": "image/svg+xml",
      "Cache-Control": "public, max-age=300",
    },
  });
}
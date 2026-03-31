import { NextResponse } from "next/server";

export async function GET() {
  return new NextResponse(null, {
    status: 307,
    headers: { location: "/api/docs" },
  });
}

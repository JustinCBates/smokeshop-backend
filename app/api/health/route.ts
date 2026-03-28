import { NextResponse } from "next/server";

export async function GET() {
  try {
    const hasDbUrl = !!process.env.DATABASE_URL;
    const dbUrlStart = process.env.DATABASE_URL
      ? process.env.DATABASE_URL.substring(0, 20) + "..."
      : "NOT SET";

    return NextResponse.json({
      status: "ok",
      timestamp: new Date().toISOString(),
      env: {
        NODE_ENV: process.env.NODE_ENV,
        HAS_DATABASE_URL: hasDbUrl,
        DATABASE_URL_PREFIX: dbUrlStart,
        HAS_SUPABASE_URL: !!process.env.NEXT_PUBLIC_SUPABASE_URL,
      },
    });
  } catch (error: any) {
    return NextResponse.json(
      {
        status: "error",
        message: error.message,
        stack: error.stack,
      },
      { status: 500 },
    );
  }
}

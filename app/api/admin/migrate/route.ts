import { NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';

export async function POST(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const step = searchParams.get('step') || 'postgis';
    
    const filename = step === 'postgis' ? '000a_postgis_setup.sql' : '000b_schema_and_data_v2.sql';
    const migrationPath = path.join(process.cwd(), 'scripts', filename);
    const migrationSQL = await fs.readFile(migrationPath, 'utf-8');

    return NextResponse.json({
      message: `Migration SQL ready (Step: ${step})`,
      sql: migrationSQL,
      step,
      instructions: 'Copy this SQL and run it in your Supabase SQL Editor',
    });
  } catch (error: any) {
    console.error('Migration error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to read migration file' },
      { status: 500 }
    );
  }
}

export async function GET(request: Request) {
  return POST(request);
}


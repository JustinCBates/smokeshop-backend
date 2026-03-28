import { NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';

/**
 * Execute SQL migration with admin privileges
 * Server-side only - never exposes service role key to browser
 */
export async function POST(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const step = searchParams.get('step');

    if (!step || !['postgis', 'schema'].includes(step)) {
      return NextResponse.json(
        { error: 'Invalid step parameter. Use "postgis" or "schema"' },
        { status: 400 }
      );
    }

    // Read the migration file
    const filename = step === 'postgis' ? '000a_postgis_setup.sql' : '000b_schema_and_data_v2.sql';
    const migrationPath = path.join(process.cwd(), 'scripts', filename);
    const migrationSQL = await fs.readFile(migrationPath, 'utf-8');

    // Get Supabase credentials
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !serviceRoleKey) {
      return NextResponse.json(
        { error: 'Missing Supabase admin credentials' },
        { status: 500 }
      );
    }

    // Extract project reference from URL
    const projectRef = supabaseUrl.split('//')[1]?.split('.')[0];
    
    // Use Supabase's SQL API endpoint
    const sqlEndpoint = `${supabaseUrl}/rest/v1/rpc/exec_sql`;

    // Execute the SQL using the Postgres REST API with service role
    const response = await fetch(sqlEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': serviceRoleKey,
        'Authorization': `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({ query: migrationSQL }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      
      // If exec_sql function doesn't exist, provide instructions
      if (errorText.includes('function') && errorText.includes('does not exist')) {
        return NextResponse.json(
          {
            success: false,
            error: 'Automatic migration not available',
            message: 'The database function for executing SQL is not available. Please use the manual copy/paste method.',
            hint: 'This is expected - Supabase does not allow arbitrary SQL execution via the REST API for security reasons.',
          },
          { status: 501 }
        );
      }

      return NextResponse.json(
        {
          success: false,
          error: `Migration failed: ${errorText}`,
        },
        { status: 500 }
      );
    }

    const result = await response.json();

    return NextResponse.json({
      success: true,
      message: `Migration completed successfully (${step})`,
      result,
    });
  } catch (error: any) {
    console.error('Migration execution error:', error);
    return NextResponse.json(
      { 
        success: false,
        error: error.message || 'Failed to execute migration',
      },
      { status: 500 }
    );
  }
}

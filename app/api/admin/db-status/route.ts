import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const supabase = await createClient();

    // Check which tables exist using raw SQL
    const { data: tablesData, error: tablesError } = await supabase.rpc('get_public_tables', {});
    
    let tableNames: string[] = [];
    
    // If the RPC doesn't exist, try checking each table individually
    if (tablesError) {
      // Try to query each expected table to see if it exists
      const expectedTables = [
        'profiles',
        'products',
        'regions',
        'region_inventory',
        'pickup_locations',
        'pickup_inventory',
        'delivery_fee_tiers',
        'delivery_slots',
        'orders',
        'order_items',
      ];
      
      for (const tableName of expectedTables) {
        const { error } = await supabase
          .from(tableName)
          .select('*', { count: 'exact', head: true })
          .limit(0);
        
        if (!error) {
          tableNames.push(tableName);
        }
      }
    } else {
      tableNames = tablesData || [];
    }

    // Check for products
    const { count: productsCount, error: productsError } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true });

    // Check for orders
    const { count: ordersCount, error: ordersError } = await supabase
      .from('orders')
      .select('*', { count: 'exact', head: true });

    const expectedTables = [
      'profiles',
      'products',
      'regions',
      'region_inventory',
      'pickup_locations',
      'pickup_inventory',
      'delivery_fee_tiers',
      'delivery_slots',
      'orders',
      'order_items',
    ];

    const missingTables = expectedTables.filter(t => !tableNames.includes(t));

    return NextResponse.json({
      status: 'ok',
      tablesFound: tableNames.length,
      expectedTables: expectedTables.length,
      missingTables,
      tables: tableNames,
      productsCount: productsCount || 0,
      ordersCount: ordersCount || 0,
      migrationNeeded: missingTables.length > 0,
    });
  } catch (error: any) {
    console.error('DB status check error:', error);
    return NextResponse.json(
      { error: error.message || 'Status check failed' },
      { status: 500 }
    );
  }
}

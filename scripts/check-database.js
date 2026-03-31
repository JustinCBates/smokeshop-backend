#!/usr/bin/env node

/**
 * Check if Supabase database is seeded
 */

require('dotenv').config({ path: '.env.local' });

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('❌ Missing Supabase credentials in .env.local');
  process.exit(1);
}

async function checkDatabase() {
  console.log('🔍 Checking Supabase database...\n');
  console.log(`📍 URL: ${SUPABASE_URL}\n`);

  try {
    // Check products table
    const productsRes = await fetch(
      `${SUPABASE_URL}/rest/v1/products?select=count`,
      {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'Prefer': 'count=exact'
        }
      }
    );

    if (productsRes.status === 404 || productsRes.status === 406) {
      console.log('❌ Products table does NOT exist');
      console.log('   Database has NOT been seeded\n');
      console.log('📋 To seed the database:\n');
      console.log('   Option 1: Run automated migration');
      console.log('   $ pnpm migrate\n');
      console.log('   Option 2: Manual migration');
      console.log('   1. Go to: https://supabase.com/dashboard → SQL Editor');
      console.log('   2. Copy: scripts/000_run_all_complete.sql');
      console.log('   3. Paste and click "Run"\n');
      return;
    }

    const productCount = productsRes.headers.get('content-range')?.split('/')[1] || 0;
    console.log(`✅ Products table exists: ${productCount} products`);

    // Check regions
    const regionsRes = await fetch(
      `${SUPABASE_URL}/rest/v1/regions?select=count`,
      {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'Prefer': 'count=exact'
        }
      }
    );
    const regionCount = regionsRes.headers.get('content-range')?.split('/')[1] || 0;
    console.log(`✅ Regions table exists: ${regionCount} regions`);

    // Check pickup locations
    const locationsRes = await fetch(
      `${SUPABASE_URL}/rest/v1/pickup_locations?select=count`,
      {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'Prefer': 'count=exact'
        }
      }
    );
    const locationCount = locationsRes.headers.get('content-range')?.split('/')[1] || 0;
    console.log(`✅ Pickup locations exist: ${locationCount} locations`);

    // Check orders table
    const ordersRes = await fetch(
      `${SUPABASE_URL}/rest/v1/orders?select=count`,
      {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'Prefer': 'count=exact'
        }
      }
    );
    const orderCount = ordersRes.headers.get('content-range')?.split('/')[1] || 0;
    console.log(`✅ Orders table exists: ${orderCount} orders`);

    console.log('\n' + '═'.repeat(60));
    
    if (productCount >= 20 && regionCount >= 3 && locationCount >= 3) {
      console.log('🎉 Database is FULLY SEEDED and ready to use!');
      console.log('\nYou have:');
      console.log(`   📦 ${productCount} products`);
      console.log(`   📍 ${regionCount} regions`);
      console.log(`   🏪 ${locationCount} pickup locations`);
      console.log(`   🛒 ${orderCount} orders`);
    } else if (productCount > 0 || regionCount > 0) {
      console.log('⚠️  Database is PARTIALLY seeded');
      console.log('   Some tables exist but may be incomplete');
      console.log('\n   Consider running the full migration:');
      console.log('   $ pnpm migrate');
    } else {
      console.log('❌ Database appears EMPTY');
      console.log('\n   Run migrations to seed:');
      console.log('   $ pnpm migrate');
    }
    console.log('═'.repeat(60) + '\n');

  } catch (error) {
    console.error('❌ Error checking database:', error.message);
    console.log('\n💡 This might mean:');
    console.log('   - Database tables don\'t exist yet');
    console.log('   - Network/API error');
    console.log('   - Invalid credentials\n');
  }
}

checkDatabase();

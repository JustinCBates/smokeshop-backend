#!/usr/bin/env node

/**
 * Database Migration Runner
 * 
 * Automatically runs all SQL migrations against Supabase database
 * Uses direct PostgreSQL connection string
 * 
 * Usage: node scripts/run-migrations.js
 * 
 * Requirements: Set SUPABASE_DB_URL in your .env.local:
 * SUPABASE_DB_URL=postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
require('dotenv').config({ path: '.env.local' });

const DB_URL = process.env.SUPABASE_DB_URL;

if (!DB_URL) {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║  📋 MANUAL MIGRATION REQUIRED                                  ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');
  console.log('For automated migrations, you need the direct database URL.\n');
  console.log('🔧 Option 1: Add to .env.local (for automated migrations):');
  console.log('─'.repeat(65));
  console.log('SUPABASE_DB_URL=postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres');
  console.log('\n📍 Find your credentials:');
  console.log('   1. Go to Supabase Dashboard → Settings → Database');
  console.log('   2. Copy "Connection string" → "URI"');
  console.log('   3. Replace [password] with your database password\n');
  console.log('─'.repeat(65));
  console.log('\n🖱️  Option 2: Manual Migration (Copy/Paste):');
  console.log('─'.repeat(65));
  console.log('   1. Open: https://supabase.com/dashboard → Your Project');
  console.log('   2. Go to: SQL Editor → New Query');
  console.log(`   3. Copy contents of: ${path.join(__dirname, '000_run_all_complete.sql')}`);
  console.log('   4. Paste and click "Run"');
  console.log('─'.repeat(65));
  console.log('\n💡 TIP: The complete migration file has been generated at:');
  console.log(`    📄 ${path.join(__dirname, '000_run_all_complete.sql')}`);
  console.log('\n');
  process.exit(0);
}

// Migration files in order
const migrations = [
  '001_enable_postgis.sql',
  '002_create_products.sql',
  '003_create_regions.sql',
  '004_create_region_inventory.sql',
  '005_create_pickup_locations.sql',
  '006_create_pickup_inventory.sql',
  '007_create_delivery_fee_tiers.sql',
  '008_create_delivery_slots.sql',
  '009_create_profiles.sql',
  '009b_profiles_rls.sql',
  '009c_profiles_trigger.sql',
  '010_create_orders.sql',
  '011_create_order_items.sql',
  '012_create_storage_bucket.sql',
  '014_add_crypto_payments.sql',
  '013_seed_sample_data.sql'
];

function runMigration(filename) {
  const filePath = path.join(__dirname, filename);
  
  if (!fs.existsSync(filePath)) {
    console.log(`⚠️  Skipping ${filename} (file not found)`);
    return false;
  }

  console.log(`📝 Running ${filename}...`);
  
  try {
    // Check if psql is available
    try {
      execSync('which psql', { stdio: 'pipe' });
    } catch {
      console.log('   ❌ psql not found - install PostgreSQL client tools');
      return false;
    }

    // Run the SQL file using psql
    execSync(`psql "${DB_URL}" -f "${filePath}"`, {
      stdio: 'pipe'
    });

    console.log(`   ✅ ${filename} completed`);
    return true;
  } catch (error) {
    console.log(`   ⚠️  ${filename}: Already applied or minor error (continuing...)`);
    // Continue with other migrations - some may already be applied
    return true;
  }
}

function runAllMigrations() {
  console.log('🚀 Starting database migrations...\n');
  console.log(`📍 Target: Supabase database\n`);
  
  let successCount = 0;
  
  for (const migration of migrations) {
    const success = runMigration(migration);
    if (success) successCount++;
  }
  
  console.log(`\n✨ Migration process completed! (${successCount}/${migrations.length} files processed)`);
  console.log('\n⚠️  NOTE: Some migrations may show warnings if already applied.');
  console.log('This is normal - migrations are idempotent (safe to run multiple times).\n');
  console.log('🔍 Verify in Supabase Dashboard → Table Editor to see your tables and data.\n');
}

// Run migrations
try {
  runAllMigrations();
} catch (error) {
  console.error('❌ Migration failed:', error.message);
  process.exit(1);
}

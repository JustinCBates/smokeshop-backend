#!/usr/bin/env node

/**
 * Database Bootstrap Runner
 *
 * Applies the minimal PostGIS + identity baseline to the self-hosted PostgreSQL database.
 * Usage: node scripts/run-migrations.js
 *
 * Requirements: Set DATABASE_URL in your .env.local:
 * DATABASE_URL=postgresql://smokeshop_user:[password]@127.0.0.1:5432/smokeshop
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

try {
  require('dotenv').config({ path: '.env.local' });
} catch {
  // Allow execution in environments that inject DATABASE_URL directly.
}

const DB_URL = process.env.DATABASE_URL;

if (!DB_URL) {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║  📋 DATABASE BOOTSTRAP REQUIRES DATABASE_URL                   ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');
  console.log('For automated bootstrap, set the self-hosted PostgreSQL URL.\n');
  console.log('🔧 Add this to .env.local:');
  console.log('─'.repeat(65));
  console.log('DATABASE_URL=postgresql://smokeshop_user:[password]@127.0.0.1:5432/smokeshop');
  console.log('\n💡 To rebuild the container-backed database from scratch:');
  console.log('─'.repeat(65));
  console.log(`./scripts/recreate-identity-db.sh [env-file]`);
  console.log(`\nThe bootstrap SQL lives at: ${path.join(__dirname, '..', 'db', 'init', '001_identity_baseline.sql')}`);
  console.log('\n');
  process.exit(0);
}

const migrations = [path.join(__dirname, '..', 'db', 'init', '001_identity_baseline.sql')];

function runMigration(filePath) {
  if (!fs.existsSync(filePath)) {
    console.log(`⚠️  Skipping ${filePath} (file not found)`);
    return false;
  }

  console.log(`📝 Running ${path.basename(filePath)}...`);

  try {
    try {
      execSync('which psql', { stdio: 'pipe' });
    } catch {
      console.log('   ❌ psql not found - install PostgreSQL client tools');
      return false;
    }

    execSync(`psql "${DB_URL}" -f "${filePath}"`, {
      stdio: 'pipe'
    });

    console.log(`   ✅ ${path.basename(filePath)} completed`);
    return true;
  } catch (error) {
    console.log(`   ❌ ${path.basename(filePath)} failed`);
    console.log(error.message);
    return false;
  }
}

function runAllMigrations() {
  console.log('🚀 Starting database bootstrap...\n');
  console.log('📍 Target: self-hosted PostgreSQL database\n');

  let successCount = 0;

  for (const migration of migrations) {
    const success = runMigration(migration);
    if (success) successCount++;
  }

  console.log(`\n✨ Bootstrap process completed! (${successCount}/${migrations.length} files processed)`);
  console.log('\nExpected tables: auth.users, auth.identities, auth.sessions, public.profiles');
  console.log('Expected extension: postgis\n');

  if (successCount !== migrations.length) {
    process.exit(1);
  }
}

// Run migrations
try {
  runAllMigrations();
} catch (error) {
  console.error('❌ Migration failed:', error.message);
  process.exit(1);
}

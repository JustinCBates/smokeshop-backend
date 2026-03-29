#!/bin/bash

# Smokeshop Deployment Script
# Automates the complete deployment process

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         🚀 Smokeshop Deployment Script                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check environment variables
echo "📋 Checking environment configuration..."

if [ ! -f .env.local ]; then
    echo "❌ Error: .env.local file not found"
    echo "   Copy .env.example to .env.local and configure your credentials"
    exit 1
fi

# Load environment variables
source .env.local 2>/dev/null || true

if [ -z "$NEXT_PUBLIC_SUPABASE_URL" ]; then
    echo "❌ Error: NEXT_PUBLIC_SUPABASE_URL not set in .env.local"
    exit 1
fi

if [ -z "$COINBASE_COMMERCE_API_KEY" ] || [ "$COINBASE_COMMERCE_API_KEY" = "your_coinbase_commerce_api_key_here" ]; then
    echo "⚠️  Warning: COINBASE_COMMERCE_API_KEY not configured"
    echo "   Payments will not work until you add a valid API key"
fi

echo "   ✅ Environment configured"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
pnpm install
echo "   ✅ Dependencies installed"
echo ""

# Run database migrations
echo "🗄️  Running database migrations..."
echo "   Option 1: Automated (if SUPABASE_DB_URL is set)"
echo "   Option 2: Manual (follow instructions)"
echo ""

pnpm migrate || {
    echo ""
    echo "⚠️  Automated migration not available"
    echo "   Please run migrations manually (see instructions above)"
    echo ""
    read -p "Have you completed the manual migration? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Deployment cancelled - complete migrations first"
        exit 1
    fi
}

# Build the application
echo "🔨 Building production bundle..."
pnpm build
echo "   ✅ Build completed"
echo ""

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo "📦 Installing PM2 process manager..."
    npm install -g pm2
fi

# Stop existing instance if running
pm2 delete smokeshop 2>/dev/null || true

# Start with PM2
echo "🚀 Starting application with PM2..."
pm2 start ecosystem.config.js
pm2 save
echo "   ✅ Application started"
echo ""

# Show status
pm2 status

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║            ✨ Deployment Complete! ✨                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📍 Your smokeshop is now running!"
echo ""
echo "🔧 Useful commands:"
echo "   pm2 status          - Check application status"
echo "   pm2 logs smokeshop  - View live logs"
echo "   pm2 restart smokeshop - Restart application"
echo "   pm2 stop smokeshop  - Stop application"
echo ""
echo "🌐 Access your shop:"
echo "   Local: http://localhost:3000"
echo "   Production: Update NEXT_PUBLIC_SITE_URL in .env.local"
echo ""

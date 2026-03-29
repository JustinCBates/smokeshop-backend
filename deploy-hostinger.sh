#!/bin/bash

# Smokeshop - Hostinger Shared Hosting Deployment Script
# Run this script ON the Hostinger server after SSH connection

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🚀 Smokeshop - Hostinger Shared Hosting Deploy         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Verify we're in the right place
echo "📍 Current directory: $(pwd)"
echo ""
read -p "Is this your domain's public_html directory? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please navigate to the correct directory first:"
    echo "   cd ~/domains/thcdeliveryguy.com/public_html"
    echo "   OR"
    echo "   cd ~/public_html"
    exit 1
fi

# Step 2: Backup existing files (if any)
if [ "$(ls -A .)" ]; then
    echo "📦 Backing up existing files..."
    BACKUP_DIR="../backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    mv * .* "$BACKUP_DIR" 2>/dev/null || true
    echo "   ✅ Backup created at: $BACKUP_DIR"
fi

# Step 3: Clone repository
echo ""
echo "📥 Cloning repository..."
if command -v git &> /dev/null; then
    git clone https://github.com/JustinCBates/Smokeshop.git .
    echo "   ✅ Repository cloned"
else
    echo "   ❌ Git not found. Please install git or upload files manually."
    exit 1
fi

# Step 4: Checkout build branch
echo ""
echo "🔀 Switching to build branch..."
git checkout build
echo "   ✅ On build branch"

# Step 5: Create environment file
echo ""
echo "⚙️  Creating environment configuration..."
cat > .env.production << 'EOF'
NODE_ENV=production
NEXT_PUBLIC_SUPABASE_URL=https://nckaphoqwlikocvpsscr.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_GjlriLVRpv4ZdBHkwKe8Zw_YWoBL6GB
COINBASE_COMMERCE_API_KEY=c9dc40e7-1a95-4bb4-b304-135ab0168f73
NEXT_PUBLIC_SITE_URL=https://thcdeliveryguy.com
AGE_VERIFICATION_PROVIDER=dob-photo
PORT=3000
EOF
echo "   ✅ Environment file created"

# Step 6: Check for Node.js
echo ""
echo "🔍 Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js found: $NODE_VERSION"
else
    echo "   ❌ Node.js not found!"
    echo ""
    echo "   Please enable Node.js in hPanel:"
    echo "   1. Go to Advanced → Node.js"
    echo "   2. Create/configure Node.js application"
    echo "   3. Come back and run this script again"
    exit 1
fi

# Step 7: Install pnpm
echo ""
echo "📦 Installing pnpm..."
if ! command -v pnpm &> /dev/null; then
    npm install -g pnpm
    echo "   ✅ pnpm installed"
else
    echo "   ✅ pnpm already installed"
fi

# Step 8: Install dependencies
echo ""
echo "📦 Installing dependencies..."
echo "   (This may take a few minutes...)"
pnpm install --prod
echo "   ✅ Dependencies installed"

# Step 9: Build application
echo ""
echo "🔨 Building application..."
echo "   (This may take 2-5 minutes...)"
pnpm build
echo "   ✅ Build complete"

# Step 10: Set up PM2
echo ""
echo "🔧 Setting up PM2 process manager..."
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
    echo "   ✅ PM2 installed"
else
    echo "   ✅ PM2 already installed"
fi

# Step 11: Start application
echo ""
echo "🚀 Starting application..."

# Stop any existing instance
pm2 delete smokeshop 2>/dev/null || true

# Start new instance
pm2 start server.js --name smokeshop --time

# Save PM2 configuration
pm2 save

echo "   ✅ Application started"

# Step 12: Display status
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  ✅ Deployment Complete!                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Application Status:"
pm2 status

echo ""
echo "🌐 Your site should now be live at:"
echo "   ${GREEN}https://thcdeliveryguy.com${NC}"
echo ""
echo "📝 Useful commands:"
echo "   pm2 status              - Check application status"
echo "   pm2 logs smokeshop      - View application logs"
echo "   pm2 restart smokeshop   - Restart application"
echo "   pm2 stop smokeshop      - Stop application"
echo "   pm2 start smokeshop     - Start application"
echo ""
echo "🔧 Next steps:"
echo "   1. Visit https://thcdeliveryguy.com to test"
echo "   2. Configure Node.js app in hPanel if not already done"
echo "   3. Check that SSL certificate is active"
echo ""
echo "📌 To update the application later:"
echo "   cd $(pwd)"
echo "   git pull origin build"
echo "   pnpm install"
echo "   pnpm build"
echo "   pm2 restart smokeshop"
echo ""

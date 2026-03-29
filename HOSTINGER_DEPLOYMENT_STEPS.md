# Hostinger Deployment Guide - Step by Step

## 🎯 Goal
Deploy your Smokeshop application to Hostinger using Git

## ✅ Prerequisites Verified
- ✅ hPanel access
- ✅ Domain connected (thcdeliveryguy.com)
- ✅ GitHub repository ready
- ✅ Production build tested successfully

---

## 📋 Step 1: Prepare Hostinger Environment

### 1.1 Enable Node.js Application
1. Log in to [Hostinger hPanel](https://hpanel.hostinger.com)
2. Select your hosting plan
3. Navigate to **Advanced** → **Node.js** (or search for "Node.js")
4. Click **"Create Application"** or **"Setup Node.js"**

### 1.2 Configure Node.js Settings
Set these values:
- **Application Root**: `/domains/thcdeliveryguy.com/public_html` (or similar path shown)
- **Application URL**: `https://thcdeliveryguy.com`
- **Application Startup File**: `server.js`
- **Node.js Version**: Select **Node.js 20.x** or **18.x** (minimum)
- **Application Mode**: **Production**

⚠️ **Important**: Note the exact path to your application root - you'll need it!

---

## 📋 Step 2: Connect via SSH

### 2.1 Enable SSH Access
1. In hPanel, go to **Advanced** → **SSH Access**
2. Click **"Enable SSH"** if not already enabled
3. Note your SSH credentials:
   - **Host**: Usually shown as `ssh.hostinger.com` or your server IP
   - **Port**: Usually `65002` (check hPanel)
   - **Username**: Your hosting username
   - **Password**: Your hosting password or SSH key

### 2.2 Connect to SSH
Open your terminal and connect:
```bash
ssh your-username@ssh.hostinger.com -p 65002
```

Or if you're already on a server, you can connect from there.

---

## 📋 Step 3: Deploy Via Git

### 3.1 Navigate to Application Directory
```bash
cd ~/domains/thcdeliveryguy.com/public_html
# Or the path you noted in Step 1.2
```

### 3.2 Clone Repository
```bash
# Remove any existing files (if directory is empty, skip this)
rm -rf * .* 2>/dev/null || true

# Clone your repository
git clone https://github.com/JustinCBates/Smokeshop.git .
```

⚠️ **Note the dot (`.`) at the end** - this clones into the current directory

### 3.3 Verify Files
```bash
ls -la
# You should see: package.json, server.js, app/, components/, etc.
```

---

## 📋 Step 4: Set Environment Variables

### 4.1 Create Production Environment File
```bash
cat > .env.production << 'EOF'
NODE_ENV=production
NEXT_PUBLIC_SUPABASE_URL=https://nckaphoqwlikocvpsscr.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_GjlriLVRpv4ZdBHkwKe8Zw_YWoBL6GB
COINBASE_COMMERCE_API_KEY=c9dc40e7-1a95-4bb4-b304-135ab0168f73
COINBASE_COMMERCE_WEBHOOK_SECRET=your_webhook_secret_here_optional
NEXT_PUBLIC_SITE_URL=https://thcdeliveryguy.com
AGE_VERIFICATION_PROVIDER=dob-photo
PORT=3000
EOF
```

### 4.2 Verify Environment File
```bash
cat .env.production
```

---

## 📋 Step 5: Install Dependencies & Build

### 5.1 Install Dependencies
```bash
# Use npm (Hostinger usually has npm pre-installed)
npm install --production=false
```

This will take 2-5 minutes depending on server speed.

### 5.2 Build Production Bundle
```bash
npm run build
```

This creates the optimized `.next` directory with your production build.

### 5.3 Verify Build
```bash
ls -la .next/
# You should see: server/, static/, BUILD_ID, etc.
```

---

## 📋 Step 6: Configure Supabase

### 6.1 Update Supabase Site URL
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: `nckaphoqwlikocvpsscr`
3. Navigate to **Authentication** → **URL Configuration**
4. Set **Site URL**: `https://thcdeliveryguy.com`

### 6.2 Add Redirect URLs
Still in **Authentication** → **URL Configuration**:

Add these to **Redirect URLs**:
```
https://thcdeliveryguy.com
https://thcdeliveryguy.com/auth/callback
https://thcdeliveryguy.com/*
```

Click **Save**

---

## 📋 Step 7: Start the Application

### 7.1 Option A: Via Hostinger hPanel (Recommended)
1. Go back to hPanel → **Node.js**
2. Find your application
3. Click **"Restart"** or **"Start"**
4. Wait 10-15 seconds
5. Status should show **"Running"** ✅

### 7.2 Option B: Via PM2 (Advanced)
If Hostinger supports PM2:
```bash
# Install PM2 globally (if not already installed)
npm install -g pm2

# Start application
pm2 start ecosystem.config.js

# Check status
pm2 status

# View logs
pm2 logs smokeshop

# Save PM2 process
pm2 save
```

---

## 📋 Step 8: Configure SSL Certificate

### 8.1 Install SSL Certificate
1. In hPanel, go to **SSL** section
2. Find `thcdeliveryguy.com`
3. Click **"Install SSL"** or enable **Let's Encrypt** (free)
4. Wait 2-5 minutes for certificate to activate

### 8.2 Force HTTPS
1. Still in SSL section
2. Enable **"Force HTTPS"** toggle
3. This redirects all HTTP traffic to HTTPS

---

## 📋 Step 9: Test Your Deployment

### 9.1 Access Your Site
Open: [https://thcdeliveryguy.com](https://thcdeliveryguy.com)

### 9.2 Verify Features
Test these key features:
- ✅ Homepage loads
- ✅ Shop page displays products
- ✅ Location selector works
- ✅ User can sign up/log in (Supabase Auth)
- ✅ Cart functionality works
- ✅ Checkout redirects to Coinbase Commerce
- ✅ Guest checkout available
- ✅ Track order page accessible

### 9.3 Check Browser Console
- Open DevTools (F12)
- Check for any errors in Console
- Verify no 404s in Network tab

---

## 📋 Step 10: Database Setup (If Not Done)

### 10.1 Run Database Migrations
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select project: `nckaphoqwlikocvpsscr`
3. Navigate to **SQL Editor**
4. Run these scripts in order:

**Run these one by one:**
```sql
-- 1. Profiles tables (MUST BE FIRST)
-- Copy and paste scripts/009_create_profiles.sql
-- Then: scripts/009b_profiles_rls.sql
-- Then: scripts/009c_profiles_trigger.sql

-- 2. PostGIS
-- scripts/001_enable_postgis.sql

-- 3. Core tables (run in numerical order)
-- scripts/002_create_products.sql
-- scripts/003_create_regions.sql
-- scripts/004_create_region_inventory.sql
-- scripts/005_create_pickup_locations.sql
-- scripts/006_create_pickup_inventory.sql
-- scripts/007_create_delivery_fee_tiers.sql
-- scripts/008_create_delivery_slots.sql
-- scripts/010_create_orders.sql
-- scripts/011_create_order_items.sql
-- scripts/012_create_storage_bucket.sql

-- 4. New features
-- scripts/014_add_crypto_payments.sql
-- scripts/015_add_guest_checkout.sql

-- 5. Sample data (LAST)
-- scripts/013_seed_sample_data.sql
```

### 10.2 Verify Database
```sql
-- Check products exist
SELECT COUNT(*) FROM products;
-- Should return 24

-- Check regions exist
SELECT COUNT(*) FROM regions;
-- Should return 4 (Kansas City, St. Louis, Springfield, Columbia)
```

---

## 🔧 Troubleshooting

### Application Not Starting
**Check Node.js logs in hPanel:**
1. Go to Node.js section
2. Click on your application
3. View **Error Log** or **Application Log**

Common issues:
- Missing environment variables
- Node.js version too old (need 18+)
- Build didn't complete

**Fix:**
```bash
cd ~/domains/thcdeliveryguy.com/public_html
npm run build
```

### Database Errors
**PGRST205 or "relation does not exist":**
- Run database migrations (Step 10)
- Profiles table MUST be created first

### SSL Not Working
- Wait 5-10 minutes after enabling SSL
- Clear browser cache
- Try incognito mode

### Can't Clone Git Repo
```bash
# If "directory not empty" error:
cd ~/domains/thcdeliveryguy.com
rm -rf public_html
mkdir public_html
cd public_html
git clone https://github.com/JustinCBates/Smokeshop.git .
```

---

## 🔄 Future Updates

### To Deploy Updates:
```bash
# SSH into Hostinger
ssh your-username@ssh.hostinger.com -p 65002

# Navigate to app
cd ~/domains/thcdeliveryguy.com/public_html

# Pull latest changes
git pull origin main

# Install any new dependencies
npm install

# Rebuild
npm run build

# Restart via hPanel or:
pm2 restart smokeshop
```

---

## 📞 Support Resources

- **Hostinger Support**: [hPanel → Support](https://hpanel.hostinger.com)
- **Supabase Docs**: https://supabase.com/docs
- **Coinbase Commerce**: https://commerce.coinbase.com/dashboard

---

## ✅ Final Checklist

Before considering deployment complete:

- [ ] Node.js application created in hPanel
- [ ] SSH access working
- [ ] Git repository cloned
- [ ] Environment variables set (.env.production)
- [ ] Dependencies installed (`npm install`)
- [ ] Production build completed (`npm run build`)
- [ ] Application started (via hPanel or PM2)
- [ ] Supabase Site URL updated
- [ ] Supabase redirect URLs configured
- [ ] SSL certificate installed
- [ ] HTTPS forced
- [ ] Database migrations run
- [ ] Sample data seeded
- [ ] Website accessible at https://thcdeliveryguy.com
- [ ] All features tested and working

---

## 🎉 You're Live!

Once all checklist items are complete, your Smokeshop is deployed and running on Hostinger!

**Site**: https://thcdeliveryguy.com  
**Admin Panel**: https://supabase.com/dashboard (for database management)  
**Payment Dashboard**: https://commerce.coinbase.com/dashboard (for crypto payments)

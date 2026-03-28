# Deployment Guide: Hostinger Hosting

This guide will help you deploy your Smokeshop Next.js application to Hostinger with Supabase and Coinbase Commerce (crypto payments) integration.

## Prerequisites

- Hostinger web hosting plan with Node.js support
- Supabase account and project
- Coinbase Commerce account (for crypto payments)
- Domain name configured in Hostinger

## Step 1: Set Up Supabase Database

### 1.1 Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and create a new project
2. Note your project URL and anon key from Settings > API

### 1.2 Enable PostGIS Extension

1. In Supabase dashboard, go to Database > Extensions
2. Search for "postgis" and enable it
3. Or run the script: `scripts/001_enable_postgis.sql`

### 1.3 Run Database Migrations

Execute all SQL scripts in order from the `scripts/` directory:

```sql
-- Run these in the Supabase SQL Editor in order:
1. scripts/001_enable_postgis.sql
2. scripts/002_create_products.sql
3. scripts/003_create_regions.sql
4. scripts/004_create_region_inventory.sql
5. scripts/005_create_pickup_locations.sql
6. scripts/006_create_pickup_inventory.sql
7. scripts/007_create_delivery_fee_tiers.sql
8. scripts/008_create_delivery_slots.sql
9. scripts/009_create_profiles.sql
10. scripts/009b_profiles_rls.sql
11. scripts/009c_profiles_trigger.sql
12. scripts/010_create_orders.sql
13. scripts/011_create_order_items.sql
14. scripts/012_create_storage_bucket.sql
15. scripts/013_seed_sample_data.sql
16. scripts/014_add_crypto_payments.sql
```

Or run all at once: `scripts/000_run_all.sql`

### 1.4 Configure Authentication

1. Go to Authentication > Settings in Supabase
2. Add your Hostinger domain to "Site URL"
3. Add redirect URLs:
   - `https://yourdomain.com/auth/callback`
   - `https://yourdomain.com`

## Step 2: Set Up Coinbase Commerce (Crypto Payments)

### 2.1 Create Coinbase Commerce Account
1. Go to [https://commerce.coinbase.com](https://commerce.coinbase.com)
2. Sign up or log in with your Coinbase account
3. Complete business verification if required

### 2.2 Get API Key
1. In Coinbase Commerce dashboard, go to Settings
2. Click on "API keys" in the sidebar
3. Click "Create an API key"
4. Copy and securely store your API key (starts with a long string)
5. **Important:** This key is only shown once - save it immediately!

### 2.3 Supported Cryptocurrencies
Coinbase Commerce automatically accepts:
- Bitcoin (BTC)
- Ethereum (ETH)
- USD Coin (USDC) - stablecoin
- Tether (USDT) - stablecoin
- DAI - stablecoin
- Litecoin (LTC)
- Dogecoin (DOGE)
- Bitcoin Cash (BCH)

### 2.4 Configure Settlement (Optional)
1. In Settings > Payouts, choose how to receive funds:
   - Keep as cryptocurrency
   - Auto-convert to your local currency
2. Set up your payout schedule

## Step 3: Deploy to Hostinger

### 3.1 Access Your Hosting Panel

1. Log in to Hostinger hPanel
2. Go to your hosting account

### 3.2 Enable Node.js

1. In hPanel, find "Node.js" or "Application Manager"
2. Create a new Node.js application:
   - **Node.js version**: 18.x or higher
   - **Application mode**: Production
   - **Application root**: `/public_html` or your chosen directory
   - **Application URL**: Your domain
   - **Application startup file**: `server.js` (we'll create this)

### 3.3 Upload Project Files

#### Option A: Using Git (Recommended)

1. In hPanel, go to Git section or use SSH
2. Clone your repository:

```bash
cd ~/public_html
git clone https://github.com/JustinCBates/Smokeshop.git .
```

#### Option B: Using File Manager

1. Compress your project locally (excluding node_modules, .next, .env)
2. Upload via Hostinger File Manager
3. Extract in your application root directory

### 3.4 Create Server File for Hostinger

Create a `server.js` file in the root directory:

```javascript
const { createServer } = require("http");
const { parse } = require("url");
const next = require("next");

const dev = process.env.NODE_ENV !== "production";
const hostname = "localhost";
const port = process.env.PORT || 3000;

const app = next({ dev, hostname, port });
const handle = app.getRequestHandler();

app.prepare().then(() => {
  createServer(async (req, res) => {
    try {
      const parsedUrl = parse(req.url, true);
      await handle(req, res, parsedUrl);
    } catch (err) {
      console.error("Error occurred handling", req.url, err);
      res.statusCode = 500;
      res.end("internal server error");
    }
  })
    .once("error", (err) => {
      console.error(err);
      process.exit(1);
    })
    .listen(port, () => {
      console.log(`> Ready on http://${hostname}:${port}`);
    });
});
```

### 3.5 Configure Environment Variables

1. In Hostinger Node.js application settings, add environment variables:

```env
NODE_ENV=production
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
COINBASE_COMMERCE_API_KEY=your_coinbase_commerce_api_key
NEXT_PUBLIC_SITE_URL=https://yourdomain.com
AGE_VERIFICATION_PROVIDER=dob-photo
```

Alternatively, create a `.env.production` file (not recommended for security):

```bash
cp .env.example .env.production
# Edit with your actual values
nano .env.production
```

### 3.6 Install Dependencies and Build

Connect via SSH to your Hostinger account:

```bash
# Navigate to your project directory
cd ~/public_html

# Install dependencies
npm install --production=false

# Build the Next.js application
npm run build

# Install production dependencies only (optional, for smaller footprint)
npm prune --production
```

### 3.7 Update package.json Scripts

Ensure your `package.json` has this start script:

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "node server.js",
    "lint": "next lint"
  }
}
```

### 3.8 Start the Application

In Hostinger's Node.js application manager:

1. Set the startup file to `server.js`
2. Click "Start" or restart the application

Or via SSH:

```bash
npm start
```

## Step 4: Configure Domain and SSL

### 4.1 Domain Setup

1. In hPanel, go to Domains
2. Point your domain to your hosting account
3. Ensure DNS is properly configured

### 4.2 SSL Certificate

1. In hPanel, go to SSL section
2. Install free SSL certificate (Let's Encrypt)
3. Enable "Force HTTPS"

## Step 5: Verify Deployment

### 5.1 Test the Application

1. Visit `https://yourdomain.com`
2. Test key functionality:
   - Product browsing
   - Location selection (PostGIS features)
   - User registration/login (Supabase Auth)
   - Checkout process (Stripe)

### 5.2 Check Logs

Monitor application logs in Hostinger panel or via SSH:

```bash
pm2 logs # if using PM2
# or check Node.js application logs in hPanel
```

## Troubleshooting

### Application won't start

- Check Node.js version is compatible (18+)
- Verify all environment variables are set
- Check build completed successfully: `npm run build`
- Review error logs

### Database connection issues

- Verify Supabase URL and keys are correct
- Check Supabase project is not paused
- Ensure PostGIS extension is enabled

### Stripe not working

- Confirm webhook URL is correct if using webhooks
- Check API keys are from the correct mode (test/live)
- Verify NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY is set

### Static files not loading

- Ensure `.next` folder is built and present
- Check file permissions (755 for directories, 644 for files)
- Verify Next.js configuration allows your domain

### Performance issues

- Use Node.js production mode: `NODE_ENV=production`
- Enable caching in Hostinger
- Consider using PM2 for process management

## Alternative: Using PM2 (Process Manager)

For better process management, you can use PM2:

```bash
# Install PM2 globally
npm install -g pm2

# Create ecosystem file
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'smokeshop',
    script: 'server.js',
    instances: 1,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
}
EOF

# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on reboot
pm2 startup
```

## Maintenance

### Updating the Application

```bash
cd ~/public_html
git pull origin main
npm install
npm run build
pm2 restart smokeshop  # or restart via hPanel
```

### Database Backups

- Use Supabase automatic backups (available in paid plans)
- Or export database regularly via Supabase dashboard

### Monitoring

- Set up Supabase alerts for database issues
- Monitor Stripe dashboard for payment issues
- Check Hostinger resource usage regularly

## Security Checklist

- ✅ SSL certificate installed and HTTPS enforced
- ✅ Environment variables stored securely (not in .env files in production)
- ✅ Supabase Row Level Security (RLS) enabled
- ✅ Stripe webhooks using webhook signatures
- ✅ .env files added to .gitignore
- ✅ Database credentials not exposed in client code
- ✅ Regular security updates: `npm audit fix`

## Support Resources

- **Hostinger Support**: [https://www.hostinger.com/tutorials](https://www.hostinger.com/tutorials)
- **Supabase Docs**: [https://supabase.com/docs](https://supabase.com/docs)
- **Stripe Docs**: [https://stripe.com/docs](https://stripe.com/docs)
- **Next.js Deployment**: [https://nextjs.org/docs/deployment](https://nextjs.org/docs/deployment)

---

## Quick Deployment Checklist

- [ ] Supabase project created
- [ ] PostGIS extension enabled
- [ ] All database migrations run
- [ ] Supabase auth redirect URLs configured
- [ ] Stripe API keys obtained
- [ ] Hostinger Node.js application created
- [ ] Project files uploaded
- [ ] Environment variables configured
- [ ] Dependencies installed (`npm install`)
- [ ] Application built (`npm run build`)
- [ ] server.js created
- [ ] Application started
- [ ] Domain configured
- [ ] SSL certificate installed
- [ ] Application tested and verified
# Last deployed: Thu Feb 19 00:26:40 UTC 2026

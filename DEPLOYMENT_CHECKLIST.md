# Hostinger Deployment - Quick Reference

## 📋 Pre-Deployment Checklist

### Supabase Setup

- [ ] Create Supabase project at supabase.com
- [ ] Copy Project URL from Settings → API
- [ ] Copy Anon Key from Settings → API
- [ ] Enable PostGIS: Database → Extensions → Enable "postgis"
- [ ] Run all SQL scripts in `scripts/` folder (or run `000_run_all.sql`)
- [ ] Add domain to Auth Settings → Site URL
- [ ] Add auth callback URL: `https://yourdomain.com/auth/callback`

### Coinbase Commerce Setup
- [ ] Create account at commerce.coinbase.com
- [ ] Complete business verification
- [ ] Copy API Key from Settings → API keys
- [ ] Configure payout settings (crypto or fiat conversion)

### Hostinger Setup

- [ ] Log in to Hostinger hPanel
- [ ] Enable Node.js application (version 18+)
- [ ] Note application root directory (usually `/public_html`)
- [ ] Ensure domain is configured
- [ ] Install SSL certificate (Let's Encrypt)

## 🚀 Deployment Steps

### 1. Upload Files to Hostinger

**Via Git (Recommended):**

```bash
cd ~/public_html
git clone https://github.com/JustinCBates/Smokeshop.git .
```

**Via File Manager:**

- Upload all files except: node_modules, .next, .env, .git

### 2. Set Environment Variables

In Hostinger Node.js app settings or create `.env.production`:

```env
NODE_ENV=production
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
COINBASE_COMMERCE_API_KEY=your_api_key_here
NEXT_PUBLIC_SITE_URL=https://yourdomain.com
AGE_VERIFICATION_PROVIDER=dob-photo
```

### 3. Build and Deploy

```bash
# SSH into Hostinger
cd ~/public_html

# Install dependencies
npm install

# Build the application
npm run build

# Start the application
npm start
```

Or configure in Hostinger Node.js panel:

- **Startup file**: `server.js`
- **Application mode**: Production

### 4. Verify Deployment

- [ ] Visit https://yourdomain.com
- [ ] Test product browsing
- [ ] Test location selection (map)
- [ ] Test user registration
- [ ] Test crypto checkout (use small amount for testing)

## 🔧 Using PM2 (Optional but Recommended)

```bash
# Install PM2
npm install -g pm2

# Start application
pm2 start ecosystem.config.js

# Save configuration
pm2 save

# Set up auto-restart on reboot
pm2 startup
```

PM2 Commands:

- `pm2 status` - Check application status
- `pm2 logs smokeshop` - View logs
- `pm2 restart smokeshop` - Restart app
- `pm2 stop smokeshop` - Stop app
- `pm2 delete smokeshop` - Remove from PM2

## 🔄 Updating Your Deployment

```bash
cd ~/public_html
git pull origin main
npm install
npm run build
pm2 restart smokeshop  # or restart via Hostinger panel
```

## ❗ Troubleshooting

### App Won't Start

```bash
# Check build
npm run build

# Check logs
pm2 logs smokeshop
# or check in Hostinger panel

# Verify environment variables
printenv | grep NEXT_PUBLIC
```

### Database Connection Issues

- Verify Supabase URL and keys in environment variables
- Check Supabase project status (not paused)
- Test connection: `psql` with Supabase connection string

### Stripe Issues

- Verify API keys match mode (test vs live)
- Check webhook secret if using webhooks
- Review Stripe logs in dashboard

### 502/504 Errors

- Check Node.js application is running
- Verify port configuration (default 3000)
- Restart application
- Check server resources (RAM/CPU)

## 📞 Support Resources

- **Hostinger**: https://www.hostinger.com/tutorials/how-to-deploy-nodejs
- **Supabase**: https://supabase.com/docs
- **Stripe**: https://stripe.com/docs
- **Next.js**: https://nextjs.org/docs/deployment

## 🧪 Test Credentials for Development

**Stripe Test Cards:**

- Success: 4242 4242 4242 4242
- Decline: 4000 0000 0000 0002
- 3D Secure: 4000 0025 0000 3155

**Test the following features:**

1. Product catalog loading
2. Location/region selection (PostGIS)
3. User authentication (Supabase)
4. Shopping cart functionality
5. Checkout process (Stripe)
6. Order confirmation
7. Age verification modal

## 📈 Performance Tips

- Enable caching in Hostinger
- Use PM2 cluster mode for multiple instances
- Optimize images (already configured in next.config.mjs)
- Monitor with `pm2 monit`
- Set up error tracking (Sentry, etc.)

---

✅ **Deployment Complete!** Your smokeshop is now live on Hostinger.

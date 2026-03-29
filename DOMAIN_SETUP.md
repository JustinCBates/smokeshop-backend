# Domain Setup Guide: neutraldevelopment.com

This guide walks you through setting up `neutraldevelopment.com` with Hostinger for both production and staging environments.

## Overview

- **Production:** `neutraldevelopment.com` → `/home/u733577836/domains/thcdeliveryguy.com/public_html`
- **Staging:** `staging.neutraldevelopment.com` → `/home/u733577836/domains/thcdeliveryguy.com/public_html/staging`
- **Server IP:** `82.29.199.157`
- **Ports:** Production (3000), Staging (3001)

---

## Part 1: Add Domain to Hostinger (hPanel)

### Step 1: Add Primary Domain

1. Log in to **hPanel** (Hostinger control panel)
2. Navigate to **Domains** → **Add Domain**
3. Select **"I will update my nameservers"**
4. Enter: `neutraldevelopment.com`
5. Click **Add Domain**

### Step 2: Point Domain to Existing Directory

Since you're adding a new domain to an existing account:

1. In hPanel, go to **Domains** → **Manage** for `neutraldevelopment.com`
2. Click **"Change Document Root"** or **"Domain Settings"**
3. Set Document Root to: `/domains/thcdeliveryguy.com/public_html`
   - This points the new domain to your existing deployment folder
   - Both domains (`thcdeliveryguy.com` and `neutraldevelopment.com`) will serve the same files

### Step 3: Add Staging Subdomain

1. In hPanel, go to **Domains** → **Subdomains**
2. Click **Create Subdomain**
3. Enter subdomain: `staging`
4. Select parent domain: `neutraldevelopment.com`
5. Set Document Root: `/domains/thcdeliveryguy.com/public_html/staging`
6. Click **Create**

---

## Part 2: Configure DNS

### Option A: Use Hostinger Nameservers (Recommended)

1. Go to your domain registrar where you purchased `neutraldevelopment.com`
2. Update nameservers to Hostinger's:
   ```
   ns1.dns-parking.com
   ns2.dns-parking.com
   ```
   - Or use the nameservers shown in your hPanel for this domain
3. Wait for DNS propagation (usually 30 minutes, up to 24 hours)

**Hostinger will automatically configure DNS records for you.**

### Option B: Keep Current Registrar DNS (Custom A Records)

If you want to keep your current registrar's DNS:

1. Log in to your domain registrar's DNS management
2. Add these **A records**:
   ```
   Type: A
   Name: @
   Value: 82.29.199.157
   TTL: 3600

   Type: A
   Name: staging
   Value: 82.29.199.157
   TTL: 3600

   Type: A
   Name: www
   Value: 82.29.199.157
   TTL: 3600
   ```

---

## Part 3: Install SSL Certificates

1. In hPanel, go to **Security** → **SSL**
2. Find `neutraldevelopment.com` in the list
3. Click **Install SSL** → Select **"Free Lifetime SSL"**
4. Wait for installation (usually instant)
5. Repeat for `staging.neutraldevelopment.com`
6. Verify both show **"Active"** status

**Note:** SSL won't work until DNS is propagated and pointing to Hostinger's servers.

---

## Part 4: Update index.php (PHP Proxy)

The current `index.php` should already handle the new domain, but verify:

**Production index.php** (`/public_html/index.php`):
```php
$nodeUrl = 'http://127.0.0.1:3000';  // Production port
```

**Staging index.php** (`/public_html/staging/index.php`):
```php
$nodeUrl = 'http://127.0.0.1:3001';  // Staging port
```

Both files accept any domain name and forward to their respective Node.js ports.

---

## Part 5: Test Domains (After DNS Propagation)

### Check DNS Resolution

```bash
# Check if DNS is propagated
nslookup neutraldevelopment.com
nslookup staging.neutraldevelopment.com

# Should return: 82.29.199.157
```

### Test HTTP Access

```bash
# Production
curl -I http://neutraldevelopment.com

# Staging
curl -I http://staging.neutraldevelopment.com

# Both should return: HTTP 200 OK or HTTP 301/302 redirect
```

### Test HTTPS Access (After SSL Installed)

```bash
# Production
curl -I https://neutraldevelopment.com

# Staging
curl -I https://staging.neutraldevelopment.com

# Should return: HTTP 200 OK
```

### Browser Test

1. Visit `http://neutraldevelopment.com` (should work immediately after DNS)
2. Visit `http://staging.neutraldevelopment.com` (should work immediately)
3. Visit `https://neutraldevelopment.com` (requires SSL + LiteSpeed config)
4. Visit `https://staging.neutraldevelopment.com` (requires SSL + LiteSpeed config)

---

## Part 6: Deploy from GitHub

Once DNS and SSL are ready:

### Trigger Production Deployment

```bash
git checkout main
git pull origin main
git push  # Triggers deploy-production.yml
```

**Monitors:** https://github.com/JustinCBates/Smokeshop/actions

### Trigger Staging Deployment

```bash
git checkout build
git merge main
git push  # Triggers deploy-staging.yml
```

---

## Troubleshooting

### Issue: Domain shows "Site Not Found" or parking page

**Cause:** DNS not propagated or not pointing to Hostinger  
**Solution:** Wait up to 24 hours, check nameservers

### Issue: HTTP works but HTTPS gives ERR_SSL_PROTOCOL_ERROR

**Cause:** LiteSpeed not configured for HTTPS on port 443  
**Solution:** Contact Hostinger support:

```
Subject: HTTPS configuration needed for neutraldevelopment.com

I've added neutraldevelopment.com to my account and installed SSL certificates,
but HTTPS returns ERR_SSL_PROTOCOL_ERROR. HTTP works fine.

Domain: neutraldevelopment.com
Subdomain: staging.neutraldevelopment.com
Account: u733577836
Server IP: 82.29.199.157

SSL certificates show as "Active" in hPanel. Please configure LiteSpeed to 
serve these domains on port 443.
```

### Issue: Both old and new domains show the same content

**Expected:** This is correct! Both `thcdeliveryguy.com` and `neutraldevelopment.com` point to the same files.  
**To change:** You would need to set different document roots for each domain

---

## GitHub Secrets (Should Already Be Set)

No new secrets needed! The workflows use:

- `HOSTINGER_SSH_HOST` → `82.29.199.157`
- `HOSTINGER_SSH_PORT` → `65002`
- `HOSTINGER_SSH_USER` → `u733577836`
- `HOSTINGER_SSH_KEY` → (your private key)
- `HOSTINGER_DEPLOY_PATH` → `/home/u733577836/domains/thcdeliveryguy.com/public_html`
- `STAGING_DEPLOY_PATH` → `/home/u733577836/domains/thcdeliveryguy.com/public_html/staging`
- `SUPABASE_URL` → (your Supabase URL)
- `SUPABASE_ANON_KEY` → (your Supabase anon key)
- `COINBASE_COMMERCE_API_KEY` → (your Coinbase key)
- `COINBASE_WEBHOOK_SECRET` → (your webhook secret)

---

## Next Steps

1. ✅ Add `neutraldevelopment.com` to Hostinger
2. ✅ Add `staging.neutraldevelopment.com` subdomain
3. ✅ Configure DNS (nameservers or A records)
4. ⏳ Wait for DNS propagation (check with `nslookup`)
5. ✅ Install SSL certificates for both domains
6. ⏳ Contact Hostinger support for HTTPS configuration (if needed)
7. ✅ Test HTTP access (should work immediately after DNS)
8. ⏳ Test HTTPS access (may require Hostinger support)
9. ✅ Push to `main` to deploy production
10. ✅ Push to `build` to deploy staging

---

## Summary

- **Production URL:** https://neutraldevelopment.com (deploy from `main` branch)
- **Staging URL:** https://staging.neutraldevelopment.com (deploy from `build` branch)
- **Old Domain:** `thcdeliveryguy.com` still works, points to same files
- **Neutral Branding:** Site now shows "Botanical Wellness Co" instead of cannabis-explicit branding
- **Development Access:** `neutraldevelopment.com` won't be blocked at cafes/public WiFi

Your site is now ready for development from anywhere! 🎉

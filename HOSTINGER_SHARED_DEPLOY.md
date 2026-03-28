# Deploy to Hostinger Shared Hosting - Quick Guide

## 🎯 Current Status

**Problem Identified:**

- Domain: thcdeliveryguy.com (82.29.199.157)
- Points to: Hostinger shared hosting plan
- Status: Blank page (nothing deployed)

**VPS Confusion:**

- You have a VPS at srv1407636.hstgr.cloud (different server)
- That's NOT where thcdeliveryguy.com points
- We need to deploy to the shared hosting plan instead

---

## 📋 Step 1: Get Hostinger Hosting Credentials

### Find Your SSH/FTP Access:

1. **Log in to Hostinger hPanel**
   - Go to: https://hpanel.hostinger.com
   - Log in with your Hostinger account

2. **Find thcdeliveryguy.com hosting**
   - Look for "thcdeliveryguy.com" in your hosting list
   - Click on it to manage

3. **Get SSH Access (Preferred)**
   - Go to: **Advanced** → **SSH Access**
   - Note these details:
     ```
     SSH Host: _____________________
     SSH Port: _____________________ (usually 65002)
     SSH Username: _________________
     SSH Password: _________________ (or use SSH key)
     ```

4. **Alternative: FTP Access**
   - Go to: **Files** → **FTP Accounts**
   - Note FTP credentials if SSH isn't available

---

## 📋 Step 2: Find Application Directory

In hPanel for thcdeliveryguy.com:

1. **Check Node.js Settings**
   - Go to: **Advanced** → **Node.js**
   - Check if Node.js app is set up
   - Note the **Application Root** path

   Common paths:
   - `/home/u{numbers}/domains/thcdeliveryguy.com/public_html`
   - `/home/{username}/public_html`
   - `/domains/thcdeliveryguy.com/public_html`

2. **If Node.js Not Set Up:**
   - Click **"Setup Node.js"** or **"Create Application"**
   - Select Node.js version: **20.x** or **18.x**
   - Note the path it gives you

---

## 📋 Step 3: Connect and Deploy

### Option A: Using SSH (Recommended)

Once you have the credentials:

```bash
# Connect to Hostinger shared hosting
ssh {your-username}@{ssh-host} -p {port}

# Example:
# ssh u123456789@srv12345.hstgr.cloud -p 65002

# Navigate to your domain directory
cd domains/thcdeliveryguy.com/public_html
# OR
cd public_html

# Check what's there
pwd
ls -la
```

### Option B: Using File Manager (If No SSH)

1. In hPanel → **Files** → **File Manager**
2. Navigate to thcdeliveryguy.com directory
3. Use Git to pull code (if Git is available)
4. Or upload files via FTP

---

## 📋 Step 4: Deploy the Application

Once connected to the correct server:

```bash
# 1. Remove any existing files
rm -rf * .* 2>/dev/null || true

# 2. Clone the repository
git clone https://github.com/JustinCBates/Smokeshop.git .

# 3. Checkout the build branch
git checkout build

# 4. Create environment file
cat > .env.production << 'EOF'
NODE_ENV=production
NEXT_PUBLIC_SUPABASE_URL=https://nckaphoqwlikocvpsscr.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_GjlriLVRpv4ZdBHkwKe8Zw_YWoBL6GB
COINBASE_COMMERCE_API_KEY=c9dc40e7-1a95-4bb4-b304-135ab0168f73
NEXT_PUBLIC_SITE_URL=https://thcdeliveryguy.com
AGE_VERIFICATION_PROVIDER=dob-photo
PORT=3000
EOF

# 5. Install pnpm (if not available)
npm install -g pnpm

# 6. Install dependencies
pnpm install

# 7. Build the application
pnpm build

# 8. Start with PM2
npm install -g pm2
pm2 start server.js --name smokeshop
pm2 save
pm2 startup # Follow the instructions it gives

# 9. Check status
pm2 status
pm2 logs smokeshop --lines 20
```

---

## 📋 Step 5: Configure Node.js in hPanel

After deploying files:

1. Go back to hPanel → **Node.js**
2. Configure:
   - **Application Root**: Your directory path
   - **Application Startup File**: `server.js`
   - **Node.js Version**: 20.x or 18.x
   - **Application Mode**: Production
   - **Application URL**: https://thcdeliveryguy.com

3. Click **"Start"** or **"Restart"**

---

## 🔍 Troubleshooting

### Can't Find SSH Credentials?

1. In hPanel → **Help** → **Live Chat**
2. Ask: "I need SSH credentials for thcdeliveryguy.com"

### SSH Not Available?

Some Hostinger plans don't include SSH. In that case:

1. Use File Manager to upload code
2. Or upgrade to a plan with SSH access
3. Or use GitHub Actions to auto-deploy

### Node.js Not Available?

Check your hosting plan. Node.js requires:

- Premium Web Hosting or higher
- Business Web Hosting
- Cloud Hosting
- VPS

If not available, you need to upgrade or use the VPS.

---

## 🎯 Quick Action Items

**Right now, do these in order:**

1. ✅ Log in to hPanel: https://hpanel.hostinger.com

2. ✅ Find thcdeliveryguy.com in your hosting list

3. ✅ Check: Advanced → SSH Access
   - Write down: Host, Port, Username

4. ✅ Check: Advanced → Node.js
   - Is it available?
   - What's the Application Root path?

5. ✅ Tell me what you find:
   - "I have SSH access" - send me the host/port
   - "No SSH available" - we'll use FTP/File Manager
   - "No Node.js" - we need to upgrade or use VPS

---

Once you have the credentials, I'll create a one-command deployment script that handles everything! 🚀

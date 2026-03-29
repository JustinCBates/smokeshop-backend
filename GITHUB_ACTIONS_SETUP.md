# GitHub Actions Setup - Quick Start

Complete these steps to enable automated deployments.

## 📋 Step 1: Configure GitHub Secrets

Go to: https://github.com/JustinCBates/Smokeshop/settings/secrets/actions

Click **"New repository secret"** for each of these:

### Application Secrets (Copy from .env.local)

```
Name: SUPABASE_URL
Value: https://nckaphoqwlikocvpsscr.supabase.co
```

```
Name: SUPABASE_ANON_KEY
Value: sb_publishable_GjlriLVRpv4ZdBHkwKe8Zw_YWoBL6GB
```

```
Name: COINBASE_COMMERCE_API_KEY
Value: c9dc40e7-1a95-4bb4-b304-135ab0168f73
```

```
Name: COINBASE_WEBHOOK_SECRET
Value: your_webhook_secret_here_optional
```

---

## 📋 Step 2: Get Hostinger SSH Details

### 2.1 Find SSH Connection Info

1. Log in to **Hostinger hPanel**: https://hpanel.hostinger.com
2. Go to **Advanced** → **SSH Access**
3. Note these values:
   - **Hostname**: (e.g., `ssh.hostinger.com`)
   - **Port**: (usually `65002`)
   - **Username**: (e.g., `u123456789`)

### 2.2 Generate SSH Key Pair

On your local machine (or this server):
```bash
ssh-keygen -t rsa -b 4096 -C "github-deploy" -f ~/.ssh/hostinger_deploy -N ""
```

### 2.3 Copy Public Key to Hostinger

```bash
# Display public key
cat ~/.ssh/hostinger_deploy.pub
```

**Then in Hostinger hPanel:**
1. Go to **Advanced** → **SSH Access**
2. Click **"Manage SSH Keys"**
3. Paste the public key
4. Save

### 2.4 Test SSH Connection

```bash
ssh -p 65002 -i ~/.ssh/hostinger_deploy username@ssh.hostinger.com
```

If successful, you'll see Hostinger's welcome message.

### 2.5 Find Deployment Path

While connected via SSH:
```bash
cd ~/domains/thcdeliveryguy.com/public_html
pwd
```

The output is your deployment path (e.g., `/home/u123456789/domains/thcdeliveryguy.com/public_html`)

---

## 📋 Step 3: Add Hostinger Secrets to GitHub

Go back to: https://github.com/JustinCBates/Smokeshop/settings/secrets/actions

### Copy Private Key

```bash
cat ~/.ssh/hostinger_deploy
```

Add these secrets:

```
Name: HOSTINGER_SSH_HOST
Value: ssh.hostinger.com  (or your actual hostname)
```

```
Name: HOSTINGER_SSH_PORT
Value: 65002  (or your actual port)
```

```
Name: HOSTINGER_SSH_USER
Value: u123456789  (your actual username)
```

```
Name: HOSTINGER_SSH_KEY
Value: [paste entire private key including -----BEGIN and -----END lines]
```

```
Name: HOSTINGER_DEPLOY_PATH
Value: /home/u123456789/domains/thcdeliveryguy.com/public_html  (your actual path)
```

---

## 📋 Step 4: Install PM2 on Hostinger (if not already)

SSH into Hostinger:
```bash
ssh -p 65002 username@ssh.hostinger.com
```

Install PM2 globally:
```bash
npm install -g pm2
```

Verify:
```bash
pm2 --version
```

---

## 📋 Step 5: Commit and Push Workflows

```bash
cd /opt/Smokeshop
git add .github/
git commit -m "Add automated CI/CD workflows"
git push origin main
```

**This will trigger the first deployment!**

---

## ✅ Verification Checklist

Before pushing to `main`, verify:

- [ ] All 9 GitHub secrets configured
- [ ] SSH public key added to Hostinger
- [ ] SSH connection tested successfully
- [ ] Deployment path verified
- [ ] PM2 installed on Hostinger
- [ ] Node.js 18+ available on Hostinger

---

## 🚀 How It Works

### After Setup:

**On Pull Request:**
- ✅ Linter runs
- ✅ Build tested
- ✅ Shows pass/fail status

**On Push to `main`:**
- 🔨 Builds production bundle
- 📦 Creates deployment package
- 🚀 Deploys to Hostinger via SSH
- 🔄 Restarts PM2 application
- ✅ Verifies site is accessible

### Monitor Deployments:
https://github.com/JustinCBates/Smokeshop/actions

---

## 🛠️ Manual Deployment Trigger

If you need to redeploy without pushing code:

1. Go to: https://github.com/JustinCBates/Smokeshop/actions
2. Click **"Deploy to Hostinger"** workflow
3. Click **"Run workflow"** button
4. Select `main` branch
5. Click **"Run workflow"**

---

## 📝 Next Steps

1. Complete Step 1-4 above
2. Push the workflows to GitHub
3. Watch the first deployment in Actions tab
4. If successful: ✅ You're done!
5. If failed: Check logs and troubleshoot

---

## ⚠️ Important Notes

- Never commit SSH private keys to the repository
- Keep GitHub secrets secure - don't share them
- The first deployment might take 2-3 minutes
- Subsequent deployments are faster (1-2 minutes)
- Monitor the Actions tab for deployment status

---

## 🆘 Troubleshooting

**"Missing required secrets"**
→ Go back to Step 1 and add all secrets

**"Permission denied (publickey)"**
→ Check SSH key is added to Hostinger (Step 2.3)

**"pm2 not found"**
→ Install PM2 on Hostinger (Step 4)

**Build fails**
→ Check secrets are correct and match your .env.local

Need help? Check: `.github/workflows/README.md`

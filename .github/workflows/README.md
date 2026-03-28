# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the Smokeshop application.

## Workflows

### 1. CI - Build & Test (`ci.yml`)
**Triggers:** Pull requests to `build` or `main`, pushes to `working` or `build`

**What it does:**
- Checks out code
- Sets up Node.js 20
- Installs dependencies with pnpm
- Runs linter
- Builds the application
- Verifies build output

**Purpose:** Ensures code quality and builds successfully before merging.

---

### 2. Deploy to Hostinger (`deploy.yml`)
**Triggers:** Pushes to `main`, manual workflow dispatch

**What it does:**
1. Builds production bundle
2. Creates deployment package
3. Creates `.env.production` with secrets
4. Connects to Hostinger via SSH
5. Syncs files using rsync
6. Installs production dependencies
7. Restarts PM2 application
8. Verifies deployment

**Purpose:** Automatically deploys to production when code is pushed to `main`.

---

## Required GitHub Secrets

To use these workflows, configure the following secrets in your GitHub repository settings:

**Go to:** `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

### Application Secrets

| Secret Name | Example Value | Description |
|-------------|---------------|-------------|
| `SUPABASE_URL` | `https://xxxxx.supabase.co` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6...` | Supabase anonymous/public key |
| `COINBASE_COMMERCE_API_KEY` | `c9dc40e7-1a95-4bb4-...` | Coinbase Commerce API key |
| `COINBASE_WEBHOOK_SECRET` | `your_webhook_secret` | Coinbase webhook secret (optional) |

### Hostinger SSH Secrets

| Secret Name | Example Value | Description |
|-------------|---------------|-------------|
| `HOSTINGER_SSH_HOST` | `ssh.hostinger.com` | Hostinger SSH hostname |
| `HOSTINGER_SSH_PORT` | `65002` | SSH port (usually 65002) |
| `HOSTINGER_SSH_USER` | `u123456789` | Your Hostinger SSH username |
| `HOSTINGER_SSH_KEY` | `-----BEGIN OPENSSH PRIVATE KEY-----...` | Your SSH private key |
| `HOSTINGER_DEPLOY_PATH` | `~/domains/thcdeliveryguy.com/public_html` | Deployment directory path |

---

## Setting Up SSH Key for Deployment

### 1. Generate SSH Key Pair (if you don't have one)

On your local machine:
```bash
ssh-keygen -t rsa -b 4096 -C "github-actions@thcdeliveryguy.com" -f ~/.ssh/hostinger_deploy
```

This creates:
- Private key: `~/.ssh/hostinger_deploy`
- Public key: `~/.ssh/hostinger_deploy.pub`

### 2. Add Public Key to Hostinger

1. Copy your public key:
   ```bash
   cat ~/.ssh/hostinger_deploy.pub
   ```

2. Log in to Hostinger hPanel
3. Go to **Advanced** → **SSH Access**
4. Click **"Manage SSH Keys"** or **"Add SSH Key"**
5. Paste the public key content
6. Save

### 3. Add Private Key to GitHub Secrets

1. Copy your private key:
   ```bash
   cat ~/.ssh/hostinger_deploy
   ```

2. Go to GitHub: `Settings` → `Secrets and variables` → `Actions`
3. Click **"New repository secret"**
4. Name: `HOSTINGER_SSH_KEY`
5. Value: Paste the entire private key (including `-----BEGIN...` and `-----END...`)
6. Click **"Add secret"**

### 4. Get Hostinger SSH Details

1. In Hostinger hPanel → **Advanced** → **SSH Access**
2. Note these values:
   - **Hostname**: Usually `ssh.hostinger.com` or an IP
   - **Port**: Usually `65002`
   - **Username**: Your hosting username (e.g., `u123456789`)

3. Add each as a GitHub secret

### 5. Find Your Deployment Path

SSH into Hostinger and run:
```bash
pwd
cd ~/domains/thcdeliveryguy.com/public_html
pwd
```

The output is your `HOSTINGER_DEPLOY_PATH` (e.g., `/home/u123456789/domains/thcdeliveryguy.com/public_html`)

---

## How to Use

### Automatic Deployment
1. Make changes to your code
2. Commit and push to `main` branch:
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```
3. GitHub Actions automatically:
   - Builds the application
   - Deploys to Hostinger
   - Restarts the server
4. Check deployment status in the **Actions** tab

### Manual Deployment
1. Go to: `Actions` → `Deploy to Hostinger`
2. Click **"Run workflow"**
3. Select branch: `main`
4. Click **"Run workflow"**

### Testing Before Merging
1. Create a pull request
2. CI workflow runs automatically
3. Check if build passes
4. Merge when all checks are green ✅

---

## Monitoring Deployments

### View Workflow Runs
- Go to repository → **Actions** tab
- Click on any workflow run to see details
- View logs for each step

### Deployment Failed?
1. Check the workflow logs in **Actions** tab
2. Look for error messages in red
3. Common issues:
   - Missing secrets
   - SSH connection failed
   - Build errors
   - Permissions issues

### Rollback
If a deployment breaks the site:
```bash
# SSH into Hostinger
ssh -p 65002 username@ssh.hostinger.com

# Navigate to app
cd ~/domains/thcdeliveryguy.com/public_html

# Pull previous commit
git reset --hard HEAD~1

# Rebuild
npm install
npm run build

# Restart
pm2 restart smokeshop
```

---

## Environment-Specific Deployments (Optional)

To add staging environment:

1. Create a `develop` branch
2. Add staging secrets (same names with `_STAGING` suffix)
3. Modify `deploy.yml` to deploy `develop` → staging server

---

## Security Best Practices

✅ **DO:**
- Use GitHub Secrets for all sensitive data
- Rotate SSH keys periodically
- Use deploy keys (read-only for production)
- Enable 2FA on GitHub account
- Review workflow runs regularly

❌ **DON'T:**
- Commit private keys to repository
- Share secrets in pull request comments
- Use personal SSH keys for deployment
- Store passwords in workflow files
- Disable required status checks

---

## Troubleshooting

### "Permission denied (publickey)"
- Verify SSH key is added to Hostinger
- Check `HOSTINGER_SSH_KEY` secret is correct
- Ensure key doesn't have a passphrase

### "rsync: command not found"
- Install rsync on Hostinger server
- Or switch to `scp` in deploy workflow

### "pm2: command not found"
- Install PM2 globally on Hostinger: `npm install -g pm2`
- Or use hPanel restart instead

### Build succeeds locally but fails in CI
- Check Node.js version matches (20.x)
- Verify all secrets are set
- Review environment variables

---

## Support

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Hostinger Support**: https://www.hostinger.com/tutorials
- **Project Issues**: https://github.com/JustinCBates/Smokeshop/issues

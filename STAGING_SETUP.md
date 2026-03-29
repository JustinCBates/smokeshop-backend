# Dual Environment Setup - GitHub Secrets

## Current Secrets (Already Set)
- `HOSTINGER_SSH_HOST` - SSH server IP (82.29.199.157)
- `HOSTINGER_SSH_PORT` - SSH port (65002)
- `HOSTINGER_SSH_USER` - SSH username (u733577836)
- `HOSTINGER_SSH_KEY` - SSH private key
- `HOSTINGER_DEPLOY_PATH` - Production deployment path
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key
- `COINBASE_COMMERCE_API_KEY` - Coinbase Commerce API key
- `COINBASE_WEBHOOK_SECRET` - Coinbase webhook secret

## New Secret Required for Staging

### Add in GitHub Settings → Secrets and Variables → Actions:

**`STAGING_DEPLOY_PATH`**
- Value: `/home/u733577836/domains/staging.thcdeliveryguy.com/public_html`
- Used by: deploy-staging.yml workflow

## Environment Configuration

### Production (main branch → port 3000)
- Domain: https://thcdeliveryguy.com
- Path: `/home/u733577836/domains/thcdeliveryguy.com/public_html`
- Port: 3000
- Branch: main
- Workflow: .github/workflows/deploy-production.yml

### Staging (build branch → port 3001)
- Domain: https://staging.thcdeliveryguy.com
- Path: `/home/u733577836/domains/staging.thcdeliveryguy.com/public_html`
- Port: 3001
- Branch: build
- Workflow: .github/workflows/deploy-staging.yml

## Deployment Flow

1. **Development**
   - Work in `working` branch locally
   - Push to GitHub

2. **Staging**
   - Create PR: `working` → `build`
   - Merge to `build` branch
   - Auto-deploys to https://staging.thcdeliveryguy.com
   - Test thoroughly

3. **Production**
   - Create PR: `build` → `main`
   - Merge to `main` branch
   - Auto-deploys to https://thcdeliveryguy.com

## Both Environments Use
- Same Supabase project (for now)
- Same SSH credentials
- Same Coinbase Commerce keys (can separate later if needed)

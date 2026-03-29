# Build Fixes & Environment Configuration

## Recent Build Issue Fixed

### Problem
The application failed to build on Hostinger with the error:
```
Neither apiKey nor config.authenticator was provided
```

### Root Cause
The Stripe client was being instantiated at the module level with `process.env.STRIPE_SECRET_KEY!`, which would be `undefined` during the build phase when environment variables aren't yet loaded.

### Solution Applied
Updated the following files to use lazy initialization and proper environment variable validation:

1. **lib/stripe.ts** - Stripe client now uses lazy initialization via Proxy
2. **lib/supabase/client.ts** - Added environment variable validation
3. **lib/supabase/server.ts** - Added environment variable validation
4. **lib/supabase/middleware.ts** - Added environment variable validation with fallback
5. **lib/env.ts** - Created comprehensive environment validation utility

## Environment Variables Setup for Hostinger

### Step 1: Create Environment File

On Hostinger, you need to set environment variables. You have two options:

#### Option A: Via Hostinger Panel (Recommended)

1. Log in to Hostinger hPanel
2. Go to your Node.js application
3. Click on "Environment Variables"
4. Add each variable:

```env
NODE_ENV=production
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
STRIPE_SECRET_KEY=sk_live_your_secret_key_here
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_your_publishable_key_here
NEXT_PUBLIC_SITE_URL=https://yourdomain.com
AGE_VERIFICATION_PROVIDER=dob-photo
```

#### Option B: Via .env.production File

SSH into your Hostinger account and create the file:

```bash
cd ~/public_html
nano .env.production
```

Add the same environment variables as above, then save (Ctrl+X, Y, Enter).

**⚠️ Security Warning**: Option A is more secure as the .env.production file could be accidentally committed or exposed.

### Step 2: Get Your Credentials

#### Supabase Credentials

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to Settings → API
4. Copy:
   - **Project URL** → use for `NEXT_PUBLIC_SUPABASE_URL`
   - **Project API keys → anon/public** → use for `NEXT_PUBLIC_SUPABASE_ANON_KEY`

#### Stripe Credentials

1. Go to [https://dashboard.stripe.com](https://dashboard.stripe.com)
2. Go to Developers → API keys
3. For **live mode** (production):
   - Copy **Secret key** (sk_live_...) → use for `STRIPE_SECRET_KEY`
   - Copy **Publishable key** (pk_live_...) → use for `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`
4. For **test mode** (staging):
   - Toggle to "Test mode"
   - Copy **Secret key** (sk_test_...) → use for `STRIPE_SECRET_KEY`
   - Copy **Publishable key** (pk_test_...) → use for `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`

### Step 3: Rebuild the Application

After setting environment variables:

```bash
cd ~/public_html

# Install dependencies if not already done
pnpm install

# Build the application
pnpm build

# Start or restart the application
pm2 restart smokeshop
# or
npm start
```

## Validating Environment Variables

You can validate your environment setup using the new validation utility:

```typescript
// In any server component or API route
import { validateEnv, logEnvValidation } from '@/lib/env';

// Log validation results
logEnvValidation();

// Or check programmatically
const result = validateEnv();
if (!result.isValid) {
  console.error('Missing variables:', result.missing);
}
```

## Common Build Errors & Solutions

### Error: "STRIPE_SECRET_KEY is not defined"

**Solution**: 
1. Ensure `STRIPE_SECRET_KEY` is set in Hostinger environment variables
2. Verify the variable name is exactly correct (case-sensitive)
3. Restart your Node.js application after adding variables

### Error: "Missing Supabase environment variables"

**Solution**:
1. Check both `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are set
2. Verify the URL format: `https://your-project.supabase.co`
3. Ensure the anon key is the complete JWT token

### Error: Build succeeds but app crashes at runtime

**Solution**:
1. Check environment variables are available at runtime
2. In Hostinger panel, verify variables are set in the Node.js application settings
3. Restart the application: `pm2 restart smokeshop`

### Error: "Cannot find module" or module import errors

**Solution**:
```bash
# Clean install
rm -rf node_modules .next
pnpm install
pnpm build
```

## Testing Build Locally

Before deploying to Hostinger, test the build locally:

```bash
# Create .env.local with your variables
cp .env.example .env.local
# Edit .env.local with actual values

# Build locally
pnpm build

# Test production build
pnpm start

# Visit http://localhost:3000 to test
```

## Production Deployment Checklist

- [ ] All environment variables set in Hostinger panel
- [ ] Using Stripe **live mode** keys (sk_live_... and pk_live_...)
- [ ] Supabase project is not paused
- [ ] Domain SSL certificate is installed
- [ ] Site URL matches your actual domain
- [ ] Build completes successfully: `pnpm build`
- [ ] Application starts without errors: `pm2 logs smokeshop`
- [ ] Can access the site via HTTPS
- [ ] Stripe checkout works (test with real card)
- [ ] User authentication works
- [ ] Database queries succeed

## Development vs Production Environments

### Development (.env.local)
```env
NODE_ENV=development
NEXT_PUBLIC_SITE_URL=http://localhost:3000
STRIPE_SECRET_KEY=sk_test_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
```

### Production (Hostinger)
```env
NODE_ENV=production
NEXT_PUBLIC_SITE_URL=https://yourdomain.com
STRIPE_SECRET_KEY=sk_live_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...
```

## Additional Resources

- [Next.js Environment Variables](https://nextjs.org/docs/basic-features/environment-variables)
- [Stripe API Keys](https://stripe.com/docs/keys)
- [Supabase API Settings](https://supabase.com/docs/guides/api)
- [Hostinger Node.js Tutorial](https://www.hostinger.com/tutorials/how-to-deploy-nodejs)

## Need Help?

If you continue to experience build issues:

1. Check build logs: `pm2 logs smokeshop` or in Hostinger panel
2. Verify all environment variables are set: `printenv | grep NEXT_PUBLIC`
3. Ensure you're on the correct branch: `git branch`
4. Try a clean rebuild: `rm -rf .next && pnpm build`

---

**Last Updated**: After fixing Stripe initialization and adding environment validation

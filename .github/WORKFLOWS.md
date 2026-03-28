# GitHub Actions Setup Guide

This guide explains the automated workflows configured for the Smokeshop repository.

## 🤖 Automated Workflows

### 1. Build Test (`build-test.yml`)

**Triggers:**

- Pull requests to `build` branch
- Direct pushes to `build` branch

**What it does:**

- Tests the build on Node.js 18.x and 20.x
- Installs dependencies with pnpm
- Runs linter
- Checks TypeScript types
- Builds the Next.js application

### 2. PR Checks (`pr-checks.yml`)

**Triggers:**

- Pull requests to `build` or `main` branches
- When PRs are opened, synchronized, or reopened

**What it does:**

- Runs comprehensive checks on PR code
- Generates a summary table showing pass/fail status
- Blocks merge if build fails
- Tests linting, TypeScript, and build process

## 🔐 Required GitHub Secrets

To enable the build workflow, you need to add these secrets to your GitHub repository:

### Setting Up Secrets

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each of the following secrets:

| Secret Name                          | Description                   | Example Value                     |
| ------------------------------------ | ----------------------------- | --------------------------------- |
| `NEXT_PUBLIC_SUPABASE_URL`           | Your Supabase project URL     | `https://xxxxx.supabase.co`       |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY`      | Supabase anonymous/public key | `eyJhbGciOiJIUzI1NiIsInR5cCI6...` |
| `STRIPE_SECRET_KEY`                  | Stripe secret key             | `sk_test_xxx` or `sk_live_xxx`    |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | Stripe publishable key        | `pk_test_xxx` or `pk_live_xxx`    |
| `NEXT_PUBLIC_SITE_URL`               | Your site URL                 | `https://yourdomain.com`          |

### Quick Setup Commands

For test/development secrets:

```bash
# Use test mode Stripe keys
STRIPE_SECRET_KEY=sk_test_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...

# Set a placeholder site URL
NEXT_PUBLIC_SITE_URL=https://smokeshop.example.com
```

## 🔒 Branch Protection Rules (Recommended)

Set up branch protection for the `build` and `main` branches:

### For the `build` branch:

1. Go to **Settings** → **Branches** → **Add rule**
2. Branch name pattern: `build`
3. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (at least 1)
   - ✅ Require status checks to pass before merging
     - Search and select: `pr-checks` and `build`
   - ✅ Require branches to be up to date before merging
   - ✅ Do not allow bypassing the above settings

### For the `main` branch:

1. Go to **Settings** → **Branches** → **Add rule**
2. Branch name pattern: `main`
3. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (at least 1)
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Include administrators
   - ✅ Do not allow bypassing the above settings

## 📝 Workflow Best Practices

### Development Flow:

```bash
# 1. Make sure you're on the working branch
git checkout working

# 2. Create a feature branch (optional but recommended)
git checkout -b feature/my-new-feature

# 3. Make your changes and commit
git add .
git commit -m "Add new feature"

# 4. Push to remote
git push origin feature/my-new-feature
# or if on working branch directly:
git push origin working

# 5. Create PR on GitHub from working → build
# The PR checks will run automatically

# 6. After PR is approved and merged to build, create PR from build → main
```

### Creating a Pull Request:

1. Push your changes to the `working` branch or a feature branch
2. Go to GitHub repository
3. Click **Pull requests** → **New pull request**
4. Set base branch to `build` and compare branch to `working` (or your feature branch)
5. Fill in the PR template
6. Click **Create pull request**
7. Wait for automated checks to complete
8. Request review if needed
9. Merge once approved and checks pass

## 🔍 Monitoring Workflow Runs

### View Workflow Status:

1. Go to the **Actions** tab in your GitHub repository
2. Click on any workflow run to see details
3. View logs for each job and step

### Check PR Status:

- PR checks appear as status checks at the bottom of the PR
- Green checkmark = passed
- Red X = failed (click for details)
- Orange circle = in progress

## 🐛 Troubleshooting

### Build Fails Due to Missing Secrets

**Error:** `Environment variable NEXT_PUBLIC_SUPABASE_URL is not defined`

**Solution:** Add the required secrets to GitHub repository settings (see above)

### pnpm Lock File Issues

**Error:** `pnpm install failed`

**Solution:**

```bash
# Locally update lock file
pnpm install
git add pnpm-lock.yaml
git commit -m "Update pnpm lock file"
git push
```

### TypeScript Errors

**Error:** TypeScript check fails

**Solution:**

```bash
# Run TypeScript check locally
npx tsc --noEmit

# Fix errors and commit
git add .
git commit -m "Fix TypeScript errors"
git push
```

### Linting Errors

**Error:** ESLint fails

**Solution:**

```bash
# Run linter locally
pnpm lint

# Auto-fix what's possible
npx next lint --fix

# Manually fix remaining issues
git add .
git commit -m "Fix linting errors"
git push
```

## ⚡ Optimizations

### Cache Management

The workflows use GitHub Actions cache to speed up builds:

- pnpm store is cached between runs
- Cache key is based on `pnpm-lock.yaml`
- Automatic cache invalidation when dependencies change

### Matrix Testing

The build-test workflow tests on multiple Node.js versions:

- 18.x (LTS)
- 20.x (Current LTS)

This ensures compatibility across different environments.

## 📊 Workflow Status Badges

Add these to your README.md to show build status:

```markdown
[![Build Test](https://github.com/JustinCBates/Smokeshop/actions/workflows/build-test.yml/badge.svg)](https://github.com/JustinCBates/Smokeshop/actions/workflows/build-test.yml)

[![PR Checks](https://github.com/JustinCBates/Smokeshop/actions/workflows/pr-checks.yml/badge.svg)](https://github.com/JustinCBates/Smokeshop/actions/workflows/pr-checks.yml)
```

## 🔄 Updating Workflows

To modify workflows:

1. Edit files in `.github/workflows/`
2. Commit and push changes
3. Workflows update automatically on next trigger

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [pnpm GitHub Action](https://github.com/pnpm/action-setup)
- [Next.js CI/CD Best Practices](https://nextjs.org/docs/pages/building-your-application/deploying/ci-build-caching)

---

**Note:** The workflows are configured with `continue-on-error: true` for linting and TypeScript checks during initial setup. Once your code is clean, consider making these checks mandatory by removing this option.

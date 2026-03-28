# GitHub Actions Workflows

This directory contains CI/CD workflows for the backend repo.

## Environment Model

- Localdev: Docker Desktop using `docker-compose.yml` / `docker-compose.postgres.yml` on your local machine
- Staging: deployed to Hostinger `staging_public_html` after successful CI on `build`
- Production: deployed to Hostinger `public_html` on `main`

## Branch Flow

`development` -> `build` -> `main`

## Workflows

### 1) CI - Build & Test (`ci.yml`)

Triggers:
- Push to `development` and `build`
- Pull requests to `build` and `main`

Purpose:
- Lint and build gate for integration branches

### 2) Build Test (`build-test.yml`)

Triggers:
- Push to `development` and `build`
- Pull requests to `build`

Purpose:
- Additional build validation matrix

### 3) PR Checks (`pr-checks.yml`)

Triggers:
- Pull requests to `build` and `main`

Purpose:
- PR-focused checks and summary table

### 4) Deploy to Staging (`deploy-staging.yml`)

Triggers:
- `workflow_run` when `CI - Build & Test` completes on `build`
- Manual `workflow_dispatch`

Guard:
- Deploy job runs only when CI conclusion is `success` (or manual dispatch)

Purpose:
- Promote validated `build` commits to staging

### 5) Deploy to Production (`deploy-production.yml`)

Triggers:
- Push to `main`
- Manual `workflow_dispatch`

Purpose:
- Deploy production from `main`

## Required GitHub Secrets

Application and integration:
- `SMOKESHOP_DATABASE_URL`
- `CLOVER_ACCESS_TOKEN`
- `CLOVER_MERCHANT_ID`
- `CLOVER_WEBHOOK_SECRET`

Hostinger deploy:
- `HOSTINGER_SSH_HOST`
- `HOSTINGER_SSH_PORT`
- `HOSTINGER_SSH_USER`
- `HOSTINGER_SSH_KEY`
- `HOSTINGER_DEPLOY_PATH`
- `STAGING_DEPLOY_PATH`

## Hostinger Paths

- Production: `/home/u733577836/domains/neutraldevelopment.com/public_html`
- Staging: `/home/u733577836/domains/neutraldevelopment.com/staging_public_html`

## Notes

- If staging deploy succeeds but `https://staging.neutraldevelopment.com` returns 404, fix the subdomain document root in hPanel to `staging_public_html`.
- Localdev remains separate from CI/CD and is run via Docker Desktop.

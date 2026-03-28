# Smokeshop Backend

Backend application and database bootstrap for the Smokeshop platform.

## Current Database Baseline

The self-hosted PostgreSQL container is intentionally bootstrapped with only:

- `postgis`, `pgcrypto`, and `citext` extensions
- `auth.users`
- `auth.identities`
- `auth.sessions`
- `public.profiles`

No product, order, inventory, or delivery tables are created by default.

## Tech Stack

- **Framework**: Next.js 15 (React 19)
- **Database**: Self-hosted PostgreSQL + PostGIS
- **Auth code**: Transitional Supabase-based application layer
- **Language**: TypeScript

## Quick Start

### Prerequisites

- Node.js 18+ and pnpm
- Supabase account
- Stripe account

### Local Development

1. **Clone the repository**

   ```bash
   git clone https://github.com/JustinCBates/Smokeshop.git
   cd Smokeshop
   ```

2. **Install dependencies**

   ```bash
   pnpm install
   ```

3. **Set up environment variables**

   ```bash
   cp .env.example .env.local
   ```

   Edit `.env.local` with your credentials.

4. **Set up local/VPS PostgreSQL baseline**
   - Prepare `.env.postgres.local` with `POSTGRES_PASSWORD`
   - Run `pnpm db:recreate`
   - Or start the container manually with `docker compose -f docker-compose.postgres.yml --env-file .env.postgres.local up -d`

5. **Run the development server**

   ```bash
   pnpm dev
   ```

6. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## Database Setup

The only automatic bootstrap file is [db/init/001_identity_baseline.sql](db/init/001_identity_baseline.sql).

It creates:

- PostGIS support
- `auth.users`
- `auth.identities`
- `auth.sessions`
- `public.profiles`
- helper functions/triggers for profile synchronization and `updated_at`

To rebuild from scratch, run:

```bash
pnpm db:recreate
```

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for deployment details.

### Quick Deployment Steps

1. Recreate the PostgreSQL container if needed
2. Set application environment variables
3. Upload code to Hostinger
4. Build and start the application

## Project Structure

```
├── app/                    # Next.js app directory
│   ├── api/              # API routes
│   └── ...
├── db/init/              # Docker bootstrap SQL
├── lib/                  # Utility libraries
│   ├── supabase/         # Transitional auth/session code
│   └── ...
├── scripts/              # Database utilities and legacy migrations
├── server.js             # Custom server for Hostinger
├── ecosystem.config.js   # PM2 configuration
└── DEPLOYMENT.md         # Deployment guide
```

## Environment Variables

Relevant environment variables:

- `DATABASE_URL` - PostgreSQL connection string for app/runtime access
- `POSTGRES_PASSWORD` - Used by the Dockerized PostgreSQL container
- `NEXT_PUBLIC_SITE_URL` - Site URL
- `AGE_VERIFICATION_PROVIDER` - Age verification method

## Scripts

- `pnpm dev` - Start development server with Turbopack
- `pnpm build` - Build for production
- `pnpm start` - Start production server
- `pnpm lint` - Run ESLint
- `pnpm migrate` - Apply the identity baseline to an existing PostgreSQL database
- `pnpm db:recreate` - Recreate the Dockerized PostgreSQL database from scratch

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is private and proprietary.

## Support

For issues and questions:

- Check [DEPLOYMENT.md](DEPLOYMENT.md) for deployment help
- Review Next.js documentation: https://nextjs.org/docs

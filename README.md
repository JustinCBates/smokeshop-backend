# Smokeshop - E-commerce Platform

A modern e-commerce platform for a smokeshop built with Next.js, Supabase (PostgreSQL + PostGIS), and Stripe payments.

## Features

- 🛍️ **Product Catalog**: Browse and search products
- 📍 **Location-Based Services**: PostGIS integration for delivery zones and pickup locations
- 🔐 **User Authentication**: Secure auth powered by Supabase
- 💳 **Payment Processing**: Stripe integration for secure payments
- 🚚 **Delivery & Pickup**: Support for both delivery and in-store pickup
- ✅ **Age Verification**: Built-in age verification system
- 📱 **Responsive Design**: Works on desktop, tablet, and mobile

## Tech Stack

- **Framework**: Next.js 15 (React 19)
- **Database**: Supabase (PostgreSQL + PostGIS)
- **Payments**: Stripe
- **Styling**: Tailwind CSS 4
- **Maps**: Leaflet
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

   Edit `.env.local` with your credentials:
   - Supabase URL and anon key
   - Stripe secret and publishable keys
   - Your local site URL

4. **Set up Supabase database**
   - Create a new Supabase project
   - Run the migration scripts in `scripts/` directory (in order)
   - Or run `scripts/000_run_all.sql` in the SQL Editor

5. **Run the development server**

   ```bash
   pnpm dev
   ```

6. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## Database Setup

The project includes SQL migration scripts in the `scripts/` directory:

1. `001_enable_postgis.sql` - Enable PostGIS extension
2. `002_create_products.sql` - Products table
3. `003_create_regions.sql` - Delivery regions (with PostGIS geometry)
4. `004_create_region_inventory.sql` - Regional inventory
5. `005_create_pickup_locations.sql` - Pickup locations
6. `006_create_pickup_inventory.sql` - Pickup inventory
7. `007_create_delivery_fee_tiers.sql` - Delivery pricing
8. `008_create_delivery_slots.sql` - Delivery time slots
9. `009_create_profiles.sql` - User profiles
10. `009b_profiles_rls.sql` - Row Level Security for profiles
11. `009c_profiles_trigger.sql` - Profile triggers
12. `010_create_orders.sql` - Orders table
13. `011_create_order_items.sql` - Order items
14. `012_create_storage_bucket.sql` - File storage
15. `013_seed_sample_data.sql` - Sample data

Run them in order in your Supabase SQL Editor, or execute `000_run_all.sql`.

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions on deploying to Hostinger with Supabase and Stripe integration.

### Quick Deployment Steps

1. Set up Supabase project and run migrations
2. Configure Stripe account
3. Upload code to Hostinger
4. Set environment variables
5. Build and start the application

## Project Structure

```
├── app/                    # Next.js app directory
│   ├── api/               # API routes
│   ├── auth/              # Authentication pages
│   ├── shop/              # Shop pages
│   └── ...
├── components/            # React components
│   ├── layout/           # Layout components
│   ├── modals/           # Modal dialogs
│   └── shop/             # Shop-specific components
├── lib/                   # Utility libraries
│   ├── supabase/         # Supabase client configuration
│   ├── age-verification/ # Age verification logic
│   └── ...
├── scripts/               # Database migration scripts
├── server.js             # Custom server for Hostinger
├── ecosystem.config.js   # PM2 configuration
└── DEPLOYMENT.md         # Deployment guide
```

## Environment Variables

Required environment variables (see `.env.example`):

- `NEXT_PUBLIC_SUPABASE_URL` - Your Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Supabase anonymous key
- `STRIPE_SECRET_KEY` - Stripe secret key
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` - Stripe publishable key
- `NEXT_PUBLIC_SITE_URL` - Your site URL
- `AGE_VERIFICATION_PROVIDER` - Age verification method (dob-photo or third-party)

## Scripts

- `pnpm dev` - Start development server with Turbopack
- `pnpm build` - Build for production
- `pnpm start` - Start production server
- `pnpm lint` - Run ESLint

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
- Review Supabase documentation: https://supabase.com/docs
- Review Stripe documentation: https://stripe.com/docs
- Review Next.js documentation: https://nextjs.org/docs

---

Built with ❤️ using Next.js, Supabase, and Stripe

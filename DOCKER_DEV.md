# Docker Development Environment Setup

This guide shows you how to develop the Smokeshop application in a Debian Docker container.

## Prerequisites

- Docker Desktop installed on Windows
- Git (to clone the repository)

## Quick Start

### 1. Build and Start the Container

```powershell
# Build the Docker image
docker-compose build

# Start the container
docker-compose up -d

# Enter the container
docker-compose exec dev bash
```

### 2. Inside the Container - First Time Setup

Once inside the container, run these commands:

```bash
# You're now in a Debian Linux environment!

# Install dependencies
pnpm install

# Copy environment template
cp .env.example .env.local

# Edit environment variables (use nano or vi)
nano .env.local
# Add your actual Supabase and Stripe credentials
# Press Ctrl+X, then Y, then Enter to save

# Run the development server
pnpm dev
```

### 3. Access the Application

Open your browser on Windows and go to:

- http://localhost:3000

The application will run inside the container but be accessible from your Windows browser!

## Alternative: Fresh Git Clone Inside Container

If you want to start completely fresh:

```powershell
# Start a fresh container
docker-compose run --rm dev bash
```

Inside the container:

```bash
# Remove existing files (be careful!)
cd /app
rm -rf *
rm -rf .*

# Clone from GitHub
git clone https://github.com/JustinCBates/Smokeshop.git .

# Checkout working branch
git checkout working

# Install dependencies
pnpm install

# Setup environment
cp .env.example .env.local
nano .env.local

# Run development server
pnpm dev
```

## Available Commands

### Docker Commands (Run from PowerShell in Windows)

```powershell
# Build the image
docker-compose build

# Start container in background
docker-compose up -d

# Enter the running container
docker-compose exec dev bash

# Stop the container
docker-compose down

# View logs
docker-compose logs -f dev

# Restart container
docker-compose restart

# Remove container and volumes (clean start)
docker-compose down -v
```

### Development Commands (Run inside the container)

```bash
# Install dependencies
pnpm install

# Start development server
pnpm dev

# Build for production
pnpm build

# Run linter
pnpm lint

# Fix linting issues
pnpm lint:fix

# Check TypeScript
pnpm type-check

# Run all checks
pnpm check-all
```

## Project Structure Inside Container

```
/app/                          # Your project root
├── node_modules/              # Installed in named volume (fast!)
├── .next/                     # Next.js build output
├── app/                       # Next.js app directory
├── components/                # React components
├── lib/                       # Utilities
├── scripts/                   # Database scripts
└── ...
```

## Environment Variables

Create `.env.local` inside the container:

```bash
# Required
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
STRIPE_SECRET_KEY=sk_test_your_key
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_your_key

# Optional
NEXT_PUBLIC_SITE_URL=http://localhost:3000
AGE_VERIFICATION_PROVIDER=dob-photo
```

## Git Workflow Inside Container

```bash
# Check current branch
git branch

# Checkout working branch
git checkout working

# Pull latest changes
git pull origin working

# Make changes, then stage
git add .

# Commit
git commit -m "Your message"

# Push (will ask for credentials)
git push origin working

# Configure git user (first time)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Advantages of Docker Development

✅ **Consistent Environment**: Same setup on any machine
✅ **No Windows Node.js Issues**: Everything runs in Linux
✅ **Easy Cleanup**: Just delete the container
✅ **Fast**: Node modules on Docker volume = better performance
✅ **Isolated**: Won't affect your Windows system

## Troubleshooting

### Container won't start

```powershell
# Check Docker is running
docker ps

# View build logs
docker-compose build --no-cache

# Check logs
docker-compose logs dev
```

### Can't access localhost:3000

```bash
# Inside container, make sure dev server is running on 0.0.0.0
pnpm dev
# Next.js should show: ready started server on 0.0.0.0:3000
```

If still not working, edit `package.json` and change the dev script:

```json
"dev": "next dev -H 0.0.0.0"
```

### Permission errors

```bash
# The container runs as 'developer' user, not root
# If you need root access:
exit  # Exit container
docker-compose exec -u root dev bash  # Re-enter as root
```

### Need to reinstall dependencies

```bash
# Remove node_modules
rm -rf node_modules

# Clear pnpm cache
pnpm store prune

# Reinstall
pnpm install
```

### Want to start completely fresh

```powershell
# From Windows PowerShell
docker-compose down -v  # Removes container and volumes
docker-compose build --no-cache  # Rebuild image
docker-compose up -d  # Start fresh
```

## VS Code Integration (Optional)

You can use VS Code to develop inside the container:

1. Install "Dev Containers" extension in VS Code
2. Press F1, type "Dev Containers: Attach to Running Container"
3. Select `smokeshop-dev`
4. VS Code will run inside the container!

Or use the Remote Explorer in VS Code sidebar.

## Tips

### Keep PowerShell Open

Keep one PowerShell window to manage Docker:

```powershell
# Terminal 1: Docker management
docker-compose logs -f dev
```

### Multiple Container Sessions

You can open multiple bash sessions in the same container:

```powershell
# Terminal 2: Enter container
docker-compose exec dev bash

# Terminal 3: Another session in same container
docker-compose exec dev bash
```

### Quick Development Loop

```bash
# Inside container
pnpm dev  # Start dev server
# Leave it running, open new terminal for other commands

# In another terminal/session
docker-compose exec dev bash
pnpm lint  # Run linter while dev server runs
```

## Next Steps

1. ✅ Build container: `docker-compose build`
2. ✅ Start container: `docker-compose up -d`
3. ✅ Enter container: `docker-compose exec dev bash`
4. ✅ Install dependencies: `pnpm install`
5. ✅ Setup env file: `cp .env.example .env.local && nano .env.local`
6. ✅ Start dev server: `pnpm dev`
7. ✅ Open browser: http://localhost:3000

Happy coding in Debian! 🐳🚀

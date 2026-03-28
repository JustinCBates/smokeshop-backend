# Development Environment Setup Guide

## Installing Node.js on Windows

You need Node.js to run npm commands and develop/build the application.

### Method 1: Using Official Installer (Recommended)

1. **Download Node.js**
   - Go to [https://nodejs.org/](https://nodejs.org/)
   - Download the **LTS version** (Long Term Support) - currently 20.x or 22.x
   - Choose the Windows Installer (.msi) for your system (64-bit recommended)

2. **Run the Installer**
   - Double-click the downloaded `.msi` file
   - Click **Next** through the setup wizard
   - Accept the license agreement
   - **Important**: Keep the default installation path (`C:\Program Files\nodejs\`)
   - **Important**: Make sure "Add to PATH" is checked ✅
   - Complete the installation

3. **Verify Installation**
   - Open a **new** PowerShell window (important - restart terminal)
   - Run these commands:
   ```powershell
   node --version
   npm --version
   ```

   - You should see version numbers (e.g., v20.x.x and 10.x.x)

### Method 2: Using Winget (Windows Package Manager)

If you have Windows 11 or Windows 10 (recent builds):

```powershell
# Install Node.js LTS
winget install OpenJS.NodeJS.LTS

# Restart your terminal after installation
```

### Method 3: Using Chocolatey

If you have Chocolatey installed:

```powershell
# Run PowerShell as Administrator
choco install nodejs-lts

# Restart your terminal after installation
```

### Method 4: Using nvm-windows (For Multiple Node Versions)

If you need to manage multiple Node.js versions:

1. Download nvm-windows from: [https://github.com/coreybutler/nvm-windows/releases](https://github.com/coreybutler/nvm-windows/releases)
2. Download `nvm-setup.exe`
3. Run the installer
4. Open a new PowerShell window and run:

```powershell
# List available Node.js versions
nvm list available

# Install LTS version
nvm install lts

# Use the installed version
nvm use lts

# Verify
node --version
npm --version
```

## After Installing Node.js

### 1. Verify Installation

Close and reopen PowerShell, then run:

```powershell
node --version
npm --version
```

Expected output:

```
v20.11.0 (or similar)
10.2.4 (or similar)
```

### 2. Install pnpm (Optional but Recommended)

This project uses pnpm for faster and more efficient package management:

```powershell
# Install pnpm globally
npm install -g pnpm

# Verify
pnpm --version
```

### 3. Navigate to Project and Install Dependencies

```powershell
# Go to project directory
cd C:\Development\smokeshop\Smokeshop

# Install dependencies (choose one)
npm install
# or if you installed pnpm:
pnpm install
```

### 4. Run the Linter

```powershell
# Check for linting issues
npm run lint

# Auto-fix issues
npm run lint:fix

# Check TypeScript types
npm run type-check

# Run all checks
npm run check-all
```

## Common Installation Issues

### Issue: "node is not recognized" after installation

**Solution:**

1. Restart your terminal/PowerShell completely
2. If still not working, restart your computer
3. Check if Node.js is in your PATH:
   ```powershell
   $env:PATH -split ';' | Select-String nodejs
   ```
4. If not in PATH, add it manually:

   ```powershell
   # Add to current session
   $env:PATH += ";C:\Program Files\nodejs\"

   # Add permanently (run PowerShell as Administrator)
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\nodejs\", "Machine")
   ```

### Issue: npm install fails with permission errors

**Solution:**

```powershell
# Configure npm to use a different directory for global packages
npm config set prefix "$env:APPDATA\npm"

# Add to PATH
$env:PATH += ";$env:APPDATA\npm"
```

### Issue: EACCES or permission denied errors

**Solution:**

```powershell
# Run PowerShell as Administrator
# Or fix npm permissions:
npm config set cache $env:LOCALAPPDATA\npm-cache --global
```

### Issue: Slow npm installs

**Solution:**

```powershell
# Use pnpm instead (much faster)
npm install -g pnpm
pnpm install

# Or configure npm to use a faster registry
npm config set registry https://registry.npmjs.org/
```

## Development Tools (Optional but Recommended)

### VS Code Extensions

If using VS Code, install these extensions:

1. **ESLint** - Automatic linting
   - Extension ID: `dbaeumer.vscode-eslint`

2. **TypeScript + JavaScript** - Better TypeScript support
   - Built-in with VS Code

3. **Prettier** - Code formatting
   - Extension ID: `esbenp.prettier-vscode`

4. **Tailwind CSS IntelliSense** - Tailwind autocomplete
   - Extension ID: `bradlc.vscode-tailwindcss`

### Configure VS Code Settings

Create `.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true
}
```

## Quick Start After Installation

```powershell
# 1. Navigate to project
cd C:\Development\smokeshop\Smokeshop

# 2. Install dependencies
npm install
# or
pnpm install

# 3. Create environment file
cp .env.example .env.local
# Edit .env.local with your actual credentials

# 4. Run development server
npm run dev

# 5. Open browser
# Navigate to http://localhost:3000
```

## Available npm Scripts

After installation, you can use these commands:

```powershell
npm run dev          # Start development server with hot reload
npm run build        # Build for production
npm start            # Start production server
npm run lint         # Check for linting issues
npm run lint:fix     # Auto-fix linting issues
npm run type-check   # Check TypeScript types
npm run check-all    # Run lint and type-check together
```

## Verifying Your Setup

Run this checklist:

```powershell
# Check Node.js
node --version        # Should show v18.x, v20.x, or v22.x

# Check npm
npm --version         # Should show 9.x or 10.x

# Check pnpm (optional)
pnpm --version        # Should show 8.x or 9.x

# Check Git
git --version         # Should show version

# Check if in correct directory
pwd                   # Should show C:\Development\smokeshop\Smokeshop
```

## Next Steps

Once Node.js is installed:

1. ✅ Install project dependencies: `npm install`
2. ✅ Run linter: `npm run lint`
3. ✅ Check TypeScript: `npm run type-check`
4. ✅ Start development server: `npm run dev`
5. ✅ Read [LINTING.md](LINTING.md) for code quality guidelines

## Troubleshooting Resources

- **Node.js Issues**: [https://nodejs.org/en/docs/](https://nodejs.org/en/docs/)
- **npm Issues**: [https://docs.npmjs.com/](https://docs.npmjs.com/)
- **Path Issues**: [Windows Environment Variables Guide](https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/)

## Getting Help

If you encounter issues:

1. Check the error message carefully
2. Make sure you restarted PowerShell after installation
3. Verify Node.js is in your PATH: `$env:PATH`
4. Try running PowerShell as Administrator
5. Check antivirus isn't blocking npm

---

**Last Updated**: After adding ESLint configuration
**Minimum Node.js Version**: 18.x
**Recommended Node.js Version**: 20.x LTS

# Quick Node.js Installation Script for Windows
# This script helps download and install Node.js LTS

Write-Host "=== Node.js Installation Helper ===" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is already installed
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
if ($nodeInstalled) {
    Write-Host "✅ Node.js is already installed!" -ForegroundColor Green
    Write-Host "Version: " -NoNewline
    node --version
    Write-Host "npm Version: " -NoNewline
    npm --version
    exit 0
}

Write-Host "❌ Node.js is not installed." -ForegroundColor Red
Write-Host ""
Write-Host "Please follow these steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "OPTION 1: Download Manually (Easiest)" -ForegroundColor Green
Write-Host "1. A browser window should have opened to https://nodejs.org"
Write-Host "2. Click the green 'Download Node.js (LTS)' button"
Write-Host "3. Run the downloaded .msi installer"
Write-Host "4. Click 'Next' through all steps (keep default settings)"
Write-Host "5. Make sure 'Add to PATH' is checked ✅"
Write-Host "6. Click 'Install' and wait for completion"
Write-Host "7. Close this PowerShell window and open a NEW one"
Write-Host "8. Run: node --version"
Write-Host ""

Write-Host "OPTION 2: Use Windows Package Manager (If available)" -ForegroundColor Green
Write-Host "Run this command in PowerShell:"
Write-Host "  winget install OpenJS.NodeJS.LTS" -ForegroundColor Cyan
Write-Host ""

Write-Host "After installation:" -ForegroundColor Yellow
Write-Host "1. Close this PowerShell completely"
Write-Host "2. Open a NEW PowerShell window"
Write-Host "3. Navigate to: C:\Development\smokeshop\Smokeshop"
Write-Host "4. Run: node --version"
Write-Host "5. Run: npm install"
Write-Host ""

# Try to open the download page
Write-Host "Opening Node.js download page in your browser..." -ForegroundColor Cyan
Start-Process "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

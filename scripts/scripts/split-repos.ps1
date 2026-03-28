param(
  [string]$SourceRepoPath,
  [string]$FrontendRepoPath,
  [string]$BackendRepoPath,
  [switch]$InitGit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SourceRepoPath) {
  $SourceRepoPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

$sourceParent = Split-Path -Parent $SourceRepoPath

if (-not $FrontendRepoPath) {
  $FrontendRepoPath = Join-Path $sourceParent 'smokeshop-frontend'
}

if (-not $BackendRepoPath) {
  $BackendRepoPath = Join-Path $sourceParent 'smokeshop-backend'
}

function Ensure-CleanDir {
  param([string]$Path)
  if (Test-Path $Path) {
    Remove-Item -Recurse -Force $Path
  }
  New-Item -ItemType Directory -Path $Path | Out-Null
}

function Copy-Repo {
  param([string]$From, [string]$To)

  $excludeDirs = @('.git', 'node_modules', '.next', 'logs')
  $excludeFiles = @('*.log')

  $dirEx = ($excludeDirs | ForEach-Object { '/XD', $_ })
  $fileEx = ($excludeFiles | ForEach-Object { '/XF', $_ })

  $null = & robocopy $From $To /E /NFL /NDL /NJH /NJS /NC /NS $dirEx $fileEx
  if ($LASTEXITCODE -gt 7) {
    throw "Robocopy failed with exit code $LASTEXITCODE"
  }
}

function Remove-IfExists {
  param([string]$Path)
  if (Test-Path $Path) {
    Remove-Item -Recurse -Force $Path
  }
}

function Copy-IfExists {
  param([string]$From, [string]$To)
  if (Test-Path $From) {
    $toParent = Split-Path -Parent $To
    if (-not (Test-Path $toParent)) {
      New-Item -ItemType Directory -Path $toParent | Out-Null
    }
    Copy-Item -Recurse -Force $From $To
  }
}

Write-Host "Preparing split directories..."
Ensure-CleanDir -Path $FrontendRepoPath
Ensure-CleanDir -Path $BackendRepoPath

Write-Host "Copying source into frontend and backend outputs..."
Copy-Repo -From $SourceRepoPath -To $FrontendRepoPath
Copy-Repo -From $SourceRepoPath -To $BackendRepoPath

Write-Host "Pruning frontend repo (remove backend-only surfaces)..."
Remove-IfExists (Join-Path $FrontendRepoPath 'app\api')
Remove-IfExists (Join-Path $FrontendRepoPath 'lib\database')
Remove-IfExists (Join-Path $FrontendRepoPath 'lib\auth')
Remove-IfExists (Join-Path $FrontendRepoPath 'lib\coinbase-commerce.ts')
Remove-IfExists (Join-Path $FrontendRepoPath 'docker-compose.postgres.yml')
Remove-IfExists (Join-Path $FrontendRepoPath '.env.postgres')
Remove-IfExists (Join-Path $FrontendRepoPath 'seed_products.sql')
Remove-IfExists (Join-Path $FrontendRepoPath 'scripts')

Write-Host "Pruning backend repo (API-only app surface)..."
Remove-IfExists (Join-Path $BackendRepoPath 'app')
Remove-IfExists (Join-Path $BackendRepoPath 'components')
Remove-IfExists (Join-Path $BackendRepoPath 'public')
Remove-IfExists (Join-Path $BackendRepoPath 'frontend')
Remove-IfExists (Join-Path $BackendRepoPath 'lib')
Remove-IfExists (Join-Path $BackendRepoPath 'middleware.ts')
Remove-IfExists (Join-Path $BackendRepoPath 'tailwind.config.ts')
Remove-IfExists (Join-Path $BackendRepoPath 'postcss.config.mjs')
Remove-IfExists (Join-Path $BackendRepoPath 'app\globals.css')

Copy-IfExists -From (Join-Path $SourceRepoPath 'app\api') -To (Join-Path $BackendRepoPath 'app\api')
Copy-IfExists -From (Join-Path $SourceRepoPath 'lib\database') -To (Join-Path $BackendRepoPath 'lib\database')
Copy-IfExists -From (Join-Path $SourceRepoPath 'lib\auth') -To (Join-Path $BackendRepoPath 'lib\auth')
Copy-IfExists -From (Join-Path $SourceRepoPath 'lib\coinbase-commerce.ts') -To (Join-Path $BackendRepoPath 'lib\coinbase-commerce.ts')
Copy-IfExists -From (Join-Path $SourceRepoPath 'lib\supabase') -To (Join-Path $BackendRepoPath 'lib\supabase')
Copy-IfExists -From (Join-Path $SourceRepoPath 'lib\env.ts') -To (Join-Path $BackendRepoPath 'lib\env.ts')
Copy-IfExists -From (Join-Path $SourceRepoPath 'scripts') -To (Join-Path $BackendRepoPath 'scripts')
Copy-IfExists -From (Join-Path $SourceRepoPath 'seed_products.sql') -To (Join-Path $BackendRepoPath 'seed_products.sql')
Copy-IfExists -From (Join-Path $SourceRepoPath 'docker-compose.postgres.yml') -To (Join-Path $BackendRepoPath 'docker-compose.postgres.yml')
Copy-IfExists -From (Join-Path $SourceRepoPath '.env.postgres') -To (Join-Path $BackendRepoPath '.env.postgres')
Copy-IfExists -From (Join-Path $SourceRepoPath 'VPS_POSTGRES_SETUP.md') -To (Join-Path $BackendRepoPath 'VPS_POSTGRES_SETUP.md')

$requiredBackendFiles = @(
  'docker-compose.postgres.yml',
  '.env.postgres',
  'seed_products.sql',
  'VPS_POSTGRES_SETUP.md',
  'scripts\\000a_postgis_setup.sql',
  'scripts\\000b_schema_and_data.sql',
  'scripts\\000_full_migration.sql',
  'scripts\\run-migrations.js'
)

$missing = @()
foreach ($relPath in $requiredBackendFiles) {
  $fullPath = Join-Path $BackendRepoPath $relPath
  if (-not (Test-Path $fullPath)) {
    $missing += $relPath
  }
}

if ($missing.Count -gt 0) {
  throw "Backend split missing required PostgreSQL files: $($missing -join ', ')"
}

if ($InitGit) {
  Write-Host "Initializing git repos..."
  Push-Location $FrontendRepoPath
  git init | Out-Null
  git add .
  git commit -m "Initial frontend split" | Out-Null
  Pop-Location

  Push-Location $BackendRepoPath
  git init | Out-Null
  git add .
  git commit -m "Initial backend split" | Out-Null
  Pop-Location
}

Write-Host "Done."
Write-Host "Frontend output: $FrontendRepoPath"
Write-Host "Backend output:  $BackendRepoPath"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1) Review both folders and adjust dependencies/env vars."
Write-Host "2) Create GitHub repos and push each folder."
Write-Host "3) Set FRONTEND env NEXT_PUBLIC_API_URL to backend domain."
Write-Host "4) Keep current repo as source until both repos pass staging." 

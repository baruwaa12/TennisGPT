# Build Flutter web app and copy output to landing/public/app/ for Vercel deployment
# Run from the repo root: .\scripts\build-pwa.ps1

param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$LandingPublicApp = Join-Path $RepoRoot "landing" "public" "app"
$FlutterBuildOutput = Join-Path $RepoRoot "build" "web"

Write-Host "`n=== Composure PWA Build ===" -ForegroundColor Cyan

if (-not $SkipBuild) {
    Write-Host "`n[1/3] Building Flutter web with base-href /app/ ..." -ForegroundColor Yellow
    Push-Location $RepoRoot
    try {
        flutter build web --base-href "/app/" --release
        if ($LASTEXITCODE -ne 0) { throw "Flutter build failed" }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "`n[1/3] Skipping Flutter build (--SkipBuild)" -ForegroundColor DarkGray
}

Write-Host "`n[2/3] Copying build output to landing/public/app/ ..." -ForegroundColor Yellow
if (Test-Path $LandingPublicApp) {
    Remove-Item -Recurse -Force $LandingPublicApp
}
Copy-Item -Recurse $FlutterBuildOutput $LandingPublicApp

Write-Host "`n[3/3] Verifying output ..." -ForegroundColor Yellow
$indexPath = Join-Path $LandingPublicApp "index.html"
if (Test-Path $indexPath) {
    $fileCount = (Get-ChildItem -Recurse $LandingPublicApp -File).Count
    Write-Host "  OK — $fileCount files in landing/public/app/" -ForegroundColor Green
} else {
    Write-Host "  ERROR — index.html not found in output" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Done! ===" -ForegroundColor Cyan
Write-Host "Next steps:"
Write-Host "  1. Test locally:  cd landing && npm run dev"
Write-Host "  2. Visit:         http://localhost:3000/app/"
Write-Host "  3. Deploy:        git add landing/public/app && git commit && git push"
Write-Host ""

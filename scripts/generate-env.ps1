# Script to generate Kubernetes ConfigMap and Secret from .env file
# Usage: .\scripts\generate-env.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$EnvFile = Join-Path $ProjectDir ".env"

if (-not (Test-Path $EnvFile)) {
    Write-Error "Error: .env file not found at $EnvFile"
    exit 1
}

Write-Host "Loading environment variables from .env..." -ForegroundColor Yellow

# Parse .env file
$envVars = @{}
Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $envVars[$key] = $value
    }
}

# Generate Secret (for DATABASE_URL and sensitive data)
Write-Host "Generating Secret..." -ForegroundColor Green
$secretFile = Join-Path $ProjectDir "manifests\secret.yaml"

kubectl create secret generic citary-secret `
    --from-literal="DATABASE_URL=$($envVars['DATABASE_URL'])" `
    --from-literal="POSTGRES_PASSWORD=$($envVars['DB_PASSWORD'])" `
    --namespace=citary `
    --dry-run=client -o yaml | Out-File -FilePath $secretFile -Encoding utf8

# Generate ConfigMap (for non-sensitive configuration)
Write-Host "Generating ConfigMap..." -ForegroundColor Green
$configFile = Join-Path $ProjectDir "manifests\configmap.yaml"

kubectl create configmap citary-config `
    --from-literal="PORT=$($envVars['PORT'])" `
    --namespace=citary `
    --dry-run=client -o yaml | Out-File -FilePath $configFile -Encoding utf8

Write-Host "✓ ConfigMap and Secret generated successfully!" -ForegroundColor Green
Write-Host "Files created:"
Write-Host "  - manifests\configmap.yaml"
Write-Host "  - manifests\secret.yaml"

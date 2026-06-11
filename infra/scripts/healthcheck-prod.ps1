$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($env:API_BASE_URL)) {
  Write-Error "API_BASE_URL is required."
  exit 1
}

Invoke-WebRequest -Uri $env:API_BASE_URL -UseBasicParsing | Out-Null
Write-Output "Production API responded at $env:API_BASE_URL."

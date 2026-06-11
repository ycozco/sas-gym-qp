$ErrorActionPreference = "Stop"

$apiUrl = $env:API_HEALTH_URL
if ([string]::IsNullOrWhiteSpace($apiUrl)) {
  $apiUrl = "http://localhost:3000/api/v1"
}

Invoke-WebRequest -Uri $apiUrl -UseBasicParsing | Out-Null
Write-Output "Local API responded at $apiUrl."

param(
  [ValidateSet("local", "production")]
  [string]$Mode = "local"
)

$required = @(
  "DB_NAME",
  "DB_USER",
  "DB_PASSWORD",
  "DATABASE_URL",
  "JWT_SECRET",
  "HUELLA_SECRET_KEY"
)

if ($Mode -eq "production") {
  $required += @(
    "REDIS_PASSWORD",
    "API_BASE_URL",
    "APP_URL",
    "ADMIN_URL",
    "EXTERNAL_PROXY_NETWORK"
  )
}

$missing = @()
foreach ($name in $required) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
    $missing += $name
  }
}

if ($missing.Count -gt 0) {
  Write-Error ("Missing required environment variables: " + ($missing -join ", "))
  exit 1
}

Write-Output "Environment variables look complete for $Mode."

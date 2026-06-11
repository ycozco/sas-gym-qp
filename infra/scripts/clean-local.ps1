$composeFile = "infra/docker/compose.local.yml"

docker compose -f $composeFile down --remove-orphans
Write-Output "Local containers stopped. Volumes were preserved."

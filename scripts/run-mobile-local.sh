#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/mobile_app"

if [[ -z "${API_BASE_URL:-}" ]]; then
  LAN_IP="$(ip route get 1.1.1.1 | awk '{for (i = 1; i <= NF; i++) if ($i == "src") {print $(i + 1); exit}}')"
  if [[ -z "$LAN_IP" ]]; then
    echo "No se pudo detectar la IP LAN. Define API_BASE_URL manualmente." >&2
    exit 1
  fi
  API_BASE_URL="http://${LAN_IP}:3000/api/v1"
fi

if [[ -z "${DEVICE_ID:-}" ]]; then
  DEVICE_ID="$(flutter devices | awk -F'•' '/android/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}')"
  if [[ -z "$DEVICE_ID" ]]; then
    echo "No se detectó ningún dispositivo Android. Conecta el celular y habilita Depuración USB." >&2
    exit 1
  fi
fi

echo "Dispositivo: $DEVICE_ID"
echo "API_BASE_URL: $API_BASE_URL"

flutter run \
  -d "$DEVICE_ID" \
  --flavor dev \
  --dart-define=APP_ENV=dev \
  --dart-define=APP_MODE=backend \
  --dart-define=ENABLE_QR_SIMULATOR=true \
  --dart-define=API_BASE_URL="$API_BASE_URL"

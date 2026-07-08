#!/usr/bin/env sh
set -eu

API_BASE_URL="${API_BASE_URL:-}"
BUILD_NAME="${BUILD_NAME:-0.1.0-local}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

if [ -z "$API_BASE_URL" ]; then
  echo "API_BASE_URL es obligatorio. Ejemplo:" >&2
  echo "API_BASE_URL=http://<IP_LAN_PC>:3000/api/v1 ./scripts/build-local-apk.sh" >&2
  exit 1
fi

case "$API_BASE_URL" in
  http://localhost:*|http://127.0.0.1:*|http://10.0.2.2:*)
    echo "API_BASE_URL no debe apuntar a localhost para APK en telefono fisico: $API_BASE_URL" >&2
    exit 1
    ;;
esac

flutter build apk \
  --flavor dev \
  --debug \
  --build-name "$BUILD_NAME" \
  --build-number "$BUILD_NUMBER" \
  --dart-define=APP_ENV=dev \
  --dart-define=APP_MODE=backend \
  --dart-define=API_BASE_URL="$API_BASE_URL"

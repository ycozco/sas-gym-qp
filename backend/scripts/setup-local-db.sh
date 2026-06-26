#!/bin/sh
set -eu

echo "Preparing Prisma client..."
npm run prisma:generate

echo "Syncing local database schema..."
if npm run db:push; then
  echo "Database schema is in sync."
  exit 0
fi

if [ "${ALLOW_TEST_DATA_RESET:-false}" != "true" ]; then
  echo "Local database sync failed and ALLOW_TEST_DATA_RESET is not true."
  echo "Set ALLOW_TEST_DATA_RESET=true only for local/dev environments if reset is acceptable."
  exit 1
fi

echo "Local database schema is incompatible with current Prisma schema."
echo "ALLOW_TEST_DATA_RESET=true, resetting local database..."
npx prisma db push --force-reset

import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

let loaded = false;

function loadLocalEnv() {
  if (loaded) return;
  loaded = true;

  const envPath = join(process.cwd(), '.env');
  if (!existsSync(envPath)) return;

  const lines = readFileSync(envPath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const index = trimmed.indexOf('=');
    if (index === -1) continue;

    const key = trimmed.slice(0, index).trim();
    const rawValue = trimmed.slice(index + 1).trim();
    const value = rawValue.replace(/^["']|["']$/g, '');

    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

export function getEnv(name: string, defaultValue?: string): string {
  loadLocalEnv();
  const value = process.env[name] ?? defaultValue;
  if (value === undefined || value === '') {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function getOptionalEnv(name: string, defaultValue = ''): string {
  loadLocalEnv();
  return process.env[name] ?? defaultValue;
}

export function getJwtSecret(): string {
  return getEnv('JWT_SECRET');
}

export function getAccessTokenTtl(): string {
  return getOptionalEnv('JWT_ACCESS_TTL', '15m');
}

export function getRefreshTokenDays(): number {
  const raw = Number(getOptionalEnv('JWT_REFRESH_DAYS', '7'));
  return Number.isFinite(raw) && raw > 0 ? raw : 7;
}

export function isProduction(): boolean {
  return getOptionalEnv('NODE_ENV', 'development') === 'production';
}

export function getFingerprintSecret(): string {
  return getEnv('HUELLA_SECRET_KEY');
}

export function getCorsOrigins(): string[] {
  const configured = getOptionalEnv(
    'CORS_ORIGINS',
    'http://localhost:8282,http://localhost:8383,http://localhost:3000',
  );

  return configured
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const repoRoot = process.cwd();
const requiredFiles = [
  'web_admin/index.html',
  'web_admin/shared.jsx',
  'web_admin/app.jsx',
  'web_admin/modules.jsx',
  'web_admin/modules2.jsx',
  'web_admin/dashboards.jsx',
  'web_admin/styles.css',
];

const missing = requiredFiles.filter((file) => !existsSync(join(repoRoot, file)));
if (missing.length > 0) {
  throw new Error(`Faltan archivos críticos del panel web: ${missing.join(', ')}`);
}

const indexHtml = readFileSync(join(repoRoot, 'web_admin/index.html'), 'utf8');
const shared = readFileSync(join(repoRoot, 'web_admin/shared.jsx'), 'utf8');
const app = readFileSync(join(repoRoot, 'web_admin/app.jsx'), 'utf8');
const styles = readFileSync(join(repoRoot, 'web_admin/styles.css'), 'utf8');

const indexMarkers = [
  'shared.jsx',
  'data.jsx',
  'dashboards.jsx',
  'modules.jsx',
  'modules2.jsx',
  'app.jsx',
];

const missingIndexMarkers = indexMarkers.filter((marker) => !indexHtml.includes(marker));
if (missingIndexMarkers.length > 0) {
  throw new Error(`index.html no carga bundles esperados: ${missingIndexMarkers.join(', ')}`);
}

const appMarkers = [
  '/auth/me',
  '/tenants/me',
  '/membership-plans',
  '/products',
  '/reports/dashboard',
  '/members/assigned',
  '/payments/me',
  '/schedules',
  '/points/catalog',
  '/auth/me/preferences',
];

const missingAppMarkers = appMarkers.filter((marker) => !app.includes(marker));
if (missingAppMarkers.length > 0) {
  throw new Error(`app.jsx no referencia contratos críticos: ${missingAppMarkers.join(', ')}`);
}

const sharedMarkers = [
  'credentials: "include"',
  'Authorization',
  'X-Tenant-ID',
  '/auth/refresh',
  'normalizeThemeMode',
];

const missingSharedMarkers = sharedMarkers.filter((marker) => !shared.includes(marker));
if (missingSharedMarkers.length > 0) {
  throw new Error(`shared.jsx no incluye piezas base de auth/theme: ${missingSharedMarkers.join(', ')}`);
}

const styleMarkers = [
  '[data-theme="dark"]',
  '[data-theme="system"]',
  '--accent-ink',
  '--sidebar-ink',
  '--control-ink',
];

const missingStyleMarkers = styleMarkers.filter((marker) => !styles.includes(marker));
if (missingStyleMarkers.length > 0) {
  throw new Error(`styles.css no cubre tokens de tema esperados: ${missingStyleMarkers.join(', ')}`);
}

console.log(JSON.stringify({
  ok: true,
  checkedFiles: requiredFiles.length,
  appContracts: appMarkers.length,
  themeTokens: styleMarkers.length,
}, null, 2));

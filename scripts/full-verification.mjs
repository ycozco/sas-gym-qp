import { spawn } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { randomUUID } from 'node:crypto';

const repoRoot = resolve(process.cwd());
const backendDir = join(repoRoot, 'backend');
const mobileDir = join(repoRoot, 'mobile_app');
const artifactRoot = join(
  repoRoot,
  '.artifacts',
  `verification-${new Date().toISOString().replace(/[:.]/g, '-')}`,
);

const args = new Set(process.argv.slice(2));
const options = {
  skipBackend: args.has('--skip-backend'),
  skipFlutter: args.has('--skip-flutter'),
  skipDocker: args.has('--skip-docker'),
  skipSecurity: args.has('--skip-security'),
  keepStack: args.has('--keep-stack'),
  help: args.has('--help') || args.has('-h'),
};

if (options.help) {
  console.log(`Uso:
  node scripts/full-verification.mjs [opciones]

Opciones:
  --skip-backend   Omite lint/build/tests del backend
  --skip-flutter   Omite analyze/test/build de Flutter
  --skip-docker    Omite compose config, stack, smoke e integración
  --skip-security  Omite checks HTTP/seguridad y resiliencia
  --keep-stack     No hace docker compose down al final
  --help, -h       Muestra esta ayuda
`);
  process.exit(0);
}

mkdirSync(artifactRoot, { recursive: true });

const summary = {
  startedAt: new Date().toISOString(),
  artifactRoot,
  checks: [],
  findings: [],
};

function shell(command, cwd = repoRoot) {
  return new Promise((resolvePromise) => {
    const child = spawn(command, {
      cwd,
      shell: true,
      env: process.env,
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (chunk) => {
      const text = chunk.toString();
      stdout += text;
      process.stdout.write(text);
    });

    child.stderr.on('data', (chunk) => {
      const text = chunk.toString();
      stderr += text;
      process.stderr.write(text);
    });

    child.on('close', (code) => {
      resolvePromise({ code: code ?? 1, stdout, stderr });
    });
  });
}

async function runCheck(name, command, cwd, opts = {}) {
  const startedAt = new Date().toISOString();
  const result = await shell(command, cwd);
  const passed = opts.allowFailure ? true : result.code === 0;
  const status = passed ? 'OK' : opts.blocking === false ? 'FAIL' : 'FAIL';
  const safeName = name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
  writeFileSync(
    join(artifactRoot, `${safeName}.log`),
    [`# ${name}`, `command: ${command}`, '', result.stdout, result.stderr]
      .filter(Boolean)
      .join('\n'),
    'utf8',
  );
  summary.checks.push({
    name,
    command,
    cwd,
    startedAt,
    finishedAt: new Date().toISOString(),
    status,
    exitCode: result.code,
    log: `${safeName}.log`,
  });
  if (!passed) {
    summary.findings.push({
      severity: opts.severity ?? 'high',
      source: name,
      type: 'command_failure',
      message: `Falló el comando: ${command}`,
    });
  }
  return result;
}

function recordCheck(name, status, details, extra = {}) {
  summary.checks.push({
    name,
    command: extra.command ?? null,
    cwd: extra.cwd ?? null,
    startedAt: extra.startedAt ?? null,
    finishedAt: new Date().toISOString(),
    status,
    details,
    log: extra.log ?? null,
  });
}

function recordFinding(severity, source, message, details = null) {
  summary.findings.push({ severity, source, message, details });
}

function ensureBackendEnv() {
  const target = join(backendDir, '.env');
  const source = join(backendDir, '.env.example');
  if (!existsSync(target) && existsSync(source)) {
    copyFileSync(source, target);
    recordCheck(
      'prepare-backend-env',
      'OK',
      'Se copió backend/.env.example a backend/.env',
    );
  } else {
    recordCheck(
      'prepare-backend-env',
      'OK',
      existsSync(target)
        ? 'backend/.env ya existía'
        : 'No se copió .env porque falta backend/.env.example',
    );
  }
}

function parseSetCookie(setCookie) {
  const cookieHeader = Array.isArray(setCookie)
    ? setCookie.join(', ')
    : String(setCookie || '');
  const parts = cookieHeader.split(/,(?=[^ ;]+=)/);
  return parts
    .map((entry) => entry.trim())
    .filter(Boolean);
}

function findCookie(setCookieHeaders, name) {
  for (const header of setCookieHeaders) {
    const pair = header.split(';')[0];
    if (pair.startsWith(`${name}=`)) return pair;
  }
  return '';
}

async function httpRequest(path, options = {}) {
  const headers = {
    Accept: 'application/json',
    ...(options.headers ?? {}),
  };
  const response = await fetch(`http://localhost:3000/api/v1${path}`, {
    method: options.method ?? 'GET',
    headers,
    body: options.body,
  });
  const text = await response.text();
  let data = text;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {}
  return {
    status: response.status,
    ok: response.ok,
    data,
    headers: response.headers,
    setCookie: parseSetCookie(
      typeof response.headers.getSetCookie === 'function'
        ? response.headers.getSetCookie()
        : response.headers.get('set-cookie'),
    ),
  };
}

async function login(emailOrDni, password, extraHeaders = {}) {
  const result = await httpRequest('/auth/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...extraHeaders,
    },
    body: JSON.stringify({ emailOrDni, password }),
  });
  const refreshCookie = findCookie(result.setCookie, 'sasgym_refresh');
  return {
    ...result,
    token: result.data?.token,
    tenantId: result.data?.tenantId,
    refreshCookie,
  };
}

async function verifySecurityAndFlows() {
  const startedAt = new Date().toISOString();
  const securityLog = [];
  const push = (line) => {
    securityLog.push(line);
    console.log(line);
  };

  try {
    const unauthorized = await httpRequest('/auth/me', {
      headers: { 'X-Tenant-ID': '77777777-7777-7777-7777-777777777777' },
    });
    push(`unauthorized /auth/me -> ${unauthorized.status}`);
    recordCheck(
      'auth-without-token',
      unauthorized.status === 401 || unauthorized.status === 403 ? 'OK' : 'FAIL',
      `Status ${unauthorized.status}`,
      { startedAt },
    );

    const invalid = await httpRequest('/auth/me', {
      headers: {
        Authorization: 'Bearer invalid-token',
        'X-Tenant-ID': '77777777-7777-7777-7777-777777777777',
      },
    });
    push(`invalid token /auth/me -> ${invalid.status}`);
    recordCheck(
      'auth-invalid-token',
      invalid.status === 401 || invalid.status === 403 ? 'OK' : 'FAIL',
      `Status ${invalid.status}`,
      { startedAt },
    );

    const admin = await login(
      'admin1.surco@test.sasgym.com',
      'admin_secure_pass',
    );
    if (!admin.ok || !admin.token || !admin.tenantId || !admin.refreshCookie) {
      recordCheck(
        'auth-admin-login',
        'FAIL',
        JSON.stringify(admin.data),
        { startedAt },
      );
      recordFinding(
        'critical',
        'auth-admin-login',
        'No se pudo iniciar sesión como admin para los checks HTTP.',
        admin.data,
      );
      throw new Error('admin login failed');
    }
    recordCheck('auth-admin-login', 'OK', `tenantId=${admin.tenantId}`, {
      startedAt,
    });

    const adminMe = await httpRequest('/auth/me', {
      headers: {
        Authorization: `Bearer ${admin.token}`,
        'X-Tenant-ID': admin.tenantId,
      },
    });
    recordCheck(
      'auth-admin-me',
      adminMe.ok ? 'OK' : 'FAIL',
      `Status ${adminMe.status}`,
      { startedAt },
    );

    const crossTenant = await httpRequest('/tenants/me', {
      headers: {
        Authorization: `Bearer ${admin.token}`,
        'X-Tenant-ID': '00000000-0000-0000-0000-000000000000',
      },
    });
    recordCheck(
      'tenant-cross-tenant',
      crossTenant.status === 403 ? 'OK' : 'FAIL',
      `Status ${crossTenant.status}`,
      { startedAt },
    );
    if (crossTenant.status !== 403) {
      recordFinding(
        'critical',
        'tenant-cross-tenant',
        'El acceso cross-tenant no fue rechazado con 403.',
        crossTenant.data,
      );
    }

    const refresh1 = await httpRequest('/auth/refresh', {
      method: 'POST',
      headers: {
        Cookie: admin.refreshCookie,
      },
    });
    const rotatedCookie = findCookie(refresh1.setCookie, 'sasgym_refresh');
    recordCheck(
      'auth-refresh-rotation',
      refresh1.ok && rotatedCookie ? 'OK' : 'FAIL',
      `Status ${refresh1.status}`,
      { startedAt },
    );

    const refreshOld = await httpRequest('/auth/refresh', {
      method: 'POST',
      headers: {
        Cookie: admin.refreshCookie,
      },
    });
    recordCheck(
      'auth-refresh-old-cookie',
      refreshOld.status === 401 ? 'OK' : 'FAIL',
      `Status ${refreshOld.status}`,
      { startedAt },
    );

    const logout = await httpRequest('/auth/logout', {
      method: 'POST',
      headers: {
        Cookie: rotatedCookie || admin.refreshCookie,
      },
    });
    recordCheck(
      'auth-logout',
      logout.ok ? 'OK' : 'FAIL',
      `Status ${logout.status}`,
      { startedAt },
    );

    const refreshAfterLogout = await httpRequest('/auth/refresh', {
      method: 'POST',
      headers: {
        Cookie: rotatedCookie || admin.refreshCookie,
      },
    });
    recordCheck(
      'auth-refresh-after-logout',
      refreshAfterLogout.status === 401 ? 'OK' : 'FAIL',
      `Status ${refreshAfterLogout.status}`,
      { startedAt },
    );

    const caja = await login('caja1.surco@test.sasgym.com', 'caja_secure_pass');
    if (!caja.ok || !caja.token || !caja.tenantId) {
      recordCheck(
        'auth-caja-login',
        'FAIL',
        JSON.stringify(caja.data),
        { startedAt },
      );
      throw new Error('caja login failed');
    }
    recordCheck('auth-caja-login', 'OK', `tenantId=${caja.tenantId}`, {
      startedAt,
    });

    const shift = await httpRequest('/payments/check-shift', {
      headers: {
        Authorization: `Bearer ${caja.token}`,
        'X-Tenant-ID': caja.tenantId,
      },
    });
    recordCheck(
      'caja-check-shift',
      shift.ok ? 'OK' : 'FAIL',
      `Status ${shift.status}`,
      { startedAt },
    );

    const activeCaja = await httpRequest('/payments/caja/active', {
      headers: {
        Authorization: `Bearer ${caja.token}`,
        'X-Tenant-ID': caja.tenantId,
      },
    });
    let cajaId = activeCaja.data?.id;
    if (!cajaId) {
      const openCaja = await httpRequest('/payments/caja/open', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${caja.token}`,
          'X-Tenant-ID': caja.tenantId,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          montoApertura: 100,
          observaciones: 'Apertura desde full-verification',
        }),
      });
      cajaId = openCaja.data?.id;
      recordCheck(
        'caja-open',
        openCaja.ok && cajaId ? 'OK' : 'FAIL',
        `Status ${openCaja.status}`,
        { startedAt },
      );
    } else {
      recordCheck('caja-active', 'OK', `Caja abierta existente ${cajaId}`, {
        startedAt,
      });
    }

    const memberSearch = await httpRequest('/members/search?q=11111111', {
      headers: {
        Authorization: `Bearer ${caja.token}`,
        'X-Tenant-ID': caja.tenantId,
      },
    });
    const member = Array.isArray(memberSearch.data) ? memberSearch.data[0] : null;
    recordCheck(
      'members-search',
      memberSearch.ok && member?.id ? 'OK' : 'FAIL',
      `Status ${memberSearch.status}`,
      { startedAt },
    );

    if (member?.id) {
      const idemKey = randomUUID();
      const ventaToken = randomUUID();
      const salePayload = {
        userId: member.id,
        planNombre: 'Mensual QA',
        duracionDias: 30,
        monto: 30,
        ventaToken,
        pagos: [{ metodo: 'CASH', monto: 30 }],
        observaciones: 'Verificacion idempotencia',
      };

      const sale1 = await httpRequest('/payments/membership-sale', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${caja.token}`,
          'X-Tenant-ID': caja.tenantId,
          'Content-Type': 'application/json',
          'idempotency-key': idemKey,
        },
        body: JSON.stringify(salePayload),
      });
      const sale2 = await httpRequest('/payments/membership-sale', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${caja.token}`,
          'X-Tenant-ID': caja.tenantId,
          'Content-Type': 'application/json',
          'idempotency-key': idemKey,
        },
        body: JSON.stringify(salePayload),
      });

      const idemOk =
        sale1.ok &&
        sale2.ok &&
        JSON.stringify(sale1.data) === JSON.stringify(sale2.data);
      recordCheck(
        'payments-idempotency',
        idemOk ? 'OK' : 'FAIL',
        `sale1=${sale1.status}, sale2=${sale2.status}`,
        { startedAt },
      );
      if (!idemOk) {
        recordFinding(
          'high',
          'payments-idempotency',
          'La segunda petición con la misma Idempotency-Key no devolvió una respuesta equivalente.',
          { sale1: sale1.data, sale2: sale2.data },
        );
      }

      const audit = await httpRequest('/reports/audit-logs?limit=5', {
        headers: {
          Authorization: `Bearer ${admin.token}`,
          'X-Tenant-ID': admin.tenantId,
        },
      });
      const auditEntries = Array.isArray(audit.data?.items)
        ? audit.data.items
        : Array.isArray(audit.data)
          ? audit.data
          : [];
      recordCheck(
        'reports-audit-logs',
        audit.ok ? 'OK' : 'FAIL',
        `Status ${audit.status}; items=${auditEntries.length}`,
        { startedAt },
      );
    }

    const memberUser = await login(
      'socio01.surco@test.sasgym.com',
      'member_secure_pass',
    );
    if (memberUser.ok && memberUser.token && memberUser.tenantId) {
      const fakePng = Buffer.from('not-a-real-png');
      const form = new FormData();
      form.append(
        'file',
        new Blob([fakePng], { type: 'image/png' }),
        'receipt.png',
      );
      form.append('monto', '10');
      form.append('metodo', 'yape');
      form.append('planNombre', 'Mensual QA');
      const upload = await httpRequest('/payments/upload-receipt', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${memberUser.token}`,
          'X-Tenant-ID': memberUser.tenantId,
        },
        body: form,
      });
      const uploadOk = upload.status >= 400;
      recordCheck(
        'uploads-magic-bytes',
        uploadOk ? 'OK' : 'FAIL',
        `Status ${upload.status}`,
        { startedAt },
      );
      if (!uploadOk) {
        recordFinding(
          'critical',
          'uploads-magic-bytes',
          'El backend aceptó un archivo adulterado con mimetype image/png.',
          upload.data,
        );
      }
    }

    const rateHeaders = { 'x-forwarded-for': '203.0.113.77' };
    let rateStatus = null;
    for (let attempt = 1; attempt <= 7; attempt += 1) {
      const badLogin = await login(
        'admin1.surco@test.sasgym.com',
        `bad-pass-${attempt}`,
        rateHeaders,
      );
      rateStatus = badLogin.status;
      push(`rate limiting attempt ${attempt} -> ${badLogin.status}`);
      if (badLogin.status === 429) break;
    }
    recordCheck(
      'auth-rate-limiting',
      rateStatus === 429 ? 'OK' : 'FAIL',
      `Último status ${rateStatus}`,
      { startedAt },
    );
    if (rateStatus !== 429) {
      recordFinding(
        'high',
        'auth-rate-limiting',
        'No se observó bloqueo 429 tras intentos fallidos repetidos.',
      );
    }
  } catch (error) {
    recordCheck(
      'security-http-suite',
      'FAIL',
      error instanceof Error ? error.message : String(error),
      { startedAt },
    );
    recordFinding(
      'critical',
      'security-http-suite',
      'La suite HTTP de seguridad no pudo completarse.',
      error instanceof Error ? error.stack : String(error),
    );
  } finally {
    writeFileSync(
      join(artifactRoot, 'security-http.log'),
      securityLog.join('\n'),
      'utf8',
    );
  }
}

function writeReports() {
  summary.finishedAt = new Date().toISOString();
  writeFileSync(
    join(artifactRoot, 'summary.json'),
    JSON.stringify(summary, null, 2),
    'utf8',
  );

  const lines = [
    '# Bitacora de Verificacion',
    '',
    `- Inicio: ${summary.startedAt}`,
    `- Fin: ${summary.finishedAt}`,
    `- Artifacts: ${artifactRoot}`,
    '',
    '## Checks',
    '',
    '| Check | Estado | Detalle |',
    '| --- | --- | --- |',
    ...summary.checks.map(
      (check) =>
        `| ${check.name} | ${check.status} | ${String(check.details ?? check.command ?? '').replace(/\|/g, '\\|')} |`,
    ),
    '',
    '## Hallazgos',
    '',
    summary.findings.length === 0
      ? '- Sin hallazgos registrados.'
      : '',
    ...summary.findings.map(
      (finding) =>
        `- [${finding.severity}] ${finding.source}: ${finding.message}`,
    ),
  ];

  writeFileSync(join(artifactRoot, 'summary.md'), lines.join('\n'), 'utf8');
}

async function main() {
  ensureBackendEnv();

  await runCheck('docker-compose-config-root', 'docker compose config', repoRoot);
  await runCheck(
    'docker-compose-config-dev',
    'docker compose -f docker-compose.dev.yml config',
    repoRoot,
  );

  if (!options.skipBackend) {
    await runCheck('backend-npm-ci', 'npm ci', backendDir);
    await runCheck(
      'backend-prisma-generate',
      'npm run prisma:generate',
      backendDir,
    );
    await runCheck(
      'backend-migrate-deploy',
      'npm run migrate:deploy',
      backendDir,
    );
    await runCheck('backend-seed-test', 'npm run seed:test', backendDir);
    await runCheck('backend-lint', 'npm run lint', backendDir);
    await runCheck('backend-build', 'npm run build', backendDir);
    await runCheck(
      'backend-test-unit',
      'npm test -- --runInBand',
      backendDir,
    );
    await runCheck(
      'backend-test-e2e',
      'npm run test:e2e -- --runInBand',
      backendDir,
    );
  }

  if (!options.skipFlutter) {
    await runCheck('flutter-pub-get', 'flutter pub get', mobileDir);
    await runCheck('flutter-analyze', 'flutter analyze', mobileDir);
    await runCheck(
      'flutter-format-check',
      'dart format --output=none --set-exit-if-changed lib test',
      mobileDir,
    );
    await runCheck('flutter-test', 'flutter test', mobileDir);
    await runCheck(
      'flutter-build-web',
      'flutter build web --release --dart-define=APP_ENV=ci --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=http://localhost:3000/api/v1',
      mobileDir,
    );
  }

  await runCheck('web-smoke', 'node scripts/web-smoke-check.mjs', repoRoot);

  if (!options.skipDocker) {
    await runCheck('docker-up-root', 'docker compose up --build -d', repoRoot);
    await runCheck('docker-ps-root', 'docker compose ps', repoRoot);
    await runCheck('integration-smoke', 'node scripts/integration-smoke.mjs', repoRoot);
    await runCheck('docker-logs-api-root', 'docker compose logs api', repoRoot, {
      allowFailure: true,
    });
    await runCheck('docker-logs-web-root', 'docker compose logs web', repoRoot, {
      allowFailure: true,
    });
    await runCheck(
      'docker-logs-frontend-root',
      'docker compose logs frontend-web',
      repoRoot,
      { allowFailure: true },
    );

    await runCheck(
      'docker-up-dev',
      'docker compose -f docker-compose.dev.yml up --build -d',
      repoRoot,
    );
    await runCheck(
      'docker-ps-dev',
      'docker compose -f docker-compose.dev.yml ps',
      repoRoot,
    );

    if (!options.skipSecurity) {
      await verifySecurityAndFlows();
      await runCheck(
        'docker-inspect-network-db-dev',
        'docker inspect gymsmart-postgres-dev',
        repoRoot,
        { allowFailure: true },
      );
      await runCheck(
        'docker-inspect-network-redis-dev',
        'docker inspect gymsmart-redis-dev',
        repoRoot,
        { allowFailure: true },
      );
      await runCheck(
        'docker-inspect-network-test-client-dev',
        'docker inspect gymsmart-test-client',
        repoRoot,
        { allowFailure: true },
      );
      await runCheck(
        'backend-biometric-spec',
        'npm test -- --runInBand biometric-handshake.gateway.spec.ts',
        backendDir,
      );
    }

    if (!options.keepStack) {
      await runCheck(
        'docker-down-dev',
        'docker compose -f docker-compose.dev.yml down -v',
        repoRoot,
        { allowFailure: true },
      );
      await runCheck('docker-down-root', 'docker compose down -v', repoRoot, {
        allowFailure: true,
      });
    }
  }

  writeReports();
  console.log(`Resumen escrito en ${join(artifactRoot, 'summary.md')}`);
}

await main();

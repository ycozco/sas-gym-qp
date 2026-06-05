const API_BASE = process.env.API_BASE_URL || 'http://localhost:3000/api/v1';
const WEB_BASE = process.env.WEB_BASE_URL || 'http://localhost:8282';
const FLUTTER_WEB_BASE = process.env.FLUTTER_WEB_BASE_URL || 'http://localhost:8383';

const users = {
  admin: {
    emailOrDni: 'admin1.surco@test.sasgym.com',
    password: 'admin_secure_pass',
    checks: ['/auth/me', '/tenants/me', '/membership-plans?includeInactive=true', '/products?includeInactive=true', '/reports/dashboard'],
  },
  caja: {
    emailOrDni: 'caja1.surco@test.sasgym.com',
    password: 'caja_secure_pass',
    checks: ['/auth/me', '/tenants/me', '/payments/caja/active', '/products?includeInactive=false'],
  },
  coach: {
    emailOrDni: 'trainer1.surco@test.sasgym.com',
    password: 'trainer_secure_pass',
    checks: ['/auth/me', '/tenants/me', '/members/assigned'],
  },
  member: {
    emailOrDni: 'socio01.surco@test.sasgym.com',
    password: 'member_secure_pass',
    checks: ['/auth/me', '/tenants/me', '/payments/me'],
  },
  superadmin: {
    emailOrDni: 'superadmin@test.sasgym.com',
    password: 'super_secure_pass',
    checks: ['/auth/me', '/tenants'],
  },
};

async function waitFor(url, label, attempts = 40, delayMs = 3000) {
  let lastError = null;
  for (let i = 0; i < attempts; i += 1) {
    try {
      const res = await fetch(url);
      if (res.ok) return;
      lastError = new Error(`${label} respondió ${res.status}`);
    } catch (error) {
      lastError = error;
    }
    await new Promise((resolve) => setTimeout(resolve, delayMs));
  }
  throw lastError || new Error(`Timeout esperando ${label}`);
}

function cookieValue(setCookieHeaders, name) {
  for (const header of setCookieHeaders) {
    const firstPart = header.split(';')[0];
    if (firstPart.startsWith(`${name}=`)) {
      return firstPart;
    }
  }
  return '';
}

async function jsonRequest(path, { method = 'GET', token, tenantId, body, cookie } = {}) {
  const headers = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (tenantId) headers['X-Tenant-ID'] = tenantId;
  if (cookie) headers.Cookie = cookie;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const response = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return {
    status: response.status,
    ok: response.ok,
    data,
    setCookie: typeof response.headers.getSetCookie === 'function'
      ? response.headers.getSetCookie()
      : (response.headers.get('set-cookie') ? [response.headers.get('set-cookie')] : []),
  };
}

async function smokeUser(label, config) {
  const login = await jsonRequest('/auth/login', {
    method: 'POST',
    body: {
      emailOrDni: config.emailOrDni,
      password: config.password,
    },
  });
  if (!login.ok || !login.data?.token || !login.data?.tenantId) {
    throw new Error(`Login falló para ${label}: ${JSON.stringify(login.data)}`);
  }

  const refreshCookie = cookieValue(login.setCookie, 'sasgym_refresh');
  if (!refreshCookie) {
    throw new Error(`No se recibió cookie refresh para ${label}`);
  }

  const token = login.data.token;
  const tenantId = login.data.tenantId;
  const checks = [];

  for (const path of config.checks) {
    const result = await jsonRequest(path, { token, tenantId, cookie: refreshCookie });
    if (!result.ok) {
      throw new Error(`Chequeo ${path} falló para ${label}: ${result.status}`);
    }
    checks.push({ path, status: result.status });
  }

  if (label === 'admin') {
    const refresh = await jsonRequest('/auth/refresh', {
      method: 'POST',
      tenantId,
      cookie: refreshCookie,
    });
    if (!refresh.ok || !refresh.data?.token) {
      throw new Error(`Refresh falló para admin: ${refresh.status}`);
    }

    const logoutCookie = cookieValue(refresh.setCookie, 'sasgym_refresh') || refreshCookie;
    const logout = await jsonRequest('/auth/logout', {
      method: 'POST',
      cookie: logoutCookie,
    });
    if (!logout.ok) {
      throw new Error(`Logout falló para admin: ${logout.status}`);
    }
  }

  return {
    role: label,
    tenantId,
    checks,
  };
}

await waitFor(`${WEB_BASE}/web/index.html`, 'panel web');
await waitFor(`${FLUTTER_WEB_BASE}/`, 'flutter web');
await waitFor(`${API_BASE.replace('/api/v1', '')}/api/v1`, 'api');

const webIndex = await fetch(`${WEB_BASE}/web/index.html`);
if (!webIndex.ok) throw new Error(`Panel web no responde bien: ${webIndex.status}`);

const results = [];
for (const [label, config] of Object.entries(users)) {
  results.push(await smokeUser(label, config));
}

console.log(JSON.stringify({
  ok: true,
  apiBase: API_BASE,
  webBase: WEB_BASE,
  flutterWebBase: FLUTTER_WEB_BASE,
  results,
}, null, 2));

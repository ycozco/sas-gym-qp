// app.jsx — raíz del panel: login → shell con sidebar + routing por sección.

const DASHBOARDS = {
  superadmin: SuperDashboard,
  admin: AdminDashboard,
  cajero: CajeroDashboard,
  coach: CoachDashboard,
  miembro: MiembroDashboard,
};

const SECTIONS = {
  usuarios: Usuarios,
  asistencia: Asistencia,
  pagos: Pagos,
  productos: Productos,
  reportes: Reportes,
  config: Config,
  // Módulos ampliados (paridad con crosshero-gym)
  membresias: Membresias,
  caja: Caja,
  finanzas: Finanzas,
  puntos: Puntos,
  clases: Clases,
  entrenamientos: Entrenamientos,
  crm: CRM,
  // Super Admin (plataforma SaaS)
  gimnasios: Gimnasios,
  planes: PlanesSaaS,
};

// Título del topbar por sección. `dashboard` depende del rol.
const TITLE = {
  dashboard: { superadmin: "Resumen de la plataforma", admin: "Dashboard", cajero: "Dashboard de turno", coach: "Panel del entrenador", miembro: "Mi resumen" },
  gimnasios:  { _: "Gimnasios de la red" },
  planes:     { _: "Planes SaaS" },
  usuarios:   { coach: "Mis alumnos", _: "Usuarios" },
  asistencia: { _: "Control de asistencia" },
  pagos:      { cajero: "Cobros del turno", _: "Pagos y acreditaciones" },
  productos:  { _: "Productos e inventario" },
  reportes:   { _: "Reportes y analítica" },
  config:     { _: "Configuración del gimnasio" },
  membresias: { _: "Membresías y planes" },
  caja:       { _: "Caja del turno" },
  finanzas:   { _: "Finanzas del gimnasio" },
  puntos:     { _: "Puntos y fidelización" },
  clases:     { _: "Clases y horarios" },
  entrenamientos: { _: "Entrenamientos y rutinas" },
  crm:        { _: "CRM · campañas y contactos" },
};
const titleFor = (section, role) => {
  const t = TITLE[section] || {};
  return t[role] || t._ || "—";
};

function App() {
  const [role, setRole] = React.useState(null);          // null → login
  const [authToken, setAuthToken] = React.useState(() => {
    try { return localStorage.getItem(AUTH_TOKEN_KEY) || ""; } catch (e) { return ""; }
  });
  const [tenantId, setTenantId] = React.useState(() => {
    try { return localStorage.getItem(TENANT_ID_KEY) || ""; } catch (e) { return ""; }
  });
  const [currentUser, setCurrentUser] = React.useState(null);
  const [tenantSettings, setTenantSettings] = React.useState(null);
  const [membershipPlans, setMembershipPlans] = React.useState([]);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState("");
  const [section, setSection] = React.useState("dashboard");
  const [themeMode, setThemeMode] = React.useState(() => {
    try { return localStorage.getItem("sasgym.theme") || "system"; } catch (e) { return "system"; }
  });

  React.useEffect(() => {
    document.documentElement.dataset.theme = themeMode;
    try { localStorage.setItem("sasgym.theme", themeMode); } catch (e) {}
  }, [themeMode]);

  React.useEffect(() => {
    applyTenantTheme(tenantSettings);
  }, [tenantSettings]);

  const authHeaders = React.useMemo(() => ({ token: authToken, tenantId }), [authToken, tenantId]);

  const loadTenantSettings = React.useCallback(async (override = authHeaders) => {
    const data = await apiRequest("/tenants/me", override);
    const normalized = normalizeTenantSettings(data);
    setTenantSettings(normalized);
    return normalized;
  }, [authHeaders]);

  const loadMembershipPlans = React.useCallback(async (includeInactive = role === "admin", override = authHeaders) => {
    const data = await apiRequest(`/membership-plans?includeInactive=${includeInactive ? "true" : "false"}`, override);
    const plans = data.map(normalizeMembershipPlan);
    setMembershipPlans(plans);
    return plans;
  }, [authHeaders, role]);

  const loadSession = React.useCallback(async (override = authHeaders) => {
    setLoading(true);
    setError("");
    try {
      const me = await apiRequest("/auth/me", override);
      const nextRole = roleFromBackend(me.rol);
      setCurrentUser(me);
      setRole(nextRole);
      await loadTenantSettings(override);
      await loadMembershipPlans(nextRole === "admin", override);
    } catch (e) {
      setError(e.message || "No se pudo cargar la sesión.");
      setRole(null);
      setCurrentUser(null);
      setTenantSettings(null);
      setMembershipPlans([]);
      try {
        localStorage.removeItem(AUTH_TOKEN_KEY);
        localStorage.removeItem(TENANT_ID_KEY);
      } catch (_) {}
    } finally {
      setLoading(false);
    }
  }, [authHeaders, loadMembershipPlans, loadTenantSettings]);

  React.useEffect(() => {
    if (authToken && tenantId && !currentUser) {
      loadSession({ token: authToken, tenantId });
    }
  }, [authToken, tenantId]);

  const login = async (emailOrDni, password) => {
    setLoading(true);
    setError("");
    try {
      const result = await apiRequest("/auth/login", {
        method: "POST",
        body: { emailOrDni, password },
      });
      try {
        localStorage.setItem(AUTH_TOKEN_KEY, result.token);
        localStorage.setItem(TENANT_ID_KEY, result.tenantId);
      } catch (_) {}
      setAuthToken(result.token);
      setTenantId(result.tenantId);
      await loadSession({ token: result.token, tenantId: result.tenantId });
      setSection("dashboard");
    } catch (e) {
      setError(e.message || "Credenciales inválidas.");
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    try {
      localStorage.removeItem(AUTH_TOKEN_KEY);
      localStorage.removeItem(TENANT_ID_KEY);
    } catch (_) {}
    setAuthToken("");
    setTenantId("");
    setCurrentUser(null);
    setTenantSettings(null);
    setMembershipPlans([]);
    setRole(null);
    setSection("dashboard");
    applyTenantTheme(null);
  };

  const saveTenantSettings = async (payload) => {
    const saved = await apiRequest("/tenants/me/settings", {
      ...authHeaders,
      method: "PATCH",
      body: payload,
    });
    const normalized = normalizeTenantSettings(saved);
    setTenantSettings(normalized);
    return normalized;
  };

  const saveMembershipPlan = async (plan) => {
    const payload = planToApiPayload(plan);
    if (plan.id) {
      await apiRequest(`/membership-plans/${plan.id}`, {
        ...authHeaders,
        method: "PATCH",
        body: payload,
      });
    } else {
      await apiRequest("/membership-plans", {
        ...authHeaders,
        method: "POST",
        body: payload,
      });
    }
    return loadMembershipPlans(true);
  };

  const deactivateMembershipPlan = async (id) => {
    await apiRequest(`/membership-plans/${id}`, {
      ...authHeaders,
      method: "DELETE",
    });
    return loadMembershipPlans(true);
  };

  if (!role) {
    return (
      <>
        <ThemeSwitcher themeMode={themeMode} setThemeMode={setThemeMode}/>
        <Login onLogin={login} loading={loading} error={error}/>
      </>
    );
  }

  // La sección activa debe pertenecer al nav del rol; si no, cae a dashboard.
  const allowed = ROLES[role].nav.flatMap(g => g.items.map(it => it.id));
  const current = allowed.includes(section) ? section : "dashboard";

  let View;
  if (current === "dashboard") View = DASHBOARDS[role];
  else View = SECTIONS[current];

  const go = (s) => setSection(allowed.includes(s) ? s : "dashboard");

  const gym = tenantSettings || GYM;
  const appContext = {
    authToken,
    tenantId,
    currentUser,
    tenantSettings,
    membershipPlans,
    loading,
    error,
    reloadTenantSettings: loadTenantSettings,
    reloadMembershipPlans: () => loadMembershipPlans(role === "admin"),
    saveTenantSettings,
    saveMembershipPlan,
    deactivateMembershipPlan,
  };

  return (
    <div className="app">
      <Sidebar role={role} section={current} onNavigate={go} tenantSettings={tenantSettings}/>
      <div className="main">
        <Topbar
          title={titleFor(current, role)}
          sub={role === "superadmin" ? "Plataforma GymSmart · SaaS multi-tenant" : `${gym.name} · ${ROLES[role].label}`}
          role={role}
          currentUser={currentUser}
          onLogout={logout}
        />
        <div style={{ position: "absolute", right: 28, top: 12 }}>
          <ThemeSwitcher themeMode={themeMode} setThemeMode={setThemeMode}/>
        </div>
        <main className="content">
          <View go={go} app={appContext}/>
        </main>
      </div>
    </div>
  );
}

function ThemeSwitcher({ themeMode, setThemeMode }) {
  return (
    <div className="theme-seg" aria-label="Tema visual">
      {[
        ["system", "Sistema"],
        ["light", "Claro"],
        ["dark", "Oscuro"],
      ].map(([id, label]) => (
        <button key={id} aria-pressed={themeMode === id} onClick={() => setThemeMode(id)}>
          {label}
        </button>
      ))}
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);

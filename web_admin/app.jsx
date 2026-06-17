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
  dietas: Dietas,
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
  dietas:     { _: "Dietas y Nutrición" },
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
  const [products, setProducts] = React.useState([]);
  const [dashboardSummary, setDashboardSummary] = React.useState(null);
  const [adminMembers, setAdminMembers] = React.useState([]);
  const [cashiers, setCashiers] = React.useState([]);
  const [pendingPayments, setPendingPayments] = React.useState([]);
  const [auditLogs, setAuditLogs] = React.useState([]);
  const [tenants, setTenants] = React.useState([]);
  const [trainerMembers, setTrainerMembers] = React.useState([]);
  const [memberPayments, setMemberPayments] = React.useState([]);
  const [announcements, setAnnouncements] = React.useState([]);
  const [observations, setObservations] = React.useState([]);
  const [activeRoutine, setActiveRoutine] = React.useState(null);
  const [schedules, setSchedules] = React.useState([]);
  const [pointsSummary, setPointsSummary] = React.useState(null);
  const [pointsCatalog, setPointsCatalog] = React.useState(null);
  const [pointsConfig, setPointsConfig] = React.useState(null);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState("");
  const [section, setSection] = React.useState("dashboard");
  const [themeMode, setThemeMode] = React.useState(() => {
    try { return normalizeThemeMode(localStorage.getItem(THEME_MODE_KEY)); } catch (e) { return "system"; }
  });
  const themeSyncRef = React.useRef({ ready: false, lastSynced: null });

  React.useEffect(() => {
    document.documentElement.dataset.theme = themeMode;
    try { localStorage.setItem(THEME_MODE_KEY, themeMode); } catch (e) {}
  }, [themeMode]);

  React.useEffect(() => {
    if (!currentUser?.id) {
      themeSyncRef.current = { ready: false, lastSynced: null };
      return;
    }
    if (!themeSyncRef.current.ready) {
      themeSyncRef.current = {
        ready: true,
        lastSynced: normalizeThemeMode(currentUser.themePreference || currentUser.theme_preference),
      };
      return;
    }

    const nextMode = normalizeThemeMode(themeMode);
    if (themeSyncRef.current.lastSynced === nextMode) return;

    let cancelled = false;
    apiRequest("/auth/me/preferences", {
      ...authHeaders,
      method: "PATCH",
      body: { themeMode: nextMode },
    })
      .then((result) => {
        if (cancelled) return;
        const savedMode = normalizeThemeMode(result?.themePreference || result?.theme_preference || nextMode);
        themeSyncRef.current.lastSynced = savedMode;
        setCurrentUser((prev) => prev ? { ...prev, themePreference: savedMode, theme_preference: savedMode } : prev);
        if (savedMode !== themeMode) setThemeMode(savedMode);
      })
      .catch((e) => {
        if (cancelled) return;
        setError((prev) => prev || e.message || "No se pudo sincronizar el tema.");
      });

    return () => { cancelled = true; };
  }, [authHeaders, currentUser?.id, themeMode]);

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

  const loadProducts = React.useCallback(async (includeInactive = role === "admin", override = authHeaders) => {
    const data = await apiRequest(`/products?includeInactive=${includeInactive ? "true" : "false"}`, override);
    const rows = data.map(normalizeProduct);
    setProducts(rows);
    return rows;
  }, [authHeaders, role]);

  const loadDashboardSummary = React.useCallback(async (override = authHeaders) => {
    const data = await apiRequest("/reports/dashboard", override);
    setDashboardSummary(data);
    return data;
  }, [authHeaders]);

  const loadAdminData = React.useCallback(async (override = authHeaders) => {
    const [members, cashierRows, pending, audit] = await Promise.all([
      apiRequest("/admin/members", override).catch(() => []),
      apiRequest("/admin/cashiers", override).catch(() => []),
      apiRequest("/payments/pending", override).catch(() => []),
      apiRequest("/reports/audit-logs", override).catch(() => []),
    ]);
    setAdminMembers(members);
    setCashiers(cashierRows);
    setPendingPayments(pending);
    setAuditLogs(audit);
    return { members, cashierRows, pending, audit };
  }, [authHeaders]);

  const loadTenants = React.useCallback(async (override = authHeaders) => {
    const data = await apiRequest("/tenants", override);
    setTenants(data);
    return data;
  }, [authHeaders]);

  const loadTrainerData = React.useCallback(async (override = authHeaders) => {
    const data = await apiRequest("/members/assigned", override);
    setTrainerMembers(data);
    return data;
  }, [authHeaders]);

  const loadMemberData = React.useCallback(async (override = authHeaders) => {
    const data = await apiRequest("/payments/me", override);
    setMemberPayments(data);
    return data;
  }, [authHeaders]);

  const loadAnnouncements = React.useCallback(async (all = false, override = authHeaders) => {
    const data = await apiRequest(all ? "/announcements/all" : "/announcements", override);
    setAnnouncements(data);
    return data;
  }, [authHeaders]);

  const loadObservations = React.useCallback(async (override = authHeaders) => {
    const data = await apiRequest("/observations", override);
    setObservations(data);
    return data;
  }, [authHeaders]);

  const loadActiveRoutine = React.useCallback(async (override = authHeaders) => {
    const data = await apiRequest("/routines/active", override);
    setActiveRoutine(data);
    return data;
  }, [authHeaders]);

  const loadSchedules = React.useCallback(async (override = authHeaders) => {
    const data = await apiRequest("/schedules", override);
    setSchedules(data);
    return data;
  }, [authHeaders]);

  const loadDiets = React.useCallback(async (memberId = "", override = authHeaders) => {
    const query = memberId ? `?memberId=${memberId}` : "";
    return apiRequest(`/dietas${query}`, override).catch(() => apiRequest(`/diets${query}`, override));
  }, [authHeaders]);

  const loadPointsData = React.useCallback(async (override = authHeaders) => {
    const [summary, catalog, config] = await Promise.all([
      apiRequest("/points/summary", override).catch(() => null),
      apiRequest("/points/catalog", override).catch(() => null),
      apiRequest("/points/config", override).catch(() => null),
    ]);
    setPointsSummary(summary);
    setPointsCatalog(catalog);
    setPointsConfig(config);
    return { summary, catalog, config };
  }, [authHeaders]);

  const loadSession = React.useCallback(async (override = authHeaders) => {
    setLoading(true);
    setError("");
    try {
      const me = await apiRequest("/auth/me", override);
      const nextRole = roleFromBackend(me.rol);
      const backendTheme = normalizeThemeMode(me.themePreference || me.theme_preference);
      themeSyncRef.current = {
        ready: true,
        lastSynced: backendTheme,
      };
      setThemeMode(backendTheme);
      setCurrentUser(me);
      setRole(nextRole);
      await loadTenantSettings(override);
      await loadMembershipPlans(nextRole === "admin", override);
      if (["admin", "cajero"].includes(nextRole)) {
        await loadProducts(nextRole === "admin", override).catch(() => []);
      }
      if (["admin", "cajero", "coach", "miembro"].includes(nextRole)) {
        await loadAnnouncements(nextRole === "admin", override).catch(() => []);
        await loadSchedules(override).catch(() => []);
      }
      if (["admin", "cajero", "miembro"].includes(nextRole)) {
        await loadPointsData(override).catch(() => null);
      }
      if (nextRole === "admin") {
        await loadDashboardSummary(override).catch(() => null);
        await loadAdminData(override).catch(() => null);
        await loadObservations(override).catch(() => []);
      }
      if (nextRole === "superadmin") {
        await loadTenants(override).catch(() => []);
      }
      if (nextRole === "coach") {
        await loadTrainerData(override).catch(() => []);
      }
      if (nextRole === "miembro") {
        await loadMemberData(override).catch(() => []);
        await loadActiveRoutine(override).catch(() => null);
      }
    } catch (e) {
      setError(e.message || "No se pudo cargar la sesión.");
      setRole(null);
      setCurrentUser(null);
      setTenantSettings(null);
      setMembershipPlans([]);
      setProducts([]);
      setDashboardSummary(null);
      setAdminMembers([]);
      setCashiers([]);
      setPendingPayments([]);
      setAuditLogs([]);
      setTenants([]);
      setTrainerMembers([]);
      setMemberPayments([]);
      setAnnouncements([]);
      setObservations([]);
      setActiveRoutine(null);
      setSchedules([]);
      setPointsSummary(null);
      setPointsCatalog(null);
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
    apiRequest("/auth/logout", { method: "POST", token: authToken, tenantId, _retry: false }).catch(() => null);
    try {
      localStorage.removeItem(AUTH_TOKEN_KEY);
      localStorage.removeItem(TENANT_ID_KEY);
    } catch (_) {}
    setAuthToken("");
    setTenantId("");
    setCurrentUser(null);
    setTenantSettings(null);
    setMembershipPlans([]);
    setProducts([]);
    setDashboardSummary(null);
    setAdminMembers([]);
    setCashiers([]);
    setPendingPayments([]);
    setAuditLogs([]);
    setTenants([]);
    setTrainerMembers([]);
    setMemberPayments([]);
    setAnnouncements([]);
    setObservations([]);
    setActiveRoutine(null);
    setSchedules([]);
    setPointsSummary(null);
    setPointsCatalog(null);
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

  const saveProduct = async (product) => {
    const payload = productToApiPayload(product);
    if (product.id) {
      await apiRequest(`/products/${product.id}`, {
        ...authHeaders,
        method: "PATCH",
        body: payload,
      });
    } else {
      await apiRequest("/products", {
        ...authHeaders,
        method: "POST",
        body: payload,
      });
    }
    return loadProducts(true);
  };

  const deactivateProduct = async (id) => {
    await apiRequest(`/products/${id}`, {
      ...authHeaders,
      method: "DELETE",
    });
    return loadProducts(true);
  };

  const searchMembers = (q) => apiRequest(`/members/search?q=${encodeURIComponent(q)}`, authHeaders);
  const getActiveCaja = () => apiRequest("/payments/caja/active", authHeaders);
  const openCaja = (payload) => apiRequest("/payments/caja/open", { ...authHeaders, method: "POST", body: payload });
  const getCajaDetails = () => apiRequest("/payments/caja/details", authHeaders);
  const getCajaSales = () => apiRequest("/payments/caja/sales", authHeaders);
  const createCajaEgress = (payload) => apiRequest("/payments/caja/egress", { ...authHeaders, method: "POST", body: payload });
  const closeCaja = (payload) => apiRequest("/payments/caja/close", { ...authHeaders, method: "POST", body: payload });
  const simulateAccess = (dni) => apiRequest("/attendance/simulation-access", { ...authHeaders, method: "POST", body: { dni } });
  const chargePOS = (payload) => apiRequest("/payments/pos-charge", { ...authHeaders, method: "POST", body: payload });
  const editCajaOpeningAmount = (payload) => apiRequest("/payments/caja/edit-opening-amount", { ...authHeaders, method: "PATCH", body: payload });
  const adminEditCaja = (id, payload) => apiRequest(`/payments/caja/${id}/admin-edit`, { ...authHeaders, method: "PATCH", body: payload });
  const toggleTenant = (id) => apiRequest(`/tenants/${id}/toggle`, { ...authHeaders, method: "POST" }).then(() => loadTenants());
  const resolvePayment = (id, status, comments = "") => apiRequest(`/payments/${id}/resolve`, { ...authHeaders, method: "POST", body: { status, comments } }).then(() => loadAdminData());
  const saveAdminMember = (member) => apiRequest(member.id ? `/admin/members/${member.id}` : "/admin/members", { ...authHeaders, method: member.id ? "PATCH" : "POST", body: member }).then(() => loadAdminData());
  const toggleAdminMember = (id) => apiRequest(`/admin/members/${id}/toggle-active`, { ...authHeaders, method: "POST" }).then(() => loadAdminData());
  const saveAnnouncement = (payload) => apiRequest(payload.id ? `/announcements/${payload.id}` : "/announcements", { ...authHeaders, method: payload.id ? "PUT" : "POST", body: payload }).then(() => loadAnnouncements(true));
  const toggleAnnouncement = (id) => apiRequest(`/announcements/${id}/toggle`, { ...authHeaders, method: "PATCH" }).then(() => loadAnnouncements(true));
  const saveDiet = (payload) => {
    if (payload.id) {
      return apiRequest(`/diets/${payload.id}`, { ...authHeaders, method: "PATCH", body: payload });
    }
    return apiRequest("/diets", { ...authHeaders, method: "POST", body: payload });
  };
  const deactivateDiet = (id) => apiRequest(`/diets/${id}`, { ...authHeaders, method: "DELETE" });
  const savePointsConfig = async (payload) => {
    const data = await apiRequest("/points/config", {
      ...authHeaders,
      method: "PUT",
      body: payload,
    });
    setPointsConfig(data);
    return data;
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
    products,
    dashboardSummary,
    adminMembers,
    cashiers,
    pendingPayments,
    auditLogs,
    tenants,
    trainerMembers,
    memberPayments,
    announcements,
    observations,
    activeRoutine,
    schedules,
    pointsSummary,
    pointsCatalog,
    pointsConfig,
    loading,
    error,
    reloadTenantSettings: loadTenantSettings,
    reloadMembershipPlans: () => loadMembershipPlans(role === "admin"),
    reloadProducts: () => loadProducts(role === "admin"),
    reloadDashboardSummary: loadDashboardSummary,
    reloadAdminData: loadAdminData,
    reloadTenants: loadTenants,
    reloadTrainerData: loadTrainerData,
    reloadMemberData: loadMemberData,
    reloadAnnouncements: loadAnnouncements,
    reloadObservations: loadObservations,
    reloadActiveRoutine: loadActiveRoutine,
    reloadSchedules: loadSchedules,
    reloadPointsData: loadPointsData,
    loadDiets,
    saveDiet,
    deactivateDiet,
    savePointsConfig,
    saveTenantSettings,
    saveMembershipPlan,
    deactivateMembershipPlan,
    saveProduct,
    deactivateProduct,
    searchMembers,
    getActiveCaja,
    openCaja,
    getCajaDetails,
    getCajaSales,
    createCajaEgress,
    closeCaja,
    simulateAccess,
    chargePOS,
    editCajaOpeningAmount,
    adminEditCaja,
    toggleTenant,
    resolvePayment,
    saveAdminMember,
    toggleAdminMember,
    saveAnnouncement,
    toggleAnnouncement,
  };

  return (
    <div className="app">
      <Sidebar role={role} section={current} onNavigate={go} tenantSettings={tenantSettings}/>
      <div className="main">
        <Topbar
          title={titleFor(current, role)}
          sub={role === "superadmin" ? "Red SaasGym · operacion multi-sede" : `${gym.name} · ${ROLES[role].label}`}
          role={role}
          currentUser={currentUser}
          onLogout={logout}
          themeMode={themeMode}
          setThemeMode={setThemeMode}
        />
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
        ["system", "Sistema", "◎"],
        ["light", "Claro", "☼"],
        ["dark", "Oscuro", "◐"],
      ].map(([id, label, glyph]) => (
        <button key={id} aria-pressed={themeMode === id} onClick={() => setThemeMode(id)} aria-label={label} title={label}>
          <span className="theme-glyph" aria-hidden="true">{glyph}</span>
        </button>
      ))}
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);

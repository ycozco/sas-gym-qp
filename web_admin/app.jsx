import React from "react";
import { createRoot } from "react-dom/client";
import {
  AdminDashboard,
  CajeroDashboard,
  CoachDashboard,
  Login,
  MiembroDashboard,
  SuperDashboard,
} from "./dashboards.jsx";
import { GYM, ROLES } from "./data.jsx";
import {
  AUTH_TOKEN_KEY,
  Sidebar,
  TENANT_ID_KEY,
  THEME_MODE_KEY,
  ThemeSwitcher,
  Topbar,
  apiRequest,
  applyTenantTheme,
  normalizeMembershipPlan,
  normalizeProduct,
  normalizeSaasPlan,
  normalizeTenantSettings,
  normalizeThemeMode,
  planToApiPayload,
  productToApiPayload,
  saasPlanToApiPayload,
  roleFromBackend,
} from "./shared.jsx";
import { Asistencia } from "./src/features/attendance/Asistencia.jsx";
import { Caja } from "./src/features/cashier/Caja.jsx";
import { Clases } from "./src/features/classes/ClasesGrupales.jsx";
import { CRM } from "./src/features/crm/CRM.jsx";
import { Reportes } from "./src/features/dashboard/Dashboard.jsx";
import { Dietas } from "./src/features/diets/Dietas.jsx";
import { Finanzas } from "./src/features/finances/Finanzas.jsx";
import { Gimnasios } from "./src/features/gyms/Gimnasios.jsx";
import { Productos } from "./src/features/inventory/Productos.jsx";
import { Usuarios } from "./src/features/members/Socios.jsx";
import { Membresias } from "./src/features/memberships/Membresias.jsx";
import { Pagos } from "./src/features/payments/Pagos.jsx";
import { Puntos } from "./src/features/points/Puntos.jsx";
import { PlanesSaaS } from "./src/features/saas/PlanesSaaS.jsx";
import { Config } from "./src/features/settings/Config.jsx";
import { Entrenamientos } from "./src/features/workouts/Entrenamientos.jsx";

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
  dashboard: {
    superadmin: "Resumen de la plataforma",
    admin: "Dashboard",
    cajero: "Dashboard de turno",
    coach: "Panel del entrenador",
    miembro: "Mi resumen",
  },
  gimnasios: { _: "Gimnasios de la red" },
  planes: { _: "Planes SaaS" },
  usuarios: { coach: "Mis alumnos", _: "Usuarios" },
  asistencia: { _: "Control de asistencia" },
  pagos: { cajero: "Cobros del turno", _: "Pagos y acreditaciones" },
  productos: { _: "Productos e inventario" },
  reportes: { _: "Reportes y analítica" },
  config: { _: "Configuración del gimnasio" },
  membresias: { _: "Membresías y planes" },
  caja: { _: "Caja del turno" },
  finanzas: { _: "Finanzas del gimnasio" },
  puntos: { _: "Puntos y fidelización" },
  clases: { _: "Clases y horarios" },
  entrenamientos: { _: "Entrenamientos y rutinas" },
  crm: { _: "CRM · campañas y contactos" },
  dietas: { _: "Dietas y Nutrición" },
};
const titleFor = (section, role) => {
  const t = TITLE[section] || {};
  return t[role] || t._ || "—";
};

function App() {
  const [role, setRole] = React.useState(null); // null → login
  const [authToken, setAuthToken] = React.useState(() => {
    try {
      return localStorage.getItem(AUTH_TOKEN_KEY) || "";
    } catch (e) {
      return "";
    }
  });
  const [tenantId, setTenantId] = React.useState(() => {
    try {
      return localStorage.getItem(TENANT_ID_KEY) || "";
    } catch (e) {
      return "";
    }
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
  const [saasPlans, setSaasPlans] = React.useState([]);
  const [trainerMembers, setTrainerMembers] = React.useState([]);
  const [memberPayments, setMemberPayments] = React.useState([]);
  const [announcements, setAnnouncements] = React.useState([]);
  const [observations, setObservations] = React.useState([]);
  const [activeRoutine, setActiveRoutine] = React.useState(null);
  const [schedules, setSchedules] = React.useState([]);
  const [pointsSummary, setPointsSummary] = React.useState(null);
  const [pointsCatalog, setPointsCatalog] = React.useState(null);
  const [pointsConfig, setPointsConfig] = React.useState(null);
  const [leads, setLeads] = React.useState([]);
  const [campaigns, setCampaigns] = React.useState([]);
  const [financesSummary, setFinancesSummary] = React.useState(null);
  const [expenses, setExpenses] = React.useState([]);
  const [payroll, setPayroll] = React.useState([]);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState("");
  const [section, setSection] = React.useState("dashboard");
  const [themeMode, setThemeMode] = React.useState(() => {
    try {
      return normalizeThemeMode(localStorage.getItem(THEME_MODE_KEY));
    } catch (e) {
      return "system";
    }
  });
  const themeSyncRef = React.useRef({ ready: false, lastSynced: null });

  const authHeaders = React.useMemo(
    () => ({ token: authToken, tenantId }),
    [authToken, tenantId],
  );

  React.useEffect(() => {
    document.documentElement.dataset.theme = themeMode;
    try {
      localStorage.setItem(THEME_MODE_KEY, themeMode);
    } catch (_) {
      // Storage can be unavailable in privacy-restricted browsers.
    }
  }, [themeMode]);

  React.useEffect(() => {
    if (!currentUser?.id) {
      themeSyncRef.current = { ready: false, lastSynced: null };
      return;
    }
    if (!themeSyncRef.current.ready) {
      themeSyncRef.current = {
        ready: true,
        lastSynced: normalizeThemeMode(
          currentUser.themePreference || currentUser.theme_preference,
        ),
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
        const savedMode = normalizeThemeMode(
          result?.themePreference || result?.theme_preference || nextMode,
        );
        themeSyncRef.current.lastSynced = savedMode;
        setCurrentUser((prev) =>
          prev
            ? {
                ...prev,
                themePreference: savedMode,
                theme_preference: savedMode,
              }
            : prev,
        );
        if (savedMode !== themeMode) setThemeMode(savedMode);
      })
      .catch((e) => {
        if (cancelled) return;
        setError(
          (prev) => prev || e.message || "No se pudo sincronizar el tema.",
        );
      });

    return () => {
      cancelled = true;
    };
  }, [
    authHeaders,
    currentUser?.id,
    currentUser?.themePreference,
    currentUser?.theme_preference,
    themeMode,
  ]);

  React.useEffect(() => {
    applyTenantTheme(tenantSettings);
  }, [tenantSettings]);

  const loadTenantSettings = React.useCallback(
    async (override = authHeaders) => {
      const data = await apiRequest("/tenants/me", override);
      const normalized = normalizeTenantSettings(data);
      setTenantSettings(normalized);
      return normalized;
    },
    [authHeaders],
  );

  const loadMembershipPlans = React.useCallback(
    async (includeInactive = role === "admin", override = authHeaders) => {
      const data = await apiRequest(
        `/membership-plans?includeInactive=${includeInactive ? "true" : "false"}`,
        override,
      );
      const plans = data.map(normalizeMembershipPlan);
      setMembershipPlans(plans);
      return plans;
    },
    [authHeaders, role],
  );

  const loadProducts = React.useCallback(
    async (includeInactive = role === "admin", override = authHeaders) => {
      const data = await apiRequest(
        `/products?includeInactive=${includeInactive ? "true" : "false"}`,
        override,
      );
      const rows = data.map(normalizeProduct);
      setProducts(rows);
      return rows;
    },
    [authHeaders, role],
  );

  const loadDashboardSummary = React.useCallback(
    async (override = authHeaders) => {
      const data = await apiRequest("/reports/dashboard", override);
      setDashboardSummary(data);
      return data;
    },
    [authHeaders],
  );

  const loadAdminData = React.useCallback(
    async (override = authHeaders) => {
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
    },
    [authHeaders],
  );

  const loadTenants = React.useCallback(
    async (override = authHeaders) => {
      const data = await apiRequest("/tenants", override);
      setTenants(data);
      return data;
    },
    [authHeaders],
  );

  const loadSaasPlans = React.useCallback(
    async (includeInactive = true, override = authHeaders) => {
      const data = await apiRequest(
        `/saas-plans?includeInactive=${includeInactive ? "true" : "false"}`,
        override,
      );
      const rows = data.map(normalizeSaasPlan);
      setSaasPlans(rows);
      return rows;
    },
    [authHeaders],
  );

  const loadTrainerData = React.useCallback(
    async (override = authHeaders) => {
      const data = await apiRequest("/members/assigned", override);
      setTrainerMembers(data);
      return data;
    },
    [authHeaders],
  );

  const loadMemberData = React.useCallback(
    async (override = authHeaders) => {
      const data = await apiRequest("/payments/me", override);
      setMemberPayments(data);
      return data;
    },
    [authHeaders],
  );

  const loadAnnouncements = React.useCallback(
    async (all = false, override = authHeaders) => {
      const data = await apiRequest(
        all ? "/announcements/all" : "/announcements",
        override,
      );
      setAnnouncements(data);
      return data;
    },
    [authHeaders],
  );

  const loadObservations = React.useCallback(
    async (override = authHeaders) => {
      const data = await apiRequest("/observations", override);
      setObservations(data);
      return data;
    },
    [authHeaders],
  );

  const loadActiveRoutine = React.useCallback(
    async (override = authHeaders) => {
      const data = await apiRequest("/routines/active", override);
      setActiveRoutine(data);
      return data;
    },
    [authHeaders],
  );

  const loadSchedules = React.useCallback(
    async (override = authHeaders) => {
      const data = await apiRequest("/schedules", override);
      setSchedules(data);
      return data;
    },
    [authHeaders],
  );

  const loadDiets = React.useCallback(
    async (memberId = "", override = authHeaders) => {
      const query = memberId ? `?memberId=${memberId}` : "";
      return apiRequest(`/diets${query}`, override);
    },
    [authHeaders],
  );

  const loadExercises = React.useCallback(
    async (override = authHeaders) => {
      return apiRequest("/routines/trainer/exercises", override);
    },
    [authHeaders],
  );

  const loadRoutineTemplates = React.useCallback(
    async (override = authHeaders) => {
      return apiRequest("/routines/trainer/templates", override);
    },
    [authHeaders],
  );

  const loadPointsData = React.useCallback(
    async (override = authHeaders) => {
      const [summary, catalog, config] = await Promise.all([
        apiRequest("/points/summary", override).catch(() => null),
        apiRequest("/points/catalog", override).catch(() => null),
        apiRequest("/points/config", override).catch(() => null),
      ]);
      setPointsSummary(summary);
      setPointsCatalog(catalog);
      setPointsConfig(config);
      return { summary, catalog, config };
    },
    [authHeaders],
  );

  const loadSession = React.useCallback(
    async (override = authHeaders) => {
      setLoading(true);
      setError("");
      try {
        const me = await apiRequest("/auth/me", override);
        const nextRole = roleFromBackend(me.rol);
        const backendTheme = normalizeThemeMode(
          me.themePreference || me.theme_preference,
        );
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
          await loadAnnouncements(nextRole === "admin", override).catch(
            () => [],
          );
          await loadSchedules(override).catch(() => []);
        }
        if (["admin", "cajero", "miembro"].includes(nextRole)) {
          await loadPointsData(override).catch(() => null);
        }
        if (nextRole === "admin") {
          await loadCrmData(override).catch(() => null);
          await loadFinancesData(override).catch(() => null);
          await loadDashboardSummary(override).catch(() => null);
          await loadAdminData(override).catch(() => null);
          await loadObservations(override).catch(() => []);
        }
        if (nextRole === "superadmin") {
          await loadTenants(override).catch(() => []);
          await loadSaasPlans(true, override).catch(() => []);
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
        setSaasPlans([]);
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
        } catch (_) {
          // Storage can be unavailable in privacy-restricted browsers.
        }
      } finally {
        setLoading(false);
      }
    },
    [
      authHeaders,
      loadActiveRoutine,
      loadAdminData,
      loadAnnouncements,
      loadDashboardSummary,
      loadMemberData,
      loadMembershipPlans,
      loadObservations,
      loadPointsData,
      loadProducts,
      loadSaasPlans,
      loadSchedules,
      loadTenantSettings,
      loadTenants,
      loadTrainerData,
    ],
  );

  React.useEffect(() => {
    if (authToken && tenantId && !currentUser) {
      loadSession({ token: authToken, tenantId });
    }
  }, [authToken, currentUser, loadSession, tenantId]);

  const login = async (emailOrDni, password) => {
    setLoading(true);
    setError("");
    try {
      const result = await apiRequest("/auth/login", {
        method: "POST",
        body: {
          emailOrDni,
          password,
          ...(tenantId ? { tenantId } : {}),
        },
      });
      try {
        localStorage.setItem(AUTH_TOKEN_KEY, result.token);
        localStorage.setItem(TENANT_ID_KEY, result.tenantId);
      } catch (_) {
        // Storage can be unavailable in privacy-restricted browsers.
      }
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
    apiRequest("/auth/logout", {
      method: "POST",
      token: authToken,
      tenantId,
      _retry: false,
    }).catch(() => null);
    try {
      localStorage.removeItem(AUTH_TOKEN_KEY);
      localStorage.removeItem(TENANT_ID_KEY);
    } catch (_) {
      // Storage can be unavailable in privacy-restricted browsers.
    }
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
    setSaasPlans([]);
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

  const savePointsProduct = async (product) => {
    const payload = {
      nombre: product.nombre,
      descripcion: product.descripcion || "",
      precio_puntos: Number(product.precio_puntos),
      stock: Number(product.stock) || 0,
      stock_minimo: Number(product.stock_minimo) || 5,
      destacado: product.destacado === true,
    };
    if (product.id) {
      await apiRequest(`/points/catalog/products/${product.id}`, {
        ...authHeaders,
        method: "PATCH",
        body: payload,
      });
    } else {
      await apiRequest("/points/catalog/products", {
        ...authHeaders,
        method: "POST",
        body: payload,
      });
    }
    return loadPointsData();
  };

  const deactivatePointsProduct = async (id) => {
    await apiRequest(`/points/catalog/products/${id}`, {
      ...authHeaders,
      method: "DELETE",
    });
    return loadPointsData();
  };

  const savePointsMembership = async (membership) => {
    const payload = {
      nombre: membership.nombre,
      descripcion: membership.descripcion || "",
      precio_puntos: Number(membership.precio_puntos),
      duracion_dias: Number(membership.duracion_dias),
      stock: Number(membership.stock) || 0,
      destacada: membership.destacada === true,
    };
    if (membership.id) {
      await apiRequest(`/points/catalog/memberships/${membership.id}`, {
        ...authHeaders,
        method: "PATCH",
        body: payload,
      });
    } else {
      await apiRequest("/points/catalog/memberships", {
        ...authHeaders,
        method: "POST",
        body: payload,
      });
    }
    return loadPointsData();
  };

  const deactivatePointsMembership = async (id) => {
    await apiRequest(`/points/catalog/memberships/${id}`, {
      ...authHeaders,
      method: "DELETE",
    });
    return loadPointsData();
  };

  const searchMembers = (q) =>
    apiRequest(`/members/search?q=${encodeURIComponent(q)}`, authHeaders);
  const getActiveCaja = () => apiRequest("/payments/caja/active", authHeaders);
  const openCaja = (payload) =>
    apiRequest("/payments/caja/open", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
  const getCajaDetails = () =>
    apiRequest("/payments/caja/details", authHeaders);
  const getCajaSales = () => apiRequest("/payments/caja/sales", authHeaders);
  const createCajaEgress = (payload) =>
    apiRequest("/payments/caja/egress", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
  const closeCaja = (payload) =>
    apiRequest("/payments/caja/close", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
  const simulateAccess = (dni) =>
    apiRequest("/attendance/simulation-access", {
      ...authHeaders,
      method: "POST",
      body: { dni },
    });
  const chargePOS = (payload) =>
    apiRequest("/payments/pos-charge", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
  const editCajaOpeningAmount = (payload) =>
    apiRequest("/payments/caja/edit-opening-amount", {
      ...authHeaders,
      method: "PATCH",
      body: payload,
    });
  const adminEditCaja = (id, payload) =>
    apiRequest(`/payments/caja/${id}/admin-edit`, {
      ...authHeaders,
      method: "PATCH",
      body: payload,
    });
  const toggleTenant = (id) =>
    apiRequest(`/tenants/${id}/toggle`, {
      ...authHeaders,
      method: "POST",
    }).then(() => loadTenants());
  const saveSaasPlan = async (plan) => {
    const payload = saasPlanToApiPayload(plan);
    if (plan.code) {
      await apiRequest(`/saas-plans/${plan.code}`, {
        ...authHeaders,
        method: "PATCH",
        body: payload,
      });
    } else {
      await apiRequest("/saas-plans", {
        ...authHeaders,
        method: "POST",
        body: payload,
      });
    }
    return loadSaasPlans(true);
  };
  const deactivateSaasPlan = (code) =>
    apiRequest(`/saas-plans/${code}`, {
      ...authHeaders,
      method: "DELETE",
    }).then(() => loadSaasPlans(true));
  const resolvePayment = (id, status, comments = "") =>
    apiRequest(`/payments/${id}/resolve`, {
      ...authHeaders,
      method: "POST",
      body: { status, comments },
    }).then(() => loadAdminData());
  const saveAdminMember = (member) =>
    apiRequest(member.id ? `/admin/members/${member.id}` : "/admin/members", {
      ...authHeaders,
      method: member.id ? "PATCH" : "POST",
      body: member,
    }).then(() => loadAdminData());
  const toggleAdminMember = (id) =>
    apiRequest(`/admin/members/${id}/toggle-active`, {
      ...authHeaders,
      method: "POST",
    }).then(() => loadAdminData());
  const saveAnnouncement = (payload) =>
    apiRequest(payload.id ? `/announcements/${payload.id}` : "/announcements", {
      ...authHeaders,
      method: payload.id ? "PUT" : "POST",
      body: payload,
    }).then(() => loadAnnouncements(true));
  const toggleAnnouncement = (id) =>
    apiRequest(`/announcements/${id}/toggle`, {
      ...authHeaders,
      method: "PATCH",
    }).then(() => loadAnnouncements(true));
  const saveDiet = (payload) => {
    if (payload.id) {
      const { id, ...body } = payload;
      return apiRequest(`/diets/${id}`, {
        ...authHeaders,
        method: "PATCH",
        body,
      });
    }
    return apiRequest("/diets", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
  };
  const deactivateDiet = (id) =>
    apiRequest(`/diets/${id}`, { ...authHeaders, method: "DELETE" });

  const createExercise = (payload) =>
    apiRequest("/routines/trainer/exercises", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
  const createRoutineTemplate = (payload) =>
    apiRequest("/routines/trainer/templates", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
  const assignRoutine = (payload) =>
    apiRequest("/routines/trainer/assign", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
  const saveSchedule = async (payload) => {
    const isNew = !payload.id;
    const url = isNew ? "/schedules" : `/schedules/${payload.id}`;
    const method = isNew ? "POST" : "PATCH";
    const data = await apiRequest(url, {
      ...authHeaders,
      method,
      body: payload,
    });
    await loadSchedules();
    return data;
  };

  const deleteSchedule = async (id) => {
    await apiRequest(`/schedules/${id}`, {
      ...authHeaders,
      method: "DELETE",
    });
    await loadSchedules();
  };

  const loadTrainers = async () => {
    return apiRequest("/schedules/trainers", authHeaders);
  };

  const loadCrmData = React.useCallback(
    async (override = authHeaders) => {
      const [leadsData, campaignsData] = await Promise.all([
        apiRequest("/crm/leads", override).catch(() => []),
        apiRequest("/crm/campaigns", override).catch(() => []),
      ]);
      setLeads(leadsData);
      setCampaigns(campaignsData);
      return { leads: leadsData, campaigns: campaignsData };
    },
    [authHeaders],
  );

  const saveLead = async (payload) => {
    const isNew = !payload.id;
    const url = isNew ? "/crm/leads" : `/crm/leads/${payload.id}`;
    const method = isNew ? "POST" : "PATCH";
    const data = await apiRequest(url, {
      ...authHeaders,
      method,
      body: payload,
    });
    await loadCrmData();
    return data;
  };

  const deleteLead = async (id) => {
    await apiRequest(`/crm/leads/${id}`, {
      ...authHeaders,
      method: "DELETE",
    });
    await loadCrmData();
  };

  const saveCampaign = async (payload) => {
    const data = await apiRequest("/crm/campaigns", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
    await loadCrmData();
    return data;
  };

  const sendCampaign = async (id) => {
    const data = await apiRequest(`/crm/campaigns/${id}/send`, {
      ...authHeaders,
      method: "POST",
    });
    await loadCrmData();
    return data;
  };

  const loadFinancesData = React.useCallback(
    async (override = authHeaders) => {
      const [sum, exp, pay] = await Promise.all([
        apiRequest("/finances/summary", override).catch(() => null),
        apiRequest("/finances/expenses", override).catch(() => []),
        apiRequest("/finances/payroll", override).catch(() => []),
      ]);
      setFinancesSummary(sum);
      setExpenses(exp);
      setPayroll(pay);
      return { summary: sum, expenses: exp, payroll: pay };
    },
    [authHeaders],
  );

  const saveExpense = async (payload) => {
    const data = await apiRequest("/finances/expenses", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
    await loadFinancesData();
    return data;
  };

  const savePayroll = async (payload) => {
    const data = await apiRequest("/finances/payroll", {
      ...authHeaders,
      method: "POST",
      body: payload,
    });
    await loadFinancesData();
    return data;
  };

  const payPayroll = async (id) => {
    const data = await apiRequest(`/finances/payroll/${id}/pay`, {
      ...authHeaders,
      method: "POST",
    });
    await loadFinancesData();
    return data;
  };


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
        <ThemeSwitcher themeMode={themeMode} setThemeMode={setThemeMode} />
        <Login onLogin={login} loading={loading} error={error} />
      </>
    );
  }

  // La sección activa debe pertenecer al nav del rol; si no, cae a dashboard.
  const allowed = ROLES[role].nav.flatMap((g) => g.items.map((it) => it.id));
  const current = allowed.includes(section) ? section : "dashboard";

  let View;
  if (current === "dashboard") View = DASHBOARDS[role];
  else View = SECTIONS[current];

  const go = (s) => setSection(allowed.includes(s) ? s : "dashboard");

  const gym = tenantSettings || GYM;
  const appContext = {
    leads,
    campaigns,
    financesSummary,
    expenses,
    payroll,
    saveSchedule,
    deleteSchedule,
    loadTrainers,
    loadCrmData,
    saveLead,
    deleteLead,
    saveCampaign,
    sendCampaign,
    loadFinancesData,
    saveExpense,
    savePayroll,
    payPayroll,
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
    saasPlans,
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
    reloadSaasPlans: loadSaasPlans,
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
    loadExercises,
    createExercise,
    loadRoutineTemplates,
    createRoutineTemplate,
    assignRoutine,
    savePointsConfig,
    savePointsProduct,
    deactivatePointsProduct,
    savePointsMembership,
    deactivatePointsMembership,
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
    saveSaasPlan,
    deactivateSaasPlan,
    resolvePayment,
    saveAdminMember,
    toggleAdminMember,
    saveAnnouncement,
    toggleAnnouncement,
  };

  return (
    <div className="app">
      <Sidebar
        role={role}
        section={current}
        onNavigate={go}
        tenantSettings={tenantSettings}
      />
      <div className="main">
        <Topbar
          title={titleFor(current, role)}
          sub={
            role === "superadmin"
              ? "Red CodeFit · operacion multi-sede"
              : `${gym.name} · ${ROLES[role].label}`
          }
          role={role}
          currentUser={currentUser}
          onLogout={logout}
          themeMode={themeMode}
          setThemeMode={setThemeMode}
        />
        <main className="content">
          <View go={go} app={appContext} />
        </main>
      </div>
    </div>
  );
}

createRoot(document.getElementById("root")).render(<App />);

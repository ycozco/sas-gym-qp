// data.jsx — datos mock del panel web CrossHero · GymSmart.
// Se carga después de shared.jsx y antes de las pantallas.

const GYM = { name: "FitZone Gym", city: "Miraflores · Lima", graceDays: 1 };
const TODAY = { long: "Miércoles, 21 de Mayo 2026", short: "21 May 2026" };

// ─── Roles y navegación del panel ──────────────────────────────
// Cada rol ve un sidebar distinto. `id` debe coincidir con una
// sección registrada en app.jsx.
const ROLES = {
  superadmin: {
    label: "Super Administrador", who: "Renzo Salinas", initials: "RS",
    desc: "Plataforma SaaS multi-inquilino",
    platform: true,
    nav: [
      { group: "Plataforma", items: [
        { id: "dashboard", label: "Resumen SaaS", icon: "grid" },
        { id: "gimnasios", label: "Gimnasios",    icon: "box", tag: "10" },
        { id: "planes",    label: "Planes SaaS",  icon: "card" },
      ]},
    ],
  },
  admin: {
    label: "Administrador", who: "Sandra Aguilar", initials: "SA",
    desc: "Gestión total del gimnasio",
    nav: [
      { group: "General", items: [
        { id: "dashboard", label: "Dashboard", icon: "grid" },
      ]},
      { group: "Operación", items: [
        { id: "usuarios",   label: "Usuarios",   icon: "users" },
        { id: "asistencia", label: "Asistencia", icon: "scan" },
        { id: "pagos",      label: "Cobros",     icon: "cash", tag: "3" },
        { id: "caja",       label: "Caja",       icon: "drawer" },
      ]},
      { group: "Catálogo", items: [
        { id: "membresias", label: "Membresías", icon: "card" },
        { id: "productos",  label: "Productos",  icon: "box" },
        { id: "puntos",     label: "Puntos",     icon: "star" },
        { id: "clases",     label: "Clases",     icon: "calendar" },
      ]},
      { group: "Servicio", items: [
        { id: "entrenamientos", label: "Entrenamientos", icon: "dumbbell" },
        { id: "dietas",         label: "Planes de Dieta", icon: "clipboard" },
        { id: "crm",            label: "CRM",            icon: "mega" },
        { id: "finanzas",       label: "Finanzas",       icon: "wallet" },
      ]},
      { group: "Análisis", items: [
        { id: "reportes", label: "Reportes",      icon: "chart" },
        { id: "config",   label: "Configuración", icon: "cog" },
      ]},
    ],
  },
  cajero: {
    label: "Caja / Recepción", who: "Mariana Quispe", initials: "MQ",
    desc: "Turno 06:00 – 14:00 · operación limitada",
    nav: [
      { group: "Mi turno", items: [
        { id: "dashboard",  label: "Dashboard",  icon: "grid" },
        { id: "asistencia", label: "Asistencia", icon: "scan" },
        { id: "caja",       label: "Caja",       icon: "drawer" },
        { id: "pagos",      label: "Cobros",     icon: "cash" },
      ]},
      { group: "Catálogo", items: [
        { id: "membresias", label: "Membresías", icon: "card" },
        { id: "productos",  label: "Productos",  icon: "box" },
        { id: "puntos",     label: "Puntos",     icon: "star" },
      ]},
    ],
  },
  coach: {
    label: "Entrenador", who: "Carlos Mendoza", initials: "CM",
    desc: "7 alumnos asignados",
    nav: [
      { group: "Mi trabajo", items: [
        { id: "dashboard",      label: "Dashboard",      icon: "grid" },
        { id: "usuarios",       label: "Mis alumnos",    icon: "users" },
        { id: "entrenamientos", label: "Entrenamientos", icon: "dumbbell" },
        { id: "dietas",         label: "Dietas Alumnos", icon: "clipboard" },
        { id: "clases",         label: "Clases",         icon: "calendar" },
      ]},
    ],
  },
  miembro: {
    label: "Miembro", who: "Diego Ccallo", initials: "DC",
    desc: "Plan Mensual · activo",
    nav: [
      { group: "Mi cuenta", items: [
        { id: "dashboard", label: "Resumen", icon: "grid" },
      ]},
    ],
  },
};

// ─── Dashboard Admin ───────────────────────────────────────────
const ADMIN_KPIS = [
  { id: "activos",  label: "Usuarios activos", value: "142", delta: "+6 este mes", dir: "up",   icon: "users" },
  { id: "hoy",      label: "Ingresos hoy",     value: "84",  delta: "vs 76 ayer",  dir: "up",   icon: "scan" },
  { id: "cobrado",  label: "Cobrado este mes", value: "S/ 21.400", delta: "+12%",  dir: "up",   icon: "cash" },
  { id: "vencidos", label: "Vencidos esta sem.", value: "8", delta: "próx. 7 días", dir: "down", icon: "alert" },
];

const WEEK_ATTENDANCE = [
  { d: "Jue", v: 42 }, { d: "Vie", v: 56 }, { d: "Sáb", v: 48 }, { d: "Dom", v: 38 },
  { d: "Lun", v: 64 }, { d: "Mar", v: 71 }, { d: "Hoy", v: 84, hot: true },
];

const PENDING_PAYMENTS = [
  { n: "Diego Ccallo",   over: "3 días", st: "danger" },
  { n: "Ana Torres",     over: "1 día",  st: "warn" },
  { n: "Luis Medina",    over: "7 días", st: "danger" },
  { n: "Rosa Paredes",   over: "hoy",    st: "warn" },
];

// ─── Usuarios ──────────────────────────────────────────────────
const USERS = [
  { id: "u1", n: "Diego Ccallo",     dni: "72345678", plan: "Mensual",    st: "active",  venc: "21/06/2026", trainer: "Carlos Mendoza", tel: "951 234 567", email: "diego.ccallo@mail.com", asis: 18 },
  { id: "u2", n: "Ana Torres",       dni: "45678901", plan: "Mensual",    st: "expired", venc: "18/05/2026", trainer: "Andrea Soto",    tel: "987 110 220", email: "ana.torres@mail.com",   asis: 9 },
  { id: "u3", n: "Luis Medina",      dni: "89012345", plan: "Trimestral", st: "pending", venc: "—",          trainer: "Sin asignar",    tel: "933 445 661", email: "luis.medina@mail.com",  asis: 0 },
  { id: "u4", n: "María López",      dni: "70998421", plan: "Mensual",    st: "active",  venc: "06/06/2026", trainer: "Lucía Flores",   tel: "962 778 014", email: "maria.lopez@mail.com",  asis: 22 },
  { id: "u5", n: "Jorge Paredes",    dni: "47312908", plan: "Anual",      st: "active",  venc: "12/03/2027", trainer: "Carlos Mendoza", tel: "915 600 233", email: "jorge.paredes@mail.com", asis: 27 },
  { id: "u6", n: "Rosa Paredes",     dni: "70845231", plan: "Mensual",    st: "grace",   venc: "20/05/2026", trainer: "Lucía Flores",   tel: "998 221 547", email: "rosa.paredes@mail.com", asis: 14 },
  { id: "u7", n: "Carmen Huamán",    dni: "44219876", plan: "Trimestral", st: "active",  venc: "01/08/2026", trainer: "Andrea Soto",    tel: "972 330 118", email: "carmen.huaman@mail.com", asis: 31 },
  { id: "u8", n: "José Pérez",       dni: "10234567", plan: "Mensual",    st: "active",  venc: "29/05/2026", trainer: "Carlos Mendoza", tel: "941 870 562", email: "jose.perez@mail.com",   asis: 12 },
];

const USER_PAYMENTS = [
  { d: "21/05/2026", m: "S/ 80", k: "Efectivo", ok: true },
  { d: "21/04/2026", m: "S/ 80", k: "Yape",     ok: true },
  { d: "21/03/2026", m: "S/ 80", k: "Pasarela", ok: true },
  { d: "21/02/2026", m: "S/ 80", k: "Efectivo", ok: true },
];

// ─── Pagos / cobros ────────────────────────────────────────────
const PENDING_ACCRED = [
  { id: "ac1", n: "Ana Torres",   m: "S/ 80",  k: "Yape", t: "20/05 08:30" },
  { id: "ac2", n: "Rosa Paredes", m: "S/ 80",  k: "Plin", t: "19/05 19:15" },
  { id: "ac3", n: "Luis Medina",  m: "S/ 220", k: "Yape", t: "19/05 12:02" },
];

const PAYMENTS_TODAY = [
  { t: "11:30", n: "María López",   m: 80,   k: "Yape",     by: "Mariana Q." },
  { t: "10:22", n: "Jorge Paredes", m: 1080, k: "Tarjeta",  by: "Mariana Q." },
  { t: "09:48", n: "Sin usuario",   m: 45,   k: "Efectivo", by: "Mariana Q." },
  { t: "09:01", n: "Carmen Huamán", m: 320,  k: "Efectivo", by: "Mariana Q." },
  { t: "08:42", n: "José Pérez",    m: 80,   k: "Yape",     by: "Mariana Q." },
];

// ─── Asistencia ────────────────────────────────────────────────
const ATTENDANCE_LOG = [
  { t: "09:15", n: "Carmen Huamán", via: "QR app",  ok: true },
  { t: "09:01", n: "José Pérez",    via: "QR app",  ok: true },
  { t: "08:50", n: "Ana Torres",    via: "DNI",     ok: false },
  { t: "08:45", n: "María López",   via: "Huella",  ok: true },
  { t: "08:42", n: "Diego Ccallo",  via: "QR app",  ok: true },
  { t: "08:20", n: "Jorge Paredes", via: "DNI",     ok: true },
  { t: "07:58", n: "Rosa Paredes",  via: "QR app",  ok: true },
  { t: "07:14", n: "Luis Medina",   via: "Huella",  ok: false },
];

// ─── Productos ─────────────────────────────────────────────────
const PRODUCTS = [
  { id: "p1", n: "Botella de agua 600ml",   cat: "Bebidas",     p: 3,  stock: 124, k: "💧" },
  { id: "p2", n: "Proteína whey · porción", cat: "Suplementos", p: 12, stock: 38,  k: "💪" },
  { id: "p3", n: "Pre-entreno · scoop",     cat: "Suplementos", p: 8,  stock: 22,  k: "⚡" },
  { id: "p4", n: "Barra energética",        cat: "Snacks",      p: 5,  stock: 56,  k: "🍫" },
  { id: "p5", n: "Polo oficial",            cat: "Merch",       p: 45, stock: 18,  k: "👕" },
  { id: "p6", n: "Toalla deportiva",        cat: "Accesorios",  p: 5,  stock: 12,  k: "🏃" },
  { id: "p7", n: "Creatina · porción",      cat: "Suplementos", p: 6,  stock: 41,  k: "💊" },
  { id: "p8", n: "Shaker 600ml",            cat: "Merch",       p: 18, stock: 9,   k: "🥤" },
];

// ─── Reportes ──────────────────────────────────────────────────
const REVENUE_6M = [
  { m: "DIC", v: 14 }, { m: "ENE", v: 17 }, { m: "FEB", v: 16 },
  { m: "MAR", v: 19 }, { m: "ABR", v: 21 }, { m: "MAY", v: 21, hot: true },
];
const PAY_METHODS = [
  { l: "Efectivo", pct: 45, c: "var(--ink)" },
  { l: "Yape / Plin", pct: 40, c: "var(--accent)" },
  { l: "Pasarela", pct: 15, c: "var(--info)" },
];
const REPORT_LIST = [
  { n: "Asistencias",   d: "Ingresos por día, franja y método", icon: "scan" },
  { n: "Membresías",    d: "Altas, renovaciones y vencimientos", icon: "card" },
  { n: "Flujo de caja", d: "Ingresos vs egresos del periodo",    icon: "wallet" },
  { n: "Productos",     d: "Ventas por categoría y producto",    icon: "box" },
  { n: "Stock",         d: "Inventario y reposición",            icon: "alert" },
  { n: "Puntos",        d: "Emisión y canjes de fidelización",   icon: "star" },
];

// ─── Datos por rol no-admin ────────────────────────────────────
const CASHIER_SHIFT = { start: "06:00", end: "14:00", left: "3h 42m", saldo: "S/ 1.585" };
const COACH_MEMBERS = [
  { n: "Diego Ccallo",  obj: "Hipertrofia",   last: "Ayer",     st: "ok" },
  { n: "María López",   obj: "Tonificación",  last: "Hace 3d",  st: "warn" },
  { n: "Jorge Paredes", obj: "Fuerza máxima", last: "Hoy",      st: "ok" },
  { n: "José Pérez",    obj: "Resistencia",   last: "Sin rutina", st: "danger" },
];

// ═══════════════════════════════════════════════════════════════
// MÓDULOS AMPLIADOS (paridad con crosshero-gym)
// ═══════════════════════════════════════════════════════════════

// ─── Membresías ────────────────────────────────────────────────
const MEMBERSHIP_PLANS = [
  { id: "pl1", n: "Mensual",     dur: "30 días",  price: 80,  activos: 96, on: true },
  { id: "pl2", n: "Trimestral",  dur: "90 días",  price: 210, activos: 32, on: true },
  { id: "pl3", n: "Anual",       dur: "365 días", price: 720, activos: 14, on: true },
  { id: "pl4", n: "Día casual",  dur: "1 día",    price: 15,  activos: "—", on: true },
  { id: "pl5", n: "Estudiante",  dur: "30 días",  price: 60,  activos: 18, on: false },
];
const MEMB_KPIS = [
  { id: "act",  label: "Membresías activas", value: "142", delta: "+6", dir: "up",   icon: "card" },
  { id: "ven",  label: "Ventas este mes",    value: "S/ 18.600", delta: "+9%", dir: "up", icon: "cash" },
  { id: "cong", label: "Congeladas",         value: "5",   delta: "reanudan en jun", dir: "flat", icon: "alert" },
];

// ─── Caja ──────────────────────────────────────────────────────
const CAJA_STATE = { abierta: true, desde: "06:02", cajero: "Mariana Quispe", inicial: 100 };
const CAJA_MOV = [
  { t: "11:30", tipo: "ingreso", concepto: "Cobro membresía · María López",  m: 80 },
  { t: "10:22", tipo: "ingreso", concepto: "Cobro membresía · Jorge Paredes", m: 1080 },
  { t: "10:05", tipo: "egreso",  concepto: "Compra de agua para dispensador",  m: 24 },
  { t: "09:48", tipo: "ingreso", concepto: "Venta producto · Polo oficial",    m: 45 },
  { t: "09:01", tipo: "ingreso", concepto: "Cobro membresía · Carmen Huamán",  m: 320 },
  { t: "08:30", tipo: "egreso",  concepto: "Vuelto de caja chica",             m: 15 },
];

// ─── Finanzas (módulo pagos admin) ─────────────────────────────
const FIN_KPIS = [
  { id: "ing", label: "Ingresos del mes", value: "S/ 24.180", delta: "+11%", dir: "up",   icon: "trend" },
  { id: "egr", label: "Egresos del mes",  value: "S/ 9.420",  delta: "+4%",  dir: "down", icon: "wallet" },
  { id: "bal", label: "Balance del mes",  value: "S/ 14.760", delta: "margen 61%", dir: "up", icon: "cash" },
];
const FIN_MOV = [
  { d: "20/05", tipo: "Sueldo",   concepto: "Sueldo · Carlos Mendoza (entrenador)", m: 2200, dir: "egreso" },
  { d: "18/05", tipo: "Servicio", concepto: "Luz · recibo mayo",                    m: 640,  dir: "egreso" },
  { d: "18/05", tipo: "Servicio", concepto: "Agua · recibo mayo",                   m: 180,  dir: "egreso" },
  { d: "15/05", tipo: "Gasto",    concepto: "Mantenimiento de máquinas (especial)", m: 850,  dir: "egreso" },
  { d: "12/05", tipo: "Ingreso",  concepto: "Alquiler de sala a evento (especial)", m: 1200, dir: "ingreso" },
  { d: "10/05", tipo: "Servicio", concepto: "Internet · recibo mayo",               m: 150,  dir: "egreso" },
];

// ─── Puntos (fidelización) ─────────────────────────────────────
const PTS_KPIS = [
  { id: "emi", label: "Puntos emitidos (mes)", value: "12.480", delta: "+8%", dir: "up", icon: "star" },
  { id: "can", label: "Canjes del mes",        value: "37",     delta: "+5",  dir: "up", icon: "check" },
  { id: "usr", label: "Usuarios con puntos",   value: "118",    delta: "",    dir: "flat", icon: "users" },
];
const PTS_CATALOG = [
  { n: "Botella de agua",     tipo: "Producto",  costo: 150 },
  { n: "Proteína · porción",  tipo: "Producto",  costo: 600 },
  { n: "Día casual gratis",   tipo: "Membresía", costo: 900 },
  { n: "Toalla deportiva",    tipo: "Producto",  costo: 400 },
  { n: "10% dto. renovación", tipo: "Membresía", costo: 1200 },
];
const PTS_CANJES = [
  { t: "Hoy 10:40", n: "Carmen Huamán", item: "Botella de agua",   pts: 150 },
  { t: "Ayer",      n: "Jorge Paredes", item: "Día casual gratis", pts: 900 },
  { t: "19/05",     n: "María López",   item: "Toalla deportiva",  pts: 400 },
];

// ─── Clases ────────────────────────────────────────────────────
const CLASSES = [
  { n: "CrossFit matutino", coach: "Carlos Mendoza", dias: "L · X · V", hora: "06:00", cupo: "12/15", st: "ok" },
  { n: "Funcional",         coach: "Lucía Flores",   dias: "L · X · V", hora: "18:00", cupo: "20/20", st: "full" },
  { n: "Yoga",              coach: "Andrea Soto",    dias: "Ma · J",    hora: "10:00", cupo: "4/10",  st: "ok" },
  { n: "Box",               coach: "Carlos Mendoza", dias: "Ma · J",    hora: "18:00", cupo: "9/15",  st: "ok" },
  { n: "Spinning",          coach: "Andrea Soto",    dias: "L · M · V", hora: "19:00", cupo: "11/12", st: "warn" },
];

// ─── Entrenamientos ────────────────────────────────────────────
const TRAIN_KPIS = [
  { id: "rut", label: "Rutinas activas",    value: "14", delta: "+2", dir: "up", icon: "dumbbell" },
  { id: "ej",  label: "Ejercicios biblioteca", value: "86", delta: "", dir: "flat", icon: "box" },
  { id: "asg", label: "Alumnos con rutina", value: "38/42", delta: "4 sin asignar", dir: "down", icon: "users" },
];
const ROUTINES = [
  { n: "Push · Pecho + Hombros",   div: "Push/Pull/Legs", ej: 6, asg: 12 },
  { n: "Pull · Espalda + Bíceps",  div: "Push/Pull/Legs", ej: 7, asg: 11 },
  { n: "Leg · Pierna + Glúteo",    div: "Push/Pull/Legs", ej: 6, asg: 9 },
  { n: "Full body intermedio",     div: "Full body",      ej: 8, asg: 4 },
  { n: "Hipertrofia avanzada",     div: "Weider",         ej: 9, asg: 2 },
];
const MUSCLE_GROUPS = ["Pecho", "Espalda", "Hombro", "Pierna", "Glúteo", "Bíceps", "Tríceps", "Core"];

// ─── CRM ───────────────────────────────────────────────────────
const CRM_KPIS = [
  { id: "con", label: "Contactos / leads",      value: "64", delta: "+9 este mes", dir: "up", icon: "users" },
  { id: "cam", label: "Campañas activas",       value: "3",  delta: "", dir: "flat", icon: "mega" },
  { id: "seg", label: "Seguimientos pendientes", value: "11", delta: "5 vencen hoy", dir: "down", icon: "alert" },
];
const CAMPAIGNS = [
  { n: "Promo Junio · trae un amigo", canal: "WhatsApp", estado: "Activa",      alcance: 142 },
  { n: "Recuperación de vencidos",     canal: "Email",    estado: "Activa",      alcance: 18 },
  { n: "Aviso clase nueva de Box",     canal: "Push",     estado: "Programada",  alcance: 142 },
  { n: "Encuesta de satisfacción",     canal: "Email",    estado: "Finalizada",  alcance: 96 },
];
const CRM_CONTACTS = [
  { n: "Pedro Salas",    origen: "Formulario web", estado: "Nuevo" },
  { n: "Lucía Romero",   origen: "Referido",       estado: "En seguimiento" },
  { n: "Marco Díaz",     origen: "Visita al gym",  estado: "En seguimiento" },
  { n: "Elena Vargas",   origen: "Instagram",      estado: "Nuevo" },
];

// ─── Super Admin (plataforma SaaS) ─────────────────────────────
const SAAS_KPIS = [
  { id: "gym", label: "Gimnasios activos",      value: "10",  delta: "+2 este mes", dir: "up",   icon: "box" },
  { id: "usr", label: "Usuarios en la red",     value: "1.840", delta: "+9%",       dir: "up",   icon: "users" },
  { id: "mrr", label: "Ingreso recurrente/mes", value: "S/ 9.600", delta: "+S/ 1.200", dir: "up", icon: "cash" },
  { id: "sus", label: "Instancias suspendidas", value: "2",   delta: "por impago",  dir: "down", icon: "alert" },
];
// Clientes = gimnasios (instancias multi-tenant).
const GYMS = [
  { id: "g1", n: "FitZone Gym",      city: "Miraflores",  plan: "Pro",        usuarios: 142, st: "active",    alta: "03/2025" },
  { id: "g2", n: "PowerHouse",       city: "San Isidro",  plan: "Pro",        usuarios: 310, st: "active",    alta: "07/2024" },
  { id: "g3", n: "IronWolf Gym",     city: "Surco",       plan: "Básico",     usuarios: 88,  st: "active",    alta: "11/2025" },
  { id: "g4", n: "Olympus Fit",      city: "Barranco",    plan: "Pro",        usuarios: 204, st: "active",    alta: "01/2025" },
  { id: "g5", n: "FlexZone",         city: "La Molina",   plan: "Básico",     usuarios: 61,  st: "suspended", alta: "09/2025" },
  { id: "g6", n: "CrossHero Centro", city: "Lima Centro", plan: "Enterprise", usuarios: 520, st: "active",    alta: "02/2024" },
  { id: "g7", n: "BodyLab",          city: "Magdalena",   plan: "Básico",     usuarios: 73,  st: "suspended", alta: "04/2026" },
  { id: "g8", n: "Titan Gym",        city: "Pueblo Libre", plan: "Pro",       usuarios: 172, st: "active",    alta: "06/2025" },
  { id: "g9", n: "VitalGym",         city: "Jesús María", plan: "Pro",        usuarios: 119, st: "active",    alta: "10/2025" },
  { id: "g10", n: "Arena Fitness",   city: "San Borja",   plan: "Básico",     usuarios: 51,  st: "active",    alta: "03/2026" },
];
const SAAS_PLANS = [
  { n: "Básico",     price: "S/ 199", limite: "Hasta 100 usuarios", gimnasios: 4, feats: "Acceso, pagos y rutinas" },
  { n: "Pro",        price: "S/ 399", limite: "Hasta 350 usuarios", gimnasios: 5, feats: "+ CRM, puntos y reportes" },
  { n: "Enterprise", price: "S/ 899", limite: "Usuarios ilimitados", gimnasios: 1, feats: "+ multi-sede, API y soporte" },
];

export { GYM, TODAY, ROLES, ADMIN_KPIS, WEEK_ATTENDANCE, PENDING_PAYMENTS, USERS, USER_PAYMENTS, PENDING_ACCRED, PAYMENTS_TODAY, ATTENDANCE_LOG, PRODUCTS, REVENUE_6M, PAY_METHODS, REPORT_LIST, CASHIER_SHIFT, COACH_MEMBERS, MEMBERSHIP_PLANS, MEMB_KPIS, CAJA_STATE, CAJA_MOV, FIN_KPIS, FIN_MOV, PTS_KPIS, PTS_CATALOG, PTS_CANJES, CLASSES, TRAIN_KPIS, ROUTINES, MUSCLE_GROUPS, CRM_KPIS, CAMPAIGNS, CRM_CONTACTS, SAAS_KPIS, GYMS, SAAS_PLANS };

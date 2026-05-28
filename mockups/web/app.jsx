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
  const [section, setSection] = React.useState("dashboard");

  if (!role) {
    return <Login onLogin={(r) => { setRole(r); setSection("dashboard"); }}/>;
  }

  // La sección activa debe pertenecer al nav del rol; si no, cae a dashboard.
  const allowed = ROLES[role].nav.flatMap(g => g.items.map(it => it.id));
  const current = allowed.includes(section) ? section : "dashboard";

  let View;
  if (current === "dashboard") View = DASHBOARDS[role];
  else View = SECTIONS[current];

  const go = (s) => setSection(allowed.includes(s) ? s : "dashboard");

  return (
    <div className="app">
      <Sidebar role={role} section={current} onNavigate={go}/>
      <div className="main">
        <Topbar
          title={titleFor(current, role)}
          sub={role === "superadmin" ? "Plataforma GymSmart · SaaS multi-tenant" : `${GYM.name} · ${ROLES[role].label}`}
          role={role}
          onLogout={() => { setRole(null); setSection("dashboard"); }}
        />
        <main className="content">
          <View go={go}/>
        </main>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);

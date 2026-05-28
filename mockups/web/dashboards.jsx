// dashboards.jsx — Login + dashboards de los 4 roles.

// ═══════════════════════════════════════════════════════════════
// LOGIN  ·  CU-01 (Inicio de sesión)
// ═══════════════════════════════════════════════════════════════
function Login({ onLogin }) {
  const [role, setRole] = React.useState("admin");
  const roleList = [
    { id: "superadmin", n: "Super Admin", s: "Plataforma SaaS" },
    { id: "admin",   n: "Administrador", s: "Gestión total" },
    { id: "cajero",  n: "Caja",          s: "Recepción / cobros" },
    { id: "coach",   n: "Entrenador",    s: "Alumnos y rutinas" },
    { id: "miembro", n: "Miembro",       s: "Mi cuenta" },
  ];
  const submit = (e) => { e.preventDefault(); onLogin(role); };
  return (
    <div className="login">
      <aside className="login-aside">
        <div className="glow" aria-hidden="true"/>
        <div className="brand">
          <span className="dot" aria-hidden="true"/>
          <span className="wm" style={{ color: "#fff" }}>Gym<em>Smart</em></span>
        </div>
        <h2 className="l-title">Panel de administración del gimnasio.</h2>
        <p className="l-sub">
          Control de acceso, pagos, membresías, inventario y reportes — todo
          desde el navegador. Una instancia aislada por gimnasio.
        </p>
        <div className="l-foot">CrossHero · GymSmart — Prototipo hi-fi del panel web</div>
      </aside>

      <main className="login-form">
        <form className="lf-wrap" onSubmit={submit}>
          <h2>Iniciar sesión</h2>
          <p className="lf-sub">Selecciona tu rol e ingresa tus credenciales.</p>

          <div className="role-pick" role="group" aria-label="Rol">
            {roleList.map(r => (
              <button type="button" key={r.id} aria-pressed={role === r.id} onClick={() => setRole(r.id)}>
                <div className="rp-n">{r.n}</div>
                <div className="rp-s">{r.s}</div>
              </button>
            ))}
          </div>

          <div className="field">
            <label htmlFor="lg-email">Correo electrónico</label>
            <input id="lg-email" type="email" defaultValue="sandra@fitzone.pe" autoComplete="username"/>
          </div>
          <div className="field">
            <label htmlFor="lg-pass">Contraseña</label>
            <input id="lg-pass" type="password" defaultValue="demo1234" autoComplete="current-password"/>
          </div>

          <div className="checkrow">
            <label><input type="checkbox" defaultChecked/> Recordarme</label>
            <a className="link">¿Olvidaste tu contraseña?</a>
          </div>

          <Btn kind="primary" size="lg" block type="submit">Iniciar sesión</Btn>
        </form>
      </main>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD · ADMIN  (WEB-01)
// ═══════════════════════════════════════════════════════════════
function AdminDashboard({ go }) {
  return (
    <div className="content-wrap">
      <div className="grid cols-4">
        {ADMIN_KPIS.map(k => <Kpi key={k.id} {...k} />)}
      </div>

      <div className="grid k-2-1" style={{ marginTop: 16 }}>
        <Panel title="Asistencia semanal" sub="ingresos por día">
          <div style={{ padding: "8px 4px 0" }}>
            <Bars data={WEEK_ATTENDANCE}/>
          </div>
        </Panel>

        <Panel title="Pagos pendientes" sub={`${PENDING_PAYMENTS.length} usuarios`}
               action={<Btn kind="ghost" size="sm" onClick={() => go("pagos")}>Ver pagos</Btn>}
               bodyPad={false}>
          {PENDING_PAYMENTS.map((p, i) => (
            <div className="lrow" key={i}>
              <span className="l-ic" style={{ color: p.st === "danger" ? "var(--danger)" : "var(--warn)" }}>{I.alert}</span>
              <div className="l-main">
                <div className="l-t">{p.n}</div>
                <div className="l-s">Vencida hace {p.over}</div>
              </div>
              <Btn kind="ghost" size="sm" onClick={() => go("pagos")}>Cobrar</Btn>
            </div>
          ))}
        </Panel>
      </div>

      <Panel title="Últimos ingresos del día" sub="control de acceso"
             action={<Btn kind="ghost" size="sm" onClick={() => go("asistencia")}>Ver asistencia</Btn>}
             bodyPad={false} className="" >
        <table className="tbl">
          <thead><tr><th>Hora</th><th>Usuario</th><th>Vía</th><th>Resultado</th></tr></thead>
          <tbody>
            {ATTENDANCE_LOG.slice(0, 6).map((a, i) => (
              <tr key={i}>
                <td className="num" style={{ font: "600 13px var(--font-mono)" }}>{a.t}</td>
                <td className="cell-main">{a.n}</td>
                <td style={{ color: "var(--ink-2)" }}>{a.via}</td>
                <td>{a.ok ? <Badge kind="ok" dot>Acceso concedido</Badge> : <Badge kind="danger" dot>Denegado</Badge>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD · CAJERO
// ═══════════════════════════════════════════════════════════════
function CajeroDashboard({ go }) {
  return (
    <div className="content-wrap">
      <div className="grid cols-2">
        <div className="panel pad" style={{ background: "var(--ink)", color: "#fff", borderColor: "transparent" }}>
          <div style={{ font: "600 11px var(--font-mono)", letterSpacing: ".08em", color: "var(--accent)", textTransform: "uppercase" }}>● Turno activo</div>
          <div style={{ font: "800 34px var(--font-display)", letterSpacing: "-0.04em", marginTop: 10 }}>{CASHIER_SHIFT.saldo}</div>
          <div style={{ font: "500 12.5px var(--font-body)", color: "rgba(255,255,255,.6)", marginTop: 2 }}>
            Saldo de mi turno · {CASHIER_SHIFT.start}–{CASHIER_SHIFT.end} · restan {CASHIER_SHIFT.left}
          </div>
        </div>
        <div className="grid cols-2">
          <Kpi icon="scan" value="28" label="Asistencias hoy" delta="desde 06:00" dir="flat"/>
          <Kpi icon="box" value="11" label="Ventas de productos" delta="S/ 245" dir="up"/>
        </div>
      </div>

      <div className="section-title">Acciones rápidas</div>
      <div className="grid cols-4">
        {[
          { ic: "scan", l: "Registrar asistencia", g: "asistencia" },
          { ic: "cash", l: "Registrar cobro", g: "pagos" },
          { ic: "users", l: "Buscar usuario", g: "asistencia" },
          { ic: "box", l: "Vender producto", g: "productos" },
        ].map(a => (
          <button key={a.l} className="panel pad" onClick={() => go(a.g)}
                  style={{ cursor: "pointer", textAlign: "left", display: "flex", flexDirection: "column", gap: 10 }}>
            <span className="k-ic">{icon(a.ic)}</span>
            <span style={{ font: "600 13.5px var(--font-body)" }}>{a.l}</span>
          </button>
        ))}
      </div>

      <Panel title="Mis últimos cobros" sub="visible para el Administrador" bodyPad={false} className="" >
        <table className="tbl">
          <thead><tr><th>Hora</th><th>Usuario</th><th>Método</th><th className="num">Monto</th></tr></thead>
          <tbody>
            {PAYMENTS_TODAY.map((p, i) => (
              <tr key={i}>
                <td style={{ font: "600 13px var(--font-mono)" }}>{p.t}</td>
                <td className="cell-main">{p.n}</td>
                <td><Badge>{p.k}</Badge></td>
                <td className="num" style={{ font: "700 14px var(--font-display)" }}>S/ {p.m}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD · ENTRENADOR (Coach)
// ═══════════════════════════════════════════════════════════════
function CoachDashboard({ go }) {
  return (
    <div className="content-wrap">
      <div className="grid cols-4">
        <Kpi icon="users" value="7" label="Alumnos asignados" delta="" dir="flat"/>
        <Kpi icon="trend" value="23" label="Sesiones esta semana" delta="+18%" dir="up"/>
        <Kpi icon="check" value="5" label="Activos hoy" delta="+2" dir="up"/>
        <Kpi icon="alert" value="1" label="Sin rutina asignada" delta="requiere acción" dir="down"/>
      </div>

      <Panel title="Mis alumnos" sub="vista técnica de asignados"
             action={<Btn kind="ghost" size="sm" onClick={() => go("usuarios")}>Ver todos</Btn>}
             bodyPad={false} className="" >
        <table className="tbl">
          <thead><tr><th>Alumno</th><th>Objetivo</th><th>Última sesión</th><th>Estado</th></tr></thead>
          <tbody>
            {COACH_MEMBERS.map((m, i) => (
              <tr key={i} className="clickable" onClick={() => go("usuarios")}>
                <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <Avatar name={m.n} size={32}/><span className="cell-main">{m.n}</span>
                </div></td>
                <td style={{ color: "var(--ink-2)" }}>{m.obj}</td>
                <td style={{ color: "var(--ink-2)" }}>{m.last}</td>
                <td>{m.st === "ok" ? <Badge kind="ok" dot>Al día</Badge>
                    : m.st === "warn" ? <Badge kind="warn" dot>Seguir</Badge>
                    : <Badge kind="danger" dot>Sin rutina</Badge>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD · MIEMBRO
// ═══════════════════════════════════════════════════════════════
function MiembroDashboard() {
  return (
    <div className="content-wrap">
      <div className="grid k-2-1">
        <div className="panel pad" style={{ background: "var(--ink)", color: "#fff", borderColor: "transparent" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
            <span style={{ font: "600 11px var(--font-mono)", letterSpacing: ".08em", color: "var(--accent)", textTransform: "uppercase" }}>Plan Mensual</span>
            <Badge kind="accent">Activa</Badge>
          </div>
          <div style={{ font: "800 34px var(--font-display)", letterSpacing: "-0.04em", marginTop: 14 }}>
            21 <span style={{ font: "500 15px var(--font-body)", color: "rgba(255,255,255,.6)" }}>días restantes</span>
          </div>
          <div className="bar-track" style={{ marginTop: 14, background: "rgba(255,255,255,.12)" }}>
            <i style={{ width: "70%", background: "var(--accent)" }}/>
          </div>
          <div style={{ font: "500 12px var(--font-mono)", color: "rgba(255,255,255,.5)", marginTop: 8 }}>Vence 21 jun 2026</div>
        </div>
        <Panel title="Acceso rápido" bodyPad={false}>
          {[
            { ic: "scan", t: "Mi código QR", s: "Para ingresar al gym" },
            { ic: "cash", t: "Pagar membresía", s: "Yape · Plin · pasarela" },
            { ic: "chart", t: "Mi agenda", s: "Rutina de la semana" },
          ].map((a, i) => (
            <div className="lrow" key={i}>
              <span className="l-ic">{icon(a.ic)}</span>
              <div className="l-main"><div className="l-t">{a.t}</div><div className="l-s">{a.s}</div></div>
              <span style={{ color: "var(--ink-3)" }}>{I.forward}</span>
            </div>
          ))}
        </Panel>
      </div>

      <Panel title="Historial de pagos" bodyPad={false} className="" >
        <table className="tbl">
          <thead><tr><th>Fecha</th><th className="num">Monto</th><th>Método</th><th>Estado</th></tr></thead>
          <tbody>
            {USER_PAYMENTS.map((p, i) => (
              <tr key={i}>
                <td style={{ font: "600 13px var(--font-mono)" }}>{p.d}</td>
                <td className="num" style={{ font: "700 14px var(--font-display)" }}>{p.m}</td>
                <td><Badge>{p.k}</Badge></td>
                <td><Badge kind="ok" dot>Acreditado</Badge></td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD · SUPER ADMINISTRADOR (plataforma SaaS)
// ═══════════════════════════════════════════════════════════════
function SuperDashboard({ go }) {
  const active = GYMS.filter(g => g.st === "active").length;
  const suspended = GYMS.length - active;
  return (
    <div className="content-wrap">
      <div className="grid cols-4">
        {SAAS_KPIS.map(k => <Kpi key={k.id} {...k}/>)}
      </div>

      <div className="grid k-2-1" style={{ marginTop: 16 }}>
        <Panel title="Gimnasios de la red" sub="instancias multi-tenant"
               action={<Btn kind="ghost" size="sm" onClick={() => go("gimnasios")}>Ver todos</Btn>}
               bodyPad={false}>
          <table className="tbl">
            <thead><tr><th>Gimnasio</th><th>Plan</th><th className="num">Usuarios</th><th>Estado</th></tr></thead>
            <tbody>
              {GYMS.slice(0, 6).map(g => (
                <tr key={g.id} className="clickable" onClick={() => go("gimnasios")}>
                  <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                    <span style={{ width: 32, height: 32, borderRadius: 9, background: "var(--ink)", color: "var(--accent)", display: "grid", placeItems: "center", font: "800 13px var(--font-display)" }}>{g.n[0]}</span>
                    <div><div className="cell-main">{g.n}</div><div className="cell-sub">{g.city}</div></div>
                  </div></td>
                  <td><Badge>{g.plan}</Badge></td>
                  <td className="num">{g.usuarios}</td>
                  <td>{g.st === "active" ? <Badge kind="ok" dot>Activo</Badge> : <Badge kind="danger" dot>Suspendido</Badge>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Panel>

        <Panel title="Estado de la red">
          <div style={{ display: "flex", gap: 14 }}>
            <div style={{ flex: 1, textAlign: "center", padding: "14px 8px", background: "color-mix(in oklab, var(--success) 9%, white)", borderRadius: 14 }}>
              <div style={{ font: "800 30px var(--font-display)", letterSpacing: "-0.04em", color: "#00753b" }}>{active}</div>
              <div style={{ font: "500 11.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>Activos</div>
            </div>
            <div style={{ flex: 1, textAlign: "center", padding: "14px 8px", background: "color-mix(in oklab, var(--danger) 8%, white)", borderRadius: 14 }}>
              <div style={{ font: "800 30px var(--font-display)", letterSpacing: "-0.04em", color: "var(--danger)" }}>{suspended}</div>
              <div style={{ font: "500 11.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>Suspendidos</div>
            </div>
          </div>
          <div className="divider"/>
          <div style={{ font: "600 13px var(--font-body)", marginBottom: 8 }}>Ocupación de la plataforma</div>
          <div className="bar-track tall" style={{ height: 12 }}>
            <i style={{ width: `${Math.round((active / GYMS.length) * 100)}%`, background: "var(--accent)" }}/>
          </div>
          <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-3)", marginTop: 8 }}>
            {active} de {GYMS.length} instancias operativas
          </div>
        </Panel>
      </div>
    </div>
  );
}

Object.assign(window, { Login, AdminDashboard, CajeroDashboard, CoachDashboard, MiembroDashboard, SuperDashboard });

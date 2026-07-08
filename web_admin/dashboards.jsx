import React from 'react';
import { ADMIN_KPIS, COACH_MEMBERS, GYMS, PENDING_PAYMENTS, USER_PAYMENTS, WEEK_ATTENDANCE } from './data.jsx';
import { Avatar, Badge, Bars, Btn, ErrorBlock, I, Kpi, Panel, icon } from './shared.jsx';

// dashboards.jsx - Login + dashboards por rol conectados al backend.

function Login({ onLogin, loading, error }) {
  const [emailOrDni, setEmailOrDni] = React.useState("");
  const [password, setPassword] = React.useState("");
  const submit = (e) => {
    e.preventDefault();
    onLogin(emailOrDni.trim(), password);
  };
  return (
    <div className="login">
      <aside className="login-aside">
        <div className="glow" aria-hidden="true"/>
        <div className="brand">
          <span className="dot" aria-hidden="true"/>
          <span className="wm">Saas<em>Gym</em></span>
        </div>
        <h2 className="l-title">Club Ops del gym.</h2>
        <p className="l-sub">Caja, ventas, socios, clases, inventario y reportes sincronizados con la API real.</p>
        <div className="l-foot">SaasGym Club Ops</div>
      </aside>

      <main className="login-form">
        <form className="lf-wrap" onSubmit={submit}>
          <h2>Iniciar sesion</h2>
          <p className="lf-sub">Ingresa con tus credenciales operativas. El rol y la sede se resuelven desde la API.</p>
          <div className="field"><label htmlFor="lg-email">Correo, DNI o usuario</label><input id="lg-email" value={emailOrDni} onChange={e => setEmailOrDni(e.target.value)} autoComplete="username" placeholder="tuusuario@empresa.com"/></div>
          <div className="field"><label htmlFor="lg-pass">Contrasena</label><input id="lg-pass" type="password" value={password} onChange={e => setPassword(e.target.value)} autoComplete="current-password"/></div>
          <ErrorBlock message={error}/>
          <div className="checkrow"><label><input type="checkbox" defaultChecked/> Recordarme</label><a className="link">Recuperar acceso</a></div>
          <Btn kind="primary" size="lg" block type="submit" disabled={loading}>{loading ? "Validando..." : "Iniciar sesion"}</Btn>
        </form>
      </main>
    </div>
  );
}

function AdminDashboard({ go, app }) {
  const s = app?.dashboardSummary;
  const pending = app?.pendingPayments || [];
  const kpis = s ? [
    { id: "active", icon: "users", value: String(s.activeMembers ?? 0), label: "Usuarios activos", delta: "tenant actual", dir: "up" },
    { id: "sales", icon: "box", value: String(s.productSalesToday ?? 0), label: "Ventas productos", delta: `${s.paymentsToday ?? 0} pagos`, dir: "flat" },
    { id: "revenue", icon: "cash", value: `S/ ${Number(s.revenueToday || 0).toFixed(2)}`, label: "Ingresos hoy", delta: "backend", dir: "up" },
    { id: "soon", icon: "alert", value: String(s.expiredSoon ?? 0), label: "Vencen pronto", delta: "7 dias", dir: "down" },
  ] : ADMIN_KPIS;
  const pendingRows = pending.length
    ? pending.map(p => ({ n: p.membership?.user?.nombre_completo || "Socio", over: p.membership?.plan_nombre || "Comprobante", st: "warn" }))
    : PENDING_PAYMENTS;
  return (
    <div className="content-wrap">
      <div className="grid cols-4">{kpis.map(k => <Kpi key={k.id} {...k}/>)}</div>
      <div className="grid k-2-1" style={{ marginTop: 16 }}>
        <Panel title="Asistencia semanal" sub="referencial hasta conectar asistencia historica">
          <div style={{ padding: "8px 4px 0" }}><Bars data={WEEK_ATTENDANCE}/></div>
        </Panel>
        <Panel title="Pagos pendientes" sub={`${pendingRows.length} registros`} action={<Btn kind="ghost" size="sm" onClick={() => go("pagos")}>Ver pagos</Btn>} bodyPad={false}>
          {pendingRows.map((p, i) => (
            <div className="lrow" key={i}>
              <span className="l-ic" style={{ color: p.st === "danger" ? "var(--danger)" : "var(--warn)" }}>{I.alert}</span>
              <div className="l-main"><div className="l-t">{p.n}</div><div className="l-s">{p.over}</div></div>
              <Btn kind="ghost" size="sm" onClick={() => go("pagos")}>Revisar</Btn>
            </div>
          ))}
        </Panel>
      </div>
      <Panel title="Ultimos movimientos" sub="auditoria real" bodyPad={false}>
        {(app?.auditLogs?.length ? app.auditLogs.slice(0, 8) : []).map(log => (
          <div className="lrow" key={log.id}>
            <span className="l-ic">{I.bell}</span>
            <div className="l-main"><div className="l-t">{log.accion}</div><div className="l-s">{log.entidad} - {log.actor_name}</div></div>
            <span className="l-time">{new Date(log.timestamp).toLocaleTimeString()}</span>
          </div>
        ))}
        {!app?.auditLogs?.length && <div className="empty">Sin auditoria reciente.</div>}
      </Panel>
    </div>
  );
}

function CajeroDashboard({ go, app }) {
  const [details, setDetails] = React.useState(null);
  const [sales, setSales] = React.useState(null);
  React.useEffect(() => {
    let alive = true;
    app?.getCajaDetails?.().then(d => alive && setDetails(d)).catch(() => {});
    app?.getCajaSales?.().then(d => alive && setSales(d)).catch(() => {});
    return () => { alive = false; };
  }, [app]);
  const total = details?.stats?.total_esperado ?? 0;
  const productSales = sales?.productSales?.length ?? 0;
  const memberSales = sales?.membershipPayments?.length ?? 0;
  return (
    <div className="content-wrap">
      <div className="grid cols-2">
        <div className="panel pad" style={{ background: "var(--sidebar-bg)", color: "var(--sidebar-ink)", borderColor: "transparent" }}>
          <div style={{ font: "600 11px var(--font-mono)", letterSpacing: ".08em", color: "var(--accent)", textTransform: "uppercase" }}>Turno activo</div>
          <div style={{ font: "800 34px var(--font-display)", marginTop: 10 }}>S/ {Number(total).toFixed(2)}</div>
          <div style={{ color: "rgba(255,255,255,.65)", marginTop: 2, font: "500 12.5px var(--font-body)" }}>Total esperado del turno segun caja</div>
        </div>
        <div className="grid cols-2">
          <Kpi icon="card" value={String(memberSales)} label="Ventas membresia" delta="turno" dir="flat"/>
          <Kpi icon="box" value={String(productSales)} label="Ventas productos" delta="turno" dir="up"/>
        </div>
      </div>
      <div className="section-title">Acciones rapidas</div>
      <div className="grid cols-4">
        {[
          { ic: "scan", l: "Registrar asistencia", g: "asistencia" },
          { ic: "cash", l: "Registrar cobro", g: "caja" },
          { ic: "users", l: "Buscar usuario", g: "caja" },
          { ic: "box", l: "Vender producto", g: "caja" },
        ].map(a => (
          <button key={a.l} className="panel pad" onClick={() => go(a.g)} style={{ cursor: "pointer", textAlign: "left", display: "flex", flexDirection: "column", gap: 10 }}>
            <span className="k-ic">{icon(a.ic)}</span><span style={{ font: "600 13.5px var(--font-body)" }}>{a.l}</span>
          </button>
        ))}
      </div>
    </div>
  );
}

function CoachDashboard({ go, app }) {
  const rows = app?.trainerMembers?.length
    ? app.trainerMembers.map(m => ({ n: m.nombre_completo, obj: m.member_profile?.objetivo || "Objetivo pendiente", last: m.memberships?.[0]?.fecha_vencimiento ? `Vence ${new Date(m.memberships[0].fecha_vencimiento).toLocaleDateString()}` : "Sin membresia", st: m.estado === "ACTIVE" ? "ok" : "warn" }))
    : COACH_MEMBERS;
  return (
    <div className="content-wrap">
      <div className="grid cols-4">
        <Kpi icon="users" value={String(rows.length)} label="Alumnos asignados" delta="API real" dir="flat"/>
        <Kpi icon="trend" value="23" label="Sesiones semana" delta="referencial" dir="up"/>
        <Kpi icon="check" value={String(rows.filter(r => r.st === "ok").length)} label="Activos" delta="" dir="up"/>
        <Kpi icon="alert" value={String(rows.filter(r => r.st !== "ok").length)} label="Requieren seguimiento" delta="" dir="down"/>
      </div>
      <Panel title="Mis alumnos" sub="asignados al entrenador" action={<Btn kind="ghost" size="sm" onClick={() => go("usuarios")}>Ver todos</Btn>} bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Alumno</th><th>Objetivo</th><th>Ultima referencia</th><th>Estado</th></tr></thead>
          <tbody>{rows.map((m, i) => (
            <tr key={i} className="clickable" onClick={() => go("usuarios")}>
              <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}><Avatar name={m.n} size={32}/><span className="cell-main">{m.n}</span></div></td>
              <td style={{ color: "var(--ink-2)" }}>{m.obj}</td><td style={{ color: "var(--ink-2)" }}>{m.last}</td>
              <td>{m.st === "ok" ? <Badge kind="ok" dot>Al dia</Badge> : <Badge kind="warn" dot>Seguir</Badge>}</td>
            </tr>
          ))}</tbody>
        </table>
      </Panel>
    </div>
  );
}

function MiembroDashboard({ app }) {
  const user = app?.currentUser || {};
  const membership = user.memberships?.[0];
  const plan = membership?.plan_nombre || "Sin membresia";
  const state = String(membership?.estado || user.estado || "PENDING").toLowerCase();
  const payments = app?.memberPayments?.length ? app.memberPayments : [];
  const expiry = membership?.fecha_vencimiento ? new Date(membership.fecha_vencimiento) : null;
  const days = expiry ? Math.max(0, Math.ceil((expiry - new Date()) / 86400000)) : 0;
  return (
    <div className="content-wrap">
      <div className="grid k-2-1">
        <div className="panel pad" style={{ background: "var(--sidebar-bg)", color: "var(--sidebar-ink)", borderColor: "transparent" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
            <span style={{ font: "600 11px var(--font-mono)", letterSpacing: ".08em", color: "var(--accent)", textTransform: "uppercase" }}>{plan}</span>
            <Badge kind={state === "active" ? "accent" : "warn"}>{state}</Badge>
          </div>
          <div style={{ font: "800 34px var(--font-display)", marginTop: 14 }}>{days} <span style={{ font: "500 15px var(--font-body)", color: "rgba(255,255,255,.65)" }}>dias restantes</span></div>
          <div className="bar-track" style={{ marginTop: 14, background: "rgba(255,255,255,.12)" }}><i style={{ width: `${Math.min(100, days * 3)}%`, background: "var(--accent)" }}/></div>
          <div style={{ font: "500 12px var(--font-mono)", color: "rgba(255,255,255,.55)", marginTop: 8 }}>{expiry ? `Vence ${expiry.toLocaleDateString()}` : "Sin vencimiento activo"}</div>
        </div>
        <Panel title="Acceso rapido" bodyPad={false}>
          {[{ ic: "scan", t: "Mi codigo QR", s: "Disponible desde perfil movil" }, { ic: "cash", t: "Pagar membresia", s: "Planes reales del tenant" }, { ic: "chart", t: "Mi rutina", s: "Rutina activa si existe" }].map((a, i) => (
            <div className="lrow" key={i}><span className="l-ic">{icon(a.ic)}</span><div className="l-main"><div className="l-t">{a.t}</div><div className="l-s">{a.s}</div></div><span style={{ color: "var(--ink-3)" }}>{I.forward}</span></div>
          ))}
        </Panel>
      </div>
      <Panel title="Historial de pagos" bodyPad={false}>
        <table className="tbl"><thead><tr><th>Fecha</th><th className="num">Monto</th><th>Metodo</th><th>Estado</th></tr></thead>
          <tbody>{(payments.length ? payments.map(p => ({ d: new Date(p.timestamp).toLocaleDateString(), m: `S/ ${p.monto}`, k: p.metodo, ok: p.estado === "APPROVED" })) : USER_PAYMENTS).map((p, i) => (
            <tr key={i}><td style={{ font: "600 13px var(--font-mono)" }}>{p.d}</td><td className="num" style={{ font: "700 14px var(--font-display)" }}>{p.m}</td><td><Badge>{p.k}</Badge></td><td><Badge kind={p.ok ? "ok" : "warn"} dot>{p.ok ? "Acreditado" : "Pendiente"}</Badge></td></tr>
          ))}</tbody>
        </table>
      </Panel>
    </div>
  );
}

function SuperDashboard({ go, app }) {
  const rows = app?.tenants?.length ? app.tenants : GYMS.map(g => ({ id: g.id, nombre: g.n, direccion: g.city, activo: g.st === "active", plan: g.plan, usuarios: g.usuarios }));
  const active = rows.filter(g => g.activo).length;
  const suspended = rows.length - active;
  const kpis = [
    { id: "gyms", icon: "box", value: String(rows.length), label: "Gimnasios", delta: "tenants", dir: "flat" },
    { id: "active", icon: "check", value: String(active), label: "Activos", delta: "operando", dir: "up" },
    { id: "suspended", icon: "alert", value: String(suspended), label: "Suspendidos", delta: "SaaS", dir: "down" },
    { id: "network", icon: "trend", value: `${rows.length ? Math.round((active / rows.length) * 100) : 0}%`, label: "Salud red", delta: "actual", dir: "flat" },
  ];
  return (
    <div className="content-wrap">
      <div className="grid cols-4">{kpis.map(k => <Kpi key={k.id} {...k}/>)}</div>
      <div className="grid k-2-1" style={{ marginTop: 16 }}>
        <Panel title="Gimnasios de la red" sub="instancias multi-tenant" action={<Btn kind="ghost" size="sm" onClick={() => go("gimnasios")}>Ver todos</Btn>} bodyPad={false}>
          <table className="tbl"><thead><tr><th>Gimnasio</th><th>Plan</th><th className="num">Usuarios</th><th>Estado</th></tr></thead>
            <tbody>{rows.slice(0, 6).map(g => (
              <tr key={g.id} className="clickable" onClick={() => go("gimnasios")}>
                <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}><span style={{ width: 32, height: 32, borderRadius: 9, background: "var(--control-bg)", color: "var(--control-ink)", display: "grid", placeItems: "center", font: "800 13px var(--font-display)" }}>{(g.nombre || "G")[0]}</span><div><div className="cell-main">{g.nombre}</div><div className="cell-sub">{g.direccion || "Sin direccion"}</div></div></div></td>
                <td><Badge>{g.plan || "SaaS"}</Badge></td><td className="num">{g.usuarios || "-"}</td><td>{g.activo ? <Badge kind="ok" dot>Activo</Badge> : <Badge kind="danger" dot>Suspendido</Badge>}</td>
              </tr>
            ))}</tbody>
          </table>
        </Panel>
        <Panel title="Estado de la red">
          <div className="grid cols-2">
            <Kpi icon="check" value={String(active)} label="Activos" delta="" dir="up"/>
            <Kpi icon="alert" value={String(suspended)} label="Suspendidos" delta="" dir="down"/>
          </div>
          <div className="divider"/>
          <div className="bar-track tall" style={{ height: 12 }}><i style={{ width: `${rows.length ? Math.round((active / rows.length) * 100) : 0}%`, background: "var(--accent)" }}/></div>
          <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-3)", marginTop: 8 }}>{active} de {rows.length} instancias operativas</div>
        </Panel>
      </div>
    </div>
  );
}

export { Login, AdminDashboard, CajeroDashboard, CoachDashboard, MiembroDashboard, SuperDashboard };

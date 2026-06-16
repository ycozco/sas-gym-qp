// modules2.jsx — módulos ampliados del panel (paridad con crosshero-gym):
// Membresías, Caja, Finanzas, Puntos, Clases, Entrenamientos, CRM.

// ═══════════════════════════════════════════════════════════════
// MEMBRESÍAS — planes, precios, congelar / traspasar
// ═══════════════════════════════════════════════════════════════
function MembershipPlanForm({ plan, onSave, onCancel }) {
  const [form, setForm] = React.useState(() => plan || {
    name: "",
    description: "",
    durationDays: 30,
    price: 0,
    color: "#2F6BFF",
    order: 0,
    active: true,
  });
  const [saving, setSaving] = React.useState(false);
  const [error, setError] = React.useState("");
  const setField = (key, value) => setForm((prev) => ({ ...prev, [key]: value }));
  const submit = async (e) => {
    e.preventDefault();
    setError("");
    if (!form.name.trim() || Number(form.durationDays) <= 0 || Number(form.price) < 0) {
      setError("Completa nombre, duración y precio válido.");
      return;
    }
    setSaving(true);
    try {
      await onSave(form);
    } catch (e) {
      setError(e.message || "No se pudo guardar el plan.");
    } finally {
      setSaving(false);
    }
  };
  return (
    <form onSubmit={submit}>
      <ErrorBlock message={error}/>
      <div className="field"><label>Nombre</label><input value={form.name} onChange={(e) => setField("name", e.target.value)}/></div>
      <div className="field"><label>Descripción</label><textarea rows="2" value={form.description} onChange={(e) => setField("description", e.target.value)}/></div>
      <div className="row-2">
        <div className="field"><label>Duración en días</label><input type="number" min="1" value={form.durationDays} onChange={(e) => setField("durationDays", e.target.value)}/></div>
        <div className="field"><label>Precio</label><input type="number" min="0" step="0.01" value={form.price} onChange={(e) => setField("price", e.target.value)}/></div>
      </div>
      <div className="row-2">
        <div className="field"><label>Color</label><input type="color" value={form.color || "#2F6BFF"} onChange={(e) => setField("color", e.target.value)}/></div>
        <div className="field"><label>Orden</label><input type="number" min="0" value={form.order || 0} onChange={(e) => setField("order", e.target.value)}/></div>
      </div>
      <label className="check-inline"><input type="checkbox" checked={form.active} onChange={(e) => setField("active", e.target.checked)}/> Plan activo</label>
      <div className="modal-foot inline">
        <Btn kind="ghost" type="button" onClick={onCancel}>Cancelar</Btn>
        <Btn kind="primary" type="submit" disabled={saving}>{saving ? "Guardando..." : "Guardar plan"}</Btn>
      </div>
    </form>
  );
}

function Membresias({ app }) {
  const plans = app?.membershipPlans?.length
    ? app.membershipPlans
    : MEMBERSHIP_PLANS.map(p => normalizeMembershipPlan({
        id: p.id,
        nombre: p.n,
        descripcion: "",
        duracion_dias: parseInt(p.dur, 10) || 30,
        precio: p.price,
        color: "#2F6BFF",
        orden: 0,
        activo: p.on,
      }));
  const [editingPlan, setEditingPlan] = React.useState(null);
  const [message, setMessage] = React.useState("");
  const [error, setError] = React.useState("");

  const savePlan = async (plan) => {
    setError("");
    setMessage("");
    await app.saveMembershipPlan(plan);
    setEditingPlan(null);
    setMessage("Plan guardado. Los cambios aplican solo a nuevas membresías.");
  };
  const deactivatePlan = async (plan) => {
    if (!confirm(`¿Desactivar ${plan.name}? Las membresías existentes conservarán su snapshot.`)) return;
    setError("");
    setMessage("");
    try {
      await app.deactivateMembershipPlan(plan.id);
      setMessage("Plan desactivado. Las membresías existentes no fueron modificadas.");
    } catch (e) {
      setError(e.message || "No se pudo desactivar el plan.");
    }
  };

  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {MEMB_KPIS.map(k => <Kpi key={k.id} {...k}/>)}
      </div>
      <ErrorBlock message={error}/>
      {message && <div className="state-block ok">{message}</div>}

      <Panel title="Planes de membresía" sub="precios y estado"
             action={<Btn kind="primary" size="sm" leading={I.plus} onClick={() => setEditingPlan({})}>Nuevo plan</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Plan</th><th>Duración</th><th className="num">Precio</th><th>Color</th><th>Estado</th><th className="num">Acciones</th></tr></thead>
          <tbody>
            {plans.map(p => (
              <tr key={p.id || p.name} className="clickable">
                <td>
                  <div className="cell-main">{p.name}</div>
                  <div className="cell-sub">{p.description || "Catálogo del tenant"}</div>
                </td>
                <td style={{ color: "var(--ink-2)" }}>{p.durationDays} días</td>
                <td className="num" style={{ font: "700 14px var(--font-display)" }}>S/ {p.price}</td>
                <td><span className="swatch" style={{ background: p.color }}/></td>
                <td>{p.active ? <Badge kind="ok" dot>Disponible</Badge> : <Badge dot>Oculto</Badge>}</td>
                <td className="num">
                  <div style={{ display: "inline-flex", gap: 8 }}>
                    <Btn kind="ghost" size="sm" leading={I.edit} onClick={() => setEditingPlan(p)}>Editar</Btn>
                    <Btn kind="ghost" size="sm" leading={I.trash} disabled={!p.id || !p.active} onClick={() => deactivatePlan(p)}>Ocultar</Btn>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="table-note">
          Editar un plan no modifica membresías en curso; el precio y duración se copian al crear nuevas ventas.
        </div>
      </Panel>

      <Panel title="Operaciones de membresía" sub="acciones sobre una membresía activa" bodyPad={false}>
        {[
          { ic: "clock",  t: "Congelar / descongelar", s: "Pausa la vigencia por viaje o lesión" },
          { ic: "users",  t: "Traspasar membresía",    s: "Transfiere los días restantes a otro usuario" },
          { ic: "cash",   t: "Registrar abono",        s: "Pago parcial a cuenta de un plan" },
          { ic: "download", t: "Reimprimir boleta",    s: "Comprobante de una venta de membresía" },
        ].map((a, i) => (
          <div className="lrow" key={i}>
            <span className="l-ic">{icon(a.ic)}</span>
            <div className="l-main"><div className="l-t">{a.t}</div><div className="l-s">{a.s}</div></div>
            <Btn kind="ghost" size="sm">Abrir</Btn>
          </div>
        ))}
      </Panel>
      {editingPlan !== null && (
        <Modal
          title={editingPlan.id ? "Editar plan de membresía" : "Nuevo plan de membresía"}
          onClose={() => setEditingPlan(null)}
        >
          <MembershipPlanForm
            plan={editingPlan.id ? editingPlan : null}
            onSave={savePlan}
            onCancel={() => setEditingPlan(null)}
          />
        </Modal>
      )}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CAJA — apertura, movimientos, cierre del turno
// ═══════════════════════════════════════════════════════════════
function Caja() {
  const ing = CAJA_MOV.filter(m => m.tipo === "ingreso").reduce((s, m) => s + m.m, 0);
  const egr = CAJA_MOV.filter(m => m.tipo === "egreso").reduce((s, m) => s + m.m, 0);
  const saldo = CAJA_STATE.inicial + ing - egr;
  return (
    <div className="content-wrap">
      <div className="grid k-2-1">
        <div className="panel pad" style={{ background: "var(--ink)", color: "#fff", borderColor: "transparent" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ font: "600 11px var(--font-mono)", letterSpacing: ".08em", color: "var(--accent)", textTransform: "uppercase" }}>● Caja abierta</span>
            <Badge kind="accent">Turno en curso</Badge>
          </div>
          <div style={{ font: "800 34px var(--font-display)", letterSpacing: "-0.04em", marginTop: 12 }}>S/ {saldo.toLocaleString()}</div>
          <div style={{ font: "500 12.5px var(--font-body)", color: "rgba(255,255,255,.6)", marginTop: 2 }}>
            Saldo actual · abierta {CAJA_STATE.desde} por {CAJA_STATE.cajero}
          </div>
          <div style={{ display: "flex", gap: 10, marginTop: 18 }}>
            <Btn kind="ghost" leading={I.trash} style={{ background: "rgba(255,255,255,.1)", color: "#fff", borderColor: "rgba(255,255,255,.18)" }}>Registrar egreso</Btn>
            <Btn kind="accent" leading={I.check}>Cerrar caja</Btn>
          </div>
        </div>
        <div className="grid" style={{ gap: 16 }}>
          <Kpi icon="trend"  value={`S/ ${ing.toLocaleString()}`} label="Ingresos del turno" delta={`${CAJA_MOV.filter(m=>m.tipo==="ingreso").length} movimientos`} dir="up"/>
          <Kpi icon="wallet" value={`S/ ${egr.toLocaleString()}`} label="Egresos del turno"  delta={`${CAJA_MOV.filter(m=>m.tipo==="egreso").length} movimientos`} dir="down"/>
        </div>
      </div>

      <Panel title="Movimientos de caja" sub={`saldo inicial S/ ${CAJA_STATE.inicial}`} bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Hora</th><th>Concepto</th><th>Tipo</th><th className="num">Monto</th></tr></thead>
          <tbody>
            {CAJA_MOV.map((m, i) => (
              <tr key={i}>
                <td style={{ font: "600 13px var(--font-mono)" }}>{m.t}</td>
                <td className="cell-main">{m.concepto}</td>
                <td>{m.tipo === "ingreso" ? <Badge kind="ok" dot>Ingreso</Badge> : <Badge kind="danger" dot>Egreso</Badge>}</td>
                <td className="num" style={{ font: "700 14px var(--font-display)", color: m.tipo === "egreso" ? "var(--danger)" : "var(--ink)" }}>
                  {m.tipo === "egreso" ? "−" : "+"}S/ {m.m}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// FINANZAS — sueldos, servicios, gastos e ingresos especiales
// ═══════════════════════════════════════════════════════════════
function Finanzas() {
  const TIPO = { Sueldo: "info", Servicio: "warn", Gasto: "danger", Ingreso: "ok" };
  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {FIN_KPIS.map(k => <Kpi key={k.id} {...k}/>)}
      </div>

      <Panel title="Movimientos del mes" sub="sueldos · servicios · gastos e ingresos especiales"
             action={<div style={{ display: "flex", gap: 8 }}>
               <Btn kind="ghost" size="sm" leading={I.plus}>Sueldo</Btn>
               <Btn kind="primary" size="sm" leading={I.plus}>Gasto</Btn>
             </div>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Fecha</th><th>Concepto</th><th>Categoría</th><th className="num">Monto</th></tr></thead>
          <tbody>
            {FIN_MOV.map((m, i) => (
              <tr key={i}>
                <td style={{ font: "600 13px var(--font-mono)" }}>{m.d}</td>
                <td className="cell-main">{m.concepto}</td>
                <td><Badge kind={TIPO[m.tipo]}>{m.tipo}</Badge></td>
                <td className="num" style={{ font: "700 14px var(--font-display)", color: m.dir === "egreso" ? "var(--danger)" : "var(--success)" }}>
                  {m.dir === "egreso" ? "−" : "+"}S/ {m.m.toLocaleString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>

      <Panel title="Gestión financiera" bodyPad={false}>
        {[
          { ic: "users",  t: "Sueldos y horas trabajadas", s: "Pagos al personal del gimnasio" },
          { ic: "wallet", t: "Servicios fijos",            s: "Luz, agua, internet, alquiler" },
          { ic: "box",    t: "Proveedores y pertenencias",  s: "Compras de inventario y activos" },
        ].map((a, i) => (
          <div className="lrow" key={i}>
            <span className="l-ic">{icon(a.ic)}</span>
            <div className="l-main"><div className="l-t">{a.t}</div><div className="l-s">{a.s}</div></div>
            <span style={{ color: "var(--ink-3)" }}>{I.forward}</span>
          </div>
        ))}
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// PUNTOS — fidelización: catálogo y canjes
// ═══════════════════════════════════════════════════════════════
function Puntos() {
  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {PTS_KPIS.map(k => <Kpi key={k.id} {...k}/>)}
      </div>

      <div className="grid k-2-1">
        <Panel title="Catálogo canjeable" sub="productos y membresías por puntos"
               action={<Btn kind="primary" size="sm" leading={I.plus}>Añadir ítem</Btn>}
               bodyPad={false}>
          <table className="tbl">
            <thead><tr><th>Ítem</th><th>Tipo</th><th className="num">Costo</th></tr></thead>
            <tbody>
              {PTS_CATALOG.map((c, i) => (
                <tr key={i} className="clickable">
                  <td className="cell-main">{c.n}</td>
                  <td><Badge kind={c.tipo === "Membresía" ? "accent" : "info"}>{c.tipo}</Badge></td>
                  <td className="num" style={{ font: "700 13.5px var(--font-mono)" }}>{c.costo} pts</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Panel>

        <Panel title="Canjes recientes" bodyPad={false}>
          {PTS_CANJES.map((c, i) => (
            <div className="lrow" key={i}>
              <span className="l-ic" style={{ color: "var(--warn)" }}>{I.star}</span>
              <div className="l-main">
                <div className="l-t">{c.n}</div>
                <div className="l-s">{c.item}</div>
              </div>
              <span style={{ font: "700 12.5px var(--font-mono)", color: "var(--ink-2)" }}>−{c.pts}</span>
            </div>
          ))}
          <div style={{ padding: "12px 16px", font: "500 12px var(--font-body)", color: "var(--ink-3)" }}>
            La configuración define cuántos puntos otorga cada sol gastado.
          </div>
        </Panel>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CLASES — horarios y cupos  (WEB-06)
// ═══════════════════════════════════════════════════════════════
function Clases() {
  return (
    <div className="content-wrap">
      <Panel title="Clases y horarios" sub={`${CLASSES.length} clases activas`}
             action={<Btn kind="primary" size="sm" leading={I.plus}>Crear clase</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Clase</th><th>Entrenador</th><th>Días</th><th>Hora</th><th className="num">Cupo</th><th>Estado</th></tr></thead>
          <tbody>
            {CLASSES.map((c, i) => (
              <tr key={i} className="clickable">
                <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span className="l-ic" style={{ width: 30, height: 30, background: "var(--ink)", color: "var(--accent)" }}>{I.calendar}</span>
                  <span className="cell-main">{c.n}</span>
                </div></td>
                <td style={{ color: "var(--ink-2)" }}>{c.coach}</td>
                <td style={{ color: "var(--ink-2)" }}>{c.dias}</td>
                <td style={{ font: "600 13px var(--font-mono)" }}>{c.hora}</td>
                <td className="num">{c.cupo}</td>
                <td>{c.st === "full" ? <Badge kind="danger" dot>Lleno</Badge>
                    : c.st === "warn" ? <Badge kind="warn" dot>Casi lleno</Badge>
                    : <Badge kind="ok" dot>Disponible</Badge>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>
      <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-3)", marginTop: 12 }}>
        Los miembros reservan su cupo desde la app móvil; al llenarse pasan a lista de espera.
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// ENTRENAMIENTOS — rutinas, ejercicios, grupos musculares
// ═══════════════════════════════════════════════════════════════
function Entrenamientos() {
  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {TRAIN_KPIS.map(k => <Kpi key={k.id} {...k}/>)}
      </div>

      <Panel title="Rutinas y plantillas" sub="biblioteca de entrenamientos"
             action={<Btn kind="primary" size="sm" leading={I.plus}>Nueva rutina</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Rutina</th><th>División</th><th className="num">Ejercicios</th><th className="num">Asignada a</th></tr></thead>
          <tbody>
            {ROUTINES.map((r, i) => (
              <tr key={i} className="clickable">
                <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span className="l-ic" style={{ width: 30, height: 30 }}>{I.dumbbell}</span>
                  <span className="cell-main">{r.n}</span>
                </div></td>
                <td style={{ color: "var(--ink-2)" }}>{r.div}</td>
                <td className="num">{r.ej}</td>
                <td className="num">{r.asg} alumnos</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>

      <Panel title="Grupos musculares" sub="biblioteca de ejercicios animados">
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {MUSCLE_GROUPS.map(g => <span className="badge" key={g}>{g}</span>)}
        </div>
        <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-3)", marginTop: 12 }}>
          Cada ejercicio guarda una animación (GIF/WebM ≤ 2 MB) versionada y cacheada.
        </div>
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CRM — campañas, contactos y seguimientos
// ═══════════════════════════════════════════════════════════════
function CRM() {
  const CANAL = { Email: "info", WhatsApp: "ok", Push: "accent" };
  const EST = { Activa: "ok", Programada: "warn", Finalizada: "" };
  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {CRM_KPIS.map(k => <Kpi key={k.id} {...k}/>)}
      </div>

      <Panel title="Campañas" sub="email · WhatsApp · push"
             action={<Btn kind="primary" size="sm" leading={I.plus}>Nueva campaña</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Campaña</th><th>Canal</th><th>Estado</th><th className="num">Alcance</th></tr></thead>
          <tbody>
            {CAMPAIGNS.map((c, i) => (
              <tr key={i} className="clickable">
                <td className="cell-main">{c.n}</td>
                <td><Badge kind={CANAL[c.canal]}>{c.canal}</Badge></td>
                <td><Badge kind={EST[c.estado]} dot>{c.estado}</Badge></td>
                <td className="num">{c.alcance} personas</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>

      <Panel title="Contactos y leads" sub="prospectos sin membresía" bodyPad={false}>
        {CRM_CONTACTS.map((c, i) => (
          <div className="lrow" key={i}>
            <Avatar name={c.n} size={34}/>
            <div className="l-main">
              <div className="l-t">{c.n}</div>
              <div className="l-s">Origen: {c.origen}</div>
            </div>
            <Badge kind={c.estado === "Nuevo" ? "info" : "warn"} dot>{c.estado}</Badge>
          </div>
        ))}
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// SUPER ADMIN · GIMNASIOS — clientes / instancias multi-tenant
// ═══════════════════════════════════════════════════════════════
function Gimnasios() {
  const [q, setQ] = React.useState("");
  const [filter, setFilter] = React.useState("Todos");
  const rows = GYMS.filter(g => {
    const okF = filter === "Todos"
      || (filter === "Activos" && g.st === "active")
      || (filter === "Suspendidos" && g.st === "suspended");
    const okQ = !q || g.n.toLowerCase().includes(q.toLowerCase()) || g.city.toLowerCase().includes(q.toLowerCase());
    return okF && okQ;
  });
  const planKind = (p) => p === "Enterprise" ? "accent" : p === "Pro" ? "info" : "";
  return (
    <div className="content-wrap">
      <Panel bodyPad={false}>
        <div className="toolbar">
          <div className="search">
            {I.search}
            <input placeholder="Buscar gimnasio o ciudad…" value={q}
                   onChange={e => setQ(e.target.value)} aria-label="Buscar gimnasio"/>
          </div>
          <div className="seg" role="tablist" aria-label="Filtro por estado">
            {["Todos", "Activos", "Suspendidos"].map(f => (
              <button key={f} role="tab" aria-selected={filter === f} onClick={() => setFilter(f)}>{f}</button>
            ))}
          </div>
          <Btn kind="primary" leading={I.plus}>Crear gimnasio</Btn>
        </div>
        <table className="tbl">
          <thead><tr><th>Gimnasio</th><th>Plan SaaS</th><th className="num">Usuarios</th><th>Alta</th><th>Estado</th></tr></thead>
          <tbody>
            {rows.map(g => (
              <tr key={g.id} className="clickable">
                <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span style={{ width: 34, height: 34, borderRadius: 9, background: "var(--ink)", color: "var(--accent)", display: "grid", placeItems: "center", font: "800 14px var(--font-display)" }}>{g.n[0]}</span>
                  <div><div className="cell-main">{g.n}</div><div className="cell-sub">{g.city}</div></div>
                </div></td>
                <td><Badge kind={planKind(g.plan)}>{g.plan}</Badge></td>
                <td className="num">{g.usuarios}</td>
                <td style={{ color: "var(--ink-2)", font: "500 12.5px var(--font-mono)" }}>{g.alta}</td>
                <td>{g.st === "active" ? <Badge kind="ok" dot>Activo</Badge> : <Badge kind="danger" dot>Suspendido</Badge>}</td>
              </tr>
            ))}
            {rows.length === 0 && <tr><td colSpan="5"><div className="empty">Sin resultados para “{q}”.</div></td></tr>}
          </tbody>
        </table>
        <div style={{ padding: "12px 16px", font: "500 12px var(--font-body)", color: "var(--ink-3)" }}>
          Mostrando {rows.length} de {GYMS.length} gimnasios · cada uno es una instancia aislada (multi-tenant)
        </div>
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// SUPER ADMIN · PLANES SAAS — suscripción de los gimnasios
// ═══════════════════════════════════════════════════════════════
function PlanesSaaS() {
  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {SAAS_PLANS.map((p, i) => (
          <div className="panel pad" key={p.n} style={i === 1 ? { borderColor: "var(--ink)", borderWidth: 2 } : null}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <Badge kind={p.n === "Enterprise" ? "accent" : p.n === "Pro" ? "info" : ""}>{p.n}</Badge>
              {i === 1 && <span style={{ font: "600 10.5px var(--font-mono)", color: "var(--ink-3)", textTransform: "uppercase", letterSpacing: ".06em" }}>Más usado</span>}
            </div>
            <div style={{ font: "800 30px var(--font-display)", letterSpacing: "-0.04em", marginTop: 14 }}>
              {p.price}<span style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}> /mes</span>
            </div>
            <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>{p.limite}</div>
            <div className="divider"/>
            <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}>{p.feats}</div>
            <div style={{ font: "700 13px var(--font-display)", marginTop: 12 }}>{p.gimnasios} gimnasios en este plan</div>
            <div style={{ marginTop: 14 }}>
              <Btn kind="ghost" block leading={I.edit}>Editar plan</Btn>
            </div>
          </div>
        ))}
      </div>
      <Panel title="Facturación de la plataforma" sub="cobro mensual a cada gimnasio">
        <div style={{ font: "500 14px var(--font-body)", color: "var(--ink-2)" }}>
          Cada gimnasio paga su suscripción según el plan contratado. El ingreso
          recurrente total (MRR) se calcula sumando los planes activos de las
          10 instancias de la red.
        </div>
      </Panel>
    </div>
  );
}

Object.assign(window, { Membresias, Caja, Finanzas, Puntos, Clases, Entrenamientos, CRM, Gimnasios, PlanesSaaS });

// modules.jsx — módulos administrativos del panel web.

// ═══════════════════════════════════════════════════════════════
// USUARIOS  (WEB-02 lista  +  WEB-03 detalle)
// ═══════════════════════════════════════════════════════════════
function normalizeWebMember(user) {
  const membership = user.memberships?.[0] || {};
  return {
    id: user.id,
    n: user.nombre_completo || user.n || "Usuario",
    dni: user.dni || "",
    plan: membership.plan_nombre || user.plan || "Sin plan",
    st: String(membership.estado || user.estado || user.st || "pending").toLowerCase(),
    venc: membership.fecha_vencimiento ? new Date(membership.fecha_vencimiento).toLocaleDateString() : "—",
    trainer: user.member_profile?.trainer?.user?.nombre_completo || user.trainer || "Sin asignar",
    tel: user.celular || user.tel || "",
    email: user.email || "",
    asis: user.asis || 0,
    raw: user,
  };
}

function Usuarios({ go, app }) {
  const [sel, setSel] = React.useState(null);
  const [q, setQ] = React.useState("");
  const [filter, setFilter] = React.useState("Todos");
  const [editing, setEditing] = React.useState(null);
  const [message, setMessage] = React.useState("");
  const [error, setError] = React.useState("");

  if (sel) return <UserDetail user={sel} onBack={() => setSel(null)} go={go}/>;

  const filters = ["Todos", "Activos", "Vencidos", "Pendientes"];
  const stForFilter = { Activos: "active", Vencidos: "expired", Pendientes: "pending" };
  const apiMembers = app?.adminMembers?.length
    ? app.adminMembers
    : app?.trainerMembers?.length
      ? app.trainerMembers
      : [];
  const source = apiMembers.length ? apiMembers.map(normalizeWebMember) : USERS;
  const rows = source.filter(u => {
    const okF = filter === "Todos" || u.st === stForFilter[filter] || (filter === "Vencidos" && u.st === "grace");
    const okQ = !q || u.n.toLowerCase().includes(q.toLowerCase()) || u.dni.includes(q);
    return okF && okQ;
  });
  const save = async (form) => {
    setError(""); setMessage("");
    try {
      await app.saveAdminMember({
        id: form.id,
        nombreCompleto: form.name,
        email: form.email,
        dni: form.dni,
        celular: form.phone,
      });
      setEditing(null);
      setMessage("Usuario guardado.");
    } catch (e) { setError(e.message || "No se pudo guardar."); }
  };

  return (
    <div className="content-wrap">
      <ErrorBlock message={error}/>
      {message && <div className="state-block ok">{message}</div>}
      <Panel bodyPad={false}>
        <div className="toolbar">
          <div className="search">
            {I.search}
            <input placeholder="Buscar por nombre o DNI…" value={q}
                   onChange={e => setQ(e.target.value)} aria-label="Buscar usuario"/>
          </div>
          <div className="seg" role="tablist" aria-label="Filtro por estado">
            {filters.map(f => (
              <button key={f} role="tab" aria-selected={filter === f} onClick={() => setFilter(f)}>{f}</button>
            ))}
          </div>
          <Btn kind="primary" leading={I.plus} onClick={() => setEditing({})}>Registrar usuario</Btn>
        </div>

        <table className="tbl">
          <thead><tr><th>Usuario</th><th>DNI</th><th>Membresía</th><th>Entrenador</th><th>Estado</th><th></th></tr></thead>
          <tbody>
            {rows.map(u => (
              <tr key={u.id} className="clickable" onClick={() => setSel(u)}>
                <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <Avatar name={u.n} size={34}/><span className="cell-main">{u.n}</span>
                </div></td>
                <td className="num" style={{ font: "500 13px var(--font-mono)", color: "var(--ink-2)" }}>{u.dni}</td>
                <td>
                  <div>{u.plan}</div>
                  <div className="cell-sub">{u.venc !== "—" ? `Vence ${u.venc}` : "Sin pago"}</div>
                </td>
                <td style={{ color: "var(--ink-2)" }}>{u.trainer}</td>
                <td><StatusBadge st={u.st}/></td>
                <td style={{ color: "var(--ink-3)", textAlign: "right" }}>
                  <Btn kind="ghost" size="sm" onClick={(e) => { e.stopPropagation(); setEditing(u); }}>Editar</Btn>
                </td>
              </tr>
            ))}
            {rows.length === 0 && <tr><td colSpan="6"><div className="empty">Sin resultados para “{q}”.</div></td></tr>}
          </tbody>
        </table>
        <div style={{ padding: "12px 16px", font: "500 12px var(--font-body)", color: "var(--ink-3)" }}>
          Mostrando {rows.length} de {source.length} usuarios
        </div>
      </Panel>
      {editing !== null && <Modal title={editing.id ? "Editar usuario" : "Registrar usuario"} onClose={() => setEditing(null)}>
        <MemberForm member={editing.id ? editing : null} onSave={save} onCancel={() => setEditing(null)}/>
      </Modal>}
    </div>
  );
}

function MemberForm({ member, onSave, onCancel }) {
  const [form, setForm] = React.useState(() => ({
    id: member?.id || "",
    name: member?.n || "",
    dni: member?.dni || "",
    email: member?.email || "",
    phone: member?.tel || "",
  }));
  const setField = (k, v) => setForm(prev => ({ ...prev, [k]: v }));
  const submit = (e) => {
    e.preventDefault();
    onSave(form);
  };
  return <form onSubmit={submit}>
    <div className="field"><label>Nombre completo</label><input value={form.name} onChange={e => setField("name", e.target.value)}/></div>
    <div className="row-2">
      <div className="field"><label>DNI</label><input value={form.dni} onChange={e => setField("dni", e.target.value)}/></div>
      <div className="field"><label>Celular</label><input value={form.phone} onChange={e => setField("phone", e.target.value)}/></div>
    </div>
    <div className="field"><label>Email</label><input value={form.email} onChange={e => setField("email", e.target.value)}/></div>
    <div className="modal-foot inline"><Btn kind="ghost" type="button" onClick={onCancel}>Cancelar</Btn><Btn kind="primary" type="submit">Guardar</Btn></div>
  </form>;
}

function UserDetail({ user, onBack, go }) {
  const u = user;
  return (
    <div className="content-wrap">
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
        <Btn kind="ghost" leading={I.back} onClick={onBack}>Volver a Usuarios</Btn>
        <span className="spacer" style={{ flex: 1 }}/>
        <Btn kind="ghost" leading={I.cash} onClick={() => go("pagos")}>Registrar pago</Btn>
        <Btn kind="danger-soft" leading={I.trash}>Dar de baja lógica</Btn>
      </div>

      <div className="grid cols-2">
        <Panel title="Datos del usuario">
          <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
            <Avatar name={u.n} size={60}/>
            <div>
              <div style={{ font: "800 19px var(--font-display)", letterSpacing: "-0.03em" }}>{u.n}</div>
              <div style={{ font: "500 12.5px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>DNI {u.dni}</div>
            </div>
          </div>
          <div className="divider"/>
          {[["Celular", u.tel], ["Correo", u.email], ["Entrenador asignado", u.trainer], ["Asistencia (30 días)", `${u.asis} días`]].map(([l, v]) => (
            <div key={l} style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", font: "500 13px var(--font-body)" }}>
              <span style={{ color: "var(--ink-2)" }}>{l}</span><span style={{ fontWeight: 600 }}>{v}</span>
            </div>
          ))}
        </Panel>

        <Panel title="Membresía actual">
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <StatusBadge st={u.st}/>
            <span style={{ font: "700 15px var(--font-display)" }}>Plan {u.plan}</span>
          </div>
          <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)", marginTop: 10 }}>
            {u.venc !== "—" ? `Vence el ${u.venc}` : "Sin membresía activa"}
          </div>
          <div className="bar-track" style={{ marginTop: 12 }}>
            <i style={{ width: u.st === "active" ? "62%" : u.st === "grace" ? "8%" : "0%",
                        background: u.st === "expired" || u.st === "pending" ? "var(--danger)" : "var(--ink)" }}/>
          </div>
          <div style={{ marginTop: 16 }}>
            <Btn kind="primary" block leading={I.cash} onClick={() => go("pagos")}>Registrar pago en efectivo</Btn>
          </div>
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
// PAGOS Y ACREDITACIONES  (WEB-04)
// ═══════════════════════════════════════════════════════════════
function Pagos({ app }) {
  const [tab, setTab] = React.useState("pend");
  const [message, setMessage] = React.useState("");
  const [error, setError] = React.useState("");
  const pending = app?.pendingPayments || [];
  const pendingRows = pending.length ? pending.map(p => ({
    id: p.id,
    n: p.membership?.user?.nombre_completo || p.membership?.user?.email || "Socio",
    m: `S/ ${Number(p.monto || 0).toFixed(2)}`,
    k: String(p.metodo || "manual").replace("MANUAL_", ""),
    t: p.timestamp ? new Date(p.timestamp).toLocaleString() : "Pendiente",
    receipt: p.comprobante_url,
  })) : PENDING_ACCRED;
  const tabs = [
    { id: "pend", l: `Pendientes (${pendingRows.length})` },
    { id: "dia",  l: "Cobros del día" },
  ];
  const totalDia = PAYMENTS_TODAY.reduce((s, p) => s + p.m, 0);
  const resolve = async (id, status) => {
    if (!app?.resolvePayment || !pending.length) return;
    setError(""); setMessage("");
    try {
      await app.resolvePayment(id, status);
      setMessage(status === "APPROVED" ? "Pago aprobado." : "Pago rechazado.");
    } catch (e) {
      setError(e.message || "No se pudo resolver el pago.");
    }
  };
  return (
    <div className="content-wrap">
      <ErrorBlock message={error}/>
      {message && <div className="state-block ok">{message}</div>}
      <div className="seg" role="tablist" aria-label="Vista de pagos" style={{ marginBottom: 16 }}>
        {tabs.map(t => (
          <button key={t.id} role="tab" aria-selected={tab === t.id} onClick={() => setTab(t.id)}>{t.l}</button>
        ))}
      </div>

      {tab === "pend" && (
        <div className="grid" style={{ gap: 14 }}>
          {pendingRows.map(a => (
            <div className="panel pad" key={a.id} style={{ display: "flex", gap: 16, alignItems: "center" }}>
              <Avatar name={a.n} size={46}/>
              <div style={{ flex: 1 }}>
                <div style={{ font: "700 15px var(--font-display)", letterSpacing: "-0.02em" }}>{a.n}</div>
                <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>
                  {a.m} · {a.k} · {a.t}
                </div>
              </div>
              <div style={{
                width: 120, height: 72, borderRadius: 12, flexShrink: 0,
                background: "linear-gradient(135deg,#2a4d70,#1a2a3f)", color: "rgba(255,255,255,.8)",
                display: "grid", placeItems: "center", font: "600 11px var(--font-mono)",
              }}>Comprobante</div>
              <div style={{ display: "flex", gap: 8 }}>
                <Btn kind="ghost" onClick={() => resolve(a.id, "REJECTED")}>Rechazar</Btn>
                <Btn kind="success" leading={I.check} onClick={() => resolve(a.id, "APPROVED")}>Aprobar {a.m}</Btn>
              </div>
            </div>
          ))}
        </div>
      )}

      {tab === "dia" && (
        <Panel title="Cobros registrados hoy" sub={`Total S/ ${totalDia.toLocaleString()}`} bodyPad={false}>
          <table className="tbl">
            <thead><tr><th>Hora</th><th>Usuario</th><th>Método</th><th>Registrado por</th><th className="num">Monto</th></tr></thead>
            <tbody>
              {PAYMENTS_TODAY.map((p, i) => (
                <tr key={i}>
                  <td style={{ font: "600 13px var(--font-mono)" }}>{p.t}</td>
                  <td className="cell-main">{p.n}</td>
                  <td><Badge>{p.k}</Badge></td>
                  <td style={{ color: "var(--ink-2)" }}>{p.by}</td>
                  <td className="num" style={{ font: "700 14px var(--font-display)" }}>S/ {p.m}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Panel>
      )}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CONTROL DE ASISTENCIA  (WEB-05)
// ═══════════════════════════════════════════════════════════════
function Asistencia({ app, go }) {
  const [dni, setDni] = React.useState("");
  const [result, setResult] = React.useState(null);
  const [error, setError] = React.useState("");
  const verify = async (e) => {
    e.preventDefault();
    setError("");
    setResult(null);
    try {
      const data = await app.simulateAccess(dni.trim());
      setResult(data);
    } catch (err) {
      setError(err.message || "No se pudo verificar el acceso.");
    }
  };
  const denied = ATTENDANCE_LOG.filter(a => !a.ok).length;
  return (
    <div className="content-wrap">
      <ErrorBlock message={error}/>
      <Panel title="Verificacion real de acceso" sub="DNI o QR simulado contra backend">
        <form onSubmit={verify} style={{ display: "grid", gridTemplateColumns: "1fr auto", gap: 10, alignItems: "end" }}>
          <div className="field" style={{ marginBottom: 0 }}>
            <label>DNI del socio</label>
            <input value={dni} onChange={e => setDni(e.target.value)} placeholder="Ej. 72345678" required/>
          </div>
          <Btn kind="primary" leading={I.scan} type="submit">Verificar</Btn>
        </form>
        {result && (
          <div className="state-block" style={{ marginTop: 14 }}>
            <div style={{ display: "flex", gap: 12, alignItems: "center", justifyContent: "space-between" }}>
              <div>
                <Badge kind={result.verdict === "GREEN" ? "ok" : "danger"} dot>
                  {result.verdict === "GREEN" ? "Acceso concedido" : "Acceso denegado"}
                </Badge>
                <div style={{ marginTop: 8, color: "var(--ink)" }}>{result.member?.fullName || "Socio"}</div>
                <div style={{ color: "var(--ink-2)" }}>{result.reason || "Verificacion completada."}</div>
              </div>
              {result.verdict !== "GREEN" && <Btn kind="accent" onClick={() => go?.("caja")}>Vender membresia</Btn>}
            </div>
          </div>
        )}
      </Panel>
      <div className="grid k-2-1">
        <Panel title="Escáner de acceso" sub="cámara de recepción">
          <div style={{
            aspectRatio: "16 / 10", borderRadius: 14, overflow: "hidden", position: "relative",
            background: "radial-gradient(600px 300px at 50% 45%, #2a2a2a, #050505)",
            display: "grid", placeItems: "center",
          }}>
            <div style={{ width: 180, height: 180, position: "relative" }}>
              {["tl","tr","bl","br"].map(c => (
                <span key={c} aria-hidden="true" style={{
                  position: "absolute", width: 34, height: 34,
                  border: "3px solid var(--accent)",
                  borderRadius: c === "tl" ? "12px 0 0 0" : c === "tr" ? "0 12px 0 0" : c === "bl" ? "0 0 0 12px" : "0 0 12px 0",
                  borderRight: c[1] === "l" ? 0 : "3px solid var(--accent)",
                  borderLeft: c[1] === "r" ? 0 : "3px solid var(--accent)",
                  borderBottom: c[0] === "t" ? 0 : "3px solid var(--accent)",
                  borderTop: c[0] === "b" ? 0 : "3px solid var(--accent)",
                  top: c[0] === "t" ? 0 : "auto", bottom: c[0] === "b" ? 0 : "auto",
                  left: c[1] === "l" ? 0 : "auto", right: c[1] === "r" ? 0 : "auto",
                }}/>
              ))}
            </div>
            <div style={{ position: "absolute", bottom: 18, color: "rgba(255,255,255,.6)", font: "600 12px var(--font-mono)", textTransform: "uppercase", letterSpacing: ".08em" }}>
              Apunta al QR del usuario
            </div>
          </div>
          <div style={{ display: "flex", gap: 10, marginTop: 14 }}>
            <Btn kind="ghost" block leading={I.search}>Buscar por DNI</Btn>
            <Btn kind="primary" block leading={I.scan}>Ingreso manual</Btn>
          </div>
        </Panel>

        <Panel title="Log del día" sub={`${ATTENDANCE_LOG.length} ingresos · ${denied} denegados`} bodyPad={false}>
          {ATTENDANCE_LOG.map((a, i) => (
            <div className="lrow" key={i}>
              <span className="l-ic" style={{ color: a.ok ? "var(--success)" : "var(--danger)" }}>
                {a.ok ? I.check : I.close}
              </span>
              <div className="l-main">
                <div className="l-t">{a.n}</div>
                <div className="l-s">{a.via}{!a.ok && " · membresía vencida"}</div>
              </div>
              <span className="l-time">{a.t}</span>
            </div>
          ))}
        </Panel>
      </div>

      <Panel title="Asistencia por franja horaria">
        <Bars data={[
          { d: "6-8", v: 35 }, { d: "8-10", v: 22 }, { d: "10-12", v: 12 },
          { d: "12-14", v: 9 }, { d: "14-17", v: 14 }, { d: "17-19", v: 40, hot: true }, { d: "19-22", v: 28 },
        ]} unit="%"/>
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// PRODUCTOS / INVENTARIO
// ═══════════════════════════════════════════════════════════════
function Productos({ app }) {
  const [editing, setEditing] = React.useState(null);
  const [message, setMessage] = React.useState("");
  const [error, setError] = React.useState("");
  const rows = app?.products?.length
    ? app.products
    : PRODUCTS.map(p => normalizeProduct({ id: p.id, nombre: p.n, categoria: p.cat, precio_venta: p.p, stock_actual: p.stock }));
  const low = rows.filter(p => p.stock < 15).length;
  const valor = rows.reduce((s, p) => s + p.price * p.stock, 0);
  const save = async (form) => {
    setError(""); setMessage("");
    try {
      await app.saveProduct(form);
      setEditing(null);
      setMessage("Producto guardado.");
    } catch (e) {
      setError(e.message || "No se pudo guardar el producto.");
    }
  };
  const deactivate = async (id) => {
    setError(""); setMessage("");
    try {
      await app.deactivateProduct(id);
      setMessage("Producto desactivado.");
    } catch (e) {
      setError(e.message || "No se pudo desactivar el producto.");
    }
  };
  return (
    <div className="content-wrap">
      <ErrorBlock message={error}/>
      {message && <div className="state-block ok">{message}</div>}
      <div className="grid cols-3">
        <Kpi icon="box" value={rows.filter(p => p.visible && p.status !== "inactivo").length} label="Productos activos" delta="catálogo real" dir="up"/>
        <Kpi icon="cash" value={`S/ ${valor.toLocaleString()}`} label="Valor del inventario" delta="" dir="flat"/>
        <Kpi icon="alert" value={low} label="Con bajo stock" delta="reponer pronto" dir="down"/>
      </div>

      <Panel title="Inventario" sub="catálogo de venta"
             action={<Btn kind="primary" size="sm" leading={I.plus} onClick={() => setEditing({})}>Nuevo producto</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Producto</th><th>Categoría</th><th className="num">Precio</th><th className="num">Stock</th><th></th></tr></thead>
          <tbody>
            {rows.map(p => (
              <tr key={p.id} className="clickable" onClick={() => setEditing(p)}>
                <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span style={{ width: 38, height: 38, borderRadius: 10, background: "var(--surface-2)", display: "grid", placeItems: "center", fontSize: 19 }}>{I.box}</span>
                  <span><span className="cell-main">{p.name}</span><span className="cell-sub">{p.sku || "Sin SKU"}</span></span>
                </div></td>
                <td style={{ color: "var(--ink-2)" }}>{p.category || "General"}</td>
                <td className="num" style={{ font: "700 14px var(--font-display)" }}>S/ {p.price}</td>
                <td className="num">{p.stock}</td>
                <td style={{ textAlign: "right" }}>
                  <div style={{ display: "inline-flex", gap: 8, alignItems: "center" }}>
                    {p.stock < 15 ? <Badge kind="warn" dot>Bajo stock</Badge> : <Badge kind="ok" dot>OK</Badge>}
                    <Btn kind="ghost" size="sm" onClick={(e) => { e.stopPropagation(); setEditing(p); }}>Editar</Btn>
                    {p.id && <Btn kind="danger-soft" size="sm" onClick={(e) => { e.stopPropagation(); deactivate(p.id); }}>Baja</Btn>}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>
      {editing !== null && <Modal title={editing.id ? "Editar producto" : "Nuevo producto"} onClose={() => setEditing(null)}>
        <ProductForm product={editing.id ? editing : null} onSave={save} onCancel={() => setEditing(null)}/>
      </Modal>}
    </div>
  );
}

function ProductForm({ product, onSave, onCancel }) {
  const [form, setForm] = React.useState(() => ({
    id: product?.id || "",
    name: product?.name || "",
    description: product?.description || "",
    category: product?.category || "General",
    sku: product?.sku || "",
    price: product?.price || 0,
    cost: product?.cost || 0,
    stock: product?.stock || 0,
    minStock: product?.minStock || 5,
    imageUrl: product?.imageUrl || "",
    status: product?.status || "activo",
    visible: product?.visible ?? true,
  }));
  const setField = (k, v) => setForm(prev => ({ ...prev, [k]: v }));
  const submit = (e) => {
    e.preventDefault();
    onSave(form);
  };
  return (
    <form onSubmit={submit}>
      <div className="row-2">
        <div className="field"><label>Nombre</label><input value={form.name} onChange={e => setField("name", e.target.value)} required/></div>
        <div className="field"><label>SKU</label><input value={form.sku} onChange={e => setField("sku", e.target.value)}/></div>
      </div>
      <div className="field"><label>Descripcion</label><textarea rows="2" value={form.description} onChange={e => setField("description", e.target.value)}/></div>
      <div className="row-2">
        <div className="field"><label>Categoria</label><input value={form.category} onChange={e => setField("category", e.target.value)}/></div>
        <div className="field"><label>Estado</label><select value={form.status} onChange={e => setField("status", e.target.value)}><option value="activo">Activo</option><option value="inactivo">Inactivo</option></select></div>
      </div>
      <div className="row-2">
        <div className="field"><label>Precio venta</label><input type="number" step="0.01" value={form.price} onChange={e => setField("price", e.target.value)} required/></div>
        <div className="field"><label>Precio compra</label><input type="number" step="0.01" value={form.cost} onChange={e => setField("cost", e.target.value)}/></div>
      </div>
      <div className="row-2">
        <div className="field"><label>Stock</label><input type="number" value={form.stock} onChange={e => setField("stock", e.target.value)}/></div>
        <div className="field"><label>Stock minimo</label><input type="number" value={form.minStock} onChange={e => setField("minStock", e.target.value)}/></div>
      </div>
      <label className="check-inline"><input type="checkbox" checked={form.visible} onChange={e => setField("visible", e.target.checked)}/> Visible en POS</label>
      <div className="modal-foot inline">
        <Btn kind="ghost" type="button" onClick={onCancel}>Cancelar</Btn>
        <Btn kind="primary" type="submit">Guardar</Btn>
      </div>
    </form>
  );
}

// ═══════════════════════════════════════════════════════════════
// REPORTES Y ANALÍTICA  (WEB-08)
// ═══════════════════════════════════════════════════════════════
function Reportes({ app }) {
  const summary = app?.dashboardSummary || {};
  const revenue = Number(summary.revenueToday || 0);
  const active = Number(summary.activeMembers || 0);
  const totalMemberships = Number(summary.memberships || active || 1);
  const retention = Math.min(100, Math.round((active / Math.max(totalMemberships, 1)) * 1000) / 10);
  return (
    <div className="content-wrap">
      <div className="grid cols-4">
        <Kpi icon="trend" value={`${retention}%`} label="Retencion activa" delta="tenant real" dir="up"/>
        <Kpi icon="cash" value={`S/ ${revenue.toLocaleString()}`} label="Ingresos hoy" delta={`${summary.paymentsToday || 0} membresias`} dir="flat"/>
        <Kpi icon="users" value={active} label="Socios activos" delta={`${summary.memberships || 0} historicos`} dir="up"/>
        <Kpi icon="alert" value={summary.expiredSoon || 0} label="Por vencer" delta="proximos 7 dias" dir="down"/>
      </div>
      <div className="grid cols-4" style={{ display: "none" }}>
        <Kpi icon="trend" value="90.5%" label="Retención 90 días" delta="+4.8 pp" dir="up"/>
        <Kpi icon="scan" value="18×" label="Asistencia prom./mes" delta="por usuario" dir="flat"/>
        <Kpi icon="users" value="6" label="Nuevos este mes" delta="+2" dir="up"/>
        <Kpi icon="alert" value="4" label="Bajas este mes" delta="vs 1 anterior" dir="down"/>
      </div>

      <div className="grid cols-2" style={{ marginTop: 16 }}>
        <Panel title="Ingresos · últimos 6 meses" sub="miles de soles">
          <div style={{ padding: "8px 4px 0" }}><Bars data={REVENUE_6M}/></div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginTop: 14 }}>
            <span style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)" }}>Mayo (parcial)</span>
            <span style={{ font: "800 22px var(--font-display)", letterSpacing: "-0.03em" }}>S/ 21.400</span>
          </div>
        </Panel>
        <Panel title="Ingresos por método de pago">
          <Donut segments={PAY_METHODS}/>
        </Panel>
      </div>

      <Panel title="Retención de membresías">
        <div style={{ font: "500 14px var(--font-body)", color: "var(--ink-2)" }}>
          <b style={{ color: "var(--ink)" }}>38 de 42</b> usuarios renovaron su membresía este mes
          (90.5%), con <b style={{ color: "var(--success)" }}>+6 nuevos</b> registros.
        </div>
        <div className="bar-track tall" style={{ marginTop: 12, height: 12 }}>
          <i style={{ width: "90.5%", background: "var(--accent)" }}/>
        </div>
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CONFIGURACIÓN DEL GIMNASIO  (WEB-09)
// ═══════════════════════════════════════════════════════════════
function Config({ app }) {
  const tenant = app?.tenantSettings || normalizeTenantSettings(GYM);
  const [form, setForm] = React.useState(() => ({
    name: tenant?.name || "",
    logoUrl: tenant?.logoUrl || "",
    address: tenant?.address || "",
    phone: tenant?.phone || "",
    schedule: tenant?.schedule || "",
    description: tenant?.description || "",
    primaryColor: tenant?.primaryColor || "#111827",
    secondaryColor: tenant?.secondaryColor || "#2F6BFF",
    accentColor: tenant?.accentColor || "#D2FF3A",
    graceDays: tenant?.graceDays ?? 1,
    alertDays: tenant?.alertDays ?? 7,
  }));
  const [saving, setSaving] = React.useState(false);
  const [message, setMessage] = React.useState("");
  const [error, setError] = React.useState("");

  React.useEffect(() => {
    if (!app?.tenantSettings) return;
    setForm({
      name: app.tenantSettings.name || "",
      logoUrl: app.tenantSettings.logoUrl || "",
      address: app.tenantSettings.address || "",
      phone: app.tenantSettings.phone || "",
      schedule: app.tenantSettings.schedule || "",
      description: app.tenantSettings.description || "",
      primaryColor: app.tenantSettings.primaryColor || "#111827",
      secondaryColor: app.tenantSettings.secondaryColor || "#2F6BFF",
      accentColor: app.tenantSettings.accentColor || "#D2FF3A",
      graceDays: app.tenantSettings.graceDays ?? 1,
      alertDays: app.tenantSettings.alertDays ?? 7,
    });
  }, [app?.tenantSettings?.id]);

  const setField = (key, value) => setForm((prev) => ({ ...prev, [key]: value }));
  const save = async () => {
    setSaving(true);
    setError("");
    setMessage("");
    try {
      await app.saveTenantSettings({
        nombre: form.name,
        logoUrl: form.logoUrl,
        direccion: form.address,
        telefono: form.phone,
        horario: form.schedule,
        descripcion: form.description,
        colorPrimario: form.primaryColor,
        colorSecundario: form.secondaryColor,
        colorAcento: form.accentColor,
        diasGracia: Number(form.graceDays),
        diasAlertaVencimiento: Number(form.alertDays),
      });
      setMessage("Configuración guardada correctamente.");
    } catch (e) {
      setError(e.message || "No se pudo guardar la configuración.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="content-wrap">
      <ErrorBlock message={error}/>
      {message && <div className="state-block ok">{message}</div>}
      <div className="grid cols-2">
        <Panel title="Datos del gimnasio">
          <div className="field"><label>Nombre comercial</label><input value={form.name} onChange={(e) => setField("name", e.target.value)}/></div>
          <div className="field"><label>Logo URL</label><input value={form.logoUrl} onChange={(e) => setField("logoUrl", e.target.value)}/></div>
          <div className="row-2">
            <div className="field"><label>Días de gracia</label><input type="number" min="0" value={form.graceDays} onChange={(e) => setField("graceDays", e.target.value)}/></div>
            <div className="field"><label>Teléfono / WhatsApp</label><input value={form.phone} onChange={(e) => setField("phone", e.target.value)}/></div>
          </div>
          <div className="field"><label>Dirección</label><input value={form.address} onChange={(e) => setField("address", e.target.value)}/></div>
          <div className="field"><label>Horario de atención</label><input value={form.schedule} onChange={(e) => setField("schedule", e.target.value)}/></div>
          <div className="field"><label>Descripción</label><textarea rows="3" value={form.description} onChange={(e) => setField("description", e.target.value)}/></div>
        </Panel>

        <div className="grid" style={{ gap: 16, alignContent: "start" }}>
          <Panel title="Reglas operativas">
            <div className="row-2">
              <div className="field"><label>Día de gracia</label><input type="number" min="0" value={form.graceDays} onChange={(e) => setField("graceDays", e.target.value)}/></div>
              <div className="field"><label>Aviso pre-vencimiento</label><input type="number" min="1" value={form.alertDays} onChange={(e) => setField("alertDays", e.target.value)}/></div>
            </div>
            <div className="field" style={{ marginBottom: 0 }}>
              <label>Recordatorio post-vencimiento</label>
              <select defaultValue="Diario"><option>Diario</option><option>Cada 2 días</option></select>
            </div>
          </Panel>
          <Panel title="Identidad">
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <span style={{ width: 64, height: 64, borderRadius: 14, background: form.primaryColor || "var(--ink)", color: form.accentColor || "var(--accent)", display: "grid", placeItems: "center", font: "800 24px var(--font-display)" }}>{(form.name || "G")[0]}</span>
              <div style={{ flex: 1 }}>
                <div className="row-2">
                  <div className="field"><label>Primario</label><input type="color" value={form.primaryColor} onChange={(e) => setField("primaryColor", e.target.value)}/></div>
                  <div className="field"><label>Secundario</label><input type="color" value={form.secondaryColor} onChange={(e) => setField("secondaryColor", e.target.value)}/></div>
                </div>
                <div className="field" style={{ marginBottom: 0 }}><label>Acento</label><input type="color" value={form.accentColor} onChange={(e) => setField("accentColor", e.target.value)}/></div>
              </div>
            </div>
          </Panel>
        </div>
      </div>
      <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 16 }}>
        <Btn kind="primary" leading={I.check} disabled={saving} onClick={save}>{saving ? "Guardando..." : "Guardar cambios"}</Btn>
      </div>
    </div>
  );
}

Object.assign(window, { Usuarios, Pagos, Asistencia, Productos, Reportes, Config });

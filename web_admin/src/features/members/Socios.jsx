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

window.Usuarios = Usuarios;

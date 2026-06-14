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
      setError(e.message || "No se pudo guardar the plan.");
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
                    <Btn kind="ghost" size="sm" onClick={() => setEditingPlan(p)}>Editar</Btn>
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

window.Membresias = Membresias;

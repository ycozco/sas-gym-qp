function PlanesSaaS({ app }) {
  const tenants = app?.tenants || [];
  const planCounts = tenants.reduce((acc, t) => {
    const plan = t.saas_plan || t.plan_saas || "Pro";
    acc[plan] = (acc[plan] || 0) + 1;
    return acc;
  }, {});

  const [localPlans, setLocalPlans] = React.useState(() => {
    try {
      const stored = localStorage.getItem("sasgym.saas_plans");
      if (stored) return JSON.parse(stored);
    } catch (e) {}
    return SAAS_PLANS;
  });
  const [editingPlan, setEditingPlan] = React.useState(null);

  const savePlansToStorage = (updatedPlans) => {
    setLocalPlans(updatedPlans);
    try {
      localStorage.setItem("sasgym.saas_plans", JSON.stringify(updatedPlans));
    } catch (e) {}
  };

  const plans = localPlans.map(p => ({
    ...p,
    gimnasios: tenants.length ? (planCounts[p.n] || 0) : (p.gimnasios || 0)
  }));

  const handleSavePlan = (e) => {
    e.preventDefault();
    if (!editingPlan.n || !editingPlan.price || !editingPlan.limite) return;
    
    let nextPlans;
    if (editingPlan._original) {
      nextPlans = localPlans.map(p => p.n === editingPlan._original.n ? { n: editingPlan.n, price: editingPlan.price, limite: editingPlan.limite, feats: editingPlan.feats, gimnasios: p.gimnasios || 0 } : p);
    } else {
      nextPlans = [...localPlans, { n: editingPlan.n, price: editingPlan.price, limite: editingPlan.limite, feats: editingPlan.feats, gimnasios: 0 }];
    }
    savePlansToStorage(nextPlans);
    setEditingPlan(null);
  };

  const handleDeletePlan = (planToDelete) => {
    if (confirm(`¿Está seguro de eliminar el plan SaaS "${planToDelete.n}"?`)) {
      const nextPlans = localPlans.filter(p => p.n !== planToDelete.n);
      savePlansToStorage(nextPlans);
    }
  };

  return (
    <div className="content-wrap">
      <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: 16 }}>
        <Btn kind="primary" size="sm" leading={I.plus} onClick={() => setEditingPlan({ n: "", price: "S/ ", limite: "Hasta 100 usuarios", feats: "Detalle de beneficios" })}>Nuevo Plan SaaS</Btn>
      </div>

      <div className="grid cols-3">
        {plans.map((p, i) => (
          <div className="panel pad" key={p.n} style={p.n === "Pro" ? { borderColor: "var(--ink)", borderWidth: 2 } : null}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <Badge kind={p.n === "Enterprise" ? "accent" : p.n === "Pro" ? "info" : ""}>{p.n}</Badge>
              {p.n === "Pro" && <span style={{ font: "600 10.5px var(--font-mono)", color: "var(--ink-3)", textTransform: "uppercase", letterSpacing: ".06em" }}>Más usado</span>}
            </div>
            <div style={{ font: "800 30px var(--font-display)", letterSpacing: "-0.04em", marginTop: 14 }}>
              {p.price}<span style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}> /mes</span>
            </div>
            <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>{p.limite}</div>
            <div className="divider"/>
            <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}>{p.feats}</div>
            <div style={{ font: "700 13px var(--font-display)", marginTop: 12 }}>{p.gimnasios} gimnasios en este plan</div>
            <div style={{ marginTop: 14, display: "flex", gap: 8 }}>
              <Btn kind="ghost" leading={I.edit} onClick={() => setEditingPlan({ ...p, _original: p })} style={{ flex: 1 }}>Editar</Btn>
              <Btn kind="ghost" onClick={() => handleDeletePlan(p)} style={{ color: "var(--warn)" }}>Eliminar</Btn>
            </div>
          </div>
        ))}
      </div>
      <Panel title="Facturación de la plataforma" sub="cobro mensual a cada gimnasio">
        <div style={{ font: "500 14px var(--font-body)", color: "var(--ink-2)" }}>
          Cada gimnasio paga su suscripción según el plan contratado. El ingreso
          recurrente total (MRR) se calcula sumando los planes activos de las
          instancias de la red.
        </div>
      </Panel>

      {editingPlan && (
        <Modal title={editingPlan._original ? "Editar Plan SaaS" : "Nuevo Plan SaaS"} onClose={() => setEditingPlan(null)}>
          <form onSubmit={handleSavePlan}>
            <div className="field">
              <label>Nombre del Plan</label>
              <input value={editingPlan.n} onChange={e => setEditingPlan({ ...editingPlan, n: e.target.value })} required />
            </div>
            <div className="field">
              <label>Precio Mensual (ej: S/ 399)</label>
              <input value={editingPlan.price} onChange={e => setEditingPlan({ ...editingPlan, price: e.target.value })} required />
            </div>
            <div className="field">
              <label>Límite de Usuarios (ej: Hasta 350 usuarios)</label>
              <input value={editingPlan.limite} onChange={e => setEditingPlan({ ...editingPlan, limite: e.target.value })} required />
            </div>
            <div className="field">
              <label>Beneficios / Características</label>
              <textarea rows="3" value={editingPlan.feats} onChange={e => setEditingPlan({ ...editingPlan, feats: e.target.value })} required />
            </div>
            <div className="modal-foot inline">
              <Btn type="button" kind="ghost" onClick={() => setEditingPlan(null)}>Cancelar</Btn>
              <Btn type="submit" kind="primary">Guardar Plan</Btn>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}

window.PlanesSaaS = PlanesSaaS;

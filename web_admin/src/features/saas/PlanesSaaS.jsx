import React from 'react';
import { Badge, Btn, I, Modal, Panel } from '../../../shared.jsx';

function PlanesSaaS({ app }) {
  const tenants = app?.tenants || [];
  const plans = app?.saasPlans || [];
  const planCounts = tenants.reduce((acc, tenant) => {
    const code = tenant.plan_saas || tenant.saas_plan?.code || 'PRO';
    acc[code] = (acc[code] || 0) + 1;
    return acc;
  }, {});
  const [editingPlan, setEditingPlan] = React.useState(null);

  const hydratedPlans = plans.map((plan) => ({
    ...plan,
    gimnasios: planCounts[plan.code] || 0,
  }));

  const handleSavePlan = async (e) => {
    e.preventDefault();
    if (!editingPlan?.name || !editingPlan?.userLimit) return;
    await app.saveSaasPlan({
      code: editingPlan.code,
      name: editingPlan.name,
      description: editingPlan.description,
      price: editingPlan.price,
      userLimit: editingPlan.userLimit,
      features: editingPlan.features,
      active: editingPlan.active ?? true,
    });
    setEditingPlan(null);
  };

  const handleDeletePlan = async (plan) => {
    if (confirm(`¿Está seguro de desactivar el plan SaaS "${plan.name}"?`)) {
      await app.deactivateSaasPlan(plan.code);
    }
  };

  return (
    <div className="content-wrap">
      <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: 16 }}>
        <Btn
          kind="primary"
          size="sm"
          leading={I.plus}
          onClick={() =>
            setEditingPlan({
              code: "",
              name: "",
              description: "",
              price: 0,
              userLimit: 100,
              features: "",
              active: true,
            })
          }
        >
          Nuevo Plan SaaS
        </Btn>
      </div>

      <div className="grid cols-3">
        {hydratedPlans.map((plan) => (
          <div
            className="panel pad"
            key={plan.code}
            style={plan.code === "PRO" ? { borderColor: "var(--ink)", borderWidth: 2 } : null}
          >
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <Badge kind={plan.code === "ENTERPRISE" ? "accent" : plan.code === "PRO" ? "info" : ""}>
                {plan.name}
              </Badge>
              {plan.code === "PRO" && (
                <span style={{ font: "600 10.5px var(--font-mono)", color: "var(--ink-3)", textTransform: "uppercase", letterSpacing: ".06em" }}>
                  Más usado
                </span>
              )}
            </div>
            <div style={{ font: "800 30px var(--font-display)", letterSpacing: "-0.04em", marginTop: 14 }}>
              S/ {Number(plan.price || 0).toFixed(2)}
              <span style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}> /mes</span>
            </div>
            <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>
              Hasta {plan.userLimit} usuarios
            </div>
            <div className="divider"/>
            <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}>{plan.features}</div>
            <div style={{ font: "700 13px var(--font-display)", marginTop: 12 }}>
              {plan.gimnasios} gimnasios en este plan
            </div>
            <div style={{ marginTop: 14, display: "flex", gap: 8 }}>
              <Btn kind="ghost" leading={I.edit} onClick={() => setEditingPlan({ ...plan })} style={{ flex: 1 }}>
                Editar
              </Btn>
              <Btn kind="ghost" onClick={() => handleDeletePlan(plan)} style={{ color: "var(--warn)" }}>
                Desactivar
              </Btn>
            </div>
          </div>
        ))}
        {hydratedPlans.length === 0 && <div className="empty">No hay planes SaaS persistidos en backend.</div>}
      </div>

      <Panel title="Facturación de la plataforma" sub="cobro mensual a cada gimnasio">
        <div style={{ font: "500 14px var(--font-body)", color: "var(--ink-2)" }}>
          Cada gimnasio paga su suscripción según el plan contratado. El ingreso
          recurrente total (MRR) se calcula sumando los planes activos de las
          instancias de la red.
        </div>
      </Panel>

      {editingPlan && (
        <Modal title={editingPlan.code ? "Editar Plan SaaS" : "Nuevo Plan SaaS"} onClose={() => setEditingPlan(null)}>
          <form onSubmit={handleSavePlan}>
            {!editingPlan.code && (
              <div className="field">
                <label>Código</label>
                <input
                  value={editingPlan.code}
                  onChange={e => setEditingPlan({ ...editingPlan, code: e.target.value.toUpperCase() })}
                  required
                />
              </div>
            )}
            <div className="field">
              <label>Nombre del Plan</label>
              <input value={editingPlan.name} onChange={e => setEditingPlan({ ...editingPlan, name: e.target.value })} required />
            </div>
            <div className="field">
              <label>Descripción</label>
              <input value={editingPlan.description} onChange={e => setEditingPlan({ ...editingPlan, description: e.target.value })} />
            </div>
            <div className="field">
              <label>Precio Mensual</label>
              <input type="number" value={editingPlan.price} onChange={e => setEditingPlan({ ...editingPlan, price: Number(e.target.value) })} required />
            </div>
            <div className="field">
              <label>Límite de Usuarios</label>
              <input type="number" value={editingPlan.userLimit} onChange={e => setEditingPlan({ ...editingPlan, userLimit: Number(e.target.value) })} required />
            </div>
            <div className="field">
              <label>Beneficios / Características</label>
              <textarea rows="3" value={editingPlan.features} onChange={e => setEditingPlan({ ...editingPlan, features: e.target.value })} required />
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

export { PlanesSaaS };

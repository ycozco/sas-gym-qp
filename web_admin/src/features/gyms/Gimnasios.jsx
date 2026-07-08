import React from 'react';
import { GYMS } from '../../../data.jsx';
import { Badge, Btn, I, Panel } from '../../../shared.jsx';

function Gimnasios({ app }) {
  const [q, setQ] = React.useState("");
  const [filter, setFilter] = React.useState("Todos");
  const tenantRows = app?.tenants?.length ? app.tenants.map(t => ({
    id: t.id,
    n: t.nombre || t.name || "Gimnasio",
    city: t.direccion || t.slug || "Sin direccion",
    plan: t.saas_plan || t.plan_saas || "Pro",
    usuarios: t._count?.users || t.usuarios || 0,
    alta: t.created_at ? new Date(t.created_at).toLocaleDateString() : (t.alta || "-"),
    st: String(t.estado || t.status || "active").toLowerCase() === "suspended" ? "suspended" : "active",
  })) : GYMS;
  const rows = tenantRows.filter(g => {
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
                <td>
                  <div style={{ display: "inline-flex", gap: 8, alignItems: "center" }}>
                    {g.st === "active" ? <Badge kind="ok" dot>Activo</Badge> : <Badge kind="danger" dot>Suspendido</Badge>}
                    {app?.toggleTenant && <Btn kind="ghost" size="sm" onClick={(e) => { e.stopPropagation(); app.toggleTenant(g.id); }}>
                      {g.st === "active" ? "Suspender" : "Activar"}
                    </Btn>}
                  </div>
                </td>
              </tr>
            ))}
            {rows.length === 0 && <tr><td colSpan="5"><div className="empty">Sin resultados para “{q}”.</div></td></tr>}
          </tbody>
        </table>
        <div style={{ padding: "12px 16px", font: "500 12px var(--font-body)", color: "var(--ink-3)" }}>
          <span>Mostrando {rows.length} de {tenantRows.length} gimnasios - multi-tenant real</span>
          <span style={{ display: "none" }}>
          Mostrando {rows.length} de {GYMS.length} gimnasios · cada uno es una instancia aislada (multi-tenant)
          </span>
        </div>
      </Panel>
    </div>
  );
}

export { Gimnasios };

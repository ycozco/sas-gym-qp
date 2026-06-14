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

window.Reportes = Reportes;

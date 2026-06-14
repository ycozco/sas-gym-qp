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

window.Finanzas = Finanzas;

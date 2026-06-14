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

window.Pagos = Pagos;

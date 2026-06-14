function Caja({ app }) {
  const [tab, setTab] = React.useState("turno");
  const [details, setDetails] = React.useState(null);
  const [sales, setSales] = React.useState(null);
  const [memberQuery, setMemberQuery] = React.useState("");
  const [memberResults, setMemberResults] = React.useState([]);
  const [selectedMember, setSelectedMember] = React.useState(null);
  const [cart, setCart] = React.useState([]);
  const [paymentMode, setPaymentMode] = React.useState("single");
  const [paymentMethod, setPaymentMethod] = React.useState("Efectivo");
  const [cashReceived, setCashReceived] = React.useState("");
  const [combined, setCombined] = React.useState({ Efectivo: "", Yape: "", Plin: "", Tarjeta: "" });
  const [openAmount, setOpenAmount] = React.useState("150");
  const [egressAmount, setEgressAmount] = React.useState("");
  const [egressReason, setEgressReason] = React.useState("");
  const [closeForm, setCloseForm] = React.useState({ efectivo: "", transferencia: "", yape: "", pos: "", obs: "" });
  const [scanDni, setScanDni] = React.useState("");
  const [scanResult, setScanResult] = React.useState(null);
  const [message, setMessage] = React.useState("");
  const [error, setError] = React.useState("");
  const [busy, setBusy] = React.useState(false);

  const products = app?.products?.length
    ? app.products.filter(p => p.visible && p.status !== "inactivo")
    : PRODUCTS.map(p => normalizeProduct({ id: p.id, nombre: p.n, categoria: p.cat, precio_venta: p.p, stock_actual: p.stock }));
  const plans = app?.membershipPlans?.length
    ? app.membershipPlans.filter(p => p.active)
    : MEMBERSHIP_PLANS.filter(p => p.on).map(p => normalizeMembershipPlan({ id: p.id, nombre: p.n, duracion_dias: parseInt(p.dur, 10) || 30, precio: p.price, activo: p.on }));
  const fallbackMovements = CAJA_MOV.map((m, i) => ({ id: i, tipo: m.tipo, monto: m.m, descripcion: m.concepto, created_at: `${TODAY.short} ${m.t}` }));
  const movements = details?.movements || fallbackMovements;
  const stats = details?.stats;
  const caja = details?.caja || null;
  const total = cart.reduce((sum, item) => sum + item.unitPrice * item.qty, 0);
  const combinedTotal = Object.values(combined).reduce((sum, value) => sum + (Number(value) || 0), 0);
  const paid = paymentMode === "combined" ? combinedTotal : (paymentMethod === "Efectivo" ? Number(cashReceived || 0) : total);
  const canCharge = cart.length > 0 && (paymentMode === "combined" ? combinedTotal >= total : paymentMethod !== "Efectivo" || Number(cashReceived || 0) >= total);

  const refreshCaja = React.useCallback(async () => {
    if (!app?.getCajaDetails) return;
    setError("");
    try {
      const nextDetails = await app.getCajaDetails();
      setDetails(nextDetails);
      const nextSales = await app.getCajaSales();
      setSales(nextSales);
      await app.reloadProducts?.();
    } catch (e) {
      setDetails(null);
      if (!String(e.message || "").includes("caja abierta")) setError(e.message);
    }
  }, [app]);

  React.useEffect(() => { refreshCaja(); }, []);

  React.useEffect(() => {
    let alive = true;
    if (!app?.searchMembers || memberQuery.trim().length < 2) {
      setMemberResults([]);
      return () => { alive = false; };
    }
    const timer = setTimeout(async () => {
      try {
        const rows = await app.searchMembers(memberQuery.trim());
        if (alive) setMemberResults(rows);
      } catch (_) {
        if (alive) setMemberResults([]);
      }
    }, 260);
    return () => { alive = false; clearTimeout(timer); };
  }, [memberQuery]);

  const addToCart = (item) => {
    setCart(prev => {
      const scoped = prev.some(c => c.type !== item.type) ? [] : prev;
      const idx = scoped.findIndex(c => c.id === item.id && c.type === item.type);
      if (idx >= 0) return scoped.map((c, i) => i === idx ? { ...c, qty: c.qty + 1 } : c);
      return [...scoped, { ...item, qty: 1 }];
    });
  };
  const updateQty = (item, delta) => {
    setCart(prev => prev.flatMap(c => {
      if (c.id !== item.id || c.type !== item.type) return [c];
      const next = c.qty + delta;
      return next <= 0 ? [] : [{ ...c, qty: next }];
    }));
  };
  const resetSale = () => {
    setCart([]);
    setSelectedMember(null);
    setMemberQuery("");
    setCashReceived("");
    setCombined({ Efectivo: "", Yape: "", Plin: "", Tarjeta: "" });
  };
  const run = async (fn, okMessage) => {
    setBusy(true); setError(""); setMessage("");
    try {
      await fn();
      setMessage(okMessage);
      await refreshCaja();
    } catch (e) {
      setError(e.message || "No se pudo completar la operación.");
    } finally {
      setBusy(false);
    }
  };
  const openShift = () => run(
    () => app.openCaja({ montoApertura: Number(openAmount || 0), observaciones: "Apertura desde panel web" }),
    "Caja abierta correctamente.",
  );
  const registerEgress = () => run(async () => {
    await app.createCajaEgress({ monto: Number(egressAmount), motivo: egressReason || "Egreso operativo", metodoPago: "efectivo" });
    setEgressAmount(""); setEgressReason("");
  }, "Egreso registrado.");
  const closeShift = () => run(async () => {
    await app.closeCaja({
      montoCierreEfectivo: Number(closeForm.efectivo || 0),
      montoCierreTransferencia: Number(closeForm.transferencia || 0),
      montoCierreYape: Number(closeForm.yape || 0),
      montoCierrePOS: Number(closeForm.pos || 0),
      observaciones: closeForm.obs,
    });
    setDetails(null); setSales(null);
  }, "Caja cerrada correctamente.");
  const charge = () => run(async () => {
    const payments = paymentMode === "combined"
      ? Object.entries(combined).filter(([, value]) => Number(value) > 0).map(([metodo, monto]) => ({ metodo, monto: Number(monto) }))
      : null;
    await app.chargePOS({
      memberDni: selectedMember?.dni || "ANONIMO",
      cartItems: cart.map(item => ({
        type: item.type,
        id: item.id,
        productId: item.type === "product" ? item.id : undefined,
        planId: item.type === "membership" ? item.id : undefined,
        name: item.name,
        qty: item.qty,
        price: item.unitPrice,
        unitPrice: item.unitPrice,
      })),
      total,
      paymentMethod: paymentMode === "combined" ? "Combinado" : paymentMethod,
      payments,
    });
    resetSale();
  }, "Venta registrada correctamente.");
  const scan = () => run(async () => {
    const result = await app.simulateAccess(scanDni.trim());
    setScanResult(result);
    if (result?.member?.dni) {
      setSelectedMember({ dni: result.member.dni, nombre_completo: result.member.name || result.member.nombre_completo });
    }
  }, "Escaneo completado.");
  const saleRows = [
    ...(sales?.membershipPayments || []).map(p => ({
      id: p.id,
      kind: "Membresía",
      who: p.membership?.user?.nombre_completo || "Socio",
      detail: p.membership?.plan_nombre || "Plan",
      amount: p.monto,
      at: p.timestamp,
      state: p.estado,
    })),
    ...(sales?.productSales || []).map(s => ({
      id: s.id,
      kind: "Productos",
      who: s.cliente?.nombre_completo || "Cliente",
      detail: s.details?.map(d => `${d.cantidad}x ${d.producto?.nombre}`).join(", ") || s.referencia,
      amount: s.total,
      at: s.fecha_venta,
      state: s.estado,
    })),
  ].sort((a, b) => new Date(b.at) - new Date(a.at));

  return (
    <div className="content-wrap">
      <ErrorBlock message={error}/>
      {message && <div className="state-block ok">{message}</div>}
      <div className="seg" role="tablist" aria-label="Caja" style={{ marginBottom: 16 }}>
        {[
          ["turno", "Turno"],
          ["pos", "POS productos"],
          ["membresias", "Membresías"],
          ["asistencia", "Asistencia"],
          ["ventas", "Ventas"],
        ].map(([id, label]) => <button key={id} role="tab" aria-selected={tab === id} onClick={() => setTab(id)}>{label}</button>)}
      </div>

      {tab === "turno" && (
        <div className="grid k-2-1">
          <Panel title={caja ? "Caja abierta" : "Abrir caja"} sub={caja ? `Desde ${new Date(caja.fecha_apertura).toLocaleString()}` : "Inicia el turno para vender"}>
            {caja ? (
              <>
                <div style={{ font: "800 34px var(--font-display)" }}>S/ {(stats?.efectivo_esperado ?? caja.monto_apertura ?? 0).toFixed(2)}</div>
                <div className="cell-sub">Efectivo esperado · saldo inicial S/ {caja.monto_apertura}</div>
                <div className="divider"/>
                <div className="row-2">
                  <div className="field"><label>Monto egreso</label><input type="number" value={egressAmount} onChange={e => setEgressAmount(e.target.value)}/></div>
                  <div className="field"><label>Motivo</label><input value={egressReason} onChange={e => setEgressReason(e.target.value)} placeholder="Servicios, movilidad..."/></div>
                </div>
                <Btn kind="ghost" leading={I.trash} disabled={busy || !egressAmount} onClick={registerEgress}>Registrar egreso</Btn>
                <div className="divider"/>
                <div className="row-2">
                  <div className="field"><label>Cierre efectivo</label><input type="number" value={closeForm.efectivo} onChange={e => setCloseForm({ ...closeForm, efectivo: e.target.value })}/></div>
                  <div className="field"><label>Cierre transferencia</label><input type="number" value={closeForm.transferencia} onChange={e => setCloseForm({ ...closeForm, transferencia: e.target.value })}/></div>
                  <div className="field"><label>Cierre Yape/Plin</label><input type="number" value={closeForm.yape} onChange={e => setCloseForm({ ...closeForm, yape: e.target.value })}/></div>
                  <div className="field"><label>Cierre tarjeta/POS</label><input type="number" value={closeForm.pos} onChange={e => setCloseForm({ ...closeForm, pos: e.target.value })}/></div>
                </div>
                <div className="field"><label>Observaciones</label><textarea rows="2" value={closeForm.obs} onChange={e => setCloseForm({ ...closeForm, obs: e.target.value })}/></div>
                <Btn kind="accent" leading={I.check} disabled={busy} onClick={closeShift}>Cerrar caja</Btn>
              </>
            ) : (
              <>
                <div className="field"><label>Monto apertura</label><input type="number" value={openAmount} onChange={e => setOpenAmount(e.target.value)}/></div>
                <Btn kind="primary" leading={I.drawer} disabled={busy} onClick={openShift}>Abrir caja</Btn>
              </>
            )}
          </Panel>
          <Panel title="Arqueo" sub="resumen por método">
            <Kpi icon="trend" value={`S/ ${(stats?.total_esperado ?? 0).toFixed(2)}`} label="Total esperado" delta={`${movements.length} movimientos`} dir="up"/>
            <div className="divider"/>
            {[
              ["Efectivo", stats?.efectivo_ingreso, stats?.efectivo_egreso],
              ["Transferencia", stats?.transferencia_ingreso, stats?.transferencia_egreso],
              ["Yape/Plin", stats?.yape_ingreso, stats?.yape_egreso],
              ["Tarjeta/POS", stats?.pos_ingreso, stats?.pos_egreso],
            ].map(([label, ing, egr]) => (
              <div key={label} className="cart-line">
                <div><div className="cell-main">{label}</div><div className="cell-sub">Ingreso S/ {(ing || 0).toFixed(2)} · Egreso S/ {(egr || 0).toFixed(2)}</div></div>
                <b>S/ {((ing || 0) - (egr || 0)).toFixed(2)}</b>
              </div>
            ))}
          </Panel>
        </div>
      )}

      {(tab === "pos" || tab === "membresias") && (
        <div className="drawer-grid">
          <Panel title={tab === "pos" ? "Catálogo POS" : "Planes activos"} sub={tab === "pos" ? "productos físicos" : "venta de membresías"}>
            <MemberSearchBox query={memberQuery} setQuery={setMemberQuery} results={memberResults} selected={selectedMember} setSelected={setSelectedMember}/>
            <div className="pos-grid" style={{ marginTop: 14 }}>
              {(tab === "pos" ? products : plans).map(item => (
                <button key={item.id} className="panel pad pos-item" onClick={() => addToCart(tab === "pos"
                  ? { type: "product", id: item.id, name: item.name, unitPrice: item.price }
                  : { type: "membership", id: item.id, name: item.name, unitPrice: item.price })}>
                  <div className="cell-main">{item.name}</div>
                  <div className="cell-sub">{tab === "pos" ? `${item.category || "Producto"} · stock ${item.stock}` : `${item.durationDays} días`}</div>
                  <div className="price">S/ {item.price}</div>
                </button>
              ))}
            </div>
          </Panel>
          <Panel title="Carrito" sub={selectedMember ? selectedMember.nombre_completo || selectedMember.name : "Venta anónima"}>
            {cart.length === 0 ? <div className="empty">Agrega productos o planes para vender.</div> : cart.map(item => (
              <div className="cart-line" key={`${item.type}-${item.id}`}>
                <div><div className="cell-main">{item.name}</div><div className="cell-sub">S/ {item.unitPrice} x {item.qty}</div></div>
                <div className="cart-actions">
                  <Btn kind="ghost" size="sm" onClick={() => updateQty(item, -1)}>-</Btn>
                  <b>{item.qty}</b>
                  <Btn kind="ghost" size="sm" onClick={() => updateQty(item, 1)}>+</Btn>
                </div>
              </div>
            ))}
            <div className="divider"/>
            <div style={{ display: "flex", justifyContent: "space-between", font: "800 18px var(--font-display)" }}><span>Total</span><span>S/ {total.toFixed(2)}</span></div>
            <div className="seg" style={{ marginTop: 14 }}>
              <button aria-selected={paymentMode === "single"} onClick={() => setPaymentMode("single")}>Pago único</button>
              <button aria-selected={paymentMode === "combined"} onClick={() => setPaymentMode("combined")}>Combinado</button>
            </div>
            {paymentMode === "single" ? (
              <>
                <div className="pay-methods" style={{ marginTop: 12 }}>
                  {["Efectivo","Yape","Plin","Tarjeta"].map(m => <Btn key={m} kind={paymentMethod === m ? "accent" : "ghost"} onClick={() => setPaymentMethod(m)}>{m}</Btn>)}
                </div>
                {paymentMethod === "Efectivo" && <div className="field" style={{ marginTop: 12 }}><label>Efectivo recibido</label><input type="number" value={cashReceived} onChange={e => setCashReceived(e.target.value)}/><div className="cell-sub">Vuelto S/ {Math.max(0, Number(cashReceived || 0) - total).toFixed(2)}</div></div>}
              </>
            ) : (
              <div className="row-2" style={{ marginTop: 12 }}>
                {Object.keys(combined).map(m => <div className="field" key={m}><label>{m}</label><input type="number" value={combined[m]} onChange={e => setCombined({ ...combined, [m]: e.target.value })}/></div>)}
                <div className="cell-sub">Ingresado S/ {combinedTotal.toFixed(2)} · restante S/ {Math.max(0, total - combinedTotal).toFixed(2)}</div>
              </div>
            )}
            <Btn kind="primary" block leading={I.cash} disabled={busy || !canCharge || !caja} onClick={charge}>Confirmar venta</Btn>
            {!caja && <div className="cell-sub" style={{ marginTop: 8 }}>Abre caja antes de vender.</div>}
          </Panel>
        </div>
      )}

      {tab === "asistencia" && (
        <Panel title="Escáner por DNI" sub="simulación de acceso real">
          <div className="row-2">
            <div className="field"><label>DNI</label><input value={scanDni} onChange={e => setScanDni(e.target.value)} placeholder="Ingresa DNI"/></div>
            <div style={{ display: "flex", alignItems: "end" }}><Btn kind="primary" disabled={busy || !scanDni} onClick={scan}>Verificar acceso</Btn></div>
          </div>
          {scanResult && <div className="scan-result" style={{ marginTop: 14 }}>
            <Badge kind={scanResult.verdict === "GREEN" ? "ok" : scanResult.verdict === "AMBER" ? "warn" : "danger"} dot>
              {scanResult.verdict === "GREEN" || scanResult.verdict === "AMBER" ? "Acceso concedido" : "Acceso denegado"}
            </Badge>
            <div className="section-title">{scanResult.member?.name || scanResult.member?.nombre_completo || scanResult.user?.nombre_completo || scanDni}</div>
            <div className="cell-sub">{scanResult.reason || scanResult.message || "Resultado de asistencia"}</div>
            {!(scanResult.verdict === "GREEN" || scanResult.verdict === "AMBER") && plans[0] && <Btn kind="accent" style={{ marginTop: 12 }} onClick={() => { addToCart({ type: "membership", id: plans[0].id, name: plans[0].name, unitPrice: plans[0].price }); setTab("membresias"); }}>Vender {plans[0].name}</Btn>}
          </div>}
        </Panel>
      )}

      {tab === "ventas" && (
        <Panel title="Ventas del turno" sub={`${saleRows.length} registros`} bodyPad={false}>
          <table className="tbl">
            <thead><tr><th>Fecha</th><th>Tipo</th><th>Cliente</th><th>Detalle</th><th>Estado</th><th className="num">Monto</th></tr></thead>
            <tbody>
              {saleRows.map(row => <tr key={`${row.kind}-${row.id}`}><td>{new Date(row.at).toLocaleString()}</td><td><Badge>{row.kind}</Badge></td><td className="cell-main">{row.who}</td><td className="cell-sub">{row.detail}</td><td><Badge kind={row.state === "APPROVED" || row.state === "completada" ? "ok" : "warn"} dot>{row.state}</Badge></td><td className="num">S/ {Number(row.amount || 0).toFixed(2)}</td></tr>)}
              {saleRows.length === 0 && <tr><td colSpan="6"><div className="empty">Sin ventas en el turno activo.</div></td></tr>}
            </tbody>
          </table>
        </Panel>
      )}
    </div>
  );
}

window.Caja = Caja;

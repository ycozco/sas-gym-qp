// modules2.jsx — módulos ampliados del panel (paridad con crosshero-gym):
// Membresías, Caja, Finanzas, Puntos, Clases, Entrenamientos, CRM.

// ═══════════════════════════════════════════════════════════════
// MEMBRESÍAS — planes, precios, congelar / traspasar
// ═══════════════════════════════════════════════════════════════
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
      setError(e.message || "No se pudo guardar el plan.");
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
                    <Btn kind="ghost" size="sm" leading={I.edit} onClick={() => setEditingPlan(p)}>Editar</Btn>
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

// ═══════════════════════════════════════════════════════════════
// CAJA — apertura, movimientos, cierre del turno
// ═══════════════════════════════════════════════════════════════
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

function MemberSearchBox({ query, setQuery, results, selected, setSelected }) {
  return (
    <div>
      <div className="field"><label>Socio destinatario</label><input value={query} onChange={e => setQuery(e.target.value)} placeholder="Buscar por DNI, nombre, email o celular"/></div>
      {selected && <div className="state-block ok">Seleccionado: {selected.nombre_completo || selected.name} · DNI {selected.dni} <Btn kind="ghost" size="sm" onClick={() => setSelected(null)}>Quitar</Btn></div>}
      {!selected && results.length > 0 && <div className="panel" style={{ overflow: "hidden", marginTop: 8 }}>
        {results.slice(0, 6).map(row => {
          const user = row.user || row;
          return <button key={user.id || user.dni} className="lrow" style={{ width: "100%", border: 0, background: "transparent", cursor: "pointer", textAlign: "left" }} onClick={() => setSelected(user)}>
            <Avatar name={user.nombre_completo || user.name} size={30}/>
            <div className="l-main"><div className="l-t">{user.nombre_completo || user.name}</div><div className="l-s">DNI {user.dni || "—"} · {user.email || ""}</div></div>
          </button>;
        })}
      </div>}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// FINANZAS — sueldos, servicios, gastos e ingresos especiales
// ═══════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════
// PUNTOS — fidelización: catálogo y canjes
// ═══════════════════════════════════════════════════════════════
function Puntos({ app }) {
  const summary = app?.pointsSummary;
  const catalog = app?.pointsCatalog;
  const products = catalog?.products || [];
  const memberships = catalog?.memberships || [];
  const catalogRows = products.length || memberships.length
    ? [
        ...products.map(p => ({ id: p.id, n: p.nombre, tipo: "Producto", costo: p.precio_puntos })),
        ...memberships.map(m => ({ id: m.id, n: m.nombre, tipo: "Membresia", costo: m.precio_puntos })),
      ]
    : PTS_CATALOG;
  const exchanges = summary?.exchanges?.length ? summary.exchanges.map(x => ({
    id: x.id,
    t: x.fecha_canje ? new Date(x.fecha_canje).toLocaleDateString() : "Reciente",
    n: x.usuario?.nombre_completo || "Socio",
    item: x.producto?.nombre || x.membresia_puntos?.nombre || x.tipo,
    pts: x.puntos_utilizados,
  })) : PTS_CANJES;
  const kpis = summary ? [
    { id: "emi", label: "Puntos emitidos", value: summary.earnedPoints || 0, delta: "tenant real", dir: "up", icon: "star" },
    { id: "can", label: "Puntos canjeados", value: summary.redeemedPoints || 0, delta: `${summary.exchanges?.length || 0} canjes`, dir: "flat", icon: "check" },
    { id: "usr", label: "Usuarios con puntos", value: summary.usersWithPoints || 0, delta: `${summary.availablePoints || 0} disponibles`, dir: "up", icon: "users" },
  ] : PTS_KPIS;
  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {kpis.map(k => <Kpi key={k.id} {...k}/>)}
      </div>

      <div className="grid k-2-1">
        <Panel title="Catálogo canjeable" sub="productos y membresías por puntos"
               action={<Btn kind="primary" size="sm" leading={I.plus}>Añadir ítem</Btn>}
               bodyPad={false}>
          <table className="tbl">
            <thead><tr><th>Ítem</th><th>Tipo</th><th className="num">Costo</th></tr></thead>
            <tbody>
              {catalogRows.map((c, i) => (
                <tr key={c.id || i} className="clickable">
                  <td className="cell-main">{c.n}</td>
                  <td><Badge kind={c.tipo === "Membresía" ? "accent" : "info"}>{c.tipo}</Badge></td>
                  <td className="num" style={{ font: "700 13.5px var(--font-mono)" }}>{c.costo} pts</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Panel>

        <Panel title="Canjes recientes" bodyPad={false}>
          {exchanges.map((c, i) => (
            <div className="lrow" key={c.id || i}>
              <span className="l-ic" style={{ color: "var(--warn)" }}>{I.star}</span>
              <div className="l-main">
                <div className="l-t">{c.n}</div>
                <div className="l-s">{c.item}</div>
              </div>
              <span style={{ font: "700 12.5px var(--font-mono)", color: "var(--ink-2)" }}>−{c.pts}</span>
            </div>
          ))}
          <div style={{ padding: "12px 16px", font: "500 12px var(--font-body)", color: "var(--ink-3)" }}>
            La configuración define cuántos puntos otorga cada sol gastado.
          </div>
        </Panel>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CLASES — horarios y cupos  (WEB-06)
// ═══════════════════════════════════════════════════════════════
function Clases({ app }) {
  const dayMap = ["Dom", "Lun", "Mar", "Mie", "Jue", "Vie", "Sab"];
  const rows = app?.schedules?.length ? app.schedules.map(s => {
    const reserved = s.bookings?.filter(b => b.estado === "CONFIRMED" || b.estado === "ATTENDED").length || 0;
    return {
      id: s.id,
      n: s.nombre_clase,
      coach: "Entrenador asignado",
      dias: (s.dia_semana || []).map(d => dayMap[d] || d).join(", "),
      hora: `${s.hora_inicio} - ${s.hora_fin}`,
      cupo: `${reserved}/${s.cupo_maximo}`,
      st: reserved >= s.cupo_maximo ? "full" : reserved >= s.cupo_maximo * 0.75 ? "warn" : "ok",
    };
  }) : CLASSES;
  return (
    <div className="content-wrap">
      <Panel title="Clases y horarios" sub={`${rows.length} clases activas`}
             action={<Btn kind="primary" size="sm" leading={I.plus}>Crear clase</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Clase</th><th>Entrenador</th><th>Días</th><th>Hora</th><th className="num">Cupo</th><th>Estado</th></tr></thead>
          <tbody>
            {rows.map((c, i) => (
              <tr key={c.id || i} className="clickable">
                <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span className="l-ic" style={{ width: 30, height: 30, background: "var(--ink)", color: "var(--accent)" }}>{I.calendar}</span>
                  <span className="cell-main">{c.n}</span>
                </div></td>
                <td style={{ color: "var(--ink-2)" }}>{c.coach}</td>
                <td style={{ color: "var(--ink-2)" }}>{c.dias}</td>
                <td style={{ font: "600 13px var(--font-mono)" }}>{c.hora}</td>
                <td className="num">{c.cupo}</td>
                <td>{c.st === "full" ? <Badge kind="danger" dot>Lleno</Badge>
                    : c.st === "warn" ? <Badge kind="warn" dot>Casi lleno</Badge>
                    : <Badge kind="ok" dot>Disponible</Badge>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>
      <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-3)", marginTop: 12 }}>
        Los miembros reservan su cupo desde la app móvil; al llenarse pasan a lista de espera.
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// ENTRENAMIENTOS — rutinas, ejercicios, grupos musculares
// ═══════════════════════════════════════════════════════════════
function Entrenamientos({ app }) {
  const routine = app?.activeRoutine;
  const routineRows = routine?.template?.ejercicios?.length
    ? routine.template.ejercicios.map((item, i) => ({
        n: item.exercise?.nombre || `Ejercicio ${i + 1}`,
        div: item.exercise?.grupo_muscular || routine.template?.nombre || "Rutina activa",
        ej: item.series ? `${item.series}x${item.repeticiones || "-"}` : "Asignado",
        asg: 1,
      }))
    : ROUTINES;
  const routineTitle = routine?.template?.nombre || "Rutinas y plantillas";
  const routineSub = routine ? `rutina activa - ${routine.trainer?.user?.nombre_completo || "entrenador"}` : "biblioteca de entrenamientos";
  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {TRAIN_KPIS.map(k => <Kpi key={k.id} {...k}/>)}
      </div>

      <Panel title={routineTitle} sub={routineSub}
             action={<Btn kind="primary" size="sm" leading={I.plus}>Nueva rutina</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Rutina</th><th>División</th><th className="num">Ejercicios</th><th className="num">Asignada a</th></tr></thead>
          <tbody>
            {routineRows.map((r, i) => (
              <tr key={i} className="clickable">
                <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span className="l-ic" style={{ width: 30, height: 30 }}>{I.dumbbell}</span>
                  <span className="cell-main">{r.n}</span>
                </div></td>
                <td style={{ color: "var(--ink-2)" }}>{r.div}</td>
                <td className="num">{r.ej}</td>
                <td className="num">{r.asg} alumnos</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>

      <Panel title="Grupos musculares" sub="biblioteca de ejercicios animados">
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {MUSCLE_GROUPS.map(g => <span className="badge" key={g}>{g}</span>)}
        </div>
        <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-3)", marginTop: 12 }}>
          Cada ejercicio guarda una animación (GIF/WebM ≤ 2 MB) versionada y cacheada.
        </div>
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CRM — campañas, contactos y seguimientos
// ═══════════════════════════════════════════════════════════════
function CRM({ app }) {
  const CANAL = { Email: "info", WhatsApp: "ok", Push: "accent" };
  const EST = { Activa: "ok", Programada: "warn", Finalizada: "" };
  const announcements = app?.announcements || [];
  const observations = app?.observations || [];
  const campaignRows = announcements.length ? announcements.map(a => ({
    id: a.id,
    n: a.titulo || "Anuncio",
    canal: "Push",
    estado: a.activo === false ? "Finalizada" : "Activa",
    alcance: "Tenant",
  })) : CAMPAIGNS;
  const contactRows = observations.length ? observations.map(o => ({
    id: o.id,
    n: o.texto || "Observacion",
    origen: o.autor_rol || "Sistema",
    estado: o.foto_url ? "Con evidencia" : "Nuevo",
  })) : CRM_CONTACTS;
  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {CRM_KPIS.map(k => <Kpi key={k.id} {...k}/>)}
      </div>

      {(announcements.length > 0 || observations.length > 0) && (
        <>
          <Panel title="Anuncios y campanas" sub="anuncios reales del tenant"
                 action={<Btn kind="primary" size="sm" leading={I.plus}>Nueva campana</Btn>}
                 bodyPad={false}>
            <table className="tbl">
              <thead><tr><th>Mensaje</th><th>Canal</th><th>Estado</th><th className="num">Alcance</th></tr></thead>
              <tbody>
                {campaignRows.map((c, i) => (
                  <tr key={c.id || i} className="clickable">
                    <td className="cell-main">{c.n}</td>
                    <td><Badge kind={CANAL[c.canal]}>{c.canal}</Badge></td>
                    <td><Badge kind={EST[c.estado]} dot>{c.estado}</Badge></td>
                    <td className="num">{c.alcance}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Panel>

          <Panel title="Observaciones e incidencias" sub="reportes reales del tenant" bodyPad={false}>
            {contactRows.map((c, i) => (
              <div className="lrow" key={c.id || i}>
                <Avatar name={c.n} size={34}/>
                <div className="l-main">
                  <div className="l-t">{c.n}</div>
                  <div className="l-s">Origen: {c.origen}</div>
                </div>
                <Badge kind={c.estado === "Nuevo" ? "info" : "warn"} dot>{c.estado}</Badge>
              </div>
            ))}
          </Panel>
        </>
      )}

      <Panel title="Campañas" sub="email · WhatsApp · push"
             action={<Btn kind="primary" size="sm" leading={I.plus}>Nueva campaña</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Campaña</th><th>Canal</th><th>Estado</th><th className="num">Alcance</th></tr></thead>
          <tbody>
            {CAMPAIGNS.map((c, i) => (
              <tr key={i} className="clickable">
                <td className="cell-main">{c.n}</td>
                <td><Badge kind={CANAL[c.canal]}>{c.canal}</Badge></td>
                <td><Badge kind={EST[c.estado]} dot>{c.estado}</Badge></td>
                <td className="num">{c.alcance} personas</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>

      <Panel title="Contactos y leads" sub="prospectos sin membresía" bodyPad={false}>
        {CRM_CONTACTS.map((c, i) => (
          <div className="lrow" key={i}>
            <Avatar name={c.n} size={34}/>
            <div className="l-main">
              <div className="l-t">{c.n}</div>
              <div className="l-s">Origen: {c.origen}</div>
            </div>
            <Badge kind={c.estado === "Nuevo" ? "info" : "warn"} dot>{c.estado}</Badge>
          </div>
        ))}
      </Panel>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// SUPER ADMIN · GIMNASIOS — clientes / instancias multi-tenant
// ═══════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════
// SUPER ADMIN · PLANES SAAS — suscripción de los gimnasios
// ═══════════════════════════════════════════════════════════════
function PlanesSaaS({ app }) {
  const tenants = app?.tenants || [];
  const planCounts = tenants.reduce((acc, t) => {
    const plan = t.saas_plan || t.plan_saas || "Pro";
    acc[plan] = (acc[plan] || 0) + 1;
    return acc;
  }, {});
  const plans = SAAS_PLANS.map(p => ({ ...p, gimnasios: tenants.length ? (planCounts[p.n] || 0) : p.gimnasios }));
  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {plans.map((p, i) => (
          <div className="panel pad" key={p.n} style={i === 1 ? { borderColor: "var(--ink)", borderWidth: 2 } : null}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <Badge kind={p.n === "Enterprise" ? "accent" : p.n === "Pro" ? "info" : ""}>{p.n}</Badge>
              {i === 1 && <span style={{ font: "600 10.5px var(--font-mono)", color: "var(--ink-3)", textTransform: "uppercase", letterSpacing: ".06em" }}>Más usado</span>}
            </div>
            <div style={{ font: "800 30px var(--font-display)", letterSpacing: "-0.04em", marginTop: 14 }}>
              {p.price}<span style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}> /mes</span>
            </div>
            <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>{p.limite}</div>
            <div className="divider"/>
            <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}>{p.feats}</div>
            <div style={{ font: "700 13px var(--font-display)", marginTop: 12 }}>{p.gimnasios} gimnasios en este plan</div>
            <div style={{ marginTop: 14 }}>
              <Btn kind="ghost" block leading={I.edit}>Editar plan</Btn>
            </div>
          </div>
        ))}
      </div>
      <Panel title="Facturación de la plataforma" sub="cobro mensual a cada gimnasio">
        <div style={{ font: "500 14px var(--font-body)", color: "var(--ink-2)" }}>
          Cada gimnasio paga su suscripción según el plan contratado. El ingreso
          recurrente total (MRR) se calcula sumando los planes activos de las
          10 instancias de la red.
        </div>
      </Panel>
    </div>
  );
}

Object.assign(window, { Membresias, Caja, Finanzas, Puntos, Clases, Entrenamientos, CRM, Gimnasios, PlanesSaaS });

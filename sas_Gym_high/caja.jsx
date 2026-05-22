// caja.jsx — App de Caja / Recepción
// Sub-rol del Admin con permisos limitados:
//  · Cobrar membresías y productos
//  · Registrar asistencias (escáner)
//  · Registro de ventas (log read-only)
//  · Ingreso de nuevos productos + asignar precios (con log)
//  · Registrar y editar usuarios (eliminación lógica, no física, con log marcado)
//  · Toda acción genera un log visible al Admin
//  · La cuenta sólo opera dentro del horario que Admin asignó

const CAJA_NAV = [
  { id: "home",    label: "Inicio",     icon: I.home },
  { id: "scan",    label: "Asistencia", icon: I.scan },
  { id: "charge",  label: "Cobrar",     icon: I.cash, fab: true },
  { id: "sales",   label: "Ventas",     icon: I.chart },
  { id: "more",    label: "Más",        icon: I.more },
];

const CAJA_PROFILE = {
  n: "Mariana Quispe",
  rol: "Caja · Turno mañana",
  shift: { start: "06:00", end: "14:00", left: "3h 42m" },
  cajero_id: "CJ-002",
};

const PRODUCTS = window.PRODUCTS;
const ALL_MEMBERS = window.ALL_MEMBERS;

const CAJA_SALES_TODAY = [
  { id: "v1", t: "08:14", n: "Mateo Salas",     it: "Proteína whey",       m: 12,  k: "Yape",     u: "Mariana Q." },
  { id: "v2", t: "08:32", n: "Sin usuario",     it: "Botella agua + Barra", m: 8,   k: "Efectivo", u: "Mariana Q." },
  { id: "v3", t: "09:01", n: "Lucía Fernández", it: "Membresía Trimestral", m: 320, k: "Efectivo", u: "Mariana Q." },
  { id: "v4", t: "09:48", n: "Sin usuario",     it: "Polo oficial L",       m: 45,  k: "Yape",     u: "Mariana Q." },
  { id: "v5", t: "10:22", n: "Jorge Paredes",   it: "Membresía Anual",      m: 1080, k: "Tarjeta",  u: "Mariana Q." },
  { id: "v6", t: "11:30", n: "Rosa Mendieta",   it: "Membresía Mensual",    m: 120, k: "Yape",     u: "Mariana Q." },
];

// ═══════════════════════════════════════════════════════════════
// SHIFT BANNER (always visible en home)
// ═══════════════════════════════════════════════════════════════
function ShiftBanner() {
  return (
    <div style={{
      margin: "0 22px 14px",
      padding: "12px 14px",
      borderRadius: 14,
      background: "linear-gradient(135deg, color-mix(in oklab, var(--accent) 18%, white), color-mix(in oklab, var(--accent) 8%, white))",
      border: "1px solid color-mix(in oklab, var(--accent) 30%, white)",
      display: "flex", alignItems: "center", gap: 12,
    }}>
      <span style={{ width: 36, height: 36, borderRadius: 10, background: "var(--ink)", color: "var(--accent)", display: "grid", placeItems: "center" }}>{I.clock}</span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ font: "600 11px var(--font-mono)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".08em" }}>● TURNO ACTIVO</div>
        <div style={{ font: "700 14px var(--font-display)", letterSpacing: "-0.02em", marginTop: 2 }}>
          {CAJA_PROFILE.shift.start} – {CAJA_PROFILE.shift.end} <span style={{ color: "var(--ink-2)", font: "500 12px var(--font-body)" }}>· restan {CAJA_PROFILE.shift.left}</span>
        </div>
      </div>
      <Chip kind="solid">Cajero {CAJA_PROFILE.cajero_id}</Chip>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CAJA HOME
// ═══════════════════════════════════════════════════════════════
function CajaHome({ go }) {
  return (
    <Screen>
      <Header
        greet={{ hi: "Mañana del miércoles", name: "Hola, Mariana" }}
        right={<>
          <button className="h-icon" onClick={() => go("notifications")}>{I.bell}<span className="dot-r"/></button>
          <Avatar name={CAJA_PROFILE.n} size={46}/>
        </>}
      />
      <div className="scroll has-nav">
        <ShiftBanner/>

        {/* Saldo del turno */}
        <div className="section" style={{ paddingTop: 0 }}>
          <Card className="dark" style={{ padding: 18, border: 0, position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", top: -60, right: -40, width: 220, height: 220, background: "radial-gradient(circle, color-mix(in oklab, var(--accent) 45%, transparent), transparent 65%)", filter: "blur(10px)" }}/>
            <div style={{ position: "relative", display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
              <div>
                <div style={{ font: "600 11.5px var(--font-mono)", letterSpacing: ".08em", color: "var(--accent)", textTransform: "uppercase" }}>SALDO DE MI TURNO</div>
                <div style={{ font: "800 32px var(--font-display)", letterSpacing: "-0.04em", marginTop: 8 }}>S/ 1.585</div>
                <div style={{ font: "500 13px var(--font-body)", color: "rgba(255,255,255,.6)", marginTop: 2 }}>6 cobros · 4 ventas productos</div>
              </div>
              <Chip kind="accent">Cierra 14:00</Chip>
            </div>
            <div style={{ position: "relative", display: "grid", gridTemplateColumns: "repeat(3,1fr)", marginTop: 22, borderTop: "1px solid rgba(255,255,255,.1)", paddingTop: 14 }}>
              {[
                { l: "Efectivo", v: "S/ 440" },
                { l: "Yape/Plin", v: "S/ 165" },
                { l: "Tarjeta",  v: "S/ 1.080" },
              ].map((s, i) => (
                <div key={s.l} style={{ paddingLeft: i === 0 ? 0 : 14, borderLeft: i === 0 ? 0 : "1px solid rgba(255,255,255,.08)" }}>
                  <div style={{ font: "500 10.5px var(--font-body)", color: "rgba(255,255,255,.5)", textTransform: "uppercase", letterSpacing: ".06em" }}>{s.l}</div>
                  <div style={{ font: "700 18px var(--font-display)", letterSpacing: "-0.02em", marginTop: 4 }}>{s.v}</div>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* Live stats */}
        <div className="section">
          <SectionTitle title="Mi actividad de hoy"/>
          <div className="grid-2">
            <div className="kpi"><span className="l">Asistencias registradas</span><span className="v">28</span><span className="d">{I.trend} desde 6:00</span></div>
            <div className="kpi"><span className="l">Ventas productos</span><span className="v">11</span><span className="d">S/ 245</span></div>
          </div>
        </div>

        {/* Quick actions */}
        <div className="section">
          <SectionTitle title="Acciones rápidas"/>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10 }}>
            {[
              { ic: I.scan, l: "Asistencia", g: "scan" },
              { ic: I.cash, l: "Cobrar", g: "charge" },
              { ic: I.plus, l: "Usuario", g: "newMember" },
              { ic: I.dumbbell, l: "Producto", g: "newProduct" },
            ].map(a => (
              <button key={a.l} onClick={() => go(a.g)} style={{ appearance: "none", border: "1px solid var(--border)", background: "var(--surface)", borderRadius: 18, padding: "16px 8px", display: "flex", flexDirection: "column", alignItems: "center", gap: 8, cursor: "pointer", font: "600 12px var(--font-body)", color: "var(--ink)" }}>
                <span style={{ width: 38, height: 38, background: "var(--surface-2)", borderRadius: 12, display: "grid", placeItems: "center" }}>{a.ic}</span>
                {a.l}
              </button>
            ))}
          </div>
        </div>

        {/* Mis logs recientes (read-only) */}
        <div className="section">
          <SectionTitle title="Mis últimas acciones" action="Ver historial →" onAction={() => go("myLogs")}/>
          <Card style={{ padding: 0, overflow: "hidden" }}>
            {[
              { t: "11:30", ac: "Cobró membresía",  d: "Rosa Mendieta · S/ 120 · Yape",      ic: I.cash, c: "var(--success)" },
              { t: "10:22", ac: "Cobró membresía",  d: "Jorge Paredes · S/ 1.080 · Tarjeta", ic: I.cash, c: "var(--success)" },
              { t: "09:48", ac: "Vendió producto",  d: "Polo oficial L · S/ 45 · Yape",      ic: I.dumbbell, c: "var(--info)" },
              { t: "09:14", ac: "Editó usuario",    d: "Ana Torres · actualizó celular",     ic: I.edit, c: "var(--warn)" },
              { t: "08:42", ac: "Registró ingreso", d: "Mateo Salas · QR escaneado",         ic: I.scan, c: "var(--ink-2)" },
            ].map((l, i) => (
              <div key={i} style={{ display: "flex", gap: 12, alignItems: "center", padding: "12px 14px", borderTop: i === 0 ? 0 : "1px solid var(--border)" }}>
                <span style={{ width: 32, height: 32, borderRadius: 10, background: "var(--surface-2)", color: l.c, display: "grid", placeItems: "center", flexShrink: 0 }}>{l.ic}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "600 13.5px var(--font-body)", letterSpacing: "-0.01em" }}>{l.ac}</div>
                  <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)", marginTop: 2, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{l.d}</div>
                </div>
                <span style={{ font: "500 11.5px var(--font-mono)", color: "var(--ink-3)" }}>{l.t}</span>
              </div>
            ))}
          </Card>
          <div style={{ marginTop: 8, font: "500 11.5px var(--font-body)", color: "var(--ink-3)", textAlign: "center" }}>
            Todas tus acciones se registran y son visibles para el Administrador.
          </div>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// CAJA · CHARGE (membresía o producto)
// ═══════════════════════════════════════════════════════════════
function CajaCharge({ go }) {
  const [mode, setMode] = React.useState("membership"); // "membership" | "product"
  const [member, setMember] = React.useState(null);
  const [cart, setCart] = React.useState([]); // [{id, qty}]
  const [plan, setPlan] = React.useState("Mensual");
  const [method, setMethod] = React.useState("cash");
  const planP = { Mensual: 120, Trimestral: 320, Anual: 1080 };

  const addToCart = (p) => {
    setCart(c => {
      const ex = c.find(x => x.id === p.id);
      return ex ? c.map(x => x.id === p.id ? { ...x, qty: x.qty + 1 } : x) : [...c, { id: p.id, qty: 1 }];
    });
  };
  const removeFromCart = (id) => setCart(c => c.filter(x => x.id !== id));
  const cartTotal = cart.reduce((sum, c) => sum + (PRODUCTS.find(p => p.id === c.id)?.p || 0) * c.qty, 0);
  const total = mode === "membership" ? planP[plan] : cartTotal;

  return (
    <Screen>
      <Header title="Registrar cobro" onBack={() => go("home")}/>
      <div className="scroll" style={{ paddingBottom: 120 }}>
        {/* Mode switch */}
        <div className="section">
          <div style={{ display: "flex", gap: 4, background: "var(--surface-2)", padding: 4, borderRadius: 14, border: "1px solid var(--border)" }}>
            {[
              { id: "membership", l: "Membresía", ic: I.cash },
              { id: "product",    l: "Productos", ic: I.dumbbell },
            ].map(m => (
              <button key={m.id} onClick={() => setMode(m.id)} style={{
                flex: 1, appearance: "none", border: 0,
                padding: "12px 6px",
                borderRadius: 10,
                font: "600 13.5px var(--font-body)",
                background: mode === m.id ? "var(--ink)" : "transparent",
                color: mode === m.id ? "#fff" : "var(--ink-2)",
                cursor: "pointer",
                display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
              }}>{m.ic}{m.l}</button>
            ))}
          </div>
        </div>

        {/* Member (optional for product) */}
        <div className="section">
          <SectionTitle title={mode === "product" ? "Usuario (opcional)" : "Usuario"}/>
          {!member ? (
            <Card style={{ padding: 14, display: "flex", alignItems: "center", gap: 10, cursor: "pointer" }} onClick={() => setMember("Mateo Salas")}>
              <span style={{ width: 38, height: 38, borderRadius: 12, background: "var(--surface-2)", color: "var(--ink-2)", display: "grid", placeItems: "center" }}>{I.search}</span>
              <input placeholder={mode === "product" ? "Sin usuario o buscar…" : "Buscar por nombre o DNI…"} style={{ flex: 1, border: 0, font: "500 14px var(--font-body)", background: "transparent", outline: "none" }}/>
            </Card>
          ) : (
            <Card style={{ padding: 12, display: "flex", alignItems: "center", gap: 12 }}>
              <Avatar name={member} size={44}/>
              <div style={{ flex: 1 }}>
                <div style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{member}</div>
                <div style={{ font: "500 12px var(--font-body)", color: "var(--success)", marginTop: 2 }}>● Activo · vence 4 jun</div>
              </div>
              <button onClick={() => setMember(null)} className="h-icon" style={{ width: 32, height: 32 }}>{I.close}</button>
            </Card>
          )}
        </div>

        {/* MEMBERSHIP FLOW */}
        {mode === "membership" && (
          <>
            <div className="section">
              <SectionTitle title="Plan"/>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
                {Object.entries(planP).map(([k, v]) => (
                  <button key={k} onClick={() => setPlan(k)} style={{
                    appearance: "none", border: "2px solid " + (plan === k ? "var(--ink)" : "var(--border)"),
                    background: plan === k ? "var(--surface-2)" : "var(--surface)",
                    borderRadius: 16, padding: 14, cursor: "pointer"
                  }}>
                    <div style={{ font: "600 11.5px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>{k}</div>
                    <div style={{ font: "800 18px var(--font-display)", letterSpacing: "-0.03em", marginTop: 4 }}>S/ {v}</div>
                  </button>
                ))}
              </div>
            </div>
          </>
        )}

        {/* PRODUCT FLOW */}
        {mode === "product" && (
          <>
            <div className="section">
              <SectionTitle title="Productos" action="Ver catálogo →" onAction={() => go("products")}/>
              <div style={{ display: "flex", gap: 6, overflowX: "auto", paddingBottom: 8 }}>
                {["Todos", "Bebidas", "Suplementos", "Snacks", "Merch", "Accesorios"].map((c, i) => (
                  <button key={c} style={{
                    flex: "0 0 auto", padding: "8px 14px", borderRadius: 999,
                    border: "1px solid " + (i === 0 ? "var(--ink)" : "var(--border)"),
                    background: i === 0 ? "var(--ink)" : "var(--surface)",
                    color: i === 0 ? "#fff" : "var(--ink)",
                    font: "600 12.5px var(--font-body)", cursor: "pointer"
                  }}>{c}</button>
                ))}
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginTop: 4 }}>
                {PRODUCTS.slice(0, 6).map(p => (
                  <button key={p.id} onClick={() => addToCart(p)} style={{
                    appearance: "none", border: "1px solid var(--border)",
                    background: "var(--surface)", borderRadius: 16,
                    padding: 12, cursor: "pointer", textAlign: "left",
                  }}>
                    <div style={{ width: 44, height: 44, borderRadius: 12, background: "var(--surface-2)", display: "grid", placeItems: "center", fontSize: 22 }}>{p.k}</div>
                    <div style={{ font: "600 13px var(--font-body)", marginTop: 8, letterSpacing: "-0.01em", textWrap: "pretty" }}>{p.n}</div>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginTop: 6 }}>
                      <span style={{ font: "800 16px var(--font-display)", letterSpacing: "-0.03em" }}>S/ {p.p}</span>
                      <span style={{ font: "500 10.5px var(--font-mono)", color: p.stock < 10 ? "var(--danger)" : "var(--ink-3)" }}>stock {p.stock}</span>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {cart.length > 0 && (
              <div className="section">
                <SectionTitle title="Carrito" action={`${cart.length} ítems`}/>
                <Card style={{ padding: 0, overflow: "hidden" }}>
                  {cart.map((c, i) => {
                    const p = PRODUCTS.find(x => x.id === c.id);
                    return (
                      <div key={c.id} style={{ display: "flex", gap: 10, alignItems: "center", padding: 12, borderTop: i === 0 ? 0 : "1px solid var(--border)" }}>
                        <span style={{ width: 36, height: 36, borderRadius: 10, background: "var(--surface-2)", display: "grid", placeItems: "center", fontSize: 18 }}>{p.k}</span>
                        <div style={{ flex: 1, minWidth: 0 }}>
                          <div style={{ font: "600 13px var(--font-body)" }}>{p.n}</div>
                          <div style={{ font: "500 11.5px var(--font-mono)", color: "var(--ink-2)" }}>{c.qty} × S/ {p.p}</div>
                        </div>
                        <span style={{ font: "700 14px var(--font-display)" }}>S/ {p.p * c.qty}</span>
                        <button onClick={() => removeFromCart(c.id)} style={{ background: "transparent", border: 0, color: "var(--ink-3)", cursor: "pointer", padding: 4 }}>{I.close}</button>
                      </div>
                    );
                  })}
                </Card>
              </div>
            )}
          </>
        )}

        {/* Method */}
        <div className="section">
          <SectionTitle title="Método de pago"/>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
            {[
              { id: "cash", l: "Efectivo", ic: I.cash },
              { id: "yape", l: "Yape", ic: I.qr },
              { id: "card", l: "Tarjeta", ic: I.cash },
            ].map(m => (
              <button key={m.id} onClick={() => setMethod(m.id)} style={{
                appearance: "none", border: "2px solid " + (method === m.id ? "var(--ink)" : "var(--border)"),
                background: method === m.id ? "var(--ink)" : "var(--surface)",
                color: method === m.id ? "#fff" : "var(--ink)",
                borderRadius: 16, padding: "14px 8px",
                cursor: "pointer",
                display: "flex", flexDirection: "column", alignItems: "center", gap: 6,
                font: "600 13px var(--font-body)"
              }}>
                {m.ic}{m.l}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="sticky-cta">
        <Btn kind="primary" block size="lg"
          onClick={() => go("home")}
          leading={I.check}
        >
          {mode === "membership" ? `Cobrar S/ ${total}` : cart.length === 0 ? "Agrega productos" : `Cobrar S/ ${total}`}
        </Btn>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// CAJA · VENTAS (Log read-only de ventas del turno)
// ═══════════════════════════════════════════════════════════════
function CajaSales({ go }) {
  const total = CAJA_SALES_TODAY.reduce((s, v) => s + v.m, 0);
  return (
    <Screen>
      <Header title="Ventas del turno" right={<button className="h-icon">{I.filter}</button>}/>
      <div className="scroll has-nav">
        <div className="section">
          <Card className="flat" style={{ padding: 16 }}>
            <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)" }}>Acumulado · 06:00 – ahora</div>
            <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginTop: 6 }}>
              <span style={{ font: "800 32px var(--font-display)", letterSpacing: "-0.04em" }}>S/ {total.toLocaleString()}</span>
              <Chip kind="ok">{CAJA_SALES_TODAY.length} ventas</Chip>
            </div>
            <div style={{ marginTop: 14, font: "500 11.5px var(--font-mono)", color: "var(--ink-3)", display: "flex", alignItems: "center", gap: 6 }}>
              <span style={{ width: 6, height: 6, background: "var(--info)", borderRadius: "50%" }}/> SOLO LECTURA · Estos registros no se editan
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Detalle"/>
          <Card style={{ padding: 0, overflow: "hidden" }}>
            {CAJA_SALES_TODAY.map((v, i) => (
              <div key={v.id} style={{ display: "flex", gap: 12, alignItems: "center", padding: 14, borderTop: i === 0 ? 0 : "1px solid var(--border)" }}>
                <div style={{ width: 44, textAlign: "center" }}>
                  <div style={{ font: "700 14px var(--font-display)", letterSpacing: "-0.02em" }}>{v.t}</div>
                  <div style={{ font: "500 9.5px var(--font-mono)", color: "var(--ink-3)" }}>{v.id.toUpperCase()}</div>
                </div>
                <div style={{ width: 1, alignSelf: "stretch", background: "var(--border)" }}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "600 13.5px var(--font-body)", letterSpacing: "-0.01em" }}>{v.it}</div>
                  <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{v.n} · {v.k}</div>
                </div>
                <div style={{ textAlign: "right" }}>
                  <div style={{ font: "700 15px var(--font-display)", letterSpacing: "-0.02em" }}>S/ {v.m}</div>
                </div>
              </div>
            ))}
          </Card>
        </div>

        <div className="section">
          <Card style={{ padding: 14, background: "color-mix(in oklab, var(--info) 6%, white)", borderColor: "color-mix(in oklab, var(--info) 20%, white)", display: "flex", gap: 12, alignItems: "flex-start" }}>
            <span style={{ width: 36, height: 36, borderRadius: 10, background: "var(--info)", color: "#fff", display: "grid", placeItems: "center", flexShrink: 0 }}>{I.warn}</span>
            <div style={{ flex: 1, font: "500 12.5px/1.5 var(--font-body)", color: "var(--ink-2)", textWrap: "pretty" }}>
              Si necesitas corregir o anular una venta, contacta al Administrador. Todas las anulaciones quedan registradas en el log de auditoría.
            </div>
          </Card>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// CAJA · MORE (productos, usuarios, mis logs)
// ═══════════════════════════════════════════════════════════════
function CajaMore({ go, onLogout }) {
  return (
    <Screen>
      <Header title="Más"/>
      <div className="scroll has-nav">
        <div className="section">
          <SectionTitle title="Gestión limitada"/>
          <div className="row-list">
            {[
              { i: I.dumbbell, l: "Catálogo de productos", s: "Ver, agregar y actualizar precios", g: "products" },
              { i: I.people, l: "Usuarios del gym", s: "Registrar, editar, dar de baja", g: "members" },
              { i: I.cash, l: "Historial de mis ventas", s: "Solo lectura · todos los turnos", g: "myLogs" },
              { i: I.scan, l: "Asistencias del día", s: "Log de ingresos registrados", g: "attendanceLog" },
            ].map(it => (
              <Card key={it.l} style={{ padding: 14, display: "flex", gap: 12, alignItems: "center", cursor: "pointer" }} onClick={() => go(it.g)}>
                <span style={{ width: 38, height: 38, borderRadius: 12, background: "var(--surface-2)", color: "var(--ink)", display: "grid", placeItems: "center" }}>{it.i}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ font: "600 14.5px var(--font-body)" }}>{it.l}</div>
                  <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{it.s}</div>
                </div>
                <span style={{ color: "var(--ink-2)" }}>{I.forward}</span>
              </Card>
            ))}
          </div>
        </div>

        <div className="section">
          <SectionTitle title="Mi cuenta"/>
          <Card>
            <Field l="Cajero ID" v={CAJA_PROFILE.cajero_id}/>
            <Field l="Rol" v="Caja · Operativo limitado"/>
            <Field l="Turno asignado" v={`${CAJA_PROFILE.shift.start} – ${CAJA_PROFILE.shift.end}`}/>
            <Field l="Asignado por" v="Sandra Aguilar (Admin)"/>
            <Field l="Permisos" v="Cobros · Ventas · Asistencia · Productos (alta) · Usuarios (CRUD)"/>
          </Card>
          <div style={{ marginTop: 12 }}>
            <Btn kind="ghost" block onClick={onLogout}>Cerrar sesión</Btn>
          </div>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// CAJA · PRODUCTS (ver catálogo, agregar nuevo, ajustar precio)
// ═══════════════════════════════════════════════════════════════
function CajaProducts({ go }) {
  return (
    <Screen>
      <Header title="Catálogo de productos" onBack={() => go("more")} right={<button className="h-icon" onClick={() => go("newProduct")}>{I.plus}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card className="flat" style={{ padding: 14, display: "flex", gap: 10, alignItems: "center" }}>
            <span style={{ width: 36, height: 36, borderRadius: 10, background: "var(--ink)", color: "var(--accent)", display: "grid", placeItems: "center" }}>{I.warn}</span>
            <div style={{ flex: 1, font: "500 12.5px/1.5 var(--font-body)", color: "var(--ink-2)", textWrap: "pretty" }}>
              Puedes <b style={{ color: "var(--ink)" }}>crear productos y ajustar precios</b>. Eliminar requiere autorización del Admin.
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title={`${PRODUCTS.length} productos activos`} action="+ Nuevo" onAction={() => go("newProduct")}/>
          <div className="row-list">
            {PRODUCTS.map(p => (
              <Card key={p.id} style={{ padding: 12, display: "flex", gap: 12, alignItems: "center", cursor: "pointer" }} onClick={() => go("editProduct", { id: p.id })}>
                <span style={{ width: 48, height: 48, borderRadius: 12, background: "var(--surface-2)", display: "grid", placeItems: "center", fontSize: 24, flexShrink: 0 }}>{p.k}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{p.n}</div>
                  <div style={{ font: "500 12px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>{p.cat} · stock {p.stock}</div>
                </div>
                <div style={{ textAlign: "right" }}>
                  <div style={{ font: "800 17px var(--font-display)", letterSpacing: "-0.03em" }}>S/ {p.p}</div>
                  {p.stock < 15 && <Chip kind="warn" size="">Bajo stock</Chip>}
                </div>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </Screen>
  );
}

// NEW PRODUCT (caja can add)
function NewProduct({ go }) {
  return (
    <Screen>
      <Header title="Nuevo producto" onBack={() => go("products")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card style={{ padding: 14, background: "color-mix(in oklab, var(--accent) 14%, white)", borderColor: "color-mix(in oklab, var(--accent) 30%, white)" }}>
            <div style={{ font: "600 11.5px var(--font-mono)", color: "var(--ink)", letterSpacing: ".08em", textTransform: "uppercase" }}>● LOG REGISTRADO</div>
            <div style={{ font: "500 12.5px/1.5 var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>
              Esta alta quedará registrada en el log de auditoría con tu usuario {CAJA_PROFILE.cajero_id}.
            </div>
          </Card>
        </div>

        <div className="section">
          <Card>
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="field"><label>Nombre del producto</label><input placeholder="Ej. Bebida isotónica 500ml"/></div>
              <div className="field">
                <label>Categoría</label>
                <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                  {["Bebidas", "Suplementos", "Snacks", "Merch", "Accesorios"].map((c, i) => (
                    <span key={c} className={`chip ${i === 0 ? "solid" : ""}`}>{c}</span>
                  ))}
                </div>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                <div className="field"><label>Precio (S/)</label><input placeholder="0.00"/></div>
                <div className="field"><label>Stock inicial</label><input placeholder="0"/></div>
              </div>
              <div className="field"><label>Código de barras (opcional)</label><input placeholder="EAN-13"/></div>
              <div className="field">
                <label>Imagen</label>
                <div style={{ height: 100, border: "2px dashed var(--border-strong)", borderRadius: 14, display: "grid", placeItems: "center", color: "var(--ink-2)" }}>
                  <div style={{ textAlign: "center" }}>
                    {I.camera}
                    <div style={{ marginTop: 6, font: "600 12.5px var(--font-body)" }}>Foto del producto</div>
                  </div>
                </div>
              </div>
            </div>
          </Card>
        </div>

        <div className="section">
          <Btn kind="primary" size="lg" block onClick={() => go("products")} leading={I.plus}>Crear producto</Btn>
        </div>
      </div>
    </Screen>
  );
}

// EDIT PRODUCT (caja can only adjust price + stock, not delete)
function EditProduct({ go, params }) {
  const p = PRODUCTS.find(x => x.id === params?.id) || PRODUCTS[0];
  return (
    <Screen>
      <Header title="Ajustar producto" onBack={() => go("products")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card>
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <span style={{ width: 56, height: 56, borderRadius: 14, background: "var(--surface-2)", display: "grid", placeItems: "center", fontSize: 28 }}>{p.k}</span>
              <div style={{ flex: 1 }}>
                <div style={{ font: "700 16px var(--font-display)", letterSpacing: "-0.02em" }}>{p.n}</div>
                <div style={{ font: "500 12px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>{p.cat}</div>
              </div>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Permitido para Caja"/>
          <Card>
            <div className="field"><label>Precio actual (S/)</label><input defaultValue={p.p}/></div>
            <div style={{ height: 14 }}/>
            <div className="field"><label>Ajustar stock</label><input defaultValue={p.stock}/></div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Restringido · Solo Admin"/>
          <Card style={{ opacity: .55 }}>
            <Field l="Nombre del producto" v={p.n}/>
            <Field l="Categoría" v={p.cat}/>
            <Field l="Código de barras" v="—"/>
            <div style={{ marginTop: 10, padding: 10, background: "var(--surface-2)", borderRadius: 10, font: "500 11.5px/1.4 var(--font-body)", color: "var(--ink-2)" }}>
              🔒 Cambios estructurales y eliminación solo pueden hacerse desde la cuenta del Administrador.
            </div>
          </Card>
        </div>

        <div className="section">
          <Btn kind="primary" size="lg" block onClick={() => go("products")} leading={I.check}>Guardar cambios</Btn>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// CAJA · MEMBERS LIST (registrar, editar, baja lógica)
// ═══════════════════════════════════════════════════════════════
function CajaMembers({ go }) {
  const [filter, setFilter] = React.useState("Todos");
  return (
    <Screen>
      <Header title="Usuarios" onBack={() => go("more")} right={<button className="h-icon" onClick={() => go("newMember")}>{I.plus}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card style={{ padding: 14, display: "flex", alignItems: "center", gap: 10 }}>
            <span style={{ width: 38, height: 38, borderRadius: 12, background: "var(--surface-2)", color: "var(--ink-2)", display: "grid", placeItems: "center" }}>{I.search}</span>
            <input placeholder="Buscar por nombre o DNI…" style={{ flex: 1, border: 0, font: "500 14px var(--font-body)", background: "transparent", outline: "none" }}/>
          </Card>
        </div>

        <div className="section">
          <div style={{ display: "flex", gap: 6, overflowX: "auto", paddingBottom: 8 }}>
            {["Todos", "Activos", "Vencidos", "Inactivos"].map(f => (
              <button key={f} onClick={() => setFilter(f)} style={{
                flex: "0 0 auto", padding: "8px 14px", borderRadius: 999,
                border: "1px solid " + (filter === f ? "var(--ink)" : "var(--border)"),
                background: filter === f ? "var(--ink)" : "var(--surface)",
                color: filter === f ? "#fff" : "var(--ink)",
                font: "600 12.5px var(--font-body)", cursor: "pointer"
              }}>{f}</button>
            ))}
          </div>
        </div>

        <div className="section">
          <div className="row-list">
            {ALL_MEMBERS.map(m => (
              <Card key={m.dni} style={{ padding: 12, display: "flex", gap: 12, alignItems: "center", cursor: "pointer" }} onClick={() => go("memberEdit", { dni: m.dni })}>
                <Avatar name={m.n} size={44}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{m.n}</div>
                  <div style={{ font: "500 12.5px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>DNI {m.dni} · {m.plan}</div>
                </div>
                <Chip kind={m.st === "active" ? "ok" : m.st === "expired" ? "danger" : m.st === "grace" ? "warn" : ""}>{m.d}</Chip>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </Screen>
  );
}

// EDIT USER (soft delete only)
function CajaMemberEdit({ go, params }) {
  const m = ALL_MEMBERS.find(x => x.dni === params?.dni) || ALL_MEMBERS[0];
  const [showDelete, setShowDelete] = React.useState(false);
  return (
    <Screen>
      <Header title="Editar usuario" onBack={() => go("members")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card>
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <Avatar name={m.n} size={64}/>
              <div style={{ flex: 1 }}>
                <div style={{ font: "800 20px var(--font-display)", letterSpacing: "-0.03em" }}>{m.n}</div>
                <div style={{ font: "500 12.5px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>DNI {m.dni}</div>
              </div>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Datos editables"/>
          <Card>
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="field"><label>Nombre completo</label><input defaultValue={m.n}/></div>
              <div className="field"><label>Celular</label><input defaultValue="+51 987 654 321"/></div>
              <div className="field"><label>Correo</label><input defaultValue={m.n.split(" ")[0].toLowerCase() + "@gmail.com"}/></div>
              <div className="field"><label>Entrenador asignado</label><input defaultValue={m.tr}/></div>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Estado del usuario"/>
          <Card>
            <div style={{ display: "flex", gap: 8 }}>
              {[
                { l: "Activo", on: m.st === "active", c: "var(--success)" },
                { l: "Suspendido", on: false, c: "var(--warn)" },
                { l: "Inactivo (baja lógica)", on: false, c: "var(--ink-2)" },
              ].map(s => (
                <span key={s.l} className={`chip ${s.on ? "solid" : ""}`} style={{ flex: 1, justifyContent: "center" }}>
                  <span style={{ width: 6, height: 6, background: s.c, borderRadius: "50%" }}/>{s.l}
                </span>
              ))}
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Zona de baja"/>
          <Card style={{ borderColor: "color-mix(in oklab, var(--danger) 25%, white)", background: "color-mix(in oklab, var(--danger) 4%, white)" }}>
            <div style={{ font: "600 13.5px var(--font-body)" }}>Eliminación lógica (Soft delete)</div>
            <div style={{ font: "500 12.5px/1.5 var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>
              El usuario quedará inactivo pero sus datos históricos se conservan. Esta acción se registra en el log de auditoría.
            </div>
            <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
              <Btn kind="danger-soft" block onClick={() => setShowDelete(true)} leading={I.trash}>Dar de baja lógica</Btn>
            </div>
            <div style={{ marginTop: 12, padding: 10, background: "var(--surface-2)", borderRadius: 10, font: "500 11.5px/1.4 var(--font-body)", color: "var(--ink-2)" }}>
              🔒 La eliminación física (borrado definitivo) solo puede ejecutarla el Administrador.
            </div>
          </Card>
        </div>

        <div className="section">
          <Btn kind="primary" size="lg" block onClick={() => go("members")} leading={I.check}>Guardar cambios</Btn>
        </div>
      </div>

      {showDelete && <SoftDeleteModal name={m.n} onClose={() => setShowDelete(false)} onConfirm={() => { setShowDelete(false); go("members"); }}/>}
    </Screen>
  );
}

function SoftDeleteModal({ name, onClose, onConfirm }) {
  return (
    <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,.5)", display: "grid", placeItems: "center", padding: 22, zIndex: 10 }} onClick={onClose}>
      <div style={{ background: "var(--surface)", borderRadius: 22, padding: 22, width: "100%", maxWidth: 360 }} onClick={e => e.stopPropagation()}>
        <div style={{ width: 56, height: 56, borderRadius: "50%", background: "color-mix(in oklab, var(--danger) 14%, white)", color: "var(--danger)", display: "grid", placeItems: "center", margin: "0 auto" }}>{I.warn}</div>
        <div style={{ font: "800 20px var(--font-display)", letterSpacing: "-0.03em", textAlign: "center", marginTop: 14, textWrap: "balance" }}>¿Dar de baja a {name}?</div>
        <div style={{ font: "500 13px/1.5 var(--font-body)", color: "var(--ink-2)", textAlign: "center", marginTop: 8, textWrap: "pretty" }}>
          Su acceso se desactiva pero los datos quedan archivados. El Admin puede revertir esto.
        </div>
        <div style={{ marginTop: 12, padding: 10, background: "var(--surface-2)", borderRadius: 10, font: "500 11.5px var(--font-mono)", color: "var(--ink-2)" }}>
          LOG: {CAJA_PROFILE.cajero_id} → baja_logica → {name}
        </div>
        <div style={{ display: "flex", gap: 10, marginTop: 18 }}>
          <Btn kind="ghost" block onClick={onClose}>Cancelar</Btn>
          <Btn kind="danger" block onClick={onConfirm}>Sí, dar de baja</Btn>
        </div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CAJA · MY LOGS (read-only history)
// ═══════════════════════════════════════════════════════════════
function CajaMyLogs({ go }) {
  const logs = [
    { d: "Hoy 11:30",   ac: "Cobró membresía",     d2: "Rosa Mendieta · S/ 120 · Yape",        ic: I.cash, c: "var(--success)" },
    { d: "Hoy 10:22",   ac: "Cobró membresía",     d2: "Jorge Paredes · S/ 1.080 · Tarjeta",   ic: I.cash, c: "var(--success)" },
    { d: "Hoy 09:48",   ac: "Vendió producto",     d2: "Polo oficial L · S/ 45 · Yape",        ic: I.dumbbell, c: "var(--info)" },
    { d: "Hoy 09:14",   ac: "Editó usuario",       d2: "Ana Torres · celular actualizado",     ic: I.edit, c: "var(--warn)" },
    { d: "Hoy 08:42",   ac: "Registró asistencia", d2: "Mateo Salas · QR escaneado",           ic: I.scan, c: "var(--ink-2)" },
    { d: "Hoy 08:00",   ac: "Inició sesión",       d2: "Turno mañana · IP 192.168.1.45",       ic: I.user, c: "var(--info)" },
    { d: "Ayer 13:58",  ac: "Cerró sesión",        d2: "Fin de turno · saldo S/ 2.140",        ic: I.close, c: "var(--ink-2)" },
    { d: "Ayer 12:14",  ac: "Creó producto",       d2: "Bebida isotónica 500ml · S/ 6",        ic: I.plus, c: "var(--accent-ink)", b: "var(--accent)" },
    { d: "Ayer 09:30",  ac: "Baja lógica usuario", d2: "Carmen Vega (DNI 71223344) · soft delete", ic: I.trash, c: "var(--danger)" },
  ];
  return (
    <Screen>
      <Header title="Mi historial de acciones" onBack={() => go("more")} right={<button className="h-icon">{I.filter}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card className="flat" style={{ padding: 14, display: "flex", gap: 10, alignItems: "center" }}>
            <span style={{ width: 36, height: 36, borderRadius: 10, background: "var(--info)", color: "#fff", display: "grid", placeItems: "center" }}>{I.warn}</span>
            <div style={{ flex: 1, font: "500 12.5px/1.5 var(--font-body)", color: "var(--ink-2)", textWrap: "pretty" }}>
              <b style={{ color: "var(--ink)" }}>Solo lectura.</b> Todas tus acciones quedan registradas y son visibles para el Admin.
            </div>
          </Card>
        </div>

        <div className="section">
          <Card style={{ padding: 0, overflow: "hidden" }}>
            {logs.map((l, i) => (
              <div key={i} style={{ display: "flex", gap: 12, alignItems: "flex-start", padding: 14, borderTop: i === 0 ? 0 : "1px solid var(--border)" }}>
                <span style={{ width: 32, height: 32, borderRadius: 10, background: l.b || "var(--surface-2)", color: l.c, display: "grid", placeItems: "center", flexShrink: 0 }}>{l.ic}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "600 13.5px var(--font-body)", letterSpacing: "-0.01em" }}>{l.ac}</div>
                  <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{l.d2}</div>
                </div>
                <span style={{ font: "500 11px var(--font-mono)", color: "var(--ink-3)", flexShrink: 0, textAlign: "right" }}>{l.d}</span>
              </div>
            ))}
          </Card>
        </div>
      </div>
    </Screen>
  );
}

// Attendance log (read-only)
function CajaAttendanceLog({ go }) {
  const ingresos = [
    { t: "11:42", n: "Diego Castro",    via: "QR app",   ok: true },
    { t: "11:30", n: "Rosa Mendieta",   via: "Manual DNI", ok: true },
    { t: "11:05", n: "Jorge Paredes",   via: "QR app",   ok: true },
    { t: "10:48", n: "Camila Rojas",    via: "QR app",   ok: true },
    { t: "10:22", n: "Ana Torres",      via: "QR app",   ok: false },
    { t: "09:30", n: "Lucía Fernández", via: "QR app",   ok: true },
    { t: "08:42", n: "Mateo Salas",     via: "QR app",   ok: true },
    { t: "07:14", n: "Pedro Quispe",    via: "Manual DNI", ok: false },
  ];
  return (
    <Screen>
      <Header title="Asistencias de hoy" onBack={() => go("more")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card className="flat" style={{ padding: 14, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)" }}>Ingresos registrados hoy</div>
              <div style={{ font: "800 28px var(--font-display)", letterSpacing: "-0.03em", marginTop: 4 }}>28 <span style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}>/ 2 denegados</span></div>
            </div>
            <Btn kind="primary" size="sm" onClick={() => go("scan")} leading={I.scan}>Escanear</Btn>
          </Card>
        </div>

        <div className="section">
          <Card style={{ padding: 0, overflow: "hidden" }}>
            {ingresos.map((it, i) => (
              <div key={i} style={{ display: "flex", gap: 12, alignItems: "center", padding: 12, borderTop: i === 0 ? 0 : "1px solid var(--border)" }}>
                <span style={{ width: 38, height: 38, borderRadius: 10, background: it.ok ? "color-mix(in oklab, var(--success) 14%, white)" : "color-mix(in oklab, var(--danger) 12%, white)", color: it.ok ? "var(--success)" : "var(--danger)", display: "grid", placeItems: "center" }}>
                  {it.ok ? I.check : I.close}
                </span>
                <div style={{ flex: 1 }}>
                  <div style={{ font: "600 13.5px var(--font-body)" }}>{it.n}</div>
                  <div style={{ font: "500 11.5px var(--font-mono)", color: "var(--ink-2)" }}>{it.via}</div>
                </div>
                <span style={{ font: "600 13px var(--font-mono)", color: it.ok ? "var(--ink-2)" : "var(--danger)" }}>{it.t}</span>
              </div>
            ))}
          </Card>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// CAJA ROUTER
// ═══════════════════════════════════════════════════════════════
function CajaApp() {
  const { screen, params, go } = useRouter("home");
  const [authed, setAuthed] = React.useState(false);

  if (!authed) return <LoginScreen role="caja" onLogin={() => setAuthed(true)}/>;

  const isScan = screen === "scan";
  const hideNav = isScan;

  const navCurrent = ({
    home: "home", notifications: "home",
    scan: "scan", attendanceLog: "scan",
    charge: "charge",
    sales: "sales",
    more: "more", products: "more", newProduct: "more", editProduct: "more",
    members: "more", memberEdit: "more", newMember: "more", myLogs: "more",
  })[screen] || "home";

  return (
    <>
      {screen === "home" && <CajaHome go={go}/>}
      {screen === "scan" && <AdminScanner go={go}/>}
      {screen === "charge" && <CajaCharge go={go}/>}
      {screen === "sales" && <CajaSales go={go}/>}
      {screen === "more" && <CajaMore go={go} onLogout={() => setAuthed(false)}/>}
      {screen === "products" && <CajaProducts go={go}/>}
      {screen === "newProduct" && <NewProduct go={go}/>}
      {screen === "editProduct" && <EditProduct go={go} params={params}/>}
      {screen === "members" && <CajaMembers go={go}/>}
      {screen === "memberEdit" && <CajaMemberEdit go={go} params={params}/>}
      {screen === "newMember" && <NewMember go={go}/>}
      {screen === "myLogs" && <CajaMyLogs go={go}/>}
      {screen === "attendanceLog" && <CajaAttendanceLog go={go}/>}
      {screen === "notifications" && <MemberNotifications go={go}/>}

      {!hideNav && (
        <div className="bnav-overlay">
          <BottomNav items={CAJA_NAV} current={navCurrent} onChange={(id) => go(id)}/>
        </div>
      )}
    </>
  );
}

Object.assign(window, { CajaApp });

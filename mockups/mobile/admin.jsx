// admin.jsx — App del Administrador / Caja

const ADMIN_NAV = [
  { id: "home",   label: "Inicio",   icon: I.home },
  { id: "members", label: "Usuarios", icon: I.people },
  { id: "scan",   label: "Escanear", icon: I.scan, fab: true },
  { id: "cash",   label: "Caja",     icon: I.cash },
  { id: "more",   label: "Más",      icon: I.more },
];

const PRODUCTS = window.PRODUCTS;

// ═══════════════════════════════════════════════════════════════
// ADMIN DASHBOARD
// ═══════════════════════════════════════════════════════════════
function AdminHome({ go }) {
  return (
    <Screen>
      <Header
        greet={{ hi: "SaaaS GYM · Miraflores", name: "Hola, Sandra" }}
        right={<>
          <button className="h-icon" onClick={() => go("notifications")}>{I.bell}<span className="dot-r"/></button>
          <Avatar name="Sandra Aguilar" size={46}/>
        </>}
      />
      <div className="scroll has-nav">
        {/* Today summary */}
        <div className="section">
          <Card className="dark" style={{ padding: 18, border: 0, position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", top: -60, right: -40, width: 220, height: 220, background: "radial-gradient(circle, color-mix(in oklab, var(--accent) 45%, transparent), transparent 65%)", filter: "blur(10px)" }}/>
            <div style={{ position: "relative" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
                <div>
                  <div style={{ font: "600 11.5px var(--font-mono)", letterSpacing: ".08em", color: "var(--accent)", textTransform: "uppercase" }}>● HOY · 21 MAY</div>
                  <div style={{ font: "800 32px var(--font-display)", letterSpacing: "-0.04em", marginTop: 8 }}>S/ 1.480</div>
                  <div style={{ font: "500 13px var(--font-body)", color: "rgba(255,255,255,.6)", marginTop: 2 }}>Ingresos del día · 12 cobros</div>
                </div>
                <Chip kind="accent">{I.trend} +24%</Chip>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 0, marginTop: 22, borderTop: "1px solid rgba(255,255,255,.1)", paddingTop: 14 }}>
                {[
                  { l: "Efectivo", v: "S/ 720", c: "6" },
                  { l: "Yape/Plin", v: "S/ 480", c: "4" },
                  { l: "Tarjeta", v: "S/ 280", c: "2" },
                ].map((s, i) => (
                  <div key={s.l} style={{ paddingLeft: i === 0 ? 0 : 14, borderLeft: i === 0 ? 0 : "1px solid rgba(255,255,255,.08)" }}>
                    <div style={{ font: "500 10.5px var(--font-body)", color: "rgba(255,255,255,.5)", textTransform: "uppercase", letterSpacing: ".06em" }}>{s.l}</div>
                    <div style={{ font: "700 18px var(--font-display)", letterSpacing: "-0.02em", marginTop: 4 }}>{s.v}</div>
                    <div style={{ font: "500 11px var(--font-mono)", color: "rgba(255,255,255,.4)" }}>{s.c} cobros</div>
                  </div>
                ))}
              </div>
            </div>
          </Card>
        </div>

        {/* Live activity */}
        <div className="section">
          <SectionTitle title="Hoy en el gym" action="En vivo"/>
          <div className="grid-2">
            <div className="kpi"><span className="l">Adentro ahora</span><span className="v">37</span><span className="d">{I.trend} +12 últ hora</span></div>
            <div className="kpi"><span className="l">Ingresos del día</span><span className="v">84</span><span className="d">{I.trend} vs 76 ayer</span></div>
            <div className="kpi"><span className="l">Activas</span><span className="v">142</span><span className="d" style={{ color: "var(--ink-2)" }}>de 168 totales</span></div>
            <div className="kpi"><span className="l">Por vencer</span><span className="v">8</span><span className="d down">próx. 7 días</span></div>
          </div>
        </div>

        {/* Pending tasks */}
        <div className="section">
          <SectionTitle title="Tu bandeja" action="3 pendientes"/>
          <div className="row-list">
            <Card style={{ padding: 14, display: "flex", gap: 12, alignItems: "center", borderLeft: "4px solid var(--warn)" }} onClick={() => go("approvePayments")}>
              <span style={{ width: 38, height: 38, borderRadius: 12, background: "color-mix(in oklab, var(--warn) 14%, white)", color: "#946b00", display: "grid", placeItems: "center" }}>{I.cash}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ font: "600 14px var(--font-body)" }}>3 pagos esperan aprobación</div>
                <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>Acreditaciones Yape · S/ 360 total</div>
              </div>
              <span style={{ color: "var(--ink-2)" }}>{I.forward}</span>
            </Card>
            <Card style={{ padding: 14, display: "flex", gap: 12, alignItems: "center", borderLeft: "4px solid var(--info)" }} onClick={() => go("inbox")}>
              <span style={{ width: 38, height: 38, borderRadius: 12, background: "color-mix(in oklab, var(--info) 14%, white)", color: "var(--info)", display: "grid", placeItems: "center" }}>{I.inbox}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ font: "600 14px var(--font-body)" }}>2 observaciones nuevas</div>
                <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>Mateo · Smith piso 2 hace ruido</div>
              </div>
              <span style={{ color: "var(--ink-2)" }}>{I.forward}</span>
            </Card>
            <Card style={{ padding: 14, display: "flex", gap: 12, alignItems: "center", borderLeft: "4px solid var(--danger)" }}>
              <span style={{ width: 38, height: 38, borderRadius: 12, background: "color-mix(in oklab, var(--danger) 12%, white)", color: "var(--danger)", display: "grid", placeItems: "center" }}>{I.warn}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ font: "600 14px var(--font-body)" }}>1 acceso denegado</div>
                <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>Diego Castro · membresía vencida hace 3d</div>
              </div>
              <span style={{ color: "var(--ink-2)" }}>{I.forward}</span>
            </Card>
          </div>
        </div>

        {/* Quick actions */}
        <div className="section">
          <SectionTitle title="Acciones rápidas"/>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10 }}>
            {[
              { ic: I.scan, l: "Escanear", g: "scan" },
              { ic: I.cash, l: "Cobrar", g: "cashRegister" },
              { ic: I.plus, l: "Usuario", g: "newMember" },
              { ic: I.megaphone, l: "Aviso", g: "newAnnouncement" },
            ].map(a => (
              <button key={a.l} onClick={() => go(a.g)} style={{ appearance: "none", border: "1px solid var(--border)", background: "var(--surface)", borderRadius: 18, padding: "16px 8px", display: "flex", flexDirection: "column", alignItems: "center", gap: 8, cursor: "pointer", font: "600 12px var(--font-body)", color: "var(--ink)" }}>
                <span style={{ width: 38, height: 38, background: "var(--surface-2)", borderRadius: 12, display: "grid", placeItems: "center" }}>{a.ic}</span>
                {a.l}
              </button>
            ))}
          </div>
        </div>

        {/* attendance graph */}
        <div className="section">
          <SectionTitle title="Asistencia · últimos 7 días"/>
          <Card>
            <div style={{ display: "flex", alignItems: "flex-end", gap: 8, height: 110 }}>
              {[42, 56, 48, 64, 71, 38, 84].map((v, i) => (
                <div key={i} style={{ flex: 1, textAlign: "center" }}>
                  <div style={{ height: `${(v / 100) * 100}%`, background: i === 6 ? "var(--accent)" : "var(--surface-3)", borderRadius: "8px 8px 0 0", display: "flex", alignItems: "flex-start", justifyContent: "center", paddingTop: 4 }}>
                    {i === 6 && <span style={{ font: "700 11px var(--font-mono)", color: "var(--accent-ink)" }}>{v}</span>}
                  </div>
                </div>
              ))}
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8, font: "500 11px var(--font-mono)", color: "var(--ink-3)" }}>
              <span>JUE</span><span>VIE</span><span>SÁB</span><span>DOM</span><span>LUN</span><span>MAR</span><span>HOY</span>
            </div>
          </Card>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// MEMBERS LIST
// ═══════════════════════════════════════════════════════════════
const ALL_MEMBERS = window.ALL_MEMBERS;

function AdminMembers({ go }) {
  const [filter, setFilter] = React.useState("Todos");
  const filters = ["Todos", "Activos", "Por vencer", "Vencidos", "En gracia"];
  return (
    <Screen>
      <Header title="Usuarios" right={<button className="h-icon" onClick={() => go("newMember")}>{I.plus}</button>}/>
      <div className="scroll has-nav">
        <div className="section">
          <Card style={{ padding: 14, display: "flex", alignItems: "center", gap: 10 }}>
            <span style={{ width: 38, height: 38, borderRadius: 12, background: "var(--surface-2)", color: "var(--ink-2)", display: "grid", placeItems: "center" }}>{I.search}</span>
            <input placeholder="Buscar por nombre o DNI…" style={{ flex: 1, border: 0, font: "500 14px var(--font-body)", background: "transparent", outline: "none" }}/>
          </Card>
        </div>

        <div className="section">
          <div style={{ display: "flex", gap: 6, overflowX: "auto", paddingBottom: 8 }}>
            {filters.map(f => (
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
              <Card key={m.dni} style={{ padding: 12, display: "flex", gap: 12, alignItems: "center", cursor: "pointer" }} onClick={() => go("memberDetail", { dni: m.dni })}>
                <Avatar name={m.n} size={44}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{m.n}</div>
                  <div style={{ font: "500 12.5px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>DNI {m.dni} · {m.plan}</div>
                </div>
                <Chip kind={m.st === "active" ? "ok" : m.st === "expired" ? "danger" : m.st === "grace" ? "warn" : ""}>
                  {m.d}
                </Chip>
              </Card>
            ))}
          </div>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ADMIN — Detail user (vista operativa)
function AdminMemberDetail({ go, params }) {
  const m = ALL_MEMBERS.find(x => x.dni === params?.dni) || ALL_MEMBERS[0];
  const isExpired = m.st === "expired";
  return (
    <Screen>
      <Header title="Detalle usuario" onBack={() => go("members")} right={<button className="h-icon">{I.more}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card>
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <Avatar name={m.n} size={64}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ font: "800 20px var(--font-display)", letterSpacing: "-0.03em" }}>{m.n}</div>
                <div style={{ font: "500 12.5px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>DNI {m.dni}</div>
                <div style={{ display: "flex", gap: 6, marginTop: 8 }}>
                  <Chip kind={m.st === "active" ? "ok" : m.st === "expired" ? "danger" : "warn"}>{m.d}</Chip>
                  <Chip>{m.plan}</Chip>
                </div>
              </div>
            </div>
            <div className="divider"/>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(2,1fr)", gap: 14 }}>
              <PhyField l="Entrenador" v={m.tr}/>
              <PhyField l="Asistencia 30d" v="18 días"/>
              <PhyField l="Celular" v="+51 987 ··· 321"/>
              <PhyField l="Email" v={m.n.split(" ")[0].toLowerCase() + "@mail.com"}/>
            </div>
          </Card>
        </div>

        {isExpired && (
          <div className="section">
            <Card style={{ padding: 16, background: "color-mix(in oklab, var(--danger) 6%, white)", borderColor: "color-mix(in oklab, var(--danger) 25%, white)" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <span style={{ width: 38, height: 38, borderRadius: 12, background: "var(--danger)", color: "#fff", display: "grid", placeItems: "center" }}>{I.warn}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ font: "700 14.5px var(--font-display)", color: "var(--danger)" }}>Membresía vencida hace 3 días</div>
                  <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>Fuera del margen de gracia</div>
                </div>
              </div>
            </Card>
          </div>
        )}

        <div className="section">
          <SectionTitle title="Historial de pagos"/>
          <div className="row-list">
            {[
              { d: "5 MAY", m: "S/ 120", k: "Yape" },
              { d: "5 ABR", m: "S/ 120", k: "Efectivo" },
              { d: "5 MAR", m: "S/ 120", k: "Plin" },
            ].map(p => (
              <div key={p.d} className="row">
                <span className="av" style={{ background: "var(--surface-3)", color: "var(--ink)" }}>{p.k.slice(0, 2).toUpperCase()}</span>
                <div className="tx">
                  <div className="nm">{p.m}</div>
                  <div className="sub">{p.k}</div>
                </div>
                <span className="tail">{p.d}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="section" style={{ display: "flex", gap: 10 }}>
          <Btn kind="ghost" block>Dar de baja</Btn>
          <Btn kind="primary" block onClick={() => go("cashRegister", { member: m.n })} leading={I.cash}>Registrar pago</Btn>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// SCANNER + VERDICT
// ═══════════════════════════════════════════════════════════════
function AdminScanner({ go }) {
  const [verdict, setVerdict] = React.useState(null);

  if (verdict === "ok") return <ScannerVerdict ok onDone={() => setVerdict(null)} go={go}/>;
  if (verdict === "bad") return <ScannerVerdict ok={false} onDone={() => setVerdict(null)} go={go}/>;

  return (
    <div className="scanner">
      <div style={{ position: "absolute", top: 14, left: 14, zIndex: 3 }}>
        <button className="iconbtn" style={{ width: 40, height: 40 }} onClick={() => go("home")}>{I.close}</button>
      </div>
      <div style={{ position: "absolute", top: 18, right: 18, zIndex: 3, display: "flex", gap: 8 }}>
        <span className="chip" style={{ background: "rgba(255,255,255,.1)", color: "#fff", border: "1px solid rgba(255,255,255,.15)" }}>● EN VIVO</span>
      </div>
      <div className="vp">
        <div className="reticle">
          <span className="c tl"/><span className="c tr"/><span className="c bl"/><span className="c br"/>
          <span className="laser"/>
        </div>
        <div style={{ position: "absolute", bottom: 110, left: 0, right: 0, textAlign: "center", color: "rgba(255,255,255,.85)", font: "700 18px var(--font-display)", letterSpacing: "-0.02em" }}>
          Apunta al QR del usuario
        </div>
        <div style={{ position: "absolute", bottom: 80, left: 0, right: 0, textAlign: "center", color: "rgba(255,255,255,.45)", font: "500 13px var(--font-body)" }}>
          o ingresa su DNI manualmente
        </div>
      </div>
      <div className="bot">
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 12 }}>
          <Btn onClick={() => setVerdict("ok")} kind="accent" block leading={I.check}>Simular ✓</Btn>
          <Btn onClick={() => setVerdict("bad")} block leading={I.close} style={{ background: "rgba(255,255,255,.1)", color: "#fff" }}>Simular ✗</Btn>
        </div>
        <Btn kind="ghost" block style={{ background: "rgba(255,255,255,.1)", color: "#fff", border: "1px solid rgba(255,255,255,.15)" }} leading={I.user}>Ingresar DNI manualmente</Btn>
      </div>
    </div>
  );
}

function ScannerVerdict({ ok, onDone, go }) {
  React.useEffect(() => {
    const t = setTimeout(onDone, 6000);
    return () => clearTimeout(t);
  }, []);
  if (ok) {
    return (
      <div style={{ position: "absolute", inset: "44px 0 0 0", background: "var(--success)", display: "flex", flexDirection: "column", color: "#fff", animation: "scrIn .2s ease" }}>
        <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", padding: 32, textAlign: "center" }}>
          <div style={{ width: 140, height: 140, borderRadius: "50%", background: "#fff", color: "var(--success)", display: "grid", placeItems: "center", boxShadow: "0 0 0 18px rgba(255,255,255,.2)" }}>
            <svg width="76" height="76" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round"><path d="m5 12 5 5L20 6"/></svg>
          </div>
          <div style={{ font: "800 44px var(--font-display)", letterSpacing: "-0.04em", marginTop: 36 }}>ACCESO</div>
          <div style={{ font: "800 44px var(--font-display)", letterSpacing: "-0.04em", marginTop: -6 }}>CONCEDIDO</div>
          <div className="divider" style={{ width: 80, background: "rgba(255,255,255,.4)", marginTop: 22 }}/>
          <div style={{ display: "flex", alignItems: "center", gap: 14, marginTop: 22 }}>
            <Avatar name="Mateo Salas" size={56}/>
            <div style={{ textAlign: "left" }}>
              <div style={{ font: "700 20px var(--font-display)", letterSpacing: "-0.02em" }}>Mateo Salas</div>
              <div style={{ font: "500 13px var(--font-body)", opacity: .85, marginTop: 2 }}>Mensual · 14 días restantes</div>
            </div>
          </div>
        </div>
        <div style={{ padding: "20px 22px 28px" }}>
          <Btn kind="primary" block size="lg" onClick={() => go("scan")} style={{ background: "var(--ink)" }}>Siguiente ingreso</Btn>
        </div>
      </div>
    );
  }
  return (
    <div style={{ position: "absolute", inset: "44px 0 0 0", background: "var(--danger)", display: "flex", flexDirection: "column", color: "#fff", animation: "scrIn .2s ease" }}>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", padding: 32, textAlign: "center" }}>
        <div style={{ width: 140, height: 140, borderRadius: "50%", background: "#fff", color: "var(--danger)", display: "grid", placeItems: "center", boxShadow: "0 0 0 18px rgba(255,255,255,.2)" }}>
          <svg width="76" height="76" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round"><path d="m6 6 12 12M18 6 6 18"/></svg>
        </div>
        <div style={{ font: "800 44px var(--font-display)", letterSpacing: "-0.04em", marginTop: 36 }}>ACCESO</div>
        <div style={{ font: "800 44px var(--font-display)", letterSpacing: "-0.04em", marginTop: -6 }}>DENEGADO</div>
        <div className="divider" style={{ width: 80, background: "rgba(255,255,255,.4)", marginTop: 22 }}/>
        <div style={{ display: "flex", alignItems: "center", gap: 14, marginTop: 22 }}>
          <Avatar name="Diego Castro" size={56}/>
          <div style={{ textAlign: "left" }}>
            <div style={{ font: "700 20px var(--font-display)", letterSpacing: "-0.02em" }}>Diego Castro</div>
            <div style={{ font: "500 13px var(--font-body)", opacity: .85, marginTop: 2 }}>Membresía vencida hace 3 días</div>
          </div>
        </div>
      </div>
      <div style={{ padding: "20px 22px 28px", display: "flex", gap: 10 }}>
        <Btn kind="ghost" block onClick={() => go("scan")} style={{ background: "rgba(255,255,255,.15)", color: "#fff", border: "1px solid rgba(255,255,255,.25)" }}>Reintentar</Btn>
        <Btn kind="primary" block onClick={() => go("cashRegister")} style={{ background: "var(--ink)" }} leading={I.cash}>Cobrar</Btn>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CASH REGISTER
// ═══════════════════════════════════════════════════════════════
function CashRegister({ go }) {
  const [member, setMember] = React.useState(null);
  const [plan, setPlan] = React.useState("Mensual");
  const [method, setMethod] = React.useState("cash");
  const planP = { Mensual: 120, Trimestral: 320, Anual: 1080 };
  return (
    <Screen>
      <Header title="Registrar cobro" onBack={() => go("home")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <SectionTitle title="Usuario"/>
          {!member ? (
            <Card style={{ padding: 14, display: "flex", alignItems: "center", gap: 10, cursor: "pointer" }} onClick={() => setMember("Diego Castro")}>
              <span style={{ width: 38, height: 38, borderRadius: 12, background: "var(--surface-2)", color: "var(--ink-2)", display: "grid", placeItems: "center" }}>{I.search}</span>
              <input placeholder="Buscar por nombre o DNI…" style={{ flex: 1, border: 0, font: "500 14px var(--font-body)", background: "transparent", outline: "none" }}/>
            </Card>
          ) : (
            <Card style={{ padding: 12, display: "flex", alignItems: "center", gap: 12 }}>
              <Avatar name={member} size={44}/>
              <div style={{ flex: 1 }}>
                <div style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{member}</div>
                <div style={{ font: "500 12.5px var(--font-body)", color: "var(--danger)", marginTop: 2 }}>● Vencida hace 3 días</div>
              </div>
              <button onClick={() => setMember(null)} className="h-icon" style={{ width: 32, height: 32 }}>{I.close}</button>
            </Card>
          )}
        </div>

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

        <div className="section">
          <Card className="flat" style={{ padding: 18 }}>
            <div style={{ display: "flex", justifyContent: "space-between", font: "500 13px var(--font-body)", color: "var(--ink-2)" }}>
              <span>Total a cobrar</span>
              <span>{plan} · 30d</span>
            </div>
            <div style={{ font: "800 38px var(--font-display)", letterSpacing: "-0.04em", marginTop: 6 }}>S/ {planP[plan]}<span style={{ font: "500 14px var(--font-body)", color: "var(--ink-2)" }}>.00</span></div>
          </Card>
        </div>

        <div className="section">
          <Btn kind="primary" block size="lg" disabled={!member} onClick={() => go("home")} leading={I.check}>Confirmar pago</Btn>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// APPROVE MANUAL PAYMENTS
// ═══════════════════════════════════════════════════════════════
function ApprovePayments({ go }) {
  const items = [
    { n: "Ana Torres",    m: "S/ 120", k: "Yape", t: "Hace 12 min" },
    { n: "Pedro Quispe",  m: "S/ 120", k: "Plin", t: "Hace 1 h" },
    { n: "Camila Rojas",  m: "S/ 320", k: "Yape", t: "Hace 3 h" },
  ];
  return (
    <Screen>
      <Header title="Aprobar pagos" onBack={() => go("home")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card className="flat" style={{ padding: 14 }}>
            <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)" }}>Pagos pendientes de aprobación</div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 8, marginTop: 4 }}>
              <span style={{ font: "800 28px var(--font-display)", letterSpacing: "-0.03em" }}>3</span>
              <span style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}>· S/ 560 total</span>
            </div>
          </Card>
        </div>

        <div className="section">
          <div className="row-list">
            {items.map((it, i) => (
              <Card key={i} style={{ padding: 14 }}>
                <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                  <Avatar name={it.n} size={44}/>
                  <div style={{ flex: 1 }}>
                    <div style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{it.n}</div>
                    <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{it.m} · {it.k} · {it.t}</div>
                  </div>
                  <Chip kind="warn">Pendiente</Chip>
                </div>
                <div style={{ marginTop: 12, height: 100, background: "var(--surface-2)", borderRadius: 14, position: "relative", overflow: "hidden", border: "1px solid var(--border)" }}>
                  <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, #2a4d70, #1a2a3f)", display: "grid", placeItems: "center" }}>
                    <div style={{ color: "rgba(255,255,255,.8)", font: "600 12px var(--font-mono)" }}>📱 Comprobante {it.k}</div>
                  </div>
                </div>
                <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
                  <Btn kind="ghost" block>Rechazar</Btn>
                  <Btn kind="primary" block leading={I.check}>Aprobar S/ {it.m.replace("S/ ", "")}</Btn>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// CASH DAY VIEW
// ═══════════════════════════════════════════════════════════════
function AdminCash({ go }) {
  return (
    <Screen>
      <Header title="Caja" right={<button className="h-icon">{I.filter}</button>}/>
      <div className="scroll has-nav">
        <div className="section">
          <Card className="dark" style={{ padding: 18, border: 0, textAlign: "center" }}>
            <div style={{ font: "600 11.5px var(--font-mono)", color: "var(--accent)", letterSpacing: ".08em", textTransform: "uppercase" }}>● HOY · MIÉRCOLES 21</div>
            <div style={{ font: "800 44px var(--font-display)", letterSpacing: "-0.04em", marginTop: 10 }}>S/ 1.480</div>
            <div style={{ font: "500 13px var(--font-body)", color: "rgba(255,255,255,.6)", marginTop: 2 }}>12 cobros del día</div>
          </Card>
        </div>

        <div className="section">
          <div className="grid-2">
            <div className="kpi"><span className="l">Esta semana</span><span className="v">S/ 6.220</span><span className="d">{I.trend} +18%</span></div>
            <div className="kpi"><span className="l">Este mes</span><span className="v">S/ 21.400</span><span className="d">{I.trend} +12%</span></div>
          </div>
        </div>

        <div className="section">
          <SectionTitle title="Cobros recientes"/>
          <div className="row-list">
            {[
              { n: "Mateo Salas",    t: "8:42",  m: "S/ 120", k: "Yape" },
              { n: "Lucía F.",       t: "9:14",  m: "S/ 320", k: "Efectivo" },
              { n: "Jorge P.",       t: "10:02", m: "S/ 1.080", k: "Tarjeta" },
              { n: "Rosa M.",        t: "11:30", m: "S/ 120", k: "Yape" },
              { n: "Camila R.",      t: "12:18", m: "S/ 120", k: "Efectivo" },
            ].map((c, i) => (
              <div key={i} className="row">
                <Avatar name={c.n} size={42}/>
                <div className="tx">
                  <div className="nm">{c.n}</div>
                  <div className="sub">{c.k} · {c.t}</div>
                </div>
                <span style={{ font: "700 14px var(--font-display)", letterSpacing: "-0.02em" }}>{c.m}</span>
              </div>
            ))}
          </div>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// MORE (Inbox, Anuncios, Clases, Reportes)
// ═══════════════════════════════════════════════════════════════
function AdminMore({ go, onLogout }) {
  return (
    <Screen>
      <Header title="Más"/>
      <div className="scroll has-nav">
        <div className="section">
          <SectionTitle title="Operaciones"/>
          <div className="row-list">
            {[
              { i: I.inbox, l: "Buzón de observaciones", s: "2 nuevas", g: "inbox" },
              { i: I.megaphone, l: "Anuncios", s: "3 publicados", g: "newAnnouncement" },
              { i: I.calendar, l: "Clases y horarios", s: "12 clases activas", g: "classes" },
              { i: I.cash, l: "Aprobar pagos manuales", s: "3 pendientes", g: "approvePayments" },
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
          <SectionTitle title="Inventario y ventas"/>
          <div className="row-list">
            {[
              { i: I.dumbbell, l: "Productos (CRUD completo)", s: "8 activos · 1 con bajo stock", g: "adminProducts" },
              { i: I.chart, l: "Ventas e ingresos", s: "S/ 21.400 este mes", g: "reports" },
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
          <SectionTitle title="Personal y seguridad"/>
          <div className="row-list">
            {[
              { i: I.people, l: "Cuentas de Caja", s: "2 cajeros activos", g: "cashiers" },
              { i: I.user, l: "Entrenadores", s: "3 entrenadores", g: "trainers" },
              { i: I.scan, l: "Log de auditoría", s: "Toda acción de Caja / Trainer", g: "auditLog" },
              { i: I.chart, l: "Reportes generales", s: "Asistencia · pagos · retención", g: "reports" },
              { i: I.settings, l: "Configuración del gym", s: "Perfil · planes · día de gracia", g: "settings" },
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
          <Btn kind="ghost" block onClick={onLogout}>Cerrar sesión</Btn>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// INBOX OBSERVACIONES
function AdminInbox({ go }) {
  const items = [
    { n: "Mateo Salas",    t: "Smith piso 2 hace ruido extraño al subir", time: "Hace 12 min", tag: "Equipamiento", img: true, st: "new" },
    { n: "Lucía Fernández", t: "Vestidores con poca luz en zona femenina",  time: "Hace 2 h",   tag: "Limpieza",    img: false, st: "new" },
    { n: "Jorge Paredes",  t: "Sugerencia: clase de boxeo en la mañana",     time: "Ayer",       tag: "Sugerencia",  img: false, st: "done" },
    { n: "Rosa Mendieta",  t: "Bidón de agua del piso 1 vacío hace 2 días", time: "Hace 2 d",   tag: "Limpieza",    img: true,  st: "done" },
  ];
  return (
    <Screen>
      <Header title="Buzón de observaciones" onBack={() => go("more")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <div className="row-list">
            {items.map((it, i) => (
              <Card key={i} style={{ padding: 14 }}>
                <div style={{ display: "flex", gap: 12 }}>
                  <Avatar name={it.n} size={42}/>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <span style={{ font: "700 14px var(--font-display)", letterSpacing: "-0.02em" }}>{it.n}</span>
                      {it.st === "new" && <span style={{ width: 6, height: 6, background: "var(--info)", borderRadius: "50%" }}/>}
                    </div>
                    <div style={{ font: "500 12.5px var(--font-mono)", color: "var(--ink-3)", marginTop: 2 }}>{it.tag} · {it.time}</div>
                    <div style={{ font: "500 13.5px var(--font-body)", color: "var(--ink)", marginTop: 8, textWrap: "pretty" }}>{it.t}</div>
                    {it.img && (
                      <div style={{ marginTop: 10, height: 110, background: "linear-gradient(135deg, #2a4d70, #1a2a3f)", borderRadius: 12, display: "grid", placeItems: "center", color: "rgba(255,255,255,.7)", font: "600 12px var(--font-mono)" }}>
                        📷 Adjunto
                      </div>
                    )}
                  </div>
                </div>
                {it.st === "new" && (
                  <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
                    <Btn kind="ghost" block>Archivar</Btn>
                    <Btn kind="primary" block leading={I.check}>Marcar resuelta</Btn>
                  </div>
                )}
              </Card>
            ))}
          </div>
        </div>
      </div>
    </Screen>
  );
}

// NEW ANNOUNCEMENT
function NewAnnouncement({ go }) {
  return (
    <Screen>
      <Header title="Nuevo aviso" onBack={() => go("more")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card>
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="field">
                <label>Etiqueta</label>
                <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                  {["EVENTO", "AVISO", "PROMO", "URGENTE"].map((t, i) => (
                    <span key={t} className={`chip ${i === 0 ? "accent" : ""}`}>{t}</span>
                  ))}
                </div>
              </div>
              <div className="field">
                <label>Título</label>
                <input defaultValue="Clases gratis este sábado"/>
              </div>
              <div className="field">
                <label>Descripción</label>
                <textarea rows="4" defaultValue="Funcional al aire libre 8am · Parque Kennedy. Trae a un amigo y entrenen juntos. Cupo limitado." style={{ resize: "none" }}/>
              </div>
              <div className="field">
                <label>Imagen destacada (opcional)</label>
                <div style={{ height: 100, border: "2px dashed var(--border-strong)", borderRadius: 14, display: "grid", placeItems: "center", color: "var(--ink-2)" }}>
                  <div style={{ textAlign: "center" }}>
                    {I.upload}
                    <div style={{ marginTop: 6, font: "600 12.5px var(--font-body)" }}>Subir imagen</div>
                  </div>
                </div>
              </div>
              <Card className="flat" style={{ padding: 12, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                <div>
                  <div style={{ font: "600 13px var(--font-body)" }}>Enviar notificación push</div>
                  <div style={{ font: "500 11.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>168 miembros activos</div>
                </div>
                <Toggle on={true}/>
              </Card>
            </div>
          </Card>
        </div>
        <div className="section">
          <Btn kind="primary" size="lg" block onClick={() => go("more")} leading={I.send}>Publicar aviso</Btn>
        </div>
      </div>
    </Screen>
  );
}

// CLASSES MANAGEMENT
function AdminClasses({ go }) {
  return (
    <Screen>
      <Header title="Clases y horarios" onBack={() => go("more")} right={<button className="h-icon">{I.plus}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <SectionTitle title="Activas · 12"/>
          <div className="row-list">
            {[
              { n: "CrossTraining matutino", tr: "Carlos M.", d: "L M V · 7am",  cupo: "12 / 12", st: "full" },
              { n: "Funcional",              tr: "Lucía F.",  d: "L X V · 6am",  cupo: "8 / 12",  st: "ok"   },
              { n: "Yoga",                   tr: "Andrea S.", d: "Ma J · 10am",  cupo: "4 / 10",  st: "ok"   },
              { n: "Spinning",               tr: "Andrea S.", d: "L M V · 7pm",  cupo: "10 / 12", st: "ok"   },
              { n: "HIIT",                   tr: "Jorge P.",  d: "Ma J · 5:30pm", cupo: "9 / 14", st: "ok"   },
            ].map((c, i) => (
              <Card key={i} style={{ padding: 14, display: "flex", gap: 12, alignItems: "center" }}>
                <span className="av" style={{ background: "var(--ink)", color: "var(--accent)" }}>{I.bolt}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{c.n}</div>
                  <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{c.tr} · {c.d}</div>
                </div>
                <Chip kind={c.st === "full" ? "warn" : "ok"}>{c.cupo}</Chip>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </Screen>
  );
}

// REPORTS
function AdminReports({ go }) {
  return (
    <Screen>
      <Header title="Reportes" onBack={() => go("more")} right={<button className="h-icon">{I.filter}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <div className="grid-2">
            <div className="kpi"><span className="l">Retención 90d</span><span className="v">84%</span><span className="d">{I.trend} +6 pp</span></div>
            <div className="kpi"><span className="l">Asistencia prom.</span><span className="v">18×</span><span className="d">por mes/usr</span></div>
            <div className="kpi"><span className="l">Nuevos</span><span className="v">14</span><span className="d">este mes</span></div>
            <div className="kpi"><span className="l">Bajas</span><span className="v">3</span><span className="d down">vs 1 anterior</span></div>
          </div>
        </div>

        <div className="section">
          <SectionTitle title="Ingresos · últimos 6 meses"/>
          <Card>
            <div style={{ display: "flex", alignItems: "flex-end", gap: 8, height: 140 }}>
              {[
                { m: "DIC", v: 14 },
                { m: "ENE", v: 17 },
                { m: "FEB", v: 16 },
                { m: "MAR", v: 19 },
                { m: "ABR", v: 21 },
                { m: "MAY", v: 21 },
              ].map((d, i) => (
                <div key={d.m} style={{ flex: 1, textAlign: "center" }}>
                  <div style={{ height: `${(d.v / 25) * 100}%`, background: i === 5 ? "var(--accent)" : "var(--ink)", borderRadius: "8px 8px 0 0" }}/>
                  <div style={{ font: "500 10px var(--font-mono)", color: "var(--ink-3)", marginTop: 6 }}>{d.m}</div>
                </div>
              ))}
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginTop: 14 }}>
              <div>
                <div style={{ font: "500 11px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>Mayo (parcial)</div>
                <div style={{ font: "800 24px var(--font-display)", letterSpacing: "-0.03em", marginTop: 4 }}>S/ 21.400</div>
              </div>
              <Chip kind="accent">+12% vs abr</Chip>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Distribución de planes"/>
          <Card>
            <div className="row-list">
              {[
                { l: "Mensual",    p: 62, c: "var(--ink)" },
                { l: "Trimestral", p: 28, c: "var(--accent)" },
                { l: "Anual",      p: 10, c: "var(--info)" },
              ].map(d => (
                <div key={d.l}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6, font: "600 13px var(--font-body)" }}>
                    <span>{d.l}</span>
                    <span style={{ font: "700 13px var(--font-mono)" }}>{d.p}%</span>
                  </div>
                  <div className="bar tall"><i style={{ width: `${d.p}%`, background: d.c }}/></div>
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </Screen>
  );
}

// SETTINGS
function AdminSettings({ go }) {
  return (
    <Screen>
      <Header title="Configuración del gym" onBack={() => go("more")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card>
            <Field l="Nombre comercial" v="SaaaS GYM Miraflores"/>
            <Field l="RUC" v="20 481 234 567"/>
            <Field l="Dirección" v="Av. Larco 1234 · Miraflores"/>
            <Field l="Horario" v="L–V 5am–11pm · S/D 7am–9pm"/>
            <Field l="Teléfono" v="+51 1 234 5678"/>
          </Card>
        </div>
        <div className="section">
          <SectionTitle title="Reglas operativas"/>
          <Card>
            <Field l="Día de gracia post-vencimiento" v="1 día"/>
            <Field l="Aviso pre-vencimiento" v="7 días antes"/>
            <Field l="Recordatorio post-vencimiento" v="Diario"/>
            <Field l="QR usuario · rotación" v="60 segundos"/>
          </Card>
        </div>
      </div>
    </Screen>
  );
}

function NewMember({ go }) {
  return (
    <Screen>
      <Header title="Nuevo usuario" onBack={() => go("members")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card>
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="field"><label>Nombre completo</label><input placeholder="Ej. María García López"/></div>
              <div className="field"><label>DNI</label><input placeholder="8 dígitos"/></div>
              <div className="field"><label>Celular</label><input placeholder="+51 9·· ··· ···"/></div>
              <div className="field"><label>Correo</label><input placeholder="usuario@mail.com"/></div>
              <div className="field">
                <label>Plan inicial</label>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
                  {["Mensual", "Trimestral", "Anual"].map((p, i) => (
                    <span key={p} className={`chip ${i === 0 ? "solid" : ""}`} style={{ justifyContent: "center" }}>{p}</span>
                  ))}
                </div>
              </div>
              <div className="field">
                <label>Entrenador asignado (opcional)</label>
                <input placeholder="Buscar entrenador…"/>
              </div>
            </div>
          </Card>
        </div>
        <div className="section">
          <Btn kind="primary" size="lg" block onClick={() => go("members")} leading={I.check}>Crear y cobrar</Btn>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// ROUTER
// ═══════════════════════════════════════════════════════════════
function AdminApp() {
  const { screen, params, go } = useRouter("home");
  const [authed, setAuthed] = React.useState(false);

  if (!authed) return <LoginScreen role="admin" onLogin={() => setAuthed(true)}/>;

  const isScan = screen === "scan";
  const hideNav = isScan;

  const navCurrent = ({
    home: "home", notifications: "home",
    members: "members", memberDetail: "members", newMember: "members",
    scan: "scan",
    cash: "cash", cashRegister: "cash", approvePayments: "cash",
    more: "more", inbox: "more", newAnnouncement: "more", classes: "more", reports: "more", settings: "more",
    cashiers: "more", newCashier: "more", editCashier: "more", trainers: "more", auditLog: "more", adminProducts: "more", editAdminProduct: "more",
  })[screen] || "home";

  return (
    <>
      {screen === "home" && <AdminHome go={go}/>}
      {screen === "members" && <AdminMembers go={go}/>}
      {screen === "memberDetail" && <AdminMemberDetail go={go} params={params}/>}
      {screen === "newMember" && <NewMember go={go}/>}
      {screen === "scan" && <AdminScanner go={go}/>}
      {screen === "cash" && <AdminCash go={go}/>}
      {screen === "cashRegister" && <CashRegister go={go}/>}
      {screen === "approvePayments" && <ApprovePayments go={go}/>}
      {screen === "more" && <AdminMore go={go} onLogout={() => setAuthed(false)}/>}
      {screen === "inbox" && <AdminInbox go={go}/>}
      {screen === "newAnnouncement" && <NewAnnouncement go={go}/>}
      {screen === "classes" && <AdminClasses go={go}/>}
      {screen === "reports" && <AdminReports go={go}/>}
      {screen === "settings" && <AdminSettings go={go}/>}
      {screen === "cashiers" && <AdminCashiers go={go}/>}
      {screen === "newCashier" && <NewCashier go={go}/>}
      {screen === "editCashier" && <EditCashier go={go} params={params}/>}
      {screen === "trainers" && <AdminTrainers go={go}/>}
      {screen === "auditLog" && <AdminAuditLog go={go}/>}
      {screen === "adminProducts" && <AdminProducts go={go}/>}
      {screen === "editAdminProduct" && <EditAdminProduct go={go} params={params}/>}
      {screen === "notifications" && <MemberNotifications go={go}/>}

      {!hideNav && (
        <div className="bnav-overlay">
          <BottomNav items={ADMIN_NAV} current={navCurrent} onChange={(id) => go(id)}/>
        </div>
      )}
    </>
  );
}

// ═══════════════════════════════════════════════════════════════
// ADMIN · CASHIER ACCOUNTS (gestión de cajeros con horario)
// ═══════════════════════════════════════════════════════════════
const CASHIERS = [
  { id: "CJ-001", n: "Roberto Vega",   shift: "14:00 – 22:00", st: "active",  last: "Activa ahora",   ses: 312 },
  { id: "CJ-002", n: "Mariana Quispe", shift: "06:00 – 14:00", st: "active",  last: "En turno",       ses: 218 },
  { id: "CJ-003", n: "Sofía Ríos",     shift: "S/D 08:00 – 16:00", st: "inactive", last: "Hace 8 días", ses: 47  },
];

function AdminCashiers({ go }) {
  return (
    <Screen>
      <Header title="Cuentas de Caja" onBack={() => go("more")} right={<button className="h-icon" onClick={() => go("newCashier")}>{I.plus}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <div className="grid-2">
            <div className="kpi"><span className="l">Cajeros activos</span><span className="v">2</span><span className="d">{I.trend} En turno</span></div>
            <div className="kpi"><span className="l">Sesiones del mes</span><span className="v">142</span><span className="d">de 3 cuentas</span></div>
          </div>
        </div>

        <div className="section">
          <SectionTitle title="Cuentas registradas"/>
          <div className="row-list">
            {CASHIERS.map(c => (
              <Card key={c.id} style={{ padding: 14, cursor: "pointer" }} onClick={() => go("editCashier", { id: c.id })}>
                <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                  <Avatar name={c.n} size={48}/>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <span style={{ font: "700 15px var(--font-display)", letterSpacing: "-0.02em" }}>{c.n}</span>
                      <Chip kind={c.st === "active" ? "ok" : ""} size="">{c.id}</Chip>
                    </div>
                    <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 4, display: "flex", alignItems: "center", gap: 6 }}>
                      {I.clock} <span>{c.shift}</span>
                    </div>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    <Chip kind={c.last === "En turno" ? "accent" : c.st === "active" ? "" : "warn"}>{c.last}</Chip>
                    <div style={{ font: "500 11px var(--font-mono)", color: "var(--ink-3)", marginTop: 4 }}>{c.ses} sesiones</div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        <div className="section">
          <Card className="flat" style={{ padding: 14, display: "flex", gap: 12, alignItems: "flex-start" }}>
            <span style={{ width: 36, height: 36, borderRadius: 10, background: "var(--ink)", color: "var(--accent)", display: "grid", placeItems: "center", flexShrink: 0 }}>{I.warn}</span>
            <div style={{ flex: 1, font: "500 12.5px/1.5 var(--font-body)", color: "var(--ink-2)", textWrap: "pretty" }}>
              Las cuentas de Caja solo pueden ingresar dentro de su horario. Fuera de turno, el sistema cierra la sesión automáticamente.
            </div>
          </Card>
        </div>
      </div>
    </Screen>
  );
}

// NEW CASHIER (Admin crea cuenta de caja con horario)
function NewCashier({ go }) {
  const [days, setDays] = React.useState(["MON", "TUE", "WED", "THU", "FRI"]);
  const toggle = (d) => setDays(days.includes(d) ? days.filter(x => x !== d) : [...days, d]);
  return (
    <Screen>
      <Header title="Nuevo cajero" onBack={() => go("cashiers")}/>
      <div className="scroll" style={{ paddingBottom: 120 }}>
        <div className="section">
          <SectionTitle title="Datos del cajero"/>
          <Card>
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="field"><label>Nombre completo</label><input placeholder="Ej. Roberto Vega Salinas"/></div>
              <div className="field"><label>DNI</label><input placeholder="8 dígitos"/></div>
              <div className="field"><label>Correo</label><input placeholder="cajero@saaasgym.pe"/></div>
              <div className="field"><label>Celular</label><input placeholder="+51 9·· ··· ···"/></div>
              <div className="field"><label>Contraseña temporal</label><input placeholder="Se enviará por email" defaultValue="CJ-2026-4f9k"/></div>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Turno asignado"/>
          <Card>
            <div style={{ font: "500 11px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>DÍAS LABORALES</div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(7, 1fr)", gap: 6, marginTop: 10 }}>
              {[
                { id: "MON", l: "L" }, { id: "TUE", l: "M" }, { id: "WED", l: "X" },
                { id: "THU", l: "J" }, { id: "FRI", l: "V" }, { id: "SAT", l: "S" }, { id: "SUN", l: "D" },
              ].map(d => {
                const on = days.includes(d.id);
                return (
                  <button key={d.id} onClick={() => toggle(d.id)} style={{
                    aspectRatio: "1", border: "2px solid " + (on ? "var(--ink)" : "var(--border)"),
                    background: on ? "var(--ink)" : "var(--surface)",
                    color: on ? "#fff" : "var(--ink-2)",
                    borderRadius: 10, cursor: "pointer",
                    font: "700 16px var(--font-display)", letterSpacing: "-0.02em",
                  }}>{d.l}</button>
                );
              })}
            </div>
            <div style={{ height: 18 }}/>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
              <div className="field"><label>Hora inicio</label><input type="time" defaultValue="06:00"/></div>
              <div className="field"><label>Hora fin</label><input type="time" defaultValue="14:00"/></div>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Permisos asignados"/>
          <Card style={{ padding: 0, overflow: "hidden" }}>
            {[
              { l: "Registrar cobros (membresías + productos)", on: true,  fixed: true },
              { l: "Registrar asistencias (escanear QR)",       on: true,  fixed: false },
              { l: "Crear y editar usuarios",                    on: true,  fixed: false },
              { l: "Dar de baja lógica a usuarios",              on: true,  fixed: false },
              { l: "Crear productos nuevos",                     on: true,  fixed: false },
              { l: "Ajustar precios y stock",                    on: true,  fixed: false },
              { l: "Eliminar productos (físicamente)",           on: false, fixed: true },
              { l: "Eliminación física de usuarios",             on: false, fixed: true },
              { l: "Aprobar pagos manuales",                     on: false, fixed: false },
            ].map((p, i) => (
              <div key={p.l} style={{ display: "flex", alignItems: "center", padding: 14, borderTop: i === 0 ? 0 : "1px solid var(--border)", gap: 10 }}>
                <div style={{ flex: 1, font: "500 13.5px var(--font-body)", color: p.fixed && !p.on ? "var(--ink-3)" : "var(--ink)" }}>{p.l}</div>
                {p.fixed
                  ? <Chip kind={p.on ? "ok" : ""}>{p.on ? "Siempre activo" : "Solo Admin"}</Chip>
                  : <Toggle on={p.on}/>}
              </div>
            ))}
          </Card>
        </div>
      </div>
      <div className="sticky-cta">
        <Btn kind="primary" block size="lg" onClick={() => go("cashiers")} leading={I.send}>Crear cuenta y enviar credenciales</Btn>
      </div>
    </Screen>
  );
}

function EditCashier({ go, params }) {
  const c = CASHIERS.find(x => x.id === params?.id) || CASHIERS[0];
  return (
    <Screen>
      <Header title={c.n} onBack={() => go("cashiers")} right={<button className="h-icon">{I.more}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card>
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <Avatar name={c.n} size={64}/>
              <div style={{ flex: 1 }}>
                <div style={{ font: "800 20px var(--font-display)", letterSpacing: "-0.03em" }}>{c.n}</div>
                <div style={{ font: "500 12.5px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>{c.id} · Caja</div>
                <div style={{ display: "flex", gap: 6, marginTop: 8 }}>
                  <Chip kind={c.st === "active" ? "ok" : ""}>{c.last}</Chip>
                </div>
              </div>
            </div>
            <div className="divider"/>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
              <PhyField l="Turno" v={c.shift}/>
              <PhyField l="Sesiones" v={c.ses}/>
              <PhyField l="Ventas mes" v="S/ 8.450"/>
              <PhyField l="Ingresos cobrados" v="S/ 14.220"/>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Acciones de este cajero" action="Ver log completo →" onAction={() => go("auditLog")}/>
          <Card style={{ padding: 0, overflow: "hidden" }}>
            {[
              { t: "Hoy 11:30", a: "Cobró membresía Rosa Mendieta · S/ 120" },
              { t: "Hoy 10:22", a: "Cobró membresía Jorge Paredes · S/ 1.080" },
              { t: "Hoy 09:14", a: "Editó usuario Ana Torres" },
              { t: "Ayer 12:14", a: "Creó producto 'Bebida isotónica 500ml'" },
              { t: "Ayer 09:30", a: "Baja lógica · Carmen Vega" },
            ].map((l, i) => (
              <div key={i} style={{ padding: 12, borderTop: i === 0 ? 0 : "1px solid var(--border)" }}>
                <div style={{ font: "600 13px var(--font-body)" }}>{l.a}</div>
                <div style={{ font: "500 11px var(--font-mono)", color: "var(--ink-3)", marginTop: 2 }}>{l.t}</div>
              </div>
            ))}
          </Card>
        </div>

        <div className="section" style={{ display: "flex", gap: 10 }}>
          <Btn kind="ghost" block>Editar turno</Btn>
          <Btn kind="danger-soft" block leading={I.close}>Suspender cuenta</Btn>
        </div>
      </div>
    </Screen>
  );
}

// ADMIN TRAINERS (gestión de cuentas de entrenador)
function AdminTrainers({ go }) {
  const trainers = [
    { n: "Carlos Mendoza", esp: "Fuerza & Hipertrofia", al: 7, st: "active" },
    { n: "Andrea Soto",    esp: "Yoga & Spinning",      al: 4, st: "active" },
    { n: "Lucía Flores",   esp: "Funcional & HIIT",     al: 5, st: "active" },
  ];
  return (
    <Screen>
      <Header title="Entrenadores" onBack={() => go("more")} right={<button className="h-icon">{I.plus}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <SectionTitle title={`${trainers.length} entrenadores activos`}/>
          <div className="row-list">
            {trainers.map(t => (
              <Card key={t.n} style={{ padding: 12, display: "flex", gap: 12, alignItems: "center" }}>
                <Avatar name={t.n} size={48}/>
                <div style={{ flex: 1 }}>
                  <div style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{t.n}</div>
                  <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{t.esp}</div>
                </div>
                <Chip kind="ok">{t.al} alumnos</Chip>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// ADMIN · AUDIT LOG (acciones de todos los usuarios)
// ═══════════════════════════════════════════════════════════════
function AdminAuditLog({ go }) {
  const [filter, setFilter] = React.useState("Todo");
  const logs = [
    { t: "11:30",  who: "Mariana Q.", role: "Caja",    ac: "Cobró membresía",      d: "Rosa Mendieta · S/ 120 · Yape",     ic: I.cash, c: "var(--success)" },
    { t: "10:22",  who: "Mariana Q.", role: "Caja",    ac: "Cobró membresía",      d: "Jorge Paredes · S/ 1.080 · Tarjeta", ic: I.cash, c: "var(--success)" },
    { t: "09:48",  who: "Mariana Q.", role: "Caja",    ac: "Vendió producto",      d: "Polo oficial L · S/ 45 · Yape",      ic: I.dumbbell, c: "var(--info)" },
    { t: "09:30",  who: "Carlos M.",  role: "Trainer", ac: "Publicó rutina",       d: "Push · Pecho+Hombros → Mateo Salas", ic: I.bolt, c: "var(--accent-ink)", b: "var(--accent)" },
    { t: "09:14",  who: "Mariana Q.", role: "Caja",    ac: "Editó usuario",        d: "Ana Torres · celular actualizado",   ic: I.edit, c: "var(--warn)" },
    { t: "08:42",  who: "Mariana Q.", role: "Caja",    ac: "Registró asistencia",  d: "Mateo Salas · QR escaneado",         ic: I.scan, c: "var(--ink-2)" },
    { t: "08:00",  who: "Mariana Q.", role: "Caja",    ac: "Inició sesión",        d: "Turno mañana · IP 192.168.1.45",     ic: I.user, c: "var(--info)" },
    { t: "Ayer 22:14", who: "Roberto V.", role: "Caja", ac: "Cerró sesión",        d: "Fin de turno · saldo S/ 3.420",      ic: I.close, c: "var(--ink-2)" },
    { t: "Ayer 18:42", who: "Roberto V.", role: "Caja", ac: "Aprobó acreditación", d: "Camila Rojas · S/ 320 · Plin",       ic: I.check, c: "var(--success)" },
    { t: "Ayer 12:14", who: "Mariana Q.", role: "Caja", ac: "Creó producto",       d: "Bebida isotónica 500ml · S/ 6",      ic: I.plus, c: "var(--accent-ink)", b: "var(--accent)" },
    { t: "Ayer 09:30", who: "Mariana Q.", role: "Caja", ac: "Baja lógica usuario", d: "Carmen Vega · DNI 71223344",         ic: I.trash, c: "var(--danger)" },
  ];

  const filters = ["Todo", "Caja", "Trainer", "Admin", "Críticos"];
  const filtered = filter === "Todo"
    ? logs
    : filter === "Críticos"
      ? logs.filter(l => l.c === "var(--danger)" || l.ac.includes("Baja"))
      : logs.filter(l => l.role === filter);

  return (
    <Screen>
      <Header title="Log de auditoría" onBack={() => go("more")} right={<button className="h-icon">{I.filter}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card className="dark" style={{ padding: 16 }}>
            <div style={{ font: "600 11.5px var(--font-mono)", color: "var(--accent)", letterSpacing: ".08em", textTransform: "uppercase" }}>● AUDITORÍA</div>
            <div style={{ font: "800 28px var(--font-display)", letterSpacing: "-0.04em", marginTop: 6 }}>{logs.length} eventos hoy</div>
            <div style={{ font: "500 12.5px var(--font-body)", color: "rgba(255,255,255,.6)", marginTop: 2 }}>De 3 cuentas activas · Caja, Trainer</div>
          </Card>
        </div>

        <div className="section">
          <div style={{ display: "flex", gap: 6, overflowX: "auto", paddingBottom: 8 }}>
            {filters.map(f => (
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
          <Card style={{ padding: 0, overflow: "hidden" }}>
            {filtered.map((l, i) => (
              <div key={i} style={{ display: "flex", gap: 12, alignItems: "flex-start", padding: 14, borderTop: i === 0 ? 0 : "1px solid var(--border)" }}>
                <span style={{ width: 34, height: 34, borderRadius: 10, background: l.b || "var(--surface-2)", color: l.c, display: "grid", placeItems: "center", flexShrink: 0 }}>{l.ic}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 6, flexWrap: "wrap" }}>
                    <span style={{ font: "600 13.5px var(--font-body)", letterSpacing: "-0.01em" }}>{l.ac}</span>
                    <span className="chip" style={{ padding: "2px 7px", fontSize: 10, background: l.role === "Caja" ? "color-mix(in oklab, var(--info) 12%, white)" : l.role === "Trainer" ? "color-mix(in oklab, var(--accent) 20%, white)" : "var(--surface-3)", color: "var(--ink-2)", border: 0 }}>{l.role.toUpperCase()}</span>
                  </div>
                  <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>{l.d}</div>
                  <div style={{ font: "500 11px var(--font-mono)", color: "var(--ink-3)", marginTop: 4 }}>{l.who}</div>
                </div>
                <span style={{ font: "500 11px var(--font-mono)", color: "var(--ink-3)", flexShrink: 0, textAlign: "right" }}>{l.t}</span>
              </div>
            ))}
          </Card>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// ADMIN · PRODUCTS (CRUD completo + eliminación física)
// ═══════════════════════════════════════════════════════════════
function AdminProducts({ go }) {
  return (
    <Screen>
      <Header title="Productos" onBack={() => go("more")} right={<button className="h-icon" onClick={() => go("newProduct")}>{I.plus}</button>}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <div className="grid-2">
            <div className="kpi"><span className="l">Productos activos</span><span className="v">{PRODUCTS.length}</span><span className="d">{I.trend} +1 esta sem</span></div>
            <div className="kpi"><span className="l">Valor inventario</span><span className="v">S/ 4.280</span><span className="d down">2 con bajo stock</span></div>
          </div>
        </div>

        <div className="section">
          <SectionTitle title="Inventario"/>
          <div className="row-list">
            {PRODUCTS.map(p => (
              <Card key={p.id} style={{ padding: 12, display: "flex", gap: 12, alignItems: "center", cursor: "pointer" }} onClick={() => go("editAdminProduct", { id: p.id })}>
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

function EditAdminProduct({ go, params }) {
  const p = PRODUCTS.find(x => x.id === params?.id) || PRODUCTS[0];
  return (
    <Screen>
      <Header title="Editar producto" onBack={() => go("adminProducts")}/>
      <div className="scroll" style={{ paddingBottom: 100 }}>
        <div className="section">
          <Card>
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <span style={{ width: 64, height: 64, borderRadius: 14, background: "var(--surface-2)", display: "grid", placeItems: "center", fontSize: 32 }}>{p.k}</span>
              <div style={{ flex: 1 }}>
                <div style={{ font: "800 18px var(--font-display)", letterSpacing: "-0.03em" }}>{p.n}</div>
                <div style={{ font: "500 12.5px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>{p.id} · {p.cat}</div>
              </div>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Detalles completos (Admin)"/>
          <Card>
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="field"><label>Nombre</label><input defaultValue={p.n}/></div>
              <div className="field">
                <label>Categoría</label>
                <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                  {["Bebidas", "Suplementos", "Snacks", "Merch", "Accesorios"].map(c => (
                    <span key={c} className={`chip ${c === p.cat ? "solid" : ""}`}>{c}</span>
                  ))}
                </div>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                <div className="field"><label>Precio (S/)</label><input defaultValue={p.p}/></div>
                <div className="field"><label>Stock</label><input defaultValue={p.stock}/></div>
              </div>
              <div className="field"><label>Código de barras</label><input defaultValue="7751234500001"/></div>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Zona crítica · Solo Admin"/>
          <Card style={{ borderColor: "color-mix(in oklab, var(--danger) 25%, white)", background: "color-mix(in oklab, var(--danger) 4%, white)" }}>
            <div style={{ font: "600 13.5px var(--font-body)" }}>Eliminar producto del catálogo</div>
            <div style={{ font: "500 12.5px/1.5 var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>
              Eliminación física. Los registros históricos de ventas mantienen referencia. Esta acción se registra en el log de auditoría.
            </div>
            <div style={{ marginTop: 12 }}>
              <Btn kind="danger-soft" block leading={I.trash}>Eliminar definitivamente</Btn>
            </div>
          </Card>
        </div>
      </div>
      <div className="sticky-cta">
        <Btn kind="primary" block size="lg" onClick={() => go("adminProducts")} leading={I.check}>Guardar cambios</Btn>
      </div>
    </Screen>
  );
}

Object.assign(window, { AdminApp, AdminScanner, NewMember, ALL_MEMBERS, PRODUCTS });

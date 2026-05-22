// member.jsx — App del Usuario (Miembro)

const MEMBER_NAV = [
  { id: "home",     label: "Inicio",   icon: I.home },
  { id: "agenda",   label: "Agenda",   icon: I.calendar },
  { id: "qr",       label: "Acceso",   icon: I.qr, fab: true },
  { id: "pay",      label: "Membresía", icon: I.cash },
  { id: "profile",  label: "Perfil",   icon: I.user },
];

// Datos mock — TODAY_WORKOUT, WEEK, EXERCISES_TODAY y ANNOUNCEMENTS
// viven ahora en data.jsx (compartidos; EXERCISES_TODAY lo usa también trainer.jsx).

// ═══════════════════════════════════════════════════════════════
// MEMBER HOME
// ═══════════════════════════════════════════════════════════════
function MemberHome({ go }) {
  return (
    <Screen>
      <Header
        greet={{ hi: "Miércoles, 21 de Mayo", name: "Hola, Mateo 👋" }}
        right={<>
          <button className="h-icon" onClick={() => go("notifications")}>
            {I.bell}<span className="dot-r"/>
          </button>
          <Avatar name="Mateo Salas" size={46}/>
        </>}
      />
      <div className="scroll has-nav">
        {/* hero today */}
        <div className="section">
          <Card className="dark" style={{ padding: 0, overflow: "hidden", position: "relative", border: 0 }}>
            <div style={{ position: "absolute", top: -60, right: -40, width: 240, height: 240, background: "radial-gradient(circle, color-mix(in oklab, var(--accent) 50%, transparent), transparent 65%)", filter: "blur(10px)" }}/>
            <div style={{ padding: 20, position: "relative" }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                <span style={{ font: "600 11.5px var(--font-mono)", letterSpacing: ".08em", color: "var(--accent)", textTransform: "uppercase" }}>● ENTRENAMIENTO DE HOY</span>
                <Chip size="lg" kind="solid" leading={I.fire} style={{ background: "rgba(255,255,255,.1)" }}>Día 47</Chip>
              </div>
              <div style={{ font: "800 26px/1.1 var(--font-display)", letterSpacing: "-0.03em", marginTop: 14, textWrap: "pretty" }}>
                {TODAY_WORKOUT.name}
              </div>
              <div style={{ display: "flex", gap: 20, marginTop: 14, color: "rgba(255,255,255,.7)", font: "500 13px var(--font-body)" }}>
                <span>{TODAY_WORKOUT.exercises} ejercicios</span>
                <span>·</span>
                <span>{TODAY_WORKOUT.duration}</span>
                <span>·</span>
                <span>Intensidad {TODAY_WORKOUT.intensity}</span>
              </div>
              <div style={{ marginTop: 20, display: "grid", gridTemplateColumns: "1fr auto", gap: 10 }}>
                <Btn kind="accent" size="lg" onClick={() => go("assistant")} leading={I.play}>
                  Empezar entrenamiento
                </Btn>
                <Btn kind="ghost" size="lg" onClick={() => go("agenda")} style={{ background: "rgba(255,255,255,.08)", color: "#fff", border: "1px solid rgba(255,255,255,.08)" }}>
                  Ver lista
                </Btn>
              </div>
            </div>
          </Card>
        </div>

        {/* stats */}
        <div className="section">
          <div className="grid-2">
            <div className="kpi">
              <span className="l">Esta semana</span>
              <span className="v">3 / 6</span>
              <span className="d">{I.trend} +1 vs sem.</span>
            </div>
            <div className="kpi">
              <span className="l">Membresía</span>
              <span className="v">14 <span style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}>días</span></span>
              <span className="d" style={{ color: "var(--ink-2)" }}>Vence 4 jun</span>
            </div>
          </div>
        </div>

        {/* quick actions */}
        <div className="section">
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10 }}>
            {[
              { ic: I.qr, l: "Mi QR", go: "qr" },
              { ic: I.calendar, l: "Reservar", go: "bookings" },
              { ic: I.cash, l: "Pagar", go: "payOnline" },
              { ic: I.warn, l: "Reportar", go: "observation" },
            ].map(a => (
              <button key={a.l} onClick={() => go(a.go)} style={{ appearance: "none", border: "1px solid var(--border)", background: "var(--surface)", borderRadius: 18, padding: "16px 8px", display: "flex", flexDirection: "column", alignItems: "center", gap: 8, cursor: "pointer", font: "600 12px var(--font-body)", color: "var(--ink)" }}>
                <span style={{ width: 38, height: 38, background: "var(--surface-2)", borderRadius: 12, display: "grid", placeItems: "center", color: "var(--ink)" }}>{a.ic}</span>
                {a.l}
              </button>
            ))}
          </div>
        </div>

        {/* anuncios */}
        <div className="section">
          <SectionTitle title="Avisos del gym" action="Ver todos →"/>
          <div className="row-list">
            {ANNOUNCEMENTS.map(a => (
              <Card key={a.id} style={{ padding: 14 }}>
                <div style={{ display: "flex", gap: 12 }}>
                  <div style={{ width: 4, alignSelf: "stretch", background: "var(--accent)", borderRadius: 4 }}/>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
                      <span className="chip accent" style={{ padding: "2px 8px", fontSize: 10 }}>{a.tag}</span>
                      <span style={{ font: "500 11.5px var(--font-mono)", color: "var(--ink-3)" }}>{a.time}</span>
                    </div>
                    <div style={{ font: "700 15px var(--font-display)", letterSpacing: "-0.02em" }}>{a.title}</div>
                    <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{a.body}</div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* community / progreso */}
        <div className="section">
          <SectionTitle title="Tu progreso"/>
          <Card>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
              <span style={{ font: "600 13px var(--font-body)", color: "var(--ink-2)" }}>Press de banca · últimas 8 sem</span>
              <Chip kind="accent" size="">+18 kg</Chip>
            </div>
            <ProgressChart/>
            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 10, font: "500 11px var(--font-mono)", color: "var(--ink-3)" }}>
              <span>S1</span><span>S2</span><span>S3</span><span>S4</span><span>S5</span><span>S6</span><span>S7</span><span>S8</span>
            </div>
          </Card>
        </div>

        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

function ProgressChart() {
  const data = [52, 55, 55, 60, 62, 65, 68, 70];
  const max = 75, min = 45;
  const w = 380, h = 110;
  const step = w / (data.length - 1);
  const pts = data.map((v, i) => [i * step, h - ((v - min) / (max - min)) * (h - 20) - 10]);
  const path = pts.map((p, i) => `${i === 0 ? "M" : "L"}${p[0]} ${p[1]}`).join(" ");
  const area = `${path} L${w} ${h} L0 ${h} Z`;
  return (
    <svg width="100%" viewBox={`0 0 ${w} ${h}`} style={{ display: "block" }}>
      <defs>
        <linearGradient id="pg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="var(--accent)" stopOpacity=".35"/>
          <stop offset="1" stopColor="var(--accent)" stopOpacity="0"/>
        </linearGradient>
      </defs>
      <path d={area} fill="url(#pg)"/>
      <path d={path} fill="none" stroke="var(--ink)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
      {pts.map((p, i) => (
        <circle key={i} cx={p[0]} cy={p[1]} r={i === pts.length - 1 ? 5 : 3} fill={i === pts.length - 1 ? "var(--accent)" : "var(--ink)"} stroke={i === pts.length - 1 ? "var(--ink)" : "var(--surface)"} strokeWidth="2"/>
      ))}
    </svg>
  );
}

// ═══════════════════════════════════════════════════════════════
// MEMBER AGENDA
// ═══════════════════════════════════════════════════════════════
function MemberAgenda({ go }) {
  const today = WEEK.find(d => d.today);
  return (
    <Screen>
      <Header
        title="Mi agenda semanal"
        right={<button className="h-icon">{I.filter}</button>}
      />
      <div className="scroll has-nav">
        <div className="weekstrip">
          {WEEK.map(d => (
            <div key={d.dow} className={`day ${d.today ? "today" : ""} ${d.rest ? "rest" : ""}`}>
              <span className="dow">{d.dow}</span>
              <span className="n">{d.n}</span>
              <span className="pip"/>
            </div>
          ))}
        </div>

        <div className="section">
          <Card className="accent" style={{ padding: 16 }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <div>
                <div style={{ font: "600 11.5px var(--font-mono)", letterSpacing: ".08em", textTransform: "uppercase", opacity: .7 }}>HOY · Miércoles</div>
                <div style={{ font: "800 22px var(--font-display)", letterSpacing: "-0.03em", marginTop: 4 }}>{TODAY_WORKOUT.name}</div>
                <div style={{ font: "500 13px var(--font-body)", marginTop: 4, opacity: .8 }}>{EXERCISES_TODAY.length} ejercicios · 55 min</div>
              </div>
              <button onClick={() => go("assistant")} style={{ width: 60, height: 60, borderRadius: "50%", background: "var(--ink)", color: "#fff", border: 0, display: "grid", placeItems: "center", cursor: "pointer", boxShadow: "0 6px 18px rgba(0,0,0,.25)" }}>{I.play}</button>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Ejercicios de hoy"/>
          <div className="row-list">
            {EXERCISES_TODAY.map((e, i) => (
              <div key={e.id} className="ex-tile">
                <div className="thumb"><ExerciseAnim kind={e.kind} small/></div>
                <div className="info">
                  <div className="n">{e.name}</div>
                  <div className="m">{e.sets}×{e.reps} · {e.weight ? `${e.weight} kg` : "Peso corporal"}</div>
                </div>
                <span style={{ font: "700 13px var(--font-mono)", color: "var(--ink-3)" }}>{String(i + 1).padStart(2, "0")}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="section">
          <SectionTitle title="Próximos días"/>
          <div className="row-list">
            {WEEK.filter(d => !d.today).slice(0, 4).map(d => (
              <div key={d.dow} className="row">
                <span className="av" style={{ background: "var(--surface-3)", color: "var(--ink)" }}>{d.dow}</span>
                <div className="tx">
                  <div className="nm">{d.group}</div>
                  <div className="sub">{d.rest ? "Día de recuperación" : `${4 + (d.n % 3)} ejercicios programados`}</div>
                </div>
                <span className="tail">{d.n} may {I.forward}</span>
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
// WORKOUT ASSISTANT (COCKPIT)
// ═══════════════════════════════════════════════════════════════
function WorkoutAssistant({ go }) {
  const [exIdx, setExIdx] = React.useState(0);
  const [setIdx, setSetIdx] = React.useState(0);
  const [resting, setResting] = React.useState(false);
  const [restLeft, setRestLeft] = React.useState(90);
  const [showLog, setShowLog] = React.useState(false);
  const [done, setDone] = React.useState(false);

  const ex = EXERCISES_TODAY[exIdx];
  const totalSeries = ex.sets;

  React.useEffect(() => {
    if (!resting) return;
    if (restLeft <= 0) { setResting(false); return; }
    const t = setTimeout(() => setRestLeft(s => s - 1), 1000);
    return () => clearTimeout(t);
  }, [resting, restLeft]);

  const completeSet = () => {
    if (setIdx + 1 >= totalSeries) {
      if (exIdx + 1 >= EXERCISES_TODAY.length) {
        setDone(true);
        return;
      }
      setExIdx(exIdx + 1);
      setSetIdx(0);
    } else {
      setSetIdx(setIdx + 1);
    }
    setRestLeft(ex.rest);
    setResting(true);
  };

  if (done) return <WorkoutComplete go={go}/>;

  return (
    <div className="cockpit">
      {/* top */}
      <div className="top">
        <button className="iconbtn" style={{ width: 40, height: 40 }} onClick={() => go("agenda")}>{I.close}</button>
        <div className="pill" style={{ background: "rgba(255,255,255,.06)" }}>
          <span style={{ font: "600 11.5px var(--font-mono)", color: "rgba(255,255,255,.5)", textTransform: "uppercase", letterSpacing: ".08em" }}>EJ {exIdx + 1} / {EXERCISES_TODAY.length}</span>
        </div>
        <button className="iconbtn" style={{ width: 40, height: 40 }}>{I.more}</button>
      </div>

      <div className="ex-name">{ex.name}</div>
      <div className="ex-meta">{ex.muscle} · Descanso {ex.rest}s · Sugerido por Carlos</div>

      {/* animation stage */}
      <div className="stage-anim">
        <ExerciseAnim kind={ex.kind}/>
        <div style={{ position: "absolute", top: 12, left: 14, font: "600 11px var(--font-mono)", color: "rgba(255,255,255,.4)", letterSpacing: ".08em", textTransform: "uppercase" }}>● en vivo</div>
        <div style={{ position: "absolute", bottom: 12, right: 14, font: "600 11px var(--font-mono)", color: "rgba(255,255,255,.4)" }}>1.0×</div>
      </div>

      {/* series pips */}
      <div className="series-row">
        {Array.from({ length: totalSeries }).map((_, i) => (
          <div key={i} className={`series-pip ${i < setIdx ? "done" : i === setIdx ? "active" : ""}`}/>
        ))}
      </div>
      <div style={{ padding: "10px 22px 0", display: "flex", justifyContent: "space-between", color: "rgba(255,255,255,.6)", font: "600 12px var(--font-body)" }}>
        <span>Serie <span style={{ color: "#fff", font: "700 14px var(--font-display)" }}>{setIdx + 1}</span> de {totalSeries}</span>
        <span>{Math.round(((setIdx) / totalSeries) * 100)}% del ejercicio</span>
      </div>

      {/* cockpit data */}
      <div className="data">
        <div className="d-cell">
          <div className="l">Peso sugerido</div>
          <div className="v">{ex.weight || "—"}<span className="u" style={{ marginLeft: 6 }}>kg</span></div>
        </div>
        <div className="d-cell">
          <div className="l">Repeticiones</div>
          <div className="v">{ex.reps.split("-")[0]}<span className="u" style={{ marginLeft: 6, fontSize: 18 }}>·{ex.reps.split("-")[1] || ""}</span></div>
        </div>
        <div className="d-cell" style={{ background: resting ? "var(--accent)" : "rgba(255,255,255,.04)", color: resting ? "var(--accent-ink)" : "#fff" }}>
          <div className="l" style={{ color: resting ? "rgba(0,0,0,.6)" : "rgba(255,255,255,.5)" }}>Descanso</div>
          <div className="v">{resting ? `${Math.floor(restLeft / 60)}:${String(restLeft % 60).padStart(2, "0")}` : `${ex.rest}`}<span className="u" style={{ marginLeft: 6, color: resting ? "rgba(0,0,0,.5)" : "rgba(255,255,255,.4)" }}>s</span></div>
        </div>
      </div>

      {/* timer area */}
      {resting && (
        <div className="timer-wrap">
          <div className="timer">
            <TimerRing pct={1 - (restLeft / ex.rest)} color="var(--accent)"/>
            <div className="num">{restLeft}</div>
            <div className="l">SEG</div>
          </div>
          <div className="ctrls">
            <Btn kind="accent" block onClick={() => { setResting(false); setRestLeft(0); }} leading={I.skip}>Saltar descanso</Btn>
            <Btn kind="ghost" block onClick={() => setRestLeft(s => s + 15)} style={{ background: "rgba(255,255,255,.06)", color: "#fff", border: "1px solid rgba(255,255,255,.1)" }} leading={I.refresh}>+15s</Btn>
          </div>
        </div>
      )}

      {/* bottom bar */}
      <div className="bottom-bar">
        <button className="iconbtn" onClick={() => setShowLog(true)} title="Ajustar esfuerzo">{I.edit}</button>
        {resting
          ? <Btn kind="accent" size="lg" block onClick={completeSet} leading={I.bolt}>Siguiente serie</Btn>
          : <Btn kind="accent" size="lg" block onClick={completeSet} leading={I.check}>Serie completada</Btn>
        }
        <button className="iconbtn">{I.pause}</button>
      </div>

      {showLog && <LogEffortModal ex={ex} setIdx={setIdx} onClose={() => setShowLog(false)}/>}
    </div>
  );
}

function LogEffortModal({ ex, setIdx, onClose }) {
  const [weight, setWeight] = React.useState(ex.weight);
  const [reps, setReps] = React.useState(parseInt(ex.reps));
  return (
    <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,.6)", display: "grid", placeItems: "end center", zIndex: 10 }} onClick={onClose}>
      <div style={{ background: "var(--surface)", borderRadius: "24px 24px 0 0", width: "100%", padding: "20px 22px 28px" }} onClick={e => e.stopPropagation()}>
        <div style={{ width: 40, height: 4, background: "var(--border-strong)", borderRadius: 4, margin: "0 auto 16px" }}/>
        <div style={{ font: "700 18px var(--font-display)", letterSpacing: "-0.02em" }}>Ajustar esfuerzo real</div>
        <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>Serie {setIdx + 1} · {ex.name}</div>

        <div style={{ marginTop: 18, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          <Stepper label="Peso (kg)" value={weight} onChange={setWeight} step={2.5}/>
          <Stepper label="Reps reales" value={reps} onChange={setReps} step={1}/>
        </div>

        <div style={{ display: "flex", gap: 10, marginTop: 18 }}>
          <Btn kind="ghost" block onClick={onClose}>Cancelar</Btn>
          <Btn kind="primary" block onClick={onClose}>Guardar serie</Btn>
        </div>
      </div>
    </div>
  );
}
// Stepper, Field, PhyField y Toggle se movieron a shared.jsx (form controls comunes).

function WorkoutComplete({ go }) {
  return (
    <div className="cockpit" style={{ background: "var(--ink)", color: "#fff" }}>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", padding: 28, textAlign: "center" }}>
        <div style={{ width: 120, height: 120, borderRadius: "50%", background: "var(--accent)", color: "var(--accent-ink)", display: "grid", placeItems: "center", boxShadow: "0 0 0 16px color-mix(in oklab, var(--accent) 30%, transparent)" }}>
          <svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="m5 12 5 5L20 6"/></svg>
        </div>
        <div style={{ font: "800 36px var(--font-display)", letterSpacing: "-0.04em", marginTop: 32, textWrap: "balance" }}>
          ¡Entrenamiento<br/>completado! 💪
        </div>
        <div style={{ font: "500 15px var(--font-body)", color: "rgba(255,255,255,.7)", marginTop: 12, maxWidth: 280, textWrap: "pretty" }}>
          Sumaste <b style={{ color: "var(--accent)" }}>2.450 kg</b> levantados hoy. Tu próxima sesión es mañana.
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12, width: "100%", marginTop: 36 }}>
          {[
            { l: "Duración", v: "53 min" },
            { l: "Series", v: "22 / 22" },
            { l: "PR's", v: "+1" },
          ].map(s => (
            <div key={s.l} style={{ background: "rgba(255,255,255,.06)", borderRadius: 16, padding: 14, textAlign: "center" }}>
              <div style={{ font: "800 22px var(--font-display)", letterSpacing: "-0.02em" }}>{s.v}</div>
              <div style={{ font: "500 11px var(--font-body)", color: "rgba(255,255,255,.5)", marginTop: 4, textTransform: "uppercase", letterSpacing: ".06em" }}>{s.l}</div>
            </div>
          ))}
        </div>
      </div>
      <div style={{ padding: "16px 22px 28px", display: "flex", flexDirection: "column", gap: 10 }}>
        <Btn kind="accent" block size="lg" onClick={() => go("home")}>Volver al inicio</Btn>
        <Btn kind="ghost" block onClick={() => go("home")} style={{ background: "rgba(255,255,255,.06)", color: "#fff", border: "1px solid rgba(255,255,255,.1)" }}>Compartir entrenamiento</Btn>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// MEMBER QR ACCESS
// ═══════════════════════════════════════════════════════════════
function MemberQR({ go }) {
  const [t, setT] = React.useState(45);
  React.useEffect(() => {
    const i = setInterval(() => setT(x => x > 0 ? x - 1 : 60), 1000);
    return () => clearInterval(i);
  }, []);
  const [seed, setSeed] = React.useState(7);
  React.useEffect(() => { if (t === 0) setSeed(s => s + 1); }, [t]);

  return (
    <Screen>
      <Header title="Mi acceso" onBack={() => go("home")}/>
      <div className="qr-screen scroll has-nav">
        <Chip kind="ok" size="lg" leading={<span style={{ width: 8, height: 8, background: "var(--success)", borderRadius: "50%" }}/>}>
          Membresía activa
        </Chip>

        <div className="qr-card">
          <div className="qr-img">
            <QRPattern seed={seed}/>
          </div>
          <div style={{ marginTop: 16, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div>
              <div style={{ font: "700 16px var(--font-display)", letterSpacing: "-0.02em" }}>Mateo Salas</div>
              <div style={{ font: "500 12.5px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>DNI · 70 432 198</div>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ font: "800 22px var(--font-display)", fontVariantNumeric: "tabular-nums", letterSpacing: "-0.03em" }}>0:{String(t).padStart(2, "0")}</div>
              <div style={{ font: "500 11px var(--font-mono)", color: "var(--ink-3)", textTransform: "uppercase", letterSpacing: ".08em" }}>Se renueva</div>
            </div>
          </div>
        </div>

        <div style={{ marginTop: 20, font: "500 13.5px var(--font-body)", color: "var(--ink-2)", textAlign: "center", maxWidth: 280, textWrap: "pretty" }}>
          Acércate al lector de la entrada o muestra este código al staff de recepción.
        </div>

        <div style={{ marginTop: "auto", width: "100%", paddingTop: 24 }}>
          <Card className="flat" style={{ padding: 14, display: "flex", gap: 12, alignItems: "center" }}>
            <span style={{ width: 38, height: 38, borderRadius: 12, background: "var(--ink)", color: "#fff", display: "grid", placeItems: "center" }}>{I.clock}</span>
            <div style={{ flex: 1, minWidth: 0, textAlign: "left" }}>
              <div style={{ font: "600 13px var(--font-body)" }}>Último ingreso</div>
              <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)" }}>Lunes 19 may · 7:42 am</div>
            </div>
          </Card>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// MEMBER MEMBERSHIP / PAY
// ═══════════════════════════════════════════════════════════════
function MemberMembership({ go }) {
  return (
    <Screen>
      <Header title="Mi membresía" right={<button className="h-icon">{I.more}</button>}/>
      <div className="scroll has-nav">
        <div className="section">
          <Card className="dark" style={{ padding: 0, overflow: "hidden", position: "relative", border: 0 }}>
            <div style={{ position: "absolute", top: -80, left: -40, width: 280, height: 280, background: "radial-gradient(circle, color-mix(in oklab, var(--accent) 40%, transparent), transparent 65%)", filter: "blur(10px)" }}/>
            <div style={{ padding: 22, position: "relative" }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                <span style={{ font: "600 11.5px var(--font-mono)", letterSpacing: ".08em", textTransform: "uppercase", color: "var(--accent)" }}>PLAN MENSUAL</span>
                <span className="chip ok">● Activa</span>
              </div>
              <div style={{ font: "800 34px var(--font-display)", letterSpacing: "-0.04em", marginTop: 18 }}>
                14 <span style={{ font: "500 16px var(--font-body)", color: "rgba(255,255,255,.6)" }}>días restantes</span>
              </div>
              <div style={{ marginTop: 14 }}>
                <Bar value={14} max={30} kind="accent"/>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8, font: "500 11.5px var(--font-mono)", color: "rgba(255,255,255,.5)" }}>
                <span>5 MAY</span>
                <span>VENCE 4 JUN</span>
              </div>
              <div style={{ display: "flex", gap: 10, marginTop: 20 }}>
                <Btn kind="accent" block onClick={() => go("payOnline")} leading={I.cash}>Renovar ahora</Btn>
              </div>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Planes disponibles"/>
          <div className="row-list">
            {[
              { name: "Mensual",    price: "S/ 120",  desc: "30 días · libre acceso",        tag: null },
              { name: "Trimestral", price: "S/ 320", desc: "90 días · ahorra S/ 40",         tag: "POPULAR" },
              { name: "Anual",      price: "S/ 1.080", desc: "365 días · ahorra S/ 360",    tag: "MEJOR PRECIO" },
            ].map((p, i) => (
              <Card key={p.name} style={{ padding: 16, position: "relative", border: i === 1 ? "2px solid var(--accent)" : "1px solid var(--border)" }}>
                {p.tag && <span style={{ position: "absolute", top: -10, right: 14 }} className="ribbon">{p.tag}</span>}
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
                  <div>
                    <div style={{ font: "700 17px var(--font-display)", letterSpacing: "-0.02em" }}>{p.name}</div>
                    <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>{p.desc}</div>
                  </div>
                  <div style={{ font: "800 22px var(--font-display)", letterSpacing: "-0.03em", fontVariantNumeric: "tabular-nums" }}>{p.price}</div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        <div className="section">
          <SectionTitle title="Historial de pagos"/>
          <div className="row-list">
            {[
              { d: "5 MAY 2026", m: "S/ 120", k: "Yape · QR pasarela", ok: true },
              { d: "5 ABR 2026", m: "S/ 120", k: "Efectivo · Caja", ok: true },
              { d: "5 MAR 2026", m: "S/ 120", k: "Plin · Acreditado", ok: true },
            ].map(p => (
              <div key={p.d} className="row">
                <span className="av" style={{ background: "color-mix(in oklab, var(--success) 18%, white)", color: "#008c44" }}>{I.check}</span>
                <div className="tx">
                  <div className="nm">{p.m}</div>
                  <div className="sub">{p.k}</div>
                </div>
                <span className="tail">{p.d}</span>
              </div>
            ))}
          </div>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// PAY ONLINE - choose gateway, show QR
function MemberPayOnline({ go }) {
  const [method, setMethod] = React.useState("yape");
  return (
    <Screen>
      <Header title="Pagar membresía" onBack={() => go("pay")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card className="flat" style={{ padding: 16, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div>
              <div style={{ font: "500 12px var(--font-body)", color: "var(--ink-2)" }}>Plan Mensual · 30 días</div>
              <div style={{ font: "800 28px var(--font-display)", letterSpacing: "-0.03em", marginTop: 4 }}>S/ 120<span style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}>.00</span></div>
            </div>
            <Chip kind="ok">Renovación</Chip>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Método de pago"/>
          <div className="row-list">
            {[
              { id: "yape", n: "Yape", s: "QR dinámico · Pago al instante", b: "#742DDD" },
              { id: "plin", n: "Plin", s: "QR dinámico · Pago al instante", b: "#00B2A9" },
              { id: "culqi", n: "Tarjeta crédito / débito", s: "Visa · Mastercard · Amex (Culqi)", b: "#0066FF" },
              { id: "manual", n: "Acreditación manual", s: "Sube tu comprobante", b: "var(--ink-2)" },
            ].map(m => (
              <label key={m.id} className="row" style={{ borderColor: method === m.id ? "var(--ink)" : "var(--border)", borderWidth: method === m.id ? 2 : 1 }}>
                <input type="radio" name="m" checked={method === m.id} onChange={() => setMethod(m.id)} style={{ display: "none" }}/>
                <span className="av" style={{ background: m.b, color: "#fff", font: "800 12px var(--font-display)", letterSpacing: "-0.01em" }}>{m.n.split(" ")[0].slice(0, 4).toUpperCase()}</span>
                <div className="tx">
                  <div className="nm">{m.n}</div>
                  <div className="sub">{m.s}</div>
                </div>
                <span style={{ width: 22, height: 22, borderRadius: "50%", border: "2px solid " + (method === m.id ? "var(--ink)" : "var(--border-strong)"), display: "grid", placeItems: "center" }}>
                  {method === m.id && <span style={{ width: 10, height: 10, borderRadius: "50%", background: "var(--ink)" }}/>}
                </span>
              </label>
            ))}
          </div>
        </div>

        {method === "yape" && (
          <div className="section">
            <Card style={{ padding: 18, textAlign: "center" }}>
              <div style={{ font: "600 11.5px var(--font-mono)", color: "var(--ink-3)", letterSpacing: ".08em", textTransform: "uppercase" }}>QR YAPE · Vence en 4:32</div>
              <div style={{ width: 200, height: 200, margin: "16px auto", padding: 12, background: "#fff", border: "1px solid var(--border)", borderRadius: 16 }}>
                <QRPattern seed={42}/>
              </div>
              <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)", textWrap: "pretty" }}>
                Abre tu app Yape, escanea el código y confirma. Tu membresía se activa al instante.
              </div>
            </Card>
          </div>
        )}

        {method === "manual" && (
          <div className="section">
            <Card style={{ padding: 18 }}>
              <div style={{ font: "700 15px var(--font-display)", letterSpacing: "-0.02em" }}>Sube tu comprobante</div>
              <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>El Admin lo revisará en menos de 30 min.</div>
              <div style={{ marginTop: 14, height: 140, border: "2px dashed var(--border-strong)", borderRadius: 16, display: "grid", placeItems: "center", color: "var(--ink-2)" }}>
                <div style={{ textAlign: "center" }}>
                  {I.upload}
                  <div style={{ marginTop: 8, font: "600 13px var(--font-body)" }}>Tocar para subir</div>
                  <div style={{ font: "500 11.5px var(--font-mono)", color: "var(--ink-3)", marginTop: 2 }}>JPG · PNG · máx 2MB</div>
                </div>
              </div>
            </Card>
          </div>
        )}

        <div className="section">
          <Btn kind="primary" block size="lg" onClick={() => go("pay")} leading={I.bolt}>
            {method === "manual" ? "Enviar comprobante" : "Confirmar pago"}
          </Btn>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// MEMBER PROFILE
// ═══════════════════════════════════════════════════════════════
function MemberProfile({ go, onLogout }) {
  const [tab, setTab] = React.useState("priv");
  return (
    <Screen>
      <Header
        title="Mi perfil"
        right={<button className="h-icon">{I.settings}</button>}
      />
      <div className="scroll has-nav">
        <div className="section" style={{ paddingTop: 4 }}>
          <Card style={{ padding: 18 }}>
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <Avatar name="Mateo Salas" size={64}/>
              <div style={{ flex: 1 }}>
                <div style={{ font: "800 20px var(--font-display)", letterSpacing: "-0.03em" }}>Mateo Salas</div>
                <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>Miembro · Hipertrofia</div>
                <div style={{ display: "flex", gap: 6, marginTop: 8 }}>
                  <Chip kind="accent">Día 47</Chip>
                  <Chip>Carlos M. · Trainer</Chip>
                </div>
              </div>
            </div>
            <div className="divider"/>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <div>
                <div style={{ font: "600 13px var(--font-body)" }}>Modo activo en comunidad</div>
                <div style={{ font: "500 11.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>Otros usuarios pueden verte</div>
              </div>
              <Toggle on={true}/>
            </div>
          </Card>
        </div>

        <div className="section">
          <div style={{ display: "flex", gap: 4, background: "var(--surface-2)", padding: 4, borderRadius: 14, border: "1px solid var(--border)" }}>
            {[
              { id: "priv", l: "Privado" },
              { id: "soc", l: "Social" },
              { id: "phy", l: "Físico" },
            ].map(t => (
              <button key={t.id} onClick={() => setTab(t.id)} style={{
                flex: 1, appearance: "none", border: 0,
                padding: "10px 6px",
                borderRadius: 10,
                font: "600 13px var(--font-body)",
                background: tab === t.id ? "var(--ink)" : "transparent",
                color: tab === t.id ? "#fff" : "var(--ink-2)",
                cursor: "pointer"
              }}>{t.l}</button>
            ))}
          </div>
        </div>

        {tab === "priv" && (
          <div className="section">
            <Card>
              <Field l="Nombre" v="Mateo Salas Rivera"/>
              <Field l="DNI" v="70 432 198"/>
              <Field l="Correo" v="mateo.salas@gmail.com"/>
              <Field l="Celular" v="+51 987 654 321"/>
              <Field l="Cumpleaños" v="14 de Octubre, 1996"/>
            </Card>
          </div>
        )}

        {tab === "soc" && (
          <div className="section">
            <Card>
              <Field l="Nickname" v="@mateosalas"/>
              <Field l="Visible para" v="Todos los miembros"/>
              <Field l="Día desde" v="4 de Abril 2026"/>
            </Card>
            <div style={{ height: 12 }}/>
            <SectionTitle title="En el gym ahora" action="Ver todos"/>
            <div style={{ display: "flex", gap: 10, overflowX: "auto", paddingBottom: 8 }}>
              {["Lucía F.", "Jorge P.", "Ana T.", "Diego C.", "Rosa M."].map(n => (
                <div key={n} style={{ flex: "0 0 auto", textAlign: "center", width: 64 }}>
                  <Avatar name={n} size={56}/>
                  <div style={{ font: "600 11px var(--font-body)", marginTop: 6, color: "var(--ink-2)" }}>{n.split(" ")[0]}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {tab === "phy" && (
          <div className="section">
            <Card>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 18 }}>
                <PhyField l="Peso" v="78.2 kg" d="-1.4 kg"/>
                <PhyField l="Altura" v="1.78 m"/>
                <PhyField l="Cintura" v="84 cm" d="-2 cm"/>
                <PhyField l="Pecho" v="102 cm" d="+1 cm"/>
                <PhyField l="Brazo" v="36 cm" d="+1 cm"/>
                <PhyField l="Cadera" v="96 cm"/>
              </div>
            </Card>
            <div style={{ height: 14 }}/>
            <SectionTitle title="Antes / Después" action="Subir foto"/>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
              <Photo hue={200} kind="person" h={180} label="MAR 2026"/>
              <Photo hue={140} kind="person" h={180} label="MAY 2026"/>
            </div>
          </div>
        )}

        <div className="section">
          <Btn kind="ghost" block onClick={onLogout}>Cerrar sesión</Btn>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// BOOKINGS
// ═══════════════════════════════════════════════════════════════
function MemberBookings({ go }) {
  const classes = [
    { t: "07:00", n: "Funcional",  tr: "Lucía Flores",  cupo: "8 / 12", st: "ok", dur: "60 min" },
    { t: "08:30", n: "CrossTraining", tr: "Carlos Mendoza", cupo: "12 / 12", st: "full", dur: "60 min" },
    { t: "10:00", n: "Yoga",       tr: "Andrea Soto",   cupo: "4 / 10",  st: "ok", dur: "45 min" },
    { t: "17:30", n: "HIIT",       tr: "Jorge Paredes", cupo: "9 / 14",  st: "ok", dur: "45 min" },
    { t: "19:00", n: "Spinning",   tr: "Andrea Soto",   cupo: "6 / 12",  st: "ok", dur: "50 min" },
  ];
  return (
    <Screen>
      <Header title="Clases grupales" right={<button className="h-icon">{I.calendar}</button>}/>
      <div className="scroll has-nav">
        <div className="section">
          <div style={{ display: "flex", gap: 8, overflowX: "auto", paddingBottom: 8 }}>
            {["Hoy 21", "Jue 22", "Vie 23", "Sáb 24", "Dom 25", "Lun 26", "Mar 27"].map((d, i) => (
              <button key={d} style={{
                flex: "0 0 auto", padding: "10px 14px", borderRadius: 12,
                border: "1px solid var(--border)",
                background: i === 0 ? "var(--ink)" : "var(--surface)",
                color: i === 0 ? "#fff" : "var(--ink)",
                font: "600 13px var(--font-body)",
                cursor: "pointer"
              }}>{d}</button>
            ))}
          </div>
        </div>

        <div className="section">
          <SectionTitle title="Hoy · 21 de Mayo"/>
          <div className="row-list">
            {classes.map(c => (
              <Card key={c.t} style={{ padding: 14, display: "flex", gap: 14, alignItems: "center", opacity: c.st === "full" ? .6 : 1 }}>
                <div style={{ textAlign: "center", width: 56 }}>
                  <div style={{ font: "800 20px var(--font-display)", letterSpacing: "-0.03em", fontVariantNumeric: "tabular-nums" }}>{c.t}</div>
                  <div style={{ font: "500 11px var(--font-mono)", color: "var(--ink-3)", marginTop: 2 }}>{c.dur}</div>
                </div>
                <div style={{ width: 1, alignSelf: "stretch", background: "var(--border)" }}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "700 15px var(--font-display)", letterSpacing: "-0.02em" }}>{c.n}</div>
                  <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{c.tr} · {c.cupo}</div>
                </div>
                {c.st === "full" ? (
                  <Chip kind="warn">Lista espera</Chip>
                ) : (
                  <Btn kind="accent" size="sm">Reservar</Btn>
                )}
              </Card>
            ))}
          </div>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// OBSERVATION (CREATE)
// ═══════════════════════════════════════════════════════════════
function MemberObservation({ go }) {
  return (
    <Screen>
      <Header title="Reportar observación" onBack={() => go("home")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card>
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="field">
                <label>Tipo</label>
                <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                  {["Equipamiento", "Limpieza", "Personal", "Sugerencia"].map((t, i) => (
                    <span key={t} className={`chip ${i === 0 ? "solid" : ""}`}>{t}</span>
                  ))}
                </div>
              </div>
              <div className="field">
                <label>Descripción</label>
                <textarea rows="5" defaultValue="La máquina Smith del piso 2 hace ruido extraño al subir el peso..." style={{ resize: "none" }}/>
              </div>
              <div className="field">
                <label>Foto (opcional)</label>
                <div style={{ height: 120, border: "2px dashed var(--border-strong)", borderRadius: 14, display: "grid", placeItems: "center", color: "var(--ink-2)" }}>
                  <div style={{ textAlign: "center" }}>
                    {I.camera}
                    <div style={{ marginTop: 6, font: "600 12.5px var(--font-body)" }}>Adjuntar evidencia</div>
                  </div>
                </div>
              </div>
            </div>
          </Card>
        </div>
        <div className="section">
          <Btn kind="primary" size="lg" block onClick={() => go("home")} leading={I.send}>Enviar observación</Btn>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// NOTIFICATIONS
// ═══════════════════════════════════════════════════════════════
function MemberNotifications({ go }) {
  const items = [
    { i: I.warn, c: "var(--warn)", t: "Tu membresía vence en 14 días", s: "Renueva ahora con Yape · S/ 120", time: "Ahora" },
    { i: I.check, c: "var(--success)", t: "Pago aprobado", s: "S/ 120 vía Yape · 5 may", time: "5 may" },
    { i: I.megaphone, c: "var(--ink)", t: "Nuevo aviso del gym", s: "Clase gratis este sábado · Funcional 8am", time: "Hace 2h" },
    { i: I.bolt, c: "var(--accent-ink)", b: "var(--accent)", t: "¡Día 47 de racha!", s: "Llevas 3 semanas consecutivas. 🔥", time: "Ayer" },
  ];
  return (
    <Screen>
      <Header title="Notificaciones" onBack={() => go("home")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <div className="row-list">
            {items.map((it, i) => (
              <Card key={i} style={{ padding: 14, display: "flex", gap: 12, alignItems: "flex-start" }}>
                <span style={{ width: 38, height: 38, borderRadius: 12, background: it.b || "color-mix(in oklab, " + it.c + " 14%, white)", color: it.c, display: "grid", placeItems: "center", flexShrink: 0 }}>{it.i}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "600 14.5px var(--font-body)", letterSpacing: "-0.01em" }}>{it.t}</div>
                  <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{it.s}</div>
                </div>
                <span style={{ font: "500 11px var(--font-mono)", color: "var(--ink-3)", flexShrink: 0 }}>{it.time}</span>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// MEMBER ROUTER
// ═══════════════════════════════════════════════════════════════
function MemberApp() {
  const { screen, go } = useRouter("home");
  const [authed, setAuthed] = React.useState(false);

  if (!authed) return <LoginScreen role="member" onLogin={() => setAuthed(true)}/>;

  const isCockpit = screen === "assistant";
  const hideNav = isCockpit || screen === "qr-full";

  const navCurrent = ({
    home: "home", agenda: "agenda", assistant: "agenda",
    qr: "qr", pay: "pay", payOnline: "pay", profile: "profile",
    bookings: "agenda", observation: "home", notifications: "home"
  })[screen] || "home";

  return (
    <>
      {screen === "home"     && <MemberHome go={go}/>}
      {screen === "agenda"   && <MemberAgenda go={go}/>}
      {screen === "assistant" && <WorkoutAssistant go={go}/>}
      {screen === "qr"       && <MemberQR go={go}/>}
      {screen === "pay"      && <MemberMembership go={go}/>}
      {screen === "payOnline" && <MemberPayOnline go={go}/>}
      {screen === "profile"  && <MemberProfile go={go} onLogout={() => setAuthed(false)}/>}
      {screen === "bookings" && <MemberBookings go={go}/>}
      {screen === "observation" && <MemberObservation go={go}/>}
      {screen === "notifications" && <MemberNotifications go={go}/>}

      {!hideNav && (
        <div className="bnav-overlay">
          <BottomNav items={MEMBER_NAV} current={navCurrent} onChange={(id) => {
            if (id === "home") go("home");
            else if (id === "agenda") go("agenda");
            else if (id === "qr") go("qr");
            else if (id === "pay") go("pay");
            else if (id === "profile") go("profile");
          }}/>
        </div>
      )}
    </>
  );
}

Object.assign(window, { MemberApp });

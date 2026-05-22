// trainer.jsx — App del Entrenador

const TRAINER_NAV = [
  { id: "home",     label: "Alumnos",     icon: I.people },
  { id: "library",  label: "Ejercicios",  icon: I.dumbbell },
  { id: "routines", label: "Rutinas",     icon: I.bolt },
  { id: "stats",    label: "Progreso",    icon: I.chart },
  { id: "profile",  label: "Perfil",      icon: I.user },
];

const MY_MEMBERS = [
  { id: "m1", n: "Mateo Salas",     o: "Hipertrofia",   ses: 47, lst: "Hoy",   st: "ok"  },
  { id: "m2", n: "Lucía Fernández", o: "Pérdida grasa", ses: 32, lst: "Ayer",  st: "ok"  },
  { id: "m3", n: "Diego Castro",    o: "Fuerza máx.",   ses: 64, lst: "Hace 2d", st: "ok" },
  { id: "m4", n: "Rosa Mendieta",   o: "Tonificación",  ses: 18, lst: "Hace 4d", st: "warn" },
  { id: "m5", n: "Jorge Paredes",   o: "Resistencia",   ses: 53, lst: "Hoy",   st: "ok"  },
  { id: "m6", n: "Ana Torres",      o: "Hipertrofia",   ses: 21, lst: "Hace 1d", st: "ok" },
  { id: "m7", n: "Pedro Quispe",    o: "Rehabilitación", ses: 9, lst: "Hace 8d", st: "danger" },
];

const EXERCISE_LIBRARY = [
  { id: "lx1", n: "Press de banca",            g: "Pecho",   k: "bench", a: true },
  { id: "lx2", n: "Sentadilla con barra",      g: "Pierna",  k: "squat", a: true },
  { id: "lx3", n: "Peso muerto convencional",  g: "Espalda", k: "row",   a: true },
  { id: "lx4", n: "Press militar",             g: "Hombro",  k: "press", a: true },
  { id: "lx5", n: "Remo con barra",            g: "Espalda", k: "row",   a: true },
  { id: "lx6", n: "Hip thrust",                g: "Glúteo",  k: "squat", a: true },
  { id: "lx7", n: "Curl bíceps mancuerna",     g: "Bíceps",  k: "press", a: false },
  { id: "lx8", n: "Fondos en paralelas",       g: "Tríceps", k: "row",   a: true },
];

const MUSCLE_GROUPS = ["Todos", "Pecho", "Espalda", "Hombro", "Pierna", "Bíceps", "Tríceps", "Glúteo", "Core"];

// ═══════════════════════════════════════════════════════════════
// TRAINER HOME — Alumnos
// ═══════════════════════════════════════════════════════════════
function TrainerHome({ go }) {
  return (
    <Screen>
      <Header
        greet={{ hi: "Tu cancha · 7 alumnos", name: "Hola, Carlos" }}
        right={<Avatar name="Carlos Mendoza" size={46}/>}
      />
      <div className="scroll has-nav">
        <div className="section">
          <div className="grid-2">
            <div className="kpi"><span className="l">Activos hoy</span><span className="v">5</span><span className="d">{I.trend} +2</span></div>
            <div className="kpi"><span className="l">Sesiones esta sem.</span><span className="v">23</span><span className="d">{I.trend} +18%</span></div>
          </div>
        </div>

        <div className="section">
          <Card style={{ padding: 14, display: "flex", alignItems: "center", gap: 10 }}>
            <span style={{ width: 38, height: 38, borderRadius: 12, background: "var(--surface-2)", color: "var(--ink-2)", display: "grid", placeItems: "center" }}>{I.search}</span>
            <input placeholder="Buscar alumno…" style={{ flex: 1, border: 0, font: "500 14px var(--font-body)", color: "var(--ink)", background: "transparent", outline: "none" }}/>
            <button className="chip">{I.filter} Filtros</button>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Mis alumnos asignados" action="7 activos"/>
          <div className="row-list">
            {MY_MEMBERS.map(m => (
              <Card key={m.id} style={{ padding: 12, display: "flex", gap: 12, alignItems: "center", cursor: "pointer" }} onClick={() => go("memberDetail", { id: m.id })}>
                <Avatar name={m.n} size={44}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                    <span style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{m.n}</span>
                    {m.st === "warn" && <span style={{ width: 6, height: 6, borderRadius: "50%", background: "var(--warn)" }}/>}
                    {m.st === "danger" && <span style={{ width: 6, height: 6, borderRadius: "50%", background: "var(--danger)" }}/>}
                  </div>
                  <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{m.o} · Sesión #{m.ses}</div>
                </div>
                <div style={{ textAlign: "right" }}>
                  <div style={{ font: "600 11.5px var(--font-mono)", color: m.st === "danger" ? "var(--danger)" : "var(--ink-2)" }}>{m.lst}</div>
                </div>
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
// TRAINER MEMBER DETAIL (Vista Técnica)
// ═══════════════════════════════════════════════════════════════
function TrainerMemberDetail({ go, params }) {
  const m = MY_MEMBERS.find(x => x.id === params?.id) || MY_MEMBERS[0];
  return (
    <Screen>
      <Header title="Vista técnica" onBack={() => go("home")} right={<button className="h-icon">{I.more}</button>}/>
      <div className="scroll has-nav">
        <div className="section">
          <Card>
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <Avatar name={m.n} size={64}/>
              <div style={{ flex: 1 }}>
                <div style={{ font: "800 20px var(--font-display)", letterSpacing: "-0.03em" }}>{m.n}</div>
                <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{m.o} · Sesión #{m.ses}</div>
                <div style={{ display: "flex", gap: 6, marginTop: 8 }}>
                  <Chip kind="ok">Activo</Chip>
                  <Chip>30 años</Chip>
                </div>
              </div>
            </div>
            <div className="divider"/>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 14 }}>
              <PhyField l="Peso" v="78.2 kg"/>
              <PhyField l="Altura" v="1.78 m"/>
              <PhyField l="IMC" v="24.7"/>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Objetivos y notas técnicas"/>
          <Card>
            <div style={{ font: "500 11px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>OBJETIVO</div>
            <div style={{ font: "600 14.5px var(--font-body)", marginTop: 4 }}>Hipertrofia tren superior · Sumar 4 kg masa magra</div>
            <div className="divider"/>
            <div style={{ font: "500 11px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>LESIONES / CUIDADOS</div>
            <div style={{ font: "600 14.5px var(--font-body)", marginTop: 4, textWrap: "pretty" }}>Tendinitis leve hombro derecho (2024). Evitar press militar con barra; preferir mancuerna.</div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Progreso de press de banca" action="Ver todo →"/>
          <Card>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 10 }}>
              <span style={{ font: "800 28px var(--font-display)", letterSpacing: "-0.03em" }}>70 kg</span>
              <Chip kind="accent">+18 kg / 8 sem</Chip>
            </div>
            <ProgressChart/>
            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 10, font: "500 11px var(--font-mono)", color: "var(--ink-3)" }}>
              <span>MAR</span><span>ABR</span><span>MAY</span>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Últimas sesiones"/>
          <div className="row-list">
            {[
              { d: "Hoy",   r: "Push · Pecho+Hombros", n: "8 ej · 53 min", k: "ok" },
              { d: "Lun 19", r: "Pull · Espalda+Bíceps", n: "7 ej · 48 min", k: "ok" },
              { d: "Sáb 17", r: "Leg · Pierna+Glúteo", n: "6 ej · 62 min", k: "ok" },
            ].map((s, i) => (
              <div key={i} className="row">
                <span className="av" style={{ background: "var(--accent)", color: "var(--accent-ink)" }}>{I.check}</span>
                <div className="tx">
                  <div className="nm">{s.r}</div>
                  <div className="sub">{s.n}</div>
                </div>
                <span className="tail">{s.d}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="section" style={{ display: "flex", gap: 10 }}>
          <Btn kind="ghost" block>Ver historial</Btn>
          <Btn kind="primary" block onClick={() => go("assignRoutine")}>Asignar rutina</Btn>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// EXERCISE LIBRARY
// ═══════════════════════════════════════════════════════════════
function TrainerLibrary({ go }) {
  const [active, setActive] = React.useState("Todos");
  const items = EXERCISE_LIBRARY.filter(e => active === "Todos" || e.g === active);
  return (
    <Screen>
      <Header title="Biblioteca" right={<button className="h-icon" onClick={() => go("createExercise")}>{I.plus}</button>}/>
      <div className="scroll has-nav">
        <div className="section">
          <div style={{ display: "flex", gap: 6, overflowX: "auto", paddingBottom: 8 }}>
            {MUSCLE_GROUPS.map(g => (
              <button key={g} onClick={() => setActive(g)} style={{
                flex: "0 0 auto", padding: "8px 14px", borderRadius: 999,
                border: "1px solid " + (active === g ? "var(--ink)" : "var(--border)"),
                background: active === g ? "var(--ink)" : "var(--surface)",
                color: active === g ? "#fff" : "var(--ink)",
                font: "600 12.5px var(--font-body)",
                cursor: "pointer"
              }}>{g}</button>
            ))}
          </div>
        </div>

        <div className="section">
          <div className="row-list">
            {items.map(e => (
              <div key={e.id} className="ex-tile" onClick={() => go("editExercise", { id: e.id })}>
                <div className="thumb" style={{ background: "var(--ink)" }}><ExerciseAnim kind={e.k} small/></div>
                <div className="info">
                  <div className="n">{e.n}</div>
                  <div className="m">{e.g} · {e.a ? "Animación GIF v3" : "Sin animación"}</div>
                </div>
                <Chip kind={e.a ? "ok" : "warn"}>{e.a ? "Animado" : "Sin GIF"}</Chip>
              </div>
            ))}
          </div>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// CREATE / EDIT EXERCISE
function CreateExercise({ go }) {
  return (
    <Screen>
      <Header title="Nuevo ejercicio" onBack={() => go("library")}/>
      <div className="scroll" style={{ paddingBottom: 24 }}>
        <div className="section">
          <Card>
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="field">
                <label>Animación / GIF</label>
                <div style={{ height: 180, background: "var(--ink)", borderRadius: 18, display: "grid", placeItems: "center", color: "rgba(255,255,255,.5)", position: "relative", overflow: "hidden" }}>
                  <div style={{ position: "absolute", top: 12, left: 14, font: "600 10.5px var(--font-mono)", color: "var(--accent)", letterSpacing: ".08em", textTransform: "uppercase" }}>● VISTA PREVIA</div>
                  <ExerciseAnim kind="bench"/>
                </div>
                <div style={{ display: "flex", gap: 8, marginTop: 4 }}>
                  <Btn kind="ghost" block leading={I.upload}>Subir GIF</Btn>
                  <Btn kind="ghost" block leading={I.camera}>Grabar</Btn>
                </div>
              </div>
              <div className="field">
                <label>Nombre del ejercicio</label>
                <input placeholder="Ej. Press de banca con barra" defaultValue="Press inclinado mancuernas"/>
              </div>
              <div className="field">
                <label>Grupo muscular</label>
                <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                  {["Pecho", "Espalda", "Hombro", "Pierna", "Bíceps", "Tríceps", "Glúteo", "Core"].map((g, i) => (
                    <span key={g} className={`chip ${i === 0 ? "solid" : ""}`}>{g}</span>
                  ))}
                </div>
              </div>
              <div className="field">
                <label>Descripción técnica</label>
                <textarea rows="4" defaultValue="Mantener escapulas retraídas. Codos a 45°. Rango completo: bajar a 3-4 cm del pecho." style={{ resize: "none" }}/>
              </div>
            </div>
          </Card>
        </div>
        <div className="section">
          <Btn kind="primary" size="lg" block onClick={() => go("library")}>Guardar en biblioteca</Btn>
        </div>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// ROUTINE TEMPLATES
// ═══════════════════════════════════════════════════════════════
function TrainerRoutines({ go }) {
  const templates = [
    { id: "r1", n: "Push · Pecho + Hombros", ej: 6, dur: "55 min", as: 3, k: "bench" },
    { id: "r2", n: "Pull · Espalda + Bíceps", ej: 7, dur: "60 min", as: 5, k: "row" },
    { id: "r3", n: "Leg · Pierna + Glúteo", ej: 6, dur: "70 min", as: 4, k: "squat" },
    { id: "r4", n: "Full body intermedio",  ej: 8, dur: "75 min", as: 2, k: "press" },
  ];
  return (
    <Screen>
      <Header title="Plantillas de rutina" right={<button className="h-icon">{I.plus}</button>}/>
      <div className="scroll has-nav">
        <div className="section">
          <Card className="accent" style={{ padding: 16 }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <div>
                <div style={{ font: "600 11.5px var(--font-mono)", letterSpacing: ".08em", textTransform: "uppercase", opacity: .65 }}>SUGERENCIA</div>
                <div style={{ font: "700 16px var(--font-display)", letterSpacing: "-0.02em", marginTop: 4, textWrap: "pretty" }}>3 alumnos sin rutina asignada esta semana</div>
              </div>
              <Btn kind="primary" size="sm" onClick={() => go("assignRoutine")}>Asignar</Btn>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Mis plantillas" action="14 totales"/>
          <div className="row-list">
            {templates.map(t => (
              <Card key={t.id} style={{ padding: 14, cursor: "pointer" }} onClick={() => go("editRoutine", { id: t.id })}>
                <div style={{ display: "flex", gap: 12 }}>
                  <div style={{ width: 56, height: 56, borderRadius: 14, background: "var(--ink)", color: "#fff", display: "grid", placeItems: "center", flexShrink: 0 }}>
                    <ExerciseAnim kind={t.k} small/>
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ font: "700 15.5px var(--font-display)", letterSpacing: "-0.02em" }}>{t.n}</div>
                    <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 4 }}>{t.ej} ejercicios · {t.dur}</div>
                    <div style={{ display: "flex", gap: 6, marginTop: 8 }}>
                      <Chip>Asignada a {t.as}</Chip>
                    </div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// EDIT ROUTINE (plantilla)
function EditRoutine({ go }) {
  return (
    <Screen>
      <Header title="Push · Pecho + Hombros" onBack={() => go("routines")} right={<button className="h-icon">{I.more}</button>}/>
      <div className="scroll" style={{ paddingBottom: 100 }}>
        <div className="section">
          <Card className="flat" style={{ padding: 14, display: "flex", justifyContent: "space-around", textAlign: "center" }}>
            <div><div style={{ font: "800 22px var(--font-display)", letterSpacing: "-0.03em" }}>6</div><div style={{ font: "500 11px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>Ejercicios</div></div>
            <div style={{ width: 1, background: "var(--border)" }}/>
            <div><div style={{ font: "800 22px var(--font-display)", letterSpacing: "-0.03em" }}>22</div><div style={{ font: "500 11px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>Series</div></div>
            <div style={{ width: 1, background: "var(--border)" }}/>
            <div><div style={{ font: "800 22px var(--font-display)", letterSpacing: "-0.03em" }}>55<span style={{ font: "500 13px var(--font-body)" }}>min</span></div><div style={{ font: "500 11px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>Duración</div></div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Ejercicios" action="+ Añadir"/>
          <div className="row-list">
            {EXERCISES_TODAY.map((e, i) => (
              <Card key={e.id} style={{ padding: 12 }}>
                <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                  <span style={{ font: "700 14px var(--font-mono)", color: "var(--ink-3)", width: 22 }}>{String(i + 1).padStart(2, "0")}</span>
                  <div style={{ width: 48, height: 48, borderRadius: 12, background: "var(--ink)", display: "grid", placeItems: "center", color: "#fff" }}>
                    <ExerciseAnim kind={e.kind} small/>
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{e.name}</div>
                    <div style={{ font: "500 12.5px var(--font-mono)", color: "var(--ink-2)", marginTop: 2 }}>{e.sets}×{e.reps} · {e.weight || 0}kg · {e.rest}s</div>
                  </div>
                  <button className="h-icon" style={{ width: 32, height: 32 }}>{I.edit}</button>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </div>
      <div className="sticky-cta">
        <Btn kind="primary" block size="lg" onClick={() => go("assignRoutine")}>Asignar a alumno</Btn>
      </div>
    </Screen>
  );
}

// ASSIGN ROUTINE
function AssignRoutine({ go }) {
  const [selected, setSelected] = React.useState(["m1", "m5"]);
  const [days, setDays] = React.useState({ MON: "r1", TUE: "r2", WED: "r1", THU: "r3", FRI: "r1", SAT: "r2", SUN: null });
  const dayNames = { MON: "Lunes", TUE: "Martes", WED: "Miércoles", THU: "Jueves", FRI: "Viernes", SAT: "Sábado", SUN: "Domingo" };
  const rTemplates = {
    r1: { n: "Push · Pecho+Hombros", c: "var(--ink)" },
    r2: { n: "Pull · Espalda+Bíceps", c: "#0066FF" },
    r3: { n: "Leg · Pierna+Glúteo", c: "#FF4D17" },
  };
  return (
    <Screen>
      <Header title="Asignar rutina" onBack={() => go("home")}/>
      <div className="scroll" style={{ paddingBottom: 100 }}>
        <div className="section">
          <SectionTitle title="Selecciona alumnos" action={`${selected.length} seleccionados`}/>
          <div style={{ display: "flex", gap: 8, overflowX: "auto", paddingBottom: 8 }}>
            {MY_MEMBERS.map(m => {
              const sel = selected.includes(m.id);
              return (
                <button key={m.id} onClick={() => setSelected(sel ? selected.filter(x => x !== m.id) : [...selected, m.id])} style={{
                  flex: "0 0 auto", textAlign: "center", width: 76, padding: "10px 6px",
                  border: "2px solid " + (sel ? "var(--ink)" : "var(--border)"),
                  borderRadius: 14,
                  background: sel ? "var(--surface-2)" : "var(--surface)",
                  cursor: "pointer"
                }}>
                  <Avatar name={m.n} size={44}/>
                  <div style={{ font: "600 11px var(--font-body)", marginTop: 6 }}>{m.n.split(" ")[0]}</div>
                  {sel && <div style={{ position: "absolute" }}>{/* checkmark */}</div>}
                </button>
              );
            })}
          </div>
        </div>

        <div className="section">
          <SectionTitle title="Agenda semanal personalizada"/>
          <div className="row-list">
            {Object.entries(dayNames).map(([d, label]) => {
              const r = days[d];
              const tpl = r ? rTemplates[r] : null;
              return (
                <Card key={d} style={{ padding: 12, display: "flex", alignItems: "center", gap: 12 }}>
                  <span className="av" style={{ width: 44, height: 44, background: "var(--surface-2)", color: "var(--ink)", font: "700 11px var(--font-display)", letterSpacing: "-0.01em", textTransform: "uppercase" }}>{d.slice(0, 3)}</span>
                  <div style={{ flex: 1 }}>
                    <div style={{ font: "600 13.5px var(--font-body)" }}>{label}</div>
                    {tpl ? (
                      <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{tpl.n}</div>
                    ) : (
                      <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-3)", marginTop: 2 }}>Día de descanso</div>
                    )}
                  </div>
                  {tpl
                    ? <Chip kind="solid" style={{ background: tpl.c }}>● Asignada</Chip>
                    : <Chip>Asignar</Chip>}
                </Card>
              );
            })}
          </div>
        </div>
      </div>
      <div className="sticky-cta">
        <Btn kind="primary" block size="lg" onClick={() => go("home")} leading={I.send}>Publicar a {selected.length} alumnos</Btn>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// TRAINER STATS
// ═══════════════════════════════════════════════════════════════
function TrainerStats({ go }) {
  return (
    <Screen>
      <Header title="Progreso técnico" right={<button className="h-icon">{I.filter}</button>}/>
      <div className="scroll has-nav">
        <div className="section">
          <Card className="flat" style={{ padding: 14, display: "flex", gap: 10, alignItems: "center" }}>
            <Avatar name="Mateo Salas" size={42}/>
            <div style={{ flex: 1 }}>
              <div style={{ font: "600 11px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>ALUMNO SELECCIONADO</div>
              <div style={{ font: "700 15px var(--font-display)", letterSpacing: "-0.02em" }}>Mateo Salas</div>
            </div>
            <Btn kind="ghost" size="sm">Cambiar</Btn>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Press de banca" action="+18 kg"/>
          <Card>
            <ProgressChart/>
            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 10, font: "500 11px var(--font-mono)", color: "var(--ink-3)" }}>
              <span>S1</span><span>S2</span><span>S3</span><span>S4</span><span>S5</span><span>S6</span><span>S7</span><span>S8</span>
            </div>
            <div className="divider"/>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 14 }}>
              <PhyField l="Récord" v="72 kg"/>
              <PhyField l="Promedio" v="65 kg"/>
              <PhyField l="Última" v="70 kg"/>
            </div>
          </Card>
        </div>

        <div className="section">
          <SectionTitle title="Volumen total levantado · 8 sem"/>
          <Card>
            <div style={{ display: "flex", alignItems: "flex-end", gap: 6, height: 140 }}>
              {[14, 18, 21, 19, 24, 27, 26, 32].map((v, i) => (
                <div key={i} style={{ flex: 1, height: `${(v / 32) * 100}%`, background: i === 7 ? "var(--accent)" : "var(--ink)", borderRadius: "6px 6px 0 0" }}/>
              ))}
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 10, font: "500 11px var(--font-mono)", color: "var(--ink-3)" }}>
              <span>S1</span><span>S2</span><span>S3</span><span>S4</span><span>S5</span><span>S6</span><span>S7</span><span>S8</span>
            </div>
            <div className="divider"/>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
              <div>
                <div style={{ font: "500 11px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>Esta semana</div>
                <div style={{ font: "800 24px var(--font-display)", letterSpacing: "-0.03em", marginTop: 4 }}>32 ton</div>
              </div>
              <Chip kind="accent">{I.trend} +23%</Chip>
            </div>
          </Card>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// TRAINER PROFILE
// ═══════════════════════════════════════════════════════════════
function TrainerProfile({ go, onLogout }) {
  return (
    <Screen>
      <Header title="Mi perfil profesional" right={<button className="h-icon">{I.edit}</button>}/>
      <div className="scroll has-nav">
        <div className="section">
          <Card>
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <Avatar name="Carlos Mendoza" size={72}/>
              <div style={{ flex: 1 }}>
                <div style={{ font: "800 22px var(--font-display)", letterSpacing: "-0.03em" }}>Carlos Mendoza</div>
                <div style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>Entrenador · Hipertrofia & Fuerza</div>
                <div style={{ display: "flex", gap: 6, marginTop: 8 }}>
                  <Chip leading={I.star}>4.9</Chip>
                  <Chip>7 alumnos</Chip>
                </div>
              </div>
            </div>
            <div className="divider"/>
            <Field l="Especialidad" v="Fuerza & Hipertrofia"/>
            <Field l="Experiencia" v="8 años"/>
            <Field l="Certificaciones" v="NSCA-CPT · ISAK 2"/>
            <Field l="Bio" v="Coach especializado en hipertrofia natural y desarrollo de fuerza."/>
          </Card>
        </div>
        <div className="section">
          <Btn kind="ghost" block onClick={onLogout}>Cerrar sesión</Btn>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

// ═══════════════════════════════════════════════════════════════
// TRAINER ROUTER
// ═══════════════════════════════════════════════════════════════
function TrainerApp() {
  const { screen, params, go } = useRouter("home");
  const [authed, setAuthed] = React.useState(false);

  if (!authed) return <LoginScreen role="trainer" onLogin={() => setAuthed(true)}/>;

  const navCurrent = ({
    home: "home", memberDetail: "home",
    library: "library", createExercise: "library", editExercise: "library",
    routines: "routines", editRoutine: "routines", assignRoutine: "routines",
    stats: "stats",
    profile: "profile",
  })[screen] || "home";

  return (
    <>
      {screen === "home" && <TrainerHome go={go}/>}
      {screen === "memberDetail" && <TrainerMemberDetail go={go} params={params}/>}
      {screen === "library" && <TrainerLibrary go={go}/>}
      {screen === "createExercise" && <CreateExercise go={go}/>}
      {screen === "editExercise" && <CreateExercise go={go}/>}
      {screen === "routines" && <TrainerRoutines go={go}/>}
      {screen === "editRoutine" && <EditRoutine go={go}/>}
      {screen === "assignRoutine" && <AssignRoutine go={go}/>}
      {screen === "stats" && <TrainerStats go={go}/>}
      {screen === "profile" && <TrainerProfile go={go} onLogout={() => setAuthed(false)}/>}

      <div className="bnav-overlay">
        <BottomNav items={TRAINER_NAV} current={navCurrent} onChange={(id) => go(id)}/>
      </div>
    </>
  );
}

Object.assign(window, { TrainerApp });

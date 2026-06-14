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

window.Entrenamientos = Entrenamientos;

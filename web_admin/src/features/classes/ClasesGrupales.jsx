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

window.Clases = Clases;

import React from 'react';
import { CLASSES } from '../../../data.jsx';
import { Badge, Btn, I, Modal, Panel } from '../../../shared.jsx';

function Clases({ app }) {
  const [trainers, setTrainers] = React.useState([]);
  const [editingSchedule, setEditingSchedule] = React.useState(null);

  React.useEffect(() => {
    if (app?.loadTrainers) {
      app.loadTrainers().then(data => setTrainers(data || [])).catch(() => null);
    }
  }, [app]);

  const dayMap = ["Dom", "Lun", "Mar", "Mie", "Jue", "Vie", "Sab"];

  // Helper to map trainer ID to name
  const getTrainerName = (trainerId) => {
    const coach = trainers.find(t => t.id === trainerId);
    return coach ? coach.nombre_completo : "Entrenador no asignado";
  };

  const rows = app?.schedules?.length ? app.schedules.filter(s => s.activo !== false).map(s => {
    const reserved = s.bookings?.filter(b => b.estado === "CONFIRMED" || b.estado === "ATTENDED").length || 0;
    return {
      id: s.id,
      n: s.nombre_clase,
      descripcion: s.descripcion || "",
      trainer_id: s.trainer_id,
      coach: getTrainerName(s.trainer_id),
      dias: (s.dia_semana || []).map(d => dayMap[d] || d).join(", "),
      rawDias: s.dia_semana || [],
      hora_inicio: s.hora_inicio,
      hora_fin: s.hora_fin,
      hora: `${s.hora_inicio} - ${s.hora_fin}`,
      cupo_maximo: s.cupo_maximo,
      cupo: `${reserved}/${s.cupo_maximo}`,
      st: reserved >= s.cupo_maximo ? "full" : reserved >= s.cupo_maximo * 0.75 ? "warn" : "ok",
    };
  }) : CLASSES.map(c => ({ ...c, rawDias: [1, 3, 5], hora_inicio: "08:00", hora_fin: "09:00", cupo_maximo: 20 }));

  const handleSaveSchedule = async (e) => {
    e.preventDefault();
    if (!editingSchedule.nombre_clase || !editingSchedule.trainer_id || !editingSchedule.hora_inicio || !editingSchedule.hora_fin) {
      alert("Por favor completa los campos requeridos.");
      return;
    }

    try {
      await app.saveSchedule({
        id: editingSchedule.id,
        nombre_clase: editingSchedule.nombre_clase,
        descripcion: editingSchedule.descripcion || "",
        trainer_id: editingSchedule.trainer_id,
        dia_semana: editingSchedule.rawDias || [],
        hora_inicio: editingSchedule.hora_inicio,
        hora_fin: editingSchedule.hora_fin,
        cupo_maximo: Number(editingSchedule.cupo_maximo) || 20,
      });
      setEditingSchedule(null);
    } catch (err) {
      alert("Error al guardar la clase: " + (err.message || err));
    }
  };

  const handleDeleteSchedule = async (id, name) => {
    if (!confirm(`¿Estás seguro de inhabilitar la clase "${name}"?`)) return;
    try {
      await app.deleteSchedule(id);
    } catch (err) {
      alert("Error al eliminar la clase: " + (err.message || err));
    }
  };

  const toggleDay = (dayIndex) => {
    const current = editingSchedule.rawDias || [];
    if (current.includes(dayIndex)) {
      setEditingSchedule({
        ...editingSchedule,
        rawDias: current.filter(d => d !== dayIndex),
      });
    } else {
      setEditingSchedule({
        ...editingSchedule,
        rawDias: [...current, dayIndex].sort(),
      });
    }
  };

  return (
    <div className="content-wrap">
      <Panel title="Clases y horarios" sub={`${rows.length} clases activas`}
             action={<Btn kind="primary" size="sm" leading={I.plus} onClick={() => setEditingSchedule({ nombre_clase: "", descripcion: "", trainer_id: trainers[0]?.id || "", rawDias: [1, 3, 5], hora_inicio: "08:00", hora_fin: "09:00", cupo_maximo: 20 })}>Crear clase</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead>
            <tr>
              <th>Clase</th>
              <th>Entrenador</th>
              <th>Días</th>
              <th>Hora</th>
              <th className="num">Cupo</th>
              <th>Estado</th>
              <th className="num">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((c, i) => (
              <tr key={c.id || i} className="clickable">
                <td onClick={() => setEditingSchedule(c)}>
                  <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                    <span className="l-ic" style={{ width: 30, height: 30, background: "var(--ink)", color: "var(--accent)" }}>{I.calendar}</span>
                    <span className="cell-main">{c.n}</span>
                  </div>
                </td>
                <td style={{ color: "var(--ink-2)" }} onClick={() => setEditingSchedule(c)}>{c.coach}</td>
                <td style={{ color: "var(--ink-2)" }} onClick={() => setEditingSchedule(c)}>{c.dias}</td>
                <td style={{ font: "600 13px var(--font-mono)" }} onClick={() => setEditingSchedule(c)}>{c.hora}</td>
                <td className="num" onClick={() => setEditingSchedule(c)}>{c.cupo}</td>
                <td onClick={() => setEditingSchedule(c)}>
                  {c.st === "full" ? <Badge kind="danger" dot>Lleno</Badge>
                    : c.st === "warn" ? <Badge kind="warn" dot>Casi lleno</Badge>
                    : <Badge kind="ok" dot>Disponible</Badge>}
                </td>
                <td className="num">
                  <div style={{ display: "inline-flex", gap: 8 }}>
                    <Btn kind="ghost" size="sm" onClick={() => setEditingSchedule(c)}>Editar</Btn>
                    {c.id && (
                      <Btn kind="ghost" size="sm" onClick={() => handleDeleteSchedule(c.id, c.n)} style={{ color: "var(--danger)" }}>{I.trash}</Btn>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>
      <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-3)", marginTop: 12 }}>
        Los miembros reservan su cupo desde la app móvil; al llenarse pasan a lista de espera.
      </div>

      {editingSchedule && (
        <Modal title={editingSchedule.id ? "Editar Clase Grupal" : "Nueva Clase Grupal"} onClose={() => setEditingSchedule(null)}>
          <form onSubmit={handleSaveSchedule} style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            <div className="field">
              <label>Nombre de la Clase</label>
              <input value={editingSchedule.nombre_clase || ""} onChange={e => setEditingSchedule({ ...editingSchedule, nombre_clase: e.target.value })} required />
            </div>
            <div className="field">
              <label>Descripción</label>
              <textarea rows="2" value={editingSchedule.descripcion || ""} onChange={e => setEditingSchedule({ ...editingSchedule, descripcion: e.target.value })} />
            </div>
            <div className="field">
              <label>Entrenador Asignado</label>
              <select value={editingSchedule.trainer_id || ""} onChange={e => setEditingSchedule({ ...editingSchedule, trainer_id: e.target.value })} required>
                <option value="" disabled>Selecciona un entrenador...</option>
                {trainers.map(t => (
                  <option key={t.id} value={t.id}>{t.nombre_completo} ({t.email})</option>
                ))}
              </select>
            </div>
            <div className="field">
              <label>Días de la Semana</label>
              <div style={{ display: "flex", gap: 10, flexWrap: "wrap", marginTop: 6 }}>
                {[1, 2, 3, 4, 5, 6, 0].map(dayIdx => {
                  const isChecked = (editingSchedule.rawDias || []).includes(dayIdx);
                  return (
                    <label key={dayIdx} className="check-inline" style={{ background: isChecked ? "var(--accent-12)" : "var(--bg-card)", padding: "4px 8px", borderRadius: 4, cursor: "pointer" }}>
                      <input type="checkbox" checked={isChecked} onChange={() => toggleDay(dayIdx)} style={{ marginRight: 4 }} />
                      {dayMap[dayIdx]}
                    </label>
                  );
                })}
              </div>
            </div>
            <div className="row-3">
              <div className="field">
                <label>Hora Inicio</label>
                <input type="time" value={editingSchedule.hora_inicio || ""} onChange={e => setEditingSchedule({ ...editingSchedule, hora_inicio: e.target.value })} required />
              </div>
              <div className="field">
                <label>Hora Fin</label>
                <input type="time" value={editingSchedule.hora_fin || ""} onChange={e => setEditingSchedule({ ...editingSchedule, hora_fin: e.target.value })} required />
              </div>
              <div className="field">
                <label>Cupo Máximo</label>
                <input type="number" min="1" value={editingSchedule.cupo_maximo || 20} onChange={e => setEditingSchedule({ ...editingSchedule, cupo_maximo: Number(e.target.value) })} required />
              </div>
            </div>
            <div className="modal-foot inline" style={{ marginTop: 8 }}>
              <Btn type="button" kind="ghost" onClick={() => setEditingSchedule(null)}>Cancelar</Btn>
              <Btn type="submit" kind="primary">Guardar Clase</Btn>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}

export { Clases };

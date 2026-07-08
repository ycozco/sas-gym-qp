import React from 'react';
import { Badge, Btn, ErrorBlock, I, Kpi, MemberSearchBox, Panel } from '../../../shared.jsx';

function Entrenamientos({ app }) {
  const [tab, setTab] = React.useState("asignaciones");
  
  // Data States
  const [exercises, setExercises] = React.useState([]);
  const [templates, setTemplates] = React.useState([]);
  const [progress, setProgress] = React.useState(null);
  
  // Loading & Messages
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState("");
  const [message, setMessage] = React.useState("");

  // Modals & View States
  const [isCreatingExercise, setIsCreatingExercise] = React.useState(false);
  const [isCreatingTemplate, setIsCreatingTemplate] = React.useState(false);
  const [isAssigning, setIsAssigning] = React.useState(false);
  const [selectedTemplateForView, setSelectedTemplateForView] = React.useState(null);

  // Form State: New Exercise
  const [newExerciseForm, setNewExerciseForm] = React.useState({
    nombre: "",
    descripcion: "",
    grupoMuscular: "Piernas",
    imagenUrl: "",
    animacionUrl: ""
  });

  // Form State: New Template
  const [newTemplateForm, setNewTemplateForm] = React.useState({
    nombre: "",
    descripcion: "",
    ejercicios: [] // { exerciseId, exerciseName, orden, series, repeticiones, pesoSugeridoKg, descansoSeg }
  });
  const [tempExercise, setTempExercise] = React.useState({
    exerciseId: "",
    series: 4,
    repeticiones: 12,
    pesoSugeridoKg: 0,
    descansoSeg: 60
  });

  // Form State: Assign Routine
  const [assignForm, setAssignForm] = React.useState({
    memberUserId: "",
    templateId: "",
    agendaSemanal: {
      LUN: "",
      MAR: "",
      MIE: "",
      JUE: "",
      VIE: "",
      SAB: "",
      DOM: ""
    },
    publicada: true
  });
  const [memberQuery, setMemberQuery] = React.useState("");
  const [memberResults, setMemberResults] = React.useState([]);
  const [selectedMember, setSelectedMember] = React.useState(null);

  // Muscle groups matching database / presets
  const GRUPOS_MUSCULARES = [
    "Pecho", "Espalda", "Piernas", "Hombros", "Brazos", "Abdominales", "Cardio", "Cuerpo Completo"
  ];

  const fetchData = React.useCallback(async () => {
    setError("");
    setLoading(true);
    try {
      const [exs, tps, prog] = await Promise.all([
        app.loadExercises().catch(() => []),
        app.loadRoutineTemplates().catch(() => []),
        app.apiRequest ? app.apiRequest("/routines/trainer/progress").catch(() => null) : Promise.resolve(null)
      ]);
      setExercises(exs || []);
      setTemplates(tps || []);
      setProgress(prog);
    } catch (err) {
      setError(err.message || "Error al cargar información de entrenamientos.");
    } finally {
      setLoading(false);
    }
  }, [app]);

  React.useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Search Members for assignment
  React.useEffect(() => {
    let alive = true;
    if (!app?.searchMembers || memberQuery.trim().length < 2) {
      setMemberResults([]);
      return;
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
  }, [memberQuery, app]);

  // Actions: Create Exercise
  const handleCreateExercise = async (e) => {
    e.preventDefault();
    setError("");
    setMessage("");
    if (!newExerciseForm.nombre.trim()) {
      setError("El nombre del ejercicio es obligatorio.");
      return;
    }
    try {
      setLoading(true);
      await app.createExercise(newExerciseForm);
      setMessage(`Ejercicio "${newExerciseForm.nombre}" creado exitosamente.`);
      setIsCreatingExercise(false);
      setNewExerciseForm({ nombre: "", descripcion: "", grupoMuscular: "Piernas", imagenUrl: "", animacionUrl: "" });
      fetchData();
    } catch (err) {
      setError(err.message || "No se pudo crear el ejercicio.");
    } finally {
      setLoading(false);
    }
  };

  // Actions: Add exercise to template drafting
  const addExerciseToTemplateDraft = () => {
    if (!tempExercise.exerciseId) {
      alert("Selecciona un ejercicio primero.");
      return;
    }
    const exObj = exercises.find(e => e.id === tempExercise.exerciseId);
    if (!exObj) return;

    const newItem = {
      exerciseId: tempExercise.exerciseId,
      exerciseName: exObj.nombre,
      grupoMuscular: exObj.grupo_muscular,
      orden: newTemplateForm.ejercicios.length + 1,
      series: Number(tempExercise.series) || 4,
      repeticiones: Number(tempExercise.repeticiones) || 12,
      pesoSugeridoKg: Number(tempExercise.pesoSugeridoKg) || 0,
      descansoSeg: Number(tempExercise.descansoSeg) || 60
    };

    setNewTemplateForm({
      ...newTemplateForm,
      ejercicios: [...newTemplateForm.ejercicios, newItem]
    });
  };

  const removeExerciseFromTemplateDraft = (idx) => {
    const filtered = newTemplateForm.ejercicios.filter((_, i) => i !== idx).map((item, i) => ({
      ...item,
      orden: i + 1
    }));
    setNewTemplateForm({ ...newTemplateForm, ejercicios: filtered });
  };

  // Actions: Create Template
  const handleCreateTemplate = async (e) => {
    e.preventDefault();
    setError("");
    setMessage("");
    if (!newTemplateForm.nombre.trim()) {
      setError("El nombre de la plantilla es obligatorio.");
      return;
    }
    if (newTemplateForm.ejercicios.length === 0) {
      setError("Debes añadir al menos un ejercicio a la plantilla.");
      return;
    }
    try {
      setLoading(true);
      const payload = {
        nombre: newTemplateForm.nombre,
        descripcion: newTemplateForm.descripcion,
        ejercicios: newTemplateForm.ejercicios.map(ej => ({
          exerciseId: ej.exerciseId,
          orden: ej.orden,
          series: ej.series,
          repeticiones: ej.repeticiones,
          pesoSugeridoKg: ej.pesoSugeridoKg,
          descansoSeg: ej.descansoSeg
        }))
      };
      await app.createRoutineTemplate(payload);
      setMessage(`Plantilla de rutina "${newTemplateForm.nombre}" creada con éxito.`);
      setIsCreatingTemplate(false);
      setNewTemplateForm({ nombre: "", descripcion: "", ejercicios: [] });
      fetchData();
    } catch (err) {
      setError(err.message || "Error al crear la plantilla.");
    } finally {
      setLoading(false);
    }
  };

  // Actions: Assign Routine
  const handleAssignRoutine = async (e) => {
    e.preventDefault();
    setError("");
    setMessage("");
    if (!selectedMember) {
      setError("Por favor, busca y selecciona a un socio.");
      return;
    }
    if (!assignForm.templateId) {
      setError("Por favor, selecciona una plantilla de rutina.");
      return;
    }

    try {
      setLoading(true);
      const agenda = {};
      // Llenamos la agenda: si el día está vacío, asociamos la plantilla seleccionada
      Object.keys(assignForm.agendaSemanal).forEach(day => {
        agenda[day] = assignForm.agendaSemanal[day] ? assignForm.agendaSemanal[day].trim() : assignForm.templateId;
      });

      const payload = {
        memberUserId: selectedMember.id,
        templateId: assignForm.templateId,
        agendaSemanal: agenda,
        publicada: assignForm.publicada
      };

      await app.assignRoutine(payload);
      setMessage(`Rutina asignada exitosamente al socio ${selectedMember.nombre_completo || selectedMember.name}.`);
      setIsAssigning(false);
      setSelectedMember(null);
      setMemberQuery("");
      setAssignForm({
        memberUserId: "",
        templateId: "",
        agendaSemanal: { LUN: "", MAR: "", MIE: "", JUE: "", VIE: "", SAB: "", DOM: "" },
        publicada: true
      });
      fetchData();
    } catch (err) {
      setError(err.message || "Error al asignar la rutina.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="content-wrap">
      <div className="tabs">
        <button className={tab === "asignaciones" ? "active" : ""} onClick={() => setTab("asignaciones")}>
          Asignaciones y Avance
        </button>
        <button className={tab === "plantillas" ? "active" : ""} onClick={() => setTab("plantillas")}>
          Plantillas de Rutina
        </button>
        <button className={tab === "ejercicios" ? "active" : ""} onClick={() => setTab("ejercicios")}>
          Biblioteca de Ejercicios
        </button>
      </div>

      <ErrorBlock message={error} />
      {message && <div className="state-block ok">{message}</div>}

      {/* TAB 1: ASIGNACIONES Y AVANCE */}
      {tab === "asignaciones" && !isAssigning && (
        <>
          <div className="grid cols-3" style={{ marginBottom: 20 }}>
            <Kpi icon="check" value={progress?.totals?.completedSessions ?? 0} label="Sesiones Completadas" dir="up" />
            <Kpi icon="trend" value={progress?.totals?.sessions ?? 0} label="Sesiones Totales Asignadas" />
            <Kpi icon="star" value={progress?.totals?.averageReps ? `${progress.totals.averageReps} reps` : "0 reps"} label="Promedio de Repeticiones Reales" />
          </div>

          <Panel title="Socios Asignados y Rendimiento" sub="Avance de rutinas y bitácora de ejecución" 
                 action={<Btn kind="primary" size="sm" leading={I.plus} onClick={() => setIsAssigning(true)}>Asignar Rutina</Btn>}
                 bodyPad={false}>
            <table className="tbl">
              <thead>
                <tr>
                  <th>Socio</th>
                  <th className="num">Sesiones Totales</th>
                  <th className="num">Completadas</th>
                  <th className="num">Promedio Reps/Serie</th>
                  <th>Estado</th>
                </tr>
              </thead>
              <tbody>
                {(progress?.memberSummaries || []).map((summary) => (
                  <tr key={summary.memberId}>
                    <td>
                      <div className="cell-main">{summary.memberName}</div>
                      <div className="cell-sub">ID: {summary.memberId}</div>
                    </td>
                    <td className="num">{summary.sessions}</td>
                    <td className="num" style={{ fontWeight: "bold", color: "var(--ok)" }}>{summary.completedSessions}</td>
                    <td className="num">{summary.averageReps} reps</td>
                    <td>
                      <Badge kind={summary.completedSessions > 0 ? "ok" : "warn"} dot>
                        {summary.completedSessions > 0 ? "Activo entrenando" : "Sin registrar ejecución"}
                      </Badge>
                    </td>
                  </tr>
                ))}
                {(!progress?.memberSummaries || progress.memberSummaries.length === 0) && (
                  <tr>
                    <td colSpan="5">
                      <div className="empty">No hay alumnos asignados con rutinas registradas en este turno.</div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </Panel>
        </>
      )}

      {/* FORMULARIO ASIGNAR RUTINA */}
      {tab === "asignaciones" && isAssigning && (
        <div className="grid k-2-1">
          <Panel title="Asignar Rutina a Socio" sub="Agenda semanal y publicación">
            <form onSubmit={handleAssignRoutine} style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              <MemberSearchBox 
                query={memberQuery} 
                setQuery={setMemberQuery} 
                results={memberResults} 
                selected={selectedMember} 
                setSelected={setSelectedMember} 
              />

              <div className="field">
                <label>Plantilla de Rutina Base</label>
                <select 
                  value={assignForm.templateId} 
                  onChange={e => setAssignForm({ ...assignForm, templateId: e.target.value })}
                  required
                >
                  <option value="">-- Selecciona una plantilla --</option>
                  {templates.map(t => (
                    <option key={t.id} value={t.id}>{t.nombre}</option>
                  ))}
                </select>
              </div>

              <div className="field">
                <label>Agenda de División Semanal (Opcional, dejar vacío para asignar la plantilla todos los días)</label>
                <div style={{ display: "flex", flexDirection: "column", gap: 8, marginTop: 8 }}>
                  {["LUN", "MAR", "MIE", "JUE", "VIE", "SAB", "DOM"].map(day => (
                    <div key={day} style={{ display: "flex", alignItems: "center", gap: 12 }}>
                      <span style={{ width: 45, fontWeight: "bold", fontSize: 13, color: "var(--ink-2)" }}>{day}:</span>
                      <input 
                        type="text" 
                        placeholder="Ej: Empuje / Tracción / Descanso" 
                        value={assignForm.agendaSemanal[day]} 
                        onChange={e => {
                          const agenda = { ...assignForm.agendaSemanal, [day]: e.target.value };
                          setAssignForm({ ...assignForm, agendaSemanal: agenda });
                        }}
                      />
                    </div>
                  ))}
                </div>
              </div>

              <div className="field">
                <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer" }}>
                  <input 
                    type="checkbox" 
                    checked={assignForm.publicada} 
                    onChange={e => setAssignForm({ ...assignForm, publicada: e.target.checked })} 
                  />
                  <span>Publicar rutina inmediatamente (visible para el socio en la app móvil)</span>
                </label>
              </div>

              <div className="modal-foot inline">
                <Btn kind="ghost" type="button" onClick={() => setIsAssigning(false)}>Cancelar</Btn>
                <Btn kind="primary" type="submit" disabled={loading}>Guardar Asignación</Btn>
              </div>
            </form>
          </Panel>
          <Panel title="Resumen del Socio" sub="Datos de perfil">
            {selectedMember ? (
              <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                <div className="cell-main" style={{ fontSize: 16 }}>{selectedMember.nombre_completo || selectedMember.name}</div>
                <div className="cell-sub">Email: {selectedMember.email}</div>
                <div className="cell-sub">DNI: {selectedMember.dni || "—"}</div>
                <div className="cell-sub">Celular: {selectedMember.celular || "—"}</div>
                <div className="divider" />
                <div style={{ color: "var(--ink-2)", fontSize: 13 }}>
                  • Al asignar una rutina nueva, cualquier asignación previa activa de este socio será marcada como inactiva (despublicada).
                </div>
              </div>
            ) : (
              <div className="empty">Busca y selecciona un socio en el formulario de la izquierda.</div>
            )}
          </Panel>
        </div>
      )}

      {/* TAB 2: PLANTILLAS DE RUTINA */}
      {tab === "plantillas" && !isCreatingTemplate && (
        <div className="grid k-2-1">
          <Panel title="Plantillas de Entrenamiento" sub="Rutinas preestablecidas y reusables"
                 action={<Btn kind="primary" size="sm" leading={I.plus} onClick={() => setIsCreatingTemplate(true)}>Nueva Plantilla</Btn>}
                 bodyPad={false}>
            <table className="tbl">
              <thead>
                <tr>
                  <th>Nombre</th>
                  <th>Ejercicios</th>
                  <th className="num">Acción</th>
                </tr>
              </thead>
              <tbody>
                {templates.map((t) => (
                  <tr key={t.id} className="clickable" onClick={() => setSelectedTemplateForView(t)}>
                    <td>
                      <div className="cell-main">{t.nombre}</div>
                      <div className="cell-sub">{t.descripcion || "Sin descripción"}</div>
                    </td>
                    <td>{t.ejercicios?.length ?? 0} ejercicios</td>
                    <td className="num">
                      <Btn kind="ghost" size="sm">Ver Detalles</Btn>
                    </td>
                  </tr>
                ))}
                {templates.length === 0 && (
                  <tr>
                    <td colSpan="3">
                      <div className="empty">No hay plantillas de entrenamiento guardadas.</div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </Panel>

          <Panel title="Detalles de Plantilla" sub={selectedTemplateForView?.nombre || "Ninguna seleccionada"}>
            {selectedTemplateForView ? (
              <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                <p style={{ fontStyle: "italic", fontSize: 13, color: "var(--ink-2)" }}>
                  {selectedTemplateForView.descripcion || "Sin descripción."}
                </p>
                <div className="divider" />
                <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                  {(selectedTemplateForView.ejercicios || []).map((e) => (
                    <div key={e.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: 8, background: "var(--background)", borderRadius: 8 }}>
                      <div>
                        <div style={{ fontWeight: "bold", fontSize: 13 }}>{e.exercise?.nombre}</div>
                        <div style={{ fontSize: 11, color: "var(--ink-3)" }}>Grupo: {e.exercise?.grupo_muscular}</div>
                      </div>
                      <div style={{ fontSize: 13, fontWeight: "700", color: "var(--accent)" }}>
                        {e.series}x{e.repeticiones} ({e.descanso_seg}s desc)
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <div className="empty">Selecciona una plantilla de la lista para ver su desglose.</div>
            )}
          </Panel>
        </div>
      )}

      {/* FORMULARIO CREAR PLANTILLA */}
      {tab === "plantillas" && isCreatingTemplate && (
        <div className="grid k-2-1">
          <Panel title="Nueva Plantilla de Entrenamiento" sub="Define la rutina y agrega ejercicios">
            <form onSubmit={handleCreateTemplate} style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              <div className="field">
                <label>Nombre de la Plantilla</label>
                <input 
                  type="text" 
                  placeholder="Ej: Torso - Fuerza máxima" 
                  value={newTemplateForm.nombre}
                  onChange={e => setNewTemplateForm({ ...newTemplateForm, nombre: e.target.value })}
                  required
                />
              </div>

              <div className="field">
                <label>Descripción / Instrucciones</label>
                <textarea 
                  rows="2" 
                  placeholder="Ej: Rutina de empujes horizontales y verticales. Mantener RPE 8-9."
                  value={newTemplateForm.descripcion}
                  onChange={e => setNewTemplateForm({ ...newTemplateForm, descripcion: e.target.value })}
                />
              </div>

              <div className="divider" />
              <h4>Ejercicios Seleccionados ({newTemplateForm.ejercicios.length})</h4>
              
              <table className="tbl" style={{ marginTop: 8 }}>
                <thead>
                  <tr>
                    <th>Orden</th>
                    <th>Ejercicio</th>
                    <th>Series</th>
                    <th>Reps</th>
                    <th>Peso</th>
                    <th className="num">Acción</th>
                  </tr>
                </thead>
                <tbody>
                  {newTemplateForm.ejercicios.map((ej, index) => (
                    <tr key={index}>
                      <td>{ej.orden}</td>
                      <td>
                        <div className="cell-main">{ej.exerciseName}</div>
                        <div className="cell-sub">{ej.grupoMuscular}</div>
                      </td>
                      <td>{ej.series}</td>
                      <td>{ej.repeticiones}</td>
                      <td>{ej.pesoSugeridoKg > 0 ? `${ej.pesoSugeridoKg} kg` : "RPE"}</td>
                      <td className="num">
                        <Btn kind="ghost" size="sm" type="button" onClick={() => removeExerciseFromTemplateDraft(index)} style={{ color: "var(--danger)" }}>
                          {I.close}
                        </Btn>
                      </td>
                    </tr>
                  ))}
                  {newTemplateForm.ejercicios.length === 0 && (
                    <tr>
                      <td colSpan="6" style={{ textAlign: "center", color: "var(--ink-3)" }}>
                        Ningún ejercicio agregado. Añade ejercicios desde el panel de la derecha.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>

              <div className="modal-foot inline" style={{ marginTop: 16 }}>
                <Btn kind="ghost" type="button" onClick={() => setIsCreatingTemplate(false)}>Cancelar</Btn>
                <Btn kind="primary" type="submit" disabled={loading}>Crear Plantilla</Btn>
              </div>
            </form>
          </Panel>

          <Panel title="Añadir Ejercicio a la Plantilla" sub="Busca e ingresa parámetros">
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              <div className="field">
                <label>Seleccionar Ejercicio</label>
                <select 
                  value={tempExercise.exerciseId} 
                  onChange={e => setTempExercise({ ...tempExercise, exerciseId: e.target.value })}
                >
                  <option value="">-- Elige un ejercicio --</option>
                  {exercises.map(e => (
                    <option key={e.id} value={e.id}>[{e.grupo_muscular}] {e.nombre}</option>
                  ))}
                </select>
              </div>

              <div className="row-2">
                <div className="field">
                  <label>Series</label>
                  <input 
                    type="number" 
                    value={tempExercise.series} 
                    onChange={e => setTempExercise({ ...tempExercise, series: e.target.value })} 
                  />
                </div>
                <div className="field">
                  <label>Repeticiones</label>
                  <input 
                    type="number" 
                    value={tempExercise.repeticiones} 
                    onChange={e => setTempExercise({ ...tempExercise, repeticiones: e.target.value })} 
                  />
                </div>
              </div>

              <div className="row-2">
                <div className="field">
                  <label>Peso Sugerido (kg)</label>
                  <input 
                    type="number" 
                    placeholder="0 = Corporal / RPE"
                    value={tempExercise.pesoSugeridoKg} 
                    onChange={e => setTempExercise({ ...tempExercise, pesoSugeridoKg: e.target.value })} 
                  />
                </div>
                <div className="field">
                  <label>Descanso (segundos)</label>
                  <input 
                    type="number" 
                    value={tempExercise.descansoSeg} 
                    onChange={e => setTempExercise({ ...tempExercise, descansoSeg: e.target.value })} 
                  />
                </div>
              </div>

              <Btn block kind="accent" leading={I.plus} onClick={addExerciseToTemplateDraft}>
                Agregar a la Plantilla
              </Btn>
            </div>
          </Panel>
        </div>
      )}

      {/* TAB 3: BIBLIOTECA DE EJERCICIOS */}
      {tab === "ejercicios" && (
        <div className="grid k-2-1">
          <Panel title="Ejercicios en la Biblioteca" sub="Listado general clasificado por grupo muscular"
                 action={<Btn kind="primary" size="sm" leading={I.plus} onClick={() => setIsCreatingExercise(true)}>Nuevo Ejercicio</Btn>}
                 bodyPad={false}>
            <table className="tbl">
              <thead>
                <tr>
                  <th>Nombre</th>
                  <th>Grupo Muscular</th>
                  <th>Detalles</th>
                </tr>
              </thead>
              <tbody>
                {exercises.map((e) => (
                  <tr key={e.id}>
                    <td>
                      <div className="cell-main">{e.nombre}</div>
                      <div className="cell-sub">{e.descripcion || "Sin descripción adicional."}</div>
                    </td>
                    <td>
                      <Badge kind="default">{e.grupo_muscular}</Badge>
                    </td>
                    <td>
                      {e.animacion_url ? (
                        <a href={e.animacion_url} target="_blank" rel="noreferrer" style={{ fontSize: 12, color: "var(--accent)" }}>
                          Ver Animación
                        </a>
                      ) : "Estático"}
                    </td>
                  </tr>
                ))}
                {exercises.length === 0 && (
                  <tr>
                    <td colSpan="3">
                      <div className="empty">No hay ejercicios registrados en la biblioteca.</div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </Panel>

          {isCreatingExercise ? (
            <Panel title="Nuevo Ejercicio" sub="Ingresa los datos para registrarlo en el catálogo">
              <form onSubmit={handleCreateExercise} style={{ display: "flex", flexDirection: "column", gap: 16 }}>
                <div className="field">
                  <label>Nombre del Ejercicio</label>
                  <input 
                    type="text" 
                    placeholder="Ej: Sentadilla con barra olímpica"
                    value={newExerciseForm.nombre}
                    onChange={e => setNewExerciseForm({ ...newExerciseForm, nombre: e.target.value })}
                    required
                  />
                </div>

                <div className="field">
                  <label>Grupo Muscular</label>
                  <select 
                    value={newExerciseForm.grupoMuscular}
                    onChange={e => setNewExerciseForm({ ...newExerciseForm, grupoMuscular: e.target.value })}
                  >
                    {GRUPOS_MUSCULARES.map(g => (
                      <option key={g} value={g}>{g}</option>
                    ))}
                  </select>
                </div>

                <div className="field">
                  <label>Descripción / Técnica de ejecución</label>
                  <textarea 
                    rows="3" 
                    placeholder="Describe la postura correcta, rango de movimiento y tips de seguridad..."
                    value={newExerciseForm.descripcion}
                    onChange={e => setNewExerciseForm({ ...newExerciseForm, descripcion: e.target.value })}
                  />
                </div>

                <div className="field">
                  <label>URL de Imagen Ilustrativa (Opcional)</label>
                  <input 
                    type="text" 
                    placeholder="https://ejemplo.com/foto.jpg"
                    value={newExerciseForm.imagenUrl}
                    onChange={e => setNewExerciseForm({ ...newExerciseForm, imagenUrl: e.target.value })}
                  />
                </div>

                <div className="field">
                  <label>URL de Animación o GIF (Opcional)</label>
                  <input 
                    type="text" 
                    placeholder="https://ejemplo.com/ejercicio.gif"
                    value={newExerciseForm.animacionUrl}
                    onChange={e => setNewExerciseForm({ ...newExerciseForm, animacionUrl: e.target.value })}
                  />
                </div>

                <div className="modal-foot inline">
                  <Btn kind="ghost" type="button" onClick={() => setIsCreatingExercise(false)}>Cancelar</Btn>
                  <Btn kind="primary" type="submit" disabled={loading}>Guardar Ejercicio</Btn>
                </div>
              </form>
            </Panel>
          ) : (
            <Panel title="Grupos Musculares" sub="Estructura de la biblioteca">
              <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
                {GRUPOS_MUSCULARES.map(g => {
                  const count = exercises.filter(e => e.grupo_muscular === g).length;
                  return (
                    <span className="badge" key={g} style={{ padding: "6px 12px", fontSize: 12 }}>
                      {g} ({count})
                    </span>
                  );
                })}
              </div>
            </Panel>
          )}
        </div>
      )}
    </div>
  );
}

export { Entrenamientos };

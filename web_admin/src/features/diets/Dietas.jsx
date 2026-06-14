function Dietas({ app }) {
  const [diets, setDiets] = React.useState([]);
  const [editingDiet, setEditingDiet] = React.useState(null);
  const [memberQuery, setMemberQuery] = React.useState("");
  const [memberResults, setMemberResults] = React.useState([]);
  const [selectedMember, setSelectedMember] = React.useState(null);
  
  const [targetWeight, setTargetWeight] = React.useState("");
  const [calories, setCalories] = React.useState("");
  const [protein, setProtein] = React.useState("");
  const [carbs, setCarbs] = React.useState("");
  const [fat, setFat] = React.useState("");
  const [suggestions, setSuggestions] = React.useState("");
  const [meals, setMeals] = React.useState([]);

  const [message, setMessage] = React.useState("");
  const [error, setError] = React.useState("");
  const [loading, setLoading] = React.useState(false);

  const [generatorWeight, setGeneratorWeight] = React.useState("70");
  const [generatorHeight, setGeneratorHeight] = React.useState("170");
  const [generatorGoal, setGeneratorGoal] = React.useState("Hipertrofia");

  const refreshDiets = React.useCallback(async () => {
    if (!app?.loadDiets) return;
    try {
      const rows = await app.loadDiets();
      setDiets(rows || []);
    } catch (e) {
      setError(e.message || "No se pudieron cargar las dietas.");
    }
  }, [app]);

  React.useEffect(() => { refreshDiets(); }, []);

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
  }, [memberQuery]);

  const startNewDiet = () => {
    setSelectedMember(null);
    setMemberQuery("");
    setTargetWeight("70");
    setCalories("2400");
    setProtein("140");
    setCarbs("300");
    setFat("70");
    setSuggestions("Asegurar hidratación constante (3L diarios). Evitar alimentos ultraprocesados.");
    setMeals([
      { hora: "08:00", nombre: "Desayuno", alimentos: "3 claras y 1 huevo entero, 60g avena con leche descremada, 1 plátano", calorias: 500 },
      { hora: "13:30", nombre: "Almuerzo", alimentos: "150g pechuga de pollo, 120g arroz cocido, ensalada mixta, 1 cdta aceite de oliva", calorias: 600 },
      { hora: "17:00", nombre: "Merienda", alimentos: "2 tostadas integrales, 50g palta, 1 lata de atún al agua", calorias: 400 },
      { hora: "21:00", nombre: "Cena", alimentos: "150g filete de pescado (panga/lenguado), 150g camote al horno, ensalada verde", calorias: 450 }
    ]);
    setEditingDiet({});
  };

  const handleEdit = (diet) => {
    setSelectedMember(diet.member);
    setTargetWeight(String(diet.peso_objetivo_kg || ""));
    setCalories(String(diet.calorias_objetivo || ""));
    setProtein(String(diet.proteinas_g || ""));
    setCarbs(String(diet.carbohidratos_g || ""));
    setFat(String(diet.grasas_g || ""));
    setSuggestions(diet.sugerencias || "");
    setMeals(diet.comidas || []);
    setEditingDiet(diet);
  };

  const handleAddMeal = () => {
    setMeals([...meals, { hora: "12:00", nombre: "Comida", alimentos: "Alimento y cantidad", calorias: 300 }]);
  };

  const handleRemoveMeal = (idx) => {
    setMeals(meals.filter((_, i) => i !== idx));
  };

  const handleMealChange = (idx, key, val) => {
    setMeals(meals.map((m, i) => i === idx ? { ...m, [key]: key === "calorias" ? Number(val) || 0 : val } : m));
  };

  const generateNutritionTemplate = () => {
    const w = Number(generatorWeight) || 70;
    
    let targetCals = 0;
    let targetProtein = 0;
    let targetCarbs = 0;
    let targetFat = 0;
    let desc = "";
    let mealsTemplate = [];

    if (generatorGoal === "Hipertrofia") {
      targetCals = Math.round(w * 36);
      targetProtein = Math.round(w * 2.0);
      targetFat = Math.round(w * 1.0);
      targetCarbs = Math.round((targetCals - (targetProtein * 4 + targetFat * 9)) / 4);
      desc = "Dieta hipercalórica enfocada en superávit para ganancia de masa muscular. Asegura un balance positivo de nitrógeno.";
      mealsTemplate = [
        { hora: "08:00", nombre: "Desayuno", alimentos: `${Math.round(w * 0.8)}g avena, 3 huevos enteros, 1 vaso jugo de naranja`, calorias: Math.round(targetCals * 0.25) },
        { hora: "11:00", nombre: "Colación", alimentos: `30g almendras, 1 manzana, 1 scoop proteína whey`, calorias: Math.round(targetCals * 0.15) },
        { hora: "13:30", nombre: "Almuerzo", alimentos: `${Math.round(w * 2.5)}g pechuga de pollo, ${Math.round(w * 2.2)}g arroz integral, vegetales`, calorias: Math.round(targetCals * 0.3) },
        { hora: "17:00", nombre: "Merienda", alimentos: `2 tostadas integrales, 60g palta, 100g pechuga de pavo`, calorias: Math.round(targetCals * 0.15) },
        { hora: "21:00", nombre: "Cena", alimentos: `${Math.round(w * 2.2)}g salmón o pescado blanco, ${Math.round(w * 2.0)}g papa cocida, espárragos`, calorias: Math.round(targetCals * 0.15) },
      ];
    } else if (generatorGoal === "Pérdida de peso") {
      targetCals = Math.round(w * 24);
      targetProtein = Math.round(w * 2.2);
      targetFat = Math.round(w * 0.8);
      targetCarbs = Math.round((targetCals - (targetProtein * 4 + targetFat * 9)) / 4);
      desc = "Dieta hipocalórica enfocada en déficit para oxidación de grasa corporal manteniendo masa magra activa.";
      mealsTemplate = [
        { hora: "08:00", nombre: "Desayuno", alimentos: `4 claras y 1 huevo entero revueltos, espinaca, 1 rebanada pan integral`, calorias: Math.round(targetCals * 0.25) },
        { hora: "11:00", nombre: "Colación", alimentos: `150g yogur griego descremado natural, 50g fresas/arándanos`, calorias: Math.round(targetCals * 0.12) },
        { hora: "13:30", nombre: "Almuerzo", alimentos: `${Math.round(w * 2.5)}g pechuga de pollo o lomo de res magro, ensalada abundante verde, 100g quinua`, calorias: Math.round(targetCals * 0.3) },
        { hora: "17:00", nombre: "Merienda", alimentos: `1 manzana verde, 1 scoop proteína de suero aislada`, calorias: Math.round(targetCals * 0.13) },
        { hora: "21:00", nombre: "Cena", alimentos: `${Math.round(w * 2.5)}g pescado blanco a la plancha, brócoli y champiñones salteados`, calorias: Math.round(targetCals * 0.2) },
      ];
    } else { 
      targetCals = Math.round(w * 30);
      targetProtein = Math.round(w * 1.8);
      targetFat = Math.round(w * 0.9);
      targetCarbs = Math.round((targetCals - (targetProtein * 4 + targetFat * 9)) / 4);
      desc = "Plan normocalórico o de recomposición corporal. Proteínas altas para tonificar fibras musculares.";
      mealsTemplate = [
        { hora: "08:00", nombre: "Desayuno", alimentos: `3 claras, 1 huevo entero, 50g avena con leche de almendras y canela`, calorias: Math.round(targetCals * 0.25) },
        { hora: "11:00", nombre: "Colación", alimentos: `1 manzana, 25g almendras o nueces`, calorias: Math.round(targetCals * 0.12) },
        { hora: "13:30", nombre: "Almuerzo", alimentos: `${Math.round(w * 2.2)}g pechuga de pollo o filete de atún, 130g arroz integral, ensalada`, calorias: Math.round(targetCals * 0.3) },
        { hora: "17:00", nombre: "Merienda", alimentos: `1 yogur griego natural, 30g avena, 1 cdta miel`, calorias: Math.round(targetCals * 0.15) },
        { hora: "21:00", nombre: "Cena", alimentos: `${Math.round(w * 2.2)}g pescado blanco, ensalada de espinaca con palta (50g)`, calorias: Math.round(targetCals * 0.18) },
      ];
    }

    setCalories(String(targetCals));
    setProtein(String(targetProtein));
    setCarbs(String(targetCarbs));
    setFat(String(targetFat));
    setSuggestions(desc + "\n\n• Tomar al menos 35ml de agua por kg de peso corporal al día.\n• Realizar el entrenamiento de fuerza de forma intensa para preservar masa muscular.");
    setMeals(mealsTemplate);
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setError("");
    setMessage("");
    if (!selectedMember) {
      setError("Debes seleccionar a un socio destinatario.");
      return;
    }
    if (meals.length === 0) {
      setError("La dieta debe contener al menos una comida.");
      return;
    }

    setLoading(true);
    try {
      const payload = {
        id: editingDiet.id,
        memberId: selectedMember.id,
        pesoObjetivoKg: Number(targetWeight) || null,
        caloriasObjetivo: Number(calories) || null,
        proteinasG: Number(protein) || null,
        carbohidratosG: Number(carbs) || null,
        grasasG: Number(fat) || null,
        comidas: meals,
        sugerencias: suggestions,
      };
      await app.saveDiet(payload);
      setMessage(editingDiet.id ? "Dieta actualizada correctamente." : "Dieta creada y asignada al socio.");
      setEditingDiet(null);
      refreshDiets();
    } catch (e) {
      setError(e.message || "No se pudo guardar la dieta.");
    } finally {
      setLoading(false);
    }
  };

  const handleDeactivate = async (dietId) => {
    if (!confirm("¿Inhabilitar esta dieta? Dejará de mostrarse en el perfil del socio.")) return;
    setError("");
    setMessage("");
    try {
      await app.deactivateDiet(dietId);
      setMessage("Dieta inhabilitada.");
      refreshDiets();
    } catch (e) {
      setError(e.message || "No se pudo inhabilitar la dieta.");
    }
  };

  return (
    <div className="content-wrap">
      <ErrorBlock message={error}/>
      {message && <div className="state-block ok">{message}</div>}

      {editingDiet === null ? (
        <Panel title="Planes de alimentación activos" sub="Gestión de dietas personalizadas"
               action={<Btn kind="primary" size="sm" leading={I.plus} onClick={startNewDiet}>Nueva dieta</Btn>}
               bodyPad={false}>
          <table className="tbl">
            <thead>
              <tr>
                <th>Socio</th>
                <th className="num">Peso Obj.</th>
                <th className="num">Calorías</th>
                <th>Distribución (P/C/F)</th>
                <th>Estado</th>
                <th className="num">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {diets.map((d) => (
                <tr key={d.id} className="clickable">
                  <td>
                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <Avatar name={d.member?.nombre_completo || "Socio"} size={32} />
                      <div>
                        <div className="cell-main">{d.member?.nombre_completo || "Socio"}</div>
                        <div className="cell-sub">DNI {d.member?.dni} · Celular {d.member?.celular || "—"}</div>
                      </div>
                    </div>
                  </td>
                  <td className="num">{d.peso_objetivo_kg ? `${d.peso_objetivo_kg} kg` : "—"}</td>
                  <td className="num" style={{ font: "700 13px var(--font-mono)" }}>{d.calorias_objetivo ? `${d.calorias_objetivo} kcal` : "—"}</td>
                  <td>
                    {d.proteinas_g !== null ? (
                      <div className="cell-sub">
                        Prot: <b>{d.proteinas_g}g</b> · Carb: <b>{d.carbohidratos_g}g</b> · Gras: <b>{d.grasas_g}g</b>
                      </div>
                    ) : "No especificada"}
                  </td>
                  <td>
                    {d.activo ? <Badge kind="ok" dot>Activo</Badge> : <Badge dot>Inactivo</Badge>}
                  </td>
                  <td className="num">
                    <div style={{ display: "inline-flex", gap: 8 }}>
                      <Btn kind="ghost" size="sm" onClick={() => handleEdit(d)}>Editar</Btn>
                      {d.activo && <Btn kind="ghost" size="sm" onClick={() => handleDeactivate(d.id)}>{I.trash}</Btn>}
                    </div>
                  </td>
                </tr>
              ))}
              {diets.length === 0 && (
                <tr>
                  <td colSpan="6">
                    <div className="empty">No hay planes de alimentación registrados en este gimnasio.</div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </Panel>
      ) : (
        <div className="grid k-2-1">
          <Panel title={editingDiet.id ? "Editar Plan de Alimentación" : "Nuevo Plan de Alimentación"}>
            <form onSubmit={handleSave} style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              {!editingDiet.id ? (
                <MemberSearchBox query={memberQuery} setQuery={setMemberQuery} results={memberResults} selected={selectedMember} setSelected={setSelectedMember}/>
              ) : (
                <div className="field">
                  <label>Socio</label>
                  <input value={selectedMember?.nombre_completo || selectedMember?.nombre || ""} disabled />
                </div>
              )}

              <div className="row-2">
                <div className="field">
                  <label>Peso Objetivo (kg)</label>
                  <input type="number" step="0.1" value={targetWeight} onChange={e => setTargetWeight(e.target.value)} placeholder="Ej: 75.5" />
                </div>
                <div className="field">
                  <label>Calorías Objetivo (kcal)</label>
                  <input type="number" value={calories} onChange={e => setCalories(e.target.value)} placeholder="Ej: 2500" />
                </div>
              </div>

              <div className="row-3">
                <div className="field">
                  <label>Proteínas (g)</label>
                  <input type="number" value={protein} onChange={e => setProtein(e.target.value)} placeholder="En gramos" />
                </div>
                <div className="field">
                  <label>Carbohidratos (g)</label>
                  <input type="number" value={carbs} onChange={e => setCarbs(e.target.value)} placeholder="En gramos" />
                </div>
                <div className="field">
                  <label>Grasas (g)</label>
                  <input type="number" value={fat} onChange={e => setFat(e.target.value)} placeholder="En gramos" />
                </div>
              </div>

              <div className="field">
                <label style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <span>Listado de Comidas del Menú Diario</span>
                  <Btn kind="ghost" size="sm" type="button" leading={I.plus} onClick={handleAddMeal}>Agregar comida</Btn>
                </label>
                
                <div style={{ display: "flex", flexDirection: "column", gap: 8, marginTop: 8 }}>
                  {meals.map((meal, idx) => (
                    <div key={idx} className="panel pad" style={{ display: "flex", flexDirection: "column", gap: 8, background: "var(--background)" }}>
                      <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                        <input style={{ width: 80 }} type="text" value={meal.hora} onChange={e => handleMealChange(idx, "hora", e.target.value)} placeholder="08:00" required />
                        <input style={{ flex: 1 }} type="text" value={meal.nombre} onChange={e => handleMealChange(idx, "nombre", e.target.value)} placeholder="Ej: Desayuno" required />
                        <input style={{ width: 100 }} type="number" value={meal.calorias || ""} onChange={e => handleMealChange(idx, "calorias", e.target.value)} placeholder="Kcal" />
                        <Btn kind="ghost" size="sm" type="button" onClick={() => handleRemoveMeal(idx)} style={{ color: "var(--danger)" }}>{I.close}</Btn>
                      </div>
                      <textarea rows="2" value={meal.alimentos} onChange={e => handleMealChange(idx, "alimentos", e.target.value)} placeholder="Describir los alimentos, cantidades o pesos..." required />
                    </div>
                  ))}
                  {meals.length === 0 && <div className="cell-sub" style={{ textAlign: "center", padding: 12 }}>Sin comidas registradas. Agrega filas para definir el menú.</div>}
                </div>
              </div>

              <div className="field">
                <label>Sugerencias y Recomendaciones Generales</label>
                <textarea rows="4" value={suggestions} onChange={e => setSuggestions(e.target.value)} placeholder="Añadir sugerencias sobre hidratación, suplementos, etc." />
              </div>

              <div className="modal-foot inline">
                <Btn kind="ghost" type="button" onClick={() => setEditingDiet(null)}>Cancelar</Btn>
                <Btn kind="primary" type="submit" disabled={loading}>{loading ? "Guardando..." : "Asignar plan"}</Btn>
              </div>
            </form>
          </Panel>

          <Panel title="Generador Inteligente de Dieta" sub="Sugerencias automatizadas según el peso del socio">
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              <div className="field">
                <label>Peso Corporal (kg)</label>
                <input type="number" value={generatorWeight} onChange={e => setGeneratorWeight(e.target.value)} />
              </div>
              <div className="field">
                <label>Altura (cm)</label>
                <input type="number" value={generatorHeight} onChange={e => setGeneratorHeight(e.target.value)} />
              </div>
              <div className="field">
                <label>Objetivo Deportivo</label>
                <select value={generatorGoal} onChange={e => setGeneratorGoal(e.target.value)}>
                  <option value="Hipertrofia">Ganar masa muscular (Hipertrofia)</option>
                  <option value="Pérdida de peso">Oxidación de grasa (Definición)</option>
                  <option value="Tonificación">Tonificar y Recomposición</option>
                </select>
              </div>
              <Btn block kind="accent" leading={I.check} onClick={generateNutritionTemplate}>Estimar Calorías y Cargar Plantilla</Btn>
              
              <div className="divider" />
              <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", lineHeight: 1.4 }}>
                Este generador utiliza estimaciones estandarizadas para el gimnasio:<br />
                • <b>Hipertrofia:</b> ~36 kcal/kg, 2.0g prot/kg, 1.0g grasa/kg.<br />
                • <b>Pérdida de peso:</b> ~24 kcal/kg, 2.2g prot/kg, 0.8g grasa/kg.<br />
                • <b>Tonificación:</b> ~30 kcal/kg, 1.8g prot/kg, 0.9g grasa/kg.<br />
                El botón cargará macros sugeridos y estructurará 5 comidas con porciones de alimentos adaptados al peso.
              </div>
            </div>
          </Panel>
        </div>
      )}
    </div>
  );
}

window.Dietas = Dietas;

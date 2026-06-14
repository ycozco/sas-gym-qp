function Puntos({ app }) {
  const [tab, setTab] = React.useState("catalogo");
  const [config, setConfig] = React.useState({
    activo: true,
    puntos_por_sol: 1.0,
    minimo_para_canje: 100,
    puntos_expiran: false,
    dias_expiracion: 365,
  });

  React.useEffect(() => {
    if (app?.reloadPointsData) {
      app.reloadPointsData();
    }
  }, []);

  React.useEffect(() => {
    if (app?.pointsConfig) {
      setConfig({
        activo: app.pointsConfig.activo ?? true,
        puntos_por_sol: app.pointsConfig.puntos_por_sol ?? 1.0,
        minimo_para_canje: app.pointsConfig.minimo_para_canje ?? 100,
        puntos_expiran: app.pointsConfig.puntos_expiran ?? false,
        dias_expiracion: app.pointsConfig.dias_expiracion ?? 365,
      });
    }
  }, [app?.pointsConfig]);

  const [editingItem, setEditingItem] = React.useState(null);
  const [localCatalog, setLocalCatalog] = React.useState([
    { id: "1", nombre: "Botella de agua 600ml", tipo: "Producto", precio_puntos: 150 },
    { id: "2", nombre: "Proteína Whey (porción)", tipo: "Producto", precio_puntos: 600 },
    { id: "3", nombre: "Pase libre de 1 Día", tipo: "Membresía", precio_puntos: 900 },
    { id: "4", nombre: "Toalla deportiva", tipo: "Producto", precio_puntos: 400 },
    { id: "5", nombre: "10% de Descuento en Renovación", tipo: "Membresía", precio_puntos: 1200 },
  ]);

  const summary = app?.pointsSummary;
  const catalog = app?.pointsCatalog;
  const products = catalog?.products || [];
  const memberships = catalog?.memberships || [];
  const catalogRows = products.length || memberships.length
    ? [
        ...products.map(p => ({ id: p.id, nombre: p.nombre, tipo: "Producto", precio_puntos: p.precio_puntos })),
        ...memberships.map(m => ({ id: m.id, nombre: m.nombre, tipo: "Membresía", precio_puntos: m.precio_puntos })),
      ]
    : localCatalog;

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
  ] : [
    { id: "emi", label: "Puntos emitidos (mes)", value: "12,480", delta: "+8%", dir: "up", icon: "star" },
    { id: "can", label: "Canjes del mes",        value: "37",     delta: "+5",  dir: "up", icon: "check" },
    { id: "usr", label: "Usuarios con puntos",   value: "118",    delta: "450 disponibles", dir: "flat", icon: "users" },
  ];

  const handleSaveConfig = async (e) => {
    e.preventDefault();
    try {
      await app.savePointsConfig({
        activo: config.activo,
        puntosPorSol: Number(config.puntos_por_sol),
        minCanje: Number(config.minimo_para_canje),
        vencimientoDias: config.puntos_expiran ? Number(config.dias_expiracion) : null,
      });
      alert("Configuración de puntos guardada correctamente.");
    } catch (err) {
      alert("Error al guardar la configuración: " + (err.message || err));
    }
  };

  const handleSaveItem = (e) => {
    e.preventDefault();
    if (!editingItem.nombre || !editingItem.precio_puntos) return;
    if (editingItem.id) {
      setLocalCatalog(prev => prev.map(item => item.id === editingItem.id ? editingItem : item));
    } else {
      setLocalCatalog(prev => [...prev, { ...editingItem, id: String(Date.now()) }]);
    }
    setEditingItem(null);
  };

  return (
    <div className="content-wrap">
      <div className="grid cols-3" style={{ marginBottom: 16 }}>
        {kpis.map(k => <Kpi key={k.id} {...k}/>)}
      </div>

      <div className="seg" role="tablist" aria-label="Puntos" style={{ marginBottom: 16 }}>
        <button role="tab" aria-selected={tab === "catalogo"} onClick={() => setTab("catalogo")}>Catálogo</button>
        <button role="tab" aria-selected={tab === "config"} onClick={() => setTab("config")}>Configuración de Canjes</button>
      </div>

      {tab === "catalogo" && (
        <div className="grid k-2-1">
          <Panel title="Catálogo canjeable" sub="productos y membresías por puntos"
                 action={<Btn kind="primary" size="sm" leading={I.plus} onClick={() => setEditingItem({ nombre: "", tipo: "Producto", precio_puntos: 100 })}>Añadir ítem</Btn>}
                 bodyPad={false}>
            <table className="tbl">
              <thead><tr><th>Ítem</th><th>Tipo</th><th className="num">Costo</th><th className="num">Acciones</th></tr></thead>
              <tbody>
                {catalogRows.map((c, i) => (
                  <tr key={c.id || i} className="clickable">
                    <td className="cell-main">{c.nombre}</td>
                    <td><Badge kind={c.tipo === "Membresía" ? "accent" : "info"}>{c.tipo}</Badge></td>
                    <td className="num" style={{ font: "700 13.5px var(--font-mono)" }}>{c.precio_puntos} pts</td>
                    <td className="num">
                      <Btn kind="ghost" size="sm" onClick={() => setEditingItem(c)}>Editar</Btn>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Panel>

          <Panel title="Canjes recientes" bodyPad={false}>
            {exchanges.map((c, i) => (
              <div className="lrow" key={c.id || i}>
                <span className="l-ic" style={{ color: "var(--warn)" }}>{icon("star")}</span>
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
      )}

      {tab === "config" && (
        <Panel title="Configuración del plan de fidelización" sub="Reglas de equivalencia e incentivos">
          <form onSubmit={handleSaveConfig} style={{ display: "flex", flexDirection: "column", gap: 16, maxWidth: 500 }}>
            <label className="check-inline">
              <input type="checkbox" checked={config.activo} onChange={e => setConfig({ ...config, activo: e.target.checked })} />
              Programa de fidelización activo
            </label>
            <div className="field">
              <label>Puntos otorgados por cada Sol gastado (S/ 1.00)</label>
              <input type="number" step="0.1" value={config.puntos_por_sol} onChange={e => setConfig({ ...config, puntos_por_sol: Number(e.target.value) })} />
            </div>
            <div className="field">
              <label>Puntos mínimos requeridos para realizar un canje</label>
              <input type="number" value={config.minimo_para_canje} onChange={e => setConfig({ ...config, minimo_para_canje: Number(e.target.value) })} />
            </div>
            <label className="check-inline">
              <input type="checkbox" checked={config.puntos_expiran} onChange={e => setConfig({ ...config, puntos_expiran: e.target.checked })} />
              Los puntos expiran
            </label>
            {config.puntos_expiran && (
              <div className="field">
                <label>Días de vigencia de los puntos</label>
                <input type="number" value={config.dias_expiracion} onChange={e => setConfig({ ...config, dias_expiracion: Number(e.target.value) })} />
              </div>
            )}
            <Btn type="submit" kind="primary">Guardar Configuración</Btn>
          </form>
        </Panel>
      )}

      {editingItem && (
        <Modal title={editingItem.id ? "Editar Item del Catálogo" : "Nuevo Item del Catálogo"} onClose={() => setEditingItem(null)}>
          <form onSubmit={handleSaveItem}>
            <div className="field">
              <label>Nombre del Item</label>
              <input value={editingItem.nombre} onChange={e => setEditingItem({ ...editingItem, nombre: e.target.value })} required />
            </div>
            <div className="field">
              <label>Tipo de Item</label>
              <select value={editingItem.tipo} onChange={e => setEditingItem({ ...editingItem, tipo: e.target.value })}>
                <option value="Producto">Producto</option>
                <option value="Membresía">Membresía</option>
              </select>
            </div>
            <div className="field">
              <label>Costo en Puntos</label>
              <input type="number" value={editingItem.precio_puntos} onChange={e => setEditingItem({ ...editingItem, precio_puntos: Number(e.target.value) })} required />
            </div>
            <div className="modal-foot inline">
              <Btn type="button" kind="ghost" onClick={() => setEditingItem(null)}>Cancelar</Btn>
              <Btn type="submit" kind="primary">Guardar Item</Btn>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}

window.Puntos = Puntos;

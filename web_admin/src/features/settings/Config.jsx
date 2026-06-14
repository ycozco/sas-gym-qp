function Config({ app }) {
  const tenant = app?.tenantSettings || normalizeTenantSettings(GYM);
  const [form, setForm] = React.useState(() => ({
    name: tenant?.name || "",
    logoUrl: tenant?.logoUrl || "",
    address: tenant?.address || "",
    phone: tenant?.phone || "",
    schedule: tenant?.schedule || "",
    description: tenant?.description || "",
    primaryColor: tenant?.primaryColor || "#111827",
    secondaryColor: tenant?.secondaryColor || "#2F6BFF",
    accentColor: tenant?.accentColor || "#D2FF3A",
    graceDays: tenant?.graceDays ?? 1,
    alertDays: tenant?.alertDays ?? 7,
  }));
  const [saving, setSaving] = React.useState(false);
  const [message, setMessage] = React.useState("");
  const [error, setError] = React.useState("");

  React.useEffect(() => {
    if (!app?.tenantSettings) return;
    setForm({
      name: app.tenantSettings.name || "",
      logoUrl: app.tenantSettings.logoUrl || "",
      address: app.tenantSettings.address || "",
      phone: app.tenantSettings.phone || "",
      schedule: app.tenantSettings.schedule || "",
      description: app.tenantSettings.description || "",
      primaryColor: app.tenantSettings.primaryColor || "#111827",
      secondaryColor: app.tenantSettings.secondaryColor || "#2F6BFF",
      accentColor: app.tenantSettings.accentColor || "#D2FF3A",
      graceDays: app.tenantSettings.graceDays ?? 1,
      alertDays: app.tenantSettings.alertDays ?? 7,
    });
  }, [app?.tenantSettings?.id]);

  const setField = (key, value) => setForm((prev) => ({ ...prev, [key]: value }));
  const save = async () => {
    setSaving(true);
    setError("");
    setMessage("");
    try {
      await app.saveTenantSettings({
        nombre: form.name,
        logoUrl: form.logoUrl,
        direccion: form.address,
        telefono: form.phone,
        horario: form.schedule,
        descripcion: form.description,
        colorPrimario: form.primaryColor,
        colorSecundario: form.secondaryColor,
        colorAcento: form.accentColor,
        diasGracia: Number(form.graceDays),
        diasAlertaVencimiento: Number(form.alertDays),
      });
      setMessage("Configuración guardada correctamente.");
    } catch (e) {
      setError(e.message || "No se pudo guardar la configuración.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="content-wrap">
      <ErrorBlock message={error}/>
      {message && <div className="state-block ok">{message}</div>}
      <div className="grid cols-2">
        <Panel title="Datos del gimnasio">
          <div className="field"><label>Nombre comercial</label><input value={form.name} onChange={(e) => setField("name", e.target.value)}/></div>
          <div className="field"><label>Logo URL</label><input value={form.logoUrl} onChange={(e) => setField("logoUrl", e.target.value)}/></div>
          <div className="row-2">
            <div className="field"><label>Días de gracia</label><input type="number" min="0" value={form.graceDays} onChange={(e) => setField("graceDays", e.target.value)}/></div>
            <div className="field"><label>Teléfono / WhatsApp</label><input value={form.phone} onChange={(e) => setField("phone", e.target.value)}/></div>
          </div>
          <div className="field"><label>Dirección</label><input value={form.address} onChange={(e) => setField("address", e.target.value)}/></div>
          <div className="field"><label>Horario de atención</label><input value={form.schedule} onChange={(e) => setField("schedule", e.target.value)}/></div>
          <div className="field"><label>Descripción</label><textarea rows="3" value={form.description} onChange={(e) => setField("description", e.target.value)}/></div>
        </Panel>

        <div className="grid" style={{ gap: 16, alignContent: "start" }}>
          <Panel title="Reglas operativas">
            <div className="row-2">
              <div className="field"><label>Día de gracia</label><input type="number" min="0" value={form.graceDays} onChange={(e) => setField("graceDays", e.target.value)}/></div>
              <div className="field"><label>Aviso pre-vencimiento</label><input type="number" min="1" value={form.alertDays} onChange={(e) => setField("alertDays", e.target.value)}/></div>
            </div>
            <div className="field" style={{ marginBottom: 0 }}>
              <label>Recordatorio post-vencimiento</label>
              <select defaultValue="Diario"><option>Diario</option><option>Cada 2 días</option></select>
            </div>
          </Panel>
          <Panel title="Identidad">
            <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
              <span style={{ width: 64, height: 64, borderRadius: 14, background: form.primaryColor || "var(--ink)", color: form.accentColor || "var(--accent)", display: "grid", placeItems: "center", font: "800 24px var(--font-display)" }}>{(form.name || "G")[0]}</span>
              <div style={{ flex: 1 }}>
                <div className="row-2">
                  <div className="field"><label>Primario</label><input type="color" value={form.primaryColor} onChange={(e) => setField("primaryColor", e.target.value)}/></div>
                  <div className="field"><label>Secundario</label><input type="color" value={form.secondaryColor} onChange={(e) => setField("secondaryColor", e.target.value)}/></div>
                </div>
                <div className="field" style={{ marginBottom: 0 }}><label>Acento</label><input type="color" value={form.accentColor} onChange={(e) => setField("accentColor", e.target.value)}/></div>
              </div>
            </div>
          </Panel>
        </div>
      </div>
      <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 16 }}>
        <Btn kind="primary" leading={I.check} disabled={saving} onClick={save}>{saving ? "Guardando..." : "Guardar cambios"}</Btn>
      </div>
    </div>
  );
}

window.Config = Config;

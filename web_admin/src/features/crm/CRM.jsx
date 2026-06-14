function CRM({ app }) {
  const CANAL = { Email: "info", WhatsApp: "ok", Push: "accent" };
  const EST = { Activa: "ok", Programada: "warn", Finalizada: "" };
  const announcements = app?.announcements || [];
  const observations = app?.observations || [];
  const campaignRows = announcements.length ? announcements.map(a => ({
    id: a.id,
    n: a.titulo || "Anuncio",
    canal: "Push",
    estado: a.activo === false ? "Finalizada" : "Activa",
    alcance: "Tenant",
  })) : CAMPAIGNS;
  const contactRows = observations.length ? observations.map(o => ({
    id: o.id,
    n: o.texto || "Observacion",
    origen: o.autor_rol || "Sistema",
    estado: o.foto_url ? "Con evidencia" : "Nuevo",
  })) : CRM_CONTACTS;
  return (
    <div className="content-wrap">
      <div className="grid cols-3">
        {CRM_KPIS.map(k => <Kpi key={k.id} {...k}/>)}
      </div>

      {(announcements.length > 0 || observations.length > 0) && (
        <>
          <Panel title="Anuncios y campanas" sub="anuncios reales del tenant"
                 action={<Btn kind="primary" size="sm" leading={I.plus}>Nueva campana</Btn>}
                 bodyPad={false}>
            <table className="tbl">
              <thead><tr><th>Mensaje</th><th>Canal</th><th>Estado</th><th className="num">Alcance</th></tr></thead>
              <tbody>
                {campaignRows.map((c, i) => (
                  <tr key={c.id || i} className="clickable">
                    <td className="cell-main">{c.n}</td>
                    <td><Badge kind={CANAL[c.canal]}>{c.canal}</Badge></td>
                    <td><Badge kind={EST[c.estado]} dot>{c.estado}</Badge></td>
                    <td className="num">{c.alcance}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Panel>

          <Panel title="Observaciones e incidencias" sub="reportes reales del tenant" bodyPad={false}>
            {contactRows.map((c, i) => (
              <div className="lrow" key={c.id || i}>
                <Avatar name={c.n} size={34}/>
                <div className="l-main">
                  <div className="l-t">{c.n}</div>
                  <div className="l-s">Origen: {c.origen}</div>
                </div>
                <Badge kind={c.estado === "Nuevo" ? "info" : "warn"} dot>{c.estado}</Badge>
              </div>
            ))}
          </Panel>
        </>
      )}

      <Panel title="Campañas" sub="email · WhatsApp · push"
             action={<Btn kind="primary" size="sm" leading={I.plus}>Nueva campaña</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Campaña</th><th>Canal</th><th>Estado</th><th className="num">Alcance</th></tr></thead>
          <tbody>
            {CAMPAIGNS.map((c, i) => (
              <tr key={i} className="clickable">
                <td className="cell-main">{c.n}</td>
                <td><Badge kind={CANAL[c.canal]}>{c.canal}</Badge></td>
                <td><Badge kind={EST[c.estado]} dot>{c.estado}</Badge></td>
                <td className="num">{c.alcance} personas</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>

      <Panel title="Contactos y leads" sub="prospectos sin membresía" bodyPad={false}>
        {CRM_CONTACTS.map((c, i) => (
          <div className="lrow" key={i}>
            <Avatar name={c.n} size={34}/>
            <div className="l-main">
              <div className="l-t">{c.n}</div>
              <div className="l-s">Origen: {c.origen}</div>
            </div>
            <Badge kind={c.estado === "Nuevo" ? "info" : "warn"} dot>{c.estado}</Badge>
          </div>
        ))}
      </Panel>
    </div>
  );
}

window.CRM = CRM;

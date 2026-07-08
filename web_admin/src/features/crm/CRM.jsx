import React from 'react';
import { CAMPAIGNS, CRM_CONTACTS, CRM_KPIS } from '../../../data.jsx';
import { Avatar, Badge, Btn, I, Kpi, Modal, Panel } from '../../../shared.jsx';

function CRM({ app }) {
  const CANAL = { Email: "info", WhatsApp: "ok", Push: "accent" };
  const EST = { Activa: "ok", Programada: "warn", Finalizada: "" };

  const [editingLead, setEditingLead] = React.useState(null);
  const [editingCampaign, setEditingCampaign] = React.useState(null);

  React.useEffect(() => {
    if (app?.loadCrmData) {
      app.loadCrmData().catch(() => null);
    }
  }, [app]);

  const leads = app?.leads || [];
  const campaigns = app?.campaigns || [];
  const announcements = app?.announcements || [];
  const observations = app?.observations || [];

  const campaignRows = campaigns.length ? campaigns.map(c => ({
    id: c.id,
    n: c.nombre,
    canal: c.canal,
    estado: c.estado,
    alcance: `${c.alcance} personas`,
  })) : CAMPAIGNS;

  const contactRows = leads.length ? leads.map(l => ({
    id: l.id,
    n: l.nombre,
    email: l.email || "",
    celular: l.celular || "",
    origen: l.origen,
    estado: l.estado,
    notas: l.notas || "",
  })) : CRM_CONTACTS;

  const handleSaveLead = async (e) => {
    e.preventDefault();
    if (!editingLead.nombre) return;
    try {
      await app.saveLead({
        id: editingLead.id,
        nombre: editingLead.nombre,
        email: editingLead.email || "",
        celular: editingLead.celular || "",
        origen: editingLead.origen || "Recomendado",
        estado: editingLead.estado || "Nuevo",
        notas: editingLead.notas || "",
      });
      setEditingLead(null);
    } catch (err) {
      alert("Error al guardar lead: " + (err.message || err));
    }
  };

  const handleDeleteLead = async (id, name) => {
    if (!confirm(`¿Estás seguro de inhabilitar/eliminar al lead "${name}"?`)) return;
    try {
      await app.deleteLead(id);
    } catch (err) {
      alert("Error al eliminar lead: " + (err.message || err));
    }
  };

  const handleSaveCampaign = async (e) => {
    e.preventDefault();
    if (!editingCampaign.nombre) return;
    try {
      await app.saveCampaign({
        nombre: editingCampaign.nombre,
        descripcion: editingCampaign.descripcion || "",
        canal: editingCampaign.canal || "Push",
      });
      setEditingCampaign(null);
    } catch (err) {
      alert("Error al guardar campaña: " + (err.message || err));
    }
  };

  const handleSendCampaign = async (id) => {
    try {
      await app.sendCampaign(id);
      alert("Campaña enviada con éxito. Se calculó el alcance correspondiente.");
    } catch (err) {
      alert("Error al enviar campaña: " + (err.message || err));
    }
  };

  // KPIs dinámicos si hay datos reales
  const dynamicKpis = app?.leads ? [
    { id: "tot", label: "Total Prospectos", value: leads.length, delta: "Reales", dir: "up" },
    { id: "cam", label: "Campañas Creadas", value: campaigns.length, delta: "Enviadas/Programadas", dir: "flat" },
    { id: "obs", label: "Anuncios Activos", value: announcements.length, delta: "Visibles en app", dir: "up" },
  ] : CRM_KPIS;

  return (
    <div className="content-wrap">
      <div className="grid cols-3" style={{ marginBottom: 16 }}>
        {dynamicKpis.map(k => <Kpi key={k.id} {...k} />)}
      </div>

      <div className="grid k-2-1" style={{ marginBottom: 16 }}>
        <Panel title="Campañas del Gym" sub="email · WhatsApp · push"
               action={<Btn kind="primary" size="sm" leading={I.plus} onClick={() => setEditingCampaign({ nombre: "", descripcion: "", canal: "Push" })}>Nueva campaña</Btn>}
               bodyPad={false}>
          <table className="tbl">
            <thead>
              <tr>
                <th>Campaña</th>
                <th>Canal</th>
                <th>Estado</th>
                <th className="num">Alcance</th>
                <th className="num">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {campaignRows.map((c, i) => (
                <tr key={c.id || i} className="clickable">
                  <td className="cell-main">{c.n}</td>
                  <td><Badge kind={CANAL[c.canal] || "info"}>{c.canal}</Badge></td>
                  <td><Badge kind={EST[c.estado] || "info"} dot>{c.estado}</Badge></td>
                  <td className="num">{c.alcance}</td>
                  <td className="num">
                    {c.estado === "Programada" && c.id && (
                      <Btn kind="primary" size="xs" onClick={() => handleSendCampaign(c.id)}>Enviar</Btn>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Panel>

        <Panel title="Observaciones de Socios" sub="reportes reales de entrenadores" bodyPad={false}>
          {observations.length ? observations.map((o, i) => (
            <div className="lrow" key={o.id || i}>
              <span className="l-ic" style={{ color: "var(--warn)" }}>{I.calendar}</span>
              <div className="l-main">
                <div className="l-t">{o.texto}</div>
                <div className="l-s">Autor: {o.autor_rol}</div>
              </div>
              <Badge kind={o.revisado ? "ok" : "warn"}>{o.revisado ? "Revisado" : "Pendiente"}</Badge>
            </div>
          )) : (
            <div className="empty" style={{ padding: 16 }}>No hay incidencias u observaciones registradas.</div>
          )}
        </Panel>
      </div>

      <Panel title="Contactos y leads" sub="prospectos registrados sin membresía activa"
             action={<Btn kind="primary" size="sm" leading={I.plus} onClick={() => setEditingLead({ nombre: "", email: "", celular: "", origen: "Recomendado", estado: "Nuevo", notas: "" })}>Nuevo lead</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead>
            <tr>
              <th>Lead / Prospecto</th>
              <th>Contacto</th>
              <th>Origen</th>
              <th>Estado</th>
              <th className="num">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {contactRows.map((c, i) => (
              <tr key={c.id || i} className="clickable">
                <td>
                  <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                    <Avatar name={c.n} size={30} />
                    <div>
                      <div className="cell-main">{c.n}</div>
                      <div style={{ fontSize: 11, color: "var(--ink-3)" }}>{c.notas}</div>
                    </div>
                  </div>
                </td>
                <td style={{ fontSize: 12, color: "var(--ink-2)", font: "var(--font-mono)" }}>
                  <div>{c.email}</div>
                  <div>{c.celular}</div>
                </td>
                <td><Badge kind="info">{c.origen}</Badge></td>
                <td>
                  <Badge kind={c.estado === "Nuevo" ? "info" : c.estado === "Contactado" ? "warn" : c.estado === "Interesado" ? "accent" : c.estado === "Cerrado" ? "ok" : ""} dot>{c.estado}</Badge>
                </td>
                <td className="num">
                  <div style={{ display: "inline-flex", gap: 8 }}>
                    <Btn kind="ghost" size="sm" onClick={() => setEditingLead(c)}>Editar</Btn>
                    {c.id && (
                      <Btn kind="ghost" size="sm" onClick={() => handleDeleteLead(c.id, c.n)} style={{ color: "var(--danger)" }}>{I.trash}</Btn>
                    )}
                  </div>
                </td>
              </tr>
            ))}
            {contactRows.length === 0 && (
              <tr>
                <td colSpan="5">
                  <div className="empty">La lista de leads está vacía. ¡Agrega un prospecto!</div>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Panel>

      {editingLead && (
        <Modal title={editingLead.id ? "Editar Lead" : "Nuevo Lead / Prospecto"} onClose={() => setEditingLead(null)}>
          <form onSubmit={handleSaveLead} style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            <div className="field">
              <label>Nombre Completo</label>
              <input value={editingLead.nombre || ""} onChange={e => setEditingLead({ ...editingLead, nombre: e.target.value })} required />
            </div>
            <div className="row-2">
              <div className="field">
                <label>Email</label>
                <input type="email" value={editingLead.email || ""} onChange={e => setEditingLead({ ...editingLead, email: e.target.value })} />
              </div>
              <div className="field">
                <label>Celular</label>
                <input value={editingLead.celular || ""} onChange={e => setEditingLead({ ...editingLead, celular: e.target.value })} />
              </div>
            </div>
            <div className="row-2">
              <div className="field">
                <label>Origen del Contacto</label>
                <select value={editingLead.origen || "Recomendado"} onChange={e => setEditingLead({ ...editingLead, origen: e.target.value })}>
                  <option value="Web">Web</option>
                  <option value="Facebook">Facebook</option>
                  <option value="Instagram">Instagram</option>
                  <option value="Recomendado">Recomendado</option>
                  <option value="Directo">Directo (Visita)</option>
                </select>
              </div>
              <div className="field">
                <label>Estado</label>
                <select value={editingLead.estado || "Nuevo"} onChange={e => setEditingLead({ ...editingLead, estado: e.target.value })}>
                  <option value="Nuevo">Nuevo</option>
                  <option value="Contactado">Contactado</option>
                  <option value="Interesado">Interesado</option>
                  <option value="Cerrado">Cerrado (Membresía Vendida)</option>
                  <option value="Descartado">Descartado</option>
                </select>
              </div>
            </div>
            <div className="field">
              <label>Notas / Intereses</label>
              <textarea rows="2" value={editingLead.notas || ""} onChange={e => setEditingLead({ ...editingLead, notas: e.target.value })} />
            </div>
            <div className="modal-foot inline" style={{ marginTop: 8 }}>
              <Btn type="button" kind="ghost" onClick={() => setEditingLead(null)}>Cancelar</Btn>
              <Btn type="submit" kind="primary">Guardar Lead</Btn>
            </div>
          </form>
        </Modal>
      )}

      {editingCampaign && (
        <Modal title="Nueva Campaña Masiva" onClose={() => setEditingCampaign(null)}>
          <form onSubmit={handleSaveCampaign} style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            <div className="field">
              <label>Nombre de la Campaña</label>
              <input value={editingCampaign.nombre || ""} onChange={e => setEditingCampaign({ ...editingCampaign, nombre: e.target.value })} required />
            </div>
            <div className="field">
              <label>Descripción / Mensaje</label>
              <textarea rows="3" value={editingCampaign.descripcion || ""} onChange={e => setEditingCampaign({ ...editingCampaign, descripcion: e.target.value })} />
            </div>
            <div className="field">
              <label>Canal de Envío</label>
              <select value={editingCampaign.canal || "Push"} onChange={e => setEditingCampaign({ ...editingCampaign, canal: e.target.value })}>
                <option value="Email">Correo Electrónico (Email)</option>
                <option value="WhatsApp">Mensaje WhatsApp</option>
                <option value="Push">Notificación Móvil Push</option>
              </select>
            </div>
            <div className="modal-foot inline" style={{ marginTop: 8 }}>
              <Btn type="button" kind="ghost" onClick={() => setEditingCampaign(null)}>Cancelar</Btn>
              <Btn type="submit" kind="primary">Guardar Campaña</Btn>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}

export { CRM };

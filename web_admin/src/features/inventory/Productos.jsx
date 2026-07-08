import React from 'react';
import { PRODUCTS } from '../../../data.jsx';
import { Badge, Btn, ErrorBlock, I, Kpi, Modal, Panel, normalizeProduct } from '../../../shared.jsx';

function Productos({ app }) {
  const [editing, setEditing] = React.useState(null);
  const [message, setMessage] = React.useState("");
  const [error, setError] = React.useState("");
  const rows = app?.products?.length
    ? app.products
    : PRODUCTS.map(p => normalizeProduct({ id: p.id, nombre: p.n, categoria: p.cat, precio_venta: p.p, stock_actual: p.stock }));
  const low = rows.filter(p => p.stock < 15).length;
  const valor = rows.reduce((s, p) => s + p.price * p.stock, 0);
  const save = async (form) => {
    setError(""); setMessage("");
    try {
      await app.saveProduct(form);
      setEditing(null);
      setMessage("Producto guardado.");
    } catch (e) {
      setError(e.message || "No se pudo guardar el producto.");
    }
  };
  const deactivate = async (id) => {
    setError(""); setMessage("");
    try {
      await app.deactivateProduct(id);
      setMessage("Producto desactivado.");
    } catch (e) {
      setError(e.message || "No se pudo desactivar el producto.");
    }
  };
  return (
    <div className="content-wrap">
      <ErrorBlock message={error}/>
      {message && <div className="state-block ok">{message}</div>}
      <div className="grid cols-3">
        <Kpi icon="box" value={rows.filter(p => p.visible && p.status !== "inactivo").length} label="Productos activos" delta="catálogo real" dir="up"/>
        <Kpi icon="cash" value={`S/ ${valor.toLocaleString()}`} label="Valor del inventario" delta="" dir="flat"/>
        <Kpi icon="alert" value={low} label="Con bajo stock" delta="reponer pronto" dir="down"/>
      </div>

      <Panel title="Inventario" sub="catálogo de venta"
             action={<Btn kind="primary" size="sm" leading={I.plus} onClick={() => setEditing({})}>Nuevo producto</Btn>}
             bodyPad={false}>
        <table className="tbl">
          <thead><tr><th>Producto</th><th>Categoría</th><th className="num">Precio</th><th className="num">Stock</th><th></th></tr></thead>
          <tbody>
            {rows.map(p => (
              <tr key={p.id} className="clickable" onClick={() => setEditing(p)}>
                <td><div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span style={{ width: 38, height: 38, borderRadius: 10, background: "var(--surface-2)", display: "grid", placeItems: "center", fontSize: 19 }}>{I.box}</span>
                  <span><span className="cell-main">{p.name}</span><span className="cell-sub">{p.sku || "Sin SKU"}</span></span>
                </div></td>
                <td style={{ color: "var(--ink-2)" }}>{p.category || "General"}</td>
                <td className="num" style={{ font: "700 14px var(--font-display)" }}>S/ {p.price}</td>
                <td className="num">{p.stock}</td>
                <td style={{ textAlign: "right" }}>
                  <div style={{ display: "inline-flex", gap: 8, alignItems: "center" }}>
                    {p.stock < 15 ? <Badge kind="warn" dot>Bajo stock</Badge> : <Badge kind="ok" dot>OK</Badge>}
                    <Btn kind="ghost" size="sm" onClick={(e) => { e.stopPropagation(); setEditing(p); }}>Editar</Btn>
                    {p.id && <Btn kind="danger-soft" size="sm" onClick={(e) => { e.stopPropagation(); deactivate(p.id); }}>Baja</Btn>}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Panel>
      {editing !== null && <Modal title={editing.id ? "Editar producto" : "Nuevo producto"} onClose={() => setEditing(null)}>
        <ProductForm product={editing.id ? editing : null} onSave={save} onCancel={() => setEditing(null)}/>
      </Modal>}
    </div>
  );
}

function ProductForm({ product, onSave, onCancel }) {
  const [form, setForm] = React.useState(() => ({
    id: product?.id || "",
    name: product?.name || "",
    description: product?.description || "",
    category: product?.category || "General",
    sku: product?.sku || "",
    price: product?.price || 0,
    cost: product?.cost || 0,
    stock: product?.stock || 0,
    minStock: product?.minStock || 5,
    imageUrl: product?.imageUrl || "",
    status: product?.status || "activo",
    visible: product?.visible ?? true,
  }));
  const setField = (k, v) => setForm(prev => ({ ...prev, [k]: v }));
  const submit = (e) => {
    e.preventDefault();
    onSave(form);
  };
  return (
    <form onSubmit={submit}>
      <div className="row-2">
        <div className="field"><label>Nombre</label><input value={form.name} onChange={e => setField("name", e.target.value)} required/></div>
        <div className="field"><label>SKU</label><input value={form.sku} onChange={e => setField("sku", e.target.value)}/></div>
      </div>
      <div className="field"><label>Descripcion</label><textarea rows="2" value={form.description} onChange={e => setField("description", e.target.value)}/></div>
      <div className="row-2">
        <div className="field"><label>Categoria</label><input value={form.category} onChange={e => setField("category", e.target.value)}/></div>
        <div className="field"><label>Estado</label><select value={form.status} onChange={e => setField("status", e.target.value)}><option value="activo">Activo</option><option value="inactivo">Inactivo</option></select></div>
      </div>
      <div className="row-2">
        <div className="field"><label>Precio venta</label><input type="number" step="0.01" value={form.price} onChange={e => setField("price", e.target.value)} required/></div>
        <div className="field"><label>Precio compra</label><input type="number" step="0.01" value={form.cost} onChange={e => setField("cost", e.target.value)}/></div>
      </div>
      <div className="row-2">
        <div className="field"><label>Stock</label><input type="number" value={form.stock} onChange={e => setField("stock", e.target.value)}/></div>
        <div className="field"><label>Stock minimo</label><input type="number" value={form.minStock} onChange={e => setField("minStock", e.target.value)}/></div>
      </div>
      <label className="check-inline"><input type="checkbox" checked={form.visible} onChange={e => setField("visible", e.target.checked)}/> Visible en POS</label>
      <div className="modal-foot inline">
        <Btn kind="ghost" type="button" onClick={onCancel}>Cancelar</Btn>
        <Btn kind="primary" type="submit">Guardar</Btn>
      </div>
    </form>
  );
}

export { Productos };

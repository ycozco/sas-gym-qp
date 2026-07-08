import React from 'react';
import { FIN_KPIS, FIN_MOV } from '../../../data.jsx';
import { Badge, Btn, I, Kpi, Modal, Panel, icon } from '../../../shared.jsx';

function Finanzas({ app }) {
  const TIPO = { Sueldo: "info", Servicio: "warn", Gasto: "danger", Ingreso: "ok", Mantenimiento: "danger", Publicidad: "accent" };

  const [trainers, setTrainers] = React.useState([]);
  const [expenseModal, setExpenseModal] = React.useState(null);
  const [payrollModal, setPayrollModal] = React.useState(false);
  const [newPayroll, setNewPayroll] = React.useState({ trainer_id: "", monto_sueldo: 1500, mes: new Date().getMonth() + 1, anio: new Date().getFullYear() });

  React.useEffect(() => {
    if (app?.loadFinancesData) {
      app.loadFinancesData().catch(() => null);
    }
    if (app?.loadTrainers) {
      app.loadTrainers().then(data => setTrainers(data || [])).catch(() => null);
    }
  }, [app]);

  const summary = app?.financesSummary;
  const expenses = app?.expenses || [];
  const payroll = app?.payroll || [];

  const dynamicKpis = summary ? [
    { id: "ing", label: "Ingresos Totales", value: `S/ ${summary.totalIncome.toLocaleString()}`, delta: `S/ ${summary.totalMembershipIncome.toLocaleString()} membresías`, dir: "up" },
    { id: "egr", label: "Egresos del Mes", value: `S/ ${summary.totalExpenses.toLocaleString()}`, delta: `${summary.expensesCount} transacciones`, dir: "down" },
    { id: "net", label: "Balance Neto", value: `S/ ${summary.netBalance.toLocaleString()}`, delta: "Flujo consolidado", dir: summary.netBalance >= 0 ? "up" : "down" },
  ] : FIN_KPIS;

  const rows = expenses.length ? expenses.map(e => ({
    id: e.id,
    d: e.fecha ? new Date(e.fecha).toLocaleDateString() : "Reciente",
    concepto: e.descripcion,
    tipo: e.categoria,
    m: e.monto,
    dir: "egreso",
    metodo: e.metodo_pago,
  })) : FIN_MOV;

  const handleSaveExpense = async (e) => {
    e.preventDefault();
    if (!expenseModal.monto || !expenseModal.descripcion) return;
    try {
      await app.saveExpense({
        monto: Number(expenseModal.monto),
        categoria: expenseModal.categoria || "Gasto",
        descripcion: expenseModal.descripcion,
        metodo_pago: expenseModal.metodo_pago || "efectivo",
        fecha: expenseModal.fecha || undefined,
      });
      setExpenseModal(null);
    } catch (err) {
      alert("Error al guardar gasto: " + (err.message || err));
    }
  };

  const handleSavePayroll = async (e) => {
    e.preventDefault();
    if (!newPayroll.trainer_id || !newPayroll.monto_sueldo) return;
    try {
      await app.savePayroll({
        trainer_id: newPayroll.trainer_id,
        monto_sueldo: Number(newPayroll.monto_sueldo),
        mes: Number(newPayroll.mes),
        anio: Number(newPayroll.anio),
      });
      alert("Planilla generada correctamente.");
    } catch (err) {
      alert("Error al generar planilla: " + (err.message || err));
    }
  };

  const handlePayPayroll = async (id) => {
    if (!confirm("¿Confirmar el pago de sueldo de esta planilla? Se debitará del flujo de caja.")) return;
    try {
      await app.payPayroll(id);
      alert("Pago registrado con éxito.");
    } catch (err) {
      alert("Error al registrar pago: " + (err.message || err));
    }
  };

  const handleExportCSV = () => {
    let csvContent = "\uFEFF"; // Byte Order Mark for Excel
    csvContent += "Fecha,Concepto,Categoria,Monto,Metodo Pago\n";
    expenses.forEach(e => {
      const date = new Date(e.fecha).toLocaleDateString();
      csvContent += `"${date}","${e.descripcion}","${e.categoria}",-${e.monto},"${e.metodo_pago}"\n`;
    });
    
    // Add product sales details if any
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `reporte_financiero_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="content-wrap">
      <div className="grid cols-3" style={{ marginBottom: 16 }}>
        {dynamicKpis.map(k => <Kpi key={k.id} {...k} />)}
      </div>

      <div className="grid k-2-1" style={{ marginBottom: 16 }}>
        <Panel title="Egresos y Transacciones del Mes" sub="servicios · planillas · insumos"
               action={<div style={{ display: "flex", gap: 8 }}>
                 <Btn kind="ghost" size="sm" leading={I.plus} onClick={() => setPayrollModal(true)}>Sueldos/Planilla</Btn>
                 <Btn kind="primary" size="sm" leading={I.plus} onClick={() => setExpenseModal({ monto: "", categoria: "Gasto", descripcion: "", metodo_pago: "efectivo", fecha: new Date().toISOString().slice(0, 10) })}>Registrar Gasto</Btn>
               </div>}
               bodyPad={false}>
          <table className="tbl">
            <thead>
              <tr>
                <th>Fecha</th>
                <th>Concepto</th>
                <th>Categoría</th>
                <th>Método</th>
                <th className="num">Monto</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((m, i) => (
                <tr key={m.id || i}>
                  <td style={{ font: "600 13px var(--font-mono)" }}>{m.d}</td>
                  <td className="cell-main">{m.concepto}</td>
                  <td><Badge kind={TIPO[m.tipo] || "info"}>{m.tipo}</Badge></td>
                  <td style={{ fontSize: 11, textTransform: "capitalize", color: "var(--ink-3)" }}>{m.metodo}</td>
                  <td className="num" style={{ font: "700 14px var(--font-display)", color: m.dir === "egreso" ? "var(--danger)" : "var(--success)" }}>
                    {m.dir === "egreso" ? "−" : "+"}S/ {m.m.toLocaleString()}
                  </td>
                </tr>
              ))}
              {rows.length === 0 && (
                <tr>
                  <td colSpan="5">
                    <div className="empty">No hay transacciones registradas este mes.</div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </Panel>

        <Panel title="Gestión Financiera" bodyPad={false}>
          <div className="lrow clickable" onClick={handleExportCSV}>
            <span className="l-ic" style={{ color: "var(--success)" }}>{icon("wallet")}</span>
            <div className="l-main">
              <div className="l-t">Exportar Reporte Mensual</div>
              <div className="l-s">Descarga todas las transacciones en formato CSV/Excel</div>
            </div>
            <span>{I.forward}</span>
          </div>

          <div style={{ padding: "12px 16px", font: "500 12px var(--font-body)", color: "var(--ink-3)", borderTop: "1px solid var(--border)" }}>
            El balance neto calcula los ingresos consolidados por venta de membresías y productos restándoles los egresos manuales y las planillas pagadas.
          </div>
        </Panel>
      </div>

      {expenseModal && (
        <Modal title="Registrar Gasto Operativo" onClose={() => setExpenseModal(null)}>
          <form onSubmit={handleSaveExpense} style={{ display: "flex", flexDirection: "column", gap: 14 }}>
            <div className="field">
              <label>Monto (S/.)</label>
              <input type="number" step="0.01" value={expenseModal.monto || ""} onChange={e => setExpenseModal({ ...expenseModal, monto: e.target.value })} required />
            </div>
            <div className="field">
              <label>Concepto / Descripción</label>
              <input value={expenseModal.descripcion || ""} onChange={e => setExpenseModal({ ...expenseModal, descripcion: e.target.value })} required />
            </div>
            <div className="row-2">
              <div className="field">
                <label>Categoría</label>
                <select value={expenseModal.categoria || "Gasto"} onChange={e => setExpenseModal({ ...expenseModal, categoria: e.target.value })}>
                  <option value="Servicio">Servicio Fijo (Luz/Agua/Alquiler)</option>
                  <option value="Mantenimiento">Mantenimiento de Máquinas</option>
                  <option value="Publicidad">Publicidad y Marketing</option>
                  <option value="Gasto">Gasto General / Caja Chica</option>
                </select>
              </div>
              <div className="field">
                <label>Método de Pago</label>
                <select value={expenseModal.metodo_pago || "efectivo"} onChange={e => setExpenseModal({ ...expenseModal, metodo_pago: e.target.value })}>
                  <option value="efectivo">Efectivo</option>
                  <option value="transferencia">Transferencia Bancaria</option>
                  <option value="yape">Yape / Plin</option>
                  <option value="pos">Tarjeta (POS)</option>
                </select>
              </div>
            </div>
            <div className="field">
              <label>Fecha de Gasto</label>
              <input type="date" value={expenseModal.fecha || ""} onChange={e => setExpenseModal({ ...expenseModal, fecha: e.target.value })} required />
            </div>
            <div className="modal-foot inline" style={{ marginTop: 8 }}>
              <Btn type="button" kind="ghost" onClick={() => setExpenseModal(null)}>Cancelar</Btn>
              <Btn type="submit" kind="primary">Registrar Gasto</Btn>
            </div>
          </form>
        </Modal>
      )}

      {payrollModal && (
        <Modal title="Planilla y Sueldos de Entrenadores" onClose={() => setPayrollModal(false)}>
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            <form onSubmit={handleSavePayroll} style={{ background: "var(--bg-card)", padding: 14, borderRadius: 8, display: "flex", flexDirection: "column", gap: 10 }}>
              <div style={{ fontWeight: 700, fontSize: 13 }}>Generar Planilla Mensual</div>
              <div className="row-2">
                <div className="field">
                  <label>Entrenador</label>
                  <select value={newPayroll.trainer_id} onChange={e => setNewPayroll({ ...newPayroll, trainer_id: e.target.value })} required>
                    <option value="" disabled>Selecciona entrenador...</option>
                    {trainers.map(t => (
                      <option key={t.id} value={t.id}>{t.nombre_completo}</option>
                    ))}
                  </select>
                </div>
                <div className="field">
                  <label>Monto Sueldo (S/.)</label>
                  <input type="number" value={newPayroll.monto_sueldo} onChange={e => setNewPayroll({ ...newPayroll, monto_sueldo: Number(e.target.value) })} required />
                </div>
              </div>
              <div className="row-2">
                <div className="field">
                  <label>Mes</label>
                  <select value={newPayroll.mes} onChange={e => setNewPayroll({ ...newPayroll, mes: Number(e.target.value) })}>
                    {[1,2,3,4,5,6,7,8,9,10,11,12].map(m => <option key={m} value={m}>Mes {m}</option>)}
                  </select>
                </div>
                <div className="field">
                  <label>Año</label>
                  <input type="number" value={newPayroll.anio} onChange={e => setNewPayroll({ ...newPayroll, anio: Number(e.target.value) })} required />
                </div>
              </div>
              <Btn type="submit" kind="primary" size="sm">Generar Planilla</Btn>
            </form>

            <div>
              <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 8 }}>Listado de Planillas</div>
              <table className="tbl" style={{ fontSize: 12 }}>
                <thead>
                  <tr>
                    <th>Entrenador</th>
                    <th>Período</th>
                    <th>Monto</th>
                    <th>Estado</th>
                    <th className="num">Acción</th>
                  </tr>
                </thead>
                <tbody>
                  {payroll.map((p, i) => (
                    <tr key={p.id || i}>
                      <td className="cell-main">{p.trainer?.nombre_completo || "Entrenador"}</td>
                      <td>Mes {p.mes} / {p.anio}</td>
                      <td>S/ {p.monto_sueldo.toLocaleString()}</td>
                      <td>
                        <Badge kind={p.estado_pago === "Pagado" ? "ok" : "warn"}>{p.estado_pago}</Badge>
                      </td>
                      <td className="num">
                        {p.estado_pago === "Pendiente" && p.id && (
                          <Btn kind="primary" size="xs" onClick={() => handlePayPayroll(p.id)}>Pagar</Btn>
                        )}
                      </td>
                    </tr>
                  ))}
                  {payroll.length === 0 && (
                    <tr>
                      <td colSpan="5">
                        <div className="empty">No hay planillas generadas en el sistema.</div>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            <div className="modal-foot">
              <Btn type="button" kind="ghost" onClick={() => setPayrollModal(false)}>Cerrar</Btn>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}

export { Finanzas };

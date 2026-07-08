import React from 'react';
import { ATTENDANCE_LOG } from '../../../data.jsx';
import { Badge, Bars, Btn, ErrorBlock, I, Panel } from '../../../shared.jsx';

function Asistencia({ app, go }) {
  const [dni, setDni] = React.useState("");
  const [result, setResult] = React.useState(null);
  const [error, setError] = React.useState("");
  const verify = async (e) => {
    e.preventDefault();
    setError("");
    setResult(null);
    try {
      const data = await app.simulateAccess(dni.trim());
      setResult(data);
    } catch (err) {
      setError(err.message || "No se pudo verificar el acceso.");
    }
  };
  const denied = ATTENDANCE_LOG.filter(a => !a.ok).length;
  return (
    <div className="content-wrap">
      <ErrorBlock message={error}/>
      <Panel title="Verificacion real de acceso" sub="DNI o QR simulado contra backend">
        <form onSubmit={verify} style={{ display: "grid", gridTemplateColumns: "1fr auto", gap: 10, alignItems: "end" }}>
          <div className="field" style={{ marginBottom: 0 }}>
            <label>DNI del socio</label>
            <input value={dni} onChange={e => setDni(e.target.value)} placeholder="Ej. 72345678" required/>
          </div>
          <Btn kind="primary" leading={I.scan} type="submit">Verificar</Btn>
        </form>
        {result && (
          <div className="state-block" style={{ marginTop: 14 }}>
            <div style={{ display: "flex", gap: 12, alignItems: "center", justifyContent: "space-between" }}>
              <div>
                <Badge kind={result.verdict === "GREEN" ? "ok" : "danger"} dot>
                  {result.verdict === "GREEN" ? "Acceso concedido" : "Acceso denegado"}
                </Badge>
                <div style={{ marginTop: 8, color: "var(--ink)" }}>{result.member?.fullName || "Socio"}</div>
                <div style={{ color: "var(--ink-2)" }}>{result.reason || "Verificacion completada."}</div>
              </div>
              {result.verdict !== "GREEN" && <Btn kind="accent" onClick={() => go?.("caja")}>Vender membresia</Btn>}
            </div>
          </div>
        )}
      </Panel>
      <div className="grid k-2-1" style={{ marginTop: 16 }}>
        <Panel title="Escáner de acceso" sub="cámara de recepción">
          <div style={{
            aspectRatio: "16 / 10", borderRadius: 14, overflow: "hidden", position: "relative",
            background: "radial-gradient(600px 300px at 50% 45%, #2a2a2a, #050505)",
            display: "grid", placeItems: "center",
          }}>
            <div style={{ width: 180, height: 180, position: "relative" }}>
              {["tl","tr","bl","br"].map(c => (
                <span key={c} aria-hidden="true" style={{
                  position: "absolute", width: 34, height: 34,
                  border: "3px solid var(--accent)",
                  borderRadius: c === "tl" ? "12px 0 0 0" : c === "tr" ? "0 12px 0 0" : c === "bl" ? "0 0 0 12px" : "0 0 12px 0",
                  borderRight: c[1] === "l" ? 0 : "3px solid var(--accent)",
                  borderLeft: c[1] === "r" ? 0 : "3px solid var(--accent)",
                  borderBottom: c[0] === "t" ? 0 : "3px solid var(--accent)",
                  borderTop: c[0] === "b" ? 0 : "3px solid var(--accent)",
                  top: c[0] === "t" ? 0 : "auto", bottom: c[0] === "b" ? 0 : "auto",
                  left: c[1] === "l" ? 0 : "auto", right: c[1] === "r" ? 0 : "auto",
                }}/>
              ))}
            </div>
            <div style={{ position: "absolute", bottom: 18, color: "rgba(255,255,255,.6)", font: "600 12px var(--font-mono)", textTransform: "uppercase", letterSpacing: ".08em" }}>
              Apunta al QR del usuario
            </div>
          </div>
          <div style={{ display: "flex", gap: 10, marginTop: 14 }}>
            <Btn kind="ghost" block leading={I.search}>Buscar por DNI</Btn>
            <Btn kind="primary" block leading={I.scan}>Ingreso manual</Btn>
          </div>
        </Panel>

        <Panel title="Log del día" sub={`${ATTENDANCE_LOG.length} ingresos · ${denied} denegados`} bodyPad={false}>
          {ATTENDANCE_LOG.map((a, i) => (
            <div className="lrow" key={i}>
              <span className="l-ic" style={{ color: a.ok ? "var(--success)" : "var(--danger)" }}>
                {a.ok ? I.check : I.close}
              </span>
              <div className="l-main">
                <div className="l-t">{a.n}</div>
                <div className="l-s">{a.via}{!a.ok && " · membresía vencida"}</div>
              </div>
              <span className="l-time">{a.t}</span>
            </div>
          ))}
        </Panel>
      </div>

      <Panel title="Asistencia por franja horaria">
        <Bars data={[
          { d: "6-8", v: 35 }, { d: "8-10", v: 22 }, { d: "10-12", v: 12 },
          { d: "12-14", v: 9 }, { d: "14-17", v: 14 }, { d: "17-19", v: 40, hot: true }, { d: "19-22", v: 28 },
        ]} unit="%"/>
      </Panel>
    </div>
  );
}

export { Asistencia };

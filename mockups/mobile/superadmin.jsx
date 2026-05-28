// superadmin.jsx — App del Super Administrador (móvil).
//
// El Super Admin gestiona la plataforma SaaS multi-inquilino. En WEB tiene un
// back-office completo (gimnasios + planes); en MÓVIL su vista es deliberadamente
// mínima: solo lista los clientes (gimnasios) y si están activos o no.

// Clientes = gimnasios (instancias multi-tenant).
const SA_CLIENTS = [
  { n: "FitZone Gym",      city: "Miraflores",   active: true },
  { n: "PowerHouse",       city: "San Isidro",   active: true },
  { n: "IronWolf Gym",     city: "Surco",        active: true },
  { n: "Olympus Fit",      city: "Barranco",     active: true },
  { n: "FlexZone",         city: "La Molina",    active: false },
  { n: "CrossHero Centro", city: "Lima Centro",  active: true },
  { n: "BodyLab",          city: "Magdalena",    active: false },
  { n: "Titan Gym",        city: "Pueblo Libre", active: true },
  { n: "VitalGym",         city: "Jesús María",  active: true },
  { n: "Arena Fitness",    city: "San Borja",    active: true },
];

function SuperAdminApp() {
  const [authed, setAuthed] = React.useState(false);
  if (!authed) return <LoginScreen role="superadmin" onLogin={() => setAuthed(true)}/>;

  const total = SA_CLIENTS.length;
  const activos = SA_CLIENTS.filter(c => c.active).length;
  const inactivos = total - activos;

  return (
    <Screen>
      <Header
        greet={{ hi: "Plataforma SaaS · GymSmart", name: "Hola, Renzo" }}
        right={<Avatar name="Renzo Salinas" size={46}/>}
      />
      <div className="scroll">
        {/* Resumen: cantidad de clientes y cuántos activos */}
        <div className="section">
          <Card className="dark" style={{ padding: 18, border: 0, position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", top: -60, right: -40, width: 220, height: 220, background: "radial-gradient(circle, color-mix(in oklab, var(--accent) 45%, transparent), transparent 65%)", filter: "blur(10px)" }}/>
            <div style={{ position: "relative" }}>
              <span style={{ font: "600 11.5px var(--font-mono)", letterSpacing: ".08em", color: "var(--accent)", textTransform: "uppercase" }}>● CLIENTES DE LA PLATAFORMA</span>
              <div style={{ font: "800 34px var(--font-display)", letterSpacing: "-0.04em", marginTop: 10 }}>
                {total} <span style={{ font: "500 15px var(--font-body)", color: "rgba(255,255,255,.6)" }}>gimnasios</span>
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginTop: 18, borderTop: "1px solid rgba(255,255,255,.1)", paddingTop: 16 }}>
                <div>
                  <div style={{ font: "800 24px var(--font-display)", letterSpacing: "-0.03em", color: "var(--accent)" }}>{activos}</div>
                  <div style={{ font: "500 11px var(--font-body)", color: "rgba(255,255,255,.55)", textTransform: "uppercase", letterSpacing: ".06em", marginTop: 2 }}>Activos</div>
                </div>
                <div>
                  <div style={{ font: "800 24px var(--font-display)", letterSpacing: "-0.03em" }}>{inactivos}</div>
                  <div style={{ font: "500 11px var(--font-body)", color: "rgba(255,255,255,.55)", textTransform: "uppercase", letterSpacing: ".06em", marginTop: 2 }}>Inactivos</div>
                </div>
              </div>
            </div>
          </Card>
        </div>

        {/* Lista de clientes con estado activo / inactivo */}
        <div className="section">
          <SectionTitle title="Gimnasios" action={`${activos} de ${total} activos`}/>
          <div className="row-list">
            {SA_CLIENTS.map(c => (
              <Card key={c.n} style={{ padding: 12, display: "flex", gap: 12, alignItems: "center" }}>
                <Avatar name={c.n} size={42}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ font: "700 14.5px var(--font-display)", letterSpacing: "-0.02em" }}>{c.n}</div>
                  <div style={{ font: "500 12.5px var(--font-body)", color: "var(--ink-2)", marginTop: 2 }}>{c.city}</div>
                </div>
                <Chip kind={c.active ? "ok" : "danger"}>
                  <span style={{ width: 6, height: 6, borderRadius: "50%", background: "currentColor" }}/>
                  {c.active ? "Activo" : "Inactivo"}
                </Chip>
              </Card>
            ))}
          </div>
        </div>

        <div className="section">
          <Btn kind="ghost" block onClick={() => setAuthed(false)}>Cerrar sesión</Btn>
        </div>
        <div style={{ height: 24 }}/>
      </div>
    </Screen>
  );
}

Object.assign(window, { SuperAdminApp });

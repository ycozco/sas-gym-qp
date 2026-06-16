// app.jsx — Root: role switcher + tweaks + page chrome

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "role": "member",
  "accent": "#D2FF3A",
  "accentInk": "#0B0B0B",
  "fontDisplay": "Bricolage Grotesque",
  "fontBody": "Geist",
  "density": "regular",
  "phoneWidth": 430,
  "showCanvas": true
}/*EDITMODE-END*/;

const ACCENT_OPTIONS = [
  ["#D2FF3A", "#0B0B0B"], // electric lime
  ["#FF4D17", "#FFFFFF"], // sunset orange
  ["#0066FF", "#FFFFFF"], // electric blue
  ["#FF2D55", "#FFFFFF"], // athletic pink
  ["#7A5AE0", "#FFFFFF"], // royal purple
];

const FONT_DISPLAY_OPTIONS = ["Bricolage Grotesque", "Sora", "Space Grotesk"];
const FONT_BODY_OPTIONS    = ["Geist", "Plus Jakarta Sans", "DM Sans"];

function Root() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [role, setRole] = React.useState(t.role || "member");
  const [themeMode, setThemeMode] = React.useState(() => {
    try { return localStorage.getItem("sasgym.theme") || "system"; } catch (e) { return "system"; }
  });

  React.useEffect(() => { setTweak("role", role); /* persist */ }, [role]);
  React.useEffect(() => {
    document.documentElement.dataset.theme = themeMode;
    try { localStorage.setItem("sasgym.theme", themeMode); } catch (e) {}
  }, [themeMode]);

  // Apply tweaks to root vars
  const styleVars = {
    "--accent": t.accent,
    "--accent-ink": t.accentInk,
    "--font-display": `"${t.fontDisplay}", ui-sans-serif, system-ui`,
    "--font-body": `"${t.fontBody}", ui-sans-serif, system-ui`,
    "--phone-w": t.phoneWidth + "px",
    "--pad": t.density === "compact" ? "14px" : t.density === "comfy" ? "22px" : "18px",
  };

  return (
    <div className="page" style={styleVars}>
      {/* TOP BAR */}
      <div className="topbar">
        <div className="wordmark">
          <span className="dot"/>
          <span>Saaa<span style={{ color: "var(--accent)" }}>S</span></span>
          <span className="gym">GYM</span>
        </div>
        <div className="role-tabs" role="tablist">
          {[
            { id: "member",  l: "Miembro" },
            { id: "trainer", l: "Entrenador" },
            { id: "caja",    l: "Caja" },
            { id: "admin",   l: "Admin" },
            { id: "superadmin", l: "Super Admin" },
          ].map(r => (
            <button key={r.id} className="role-tab" aria-selected={role === r.id} onClick={() => setRole(r.id)}>
              {r.l}
            </button>
          ))}
        </div>
        <div className="meta">
          <span>v1.0 · Hi-fi Prototype</span>
        </div>
      </div>

        <div className="theme-seg" aria-label="Tema visual">
          {[
            ["system", "Sistema"],
            ["light", "Claro"],
            ["dark", "Oscuro"],
          ].map(([id, label]) => (
            <button key={id} aria-pressed={themeMode === id} onClick={() => setThemeMode(id)}>
              {label}
            </button>
          ))}
        </div>

      {/* PHONE STAGE */}
      <div className="stage">
        <div className="phone" key={role}>
          <StatusBar/>
          {role === "member"  && <MemberApp/>}
          {role === "trainer" && <TrainerApp/>}
          {role === "caja"    && <CajaApp/>}
          {role === "admin"   && <AdminApp/>}
          {role === "superadmin" && <SuperAdminApp/>}
        </div>
      </div>

      {/* TWEAKS */}
      <TweaksPanel>
        <TweakSection label="Rol activo"/>
        <TweakRadio
          label="Vista"
          value={role}
          options={[
            { value: "member", label: "Miembro" },
            { value: "trainer", label: "Entrenador" },
            { value: "caja", label: "Caja" },
            { value: "admin", label: "Admin" },
            { value: "superadmin", label: "Super Admin" },
          ]}
          onChange={setRole}
        />

        <TweakSection label="Identidad de marca"/>
        <TweakColor
          label="Color de acento"
          value={[t.accent, t.accentInk]}
          options={ACCENT_OPTIONS}
          onChange={(v) => setTweak({ accent: v[0], accentInk: v[1] })}
        />

        <TweakSection label="Tipografía"/>
        <TweakSelect
          label="Display"
          value={t.fontDisplay}
          options={FONT_DISPLAY_OPTIONS}
          onChange={(v) => setTweak("fontDisplay", v)}
        />
        <TweakSelect
          label="Cuerpo"
          value={t.fontBody}
          options={FONT_BODY_OPTIONS}
          onChange={(v) => setTweak("fontBody", v)}
        />

        <TweakSection label="Layout"/>
        <TweakRadio
          label="Densidad"
          value={t.density}
          options={["compact", "regular", "comfy"]}
          onChange={(v) => setTweak("density", v)}
        />
        <TweakSlider
          label="Ancho canvas"
          value={t.phoneWidth}
          min={360} max={460} step={5} unit="px"
          onChange={(v) => setTweak("phoneWidth", v)}
        />
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<Root/>);

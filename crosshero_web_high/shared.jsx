// shared.jsx — iconos y componentes reutilizables del panel web.
// Expone todo en window para que data/dashboards/modules/app lo consuman.

// ─── ICONOS ────────────────────────────────────────────────────
const svg = (paths, fill) => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill={fill ? "currentColor" : "none"}
       stroke={fill ? "none" : "currentColor"} strokeWidth="2"
       strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths}</svg>
);
const I = {
  grid:  svg(<><rect x="3" y="3" width="8" height="8" rx="1.5"/><rect x="13" y="3" width="8" height="8" rx="1.5"/><rect x="3" y="13" width="8" height="8" rx="1.5"/><rect x="13" y="13" width="8" height="8" rx="1.5"/></>),
  users: svg(<><circle cx="9" cy="8" r="3.5"/><path d="M2 20c0-3.5 3-6 7-6s7 2.5 7 6"/><circle cx="17" cy="7" r="2.5"/><path d="M22 18c0-2.5-2-4-4.5-4"/></>),
  scan:  svg(<><path d="M3 7V5a2 2 0 0 1 2-2h2M3 17v2a2 2 0 0 0 2 2h2M21 7V5a2 2 0 0 0-2-2h-2M21 17v2a2 2 0 0 1-2 2h-2M7 12h10"/></>),
  cash:  svg(<><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M6 10v.01M18 14v.01"/></>),
  box:   svg(<><path d="M3 8l9-5 9 5v8l-9 5-9-5z"/><path d="M3 8l9 5 9-5M12 13v8"/></>),
  chart: svg(<><path d="M3 3v18h18"/><path d="m7 14 3-3 4 4 6-7"/></>),
  cog:   svg(<><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1.2l2-1.5-2-3.5-2.4.9a7 7 0 0 0-2-1.2L14 3h-4l-.5 2.5a7 7 0 0 0-2 1.2L5.1 5.8l-2 3.5 2 1.5A7 7 0 0 0 5 12c0 .4 0 .8.1 1.2l-2 1.5 2 3.5 2.4-.9a7 7 0 0 0 2 1.2L10 21h4l.5-2.5a7 7 0 0 0 2-1.2l2.4.9 2-3.5-2-1.5z"/></>),
  alert: svg(<><path d="m12 3 10 18H2z"/><path d="M12 10v5M12 18v0"/></>),
  bell:  svg(<><path d="M6 8a6 6 0 1 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10 21a2 2 0 0 0 4 0"/></>),
  search: svg(<><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></>),
  plus:  svg(<><path d="M12 5v14M5 12h14"/></>),
  check: svg(<><path d="m5 12 5 5L20 6"/></>),
  close: svg(<><path d="m6 6 12 12M18 6 6 18"/></>),
  more:  svg(<><circle cx="5" cy="12" r="1.6" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1.6" fill="currentColor" stroke="none"/><circle cx="19" cy="12" r="1.6" fill="currentColor" stroke="none"/></>),
  back:  svg(<><path d="m15 6-6 6 6 6"/></>),
  forward: svg(<><path d="m9 6 6 6-6 6"/></>),
  edit:  svg(<><path d="M3 21h4l11-11-4-4L3 17v4z"/><path d="M14 6l4 4"/></>),
  trash: svg(<><path d="M3 6h18M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></>),
  download: svg(<><path d="M12 3v12M7 11l5 5 5-5M5 21h14"/></>),
  logout: svg(<><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/></>),
  clock: svg(<><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>),
  filter: svg(<><path d="M3 5h18l-7 9v6l-4-2v-4z"/></>),
  dumbbell: svg(<><path d="M2 12h2M22 12h-2M6 6v12M18 6v12M10 4v16M14 4v16M6 12h12"/></>),
  trend: svg(<><path d="m3 17 6-6 4 4 8-9"/><path d="M14 6h7v7"/></>),
  card:  svg(<><rect x="2" y="5" width="20" height="14" rx="2.5"/><path d="M2 10h20M6 15h5"/></>),
  drawer: svg(<><rect x="3" y="11" width="18" height="9" rx="1.5"/><path d="M5 11V6a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v5M10 15h4"/></>),
  wallet: svg(<><path d="M3 7a2 2 0 0 1 2-2h12v4"/><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M16 13h3"/></>),
  star:  svg(<><path d="M12 2.6l2.7 5.9 6.3.7-4.8 4.3 1.3 6.3-5.5-3.2-5.5 3.2 1.3-6.3L2.3 9.2l6.3-.7z" fill="currentColor" stroke="none"/></>),
  calendar: svg(<><rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 10h18M8 3v4M16 3v4"/></>),
  mega:  svg(<><path d="M3 11v3l13 5V6L3 11z"/><path d="M16 8.5a3.5 3.5 0 0 1 0 7M6 14v5h3"/></>),
};
const icon = (name) => I[name] || I.grid;

// ─── AVATAR ────────────────────────────────────────────────────
const HUES = [12, 40, 150, 200, 255, 310];
function Avatar({ name, size = 38 }) {
  const initials = String(name || "?").split(" ").slice(0, 2).map(s => s[0]).join("").toUpperCase();
  const hue = HUES[(name || "").length % HUES.length];
  return (
    <span className="avatar" style={{
      width: size, height: size, fontSize: size * 0.36,
      background: `linear-gradient(135deg, hsl(${hue} 52% 58%), hsl(${hue + 28} 56% 44%))`,
    }}>{initials}</span>
  );
}

// ─── BOTÓN ─────────────────────────────────────────────────────
function Btn({ kind = "primary", size = "", block, leading, children, style, disabled, ...rest }) {
  return (
    <button className={`btn ${kind} ${size} ${block ? "block" : ""}`} style={style} disabled={disabled} {...rest}>
      {leading}{children && <span>{children}</span>}
    </button>
  );
}

// ─── BADGE ─────────────────────────────────────────────────────
function Badge({ kind = "", children, dot, style }) {
  return <span className={`badge ${kind}`} style={style}>{dot && <span className="pip"/>}{children}</span>;
}

// Estado de membresía → badge coherente en todo el panel.
const ST_BADGE = {
  active:  { kind: "ok",     label: "Activo" },
  expired: { kind: "danger", label: "Vencido" },
  pending: { kind: "warn",   label: "Pendiente" },
  grace:   { kind: "warn",   label: "En gracia" },
};
function StatusBadge({ st }) {
  const s = ST_BADGE[st] || { kind: "", label: st };
  return <Badge kind={s.kind} dot>{s.label}</Badge>;
}

// ─── KPI ───────────────────────────────────────────────────────
function Kpi({ icon: ic, value, label, delta, dir = "flat" }) {
  return (
    <div className="kpi">
      <div className="k-top">
        <span className="k-ic">{icon(ic)}</span>
        {delta && <span className={`k-delta ${dir}`}>{dir === "up" ? "▲ " : dir === "down" ? "▼ " : ""}{delta}</span>}
      </div>
      <div className="k-val">{value}</div>
      <div className="k-label">{label}</div>
    </div>
  );
}

// ─── PANEL ─────────────────────────────────────────────────────
function Panel({ title, sub, action, children, className = "", bodyPad = true }) {
  return (
    <section className={`panel ${className}`}>
      {(title || action) && (
        <div className="panel-head">
          {title && <h2>{title}</h2>}
          {sub && <span className="ph-sub">{sub}</span>}
          <span className="spacer"/>
          {action}
        </div>
      )}
      <div style={bodyPad ? { padding: title ? 16 : 20 } : null}>{children}</div>
    </section>
  );
}

// ─── GRÁFICAS ──────────────────────────────────────────────────
function Bars({ data, max, unit = "" }) {
  const top = max || Math.max(...data.map(d => d.v));
  return (
    <div className="bars" role="img" aria-label="Gráfico de barras">
      {data.map((d, i) => (
        <div className="bar-col" key={i}>
          <div className={`bar ${d.hot ? "hot" : "ink"}`}
               style={{ height: `${Math.max(4, (d.v / top) * 100)}%` }}
               title={`${d.d || d.m}: ${d.v}${unit}`}/>
          <span className="bar-x">{d.d || d.m}</span>
        </div>
      ))}
    </div>
  );
}

// Donut con conic-gradient a partir de segmentos {pct, c}.
function Donut({ segments, size = 150 }) {
  let acc = 0;
  const stops = segments.map(s => {
    const from = acc; acc += s.pct;
    return `${s.c} ${from}% ${acc}%`;
  }).join(", ");
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 22 }}>
      <div role="img" aria-label="Gráfico circular" style={{
        width: size, height: size, borderRadius: "50%",
        background: `conic-gradient(${stops})`,
        display: "grid", placeItems: "center", flexShrink: 0,
      }}>
        <div style={{ width: size * 0.56, height: size * 0.56, borderRadius: "50%", background: "var(--surface)" }}/>
      </div>
      <div className="legend" style={{ flexDirection: "column", gap: 10, marginTop: 0 }}>
        {segments.map((s, i) => (
          <div className="li" key={i}>
            <span className="sw" style={{ background: s.c }}/>
            <b style={{ font: "700 13px var(--font-body)", color: "var(--ink)" }}>{s.pct}%</b> {s.l}
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── SIDEBAR ───────────────────────────────────────────────────
function Sidebar({ role, section, onNavigate }) {
  const r = ROLES[role];
  return (
    <aside className="sidebar">
      <div className="brand">
        <span className="dot" aria-hidden="true"/>
        <span className="wm">Gym<em>Smart</em></span>
      </div>
      <nav aria-label="Navegación del panel">
        {r.nav.map(grp => (
          <div key={grp.group}>
            <div className="nav-label">{grp.group}</div>
            {grp.items.map(it => (
              <button key={it.id} className="nav-item"
                      aria-current={section === it.id ? "page" : undefined}
                      onClick={() => onNavigate(it.id)}>
                <span className="ic">{icon(it.icon)}</span>
                {it.label}
                {it.tag && <span className="tag">{it.tag}</span>}
              </button>
            ))}
          </div>
        ))}
      </nav>
      <div className="gym-card">
        <span className="logo" aria-hidden="true">{r.platform ? "★" : GYM.name[0]}</span>
        <div style={{ minWidth: 0 }}>
          <div className="gn">{r.platform ? "GymSmart SaaS" : GYM.name}</div>
          <div className="gs">{r.platform ? "Plataforma multi-tenant" : GYM.city}</div>
        </div>
      </div>
    </aside>
  );
}

// ─── TOPBAR ────────────────────────────────────────────────────
function Topbar({ title, sub, role, onLogout }) {
  const r = ROLES[role];
  return (
    <header className="topbar">
      <div>
        <h1>{title}</h1>
        {sub && <div className="sub">{sub}</div>}
      </div>
      <span className="spacer"/>
      <div className="t-actions">
        <span className="badge" style={{ font: "500 11.5px var(--font-mono)" }}>{TODAY.short}</span>
        <button className="icon-btn" aria-label="Notificaciones">{I.bell}<span className="dot-r"/></button>
        <div className="user-chip" role="button" tabIndex={0}>
          <Avatar name={r.who} size={30}/>
          <div>
            <div className="un">{r.who}</div>
            <div className="ur">{r.label}</div>
          </div>
        </div>
        <button className="icon-btn" aria-label="Cerrar sesión" onClick={onLogout} title="Cerrar sesión">{I.logout}</button>
      </div>
    </header>
  );
}

Object.assign(window, {
  I, icon, Avatar, Btn, Badge, StatusBadge, Kpi, Panel, Bars, Donut, Sidebar, Topbar,
});

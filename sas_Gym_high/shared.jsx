// shared.jsx — shared components & icons for SaaaS GYM prototype

// ─── ICONS ─────────────────────────────────────────────────────
const I = {
  home: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 11.5 12 4l9 7.5"/><path d="M5 10v10h14V10"/></svg>,
  calendar: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 10h18M8 3v4M16 3v4"/></svg>,
  play: <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M7 5v14l12-7z"/></svg>,
  qr: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><path d="M14 14h3v3M21 14v0M14 21h3M21 17v4"/></svg>,
  user: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/></svg>,
  bell: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 8a6 6 0 1 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10 21a2 2 0 0 0 4 0"/></svg>,
  search: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>,
  back: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="m15 6-6 6 6 6"/></svg>,
  forward: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="m9 6 6 6-6 6"/></svg>,
  more: <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="19" cy="12" r="2"/></svg>,
  plus: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"><path d="M12 5v14M5 12h14"/></svg>,
  close: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"><path d="m6 6 12 12M18 6 6 18"/></svg>,
  check: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="m5 12 5 5L20 6"/></svg>,
  dumbbell: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M2 12h2M22 12h-2M6 6v12M18 6v12M10 4v16M14 4v16M6 12h12"/></svg>,
  scan: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 7V5a2 2 0 0 1 2-2h2M3 17v2a2 2 0 0 0 2 2h2M21 7V5a2 2 0 0 0-2-2h-2M21 17v2a2 2 0 0 1-2 2h-2M7 12h10"/></svg>,
  cash: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M6 10v.01M18 14v.01"/></svg>,
  chart: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 3v18h18"/><path d="m7 14 3-3 4 4 6-7"/></svg>,
  people: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="9" cy="8" r="3.5"/><path d="M2 20c0-3.5 3-6 7-6s7 2.5 7 6"/><circle cx="17" cy="7" r="2.5"/><path d="M22 18c0-2.5-2-4-4.5-4"/></svg>,
  send: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 11 18-8-8 18-2-8z"/></svg>,
  camera: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 8h3l2-3h6l2 3h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13" r="3.5"/></svg>,
  pause: <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>,
  skip: <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M5 5v14l9-7zM16 5h3v14h-3z"/></svg>,
  edit: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 21h4l11-11-4-4L3 17v4z"/><path d="M14 6l4 4"/></svg>,
  fire: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22c5 0 8-3 8-7 0-3-2-5-3-7l-2 2c0-3-2-6-5-8 1 4-1 6-3 8-1 1-3 3-3 6 0 4 3 6 8 6z"/></svg>,
  trend: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 17 6-6 4 4 8-9"/><path d="M14 6h7v7"/></svg>,
  clock: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>,
  bolt: <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M13 2 4 14h7l-1 8 9-12h-7z"/></svg>,
  filter: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 5h18l-7 9v6l-4-2v-4z"/></svg>,
  settings: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1.2l2-1.5-2-3.5-2.4.9a7 7 0 0 0-2-1.2L14 3h-4l-.5 2.5a7 7 0 0 0-2 1.2L5.1 5.8l-2 3.5 2 1.5A7 7 0 0 0 5 12c0 .4 0 .8.1 1.2l-2 1.5 2 3.5 2.4-.9a7 7 0 0 0 2 1.2L10 21h4l.5-2.5a7 7 0 0 0 2-1.2l2.4.9 2-3.5-2-1.5c.1-.4.1-.8.1-1.2z"/></svg>,
  star: <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3 6.5 7 .8-5.3 4.8 1.5 7-6.2-3.6L5.8 21l1.5-7L2 9.3l7-.8z"/></svg>,
  vibrate: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="8" y="3" width="8" height="18" rx="1.5"/><path d="M3 9v6M21 9v6"/></svg>,
  refresh: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 12a9 9 0 0 1 15.5-6L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-15.5 6L3 16"/><path d="M3 21v-5h5"/></svg>,
  warn: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m12 3 10 18H2z"/><path d="M12 10v5M12 18v0"/></svg>,
  upload: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m7 9 5-5 5 5M12 4v12"/></svg>,
  mic: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>,
  inbox: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 13V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v8M3 13h5l2 3h4l2-3h5M3 13v6a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-6"/></svg>,
  megaphone: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 11v2l13 5V6L3 11z"/><path d="M16 8a4 4 0 0 1 0 8M6 13v6h4"/></svg>,
  trash: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></svg>,
};

// ─── STATUS BAR ────────────────────────────────────────────────
function StatusBar({ time = "08:42" }) {
  return (
    <div className="statusbar">
      <span>{time}</span>
      <span className="icons">
        <svg width="16" height="11" viewBox="0 0 16 11" fill="currentColor"><path d="M1 9h2v2H1zM5 7h2v4H5zM9 4h2v7H9zM13 1h2v10h-2z"/></svg>
        <svg width="15" height="11" viewBox="0 0 15 11" fill="none" stroke="currentColor" strokeWidth="1.4"><path d="M1 5a10 10 0 0 1 13 0"/><path d="M3.5 7a6.5 6.5 0 0 1 8 0"/><circle cx="7.5" cy="9.2" r="1" fill="currentColor"/></svg>
        <svg width="24" height="11" viewBox="0 0 24 11" fill="none" stroke="currentColor" strokeWidth="1"><rect x="1" y="1" width="20" height="9" rx="2.5"/><rect x="3" y="3" width="14" height="5" rx="1" fill="currentColor"/><path d="M22 4v3" strokeLinecap="round"/></svg>
      </span>
    </div>
  );
}

// ─── HEADER ────────────────────────────────────────────────────
function Header({ title, onBack, right, greet }) {
  if (greet) {
    return (
      <div className="s-greet">
        <div className="row">
          <div>
            <div className="hi">{greet.hi}</div>
            <div className="name" role="heading" aria-level={1}>{greet.name}</div>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            {right}
          </div>
        </div>
      </div>
    );
  }
  return (
    <div className="s-head">
      {onBack ? (
        <button className="h-back" onClick={onBack} aria-label="Volver">{I.back}</button>
      ) : <div style={{ width: 38 }}/>}
      <div className="h-title" role="heading" aria-level={1}>{title}</div>
      <div className="h-right">{right || <div style={{ width: 38 }}/>}</div>
    </div>
  );
}

// ─── BOTTOM NAV ────────────────────────────────────────────────
function BottomNav({ items, current, onChange }) {
  const cols = items.length === 4 ? "cols-4" : items.length === 3 ? "cols-3" : "";
  return (
    <nav className={`bnav ${cols}`} aria-label="Navegación principal">
      {items.map((it) => (
        <button
          key={it.id}
          className={`bnav-item ${it.fab ? "fab" : ""}`}
          aria-current={current === it.id ? "page" : undefined}
          aria-label={it.label}
          onClick={() => onChange(it.id)}
        >
          <span className="ic" aria-hidden="true">{it.icon}</span>
          {!it.fab && <span>{it.label}</span>}
        </button>
      ))}
    </nav>
  );
}

// ─── SCREEN ────────────────────────────────────────────────────
function Screen({ children, dark }) {
  return <div className="screen" style={dark ? { background: "var(--ink)", color: "#fff" } : null}>{children}</div>;
}

// ─── CARD ──────────────────────────────────────────────────────
function Card({ children, className = "", style, onClick }) {
  return <div className={`card ${className}`} style={style} onClick={onClick}>{children}</div>;
}

// ─── BTN ───────────────────────────────────────────────────────
// kind: primary | accent | ghost | danger | danger-soft
// Propaga `style`, `disabled` y cualquier prop extra (aria-*, title…).
function Btn({ kind = "primary", size = "", block, children, onClick, type, leading, trailing, style, disabled, ...rest }) {
  return (
    <button
      className={`btn ${kind} ${size} ${block ? "block" : ""}`}
      onClick={onClick}
      type={type || "button"}
      style={style}
      disabled={disabled}
      {...rest}
    >
      {leading}<span>{children}</span>{trailing}
    </button>
  );
}

// ─── CHIP ──────────────────────────────────────────────────────
function Chip({ children, kind = "", size = "", leading, style, ...rest }) {
  return <span className={`chip ${kind} ${size}`} style={style} {...rest}>{leading}{children}</span>;
}

// ─── BAR ───────────────────────────────────────────────────────
function Bar({ value, max = 100, kind = "" }) {
  const pct = Math.min(100, Math.max(0, (value / max) * 100));
  return <div className={`bar ${kind}`}><i style={{ width: `${pct}%` }}/></div>;
}

// ─── SECTION TITLE ─────────────────────────────────────────────
function SectionTitle({ title, action, onAction }) {
  return (
    <div className="s-title">
      <span className="t" role="heading" aria-level={2}>{title}</span>
      {action && (
        <span
          className="a"
          role={onAction ? "button" : undefined}
          tabIndex={onAction ? 0 : undefined}
          onClick={onAction}
          onKeyDown={onAction ? (e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); onAction(); } } : undefined}
        >{action}</span>
      )}
    </div>
  );
}

// ─── AVATAR ────────────────────────────────────────────────────
const HUES = [12, 40, 70, 130, 180, 220, 260, 310];
function Avatar({ name, size = 42 }) {
  const initials = name.split(" ").slice(0, 2).map(s => s[0]).join("").toUpperCase();
  const hue = HUES[name.length % HUES.length];
  return (
    <span
      className="av"
      style={{
        width: size, height: size,
        background: `linear-gradient(135deg, hsl(${hue} 50% 70%), hsl(${hue + 30} 55% 55%))`,
        color: "#fff",
        fontSize: size * 0.36,
      }}
    >{initials}</span>
  );
}

// ─── QR ART ────────────────────────────────────────────────────
function QRPattern({ seed = 7 }) {
  const cells = 25;
  let s = seed;
  const rand = () => { s = (s * 9301 + 49297) % 233280; return s / 233280; };
  const bits = Array.from({ length: cells * cells }, () => rand() > 0.5);
  // corners
  const isCorner = (r, c) => (r < 7 && c < 7) || (r < 7 && c > cells - 8) || (r > cells - 8 && c < 7);
  return (
    <svg viewBox={`0 0 ${cells} ${cells}`} width="100%" style={{ display: "block" }}>
      {bits.map((b, i) => {
        const r = Math.floor(i / cells);
        const c = i % cells;
        if (isCorner(r, c)) return null;
        if (!b) return null;
        return <rect key={i} x={c} y={r} width="1" height="1" fill="#0B0B0B"/>;
      })}
      {[[0, 0], [0, cells - 7], [cells - 7, 0]].map(([rr, cc], i) => (
        <g key={i}>
          <rect x={cc} y={rr} width="7" height="7" fill="#0B0B0B" rx="1.2"/>
          <rect x={cc + 1} y={rr + 1} width="5" height="5" fill="#fff" rx="0.8"/>
          <rect x={cc + 2} y={rr + 2} width="3" height="3" fill="#0B0B0B" rx="0.4"/>
        </g>
      ))}
      {/* center mark */}
      <rect x={cells / 2 - 2} y={cells / 2 - 2} width="4" height="4" fill="var(--accent)" rx="1"/>
    </svg>
  );
}

// ─── TIMER RING ────────────────────────────────────────────────
function TimerRing({ pct, color = "var(--accent)", size = 96 }) {
  const r = 42;
  const c = 2 * Math.PI * r;
  return (
    <svg width={size} height={size} viewBox="0 0 100 100">
      <circle cx="50" cy="50" r={r} stroke="rgba(255,255,255,.1)" strokeWidth="6" fill="none"/>
      <circle
        cx="50" cy="50" r={r}
        stroke={color} strokeWidth="6" fill="none"
        strokeDasharray={c}
        strokeDashoffset={c * (1 - pct)}
        strokeLinecap="round"
        style={{ transition: "stroke-dashoffset .5s linear" }}
      />
    </svg>
  );
}

// ─── EXERCISE ANIM (placeholder dumbbell illustration) ─────────
function ExerciseAnim({ kind = "bench", small }) {
  return (
    <div style={{ width: "100%", height: "100%", display: "grid", placeItems: "center", position: "relative" }}>
      <svg width={small ? 60 : 130} height={small ? 60 : 130} viewBox="0 0 100 100" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" style={{ color: "rgba(255,255,255,.85)" }}>
        {kind === "bench" && (<>
          <rect x="10" y="40" width="80" height="6" rx="3" fill="currentColor"/>
          <circle cx="20" cy="43" r="12" fill="currentColor" opacity=".15"/>
          <circle cx="20" cy="43" r="12"/>
          <circle cx="80" cy="43" r="12"/>
          <circle cx="80" cy="43" r="12" fill="currentColor" opacity=".15"/>
          <path d="M30 60v15M70 60v15M22 75h56" />
        </>)}
        {kind === "squat" && (<>
          <circle cx="50" cy="22" r="8" fill="currentColor" opacity=".18"/>
          <circle cx="50" cy="22" r="8"/>
          <path d="M30 35h40v6H30zM35 41l-6 30M65 41l6 30M30 35l-6 -3M70 35l6 -3"/>
          <circle cx="22" cy="32" r="6"/>
          <circle cx="78" cy="32" r="6"/>
        </>)}
        {kind === "row" && (<>
          <circle cx="32" cy="30" r="8"/>
          <path d="M32 38v18M22 56h20M38 45h32M70 45 60 35M70 45l-10 10M40 70l5 12M28 70l-5 12"/>
        </>)}
        {kind === "press" && (<>
          <circle cx="50" cy="22" r="8"/>
          <path d="M50 30v20M30 30h40M30 30 22 20M70 30l8-10M40 50v20M60 50v20"/>
        </>)}
      </svg>
      {/* subtle motion arc */}
      <svg style={{ position: "absolute", inset: 0, opacity: .25, color: "var(--accent)" }} viewBox="0 0 100 100">
        <path d="M20 80 Q50 30 80 80" stroke="currentColor" strokeWidth="1.5" fill="none" strokeDasharray="2 3"/>
      </svg>
    </div>
  );
}

// ─── PHOTO PLACEHOLDER (athletic/community) ─────────────────────
let __photoSeq = 0;
function Photo({ hue = 200, kind = "person", w = "100%", h = 160, label }) {
  // id estable por instancia: Math.random() en render cambiaba el gradiente
  // en cada repintado y podía colisionar entre dos <Photo>.
  const id = React.useMemo(() => `photo-grad-${__photoSeq++}`, []);
  return (
    <div style={{ width: w, height: h, position: "relative", borderRadius: 18, overflow: "hidden", background: `hsl(${hue} 25% 22%)` }}>
      <svg width="100%" height="100%" viewBox="0 0 200 200" preserveAspectRatio="xMidYMid slice">
        <defs>
          <linearGradient id={id} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor={`hsl(${hue} 40% 35%)`}/>
            <stop offset="1" stopColor={`hsl(${hue - 30} 30% 15%)`}/>
          </linearGradient>
        </defs>
        <rect width="200" height="200" fill={`url(#${id})`}/>
        {kind === "person" && <g fill="rgba(0,0,0,.3)">
          <circle cx="100" cy="78" r="28"/>
          <path d="M40 200 Q40 130 100 130 Q160 130 160 200 Z"/>
        </g>}
        {kind === "weights" && <g stroke="rgba(255,255,255,.3)" strokeWidth="6" fill="none">
          <rect x="20" y="90" width="160" height="20" rx="10"/>
          <circle cx="40" cy="100" r="22" fill="rgba(255,255,255,.2)"/>
          <circle cx="160" cy="100" r="22" fill="rgba(255,255,255,.2)"/>
        </g>}
        {kind === "gym" && <g stroke="rgba(255,255,255,.25)" strokeWidth="3" fill="none">
          <path d="M0 150 L50 130 L100 140 L150 120 L200 130"/>
          <path d="M0 170 L50 160 L100 165 L150 155 L200 160"/>
          <circle cx="50" cy="80" r="20" fill="rgba(255,255,255,.1)"/>
        </g>}
      </svg>
      {label && (
        <div style={{ position: "absolute", left: 14, bottom: 12, color: "#fff", font: "700 14px var(--font-display)", letterSpacing: "-0.02em", textShadow: "0 1px 8px rgba(0,0,0,.4)" }}>{label}</div>
      )}
    </div>
  );
}

// ─── FORM CONTROLS (compartidos por todas las apps de rol) ─────
// Antes vivían duplicados dentro de member.jsx; centralizados aquí
// para que member/trainer/caja/admin usen la misma implementación.

// Fila etiqueta/valor de solo lectura.
function Field({ l, v }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", padding: "10px 0", borderBottom: "1px solid var(--border)" }}>
      <span style={{ font: "500 13px var(--font-body)", color: "var(--ink-2)" }}>{l}</span>
      <span style={{ font: "600 13.5px var(--font-body)" }}>{v}</span>
    </div>
  );
}

// Métrica física: etiqueta + valor grande + delta opcional.
function PhyField({ l, v, d }) {
  return (
    <div>
      <div style={{ font: "500 11px var(--font-body)", color: "var(--ink-2)", textTransform: "uppercase", letterSpacing: ".06em" }}>{l}</div>
      <div style={{ font: "800 22px var(--font-display)", letterSpacing: "-0.03em", fontVariantNumeric: "tabular-nums", marginTop: 4 }}>{v}</div>
      {d && <div style={{ font: "600 11px var(--font-mono)", color: d.startsWith("-") ? "var(--success)" : "var(--info)", marginTop: 2 }}>{d}</div>}
    </div>
  );
}

// Switch on/off. Sincroniza con la prop `on` para no quedar desfasado
// si el padre cambia el valor.
function Toggle({ on, onChange }) {
  const [v, setV] = React.useState(on);
  React.useEffect(() => { setV(on); }, [on]);
  return (
    <button
      type="button" role="switch" aria-checked={!!v}
      onClick={() => { setV(!v); onChange && onChange(!v); }}
      style={{
        width: 50, height: 30, borderRadius: 999, border: 0,
        background: v ? "var(--accent)" : "var(--surface-3)",
        position: "relative", cursor: "pointer", transition: "background .18s",
      }}>
      <span style={{
        position: "absolute", top: 3, left: v ? 23 : 3,
        width: 24, height: 24, borderRadius: "50%", background: "#fff",
        boxShadow: "0 1px 3px rgba(0,0,0,.2)", transition: "left .18s",
      }}/>
    </button>
  );
}

// Stepper numérico − / +. Respeta min/max (min 0 por defecto: evita pesos
// o cantidades negativas).
function Stepper({ label, value, onChange, step = 1, min = 0, max }) {
  const clamp = (n) => {
    if (min != null && n < min) return min;
    if (max != null && n > max) return max;
    return n;
  };
  const btn = { width: 38, height: 44, border: 0, background: "transparent", font: "700 20px var(--font-display)", cursor: "pointer", color: "var(--ink)" };
  return (
    <div className="field">
      <label>{label}</label>
      <div style={{ display: "flex", alignItems: "center", background: "var(--surface-2)", border: "1px solid var(--border)", borderRadius: 14, padding: 4 }}>
        <button type="button" aria-label={`Disminuir ${label}`} onClick={() => onChange(clamp(value - step))} style={btn}>−</button>
        <span style={{ flex: 1, textAlign: "center", font: "800 22px var(--font-display)", letterSpacing: "-0.03em", fontVariantNumeric: "tabular-nums" }}>{value}</span>
        <button type="button" aria-label={`Aumentar ${label}`} onClick={() => onChange(clamp(value + step))} style={btn}>+</button>
      </div>
    </div>
  );
}

// ─── ROUTER (pila de navegación) ───────────────────────────────
// Reemplaza el useState("home") + go() de cada app de rol. `go` apila
// la pantalla previa; si navegas hacia la pantalla inmediatamente
// anterior (lo que hace cada onBack), hace pop en vez de push, así el
// botón "volver" regresa al origen real y no a un destino fijo.
function useRouter(initial) {
  const [state, setState] = React.useState({ screen: initial, params: null });
  const stackRef = React.useRef([]);
  const go = React.useCallback((screen, params = null) => {
    setState((prev) => {
      const stack = stackRef.current;
      if (stack.length && stack[stack.length - 1].screen === screen) {
        return stack.pop();           // volver al origen real
      }
      stack.push(prev);
      return { screen, params };
    });
  }, []);
  const back = React.useCallback(() => {
    setState((prev) => {
      const stack = stackRef.current;
      return stack.length ? stack.pop() : prev;
    });
  }, []);
  return { screen: state.screen, params: state.params, go, back };
}

// ─── LOGIN (CU-01) ─────────────────────────────────────────────
// Pantalla de inicio de sesión compartida por las 4 apps de rol.
// `role` solo adapta el texto/correo de ejemplo; el rol real lo fija
// el selector superior del prototipo.
const AUTH_ROLES = {
  member:     { label: "Miembro",            email: "mateo.salas@gmail.com" },
  trainer:    { label: "Entrenador",         email: "carlos.mendoza@gmail.com" },
  caja:       { label: "Caja · Recepción",   email: "mariana.quispe@saaasgym.pe" },
  admin:      { label: "Administración",     email: "sandra.aguilar@saaasgym.pe" },
  superadmin: { label: "Super Administrador", email: "renzo.salinas@gymsmart.io" },
};

function LoginScreen({ role = "member", onLogin }) {
  const r = AUTH_ROLES[role] || AUTH_ROLES.member;
  const submit = (e) => { e.preventDefault(); onLogin && onLogin(); };
  return (
    <div className="screen">
      <div className="auth">
        <div className="a-hero">
          <span className="a-glow" aria-hidden="true"/>
          <span className="a-wm">
            <span className="d"/>Saaa<span style={{ color: "var(--accent)" }}>S</span> GYM
          </span>
          <div className="a-title" role="heading" aria-level={1}>Bienvenido<br/>de vuelta</div>
          <div className="a-sub">Ingresa a tu cuenta para continuar.</div>
          <span className="a-role">● {r.label}</span>
        </div>
        <form className="a-form" onSubmit={submit}>
          <div className="field">
            <label htmlFor="au-email">Correo electrónico</label>
            <input id="au-email" type="email" defaultValue={r.email} autoComplete="username"/>
          </div>
          <div className="field">
            <label htmlFor="au-pass">Contraseña</label>
            <input id="au-pass" type="password" defaultValue="demo1234" autoComplete="current-password"/>
          </div>
          <div className="a-row">
            <label className="a-check"><input type="checkbox" defaultChecked/> Recordarme</label>
            <span className="a-link" role="button" tabIndex={0}>¿Olvidaste tu contraseña?</span>
          </div>
          <Btn kind="primary" size="lg" block type="submit">Iniciar sesión</Btn>
          <div className="a-foot">¿Aún no tienes cuenta? <b>Regístrate</b></div>
        </form>
      </div>
    </div>
  );
}

// ─── EXPORT ────────────────────────────────────────────────────
Object.assign(window, {
  I, StatusBar, Header, BottomNav, Screen, Card, Btn, Chip, Bar, SectionTitle, Avatar, QRPattern, TimerRing, ExerciseAnim, Photo,
  Field, PhyField, Toggle, Stepper, useRouter, LoginScreen
});

// data.jsx — datos mock compartidos por las apps de rol.
// Se carga antes de member/trainer/admin/caja para que todos lean
// la misma fuente y no dependan de variables accidentales del scope global.

// Fecha de referencia del prototipo (un único lugar para "hoy").
const TODAY = {
  iso: "2026-05-21",
  long: "Miércoles, 21 de Mayo",
  short: "21 may",
  dow: "Miércoles",
};

// ─── Catálogo (Admin + Caja) ───────────────────────────────────
const PRODUCTS = [
  { id: "p1", n: "Botella de agua 600ml",  cat: "Bebidas",     p: 3,  stock: 124, k: "💧" },
  { id: "p2", n: "Proteína whey · porción", cat: "Suplementos", p: 12, stock: 38,  k: "💪" },
  { id: "p3", n: "Pre-entreno · scoop",     cat: "Suplementos", p: 8,  stock: 22,  k: "⚡" },
  { id: "p4", n: "Barra energética",        cat: "Snacks",      p: 5,  stock: 56,  k: "🍫" },
  { id: "p5", n: "Polo oficial SaaaS",      cat: "Merch",       p: 45, stock: 18,  k: "👕" },
  { id: "p6", n: "Toalla deportiva",        cat: "Accesorios",  p: 5,  stock: 12,  k: "🏃" },
  { id: "p7", n: "Creatina · porción",      cat: "Suplementos", p: 6,  stock: 41,  k: "💊" },
  { id: "p8", n: "Shaker 600ml",            cat: "Merch",       p: 18, stock: 9,   k: "🥤" },
];

const ALL_MEMBERS = [
  { n: "Mateo Salas",      dni: "70432198", plan: "Mensual",    st: "active",  d: "14d", tr: "Carlos M." },
  { n: "Lucía Fernández",  dni: "44219876", plan: "Trimestral", st: "active",  d: "42d", tr: "Andrea S." },
  { n: "Diego Castro",     dni: "08123456", plan: "Mensual",    st: "expired", d: "-3d", tr: "Carlos M." },
  { n: "Rosa Mendieta",    dni: "70998421", plan: "Mensual",    st: "active",  d: "6d", tr: "Lucía F." },
  { n: "Jorge Paredes",    dni: "47312908", plan: "Anual",      st: "active",  d: "287d", tr: "Carlos M." },
  { n: "Ana Torres",       dni: "73219804", plan: "Mensual",    st: "grace",   d: "1d gracia", tr: "Andrea S." },
  { n: "Pedro Quispe",     dni: "10234567", plan: "Mensual",    st: "pending", d: "Sin pagar", tr: "—" },
  { n: "Camila Rojas",     dni: "70845231", plan: "Trimestral", st: "active",  d: "65d", tr: "Lucía F." },
];

// ─── Rutina / agenda (Practicante; EXERCISES_TODAY lo usa también el Entrenador) ───
const TODAY_WORKOUT = {
  name: "Push · Pecho + Hombros",
  exercises: 6,
  duration: "55 min",
  intensity: "Alta",
  trainer: "Carlos Mendoza",
};

const WEEK = [
  { dow: "Lun", n: 19, group: "Pecho",  rest: false },
  { dow: "Mar", n: 20, group: "Pull",   rest: false },
  { dow: "Mié", n: 21, group: "Push",   rest: false, today: true },
  { dow: "Jue", n: 22, group: "Pierna", rest: false },
  { dow: "Vie", n: 23, group: "Full",   rest: false },
  { dow: "Sáb", n: 24, group: "Core",   rest: false },
  { dow: "Dom", n: 25, group: "Descanso", rest: true },
];

const EXERCISES_TODAY = [
  { id: "e1", name: "Press de banca",        muscle: "Pecho",    sets: 4, reps: "8-10", weight: 70, rest: 90, kind: "bench" },
  { id: "e2", name: "Press inclinado con mancuernas", muscle: "Pecho superior", sets: 4, reps: "10-12", weight: 24, rest: 75, kind: "press" },
  { id: "e3", name: "Aperturas en máquina",  muscle: "Pecho",    sets: 3, reps: "12-15", weight: 35, rest: 60, kind: "press" },
  { id: "e4", name: "Press militar barra",   muscle: "Hombro",   sets: 4, reps: "8-10", weight: 40, rest: 90, kind: "press" },
  { id: "e5", name: "Elevaciones laterales", muscle: "Hombro",   sets: 4, reps: "12-15", weight: 10, rest: 60, kind: "press" },
  { id: "e6", name: "Fondos en paralelas",   muscle: "Tríceps",  sets: 3, reps: "Al fallo", weight: 0, rest: 90, kind: "row" },
];

const ANNOUNCEMENTS = [
  { id: "a1", title: "Clases gratis sábado", body: "Funcional al aire libre 8am · Parque Kennedy", time: "Hace 2h", tag: "EVENTO" },
  { id: "a2", title: "Mantenimiento jueves", body: "Máquina Smith fuera de servicio de 6 a 9pm", time: "Ayer", tag: "AVISO" },
];

Object.assign(window, {
  TODAY, PRODUCTS, ALL_MEMBERS,
  TODAY_WORKOUT, WEEK, EXERCISES_TODAY, ANNOUNCEMENTS,
});

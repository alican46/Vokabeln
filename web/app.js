/* Ferheng Web – Kurdisch lernen.
 * Datenformat ist identisch mit der iOS-App, Backups sind austauschbar.
 * Zeiten werden wie in Swift als Sekunden seit 1.1.2001 gespeichert. */
'use strict';

// ---------- Hilfsfunktionen ----------
const $ = (s, el = document) => el.querySelector(s);
const $$ = (s, el = document) => Array.from(el.querySelectorAll(s));
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
const REF = 978307200; // 1.1.2001 in Unix-Sekunden
const DISTANT_PAST = -63114076800;
const DAY = 86400;
const firstGrapheme = (s) => {
  s = String(s ?? '').trim(); if (!s) return '';
  if (window.Intl && Intl.Segmenter) { for (const g of new Intl.Segmenter('de', { granularity: 'grapheme' }).segment(s)) return g.segment; }
  return Array.from(s)[0];
};
const nowRef = () => Date.now() / 1000 - REF;
const refToDate = (r) => new Date((r + REF) * 1000);
const startOfDayRef = (r = nowRef()) => { const d = refToDate(r); d.setHours(0, 0, 0, 0); return d.getTime() / 1000 - REF; };
const pad = (n) => String(n).padStart(2, '0');
const dayKey = (d = new Date()) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const daysAgo = (n) => { const d = new Date(); d.setDate(d.getDate() - n); return d; };
const uuid = () => (crypto.randomUUID ? crypto.randomUUID() : 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
  const r = Math.random() * 16 | 0; return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
})).toUpperCase();
const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
const trim = (s) => String(s ?? '').trim();
const md = (s) => esc(s).replace(/\*\*(.+?)\*\*/g, '<b>$1</b>').replace(/\*(.+?)\*/g, '<i>$1</i>');
const plural = (n, one, many) => `${n} ${n === 1 ? one : many}`;
const vibrate = (p) => { try { navigator.vibrate && navigator.vibrate(p); } catch (e) { /* iOS kann das nicht */ } };

// ---------- Konstanten ----------
const WORD_TYPES = { noun: 'Nomen', verb: 'Verb', adj: 'Adjektiv', phrase: 'Redewendung', other: 'Sonstiges' };
const TYPE_ICON = { noun: '📦', verb: '⚡️', adj: '🎨', phrase: '💬', other: '🔤' };
const VERB_FORMS = [
  { key: 'stem', label: 'Präsensstamm', hint: 'z. B. -ç-' },
  { key: 'present', label: 'Präsens (ez …)', hint: 'z. B. ez diçim' },
  { key: 'past', label: 'Vergangenheit', hint: 'z. B. ez çûm / min xwar' },
  { key: 'imperative', label: 'Imperativ', hint: 'z. B. here!' },
  { key: 'future', label: 'Futur', hint: 'z. B. ez ê biçim' }
];
const FORM_LABEL = Object.fromEntries(VERB_FORMS.map((f) => [f.key, f.label]));
const TRANS = { unknown: '–', transitive: 'transitiv', intransitive: 'intransitiv' };
const MASTERY = {
  new: { label: 'Neu', color: '#c7c7cc' },
  hard: { label: 'Schwer', color: '#ed455c' },
  learning: { label: 'In Arbeit', color: '#ff9500' },
  easy: { label: 'Leicht', color: '#0a84ff' },
  mastered: { label: 'Sitzt', color: '#30c75e' }
};
const MASTERY_ORDER = ['mastered', 'easy', 'learning', 'hard', 'new'];
const COLORS = { teal: '#0d8c80', blue: '#0a84ff', indigo: '#5e5ce6', violet: '#af52de', pink: '#ff375f', red: '#ff3b30', orange: '#ff9500', amber: '#f2a60d', green: '#30c75e', gray: '#8e8e93' };
const GRADE_COLOR = ['#ed455c', '#ff9500', '#0d8c80', '#0a84ff'];
const GRADE_LABEL = ['Nochmal', 'Schwer', 'Gut', 'Einfach'];
const DIRECTIONS = { kuToDe: 'Kurdisch → Deutsch', deToKu: 'Deutsch → Kurdisch', mixed: 'Gemischt' };
const QUIZ = { flashcard: ['Karteikarte', '🃏'], multipleChoice: ['Auswahl', '☑️'], typing: ['Schreiben', '⌨️'], mixed: ['Gemischt', '🔀'] };
const MODES = {
  smart: { label: 'Smart lernen', sub: 'Fällige Wiederholungen + neue Wörter', icon: '🧠', cls: '' },
  hard: { label: 'Schwierige Wörter', sub: 'Nur Wörter, die dir schwerfallen', icon: '🔥', cls: 'hard' },
  practice: { label: 'Freies Üben', sub: 'Zufällig – schwere Wörter kommen öfter', icon: '🎲', cls: 'sun' },
  verbs: { label: 'Verb-Trainer', sub: 'Stamm, Präsens, Vergangenheit, Imperativ, Futur', icon: '⚡️', cls: 'verb' }
};
const GRADIENT = { '': 'linear-gradient(135deg,#0d8c80,#21c7a8)', hard: 'linear-gradient(135deg,#ed455c,#fa7859)', sun: 'linear-gradient(135deg,#fa8c26,#fab81a)', verb: 'linear-gradient(135deg,#704cf2,#b366fa)' };
const KU_CHARS = ['ê', 'î', 'û', 'ç', 'ş'];

// ---------- Datenspeicher ----------
const STORAGE_KEY = 'ferheng-daten';
const defaultSettings = () => ({ dailyGoal: 20, newPerDay: 10, sessionSize: 20, direction: 'mixed', quizKind: 'mixed' });
let db = { folders: [], cards: [], progress: {}, log: {}, settings: defaultSettings(), hasOnboarded: false };

function normalizeSnapshot(s) {
  const out = {
    folders: Array.isArray(s.folders) ? s.folders : [],
    cards: Array.isArray(s.cards) ? s.cards : [],
    progress: s.progress && typeof s.progress === 'object' ? s.progress : {},
    log: s.log && typeof s.log === 'object' ? s.log : {},
    settings: Object.assign(defaultSettings(), s.settings || {}),
    hasOnboarded: !!s.hasOnboarded
  };
  out.folders = out.folders.map((f) => Object.assign({ emoji: '📁', colorName: 'teal', linkedIDs: [], createdAt: nowRef() }, f));
  out.cards = out.cards.map((c) => Object.assign({
    type: 'other', gender: 'none', plural: '', transitivity: 'unknown', forms: {},
    exampleKu: '', exampleDe: '', note: '', createdAt: nowRef()
  }, c));
  return out;
}

function load() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) db = normalizeSnapshot(JSON.parse(raw));
  } catch (e) { console.warn('Laden fehlgeschlagen', e); }
}
function save() {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(db)); }
  catch (e) { toast('Speichern fehlgeschlagen – Speicher voll?'); }
}
// Bittet den Browser, die Daten nicht automatisch zu löschen.
if (navigator.storage && navigator.storage.persist) navigator.storage.persist().catch(() => {});

// Export im Swift-kompatiblen Format (parentID/lastSeen weglassen statt null)
function exportJSON() {
  const clean = JSON.parse(JSON.stringify(db));
  clean.folders.forEach((f) => { if (f.parentID == null) delete f.parentID; });
  Object.values(clean.progress).forEach((p) => { if (p.lastSeen == null) delete p.lastSeen; });
  return JSON.stringify(clean, null, 2);
}

// ---------- Ordner ----------
const folderById = (id) => db.folders.find((f) => f.id === id);
const cardById = (id) => db.cards.find((c) => c.id === id);
const children = (parent) => db.folders.filter((f) => (f.parentID ?? null) === (parent ?? null))
  .sort((a, b) => a.name.localeCompare(b.name, 'de', { numeric: true }));
function pathTo(id) {
  const out = []; let cur = folderById(id); let n = 0;
  while (cur && n++ < 50) { out.unshift(cur); cur = folderById(cur.parentID); }
  return out;
}
function descendantIDs(id) {
  const res = new Set([id]); const stack = [id];
  while (stack.length) {
    const next = stack.pop();
    db.folders.forEach((f) => { if (f.parentID === next && !res.has(f.id)) { res.add(f.id); stack.push(f.id); } });
  }
  return res;
}
function flatFolders() {
  const out = [];
  const walk = (parent, depth) => children(parent).forEach((f) => { out.push({ folder: f, depth }); walk(f.id, depth + 1); });
  walk(null, 0);
  return out;
}
const directCards = (fid) => db.cards.filter((c) => c.folderID === fid).sort((a, b) => b.createdAt - a.createdAt);
function allCards(fid) {
  const ids = new Set(); const stack = [fid];
  while (stack.length) {
    const id = stack.pop();
    if (ids.has(id)) continue;
    ids.add(id);
    db.folders.forEach((f) => { if (f.parentID === id) stack.push(f.id); });
    const f = folderById(id); if (f) stack.push(...(f.linkedIDs || []));
  }
  return db.cards.filter((c) => ids.has(c.folderID));
}
function addFolder(name, emoji, colorName, parentID) {
  const f = { id: uuid(), name, emoji: emoji || '📁', colorName, linkedIDs: [], createdAt: nowRef() };
  if (parentID) f.parentID = parentID;
  db.folders.push(f); save(); return f;
}
function deleteFolder(id) {
  const ids = descendantIDs(id);
  db.cards.filter((c) => ids.has(c.folderID)).forEach((c) => removeProgress(c.id));
  db.cards = db.cards.filter((c) => !ids.has(c.folderID));
  db.folders = db.folders.filter((f) => !ids.has(f.id));
  db.folders.forEach((f) => { f.linkedIDs = (f.linkedIDs || []).filter((x) => !ids.has(x)); });
  save();
}
function mergeFolders(ids, name, emoji, parentID, mode) {
  const selected = new Set(ids);
  let parent = parentID || null;
  if (mode === 'combine' && parent) {
    const outer = pathTo(parent).find((f) => selected.has(f.id));
    if (outer) parent = outer.parentID || null;
  }
  const nf = { id: uuid(), name, emoji: emoji || '🗂️', colorName: 'indigo', linkedIDs: [], createdAt: nowRef() };
  if (parent) nf.parentID = parent;
  if (mode === 'link') {
    nf.linkedIDs = ids.slice();
    db.folders.push(nf);
  } else {
    db.folders.push(nf);
    ids.forEach((id) => {
      db.folders.forEach((f) => { if (f.parentID === id && !selected.has(f.id)) f.parentID = nf.id; });
      db.cards.forEach((c) => { if (c.folderID === id) c.folderID = nf.id; });
    });
    db.folders = db.folders.filter((f) => !selected.has(f.id));
    db.folders.forEach((f) => {
      const had = (f.linkedIDs || []).some((x) => selected.has(x));
      f.linkedIDs = (f.linkedIDs || []).filter((x) => !selected.has(x));
      if (had && f.id !== nf.id && !f.linkedIDs.includes(nf.id)) f.linkedIDs.push(nf.id);
    });
  }
  save(); return nf;
}

// ---------- Karten ----------
function newCard(folderID) {
  return { id: uuid(), folderID, kurdish: '', german: '', type: 'other', gender: 'none', plural: '', transitivity: 'unknown', forms: {}, exampleKu: '', exampleDe: '', note: '', createdAt: nowRef() };
}
function upsertCard(card) {
  const i = db.cards.findIndex((c) => c.id === card.id);
  if (i >= 0) db.cards[i] = card; else db.cards.push(card);
  save();
}
function deleteCard(id) { db.cards = db.cards.filter((c) => c.id !== id); removeProgress(id); save(); }
function removeProgress(cardID) { Object.keys(db.progress).forEach((k) => { if (k.includes(cardID)) delete db.progress[k]; }); }
const cardForm = (c, f) => trim((c.forms || {})[f]);
const filledForms = (c) => (c.type === 'verb' ? VERB_FORMS.map((f) => f.key).filter((f) => cardForm(c, f)) : []);
function splitLine(line) {
  for (const sep of ['\t', ' = ', '=', ';', ' – ', ' — ', ' - ', ':']) {
    const i = line.indexOf(sep);
    if (i > 0) {
      const a = trim(line.slice(0, i)); const b = trim(line.slice(i + sep.length));
      if (a && b) return [a, b];
    }
  }
  return null;
}
function bulkAdd(text, folderID, type) {
  let n = 0;
  text.split(/\r?\n/).forEach((l) => {
    const p = splitLine(trim(l)); if (!p) return;
    const c = newCard(folderID); c.kurdish = p[0]; c.german = p[1]; c.type = type;
    db.cards.push(c); n++;
  });
  if (n) save();
  return n;
}

// ---------- Spaced Repetition (wie iOS) ----------
const defaultState = () => ({ ease: 2.5, interval: 0, due: DISTANT_PAST, reps: 0, lapses: 0, seen: 0, correct: 0, wrong: 0, streak: 0, firstEasy: false });
const stateOf = (key) => Object.assign(defaultState(), db.progress[key] || {});
const keyOf = (item) => (item.form ? `v:${item.cardID}:${item.form}` : `c:${item.cardID}`);

function schedule(s, grade, now = nowRef()) {
  const n = Object.assign({}, s);
  n.seen++; n.lastSeen = now;
  if (grade === 0) {
    n.wrong++; if (n.reps > 0) n.lapses++;
    n.reps = 0; n.streak = 0; n.interval = 0; n.ease = Math.max(1.3, n.ease - 0.2); n.due = now + 600;
    return n;
  }
  n.correct++; n.streak++;
  if (s.seen === 0 && grade === 3) n.firstEasy = true;
  let iv;
  if (n.reps === 0) iv = grade === 3 ? 4 : 1;
  else if (n.reps === 1) iv = grade === 1 ? 2 : grade === 2 ? 3 : 6;
  else {
    const factor = grade === 1 ? 1.2 : grade === 2 ? n.ease : n.ease * 1.3;
    iv = Math.round(Math.max(n.interval, 1) * factor);
    if (grade !== 1) iv = Math.max(iv, n.interval + 1);
    iv = Math.max(iv, 1);
  }
  if (grade === 1) n.ease = Math.max(1.3, n.ease - 0.15);
  if (grade === 3) n.ease = Math.min(3.2, n.ease + 0.15);
  n.interval = iv; n.reps++;
  n.due = startOfDayRef(now) + iv * DAY;
  return n;
}
function practiceUpdate(s, correct, now = nowRef()) {
  const n = Object.assign({}, s);
  n.seen++; n.lastSeen = now;
  if (correct) { n.correct++; n.streak++; }
  else { n.wrong++; n.streak = 0; n.ease = Math.max(1.3, n.ease - 0.1); n.due = Math.min(n.due, now); }
  return n;
}
function difficulty(s) {
  if (!s.seen) return 0;
  const acc = s.correct / s.seen;
  return (1 - acc) * 5 + s.lapses * 1.5 + (2.5 - s.ease) * 3 - Math.min(s.streak, 5) * 0.4;
}
function mastery(s) {
  if (!s.seen) return 'new';
  if (difficulty(s) >= 2.5) return 'hard';
  if (s.interval >= 21) return 'mastered';
  if (s.firstEasy || (s.wrong === 0 && s.seen >= 2)) return 'easy';
  return 'learning';
}
function intervalLabel(s, grade) {
  const n = schedule(s, grade);
  if (n.interval === 0) return '10 Min';
  if (n.interval === 1) return '1 Tag';
  if (n.interval < 30) return `${n.interval} Tage`;
  if (n.interval < 365) return `${Math.floor(n.interval / 30)} Mon.`;
  return `${Math.floor(n.interval / 365)} J.`;
}
const cardMastery = (c) => mastery(stateOf(`c:${c.id}`));

function record(item, grade, practice) {
  const key = keyOf(item);
  const before = stateOf(key);
  db.progress[key] = practice ? practiceUpdate(before, grade !== 0) : schedule(before, grade);
  const k = dayKey();
  const st = Object.assign({ reviews: 0, correct: 0, newCards: 0 }, db.log[k]);
  st.reviews++; if (grade !== 0) st.correct++; if (before.seen === 0) st.newCards++;
  db.log[k] = st;
  save();
}
const todayStat = () => Object.assign({ reviews: 0, correct: 0, newCards: 0 }, db.log[dayKey()]);
function streak() {
  let off = (db.log[dayKey()]?.reviews || 0) > 0 ? 0 : 1; let n = 0;
  while ((db.log[dayKey(daysAgo(off))]?.reviews || 0) > 0) { n++; off++; }
  return n;
}
const vocabItems = (scope) => scope.map((c) => ({ cardID: c.id, form: null }));
const verbItems = (scope) => scope.flatMap((c) => filledForms(c).map((f) => ({ cardID: c.id, form: f })));
function dueCount(scope) { const now = nowRef(); return vocabItems(scope).filter((i) => { const s = stateOf(keyOf(i)); return s.seen > 0 && s.due <= now; }).length; }
const newCount = (scope) => vocabItems(scope).filter((i) => stateOf(keyOf(i)).seen === 0).length;
const hardItems = (scope) => vocabItems(scope).concat(verbItems(scope)).filter((i) => mastery(stateOf(keyOf(i))) === 'hard');
function masteryCounts(scope) { const r = {}; scope.forEach((c) => { const m = cardMastery(c); r[m] = (r[m] || 0) + 1; }); return r; }
const byDifficulty = (a, b) => difficulty(stateOf(keyOf(b))) - difficulty(stateOf(keyOf(a)));

function weightedSample(items, count) {
  const pool = items.map((i) => { const s = stateOf(keyOf(i)); return [i, s.seen === 0 ? 1.5 : 1 + Math.max(0, difficulty(s)) * 1.5]; });
  const out = [];
  while (out.length < count && pool.length) {
    const total = pool.reduce((a, p) => a + p[1], 0);
    let r = Math.random() * total; let idx = pool.length - 1;
    for (let i = 0; i < pool.length; i++) { r -= pool[i][1]; if (r <= 0) { idx = i; break; } }
    out.push(pool.splice(idx, 1)[0][0]);
  }
  return out;
}
function buildSession(scope, mode, size) {
  const now = nowRef();
  if (mode === 'smart' || mode === 'verbs') {
    const items = mode === 'verbs' ? verbItems(scope) : vocabItems(scope);
    const due = items.filter((i) => { const s = stateOf(keyOf(i)); return s.seen > 0 && s.due <= now; }).sort(byDifficulty);
    const fresh = shuffle(items.filter((i) => stateOf(keyOf(i)).seen === 0));
    const newLimit = mode === 'verbs' ? size : Math.max(0, db.settings.newPerDay - todayStat().newCards);
    let res = due.slice(0, size);
    if (res.length < size) res = res.concat(fresh.slice(0, Math.min(newLimit, size - res.length)));
    if (mode === 'verbs' && res.length < size) {
      const used = new Set(res.map(keyOf));
      res = res.concat(weightedSample(items.filter((i) => !used.has(keyOf(i))), size - res.length));
    }
    return shuffle(res);
  }
  if (mode === 'hard') {
    const items = vocabItems(scope).concat(verbItems(scope))
      .filter((i) => { const s = stateOf(keyOf(i)); return s.seen > 0 && difficulty(s) > 0.5; }).sort(byDifficulty);
    return shuffle(items.slice(0, size));
  }
  return weightedSample(vocabItems(scope), size);
}
function availableFor(scope, mode) {
  if (mode === 'smart') return dueCount(scope) + Math.min(newCount(scope), Math.max(0, db.settings.newPerDay - todayStat().newCards));
  if (mode === 'hard') return hardItems(scope).length;
  if (mode === 'verbs') return verbItems(scope).length;
  return scope.length;
}

const promptOf = (item, c, dir) => (item.form ? c.kurdish : dir === 'deToKu' ? c.german : c.kurdish);
const answerOf = (item, c, dir) => (item.form ? cardForm(c, item.form) : dir === 'deToKu' ? c.kurdish : c.german);
function distractors(item, card, dir, count) {
  const correct = answerOf(item, card, dir);
  let pool = [];
  if (item.form) {
    pool = filledForms(card).filter((f) => f !== item.form).map((f) => cardForm(card, f))
      .concat(shuffle(db.cards.filter((c) => c.id !== card.id).map((c) => cardForm(c, item.form)).filter(Boolean)));
  } else {
    const others = shuffle(db.cards.filter((c) => c.id !== card.id));
    pool = others.filter((c) => c.type === card.type).concat(others.filter((c) => c.type !== card.type))
      .map((c) => (dir === 'deToKu' ? c.kurdish : c.german));
  }
  const seen = new Set([correct.toLowerCase()]); const out = [];
  for (const p of pool) {
    if (seen.has(p.toLowerCase())) continue;
    seen.add(p.toLowerCase()); out.push(p);
    if (out.length === count) break;
  }
  return out;
}

// ---------- Antwortprüfung ----------
function normalizeAnswer(s, german) {
  let t = String(s).toLowerCase().replace(/\([^)]*\)/g, ' ').replace(/[?!.,;:¡¿"'“”„…]/g, '');
  let words = t.split(/\s+/).filter(Boolean);
  if (german && words.length > 1 && ['der', 'die', 'das', 'ein', 'eine', 'einen', 'sich', 'zu'].includes(words[0])) words.shift();
  return words.join(' ');
}
const fold = (s) => String(s).normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
function levenshtein(a, b) {
  a = Array.from(a); b = Array.from(b);
  if (!a.length) return b.length; if (!b.length) return a.length;
  let prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    const cur = [i];
    for (let j = 1; j <= b.length; j++) cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    prev = cur;
  }
  return prev[b.length];
}
function checkAnswer(input, answer, german) {
  const given = normalizeAnswer(input, german);
  if (!given) return 'wrong';
  const sep = german ? /[\/;,]/ : /[\/;]/;
  const alts = Array.from(new Set(answer.split(sep).map((p) => normalizeAnswer(p, german)).filter(Boolean).concat([normalizeAnswer(answer, german)])));
  if (alts.includes(given)) return 'exact';
  const fg = fold(given);
  if (alts.some((a) => fold(a) === fg)) return 'accent';
  for (const alt of alts) {
    const a = fold(alt); const allowed = a.length >= 9 ? 2 : a.length >= 4 ? 1 : 0;
    if (allowed && levenshtein(a, fg) <= allowed) return 'typo';
  }
  return 'wrong';
}

// ---------- Startpaket ----------
function loadStarterPack() {
  const insert = (node, parent) => {
    const f = addFolder(node.name, node.emoji, node.color, parent);
    (node.cards || []).forEach((sc) => {
      const c = newCard(f.id);
      c.kurdish = sc.ku; c.german = sc.de; c.type = sc.type || 'other';
      c.gender = sc.gender || 'none'; c.transitivity = sc.trans || 'unknown'; c.forms = sc.forms || {};
      c.exampleKu = sc.exKu || ''; c.exampleDe = sc.exDe || ''; c.note = sc.note || '';
      db.cards.push(c);
    });
    (node.children || []).forEach((ch) => insert(ch, f.id));
  };
  insert(window.STARTER_PACK, null);
  db.hasOnboarded = true; save();
}

// ---------- UI-Zustand ----------
const ui = { tab: 'home', folder: null, search: '', grammar: null };
let session = null;

function toast(msg) {
  const t = $('#toast'); t.textContent = msg; t.classList.add('show');
  clearTimeout(toast._t); toast._t = setTimeout(() => t.classList.remove('show'), 2200);
}

// ---------- Bausteine ----------
function folderIcon(f, big = false) {
  const c = COLORS[f.colorName] || COLORS.teal;
  const link = (f.linkedIDs || []).length ? `<span class="link-dot" style="background:${c}">🔗</span>` : '';
  return `<div class="folder-icon ${big ? 'big' : ''}" style="background:linear-gradient(${c}40,${c}1f)">${esc(f.emoji)}${link}</div>`;
}
function mbar(counts, thick = false) {
  const total = Object.values(counts).reduce((a, b) => a + b, 0) || 1;
  return `<div class="mbar ${thick ? 'thick' : ''}">${MASTERY_ORDER.filter((m) => counts[m]).map((m) =>
    `<span style="width:${(counts[m] / total) * 100}%;background:${MASTERY[m].color}"></span>`).join('')}</div>`;
}
const legend = (counts) => `<div class="legend">${MASTERY_ORDER.map((m) => `<span><i class="dot" style="background:${MASTERY[m].color}"></i>${MASTERY[m].label} ${counts[m] || 0}</span>`).join('')}</div>`;
const pill = (text, color = '#8e8e93') => `<span class="pill" style="color:${color};background:${color}22">${esc(text)}</span>`;
const genderColor = (g) => (g === 'f' ? '#ff375f' : '#0a84ff');
function ring(progress, size = 104, stroke = 12) {
  const r = (size - stroke) / 2; const c = 2 * Math.PI * r; const p = Math.max(0.001, Math.min(1, progress));
  return `<svg width="${size}" height="${size}"><defs><linearGradient id="rg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0d8c80"/><stop offset="1" stop-color="#21c7a8"/></linearGradient></defs>
    <circle cx="${size / 2}" cy="${size / 2}" r="${r}" fill="none" stroke="var(--fill)" stroke-width="${stroke}"/>
    <circle cx="${size / 2}" cy="${size / 2}" r="${r}" fill="none" stroke="url(#rg)" stroke-width="${stroke}" stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="${c * (1 - p)}" style="transition:stroke-dashoffset .6s"/></svg>`;
}
const charbar = (target) => `<div class="charbar" data-target="${target}">${KU_CHARS.map((ch) => `<button type="button" data-char="${ch}">${ch}</button>`).join('')}<button type="button" data-shift>⇧</button></div>`;
function itemLabel(item) {
  const c = cardById(item.cardID); if (!c) return ['', ''];
  return item.form ? [`${c.kurdish} · ${FORM_LABEL[item.form]}`, cardForm(c, item.form)] : [c.kurdish, c.german];
}

// ---------- Ansichten ----------
function render() {
  const view = { home: viewHome, folders: viewFolders, stats: viewStats, grammar: viewGrammar, settings: viewSettings }[ui.tab];
  $('#app').innerHTML = view();
  renderTabbar();
}
function renderTabbar() {
  const tabs = [['home', '☀️', 'Heute'], ['folders', '📂', 'Ordner'], ['stats', '📊', 'Statistik'], ['grammar', '📖', 'Grammatik'], ['settings', '⚙️', 'Mehr']];
  $('#tabbar').innerHTML = tabs.map(([k, i, l]) => `<button data-act="tab" data-id="${k}" class="${ui.tab === k ? 'on' : ''}"><span class="ti">${i}</span>${l}</button>`).join('');
}

function viewHome() {
  const h = new Date().getHours();
  const greet = h < 11 ? 'Rojbaş ☀️' : h < 18 ? 'Silav 👋' : 'Êvarbaş 🌙';
  const t = todayStat(); const goal = Math.max(1, db.settings.dailyGoal); const prog = t.reviews / goal;
  const due = dueCount(db.cards); const st = streak();
  const hard = hardItems(db.cards).sort(byDifficulty).slice(0, 5);
  let wotd = '';
  if (db.cards.length) {
    const sorted = db.cards.slice().sort((a, b) => a.createdAt - b.createdAt);
    const c = sorted[Math.floor(Date.now() / 86400000) % sorted.length];
    wotd = `<div class="card wotd stack" style="gap:6px">
      <div class="row"><span class="small bold" style="opacity:.9">✨ Wort des Tages</span><span class="grow"></span><span class="tiny semi" style="opacity:.85">${WORD_TYPES[c.type]}</span></div>
      <div class="big">${esc(c.kurdish)}</div><div style="font-size:20px;opacity:.92">${esc(c.german)}</div>
      ${c.exampleKu ? `<div class="small" style="opacity:.85">„${esc(c.exampleKu)}“ – ${esc(c.exampleDe)}</div>` : ''}</div>`;
  }
  const tile = (title, icon, grad, count, act) => `<button class="card tile" data-act="${act}">
      <div class="row" style="width:100%"><span class="ic" style="background:${grad}">${icon}</span><span class="grow"></span>${count != null ? `<span class="small bold muted">${count}</span>` : ''}</div>
      <span class="semi small">${title}</span></button>`;
  return `<div class="header"><div><div class="sub">${new Date().toLocaleDateString('de-DE', { weekday: 'long', day: 'numeric', month: 'long' })}</div><h1>${greet}</h1></div></div>
  <div class="stack">
    <div class="card row" style="gap:20px;padding:20px">
      <div class="ring">${ring(prog)}<div class="ring-label"><div><div style="font-size:28px;font-weight:800">${t.reviews}</div><div class="tiny muted">von ${goal}</div></div></div></div>
      <div class="stack grow" style="gap:8px">
        <div class="bold">${prog >= 1 ? 'Tagesziel erreicht! 🎉' : 'Tagesziel'}</div>
        <div class="small semi">🔥 ${plural(st, 'Tag', 'Tage')} in Folge</div>
        <div class="small muted">🕑 ${due} fällig · ${newCount(db.cards)} neu</div>
      </div>
    </div>
    <button class="btn" data-act="quick" data-id="smart">▶︎ Jetzt lernen ${due ? `<span class="badge">${due}</span>` : ''}</button>
    <div class="grid3">
      ${tile('Schwierige<br>Wörter', '🔥', GRADIENT.hard, hardItems(db.cards).length, 'quick" data-id="hard')}
      ${tile('Verb-<br>Trainer', '⚡️', GRADIENT.verb, verbItems(db.cards).length, 'quick" data-id="verbs')}
      ${tile('Optionen<br>wählen', '🎛️', GRADIENT.sun, null, 'learn-setup')}
    </div>
    ${wotd}
    ${hard.length ? `<div class="card stack" style="gap:10px"><div class="bold">Fällt dir noch schwer</div>
      ${hard.map((i) => { const [a, b] = itemLabel(i); const s = stateOf(keyOf(i));
        return `<div class="row"><i class="dot" style="background:${MASTERY.hard.color}"></i><div class="grow"><div class="semi small">${esc(a)}</div><div class="tiny muted">${esc(b)}</div></div><span class="small muted">${s.wrong}× falsch</span></div>`; }).join('')}
    </div>` : ''}
  </div>`;
}

function folderRow(f) {
  const all = allCards(f.id); const subs = children(f.id).length; const due = dueCount(all);
  const parts = [plural(all.length, 'Wort', 'Wörter')];
  if (subs) parts.push(`${subs} Unterordner`);
  if ((f.linkedIDs || []).length) parts.push(`Sammlung aus ${f.linkedIDs.length}`);
  return `<button class="list-item" data-act="open-folder" data-id="${f.id}">
    ${folderIcon(f)}
    <div class="grow stack" style="gap:5px">
      <div class="row" style="gap:8px"><span class="semi ellipsis grow">${esc(f.name)}</span>${due ? `<span class="pill" style="background:var(--brand);color:#fff">${due} fällig</span>` : ''}</div>
      <div class="small muted">${parts.join(' · ')}</div>
      ${all.length ? mbar(masteryCounts(all)) : ''}
    </div><span class="chev">›</span></button>`;
}
function cardRow(c, showFolder = false) {
  const m = cardMastery(c); const f = showFolder ? folderById(c.folderID) : null;
  const n = filledForms(c).length;
  return `<button class="list-item" data-act="edit-card" data-id="${c.id}">
    <i class="dot" style="background:${MASTERY[m].color};width:10px;height:10px"></i>
    <div class="grow">
      <div class="semi">${esc(c.kurdish)} ${c.gender !== 'none' && c.type === 'noun' ? `<span class="tiny bold" style="color:${genderColor(c.gender)}">${c.gender}</span>` : ''}</div>
      <div class="small muted">${esc(c.german)}</div>
      ${f ? `<div class="tiny faint">${esc(f.emoji)} ${esc(f.name)}</div>` : ''}
    </div>
    ${n ? pill(`${n} Formen`, '#af52de') : `<span class="faint small">${TYPE_ICON[c.type] || ''}</span>`}
  </button>`;
}

function viewFolders() {
  if (ui.folder && folderById(ui.folder)) return viewFolderDetail(folderById(ui.folder));
  ui.folder = null;
  return `<div class="header"><h1>Ordner</h1><button class="icon-btn" data-act="folders-menu">＋</button></div>
    <div class="search"><input id="search" type="search" placeholder="Wörter suchen (Kurdisch oder Deutsch)" value="${esc(ui.search)}" autocomplete="off" autocorrect="off" spellcheck="false"></div>
    <div id="folder-results">${folderResults()}</div>`;
}
function folderResults() {
  const roots = children(null);
  let body;
  if (trim(ui.search)) {
    const q = fold(trim(ui.search));
    const res = db.cards.filter((c) => fold(c.kurdish).includes(q) || fold(c.german).includes(q));
    body = res.length ? `<div class="section-title">${res.length} Treffer</div><div class="list">${res.map((c) => cardRow(c, true)).join('')}</div>`
      : `<div class="empty"><div class="big">🔍</div>Keine Treffer für „${esc(ui.search)}“</div>`;
  } else if (!roots.length) {
    body = `<div class="empty"><div class="big">📂</div><div class="bold" style="color:var(--text)">Noch keine Ordner</div><p>Erstelle deinen ersten Ordner, z. B. „Essen“ oder „Verben“.</p><button class="btn" data-act="new-folder">Ordner erstellen</button></div>`;
  } else {
    body = `<div class="list">${roots.map(folderRow).join('')}</div>
      <div class="footnote">Tipp: Über ＋ → „Zusammenfügen“ machst du aus mehreren Ordnern einen neuen.</div>`;
  }
  return body;
}

function viewFolderDetail(f) {
  const all = allCards(f.id); const direct = directCards(f.id); const subs = children(f.id);
  const linked = (f.linkedIDs || []).map(folderById).filter(Boolean);
  const counts = masteryCounts(all); const path = pathTo(f.id).slice(0, -1);
  return `<div class="navbar"><button class="back" data-act="back">‹ ${esc(path.length ? path[path.length - 1].name : 'Ordner')}</button><span class="spacer"></span>
      <button class="icon-btn" data-act="folder-menu" data-id="${f.id}">•••</button></div>
    <div class="card stack" style="margin-top:6px">
      <div class="row" style="gap:14px">${folderIcon(f, true)}
        <div class="grow">${path.length ? `<div class="tiny muted ellipsis">${path.map((p) => esc(p.name)).join(' › ')}</div>` : ''}
          <div style="font-size:24px;font-weight:800">${esc(f.name)}</div>
          <div class="small muted">${all.length} Wörter · ${dueCount(all)} fällig</div></div></div>
      ${all.length ? mbar(counts, true) + legend(counts) : ''}
      <div class="row" style="gap:10px"><button class="btn" data-act="learn-setup" data-id="${f.id}" ${all.length ? '' : 'disabled'}>▶︎ Lernen</button>
        <button class="btn soft" style="width:56px;flex:none" data-act="photo" data-id="${f.id}" aria-label="Wörter fotografieren">📷</button>
        <button class="btn soft" style="width:56px;flex:none" data-act="new-card" data-id="${f.id}">＋</button></div>
    </div>
    ${subs.length ? `<div class="section-title">Unterordner</div><div class="list">${subs.map(folderRow).join('')}</div>` : ''}
    ${linked.length ? `<div class="section-title">Verknüpfte Ordner</div><div class="list">${linked.map(folderRow).join('')}</div>
      <div class="footnote">Die Wörter dieser Ordner gehören auch zu dieser Sammlung. Der Lernfortschritt ist geteilt. Lösen über ••• → „Verknüpfungen lösen“.</div>` : ''}
    <div class="section-title">Wörter in diesem Ordner (${direct.length})</div>
    ${direct.length ? `<div class="list">${direct.map((c) => cardRow(c)).join('')}</div>`
      : `<div class="list"><button class="list-item link" data-act="new-card" data-id="${f.id}">＋ Erstes Wort hinzufügen</button></div>`}
    ${all.length > direct.length ? `<div class="footnote">+ ${all.length - direct.length} weitere Wörter aus Unter- und verknüpften Ordnern werden beim Lernen mit abgefragt.</div>` : ''}`;
}

function viewStats() {
  let reviews = 0, correct = 0;
  Object.values(db.log).forEach((s) => { reviews += s.reviews || 0; correct += s.correct || 0; });
  const acc = reviews ? Math.round((correct / reviews) * 100) : 0;
  const tomorrow = startOfDayRef() + 2 * DAY;
  const dueTomorrow = vocabItems(db.cards).filter((i) => { const s = stateOf(keyOf(i)); return s.seen > 0 && s.due < tomorrow; }).length;
  const tile = (v, l, i) => `<div class="card stack" style="gap:6px;padding:14px"><span>${i}</span><div style="font-size:24px;font-weight:800">${v}</div><div class="tiny muted">${l}</div></div>`;
  const days = Array.from({ length: 14 }, (_, k) => { const d = daysAgo(13 - k); const s = db.log[dayKey(d)] || { reviews: 0, correct: 0 }; return { d, s }; });
  const max = Math.max(5, ...days.map((x) => x.s.reviews));
  const bars = days.map(({ s }) => `<div class="b"><span style="height:${((s.reviews - s.correct) / max) * 100}%;background:var(--hard)"></span><span style="height:${(s.correct / max) * 100}%;background:var(--brand)"></span></div>`).join('');
  const xs = days.map(({ d }, k) => `<span>${k % 2 ? '' : `${d.getDate()}.${d.getMonth() + 1}.`}</span>`).join('');
  const counts = masteryCounts(db.cards); const total = db.cards.length || 1;
  let acc2 = 0;
  const conic = MASTERY_ORDER.map((m) => { const from = acc2; acc2 += ((counts[m] || 0) / total) * 360; return `${MASTERY[m].color} ${from}deg ${acc2}deg`; }).join(',');
  const hardest = hardItems(db.cards).sort(byDifficulty).slice(0, 10);
  const easiest = vocabItems(db.cards).filter((i) => { const s = stateOf(keyOf(i)); return s.seen > 0 && (s.firstEasy || (s.wrong === 0 && s.seen >= 2)); })
    .sort((a, b) => stateOf(keyOf(b)).seen - stateOf(keyOf(a)).seen).slice(0, 10);
  const list = (title, color, items) => items.length ? `<div class="card stack" style="gap:10px"><div class="bold" style="color:${color}">${title}</div>
    ${items.map((i) => { const [a, b] = itemLabel(i); const s = stateOf(keyOf(i)); return `<div class="row"><div class="grow"><div class="semi small">${esc(a)}</div><div class="tiny muted">${esc(b)}</div></div><span class="small muted">${s.correct}/${s.seen}</span></div>`; }).join('')}</div>` : '';
  return `<div class="header"><h1>Statistik</h1></div><div class="stack">
    <div class="grid2">${tile(streak(), 'Tage in Folge', '🔥')}${tile(db.cards.length, 'Wörter gesamt', '📚')}${tile(reviews, 'Abfragen gesamt', '✅')}${tile(acc + ' %', 'Trefferquote', '🎯')}${tile(todayStat().reviews, 'Heute geübt', '☀️')}${tile(dueTomorrow, 'Fällig bis morgen', '📅')}</div>
    <div class="card"><div class="bold" style="margin-bottom:8px">Letzte 14 Tage</div><div class="bars">${bars}</div><div class="bars-x">${xs}</div>
      <div class="legend" style="margin-top:8px"><span><i class="dot" style="background:var(--brand)"></i>Richtig</span><span><i class="dot" style="background:var(--hard)"></i>Falsch</span></div></div>
    <div class="card stack"><div class="bold">Wie gut sitzen deine Wörter?</div>
      ${db.cards.length ? `<div class="donut" style="background:conic-gradient(${conic})"><div class="lbl"><div><div style="font-size:28px;font-weight:800">${(counts.mastered || 0) + (counts.easy || 0)}</div><div class="tiny muted">sitzen gut</div></div></div></div>${legend(counts)}` : '<div class="muted">Noch keine Wörter vorhanden.</div>'}</div>
    ${list('🔥 Fällt dir schwer', MASTERY.hard.color, hardest)}
    ${list('⚡ Sofort gewusst', MASTERY.easy.color, easiest)}
  </div>`;
}

function viewGrammar() {
  if (ui.grammar != null) {
    const g = window.GRAMMAR[ui.grammar];
    const blocks = g.blocks.map(([k, v]) => {
      if (k === 't') return `<p class="gtext">${md(v)}</p>`;
      if (k === 'ul') return `<ul class="gbullets">${v.map((x) => `<li>${md(x)}</li>`).join('')}</ul>`;
      return `<div class="gtable" style="margin-bottom:14px">${v.map((r) => `<div class="gr">${r.map((c) => `<div>${md(c)}</div>`).join('')}</div>`).join('')}</div>`;
    }).join('');
    return `<div class="navbar"><button class="back" data-act="grammar-back">‹ Grammatik</button></div>
      <div style="font-size:54px;margin:6px 4px">${g.emoji}</div><h2 style="margin:0 4px 14px;font-size:26px">${esc(g.title)}</h2>${blocks}`;
  }
  return `<div class="header"><h1>Grammatik</h1></div>
    <div class="list">${window.GRAMMAR.map((g, i) => `<button class="list-item" data-act="grammar" data-id="${i}">
      <span class="folder-icon" style="background:color-mix(in srgb,var(--brand) 14%,transparent)">${g.emoji}</span><span class="grow semi">${esc(g.title)}</span><span class="chev">›</span></button>`).join('')}</div>
    <div class="footnote">Spickzettel für Kurmancî (Nordkurdisch).</div>`;
}

function viewSettings() {
  const s = db.settings;
  const stepper = (key, label, unit, min, max) => `<div class="stepper"><div><div class="semi">${label}</div><div class="small muted">${s[key]}${unit}</div></div>
    <div class="ctrl"><button data-act="step" data-id="${key}" data-d="-5" data-min="${min}" data-max="${max}">−</button><button data-act="step" data-id="${key}" data-d="5" data-min="${min}" data-max="${max}">＋</button></div></div>`;
  const standalone = window.matchMedia('(display-mode: standalone)').matches || navigator.standalone;
  return `<div class="header"><h1>Mehr</h1></div>
    ${standalone ? '' : `<div class="card stack" style="gap:8px;border:2px solid var(--brand)"><div class="bold">📲 Als App installieren</div>
      <div class="small">In Safari unten auf <b>Teilen</b> (Quadrat mit Pfeil) tippen → <b>„Zum Home-Bildschirm“</b>. Dann startet Ferheng wie eine richtige App – im Vollbild und offline.</div></div>`}
    <div class="section-title">Lernziele</div>
    <div class="stack" style="gap:8px">${stepper('dailyGoal', 'Tagesziel', ' Abfragen', 5, 300)}${stepper('newPerDay', 'Neue Wörter pro Tag', '', 0, 100)}${stepper('sessionSize', 'Abfragen pro Runde', '', 5, 100)}</div>
    <div class="footnote">Weniger neue Wörter pro Tag = weniger Stress bei den Wiederholungen. 10 ist ein guter Startwert.</div>
    <div class="section-title">Standard beim Lernen</div>
    <div class="card stack" style="gap:10px">
      <div class="small semi muted">Abfrageart</div>
      <div class="segmented">${Object.entries(QUIZ).map(([k, [l]]) => `<button data-act="set" data-id="quizKind" data-v="${k}" class="${s.quizKind === k ? 'on' : ''}">${l}</button>`).join('')}</div>
      <div class="small semi muted">Richtung</div>
      <div class="segmented">${[['kuToDe', 'KU → DE'], ['deToKu', 'DE → KU'], ['mixed', 'Gemischt']].map(([k, l]) => `<button data-act="set" data-id="direction" data-v="${k}" class="${s.direction === k ? 'on' : ''}">${l}</button>`).join('')}</div>
    </div>
    <div class="section-title">Daten</div>
    <div class="list">
      <button class="list-item" data-act="export">📤 <span class="grow">Backup erstellen</span></button>
      <button class="list-item" data-act="import">📥 <span class="grow">Backup wiederherstellen</span></button>
      <button class="list-item" data-act="starter">✨ <span class="grow">Beispielvokabeln hinzufügen</span></button>
      <button class="list-item" data-act="reset" style="color:var(--hard)">🗑️ <span class="grow">Alle Daten löschen</span></button>
    </div>
    <div class="footnote">Deine Daten liegen nur auf diesem Gerät. Backups sind mit der iPhone-App (SideStore-Version) austauschbar – so kannst du jederzeit wechseln.</div>
    <input type="file" id="import-file" accept="application/json,.json" hidden>
    <div class="section-title">Info</div>
    <div class="list"><div class="list-item"><span class="grow">Version</span><span class="muted">Web ${window.FERHENG_VERSION || ''}</span></div>
      <div class="list-item"><span class="grow">Sprache</span><span class="muted">Kurmancî ↔ Deutsch</span></div></div>
    <div class="footnote">„Ferheng“ heißt auf Kurdisch „Wörterbuch“.</div>`;
}

// ---------- Sheets (Dialoge) ----------
function openSheet({ title, body, primary, onPrimary, cancel = 'Abbrechen', onMount }) {
  closeSheet();
  const root = $('#sheet-root');
  root.innerHTML = `<div class="backdrop" data-act="close-sheet"></div>
    <div class="sheet" role="dialog"><div class="sheet-head"><button data-act="close-sheet">${cancel}</button><h2>${esc(title)}</h2>
      ${primary ? `<button class="primary" id="sheet-primary">${esc(primary)}</button>` : '<button style="visibility:hidden">.</button>'}</div>
      <div class="sheet-body">${body}</div></div>`;
  if (primary) $('#sheet-primary').onclick = onPrimary;
  if (onMount) onMount($('.sheet', root));
}
function closeSheet() { $('#sheet-root').innerHTML = ''; }
function confirmSheet(title, text, label, onYes, danger = true) {
  openSheet({ title, body: `<p class="center muted" style="margin:8px 8px 18px">${esc(text)}</p>
    <button class="btn ${danger ? 'hard' : ''}" id="confirm-yes">${esc(label)}</button>`,
  onMount: () => { $('#confirm-yes').onclick = () => { closeSheet(); onYes(); }; } });
}
function menuSheet(title, items) {
  openSheet({ title, cancel: 'Schließen', body: `<div class="list">${items.map((it, i) => `<button class="list-item" data-menu="${i}" ${it.disabled ? 'disabled style="opacity:.4"' : ''} ${it.danger ? 'style="color:var(--hard)"' : ''}>${it.icon} <span class="grow">${esc(it.label)}</span></button>`).join('')}</div>`,
    onMount: (el) => $$('[data-menu]', el).forEach((b) => { b.onclick = () => { const it = items[+b.dataset.menu]; if (it.disabled) return; closeSheet(); it.run(); }; }) });
}
function folderOptions(selected) {
  return flatFolders().map(({ folder, depth }) => `<option value="${folder.id}" ${folder.id === selected ? 'selected' : ''}>${'   '.repeat(depth)}${esc(folder.emoji)} ${esc(folder.name)}</option>`).join('');
}

const EMOJIS = ['📁', '👋', '🔢', '👨‍👩‍👧', '🏠', '⚡️', '🍎', '🍞', '🎨', '🐑', '🌄', '☀️', '🗣️', '📚', '✈️', '💼', '🩺', '🎵', '⚽️', '❤️', '🕰️', '🌦️', '👕', '🚗'];
function folderEditor(folder, parentID) {
  let emoji = folder?.emoji || '📁'; let color = folder?.colorName || 'teal';
  const parent = folderById(parentID);
  openSheet({
    title: folder ? 'Ordner bearbeiten' : 'Neuer Ordner', primary: 'Sichern',
    body: `<div class="center" style="margin:6px 0 16px"><div id="fe-preview" style="display:inline-block"></div></div>
      <div class="field"><label>Name</label><input id="fe-name" placeholder="z. B. Essen & Trinken" value="${esc(folder?.name || '')}"></div>
      ${parent ? `<div class="field"><label>Liegt in</label><div class="card" style="padding:12px 14px">${esc(parent.emoji)} ${esc(parent.name)}</div></div>` : ''}
      <div class="field"><label>Symbol</label><div class="card"><div class="emoji-grid">${EMOJIS.map((e) => `<button type="button" data-emoji="${e}">${e}</button>`).join('')}</div>
        <input id="fe-emoji" style="margin-top:10px" placeholder="Eigenes Emoji" value="${esc(emoji)}"></div></div>
      <div class="field"><label>Farbe</label><div class="card"><div class="color-grid">${Object.entries(COLORS).map(([k, v]) => `<button type="button" data-color="${k}" style="background:${v}"></button>`).join('')}</div></div></div>`,
    onMount: (el) => {
      const upd = () => {
        $('#fe-preview').innerHTML = folderIcon({ emoji, colorName: color, linkedIDs: [] }, true);
        $$('[data-emoji]', el).forEach((b) => b.classList.toggle('on', b.dataset.emoji === emoji));
        $$('[data-color]', el).forEach((b) => { b.textContent = b.dataset.color === color ? '✓' : ''; });
      };
      $$('[data-emoji]', el).forEach((b) => { b.onclick = () => { emoji = b.dataset.emoji; $('#fe-emoji').value = emoji; upd(); }; });
      $$('[data-color]', el).forEach((b) => { b.onclick = () => { color = b.dataset.color; upd(); }; });
      $('#fe-emoji').oninput = (e) => { const v = firstGrapheme(e.target.value); if (v) { emoji = v; upd(); } };
      upd();
      if (!folder) setTimeout(() => $('#fe-name').focus(), 300);
    },
    onPrimary: () => {
      const name = trim($('#fe-name').value);
      if (!name) { $('#fe-name').classList.add('shake'); setTimeout(() => $('#fe-name').classList.remove('shake'), 400); return; }
      if (folder) { const f = folderById(folder.id); f.name = name; f.emoji = emoji; f.colorName = color; save(); }
      else addFolder(name, emoji, color, parentID);
      closeSheet(); render();
    }
  });
}

function cardEditor(card, isNew) {
  const d = JSON.parse(JSON.stringify(card)); let added = 0;
  const formsHTML = () => VERB_FORMS.map((f) => `<div class="field"><label>${f.label}</label><input data-form="${f.key}" class="ku" placeholder="${esc(f.hint)}" value="${esc(d.forms[f.key] || '')}" autocapitalize="off" autocorrect="off" spellcheck="false"></div>`).join('');
  const progressHTML = () => {
    if (isNew) return '';
    const s = stateOf(`c:${d.id}`); const m = mastery(s);
    return `<div class="section-title">Lernstand</div><div class="card stack" style="gap:8px">
      <div class="row"><span class="grow">Status</span>${pill(MASTERY[m].label, MASTERY[m].color)}</div>
      ${s.seen ? `<div class="row"><span class="grow">Abgefragt</span><span class="muted">${s.seen}×</span></div>
      <div class="row"><span class="grow">Richtig</span><span class="muted">${Math.round((s.correct / s.seen) * 100)} %</span></div>
      <div class="row"><span class="grow">Nächste Wiederholung</span><span class="muted">${s.due <= nowRef() ? 'jetzt' : refToDate(s.due).toLocaleDateString('de-DE')}</span></div>
      <button class="link" id="ce-reset" style="text-align:left">Lernstand zurücksetzen</button>` : ''}</div>
      <button class="btn danger" id="ce-delete" style="margin-top:16px">Wort löschen</button>`;
  };
  openSheet({
    title: isNew ? 'Neues Wort' : 'Wort bearbeiten', primary: 'Sichern',
    body: `<div id="ce-added" class="small center semi" style="color:var(--green)"></div>
      <div class="field"><label>Kurdisch</label><input id="ce-ku" class="ku" value="${esc(d.kurdish)}" autocapitalize="off" autocorrect="off" spellcheck="false" style="font-size:20px;font-weight:600"></div>
      <div class="field"><label>Deutsch</label><input id="ce-de" value="${esc(d.german)}" autocorrect="off" style="font-size:19px"></div>
      <div class="footnote" style="margin-top:-6px;margin-bottom:12px">Mehrere Bedeutungen mit „/“ trennen – beim Schreiben zählt jede davon als richtig.</div>
      <div id="ce-charbar" style="display:none;margin-bottom:12px">${charbar('focused')}</div>
      <div class="field"><label>Wortart</label><select id="ce-type">${Object.entries(WORD_TYPES).map(([k, v]) => `<option value="${k}" ${d.type === k ? 'selected' : ''}>${TYPE_ICON[k]} ${v}</option>`).join('')}</select></div>
      <div id="ce-noun"><div class="field"><label>Geschlecht</label><div class="segmented" id="ce-gender">${[['none', '–'], ['m', 'm'], ['f', 'f']].map(([k, l]) => `<button type="button" data-g="${k}" class="${d.gender === k ? 'on' : ''}">${l}</button>`).join('')}</div></div>
        <div class="field"><label>Plural (optional)</label><input id="ce-plural" class="ku" value="${esc(d.plural)}" autocapitalize="off" autocorrect="off"></div></div>
      <div id="ce-verb"><div class="section-title" style="margin-top:6px">Verbformen</div>
        <div class="field"><div class="segmented" id="ce-trans">${Object.entries(TRANS).map(([k, l]) => `<button type="button" data-t="${k}" class="${d.transitivity === k ? 'on' : ''}">${l}</button>`).join('')}</div></div>
        ${formsHTML()}<div class="footnote" style="margin:-4px 6px 12px">Jede ausgefüllte Form wird im Verb-Trainer einzeln abgefragt.</div></div>
      <div class="field"><label>Beispielsatz (Kurdisch)</label><input id="ce-exku" class="ku" value="${esc(d.exampleKu)}" autocorrect="off"></div>
      <div class="field"><label>Beispielsatz (Deutsch)</label><input id="ce-exde" value="${esc(d.exampleDe)}"></div>
      <div class="field"><label>Eselsbrücke / Notiz</label><input id="ce-note" value="${esc(d.note)}" placeholder="z. B. „av“ klingt wie „Aqua“"></div>
      <div class="field"><label>Ordner</label><select id="ce-folder">${folderOptions(d.folderID)}</select></div>
      ${isNew ? '<button class="btn soft" id="ce-next">Sichern & nächstes Wort</button>' : ''}
      ${progressHTML()}`,
    onMount: (el) => {
      const toggle = () => { $('#ce-noun').style.display = $('#ce-type').value === 'noun' ? '' : 'none'; $('#ce-verb').style.display = $('#ce-type').value === 'verb' ? '' : 'none'; };
      $('#ce-type').onchange = toggle; toggle();
      $$('#ce-gender button', el).forEach((b) => { b.onclick = () => { d.gender = b.dataset.g; $$('#ce-gender button', el).forEach((x) => x.classList.toggle('on', x === b)); }; });
      $$('#ce-trans button', el).forEach((b) => { b.onclick = () => { d.transitivity = b.dataset.t; $$('#ce-trans button', el).forEach((x) => x.classList.toggle('on', x === b)); }; });
      // Sonderzeichen-Leiste erscheint bei kurdischen Feldern
      let lastKu = $('#ce-ku');
      el.addEventListener('focusin', (e) => { if (e.target.classList?.contains('ku')) { lastKu = e.target; $('#ce-charbar').style.display = ''; } });
      $('#ce-charbar').querySelector('.charbar').__getInput = () => lastKu;
      if ($('#ce-reset')) $('#ce-reset').onclick = () => { removeProgress(d.id); save(); toast('Lernstand zurückgesetzt'); closeSheet(); render(); };
      if ($('#ce-delete')) $('#ce-delete').onclick = () => confirmSheet('Wort löschen?', `„${d.kurdish}“ wird gelöscht.`, 'Löschen', () => { deleteCard(d.id); render(); });
      if ($('#ce-next')) $('#ce-next').onclick = () => doSave(true);
      if (isNew) setTimeout(() => $('#ce-ku').focus(), 300);
    },
    onPrimary: () => doSave(false)
  });
  function doSave(next) {
    const ku = trim($('#ce-ku').value); const de = trim($('#ce-de').value);
    if (!ku || !de) { (ku ? $('#ce-de') : $('#ce-ku')).classList.add('shake'); setTimeout(() => $$('.shake').forEach((x) => x.classList.remove('shake')), 400); return; }
    const c = Object.assign({}, d, {
      kurdish: ku, german: de, type: $('#ce-type').value, folderID: $('#ce-folder').value,
      plural: trim($('#ce-plural').value), exampleKu: trim($('#ce-exku').value), exampleDe: trim($('#ce-exde').value), note: trim($('#ce-note').value), forms: {}
    });
    $$('[data-form]').forEach((i) => { if (trim(i.value)) c.forms[i.dataset.form] = trim(i.value); });
    if (c.type !== 'verb') { c.forms = {}; c.transitivity = 'unknown'; }
    if (c.type !== 'noun') { c.gender = 'none'; c.plural = ''; }
    upsertCard(c);
    if (next) {
      added++;
      const fresh = newCard(c.folderID); fresh.type = c.type;
      Object.assign(d, fresh);
      ['#ce-ku', '#ce-de', '#ce-plural', '#ce-exku', '#ce-exde', '#ce-note'].forEach((s) => { $(s).value = ''; });
      $$('[data-form]').forEach((i) => { i.value = ''; });
      $('#ce-added').textContent = `✓ ${plural(added, 'Wort', 'Wörter')} hinzugefügt`;
      $('#ce-ku').focus(); render();
    } else { closeSheet(); render(); }
  }
}


// ---------- Foto-Import (Texterkennung auf dem Gerät) ----------
const TESSERACT_URL = 'https://cdn.jsdelivr.net/npm/tesseract.js@5.1.1/dist/tesseract.min.js';
let ocrWorker = null;
function loadScript(src) {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`script[src="${src}"]`)) return resolve();
    const el = document.createElement('script'); el.src = src; el.onload = resolve; el.onerror = () => reject(new Error('Script konnte nicht geladen werden'));
    document.head.appendChild(el);
  });
}
async function getOcrWorker(onProgress) {
  if (ocrWorker) return ocrWorker;
  await loadScript(TESSERACT_URL);
  // Kurmancî (kmr) + Deutsch (deu). Sprachdaten werden einmal geladen und dann im Browser gespeichert.
  ocrWorker = await Tesseract.createWorker(['kmr', 'deu'], 1, { logger: (m) => ocrWorker && ocrWorker.__onProgress && ocrWorker.__onProgress(m) });
  return ocrWorker;
}
function fileToCanvas(file) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      const max = 2200; const scale = Math.min(1, max / Math.max(img.naturalWidth, img.naturalHeight));
      const c = document.createElement('canvas');
      c.width = Math.round(img.naturalWidth * scale); c.height = Math.round(img.naturalHeight * scale);
      const ctx = c.getContext('2d');
      ctx.filter = 'grayscale(1) contrast(1.25)';
      ctx.drawImage(img, 0, 0, c.width, c.height);
      URL.revokeObjectURL(img.src);
      resolve(c);
    };
    img.onerror = () => reject(new Error('Bild konnte nicht geöffnet werden'));
    img.src = URL.createObjectURL(file);
  });
}

// Wörter mit Position → Zeilen → Wortpaare (links | rechts).
const SEP_TOKEN = /^[-–—=:;|>→]+$/;
function median(arr) { const a = arr.slice().sort((x, y) => x - y); return a.length ? a[Math.floor(a.length / 2)] : 0; }
function parseOcrWords(words) {
  const ws = words.map((w) => ({ text: trim(w.text), x0: w.x0, x1: w.x1, y0: w.y0, y1: w.y1, yc: (w.y0 + w.y1) / 2, xc: (w.x0 + w.x1) / 2 }))
    .filter((w) => w.text && !/^[|_~•·*©®°^`´'"]+$/.test(w.text));
  if (!ws.length) return [];
  const h = median(ws.map((w) => w.y1 - w.y0)) || 10;
  // 1) Wörter zu Zeilen gruppieren
  ws.sort((a, b) => a.yc - b.yc);
  let rows = [];
  for (const w of ws) {
    const row = rows.find((r) => Math.abs(r.yc - w.yc) < h * 0.7);
    if (row) { row.words.push(w); row.yc = (row.yc * (row.words.length - 1) + w.yc) / row.words.length; }
    else rows.push({ yc: w.yc, words: [w] });
  }
  rows.sort((a, b) => a.yc - b.yc);
  rows.forEach((r) => { r.words.sort((a, b) => a.x0 - b.x0); r.h = Math.max(...r.words.map((w) => w.y1 - w.y0)); });
  const rowH = median(rows.map((r) => r.h));
  const HEADING_WORDS = /\b(lektion|kapitel|seite|übung|wortschatz|vokabeln?|ders|beş|rûpel|peyv|ferheng|unit|lesson)\b/i;

  // 2) Gemeinsame Spaltengrenze der Seite finden (Mitte der großen Lücken)
  const splits = [];
  rows.forEach((r) => {
    for (let i = 0; i < r.words.length - 1; i++) {
      const g = r.words[i + 1].x0 - r.words[i].x1;
      if (g > h * 1.6) splits.push((r.words[i].x1 + r.words[i + 1].x0) / 2);
    }
  });
  const colX = splits.length >= 2 && splits.length >= rows.length * 0.25 ? median(splits) : null;

  // 3) Jede Zeile in links/rechts aufteilen
  let pairs = rows.map((r) => {
    const wsr = r.words;
    const joined = wsr.map((w) => w.text).join(' ');
    const bigOrTitle = r.h > rowH * 1.6 || HEADING_WORDS.test(joined);
    const sepIdx = wsr.findIndex((w, i) => i > 0 && i < wsr.length - 1 && SEP_TOKEN.test(w.text));
    let left; let right;
    if (sepIdx > 0) { left = wsr.slice(0, sepIdx); right = wsr.slice(sepIdx + 1); }
    else if (/[=;]|\s[-–—]\s/.test(joined) && splitLine(joined)) {
      const [a, b] = splitLine(joined); return markHeading(cleanPair(a, b), r.yc, bigOrTitle);
    } else if (colX != null) { left = wsr.filter((w) => w.xc < colX); right = wsr.filter((w) => w.xc >= colX); }
    else {
      let best = -1; let gap = -Infinity;
      for (let i = 0; i < wsr.length - 1; i++) { const g = wsr[i + 1].x0 - wsr[i].x1; if (g > gap) { gap = g; best = i; } }
      if (best >= 0 && gap > h * 1.6) { left = wsr.slice(0, best + 1); right = wsr.slice(best + 1); } else { left = wsr; right = []; }
    }
    return markHeading(cleanPair(left.map((w) => w.text).join(' '), right.map((w) => w.text).join(' ')), r.yc, bigOrTitle);
  });

  // 4) Halbe Zeilen zusammenführen (z. B. bei schief fotografierten Seiten)
  for (let i = 0; i < pairs.length - 1; i++) {
    const a = pairs[i]; const b = pairs[i + 1];
    if (Math.abs(b.yc - a.yc) > h * 1.4) continue;
    if (a.ku && !a.de && b.de && !b.ku) { a.de = b.de; b.ku = ''; b.de = ''; }
    else if (a.de && !a.ku && b.ku && !b.de) { a.ku = b.ku; b.ku = ''; b.de = ''; }
  }
  return pairs.filter((p) => p.ku || p.de).map((p) => ({ ku: p.ku, de: p.de, on: !!(p.ku && p.de) && !p.heading }));
}
// Überschriften (große Schrift, „Lektion 3“, Seitenzahlen …) werden vorgeschlagen, aber nicht vorausgewählt.
const markHeading = (p, yc, bigOrTitle) => Object.assign(p, { yc, heading: bigOrTitle || /\d/.test(p.ku + p.de) });
function cleanPair(a, b) {
  const strip = (s) => trim(String(s).replace(/^\s*(\d+[.)]|[a-z][.)]|[-–—•·*])\s+/i, '').replace(/^[-–—=:;|]+|[-–—=:;|,]+$/g, ''));
  const ku = strip(a); const de = strip(b);
  return { ku, de, on: !!(ku && de) };
}
// Erkennt, ob die Spalten vertauscht sind (Deutsch links, Kurdisch rechts).
function looksSwapped(pairs) {
  const ku = (s) => (s.match(/[êîûçşÊÎÛÇŞ]/g) || []).length;
  const de = (s) => (s.match(/[äöüßÄÖÜ]|sch|ch(?!a)|ei|ie|tz/g) || []).length + (/^(der|die|das|ein|eine|sich)\s/i.test(s) ? 2 : 0);
  let left = 0; let right = 0;
  pairs.forEach((p) => { left += ku(p.ku) - de(p.ku); right += ku(p.de) - de(p.de); });
  return right > left;
}

function photoSheet(folderID) {
  if (!db.folders.length) { toast('Erstelle zuerst einen Ordner'); return; }
  openSheet({
    title: 'Wörter fotografieren',
    body: `<div class="stack" style="align-items:center;text-align:center;gap:16px;padding:10px 4px">
        <div class="sun-badge" style="width:96px;height:96px;font-size:48px;background:linear-gradient(135deg,var(--brand),var(--brand-2));box-shadow:0 10px 30px rgba(13,140,128,.35)">📷</div>
        <div class="muted">Fotografiere eine Vokabelliste – z. B. aus deinem Lernbuch. Am besten gerade von oben, gut beleuchtet, eine Spalte Kurdisch und eine Spalte Deutsch.</div>
        <label class="btn" for="photo-input" id="photo-pick">📸 Foto aufnehmen oder auswählen</label>
        <input type="file" id="photo-input" accept="image/*" hidden>
        <div id="photo-status" class="stack" style="width:100%;gap:8px;display:none">
          <img id="photo-preview" style="width:100%;max-height:240px;object-fit:contain;border-radius:14px;background:var(--card)">
          <div class="small semi" id="photo-msg">Text wird erkannt …</div>
          <div class="progress"><span id="photo-bar" style="width:3%"></span></div>
        </div>
        <div class="footnote">Die Erkennung läuft direkt auf deinem Handy – das Foto wird nirgendwo hochgeladen. Dafür wird eine Internetverbindung gebraucht; beim ersten Mal werden ca. 5 MB Sprachdaten geladen.</div>
      </div>`,
    onMount: () => {
      $('#photo-input').onchange = async (e) => {
        const file = e.target.files[0]; if (!file) return;
        $('#photo-pick').style.display = 'none';
        $('#photo-status').style.display = '';
        $('#photo-preview').src = URL.createObjectURL(file);
        const setP = (msg, p) => { if ($('#photo-msg')) { $('#photo-msg').textContent = msg; $('#photo-bar').style.width = `${Math.max(3, p * 100)}%`; } };
        try {
          setP('Texterkennung wird vorbereitet …', 0.05);
          const worker = await getOcrWorker();
          worker.__onProgress = (m) => {
            if (m.status === 'recognizing text') setP(`Text wird erkannt … ${Math.round(m.progress * 100)} %`, 0.3 + m.progress * 0.7);
            else if (/load/.test(m.status)) setP('Sprachdaten werden geladen …', 0.05 + (m.progress || 0) * 0.25);
          };
          const canvas = await fileToCanvas(file);
          const { data } = await worker.recognize(canvas);
          const words = (data.words || []).filter((w) => w.confidence > 20).map((w) => ({ text: w.text, ...w.bbox }));
          let pairs = parseOcrWords(words);
          if (looksSwapped(pairs)) pairs = pairs.map((p) => ({ ku: p.de, de: p.ku, on: p.on }));
          if (!pairs.length) { setP('Keine Wörter erkannt. Versuch es mit einem schärferen, geraden Foto.', 1); $('#photo-pick').style.display = ''; return; }
          reviewSheet(pairs, folderID);
        } catch (err) {
          console.error(err);
          setP(navigator.onLine ? 'Die Texterkennung ist fehlgeschlagen. Bitte versuch es nochmal.' : 'Für die Texterkennung wird eine Internetverbindung benötigt.', 1);
          $('#photo-pick').style.display = '';
        }
        e.target.value = '';
      };
    }
  });
}

function reviewSheet(pairs, folderID) {
  const rows = pairs.map((p) => Object.assign({}, p));
  const count = () => rows.filter((r) => r.on && trim(r.ku) && trim(r.de)).length;
  openSheet({
    title: 'Erkannte Wörter', primary: 'Einfügen',
    body: `<div class="footnote" style="margin:0 4px 10px">Prüfe die Wörter, korrigiere Fehler und wähle aus, was übernommen werden soll. Erst mit „Einfügen“ wird gespeichert.</div>
      <div class="row" style="gap:8px;margin-bottom:10px">
        <button class="btn soft" id="rv-swap" style="padding:11px">⇄ Spalten tauschen</button>
        <button class="btn gray" id="rv-all" style="padding:11px">Alle an/aus</button>
      </div>
      <div class="row tiny semi muted" style="padding:0 12px 6px 46px"><span class="grow">Kurdisch</span><span class="grow">Deutsch</span></div>
      <div class="list" id="rv-list"></div>
      <button class="link small" id="rv-add" style="margin:10px 6px">＋ Zeile hinzufügen</button>
      <div id="rv-charbar">${charbar('focused')}</div>
      <div class="field" style="margin-top:14px"><label>In Ordner</label><select id="rv-folder">${folderOptions(folderID || flatFolders()[0].folder.id)}</select></div>
      <div class="field"><label>Wortart</label><select id="rv-type">${Object.entries(WORD_TYPES).map(([k, v]) => `<option value="${k}" ${k === 'other' ? 'selected' : ''}>${v}</option>`).join('')}</select></div>`,
    onMount: (el) => {
      let lastKu = null;
      $('#rv-charbar .charbar').__getInput = () => lastKu;
      const draw = () => {
        $('#rv-list').innerHTML = rows.map((r, i) => `<div class="list-item" style="gap:8px;padding:8px 10px">
            <button class="radio ${r.on ? 'on' : ''}" data-rv-toggle="${i}" aria-label="Übernehmen"></button>
            <input class="ku" data-rv="${i}" data-f="ku" value="${esc(r.ku)}" autocapitalize="off" autocorrect="off" spellcheck="false" style="padding:9px 10px;font-size:16px">
            <input data-rv="${i}" data-f="de" value="${esc(r.de)}" autocorrect="off" style="padding:9px 10px;font-size:16px">
          </div>`).join('') || '<div class="list-item muted">Keine Zeilen</div>';
        $('#sheet-primary').textContent = `${count()} einfügen`;
        $('#sheet-primary').disabled = !count();
      };
      el.addEventListener('input', (e) => {
        const i = e.target.dataset.rv; if (i == null) return;
        rows[+i][e.target.dataset.f] = e.target.value;
        if (trim(rows[+i].ku) && trim(rows[+i].de)) rows[+i].on = true;
        $(`[data-rv-toggle="${i}"]`).classList.toggle('on', rows[+i].on);
        $('#sheet-primary').textContent = `${count()} einfügen`; $('#sheet-primary').disabled = !count();
      });
      el.addEventListener('focusin', (e) => { if (e.target.dataset?.f === 'ku') lastKu = e.target; });
      el.addEventListener('click', (e) => {
        const t = e.target.closest('[data-rv-toggle]'); if (!t) return;
        const r = rows[+t.dataset.rvToggle]; r.on = !r.on; t.classList.toggle('on', r.on);
        $('#sheet-primary').textContent = `${count()} einfügen`; $('#sheet-primary').disabled = !count();
      });
      $('#rv-swap').onclick = () => { rows.forEach((r) => { [r.ku, r.de] = [r.de, r.ku]; }); draw(); };
      $('#rv-all').onclick = () => { const all = rows.every((r) => r.on); rows.forEach((r) => { r.on = !all; }); draw(); };
      $('#rv-add').onclick = () => { rows.push({ ku: '', de: '', on: false }); draw(); $(`[data-rv="${rows.length - 1}"]`).focus(); };
      draw();
    },
    onPrimary: () => {
      const fid = $('#rv-folder').value; const type = $('#rv-type').value; let n = 0;
      rows.filter((r) => r.on && trim(r.ku) && trim(r.de)).forEach((r) => {
        const c = newCard(fid); c.kurdish = trim(r.ku); c.german = trim(r.de); c.type = type; db.cards.push(c); n++;
      });
      save(); closeSheet(); toast(`✓ ${plural(n, 'Wort', 'Wörter')} eingefügt`);
      ui.tab = 'folders'; ui.folder = fid; render();
    }
  });
}

function bulkSheet(folderID) {
  if (!db.folders.length) { toast('Erstelle zuerst einen Ordner'); return; }
  openSheet({
    title: 'Mehrere Wörter', primary: 'Hinzufügen',
    body: `<div class="field"><label>Ordner</label><select id="bk-folder">${folderOptions(folderID || flatFolders()[0].folder.id)}</select></div>
      <div class="field"><label>Wortart</label><select id="bk-type">${Object.entries(WORD_TYPES).map(([k, v]) => `<option value="${k}" ${k === 'other' ? 'selected' : ''}>${v}</option>`).join('')}</select></div>
      <div class="field"><label>Ein Wort pro Zeile</label><textarea id="bk-text" class="ku" rows="9" placeholder="av = Wasser&#10;nan = Brot&#10;mal = Haus" autocapitalize="off" autocorrect="off" spellcheck="false"></textarea>${charbar('bk-text')}</div>
      <div class="footnote" id="bk-count">Format: Kurdisch = Deutsch. Auch „;“, „-“ oder Tabulator funktionieren.</div>`,
    onMount: () => {
      $('#bk-text').oninput = () => {
        const n = $('#bk-text').value.split(/\r?\n/).filter((l) => splitLine(trim(l))).length;
        $('#sheet-primary').textContent = n ? `${n} hinzufügen` : 'Hinzufügen';
      };
    },
    onPrimary: () => {
      const n = bulkAdd($('#bk-text').value, $('#bk-folder').value, $('#bk-type').value);
      if (!n) { toast('Keine gültigen Zeilen gefunden'); return; }
      closeSheet(); toast(`✓ ${plural(n, 'Wort', 'Wörter')} hinzugefügt`); render();
    }
  });
}

function mergeSheet(parentID, preselected = []) {
  const sel = new Set(preselected); let mode = 'link';
  const explain = { link: 'Neuer Sammel-Ordner, der die Wörter der ausgewählten Ordner enthält. Die Originale bleiben bestehen, der Lernfortschritt ist geteilt.', combine: 'Alle Wörter und Unterordner werden in den neuen Ordner verschoben. Die ausgewählten Ordner werden danach entfernt.' };
  openSheet({
    title: 'Zusammenfügen', primary: 'Erstellen',
    body: `<div class="section-title" id="mg-count" style="margin-top:4px"></div>
      <div class="list">${flatFolders().map(({ folder, depth }) => `<button class="list-item" data-sel="${folder.id}" style="padding-left:${16 + depth * 18}px">
        <span class="radio"></span><span>${esc(folder.emoji)}</span><span class="grow">${esc(folder.name)}</span><span class="small muted">${allCards(folder.id).length}</span></button>`).join('')}</div>
      <div class="section-title">Neuer Ordner</div>
      <div class="row" style="gap:8px"><input id="mg-emoji" value="🗂️" style="width:60px;text-align:center"><input id="mg-name" placeholder="Name, z. B. „Prüfung Mai“"></div>
      <div class="section-title">Art</div>
      <div class="segmented" id="mg-mode"><button data-m="link" class="on">Verknüpfen</button><button data-m="combine">Zusammenführen</button></div>
      <div class="footnote" id="mg-explain">${explain.link}</div>`,
    onMount: (el) => {
      const upd = () => {
        $$('[data-sel]', el).forEach((b) => b.querySelector('.radio').classList.toggle('on', sel.has(b.dataset.sel)));
        $('#mg-count').textContent = `Ordner auswählen (${sel.size})`;
      };
      $$('[data-sel]', el).forEach((b) => { b.onclick = () => { const id = b.dataset.sel; sel.has(id) ? sel.delete(id) : sel.add(id); upd(); }; });
      $$('#mg-mode button', el).forEach((b) => { b.onclick = () => { mode = b.dataset.m; $$('#mg-mode button', el).forEach((x) => x.classList.toggle('on', x === b)); $('#mg-explain').textContent = explain[mode]; }; });
      upd();
    },
    onPrimary: () => {
      const name = trim($('#mg-name').value);
      if (sel.size < 2) { toast('Wähle mindestens 2 Ordner'); return; }
      if (!name) { $('#mg-name').classList.add('shake'); setTimeout(() => $('#mg-name').classList.remove('shake'), 400); return; }
      const ordered = flatFolders().map((x) => x.folder.id).filter((id) => sel.has(id));
      const nf = mergeFolders(ordered, name, firstGrapheme($('#mg-emoji').value) || '🗂️', parentID, mode);
      closeSheet(); ui.tab = 'folders'; ui.folder = nf.id; render(); toast('✓ Ordner erstellt');
    }
  });
}

function learnSetup(folderID) {
  const f = folderById(folderID);
  const scope = f ? allCards(f.id) : db.cards;
  let mode = 'smart'; let kind = db.settings.quizKind; let dir = db.settings.direction; let size = db.settings.sessionSize;
  openSheet({
    title: f ? f.name : 'Alle Wörter', cancel: 'Schließen',
    body: `<div class="section-title" style="margin-top:4px">Was möchtest du lernen?</div><div class="stack" style="gap:10px" id="ls-modes"></div>
      <div class="section-title">Abfrageart</div><div class="choice-grid" id="ls-kinds"></div>
      <div id="ls-dir-wrap"><div class="section-title">Richtung</div><div class="segmented" id="ls-dir">${[['kuToDe', 'KU → DE'], ['deToKu', 'DE → KU'], ['mixed', 'Gemischt']].map(([k, l]) => `<button data-d="${k}">${l}</button>`).join('')}</div></div>
      <div class="section-title">Anzahl</div><div class="stepper"><span class="semi" id="ls-size"></span><div class="ctrl"><button id="ls-minus">−</button><button id="ls-plus">＋</button></div></div>
      <button class="btn" id="ls-start" style="margin-top:20px"></button>`,
    onMount: () => {
      const upd = () => {
        $('#ls-modes').innerHTML = Object.entries(MODES).map(([k, m]) => `<button class="mode ${mode === k ? 'on' : ''}" data-mode="${k}">
          <span class="ic" style="background:${GRADIENT[m.cls]}">${m.icon}</span><span class="grow"><div class="semi">${m.label}</div><div class="tiny muted">${m.sub}</div></span>
          <span class="small bold muted">${availableFor(scope, k)}</span><span class="radio"></span></button>`).join('');
        $('#ls-kinds').innerHTML = Object.entries(QUIZ).map(([k, [l, i]]) => `<button class="choice ${kind === k ? 'on' : ''}" data-kind="${k}">${i} ${l}</button>`).join('');
        $$('#ls-dir button').forEach((b) => b.classList.toggle('on', b.dataset.d === dir));
        $('#ls-dir-wrap').style.display = mode === 'verbs' ? 'none' : '';
        $('#ls-size').textContent = `${size} Abfragen`;
        const n = availableFor(scope, mode);
        $('#ls-start').disabled = !n; $('#ls-start').className = `btn ${MODES[mode].cls}`;
        $('#ls-start').textContent = n ? "▶︎ Los geht's" : 'Nichts zu lernen';
        $$('[data-mode]').forEach((b) => { b.onclick = () => { mode = b.dataset.mode; upd(); }; });
        $$('[data-kind]').forEach((b) => { b.onclick = () => { kind = b.dataset.kind; upd(); }; });
      };
      $$('#ls-dir button').forEach((b) => { b.onclick = () => { dir = b.dataset.d; upd(); }; });
      $('#ls-minus').onclick = () => { size = Math.max(5, size - 5); upd(); };
      $('#ls-plus').onclick = () => { size = Math.min(100, size + 5); upd(); };
      $('#ls-start').onclick = () => {
        Object.assign(db.settings, { quizKind: kind, direction: dir, sessionSize: size }); save();
        const items = buildSession(scope, mode, size);
        if (!items.length) return;
        closeSheet();
        startSession(items, mode === 'practice' || mode === 'hard', kind, mode === 'verbs' ? 'kuToDe' : dir);
      };
      upd();
    }
  });
}

function welcome() {
  openSheet({
    title: '', cancel: '',
    body: `<div class="welcome"><div class="sun-badge">☀️</div>
      <div><h1 style="margin:0 0 6px;font-size:32px">Bi xêr hatî!</h1><div class="muted" style="font-size:18px">Willkommen bei Ferheng – deinem Kurdisch-Trainer.</div></div>
      <div class="stack" style="text-align:left;gap:14px;width:100%">
        <div class="row" style="align-items:flex-start"><span style="font-size:24px">📂</span><div><div class="bold">Ordner & Unterordner</div><div class="small muted">Sortiere deine Wörter nach Themen – und füge Ordner zusammen.</div></div></div>
        <div class="row" style="align-items:flex-start"><span style="font-size:24px">🧠</span><div><div class="bold">Lernt mit dir mit</div><div class="small muted">Schwere Wörter kommen öfter, leichte seltener.</div></div></div>
        <div class="row" style="align-items:flex-start"><span style="font-size:24px">⚡️</span><div><div class="bold">Verb-Trainer</div><div class="small muted">Präsensstamm, Präsens, Vergangenheit, Imperativ & Futur.</div></div></div>
      </div>
      <button class="btn" id="wl-starter">Mit Beispielvokabeln starten</button>
      <button class="btn soft" id="wl-empty">Leer starten</button></div>`,
    onMount: () => {
      $('.sheet-head').style.display = 'none';
      $('.backdrop').removeAttribute('data-act');
      $('#wl-starter').onclick = () => { loadStarterPack(); closeSheet(); render(); };
      $('#wl-empty').onclick = () => { db.hasOnboarded = true; save(); closeSheet(); render(); };
    }
  });
}

// ---------- Lernsitzung ----------
function startSession(items, practice, quizKind, direction) {
  session = { queue: items, index: 0, practice, quizKind, direction, correct: 0, wrong: 0, wrongItems: [], retries: {}, q: null };
  prepare();
  renderSession();
}
function quickStart(mode) {
  const items = buildSession(db.cards, mode, db.settings.sessionSize);
  if (!items.length) {
    if (!db.cards.length) { toast('Füge zuerst Wörter hinzu'); return; }
    if (mode === 'smart') {
      confirmSheet('Gerade nichts fällig 🎉', 'Du hast alle fälligen Wörter wiederholt und dein Limit für neue Wörter erreicht. Möchtest du trotzdem frei üben?', 'Freies Üben',
        () => quickStart('practice'), false);
    } else toast(mode === 'hard' ? 'Keine schwierigen Wörter – super! 💪' : 'Keine Verben mit Formen vorhanden');
    return;
  }
  startSession(items, mode === 'practice' || mode === 'hard', db.settings.quizKind, mode === 'verbs' ? 'kuToDe' : db.settings.direction);
}
function prepare() {
  const s = session; const item = s.queue[s.index];
  if (!item) { s.q = null; return; }
  const card = cardById(item.cardID);
  if (!card) { s.index++; return prepare(); }
  const dir = item.form ? 'kuToDe' : s.direction === 'mixed' ? (Math.random() < 0.5 ? 'kuToDe' : 'deToKu') : s.direction;
  let kind = s.quizKind === 'mixed' ? ['flashcard', 'multipleChoice', 'typing'][Math.floor(Math.random() * 3)] : s.quizKind;
  let options = [];
  if (kind === 'multipleChoice') {
    const wrong = distractors(item, card, dir, 3);
    if (wrong.length < 3) kind = 'flashcard'; else options = shuffle(wrong.concat([answerOf(item, card, dir)]));
  }
  s.q = { item, card, dir, kind, options, revealed: false, picked: null, typed: '', verdict: null, state: stateOf(keyOf(item)) };
}
function answer(grade) {
  const s = session; const item = s.q.item;
  record(item, grade, s.practice);
  if (grade === 0) {
    s.wrong++;
    if (!s.wrongItems.some((w) => keyOf(w) === keyOf(item))) s.wrongItems.push(item);
    const k = keyOf(item); const tries = s.retries[k] || 0;
    if (tries < 2) { s.retries[k] = tries + 1; s.queue.splice(Math.min(s.queue.length, s.index + 4), 0, { cardID: item.cardID, form: item.form }); }
    vibrate([30, 40, 30]);
  } else { s.correct++; vibrate(15); }
  s.index++;
  prepare();
  renderSession();
}
function closeSession() { session = null; $('#overlay').innerHTML = ''; render(); }

function renderSession() {
  const s = session; const o = $('#overlay');
  const total = s.queue.length; const pct = total ? (s.index / total) * 100 : 100;
  const top = `<div class="session-top"><button class="icon-btn" data-act="session-close">✕</button>
    <div class="progress"><span style="width:${pct}%"></span></div><span class="small semi muted" style="font-variant-numeric:tabular-nums">${Math.min(s.index + 1, total)}/${total}</span></div>`;
  let shell = $('.overlay', o);
  if (!shell) { o.innerHTML = '<div class="overlay"></div>'; shell = $('.overlay', o); }
  if (!s.q) { shell.innerHTML = `${top}${summaryHTML()}`; s.lastIndex = -1; return; }
  const isNew = s.lastIndex !== s.index; s.lastIndex = s.index;
  const q = s.q; const { item, card, dir, kind } = q;
  const prompt = promptOf(item, card, dir); const ans = answerOf(item, card, dir);
  const answerGerman = !item.form && dir === 'kuToDe'; const promptKu = item.form || dir === 'kuToDe';
  const m = mastery(q.state);
  const showAnswer = kind === 'flashcard' ? q.revealed : kind === 'multipleChoice' ? q.picked != null : q.verdict != null;

  let middle = '';
  if (kind === 'multipleChoice') {
    middle = `<div class="stack" style="gap:10px;margin-top:16px">${q.options.map((op, i) => {
      let cls = ''; let mark = '';
      if (q.picked != null) { if (op === ans) { cls = 'right'; mark = '✅'; } else if (op === q.picked) { cls = 'wrong'; mark = '❌'; } }
      return `<button class="opt ${cls}" data-act="pick" data-id="${i}">${esc(op)}<span>${mark}</span></button>`;
    }).join('')}</div>`;
  } else if (kind === 'typing') {
    const vColor = { exact: 'var(--green)', accent: 'var(--green)', typo: 'var(--orange)', wrong: 'var(--hard)' }[q.verdict];
    const vTitle = { exact: 'Richtig!', accent: 'Richtig – achte auf die Sonderzeichen', typo: 'Fast richtig – kleiner Tippfehler', wrong: 'Leider falsch' }[q.verdict];
    middle = `<div class="stack" style="gap:10px;margin-top:16px">
      <input id="type-input" value="${esc(q.typed)}" placeholder="${answerGerman ? 'Auf Deutsch …' : 'Auf Kurdisch …'}" autocapitalize="off" autocorrect="off" autocomplete="off" spellcheck="false" enterkeyhint="done"
        style="font-size:20px;padding:16px;background:var(--card);${q.verdict ? `border-color:${vColor}` : ''}" ${q.verdict ? 'disabled' : ''}>
      ${!answerGerman && !q.verdict ? charbar('type-input') : ''}
      ${q.verdict ? `<div class="verdict" style="background:color-mix(in srgb,${vColor} 14%,transparent)"><span style="font-size:22px">${q.verdict === 'wrong' ? '❌' : '✅'}</span>
        <div><div class="bold">${vTitle}</div>${q.verdict !== 'exact' ? `<div class="small">Richtig: <b>${esc(ans)}</b></div>` : ''}</div></div>` : ''}
    </div>`;
  }

  let details = '';
  if (showAnswer) {
    const forms = filledForms(card);
    const parts = [];
    if (!item.form && card.type === 'noun' && (card.gender !== 'none' || card.plural)) parts.push(`<div class="row" style="gap:8px">${card.gender !== 'none' ? pill(card.gender === 'f' ? 'weiblich (f)' : 'männlich (m)', genderColor(card.gender)) : ''}${card.plural ? `<span class="small">Plural: ${esc(card.plural)}</span>` : ''}</div>`);
    if (forms.length) parts.push(`<div><div class="row" style="gap:8px;margin-bottom:6px"><span class="small bold">Verbformen</span>${card.transitivity !== 'unknown' ? pill(TRANS[card.transitivity], '#af52de') : ''}</div>
      <div class="forms-table">${forms.map((f) => `<span class="muted">${FORM_LABEL[f]}</span><span style="${f === item.form ? 'font-weight:800;color:#af52de' : ''}">${esc(cardForm(card, f))}</span>`).join('')}</div></div>`);
    if (card.exampleKu) parts.push(`<div><div class="small" style="font-style:italic">${esc(card.exampleKu)}</div>${card.exampleDe ? `<div class="tiny muted">${esc(card.exampleDe)}</div>` : ''}</div>`);
    if (card.note) parts.push(`<div class="small" style="color:var(--orange)">💡 ${esc(card.note)}</div>`);
    if (parts.length) details = `<div class="card stack" style="gap:12px;margin-top:16px;animation:fade .3s">${parts.join('')}</div>`;
  }

  let bottom = '';
  if (kind === 'multipleChoice') {
    bottom = q.picked != null ? `<button class="btn" data-act="grade" data-id="${q.picked === ans ? 2 : 0}">Weiter</button>` : '<button class="btn gray" data-act="dont-know">Weiß ich nicht</button>';
  } else if (kind === 'typing') {
    const g = { exact: 2, accent: 2, typo: 1, wrong: 0 }[q.verdict];
    bottom = q.verdict ? `<div class="btn-row">${q.verdict === 'wrong' ? '<button class="btn soft" data-act="grade" data-id="1">Ich lag richtig</button>' : ''}<button class="btn" data-act="grade" data-id="${g}">Weiter</button></div>`
      : '<div class="btn-row"><button class="btn gray" data-act="dont-know">Weiß ich nicht</button><button class="btn" data-act="check">Prüfen</button></div>';
  } else if (q.revealed) {
    bottom = s.practice ? `<div class="grades two"><button class="grade" style="background:${GRADE_COLOR[0]}" data-act="grade" data-id="0">Nicht gewusst</button><button class="grade" style="background:${GRADE_COLOR[2]}" data-act="grade" data-id="2">Gewusst</button></div>`
      : `<div class="grades">${[0, 1, 2, 3].map((g) => `<button class="grade" style="background:${GRADE_COLOR[g]}" data-act="grade" data-id="${g}">${GRADE_LABEL[g]}<small>${intervalLabel(q.state, g)}</small></button>`).join('')}</div>`;
  } else bottom = '<button class="btn" data-act="reveal">Antwort zeigen</button>';

  const tags = [
    item.form ? pill('Verbform', '#af52de') : pill(dir === 'kuToDe' ? 'KU → DE' : 'DE → KU', '#0d8c80'),
    pill(WORD_TYPES[card.type]),
    promptKu && card.type === 'noun' && card.gender !== 'none' ? pill(card.gender, genderColor(card.gender)) : '',
    '<span class="grow"></span>', pill(MASTERY[m].label, MASTERY[m].color)
  ].join('');

  shell.innerHTML = `${top}
    <div class="session-body">
      <div class="card q-card ${isNew ? '' : 'still'}" ${kind === 'flashcard' && !q.revealed ? 'data-act="reveal"' : ''} style="cursor:pointer">
        <div class="tags">${tags}</div>
        <div class="stack" style="gap:8px;align-items:center">
          ${item.form ? `<div class="bold" style="color:#8a5cf5">${FORM_LABEL[item.form]}</div>` : ''}
          <div class="q-prompt">${esc(prompt)}</div>
          ${item.form ? `<div class="small muted">${esc(card.german)} ${card.transitivity !== 'unknown' ? pill(TRANS[card.transitivity], '#af52de') : ''}</div>` : ''}
          ${kind === 'flashcard' ? (q.revealed ? `<div class="q-divider"></div><div class="q-answer">${esc(ans)}</div>` : '<div class="small faint">Tippe, um die Antwort zu sehen</div>') : ''}
        </div><div></div>
      </div>
      ${middle}${details}
    </div>
    <div class="session-bottom"><div>${bottom}</div></div>`;

  const inp = $('#type-input');
  if (inp) {
    inp.oninput = () => { q.typed = inp.value; };
    inp.onkeydown = (e) => { if (e.key === 'Enter') { e.preventDefault(); checkTyped(); } };
    if (!q.verdict) setTimeout(() => inp.focus(), 50);
  }
}
function checkTyped() {
  const q = session.q; if (q.verdict) return;
  q.typed = $('#type-input')?.value || q.typed;
  if (!trim(q.typed)) { $('#type-input')?.classList.add('shake'); return; }
  q.verdict = checkAnswer(q.typed, answerOf(q.item, q.card, q.dir), !q.item.form && q.dir === 'kuToDe');
  vibrate(q.verdict === 'wrong' ? [30, 40, 30] : 15);
  renderSession();
}
function summaryHTML() {
  const s = session; const total = s.correct + s.wrong; const rate = total ? s.correct / total : 1;
  const msg = rate >= 0.9 ? 'Bijî! Super gemacht! 🎉' : rate >= 0.6 ? 'Gut gemacht! 💪' : 'Dranbleiben – das wird! 🌱';
  return `<div class="session-body"><div class="stack" style="align-items:center;gap:20px;padding-top:20px">
    <div class="ring" style="width:160px;height:160px">${ring(rate, 160, 14)}<div class="ring-label"><div><div style="font-size:40px;font-weight:800">${Math.round(rate * 100)}%</div><div class="small muted">richtig</div></div></div></div>
    <h2 style="margin:0;text-align:center">${msg}</h2>
    <div class="grid3" style="width:100%">
      <div class="card center"><div style="font-size:24px;font-weight:800;color:var(--green)">${s.correct}</div><div class="tiny muted">richtig</div></div>
      <div class="card center"><div style="font-size:24px;font-weight:800;color:var(--hard)">${s.wrong}</div><div class="tiny muted">falsch</div></div>
      <div class="card center"><div style="font-size:24px;font-weight:800;color:var(--orange)">${streak()}</div><div class="tiny muted">Tage Serie</div></div>
    </div>
    ${s.wrongItems.length ? `<div class="card stack" style="width:100%;gap:10px"><div class="bold">Diese Wörter üben wir öfter</div>
      ${s.wrongItems.map((i) => { const [a, b] = itemLabel(i); return `<div class="row"><span class="semi small grow">${esc(a)}</span><span class="small muted">${esc(b)}</span></div>`; }).join('')}</div>
      <button class="btn hard" data-act="retry-wrong">↻ Fehler nochmal üben</button>` : ''}
    <button class="btn ${s.wrongItems.length ? 'soft' : ''}" data-act="session-close">Fertig</button>
  </div></div>`;
}

// ---------- Ereignisse ----------
document.addEventListener('click', (e) => {
  const charBtn = e.target.closest('[data-char],[data-shift]');
  if (charBtn) { handleChar(charBtn); return; }
  const el = e.target.closest('[data-act]');
  if (!el) return;
  const act = el.dataset.act; const id = el.dataset.id;
  switch (act) {
    case 'tab':
      if (ui.tab === id) { ui.folder = null; ui.grammar = null; } // erneut antippen = zurück zur Übersicht
      ui.tab = id; render(); window.scrollTo(0, 0); break;
    case 'open-folder': ui.tab = 'folders'; ui.folder = id; render(); window.scrollTo(0, 0); break;
    case 'back': { const f = folderById(ui.folder); ui.folder = f?.parentID || null; render(); break; }
    case 'new-folder': folderEditor(null, null); break;
    case 'new-card': cardEditor(newCard(id), true); break;
    case 'photo': photoSheet(id); break;
    case 'edit-card': { const c = cardById(id); if (c) cardEditor(c, false); break; }
    case 'folders-menu': menuSheet('Hinzufügen', [
      { icon: '📁', label: 'Neuer Ordner', run: () => folderEditor(null, null) },
      { icon: '🗂️', label: 'Ordner zusammenfügen', disabled: db.folders.length < 2, run: () => mergeSheet(null) },
      { icon: '📷', label: 'Wörter fotografieren', disabled: !db.folders.length, run: () => photoSheet(null) },
      { icon: '📝', label: 'Mehrere Wörter einfügen', disabled: !db.folders.length, run: () => bulkSheet(null) }
    ]); break;
    case 'folder-menu': {
      const f = folderById(id);
      menuSheet(f.name, [
        { icon: '➕', label: 'Wort hinzufügen', run: () => cardEditor(newCard(f.id), true) },
        { icon: '📷', label: 'Wörter fotografieren', run: () => photoSheet(f.id) },
        { icon: '📝', label: 'Mehrere Wörter einfügen', run: () => bulkSheet(f.id) },
        { icon: '📁', label: 'Unterordner erstellen', run: () => folderEditor(null, f.id) },
        { icon: '✏️', label: 'Ordner bearbeiten', run: () => folderEditor(f, f.parentID) },
        { icon: '🗂️', label: 'Mit anderen zusammenfügen', run: () => mergeSheet(f.parentID, [f.id]) },
        ...((f.linkedIDs || []).length ? [{ icon: '⛓️‍💥', label: 'Verknüpfungen lösen', run: () => { f.linkedIDs = []; save(); render(); toast('Verknüpfungen gelöst'); } }] : []),
        { icon: '🗑️', label: 'Ordner löschen', danger: true, run: () => confirmSheet(`„${f.name}“ löschen?`, 'Alle Wörter und Unterordner darin werden ebenfalls gelöscht.', 'Ordner & Inhalt löschen', () => { ui.folder = f.parentID || null; deleteFolder(f.id); render(); }) }
      ]);
      break;
    }
    case 'learn-setup': learnSetup(id || null); break;
    case 'quick': quickStart(id); break;
    case 'grammar': ui.grammar = +id; render(); window.scrollTo(0, 0); break;
    case 'grammar-back': ui.grammar = null; render(); break;
    case 'close-sheet': closeSheet(); break;
    case 'step': {
      const v = Math.min(+el.dataset.max, Math.max(+el.dataset.min, db.settings[id] + (+el.dataset.d)));
      db.settings[id] = v; save(); render(); break;
    }
    case 'set': db.settings[id] = el.dataset.v; save(); render(); break;
    case 'export': doExport(); break;
    case 'import': $('#import-file').click(); break;
    case 'starter': confirmSheet('Beispielvokabeln hinzufügen?', 'Es wird ein Ordner „Kurmancî Grundlagen“ mit Unterordnern angelegt.', 'Hinzufügen', () => { loadStarterPack(); render(); toast('✓ Beispielvokabeln hinzugefügt'); }, false); break;
    case 'reset': confirmSheet('Wirklich alles löschen?', 'Alle Ordner, Wörter und dein Lernfortschritt werden gelöscht. Das kann nicht rückgängig gemacht werden.', 'Alles löschen', () => {
      db = { folders: [], cards: [], progress: {}, log: {}, settings: db.settings, hasOnboarded: true }; save(); render(); toast('Alles gelöscht');
    }); break;
    // Lernsitzung
    case 'session-close':
      if (session.q && session.index > 0) confirmSheet('Sitzung beenden?', 'Dein bisheriger Fortschritt ist bereits gespeichert.', 'Beenden', closeSession);
      else closeSession();
      break;
    case 'reveal': session.q.revealed = true; renderSession(); break;
    case 'grade': answer(+id); break;
    case 'pick': if (session.q.picked == null) { session.q.picked = session.q.options[+id]; vibrate(session.q.picked === answerOf(session.q.item, session.q.card, session.q.dir) ? 15 : [30, 40, 30]); renderSession(); } break;
    case 'dont-know':
      if (session.q.kind === 'multipleChoice') session.q.picked = '';
      else { session.q.typed = ''; session.q.verdict = 'wrong'; }
      renderSession(); break;
    case 'check': checkTyped(); break;
    case 'retry-wrong': {
      const items = shuffle(session.wrongItems.map((i) => ({ cardID: i.cardID, form: i.form })));
      startSession(items, true, session.quizKind, session.direction); break;
    }
    default: break;
  }
});

function handleChar(btn) {
  const bar = btn.closest('.charbar');
  if (btn.hasAttribute('data-shift')) {
    bar.classList.toggle('upper');
    $$('[data-char]', bar).forEach((b) => { b.textContent = bar.classList.contains('upper') ? b.dataset.char.toUpperCase() : b.dataset.char; });
    return;
  }
  const input = bar.__getInput ? bar.__getInput() : document.getElementById(bar.dataset.target);
  if (!input) return;
  const ch = btn.textContent;
  const start = input.selectionStart ?? input.value.length; const end = input.selectionEnd ?? input.value.length;
  input.value = input.value.slice(0, start) + ch + input.value.slice(end);
  input.focus();
  try { input.setSelectionRange(start + ch.length, start + ch.length); } catch (e) { /* ignorieren */ }
  input.dispatchEvent(new Event('input', { bubbles: true }));
  if (bar.classList.contains('upper')) handleChar(bar.querySelector('[data-shift]'));
}
// Verhindert, dass ein Tipp auf die Zeichenleiste die Tastatur schließt
document.addEventListener('mousedown', (e) => { if (e.target.closest('.charbar button')) e.preventDefault(); });
document.addEventListener('touchend', (e) => {
  const b = e.target.closest('.charbar button');
  if (b) { e.preventDefault(); handleChar(b); }
}, { passive: false });

document.addEventListener('input', (e) => {
  if (e.target.id === 'search') {
    ui.search = e.target.value;
    $('#folder-results').innerHTML = folderResults();
  }
});
document.addEventListener('change', async (e) => {
  if (e.target.id !== 'import-file') return;
  const file = e.target.files[0]; if (!file) return;
  try {
    const data = JSON.parse(await file.text());
    if (!Array.isArray(data.folders) || !Array.isArray(data.cards)) throw new Error('format');
    confirmSheet('Backup wiederherstellen?', `${data.folders.length} Ordner und ${data.cards.length} Wörter werden geladen. Deine aktuellen Daten werden ersetzt.`, 'Wiederherstellen', () => {
      db = normalizeSnapshot(data); db.hasOnboarded = true; save(); render(); toast('✓ Backup wiederhergestellt');
    }, false);
  } catch (err) { toast('Die Datei konnte nicht gelesen werden'); }
  e.target.value = '';
});

async function doExport() {
  const name = `Ferheng-Backup-${dayKey()}.json`;
  const blob = new Blob([exportJSON()], { type: 'application/json' });
  try {
    const file = new File([blob], name, { type: 'application/json' });
    if (navigator.canShare && navigator.canShare({ files: [file] })) { await navigator.share({ files: [file], title: 'Ferheng-Backup' }); return; }
  } catch (err) { if (err && err.name === 'AbortError') return; }
  const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = name;
  document.body.appendChild(a); a.click(); a.remove(); setTimeout(() => URL.revokeObjectURL(a.href), 2000);
  toast('Backup gespeichert');
}

// ---------- Start ----------
load();
render();
if (!db.hasOnboarded && !db.folders.length) welcome();

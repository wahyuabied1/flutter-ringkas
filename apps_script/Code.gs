/**
 * Ringkas API di atas Google Sheets ("Database ringkas").
 *
 * Cara pakai:
 * 1) Buka spreadsheet → Ekstensi > Apps Script → tempel isi file ini
 * 2) Jalankan fungsi setup() sekali (izinkan akses)
 * 3) Deploy > Deployment baru > Aplikasi web
 *      Jalankan sebagai: Saya | Yang memiliki akses: Siapa saja
 * 4) Salin URL berakhiran /exec ke ApiService.baseUrl di lib/data/services/api_service.dart
 *
 * Setiap kali kode ini diubah, buat VERSI BARU pada deployment agar perubahan aktif.
 * Penjelasan kolom ada di sheet "Panduan Kolom".
 */
const SS = SpreadsheetApp.getActiveSpreadsheet();
const TZ = Session.getScriptTimeZone();

const SCHEMA = {
  users:     ['id', 'name', 'email', 'password_hash', 'salt', 'created_at'],
  sessions:  ['token', 'user_id', 'created_at'],
  dompet:    ['id', 'user_id', 'name', 'currency', 'initial_balance', 'is_active', 'created_at', 'updated_at'],
  kategori:  ['id', 'user_id', 'parent_id', 'name', 'kind', 'color', 'icon', 'created_at'],
  transaksi: ['id', 'user_id', 'category_id', 'dompet_id', 'trx_date', 'amount', 'note', 'created_at', 'updated_at'],
};

// ---------- SETUP ----------
function setup() {
  Object.keys(SCHEMA).forEach(name => {
    const sh = SS.getSheetByName(name) || SS.insertSheet(name);
    const cols = SCHEMA[name];
    sh.getRange(1, 1, 1, cols.length).setValues([cols]);
    sh.setFrozenRows(1);
    // kolom tanggal disimpan sebagai teks supaya tidak diubah jadi Date oleh Sheets
    cols.forEach((c, i) => {
      if (/date|_at$/.test(c)) sh.getRange(2, i + 1, sh.getMaxRows() - 1).setNumberFormat('@');
    });
  });
}

// ---------- ENTRY POINT ----------
function doGet() { return out({ status: 'success', message: 'Ringkas API aktif' }); }

function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(15000); // cegah dua request menulis bersamaan
    return out(route(JSON.parse(e.postData.contents)));
  } catch (err) {
    return out({ status: 'error', message: err.message });
  } finally {
    lock.releaseLock();
  }
}

function out(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
const ok = (extra) => Object.assign({ status: 'success', message: 'OK' }, extra);

// ---------- ROUTER ----------
function route(req) {
  const method = String(req.method || 'GET').toUpperCase();
  const [resource, id] = String(req.path || '').split('/').filter(Boolean);
  const b = req.body || {};
  const q = req.query || {};

  if (resource === 'register' && method === 'POST') return register(b);
  if (resource === 'login' && method === 'POST') return login(b);

  const user = authenticate(req.token);
  switch (resource) {
    case 'users':     return ok(publicUser(user));
    case 'dompet':    return dompetApi(method, id, b, user);
    case 'kategori':  return kategoriApi(method, id, b, user);
    case 'transaksi': return transaksiApi(method, id, b, q, user);
  }
  throw new Error('Endpoint tidak ditemukan');
}

// ---------- AUTH ----------
function hash(salt, password) {
  const bytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, salt + password);
  return bytes.map(x => ('0' + (x & 0xff).toString(16)).slice(-2)).join('');
}
const publicUser = (u) => ({ id: u.id, name: u.name, email: u.email, created_at: u.created_at });

function authResponse(u) {
  const token = Utilities.getUuid() + Utilities.getUuid();
  insert('sessions', { token, user_id: u.id, created_at: now() });
  return ok({ access_token: token, user: publicUser(u) });
}

function register(b) {
  if (!b.name || !b.email || !b.password) throw new Error('Nama, email, dan password wajib diisi');
  const email = String(b.email).trim().toLowerCase();
  if (all('users').some(u => u.email === email)) throw new Error('Email sudah terdaftar');
  const salt = Utilities.getUuid();
  const user = insert('users', {
    name: b.name, email, salt,
    password_hash: hash(salt, String(b.password)),
    created_at: now(),
  });
  seedCategories(user.id);
  return authResponse(user);
}

// Kategori bawaan untuk user baru: [nama, kind, warna, ikon].
// Nama ikon harus sama dengan yang dikenali app (icon_picker_page.dart).
const DEFAULT_CATEGORIES = [
  ['Makanan & Minuman', 'expense', '#FF7043', 'restaurant'],
  ['Transportasi', 'expense', '#42A5F5', 'directions_car'],
  ['Belanja', 'expense', '#AB47BC', 'shopping_bag'],
  ['Tagihan', 'expense', '#EF5350', 'credit_card'],
  ['Hiburan', 'expense', '#FFCA28', 'movie'],
  ['Kesehatan', 'expense', '#26A69A', 'local_hospital'],
  ['Pendidikan', 'expense', '#5C6BC0', 'school'],
  ['Gaji', 'income', '#66BB6A', 'attach_money'],
  ['Bonus', 'income', '#5D9E85', 'card_giftcard'],
  ['Investasi', 'income', '#29B6F6', 'trending_up'],
];

function seedCategories(userId) {
  const created = now();
  insertMany('kategori', DEFAULT_CATEGORIES.map(([name, kind, color, icon]) => ({
    user_id: userId, name, kind, color, icon, created_at: created,
  })));
}

function login(b) {
  const email = String(b.email || '').trim().toLowerCase();
  const u = all('users').find(x => x.email === email);
  if (!u || u.password_hash !== hash(u.salt, String(b.password))) {
    throw new Error('Email atau password salah');
  }
  return authResponse(u);
}

function authenticate(token) {
  const s = all('sessions').find(r => r.token === token);
  const u = s && all('users').find(x => Number(x.id) === Number(s.user_id));
  if (!u) throw new Error('Unauthenticated');
  return u;
}

// ---------- DOMPET ----------
function dompetApi(method, id, b, user) {
  const mine = () => all('dompet').filter(w => Number(w.user_id) === user.id);
  const find = () => {
    const w = mine().find(x => String(x.id) === String(id));
    if (!w) throw new Error('Dompet tidak ditemukan');
    return w;
  };

  if (method === 'GET') {
    const kinds = kindMap(user.id), trx = userTrx(user.id);
    const list = mine().map(w => ({ ...strip(w), current_balance: balanceOf(w, trx, kinds) }));
    return ok({ data: { dompets: list, total_current_balance: sum(list.map(w => w.current_balance)) } });
  }
  if (method === 'POST') {
    if (!b.name) throw new Error('Nama dompet wajib diisi');
    const w = insert('dompet', {
      user_id: user.id, name: b.name, currency: b.currency || 'IDR',
      initial_balance: Number(b.initial_balance) || 0, is_active: true,
      created_at: now(), updated_at: now(),
    });
    return ok({ data: strip(w) });
  }
  if (method === 'PUT') {
    const w = find();
    Object.assign(w, {
      name: b.name ?? w.name, currency: b.currency ?? w.currency,
      initial_balance: b.initial_balance ?? w.initial_balance, updated_at: now(),
    });
    save('dompet', w);
    return ok({ data: strip(w) });
  }
  if (method === 'DELETE') {
    const w = find();
    removeRows('transaksi', userTrx(user.id).filter(t => String(t.dompet_id) === String(w.id)));
    removeRows('dompet', [w]);
    return ok();
  }
  throw new Error('Method tidak didukung');
}

// ---------- KATEGORI ----------
function kategoriApi(method, id, b, user) {
  const mine = () => all('kategori').filter(k => Number(k.user_id) === user.id);
  const find = () => {
    const k = mine().find(x => String(x.id) === String(id));
    if (!k) throw new Error('Kategori tidak ditemukan');
    return k;
  };

  if (method === 'GET') return ok({ data: mine().map(strip) });
  if (method === 'POST') {
    if (!b.name || !['income', 'expense'].includes(b.kind)) throw new Error('Nama dan kind (income/expense) wajib diisi');
    const k = insert('kategori', {
      user_id: user.id, name: b.name, kind: b.kind,
      color: b.color || '', icon: b.icon || '', created_at: now(),
    });
    return ok({ data: strip(k) });
  }
  if (method === 'PUT') {
    const k = find();
    Object.assign(k, {
      name: b.name ?? k.name, kind: b.kind ?? k.kind,
      color: b.color ?? k.color, icon: b.icon ?? k.icon,
    });
    save('kategori', k);
    return ok({ data: strip(k) });
  }
  if (method === 'DELETE') {
    const k = find();
    if (userTrx(user.id).some(t => String(t.category_id) === String(k.id))) {
      throw new Error('Kategori masih dipakai transaksi');
    }
    removeRows('kategori', [k]);
    return ok();
  }
  throw new Error('Method tidak didukung');
}

// ---------- TRANSAKSI ----------
function transaksiApi(method, id, b, q, user) {
  const cats = byId(all('kategori').filter(k => Number(k.user_id) === user.id));
  const wallets = byId(all('dompet').filter(w => Number(w.user_id) === user.id));
  const trx = userTrx(user.id);
  const kinds = kindMap(user.id);
  const find = () => {
    const t = trx.find(x => String(x.id) === String(id));
    if (!t) throw new Error('Transaksi tidak ditemukan');
    return t;
  };
  const enrich = (t) => ({
    ...strip(t),
    kategori_name: (cats[t.category_id] || {}).name,
    kind: (cats[t.category_id] || {}).kind,
    dompet_name: (wallets[t.dompet_id] || {}).name,
  });
  const validate = (t) => {
    if (!cats[t.category_id]) throw new Error('Kategori tidak valid');
    if (!wallets[t.dompet_id]) throw new Error('Dompet tidak valid');
    if (!(Number(t.amount) > 0)) throw new Error('Nominal harus lebih dari 0');
  };

  if (method === 'GET' && id) return ok({ data: enrich(find()) });

  if (method === 'GET') {
    const day = (t) => String(t.trx_date).slice(0, 10);
    const ids = (s) => String(s).split(',').map(Number);
    let list = trx;
    if (q.start_date) list = list.filter(t => day(t) >= q.start_date);
    if (q.end_date) list = list.filter(t => day(t) <= q.end_date);
    if (q.dompet_id) list = list.filter(t => ids(q.dompet_id).includes(Number(t.dompet_id)));
    if (q.category_id) list = list.filter(t => ids(q.category_id).includes(Number(t.category_id)));
    if (q.search) {
      const s = String(q.search).toLowerCase();
      list = list.filter(t => String(t.note).toLowerCase().includes(s) ||
        String((cats[t.category_id] || {}).name).toLowerCase().includes(s));
    }
    list.sort((a, c) => day(c).localeCompare(day(a)) || c.id - a.id);

    const before = q.start_date ? trx.filter(t => day(t) < q.start_date) : [];
    const saldoAwal = sum(Object.values(wallets).map(w => Number(w.initial_balance))) +
      sum(before.map(t => signed(t, kinds)));
    const saldoAkhir = saldoAwal + sum(list.map(t => signed(t, kinds)));
    return ok({ data: {
      transaksi: list.map(enrich),
      saldo_awal: saldoAwal, saldo_akhir: saldoAkhir, total_transaksi: list.length,
    } });
  }
  if (method === 'POST') {
    validate(b);
    const t = insert('transaksi', {
      user_id: user.id, category_id: Number(b.category_id), dompet_id: Number(b.dompet_id),
      trx_date: b.trx_date, amount: Number(b.amount), note: b.note || '',
      created_at: now(), updated_at: now(),
    });
    return ok({ data: enrich(t) });
  }
  if (method === 'PUT') {
    const t = find();
    const next = {
      category_id: Number(b.category_id ?? t.category_id), dompet_id: Number(b.dompet_id ?? t.dompet_id),
      amount: Number(b.amount ?? t.amount), trx_date: b.trx_date ?? t.trx_date,
      note: b.note ?? t.note,
    };
    validate(next);
    Object.assign(t, next, { updated_at: now() });
    save('transaksi', t);
    return ok({ data: enrich(t) });
  }
  if (method === 'DELETE') { removeRows('transaksi', [find()]); return ok(); }
  throw new Error('Method tidak didukung');
}

// ---------- HELPER HITUNG ----------
const sum = (arr) => arr.reduce((a, n) => a + Number(n), 0);
const byId = (rows) => Object.fromEntries(rows.map(r => [r.id, r]));
const strip = (o) => { const { _row, ...rest } = o; return rest; };
const now = () => Utilities.formatDate(new Date(), TZ, 'yyyy-MM-dd HH:mm:ss');

function kindMap(uid) {
  const m = {};
  all('kategori').filter(k => Number(k.user_id) === uid).forEach(k => m[k.id] = k.kind);
  return m;
}
const signed = (t, kinds) => (kinds[t.category_id] === 'income' ? 1 : -1) * Number(t.amount);
const balanceOf = (w, trx, kinds) =>
  Number(w.initial_balance) + sum(trx.filter(t => String(t.dompet_id) === String(w.id)).map(t => signed(t, kinds)));
const userTrx = (uid) => all('transaksi').filter(t => Number(t.user_id) === uid);

// ---------- AKSES SHEET ----------
function all(name) {
  const values = SS.getSheetByName(name).getDataRange().getValues();
  const head = values.shift();
  const expected = SCHEMA[name];
  // Header yang berubah (mis. "id" diketik ulang) membuat kolom tidak terbaca dan
  // menggagalkan request tanpa pesan yang jelas, jadi hentikan lebih awal.
  if (head.slice(0, expected.length).join(',') !== expected.join(',')) {
    throw new Error('Header sheet "' + name + '" salah. Baris 1 harus: ' + expected.join(', '));
  }
  return values.map((r, i) => {
    const o = { _row: i + 2 };
    head.forEach((h, c) => {
      o[h] = r[c] instanceof Date ? Utilities.formatDate(r[c], TZ, 'yyyy-MM-dd') : r[c];
    });
    return o;
  });
}
function insert(name, obj) {
  const cols = SCHEMA[name];
  if (cols.includes('id')) obj.id = all(name).reduce((m, r) => Math.max(m, Number(r.id)), 0) + 1;
  SS.getSheetByName(name).appendRow(cols.map(c => obj[c] === undefined ? '' : obj[c]));
  return obj;
}
// Tulis banyak baris sekaligus (satu kali setValues) supaya register tidak lambat.
function insertMany(name, objs) {
  if (!objs.length) return;
  const cols = SCHEMA[name];
  let nextId = all(name).reduce((m, r) => Math.max(m, Number(r.id)), 0) + 1;
  const rows = objs.map(o => {
    o.id = nextId++;
    return cols.map(c => o[c] === undefined ? '' : o[c]);
  });
  const sh = SS.getSheetByName(name);
  sh.getRange(sh.getLastRow() + 1, 1, rows.length, cols.length).setValues(rows);
}
function save(name, row) {
  const cols = SCHEMA[name];
  SS.getSheetByName(name).getRange(row._row, 1, 1, cols.length).setValues([cols.map(c => row[c])]);
}
function removeRows(name, rows) {
  const sh = SS.getSheetByName(name);
  rows.map(r => r._row).sort((a, c) => c - a).forEach(n => sh.deleteRow(n)); // dari bawah supaya index tidak bergeser
}

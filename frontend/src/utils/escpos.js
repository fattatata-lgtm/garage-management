// Encoder perintah ESC/POS minimal untuk printer thermal 58 mm / 80 mm.
// Teks dikirim sebagai ASCII murni (aksen dibuang, karakter lain -> "?") agar tampil benar di semua
// merek printer tanpa perlu mengatur code page.

const ESC = 0x1b;
const GS = 0x1d;
const LF = 0x0a;

const REPLACE = { '–': '-', '—': '-', '‘': "'", '’': "'", '“': '"', '”': '"', '×': 'x', '•': '*', '…': '...', '\u00a0': ' ' };

export function toAscii(value) {
  return String(value ?? '')
    .replace(/[–—‘’“”×•…\u00a0]/g, (c) => REPLACE[c])
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/[\r\n\t]+/g, ' ')
    .replace(/[^\x20-\x7e]/g, '?');
}

// Pecah teks menjadi baris selebar `width` karakter (kata panjang dipotong).
export function wrapText(text, width) {
  const out = [];
  let line = '';
  for (let word of toAscii(text).trim().split(/ +/)) {
    if (!word) continue;
    while (word.length > width) {
      if (line) { out.push(line); line = ''; }
      out.push(word.slice(0, width));
      word = word.slice(width);
    }
    if (!line) line = word;
    else if (line.length + 1 + word.length <= width) line += ` ${word}`;
    else { out.push(line); line = word; }
  }
  if (line) out.push(line);
  return out.length ? out : [''];
}

export class EscPos {
  // cols: jumlah karakter per baris pada ukuran normal (58 mm = 32, 80 mm = 48 untuk Font A)
  constructor(cols = 48) {
    this.cols = cols;
    this.bytes = [];
    this.raw([ESC, 0x40]); // initialize
    this.raw([ESC, 0x74, 0x00]); // code page PC437 (teks ASCII murni)
    this.raw([ESC, 0x4d, 0x00]); // Font A (12x24): 32 karakter/baris di kertas 58 mm, 48 di 80 mm
  }

  raw(arr) { for (const b of arr) this.bytes.push(b); return this; }
  text(s) { const a = toAscii(s); for (let i = 0; i < a.length; i += 1) this.bytes.push(a.charCodeAt(i)); return this; }
  line(s = '') { return this.text(s).raw([LF]); }
  feed(n = 1) { return this.raw([ESC, 0x64, Math.min(255, Math.max(0, n))]); }

  align(a) { return this.raw([ESC, 0x61, { left: 0, center: 1, right: 2 }[a] ?? 0]); }
  bold(on = true) { return this.raw([ESC, 0x45, on ? 1 : 0]); }
  // w,h: pembesaran 1..4 (lebar x tinggi). Pembesaran lebar mengurangi jumlah karakter per baris.
  size(w = 1, h = 1) { return this.raw([GS, 0x21, ((Math.min(8, w) - 1) << 4) | (Math.min(8, h) - 1)]); }
  reset() { return this.size(1, 1).bold(false).align('left'); }

  divider(ch = '-') { return this.line(ch.repeat(this.cols)); }

  // Baris rata kiri, dibungkus otomatis
  wrap(text) { for (const l of wrapText(text, this.cols)) this.line(l); return this; }

  // "kiri ......... kanan"; bila kiri terlalu panjang, kiri dibungkus dan nominal ditaruh di baris terakhir
  // (rata kanan) kalau muat, jika tidak di baris sendiri. Nominal tidak pernah terpotong.
  pair(left, right, cols = this.cols) {
    const l = toAscii(left).trim();
    const r = toAscii(right);
    if (l.length + r.length + 1 <= cols) return this.line(l + ' '.repeat(cols - l.length - r.length) + r);
    const parts = wrapText(l, Math.max(8, cols - r.length - 1)); // sisakan ruang untuk nominal di baris terakhir
    parts.forEach((part, i) => {
      if (i < parts.length - 1) this.line(part);
      else this.line(part + ' '.repeat(Math.max(1, cols - part.length - r.length)) + r);
    });
    return this;
  }

  // Baris rincian bernomor. Tanpa `sub`: nominal sebaris dengan baris terakhir nama bila muat, jika tidak di baris sendiri.
  // Dengan `sub` (mis. "2 x Rp50.000"): nama dibungkus, lalu sub di kiri dan nominal di kanan pada baris berikutnya.
  entry(no, name, amount, sub) {
    const prefix = `${no}. `;
    const indent = ' '.repeat(prefix.length);
    const amt = amount == null ? '' : toAscii(amount);
    const lines = wrapText(name, this.cols - prefix.length);
    const put = (l, i) => (i === 0 ? prefix : indent) + l;
    const right = (left, r) => left + ' '.repeat(Math.max(1, this.cols - left.length - r.length)) + r;
    lines.forEach((l, i) => {
      const last = i === lines.length - 1;
      const text = put(l, i);
      if (last && !sub && amt && text.length + 1 + amt.length <= this.cols) this.line(right(text, amt));
      else this.line(text);
    });
    if (sub) {
      const left = indent + toAscii(sub);
      this.line(amt ? right(left, amt) : left);
    } else if (amt && !(lines[lines.length - 1] && put(lines[lines.length - 1], lines.length - 1).length + 1 + amt.length <= this.cols)) {
      this.line(' '.repeat(Math.max(0, this.cols - amt.length)) + amt);
    }
    return this;
  }

  // Teks tambahan menjorok (mis. keterangan jasa)
  note(text, indent = 3) {
    for (const l of wrapText(text, this.cols - indent)) this.line(' '.repeat(indent) + l);
    return this;
  }

  center(text) { this.align('center'); this.wrap(text); return this.align('left'); }

  // Judul besar (lebar & tinggi 2x), otomatis dibungkus sesuai lebar yang menyusut
  big(text) {
    this.align('center').bold(true).size(2, 2);
    for (const l of wrapText(text, Math.floor(this.cols / 2))) this.line(l);
    return this.reset();
  }

  // raster = { widthBytes, height, data } dari loadRaster(); dikirim per pita 128 baris agar aman di buffer printer kecil
  image(raster) {
    const { widthBytes, height, data } = raster;
    const BAND = 128;
    for (let y = 0; y < height; y += BAND) {
      const h = Math.min(BAND, height - y);
      this.raw([GS, 0x76, 0x30, 0x00, widthBytes & 0xff, widthBytes >> 8, h & 0xff, h >> 8]);
      this.raw(data.subarray(y * widthBytes, (y + h) * widthBytes));
    }
    return this;
  }

  // Akhir struk. Printer 58 mm mobile (mis. Rongta RPP02N) tidak punya pemotong: cukup majukan kertas
  // melewati batang sobek. Printer 80 mm: maju lalu potong sebagian.
  cut() {
    if (this.cols <= 32) return this.feed(5);
    return this.feed(4).raw([GS, 0x56, 0x42, 0x03]);
  }

  build() { return Uint8Array.from(this.bytes); }
}

// Muat gambar (mis. logo) lalu ubah ke bitmap 1-bit untuk perintah GS v 0.
// maxWidth dalam dot (203 dpi): 58 mm = 384 dot, 80 mm = 576 dot.
export async function loadRaster(url, maxWidth = 384, maxHeight = 160) {
  const res = await fetch(url, { cache: 'force-cache' });
  if (!res.ok) throw new Error('Logo tidak dapat dimuat.');
  const bmp = await createImageBitmap(await res.blob());
  const scale = Math.min(1, maxWidth / bmp.width, maxHeight / bmp.height);
  const w = Math.max(1, Math.round(bmp.width * scale));
  const h = Math.max(1, Math.round(bmp.height * scale));
  const widthBytes = Math.ceil(w / 8);
  const W = widthBytes * 8;

  const canvas = document.createElement('canvas');
  canvas.width = W; canvas.height = h;
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  ctx.fillStyle = '#fff'; // latar transparan -> putih (tidak tercetak)
  ctx.fillRect(0, 0, W, h);
  ctx.drawImage(bmp, 0, 0, w, h);
  const { data: px } = ctx.getImageData(0, 0, W, h);

  // Floyd-Steinberg: tepi & gradasi logo tetap halus di printer 1-bit (threshold kasar membuat logo kotak-kotak / hilang)
  const gray = new Float32Array(W * h);
  for (let i = 0; i < W * h; i += 1) {
    const o = i * 4;
    const lum = 0.299 * px[o] + 0.587 * px[o + 1] + 0.114 * px[o + 2];
    // sedikit kontras agar abu-abu muda tidak hilang; piksel transparan sudah putih
    gray[i] = Math.max(0, Math.min(255, (lum - 128) * 1.15 + 128));
  }
  const data = new Uint8Array(widthBytes * h);
  for (let y = 0; y < h; y += 1) {
    for (let x = 0; x < W; x += 1) {
      const i = y * W + x;
      const old = gray[i];
      const black = old < 128;
      if (black) data[y * widthBytes + (x >> 3)] |= 0x80 >> (x & 7);
      const err = old - (black ? 0 : 255);
      if (x + 1 < W) gray[i + 1] += (err * 7) / 16;
      if (y + 1 < h) {
        if (x > 0) gray[i + W - 1] += (err * 3) / 16;
        gray[i + W] += (err * 5) / 16;
        if (x + 1 < W) gray[i + W + 1] += err / 16;
      }
    }
  }
  return { widthBytes, height: h, data };
}

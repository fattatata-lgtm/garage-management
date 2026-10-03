// Lebar kertas thermal (mm) dari Pengaturan > Tipe Printer ("Thermal 58mm" / "Thermal 80mm"); bawaan 80 mm.
export function paperWidthMm(settings) {
  return /58/.test(settings?.printerType || '') ? 58 : 80;
}

// Membuka window baru berisi dokumen siap cetak (Invoice/Struk Thermal/Work Order)
// lalu memanggil window.print(). Pendekatan ini menghindari konflik CSS dengan halaman utama.
export function printDocument(title, bodyHtml, { thermal = false, paperMm = 80, width = 420, height = 600, css = '' } = {}) {
  // Struk thermal: tampilan bawaan (lebar 280px, huruf 12px) dipakai untuk kertas 80 mm; kertas 58 mm
  // dibuat lebih sempit. Margin browser dimatikan, dan tinggi halaman dipasang setelah isi dirender
  // (Chrome tidak mengenal "size: 58mm auto"), lihat di bawah.
  const thermalCss = thermal ? `
        @page { margin: 0; }${paperMm === 58 ? `
        body { width: 210px !important; padding: 10px !important; font-size: 11px !important; }
        td, th { font-size: 10px !important; }` : ''}` : '';
  const win = window.open('', '_blank', `width=${width},height=${height}`);
  if (!win) {
    alert('Popup diblokir oleh browser. Izinkan popup untuk mencetak dokumen.');
    return;
  }
  win.document.write(`
    <!doctype html>
    <html lang="id">
    <head>
      <meta charset="UTF-8" />
      <title>${title}</title>
      <style>
        * { box-sizing: border-box; }
        body {
          font-family: ${thermal ? "'Courier New', monospace" : "Arial, Helvetica, sans-serif"};
          font-size: ${thermal ? '12px' : '13px'};
          width: ${thermal ? '280px' : '100%'};
          margin: 0 auto;
          padding: 16px;
          color: #111;
        }
        h1, h2, h3 { margin: 0 0 8px; }
        table { width: 100%; border-collapse: collapse; margin: 8px 0; }
        td, th { padding: 4px 2px; text-align: left; font-size: ${thermal ? '11px' : '12px'}; }
        .right { text-align: right; }
        .center { text-align: center; }
        .divider { border-top: 1px dashed #999; margin: 8px 0; }
        .total-row td { font-weight: bold; border-top: 1px solid #333; }
        .muted { color: #666; font-size: 11px; }
        ${thermalCss}
        ${css}
      </style>
    </head>
    <body>${bodyHtml}</body>
    </html>
  `);
  win.document.close();
  win.focus();
  // Tunggu gambar (mis. logo dari URL) selesai dimuat, maksimal 2,5 detik, baru buka dialog cetak.
  const pending = [...win.document.images].filter((i) => !i.complete)
    .map((i) => new Promise((r) => { i.onload = r; i.onerror = r; }));
  Promise.race([Promise.all(pending), new Promise((r) => setTimeout(r, 2500))])
    .then(() => setTimeout(() => {
      if (thermal) {
        // Tinggi halaman = tinggi isi struk (+ sedikit ruang), agar tidak ada kertas kosong panjang
        // dan tidak terpecah ke halaman kedua.
        const mm = Math.ceil((win.document.body.getBoundingClientRect().height * 25.4) / 96) + 10;
        const st = win.document.createElement('style');
        st.textContent = `@page { size: ${paperMm}mm ${mm}mm; margin: 0; }`;
        win.document.head.appendChild(st);
      }
      win.print();
    }, 300));
}

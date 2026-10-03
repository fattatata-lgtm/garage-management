// Membuka wa.me dengan pesan yang sudah disiapkan backend (bukan integrasi otomatis,
// hanya pre-filled message yang dikirim manual oleh staff sesuai scope PRD)
export function openWhatsApp(phone, message) {
  if (!phone) {
    alert('Nomor WhatsApp pelanggan tidak tersedia.');
    return;
  }
  const digits = phone.replace(/[^0-9]/g, '');
  const normalized = digits.startsWith('0') ? `62${digits.slice(1)}` : digits;
  // Pakai api.whatsapp.com/send langsung (bukan wa.me) supaya emoji & karakter khusus tidak rusak
  // akibat redirect. Pesan dinormalisasi ke NFC lalu di-encode UTF-8.
  const url = `https://api.whatsapp.com/send?phone=${normalized}&text=${encodeURIComponent(message.normalize('NFC'))}`;
  window.open(url, '_blank');
}

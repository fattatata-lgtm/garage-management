// Panggil Kasir - Text-to-Speech menggunakan Web Speech API bawaan browser

// Eja plat nomor per karakter agar jelas didengar, mis. "N 1234 AB" -> "N, 1 2 3 4, A B"
function spellPlate(plate = '') {
  return String(plate)
    .toUpperCase()
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => part.split('').join(' '))
    .join(', ');
}

// Pilih suara bahasa Indonesia bila tersedia
function pickIndonesianVoice() {
  const voices = window.speechSynthesis.getVoices() || [];
  return voices.find((v) => v.lang === 'id-ID') || voices.find((v) => v.lang?.startsWith('id')) || null;
}

export function buildCashierCallText({ plateNumber, ownerName }) {
  return `Perhatian. Atas nama ${ownerName}, dengan nomor polisi ${spellPlate(plateNumber)}, `
    + 'sudah selesai pengerjaan. Silakan ke kasir untuk melakukan pembayaran.';
}

export function speakCashierCall({ plateNumber, ownerName }) {
  if (!('speechSynthesis' in window)) {
    alert('Browser Anda tidak mendukung fitur suara (Web Speech API).');
    return;
  }
  const text = buildCashierCallText({ plateNumber, ownerName });
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = 'id-ID';
  const voice = pickIndonesianVoice();
  if (voice) utterance.voice = voice;
  utterance.rate = 0.9;

  window.speechSynthesis.cancel();
  window.speechSynthesis.speak(utterance);
}
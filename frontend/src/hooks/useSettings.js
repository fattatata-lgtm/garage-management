import { useSettingsContext } from '../context/SettingsContext';

// Objek pengaturan usaha (nama, logo, alamat, telepon, pajak) dari konteks bersama.
// Dipakai halaman cetak: data sudah siap sebelum tombol ditekan (window.open harus sinkron dari klik).
export default function useSettings() {
  return useSettingsContext().settings;
}

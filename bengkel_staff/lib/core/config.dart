/// Konfigurasi aplikasi.
class AppConfig {
  AppConfig._();

  static const String appName = 'Self Automotive';

  /// Alamat bawaan server. 10.0.2.2 = "localhost" komputer bila memakai emulator Android.
  /// Di handphone asli, ubah dari layar Login (ikon server) menjadi IP komputer, mis. 192.168.1.10:4000
  static const String defaultServerUrl = 'http://10.0.2.2:4000';

  /// Hanya role ini yang boleh masuk ke aplikasi mobile.
  /// Tambahkan 'ADMIN' bila nanti admin juga ingin memakainya.
  static const Set<String> allowedRoles = {'STAFF'};
}

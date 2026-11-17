import 'package:flutter/material.dart';

import 'api_client.dart';
import 'config.dart';
import 'demo_backend.dart';
import 'nav.dart';
import 'storage.dart';

class AppUser {
  AppUser({required this.id, required this.username, required this.email, required this.role});
  final int id;
  final String username;
  final String email;
  final String role;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: int.tryParse('${j['id']}') ?? 0,
        username: '${j['username'] ?? ''}',
        email: '${j['email'] ?? ''}',
        role: '${j['role'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {'id': id, 'username': username, 'email': email, 'role': role};

  String get roleLabel => switch (role) {
        'ADMIN' => 'Administrator',
        'STAFF' => 'Staff',
        'TEKNISI' => 'Teknisi',
        _ => role,
      };
}

class AuthProvider extends ChangeNotifier {
  AppUser? user;
  bool ready = false;

  /// Dipanggil saat aplikasi dibuka: pulihkan sesi bila token masih ada.
  Future<void> bootstrap() async {
    Api.I.onSessionExpired = () => logout(silent: false);

    if (Store.accessToken != null || Store.refreshToken != null) {
      try {
        final me = await Api.I.get('/auth/me');
        final u = AppUser.fromJson(Map<String, dynamic>.from(me as Map));
        if (AppConfig.allowedRoles.contains(u.role)) {
          user = u;
          await Store.saveUser(u.toJson());
        } else {
          await Store.clearTokens();
        }
      } on ApiException catch (e) {
        if (e.isNetwork) {
          // server belum terjangkau: tetap buka dengan data user tersimpan
          final cached = Store.cachedUser;
          if (cached != null) {
            final u = AppUser.fromJson(cached);
            if (AppConfig.allowedRoles.contains(u.role)) user = u;
          }
        } else {
          await Store.clearTokens();
        }
      } catch (_) {
        await Store.clearTokens();
      }
    }
    ready = true;
    notifyListeners();
  }

  /// Mengembalikan null bila sukses, atau pesan galat.
  Future<String?> login(String identifier, String password) async {
    try {
      final d = await Api.I.post('/auth/login', body: {'identifier': identifier, 'password': password});
      final map = Map<String, dynamic>.from(d as Map);
      final u = AppUser.fromJson(Map<String, dynamic>.from(map['user'] as Map));
      if (!AppConfig.allowedRoles.contains(u.role)) {
        return 'Aplikasi ini khusus akun Staff. Akun ${u.roleLabel} silakan memakai versi web.';
      }
      await Store.saveTokens(map['accessToken'] as String, map['refreshToken'] as String);
      await Store.saveUser(u.toJson());
      await Store.setLastUsername(identifier);
      user = u;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  /// Mode demo: tanpa server, data contoh di dalam app.
  void demoLogin() {
    DemoBackend.start();
    user = AppUser(id: 1, username: 'staff', email: 'staff@selfautomotive.test', role: 'STAFF');
    notifyListeners();
  }

  Future<void> logout({bool silent = true}) async {
    DemoBackend.stop();
    await Store.clearTokens();
    user = null;
    navigatorKey.currentState?.popUntil((r) => r.isFirst);
    AppNav.tab.value = 0;
    notifyListeners();
  }
}

import 'package:dio/dio.dart';

import 'demo_backend.dart';
import 'storage.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.status]);
  final String message;
  final int? status;

  bool get isNetwork => status == null;

  @override
  String toString() => message;
}

/// Klien REST: Bearer JWT + refresh token otomatis (sama seperti interceptor Axios di web).
class Api {
  Api._();
  static final Api I = Api._();

  late Dio _dio;
  Future<String?>? _refreshing;

  /// Dipanggil saat refresh token gagal (sesi habis).
  void Function()? onSessionExpired;

  void configure() {
    _dio = Dio(BaseOptions(
      baseUrl: Store.apiBase,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (DemoBackend.active) {
          await Future<void>.delayed(const Duration(milliseconds: 280));
          try {
            final data = DemoBackend.handle(options);
            return handler.resolve(Response(requestOptions: options, statusCode: 200, data: data));
          } on DemoError catch (e) {
            return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: options, statusCode: e.status, data: {'message': e.message}),
            ));
          }
        }
        final token = Store.accessToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        final req = e.requestOptions;
        final is401 = e.response?.statusCode == 401;
        final isAuthCall = req.path.startsWith('/auth/');
        if (is401 && !isAuthCall && req.extra['retried'] != true && Store.refreshToken != null) {
          final fresh = await _refreshToken();
          if (fresh != null) {
            req.extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer $fresh';
            try {
              final res = await _dio.fetch(req);
              return handler.resolve(res);
            } on DioException catch (e2) {
              return handler.next(e2);
            }
          } else {
            onSessionExpired?.call();
          }
        }
        handler.next(e);
      },
    ));
  }

  Future<String?> _refreshToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    try {
      final plain = Dio(BaseOptions(
        baseUrl: Store.apiBase,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
      ));
      final r = await plain.post('/auth/refresh', data: {'refreshToken': Store.refreshToken});
      final data = Map<String, dynamic>.from(r.data as Map);
      await Store.saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
      return data['accessToken'] as String;
    } catch (_) {
      await Store.clearTokens();
      return null;
    }
  }

  ApiException _toException(DioException e) {
    final data = e.response?.data;
    final code = e.response?.statusCode;
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String, code);
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Koneksi ke server timeout. Periksa jaringan Anda.');
      case DioExceptionType.connectionError:
        return ApiException('Tidak dapat terhubung ke server. Periksa alamat server & jaringan.');
      default:
        return ApiException('Terjadi kesalahan pada server (${code ?? '-'}).', code);
    }
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final r = await call();
      return r.data;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) => _send(() => _dio.post(path, data: body));

  Future<dynamic> put(String path, {Object? body}) => _send(() => _dio.put(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) => _send(() => _dio.patch(path, data: body));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  /// Unggah satu gambar (multipart/form-data), mis. logo bengkel.
  Future<dynamic> uploadImage(String path, {required String field, required String filePath, String? fileName, String? mime}) async {
    if (DemoBackend.active) throw ApiException('Unggah logo tidak tersedia pada mode demo.');
    final name = (fileName == null || fileName.isEmpty) ? filePath.split(RegExp(r'[\\/]')).last : fileName;
    const mimes = {'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'webp': 'image/webp', 'gif': 'image/gif'};
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final type = mimes[ext] ?? mime;
    if (type == null || !mimes.containsValue(type)) throw ApiException('Format logo harus PNG, JPG, WEBP, atau GIF.');
    final form = FormData.fromMap({
      field: await MultipartFile.fromFile(filePath, filename: name, contentType: DioMediaType.parse(type)),
    });
    return _send(() => _dio.post(path, data: form, options: Options(sendTimeout: const Duration(seconds: 60))));
  }

  /// GET daftar -> List<T>
  Future<List<T>> list<T>(String path, T Function(Map<String, dynamic>) f, {Map<String, dynamic>? query}) async {
    final d = await get(path, query: query);
    if (d is! List) return <T>[];
    return d.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList();
  }

  /// GET satu objek -> T
  Future<T> one<T>(String path, T Function(Map<String, dynamic>) f, {Map<String, dynamic>? query}) async {
    final d = await get(path, query: query);
    return f(Map<String, dynamic>.from(d as Map));
  }

  /// Tes koneksi ke server (tanpa token). Mengembalikan null bila OK, atau pesan galat.
  static Future<String?> ping(String serverUrl) async {
    try {
      final base = Store.normalizeServerUrl(serverUrl);
      final dio = Dio(BaseOptions(
        baseUrl: '$base/api',
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ));
      final r = await dio.get('/health');
      if (r.data is Map && r.data['status'] == 'ok') return null;
      return 'Server menjawab, tetapi bukan server Bengkel.';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return 'Timeout. Pastikan komputer server menyala & satu jaringan WiFi.';
      }
      return 'Tidak dapat terhubung. Cek alamat/port & firewall komputer server.';
    } catch (_) {
      return 'Alamat server tidak valid.';
    }
  }
}

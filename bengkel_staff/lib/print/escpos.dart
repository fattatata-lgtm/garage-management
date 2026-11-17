import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

// Encoder ESC/POS minimal untuk printer thermal 58 mm / 80 mm (port dari utils/escpos.js versi web).
// Teks dikirim sebagai ASCII murni (aksen dibuang, karakter lain -> "?") agar tampil benar di semua merek.

const int _esc = 0x1b;
const int _gs = 0x1d;
const int _lf = 0x0a;

const String _from = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÑñÇçÝýÿ';
const String _to = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCcYyy';

String toAscii(Object? value) {
  var s = (value ?? '').toString();
  s = s
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('‘', "'")
      .replaceAll('’', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('×', 'x')
      .replaceAll('•', '*')
      .replaceAll('…', '...')
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'[\r\n\t]+'), ' ');
  final sb = StringBuffer();
  for (final ch in s.split('')) {
    final i = _from.indexOf(ch);
    if (i >= 0) {
      sb.write(_to[i]);
      continue;
    }
    final c = ch.codeUnitAt(0);
    sb.write((ch.length == 1 && c >= 0x20 && c <= 0x7e) ? ch : '?');
  }
  return sb.toString();
}

/// Pecah teks menjadi baris selebar [width] karakter (kata panjang dipotong).
List<String> wrapText(String text, int width) {
  final out = <String>[];
  var line = '';
  for (var word in toAscii(text).trim().split(RegExp(r' +'))) {
    if (word.isEmpty) continue;
    while (word.length > width) {
      if (line.isNotEmpty) {
        out.add(line);
        line = '';
      }
      out.add(word.substring(0, width));
      word = word.substring(width);
    }
    if (line.isEmpty) {
      line = word;
    } else if (line.length + 1 + word.length <= width) {
      line += ' $word';
    } else {
      out.add(line);
      line = word;
    }
  }
  if (line.isNotEmpty) out.add(line);
  return out.isEmpty ? [''] : out;
}

class Raster {
  Raster(this.widthBytes, this.height, this.data);
  final int widthBytes;
  final int height;
  final Uint8List data;
}

class EscPos {
  /// cols: karakter per baris ukuran normal (58 mm = 32, 80 mm = 48 untuk Font A)
  EscPos([this.cols = 48]) {
    raw([_esc, 0x40]); // initialize
    raw([_esc, 0x74, 0x00]); // code page PC437
    raw([_esc, 0x4d, 0x00]); // Font A
  }

  final int cols;
  final List<int> _bytes = [];

  /// Salinan isi struk dalam teks (dipakai untuk pratinjau/cadangan PDF).
  final List<String> preview = [];
  String _align = 'left';
  int _sizeW = 1;

  EscPos raw(Iterable<int> arr) {
    _bytes.addAll(arr);
    return this;
  }

  EscPos text(String s) {
    final a = toAscii(s);
    for (var i = 0; i < a.length; i++) {
      _bytes.add(a.codeUnitAt(i));
    }
    return this;
  }

  void _record(String s) {
    final a = toAscii(s);
    final eff = cols ~/ _sizeW;
    if (_align == 'center' && a.length < eff) {
      preview.add(' ' * ((eff - a.length) ~/ 2) + a);
    } else if (_align == 'right' && a.length < eff) {
      preview.add(' ' * (eff - a.length) + a);
    } else {
      preview.add(a);
    }
  }

  EscPos line([String s = '']) {
    text(s);
    raw([_lf]);
    _record(s);
    return this;
  }

  EscPos feed([int n = 1]) => raw([_esc, 0x64, math.min(255, math.max(0, n))]);

  EscPos align(String a) {
    _align = a;
    return raw([_esc, 0x61, a == 'center' ? 1 : (a == 'right' ? 2 : 0)]);
  }

  EscPos bold([bool on = true]) => raw([_esc, 0x45, on ? 1 : 0]);

  EscPos size([int w = 1, int h = 1]) {
    _sizeW = math.min(8, w);
    return raw([_gs, 0x21, ((math.min(8, w) - 1) << 4) | (math.min(8, h) - 1)]);
  }

  EscPos reset() => size(1, 1).bold(false).align('left');

  EscPos divider([String ch = '-']) => line(ch * cols);

  EscPos wrap(String text) {
    for (final l in wrapText(text, cols)) {
      line(l);
    }
    return this;
  }

  /// "kiri ......... kanan"; nominal tidak pernah terpotong.
  EscPos pair(String left, String right, [int? width]) {
    final c = width ?? cols;
    final l = toAscii(left).trim();
    final r = toAscii(right);
    if (l.length + r.length + 1 <= c) return line(l + ' ' * (c - l.length - r.length) + r);
    final parts = wrapText(l, math.max(8, c - r.length - 1));
    for (var i = 0; i < parts.length; i++) {
      if (i < parts.length - 1) {
        line(parts[i]);
      } else {
        line(parts[i] + ' ' * math.max(1, c - parts[i].length - r.length) + r);
      }
    }
    return this;
  }

  /// Baris rincian bernomor. Dengan [sub] (mis. "2 x Rp50.000"): sub di kiri, nominal di kanan.
  EscPos entry(int no, String name, [String? amount, String? sub]) {
    final prefix = '$no. ';
    final indent = ' ' * prefix.length;
    final amt = amount == null ? '' : toAscii(amount);
    final lines = wrapText(name, cols - prefix.length);
    String put(String l, int i) => (i == 0 ? prefix : indent) + l;
    String right(String left, String r) => left + ' ' * math.max(1, cols - left.length - r.length) + r;
    final lastText = put(lines.last, lines.length - 1);
    final fitsLast = amt.isNotEmpty && sub == null && lastText.length + 1 + amt.length <= cols;
    for (var i = 0; i < lines.length; i++) {
      final isLast = i == lines.length - 1;
      final t = put(lines[i], i);
      line(isLast && fitsLast ? right(t, amt) : t);
    }
    if (sub != null) {
      final left = indent + toAscii(sub);
      line(amt.isNotEmpty ? right(left, amt) : left);
    } else if (amt.isNotEmpty && !fitsLast) {
      line(' ' * math.max(0, cols - amt.length) + amt);
    }
    return this;
  }

  EscPos note(String text, [int indent = 3]) {
    for (final l in wrapText(text, cols - indent)) {
      line(' ' * indent + l);
    }
    return this;
  }

  EscPos center(String text) {
    align('center');
    wrap(text);
    return align('left');
  }

  /// Judul besar (2x), otomatis dibungkus sesuai lebar yang menyusut.
  EscPos big(String text) {
    align('center').bold(true).size(2, 2);
    for (final l in wrapText(text, cols ~/ 2)) {
      line(l);
    }
    return reset();
  }

  /// Gambar 1-bit (logo) per pita 128 baris agar aman di buffer printer kecil.
  EscPos image(Raster r) {
    const band = 128;
    for (var y = 0; y < r.height; y += band) {
      final h = math.min(band, r.height - y);
      raw([_gs, 0x76, 0x30, 0x00, r.widthBytes & 0xff, r.widthBytes >> 8, h & 0xff, h >> 8]);
      raw(r.data.sublist(y * r.widthBytes, (y + h) * r.widthBytes));
    }
    return this;
  }

  /// Printer 58 mm mobile tanpa pemotong: cukup majukan kertas. 80 mm: maju lalu potong sebagian.
  EscPos cut() {
    if (cols <= 32) return feed(5);
    return feed(4).raw([_gs, 0x56, 0x42, 0x03]);
  }

  Uint8List build() => Uint8List.fromList(_bytes);
}

/// Ubah gambar (logo) menjadi bitmap 1-bit (dithering Floyd-Steinberg) untuk perintah GS v 0.
/// maxWidth dalam dot (203 dpi): 58 mm = 384, 80 mm = 576.
Future<Raster> loadRaster(Uint8List bytes, {int maxWidth = 384, int maxHeight = 160}) async {
  final c0 = await ui.instantiateImageCodec(bytes);
  final f0 = await c0.getNextFrame();
  final w0 = f0.image.width;
  final h0 = f0.image.height;
  final scale = math.min(1.0, math.min(maxWidth / w0, maxHeight / h0));
  final w = math.max(1, (w0 * scale).round());
  final h = math.max(1, (h0 * scale).round());

  final c1 = await ui.instantiateImageCodec(bytes, targetWidth: w, targetHeight: h);
  final f1 = await c1.getNextFrame();
  final bd = await f1.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (bd == null) throw Exception('Logo tidak dapat diproses.');
  final px = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
  final iw = f1.image.width;
  final ih = f1.image.height;

  final widthBytes = (iw + 7) ~/ 8;
  final W = widthBytes * 8;
  final gray = Float32List(W * ih);
  for (var y = 0; y < ih; y++) {
    for (var x = 0; x < W; x++) {
      double lum = 255;
      if (x < iw) {
        final o = (y * iw + x) * 4;
        final a = px[o + 3] / 255.0;
        double ch(int v) => v * a + 255 * (1 - a); // transparan -> putih
        lum = 0.299 * ch(px[o]) + 0.587 * ch(px[o + 1]) + 0.114 * ch(px[o + 2]);
      }
      gray[y * W + x] = ((lum - 128) * 1.15 + 128).clamp(0, 255).toDouble();
    }
  }
  final data = Uint8List(widthBytes * ih);
  for (var y = 0; y < ih; y++) {
    for (var x = 0; x < W; x++) {
      final i = y * W + x;
      final old = gray[i];
      final black = old < 128;
      if (black) data[y * widthBytes + (x >> 3)] |= 0x80 >> (x & 7);
      final err = old - (black ? 0 : 255);
      if (x + 1 < W) gray[i + 1] += err * 7 / 16;
      if (y + 1 < ih) {
        if (x > 0) gray[i + W - 1] += err * 3 / 16;
        gray[i + W] += err * 5 / 16;
        if (x + 1 < W) gray[i + W + 1] += err / 16;
      }
    }
  }
  return Raster(widthBytes, ih, data);
}

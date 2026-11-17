import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import 'motion.dart';

// =============================================================== Kartu & umum

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.margin,
    this.color,
    this.borderColor,
    this.animate = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final bool animate;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isDark = C.isDark(context);
    final radius = BorderRadius.circular(18);
    final cardColor = widget.color != null ? C.soft(context, widget.color!) : C.cardOf(context);
    final border = widget.borderColor != null ? C.soft(context, widget.borderColor!) : C.lineOf(context);

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: radius,
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x40000000) : const Color(0x0D0A1020),
            blurRadius: isDark ? 14 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: C.textOf(context)),
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            onHighlightChanged: widget.onTap == null ? null : (v) => setState(() => _down = v),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      card = AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: card,
      );
    }
    return widget.animate ? FadeSlideIn(child: card) : card;
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction, this.padding});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.textOf(context))),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.brandOf(context))),
            ),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.size = 44});
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [C.brand500, Color(0xFF0EA5E9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Text(initialOf(name),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.4)),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.color = C.brand, this.bg = C.brand50, this.size = 44});
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(color: C.soft(context, bg), borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, color: C.tone(context, color), size: size * 0.5),
    );
  }
}

class PlateBadge extends StatelessWidget {
  const PlateBadge(this.plate, {super.key});
  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: C.isDark(context) ? const Color(0xFF05080E) : C.ink,
        borderRadius: BorderRadius.circular(6),
        border: C.isDark(context) ? Border.all(color: D.line) : null,
      ),
      child: Text(plate,
          style: TextStyle(color: C.isDark(context) ? D.text : Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.bold = false, this.valueColor});
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: C.mutedOf(context), fontSize: 13.5)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? C.textOf(context),
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================== Status

Color statusColor(String s) => switch (s) {
      'DITERIMA' => C.warn,
      'DIKERJAKAN' => C.info,
      'MENUNGGU_PEMBAYARAN' => C.violet,
      'SELESAI' || 'BAIK' || 'AKTIF' || 'MASUK' => C.ok,
      'RENDAH' => C.warn,
      'HABIS' || 'KELUAR' => C.danger,
      _ => C.muted,
    };

Color statusBg(String s) => switch (s) {
      'DITERIMA' => C.warnBg,
      'DIKERJAKAN' => C.infoBg,
      'MENUNGGU_PEMBAYARAN' => C.violetBg,
      'SELESAI' || 'BAIK' || 'AKTIF' || 'MASUK' => C.okBg,
      'RENDAH' => C.warnBg,
      'HABIS' || 'KELUAR' => C.dangerBg,
      _ => C.slateBg,
    };

String statusLabel(String s) => switch (s) {
      'DITERIMA' => 'Diterima',
      'DIKERJAKAN' => 'Dikerjakan',
      'MENUNGGU_PEMBAYARAN' => 'Menunggu Bayar',
      'SELESAI' => 'Lunas',
      'BAIK' => 'Stok Baik',
      'RENDAH' => 'Stok Rendah',
      'HABIS' => 'Habis',
      'AKTIF' => 'Aktif',
      'NONAKTIF' => 'Nonaktif',
      'MASUK' => 'Masuk',
      'KELUAR' => 'Keluar',
      _ => s,
    };

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.label});
  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = C.tone(context, statusColor(status));
    final running = status == 'DIKERJAKAN';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: running ? 1 : 4),
      decoration: BoxDecoration(color: C.soft(context, statusBg(status)), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (running)
            PulseDot(color: c, size: 6)
          else ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(label ?? statusLabel(status), style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// =============================================================== Keadaan kosong / galat

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: FadeSlideIn(
        delay: Duration.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: C.soft(context, C.brand50), shape: BoxShape.circle),
                child: Icon(icon, size: 36, color: C.tone(context, C.brand500)),
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.textOf(context))),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: C.mutedOf(context), fontSize: 13.5)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Daftar kosong yang tetap bisa ditarik untuk refresh.
Widget emptyList(IconData icon, String title, [String? subtitle]) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [const SizedBox(height: 60), EmptyView(icon: icon, title: title, subtitle: subtitle)],
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeSlideIn(
          delay: Duration.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: C.soft(context, C.dangerBg), shape: BoxShape.circle),
                child: Icon(Icons.cloud_off_rounded, size: 36, color: C.tone(context, C.danger)),
              ),
              const SizedBox(height: 16),
              Text('Gagal memuat data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.textOf(context))),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: C.mutedOf(context), fontSize: 13.5)),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================== Pemuat data async

/// Memuat data, menampilkan loading/galat, mendukung tarik-untuk-refresh, dan
/// memuat ulang otomatis saat [refreshOn] berubah (mis. Bus.tick).
class AsyncBody<T> extends StatefulWidget {
  const AsyncBody({super.key, required this.loader, required this.builder, this.refreshOn, this.fullScreen = false});

  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  final Listenable? refreshOn;

  /// true bila [builder] mengembalikan Scaffold sendiri: state loading/galat dibungkus Scaffold + AppBar.
  final bool fullScreen;

  @override
  State<AsyncBody<T>> createState() => AsyncBodyState<T>();
}

class AsyncBodyState<T> extends State<AsyncBody<T>> {
  T? _data;
  bool _hasData = false;
  Object? _error;
  bool _loading = true;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    widget.refreshOn?.addListener(_onTick);
    _run();
  }

  @override
  void didUpdateWidget(covariant AsyncBody<T> old) {
    super.didUpdateWidget(old);
    if (old.refreshOn != widget.refreshOn) {
      old.refreshOn?.removeListener(_onTick);
      widget.refreshOn?.addListener(_onTick);
    }
  }

  @override
  void dispose() {
    widget.refreshOn?.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() => reload();

  Future<void> _run() async {
    final gen = ++_gen;
    try {
      final d = await widget.loader();
      if (!mounted || gen != _gen) return;
      setState(() {
        _data = d;
        _hasData = true;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || gen != _gen) return;
      setState(() {
        _error = e;
        _loading = false;
      });
      if (_hasData && mounted) toast(context, 'Gagal memperbarui: $e', error: true);
    }
  }

  Future<void> reload() async {
    if (mounted && _hasData) {
      setState(() => _loading = true);
    } else if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    await _run();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasData) {
      final Widget inner = AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: _error != null
            ? ErrorView(key: const ValueKey('err'), message: '$_error', onRetry: reload)
            : const SkeletonList(key: ValueKey('loading')),
      );
      return widget.fullScreen ? Scaffold(appBar: AppBar(), body: inner) : inner;
    }
    final content = Stack(
        children: [
          RefreshIndicator(
            onRefresh: reload,
            child: widget.builder(context, _data as T, reload),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _loading
                    ? const LinearProgressIndicator(key: ValueKey('bar'), minHeight: 2)
                    : const SizedBox(key: ValueKey('none'), height: 2),
              ),
            ),
          ),
        ],
    );
    return widget.fullScreen
        ? content
        : FadeSlideIn(delay: Duration.zero, offset: 0, duration: const Duration(milliseconds: 380), child: content);
  }
}

// =============================================================== Tombol

enum BtnKind { primary, success, danger, secondary, tonal }

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.kind = BtnKind.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final BtnKind kind;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final accent = C.brandOf(context);
    final fg = switch (kind) {
      BtnKind.secondary => accent,
      BtnKind.tonal => accent,
      _ => Colors.white,
    };
    final rawContent = busy
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: kind == BtnKind.secondary || kind == BtnKind.tonal ? accent : Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 19, color: fg), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
            ],
          );

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(key: ValueKey(busy), child: rawContent),
    );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const size = Size(0, 50);
    final VoidCallback? cb = busy ? null : onPressed;

    final Widget btn = switch (kind) {
      BtnKind.secondary => OutlinedButton(
          onPressed: cb,
          style: OutlinedButton.styleFrom(minimumSize: size, shape: shape, foregroundColor: accent, side: BorderSide(color: C.soft(context, C.brand100), width: 1.5)),
          child: content,
        ),
      BtnKind.tonal => FilledButton(
          onPressed: cb,
          style: FilledButton.styleFrom(minimumSize: size, shape: shape, backgroundColor: C.soft(context, C.brand50), foregroundColor: accent),
          child: content,
        ),
      BtnKind.danger => FilledButton(
          onPressed: cb,
          style: FilledButton.styleFrom(minimumSize: size, shape: shape, backgroundColor: C.isDark(context) ? const Color(0xFFB94747) : C.danger),
          child: content,
        ),
      BtnKind.success => FilledButton(
          onPressed: cb,
          style: FilledButton.styleFrom(minimumSize: size, shape: shape, backgroundColor: C.isDark(context) ? const Color(0xFF1F8F6E) : C.ok),
          child: content,
        ),
      BtnKind.primary => FilledButton(
          onPressed: cb,
          style: FilledButton.styleFrom(minimumSize: size, shape: shape, backgroundColor: C.fillOf(context)),
          child: content,
        ),
    };
    final animated = Pressable(enabled: cb != null, scale: 0.97, child: btn);
    return expand ? SizedBox(width: double.infinity, child: animated) : animated;
  }
}

// =============================================================== Input

OutlineInputBorder _border(Color c, [double w = 1]) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));

/// Kolom isian dengan judul DI ATAS kolom (judul tidak pernah menembus garis kolom).
class LabeledField extends StatelessWidget {
  const LabeledField(this.label, this.child, {super.key});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
        ),
        child,
      ],
    );
  }
}

/// Dekorasi input. Warna isi & garis mengikuti tema (terang / malam) kecuali diberikan eksplisit.
InputDecoration deco(String? label, {IconData? icon, String? hint, String? prefixText, Widget? suffix, Color? fillColor, Color? borderColor, bool dense = false}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    prefixIcon: icon == null ? null : Icon(icon, size: dense ? 17 : 20),
    prefixIconConstraints: dense ? const BoxConstraints(minWidth: 38, minHeight: 36) : null,
    suffixIcon: suffix,
    isDense: dense,
    filled: true,
    fillColor: fillColor,
    contentPadding: dense ? const EdgeInsets.symmetric(horizontal: 10, vertical: 11) : const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: borderColor == null ? null : _border(borderColor),
    enabledBorder: borderColor == null ? null : _border(borderColor),
  );
}

/// Kotak pilihan (membuka bottom sheet / date picker saat disentuh).
class FieldTile extends StatelessWidget {
  const FieldTile({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.onTap,
    this.error,
    this.trailing,
    this.hint,
    this.showLabel = true,
    this.dense = false,
  });

  final bool dense;
  final String label;
  final String? value;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? error;
  final Widget? trailing;
  final String? hint;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.isEmpty;
    final hintStr = hint ?? (empty ? label : null);
    final box = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        isEmpty: empty,
        decoration: deco(
          null,
          hint: hintStr,
          icon: icon,
          dense: dense,
          suffix: trailing ?? const Icon(Icons.keyboard_arrow_down_rounded),
        ).copyWith(errorText: error),
        child: Text(
          value ?? '',
          maxLines: dense ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: dense ? 13 : null, color: C.textOf(context)),
        ),
      ),
    );

    if (!showLabel || label.isEmpty) return box;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: dense ? 12 : 13, fontWeight: FontWeight.w700, color: C.mutedOf(context)),
        ),
        SizedBox(height: dense ? 4 : 6),
        box,
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, required this.onChanged, this.controller, this.trailing});
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: C.textOf(context)),
            decoration: deco(
              null,
              icon: Icons.search_rounded,
              hint: hint,
            ).copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

/// Tombol ikon filter (corong/tune) yang diletakkan di samping kolom/tombol pencarian.
class FilterIconButton extends StatelessWidget {
  const FilterIconButton({
    super.key,
    required this.onTap,
    this.isActive = false,
    this.tooltip = 'Filter',
    this.size = 50,
  });

  final VoidCallback onTap;
  final bool isActive;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        animationDuration: const Duration(milliseconds: 250),
        color: isActive ? C.fillOf(context) : C.cardOf(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isActive ? C.fillOf(context) : C.lineOf(context)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: isActive ? Colors.white : C.textOf(context),
                  size: 22,
                ),
                if (isActive)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      builder: (context, v, child) => Transform.scale(scale: v, child: child),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Baris chip untuk menampilkan dan menghapus filter yang sedang aktif.
class ActiveFilterBar extends StatelessWidget {
  const ActiveFilterBar({super.key, required this.tags, required this.onClearAll});
  final List<(String, VoidCallback)> tags;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in tags)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  builder: (context, v, child) => Transform.scale(scale: v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
                  child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
                  decoration: BoxDecoration(
                    color: C.soft(context, C.brand50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: C.soft(context, C.brand100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.brandOf(context))),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: t.$2,
                        child: Icon(Icons.close_rounded, size: 16, color: C.brandOf(context)),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            if (tags.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: onClearAll,
                  child: Text('Reset Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.tone(context, C.danger))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// True bila [d] berada dalam rentang tanggal (inklusif sampai akhir hari), sama seperti filter website.
bool inDateRange(DateTime? d, DateTime? from, DateTime? to) {
  if (from == null && to == null) return true;
  if (d == null) return false;
  final day = DateTime(d.year, d.month, d.day);
  if (from != null && day.isBefore(DateTime(from.year, from.month, from.day))) return false;
  if (to != null && day.isAfter(DateTime(to.year, to.month, to.day))) return false;
  return true;
}

// =============================================================== Dialog & toast

void toast(BuildContext context, String message, {bool error = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(message, style: TextStyle(fontWeight: FontWeight.w600, color: C.isDark(context) ? D.text : Colors.white)),
    backgroundColor: error ? (C.isDark(context) ? const Color(0xFF7A2B33) : C.danger) : (C.isDark(context) ? D.surface2 : C.ink),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String okLabel = 'Ya',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: Text(message, style: TextStyle(color: C.mutedOf(context), height: 1.4)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger ? (C.isDark(context) ? const Color(0xFFB94747) : C.danger) : C.fillOf(context)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(okLabel),
        ),
      ],
    ),
  );
  return r == true;
}

/// Pilih tanggal (bahasa Indonesia mengikuti locale perangkat).
Future<DateTime?> pickDate(BuildContext context, {DateTime? initial, DateTime? first, DateTime? last}) {
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: first ?? DateTime(2020),
    lastDate: last ?? DateTime(2100),
  );
}

String dateOrDash(DateTime? d) => d == null ? '' : fmtDate(d);

// =============================================================== Ringkasan biaya

class SummaryRow extends StatelessWidget {
  const SummaryRow(this.label, this.value, {super.key, this.bold = false, this.color, this.big = false});
  final String label;
  final String value;
  final bool bold;
  final bool big;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(color: bold ? C.textOf(context) : C.mutedOf(context), fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: big ? 16 : 14))),
          Text(value,
              style: TextStyle(color: color ?? C.textOf(context), fontWeight: bold ? FontWeight.w800 : FontWeight.w700, fontSize: big ? 20 : 14.5)),
        ],
      ),
    );
  }
}

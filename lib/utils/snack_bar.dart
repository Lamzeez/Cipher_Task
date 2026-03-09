import 'package:flutter/material.dart';

SnackBar miniSnackBar(
  BuildContext context,
  String msg, {
  Duration duration = const Duration(seconds: 2),
  bool success = true,
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: duration,
    backgroundColor: Colors.transparent,
    elevation: 0,
    margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
    content: _SnackBarCard(
      msg: msg,
      success: success,
    ),
  );
}

void showMiniSnackBar(
  BuildContext context,
  String msg, {
  Duration duration = const Duration(seconds: 2),
  bool success = true,
}) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;

  final view = View.of(context);
  final size = MediaQueryData.fromView(view).size;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 18,
      right: 18,
      top: (size.height / 2) - 42,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _SnackBarCard(
              msg: msg,
              success: success,
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(duration, () {
    if (entry.mounted) entry.remove();
  });
}

class _SnackBarCard extends StatelessWidget {
  final String msg;
  final bool success;

  const _SnackBarCard({
    required this.msg,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    final accent = success ? const Color(0xFF2F73D9) : Colors.redAccent;
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

SnackBar miniSnackBar(
  BuildContext context,
  String msg, {
  Duration duration = const Duration(seconds: 2),
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: duration,
    backgroundColor: Colors.transparent,
    elevation: 0,
    margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1730).withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.35),
          ),
        ],
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  );
}

void showMiniSnackBar(
  BuildContext context,
  String msg, {
  Duration duration = const Duration(seconds: 2),
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
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1730).withOpacity(0.97),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.24),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  color: Colors.black.withOpacity(0.38),
                ),
              ],
            ),
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
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
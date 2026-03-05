import 'package:flutter/material.dart';

/// Reusable mini-snackbar helpers.
/// Use [showMiniSnackBar] for a centered snackbar that does NOT move when the keyboard appears.
/// For the normal ScaffoldMessenger style, use:
/// ScaffoldMessenger.of(context).showSnackBar(miniSnackBar(context, 'Message'));
SnackBar miniSnackBar(
  BuildContext context,
  String msg, {
  Duration duration = const Duration(seconds: 2),
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: duration,
    // Bigger padding
    content: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, height: 1.2, fontWeight: FontWeight.w600),
      ),
    ),
    // Soft border + rounded corners so it won’t blend with dark themes
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Colors.white.withOpacity(0.18), width: 1),
    ),
  );
}

/// Shows a centered “mini snackbar” using an OverlayEntry.
///
/// This stays centered even if the keyboard opens/closes.
/// Call it like:
/// showMiniSnackBar(context, 'Saved!');
void showMiniSnackBar(
  BuildContext context,
  String msg, {
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;

  // Full-screen size independent of keyboard/viewInsets
  final view = View.of(context);
  final size = MediaQueryData.fromView(view).size;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 16,
      right: 16,
      top: (size.height / 2) - 40,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
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
                height: 1.2,
                fontWeight: FontWeight.w600,
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

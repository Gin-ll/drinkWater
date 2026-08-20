import 'dart:async';

import 'package:flutter/material.dart';

/// 顶部居中轻提示（自动消失），置于最顶层（rootOverlay）。
/// 样式：白色背景 + 细边框 + 阴影 + 图标，醒目且清爽。
void showTopToast(BuildContext context, String message, {IconData? icon}) {
  // rootOverlay: true —— 置于最顶层，覆盖页面与弹出层
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Positioned(
        top: MediaQuery.of(ctx).padding.top + 8,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x22000000)),
              boxShadow: const [
                BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon ?? Icons.check_circle_outline, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  Timer(const Duration(milliseconds: 1600), () {
    if (entry.mounted) entry.remove();
  });
}
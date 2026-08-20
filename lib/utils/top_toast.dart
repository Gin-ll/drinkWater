import 'dart:async';

import 'package:flutter/material.dart';

/// 顶部居中轻提示（自动消失），置于最顶层（rootOverlay）。
/// 样式：白色背景 + 细边框 + 阴影 + 图标，醒目且清爽。
/// 传 [actionLabel]/[onAction] 可作为可撤销提示（如「已记录一杯水 撤销」），
/// 展示时长自动延长到 [actionDuration]（默认 4 秒）。
void showTopToast(
  BuildContext context,
  String message, {
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(milliseconds: 1600),
}) {
  final hasAction = actionLabel != null && onAction != null;
  final effectiveDuration = hasAction ? const Duration(seconds: 4) : duration;
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
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
                if (hasAction) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                      foregroundColor: scheme.primary,
                    ),
                    onPressed: () {
                      onAction();
                      if (entry.mounted) entry.remove();
                    },
                    child: Text(actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  Timer(effectiveDuration, () {
    if (entry.mounted) entry.remove();
  });
}
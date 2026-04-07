import "package:flutter/material.dart";
import "package:liuban/core/session/app_session.dart";
import "package:liuban/core/session/app_session_scope.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";

class PhaseBadge extends StatelessWidget {
  const PhaseBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final (label, color) = switch (session.phase) {
          AccountPhase.guest => ("訪客", Colors.grey),
          AccountPhase.pendingVerification => ("審核中", Colors.orange),
          AccountPhase.verifiedStudent => ("已認證", Colors.green),
        };
        return Semantics(
          container: true,
          label: "帳戶狀態：$label",
          hint: "目前審核階段標示，非按鈕。${ApiDevSemantics.phaseBadgeDevNote}",
          excludeSemantics: true,
          child: Chip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            backgroundColor: color.withValues(alpha: 0.12),
          ),
        );
      },
    );
  }
}

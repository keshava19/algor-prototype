import 'package:flutter/material.dart';

import '../../core/domain/fictional_data.dart';
import 'demo_tray.dart';

class ConceptFooter extends StatelessWidget {
  const ConceptFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => showDemoTray(context),
      child: Container(
        width: double.infinity,
        color: scheme.surface,
        padding: EdgeInsets.only(
          top: 6,
          bottom: 6 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Text(
          conceptFooterText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.2,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

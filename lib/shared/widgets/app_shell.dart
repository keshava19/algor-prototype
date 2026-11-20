import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/excursion/excursion_overlay.dart';
import 'concept_footer.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        child,
        ExcursionOverlay(
          enabled: GoRouterState.of(context).uri.path == '/driver',
        ),
      ],
    ),
    bottomNavigationBar: const ConceptFooter(),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/excursion/excursion_overlay.dart';
import '../../features/excursion/excursion_push_banner.dart';
import 'concept_footer.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: Stack(
        children: [
          child,
          ExcursionOverlay(enabled: path == '/driver'),
          ExcursionPushBanner(enabled: path != '/client/sample'),
        ],
      ),
      bottomNavigationBar: const ConceptFooter(),
    );
  }
}

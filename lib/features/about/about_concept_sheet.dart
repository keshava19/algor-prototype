import 'package:flutter/material.dart';

Future<void> showAboutConceptSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const AboutConceptSheet(),
    );

class AboutConceptSheet extends StatelessWidget {
  const AboutConceptSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About this concept', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'Algor Field is a concept prototype prepared for Algor Supply '
              'Chain Solutions. It contains no live data, no connection to '
              'Algor systems and no client information. Shipment, driver, '
              'vehicle and consignee details are fictional.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Phase 1 — Driver & field MVP: offline-first checklist, seal '
              'capture, e-POD and excursion acknowledgement.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Phase 2 — Client visibility: live temperature curve, custody '
              'trail and one-tap audit reports that support GDP documentation.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'One owner per fact. The app never creates temperature or '
              'location data; the logger and tracker own those, and the app '
              'reads them. The driver owns only what no sensor can know, '
              'captured as append-only events with unique IDs.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Designed with DPDP obligations in mind: notice and consent, '
              'minimal collection, encrypted storage and Indian hosting are '
              'part of the Phase 1 build. This concept uses mock data only.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'One Flutter codebase sits on top of existing tracking data, so '
              'live operations stay untouched.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

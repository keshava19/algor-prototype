import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/scenario/providers.dart';
import '../../core/theme/app_theme.dart';

Future<void> showCallSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String custodyTitle,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isDismissible: false,
  enableDrag: false,
  builder: (_) =>
      CallSheet(title: title, subtitle: subtitle, custodyTitle: custodyTitle),
);

class CallSheet extends ConsumerStatefulWidget {
  const CallSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.custodyTitle,
  });

  final String title;
  final String subtitle;
  final String custodyTitle;

  @override
  ConsumerState<CallSheet> createState() => _CallSheetState();
}

class _CallSheetState extends ConsumerState<CallSheet> {
  Timer? _timer;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _connected = true);
      ref
          .read(scenarioControllerProvider.notifier)
          .recordCall(widget.custodyTitle);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: (_connected ? AppColors.success : AppColors.cyan)
                    .withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _connected ? Icons.call_end : Icons.phone_in_talk,
                color: _connected ? AppColors.success : AppColors.cyan,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _connected ? 'Connected' : 'Ringing…',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _connected ? AppColors.success : AppColors.queued,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _connected
                  ? 'Simulated call — no number dialled. Logged to the '
                        'custody trail.'
                  : 'Simulated call for concept demo',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _connected
                    ? () => Navigator.of(context).pop()
                    : null,
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

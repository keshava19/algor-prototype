import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/scenario/providers.dart';
import '../../core/util/formatters.dart';

const _reasonCodes = <String>[
  'Compressor reset',
  'Door resealed',
  'Sensor drift checked',
  'Other',
];

Future<void> showLogActionSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const LogActionSheet(),
    );

class LogActionSheet extends ConsumerStatefulWidget {
  const LogActionSheet({super.key});

  @override
  ConsumerState<LogActionSheet> createState() => _LogActionSheetState();
}

class _LogActionSheetState extends ConsumerState<LogActionSheet> {
  String _reasonCode = _reasonCodes.first;
  final TextEditingController _noteController = TextEditingController();

  bool get _isOther => _reasonCode == 'Other';

  bool get _canSubmit => !_isOther || _noteController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scenarioControllerProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log action', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${formatClock(state.tick)} · ${state.excursion?.location ?? ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text('Reason code', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in _reasonCodes)
                ChoiceChip(
                  label: Text(code),
                  selected: _reasonCode == code,
                  onSelected: (_) => setState(() => _reasonCode = code),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _isOther ? 'Note (required)' : 'Note (optional)',
              hintText: 'e.g. compressor restarted, set-point restored',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Both paths record a custody event. The reading stays pinned until '
            'the box recovers.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _canSubmit
                ? () {
                    ref
                        .read(scenarioControllerProvider.notifier)
                        .acknowledge(
                          reasonCode: _reasonCode,
                          note: _noteController.text,
                        );
                    Navigator.of(context).pop();
                  }
                : null,
            child: const Text('Save acknowledgement'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

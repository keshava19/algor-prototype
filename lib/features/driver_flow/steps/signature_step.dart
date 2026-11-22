import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import '../../../core/domain/fictional_data.dart';
import '../../../core/domain/route.dart';
import '../../../core/scenario/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/formatters.dart';

class SignatureStep extends ConsumerStatefulWidget {
  const SignatureStep({super.key});

  @override
  ConsumerState<SignatureStep> createState() => _SignatureStepState();
}

class _SignatureStepState extends ConsumerState<SignatureStep> {
  late final SignatureController _signatureController;
  final TextEditingController _nameController = TextEditingController(
    text: consigneeName,
  );
  final TextEditingController _noteController = TextEditingController();
  bool _hasInk = false;
  String? _deliveryNote;

  bool get _isOther => _deliveryNote == deliveryNoteOtherLabel;

  bool get _canDone =>
      _hasInk && (!_isOther || _noteController.text.trim().isNotEmpty);

  String? get _resolvedNote => _isOther
      ? (_noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim())
      : _deliveryNote;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3.2,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    )..addListener(_handleInkChanged);
  }

  void _handleInkChanged() {
    final hasInk = _signatureController.isNotEmpty;
    if (hasInk != _hasInk) setState(() => _hasInk = hasInk);
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final bytes = await _signatureController.toPngBytes();
    if (bytes == null || !mounted) return;
    final name = _nameController.text.trim().isEmpty
        ? consigneeName
        : _nameController.text.trim();
    ref
        .read(scenarioControllerProvider.notifier)
        .captureSignature(bytes, name, deliveryNote: _resolvedNote);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scenarioControllerProvider);
    final theme = Theme.of(context);
    final position = positionOnRoute(state.tick);
    final captured = state.signature;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        Text(
          'Consignee signature',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatCoordinate(position.lat, position.lng)} · '
          '${formatClock(state.tick)} IST',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        if (captured == null) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Signature(
              controller: _signatureController,
              height: 200,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: _signatureController.clear,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Consignee name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Text(deliveryNoteLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text(deliveryNoteNoneLabel),
                selected: _deliveryNote == null,
                onSelected: (_) => setState(() => _deliveryNote = null),
              ),
              for (final option in deliveryNoteOptions)
                ChoiceChip(
                  label: Text(option),
                  selected: _deliveryNote == option,
                  onSelected: (_) => setState(() {
                    _deliveryNote = option;
                    _noteController.clear();
                  }),
                ),
            ],
          ),
          if (_isOther) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              minLines: 1,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Note (required)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _canDone ? _done : null,
            child: const Text('Done'),
          ),
        ] else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Signed by ${captured.name} at '
                        '${formatClock(captured.tick)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  if (captured.deliveryNote != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Delivery note: ${captured.deliveryNote}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Image.memory(captured.bytes, height: 70),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

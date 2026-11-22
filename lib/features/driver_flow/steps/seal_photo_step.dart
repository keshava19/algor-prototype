import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/fictional_data.dart';
import '../../../core/domain/route.dart';
import '../../../core/scenario/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/formatters.dart';

class SealPhotoStep extends ConsumerStatefulWidget {
  const SealPhotoStep({super.key});

  @override
  ConsumerState<SealPhotoStep> createState() => _SealPhotoStepState();
}

class _SealPhotoStepState extends ConsumerState<SealPhotoStep> {
  final TextEditingController _sealController = TextEditingController(
    text: defaultSealNumber,
  );
  bool _photoTaken = false;

  @override
  void dispose() {
    _sealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scenarioControllerProvider);
    final controller = ref.read(scenarioControllerProvider.notifier);
    final theme = Theme.of(context);
    final position = positionOnRoute(state.lastFeedTick);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        Text(
          'Seal photo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Geotagged and timestamped. Everything stays on the device when '
          'the network drops.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.asset(
                'assets/images/reefer_door_seal.png',
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              if (!_photoTaken)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: const Text(
                      'Tap capture to attach a geotagged photo',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              if (_photoTaken)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    child: Text(
                      formatWatermark(position, state.tick),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _photoTaken
              ? null
              : () => setState(() => _photoTaken = true),
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(
            _photoTaken ? 'Seal photo captured' : 'Capture seal photo',
          ),
        ),
        if (_photoTaken) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _sealController,
            decoration: const InputDecoration(
              labelText: 'Seal number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (state.sealVerified)
            Row(
              children: [
                const Icon(Icons.verified, color: AppColors.success, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$sealVerifiedLabel ✓ (${state.sealNumber})',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            FilledButton.tonal(
              onPressed: () =>
                  controller.confirmSeal(_sealController.text.trim()),
              child: Text(sealVerifiedLabel),
            ),
        ],
      ],
    );
  }
}

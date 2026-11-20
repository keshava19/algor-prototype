import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/fictional_data.dart';
import '../../../core/scenario/providers.dart';
import '../../../core/theme/app_theme.dart';

class ScanStep extends ConsumerStatefulWidget {
  const ScanStep({super.key});

  @override
  ConsumerState<ScanStep> createState() => _ScanStepState();
}

class _ScanStepState extends ConsumerState<ScanStep> {
  bool _scanning = false;

  Future<void> _scan() async {
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    ref.read(scenarioControllerProvider.notifier).confirmScan();
    setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scenarioControllerProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        Text(
          'Scan AWB / LR',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Camera capture is simulated in this concept build.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state.scanned
                  ? AppColors.success.withValues(alpha: 0.7)
                  : AppColors.cyan.withValues(alpha: 0.4),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_scanning)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  builder: (context, value, child) => Align(
                    alignment: Alignment(0, value * 2 - 1),
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      color: AppColors.danger,
                    ),
                  ),
                ),
              if (state.scanned)
                const Icon(Icons.qr_code, size: 64, color: AppColors.success)
              else
                const Icon(
                  Icons.qr_code_scanner,
                  size: 64,
                  color: AppColors.cyan,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (state.scanned)
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              title: Text(awbLabel),
              subtitle: const Text('Matches trip manifest'),
              trailing: TextButton(
                onPressed: _scanning ? null : _scan,
                child: const Text('Retry'),
              ),
            ),
          )
        else
          FilledButton.icon(
            onPressed: _scanning ? null : _scan,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(_scanning ? 'Scanning…' : 'Tap to scan'),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/fictional_data.dart';
import '../../core/scenario/providers.dart';
import '../../core/scenario/scenario_state.dart';
import '../../core/theme/app_theme.dart';
import 'steps/checklist_step.dart';
import 'steps/confirm_step.dart';
import 'steps/scan_step.dart';
import 'steps/seal_photo_step.dart';
import 'steps/signature_step.dart';

class DriverFlowScreen extends ConsumerStatefulWidget {
  const DriverFlowScreen({super.key});

  @override
  ConsumerState<DriverFlowScreen> createState() => _DriverFlowScreenState();
}

class _DriverFlowScreenState extends ConsumerState<DriverFlowScreen> {
  final PageController _pageController = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _canContinue(ScenarioState state) => switch (_step) {
    0 => state.checklist.every((item) => item.confirmed),
    1 => state.scanned,
    2 => state.sealVerified,
    3 => state.signature != null,
    _ => true,
  };

  void _continue(ScenarioState state) {
    final controller = ref.read(scenarioControllerProvider.notifier);
    if (_step == 0) controller.completeChecklist();
    if (_step == 4) {
      context.go('/client');
      return;
    }
    setState(() => _step += 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scenarioControllerProvider);
    final controller = ref.read(scenarioControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver & e-POD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Role picker',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Step ${_step + 1} of 5',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.cyan,
                      ),
                    ),
                    const Spacer(),
                    Text(offlineToggleLabel, style: theme.textTheme.bodySmall),
                    Switch(
                      value: state.isOffline,
                      onChanged: controller.setOffline,
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / 5,
                    minHeight: 4,
                    backgroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.isOffline)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.queued.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.queued.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: AppColors.queued),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.signature == null
                          ? offlineBanner(state.queue.length)
                          : epodHeldLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                ChecklistStep(),
                ScanStep(),
                SealPhotoStep(),
                SignatureStep(),
                ConfirmStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                if (_step > 0)
                  OutlinedButton(onPressed: _back, child: const Text('Back')),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _canContinue(state)
                        ? () => _continue(state)
                        : null,
                    child: Text(_step == 4 ? 'View client view' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

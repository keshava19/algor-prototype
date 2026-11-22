import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/models.dart';
import '../../core/scenario/providers.dart';
import '../../core/scenario/scenario_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/formatters.dart';

class ExcursionPushBanner extends ConsumerStatefulWidget {
  const ExcursionPushBanner({super.key, required this.enabled});

  final bool enabled;

  @override
  ConsumerState<ExcursionPushBanner> createState() =>
      _ExcursionPushBannerState();
}

class _ExcursionPushBannerState extends ConsumerState<ExcursionPushBanner> {
  bool _visible = false;
  Timer? _timer;

  void _show() {
    _timer?.cancel();
    setState(() => _visible = true);
    _timer = Timer(const Duration(seconds: 5), _hide);
  }

  void _hide() {
    _timer?.cancel();
    if (!mounted || !_visible) return;
    setState(() => _visible = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScenarioState>(scenarioControllerProvider, (previous, next) {
      if (!widget.enabled) return;
      final becameActive =
          previous?.phase != TripPhase.excursionActive &&
          next.phase == TripPhase.excursionActive;
      if (becameActive) _show();
      if (next.phase != TripPhase.excursionActive) _hide();
    });
    final state = ref.watch(scenarioControllerProvider);
    final theme = Theme.of(context);
    final visible = _visible && widget.enabled;

    return IgnorePointer(
      ignoring: !visible,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, -1.2),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Material(
                  color: AppColors.surfaceRaised,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _hide,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              size: 20,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ALGOR FIELD · EXCURSION ALERT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 0.7,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  state.bandProfile.excursionTitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${state.excursion?.location ?? ''} · '
                                  '${formatClock(state.excursion?.startedTick ?? state.tick)} IST',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _hide,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Dismiss',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

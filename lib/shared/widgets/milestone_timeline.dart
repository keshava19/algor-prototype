import 'package:flutter/material.dart';

import '../../core/domain/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/formatters.dart';

class MilestoneTimeline extends StatelessWidget {
  const MilestoneTimeline({super.key, required this.events});

  final List<CustodyEvent> events;

  @override
  Widget build(BuildContext context) {
    final ordered = events.reversed.toList();
    return Column(
      children: [
        for (var index = 0; index < ordered.length; index++)
          _MilestoneRow(
            key: ValueKey(ordered[index].eventId),
            event: ordered[index],
            newest: index == 0,
            last: index == ordered.length - 1,
          ),
      ],
    );
  }
}

class _MilestoneRow extends StatefulWidget {
  const _MilestoneRow({
    super.key,
    required this.event,
    required this.newest,
    required this.last,
  });

  final CustodyEvent event;
  final bool newest;
  final bool last;

  @override
  State<_MilestoneRow> createState() => _MilestoneRowState();
}

class _MilestoneRowState extends State<_MilestoneRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final event = widget.event;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: widget.newest ? AppColors.cyan : scheme.outline,
                  shape: BoxShape.circle,
                ),
              ),
              if (!widget.last)
                Container(
                  width: 2,
                  height: 26,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontSize: 13)),
                    if (event.detail != null)
                      Text(
                        event.detail!,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    if (_expanded) ...[
                      const SizedBox(height: 6),
                      _Detail(label: 'Event ID', value: event.eventId),
                      _Detail(label: 'Actor', value: event.actor ?? '—'),
                      _Detail(label: 'Source', value: event.source ?? '—'),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatClock(event.tick),
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 14,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

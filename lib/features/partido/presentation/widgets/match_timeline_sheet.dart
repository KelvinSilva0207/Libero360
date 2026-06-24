import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/timeline_event.dart';

class MatchTimelineSheet extends StatefulWidget {
  final List<TimelineEvent> events;

  const MatchTimelineSheet({super.key, required this.events});

  @override
  State<MatchTimelineSheet> createState() => _MatchTimelineSheetState();
}

class _MatchTimelineSheetState extends State<MatchTimelineSheet> {
  String _selectedFilter = _filterAll;

  static const _filterAll = 'Todos';
  static const _filterActions = 'Jugadas';
  static const _filterServices = 'Servicios';
  static const _filterRotations = 'Rotaciones';
  static const _filterSubs = 'Sustituciones';
  static const _filterLiberos = 'Líberos';
  static const _filterTimeouts = 'Timeouts';

  static const _filters = [
    _filterAll,
    _filterActions,
    _filterServices,
    _filterRotations,
    _filterSubs,
    _filterLiberos,
    _filterTimeouts,
  ];

  bool _matchesFilter(TimelineEvent e) {
    switch (_selectedFilter) {
      case _filterActions:
        return e.type == TimelineEvent.typePlayerAction;
      case _filterServices:
        return e.type == TimelineEvent.typeService;
      case _filterRotations:
        return e.type == TimelineEvent.typeRotation;
      case _filterSubs:
        return e.type == TimelineEvent.typeSubstitution;
      case _filterLiberos:
        return e.type == TimelineEvent.typeLiberoSwap;
      case _filterTimeouts:
        return e.type == TimelineEvent.typeTimeout;
      default:
        return true;
    }
  }

  String _iconFor(String type) {
    switch (type) {
      case TimelineEvent.typeMatchStarted:
        return '\u{1F3C6}';
      case TimelineEvent.typeService:
        return '\u{1F3D0}';
      case TimelineEvent.typeRotation:
        return '\u{1F504}';
      case TimelineEvent.typeSubstitution:
        return '\u{1F501}';
      case TimelineEvent.typeLiberoSwap:
        return '\u{1F7E3}';
      case TimelineEvent.typePlayerAction:
        return '\u{2694}';
      case TimelineEvent.typeTimeout:
        return '\u{23F1}';
      case TimelineEvent.typeSetEnd:
        return '\u{1F3C1}';
      case TimelineEvent.typeMatchEnd:
        return '\u{1F3C6}';
      default:
        return '\u{2022}';
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case TimelineEvent.typeMatchStarted:
        return Colors.green;
      case TimelineEvent.typeService:
        return Colors.orange;
      case TimelineEvent.typeRotation:
        return Colors.cyan;
      case TimelineEvent.typeSubstitution:
        return Colors.yellow;
      case TimelineEvent.typeLiberoSwap:
        return Colors.purple;
      case TimelineEvent.typePlayerAction:
        return AppColors.accent;
      case TimelineEvent.typeTimeout:
        return Colors.red;
      case TimelineEvent.typeSetEnd:
        return Colors.blue;
      case TimelineEvent.typeMatchEnd:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _timeText(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.events.where(_matchesFilter).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Crónica',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _filters.map((f) {
                final selected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      f,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.accent.withValues(alpha: 0.3),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: selected
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Separator
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          // Events list
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Sin eventos',
                      style: TextStyle(color: Colors.white24),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final event = filtered[index];
                      final color = _colorFor(event.type);
                      final isLast = index == filtered.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Timeline gutter
                            SizedBox(
                              width: 60,
                              child: Column(
                                children: [
                                  Container(
                                    width: 2,
                                    height: 8,
                                    color: index == 0
                                        ? Colors.transparent
                                        : color.withValues(alpha: 0.3),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color.withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: color,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _iconFor(event.type),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: isLast
                                          ? Colors.transparent
                                          : color.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Content card
                            Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.only(bottom: 6, right: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Time + set badge row
                                    Row(
                                      children: [
                                        Text(
                                          _timeText(event.time),
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.06),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'SET ${event.set}',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.35),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Title
                                    Text(
                                      event.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    // Player info
                                    if (event.playerName != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            event.playerName!,
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (event.playerId != null) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '#${event.playerId}',
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                    // Metadata rows
                                    if (event.metadata != null &&
                                        event.metadata!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      ...event.metadata!.entries.map((e) {
                                        final val =
                                            '${e.value}';
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 3,
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                val,
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

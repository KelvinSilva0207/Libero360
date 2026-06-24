import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../data/rotation_stats_model.dart';
import '../../data/rotation_stats_repository.dart';
import '../viewmodels/rotation_stats_viewmodel.dart';

class RotationDetailSheet extends StatefulWidget {
  final int rotationIndex;

  const RotationDetailSheet({super.key, required this.rotationIndex});

  @override
  State<RotationDetailSheet> createState() => _RotationDetailSheetState();
}

class _RotationDetailSheetState extends State<RotationDetailSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RotationStatsViewModel>().loadDetail(widget.rotationIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final vm = context.watch<RotationStatsViewModel>();
    final detail = vm.selectedDetail;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.background : AppColors.lightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: vm.detailLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                    : detail == null
                        ? Center(
                            child: Text('Sin datos', style: TextStyle(color: _sec(isDark))),
                          )
                        : _buildContent(detail, isDark, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(RotationStatsDetail detail, bool isDark, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: Text('R${detail.rotationIndex + 1}',
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                fontSize: 28, fontWeight: FontWeight.bold,
              )),
        ),
        const SizedBox(height: 20),
        _CourtMini(detail: detail, isDark: isDark),
        const SizedBox(height: 20),
        _StatsRow(detail: detail, isDark: isDark),
        const SizedBox(height: 16),
        _HistorySection(detail: detail, isDark: isDark),
      ],
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
}

class _CourtMini extends StatelessWidget {
  final RotationStatsDetail detail;
  final bool isDark;

  const _CourtMini({required this.detail, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = _bg(isDark);
    final border = _bd(isDark);

    if (detail.playerSlotsList.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Center(
          child: Text('Sin datos de formación', style: TextStyle(color: _sec(isDark))),
        ),
      );
    }

    final latestSlots = detail.playerSlotsList.last;
    final zones = [4, 3, 2, 5, 6, 1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        children: [
          Text('FORMACIÓN', style: TextStyle(
            color: _sec(isDark), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5,
          )),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int row = 0; row < 2; row++)
                  Padding(
                    padding: EdgeInsets.only(right: row == 0 ? 24 : 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (int col = 0; col < 3; col++)
                          _PlayerSlot(
                            zoneNumber: zones[row * 3 + col],
                            playerNumber: row * 3 + col < latestSlots.length ? latestSlots[row * 3 + col] : null,
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Red', style: TextStyle(color: _sec(isDark), fontSize: 10)),
        ],
      ),
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color _bg(bool d) => d ? AppColors.surface : AppColors.lightCard;
  Color _bd(bool d) => d ? AppColors.border : AppColors.lightBorder;
}

class _PlayerSlot extends StatelessWidget {
  final int zoneNumber;
  final int? playerNumber;
  final bool isDark;

  const _PlayerSlot({required this.zoneNumber, required this.playerNumber, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isServer = zoneNumber == 1;
    return Container(
      width: 36, height: 36,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isServer
            ? AppColors.accent.withValues(alpha: 0.2)
            : (isDark ? AppColors.surfaceLight : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isServer ? AppColors.accent : (isDark ? AppColors.border : AppColors.lightBorder),
          width: isServer ? 1.5 : 0.5,
        ),
      ),
      child: Center(
        child: Text(
          playerNumber != null ? '#${playerNumber!}' : '-',
          style: TextStyle(
            color: isServer ? AppColors.accent : _sec(isDark),
            fontSize: 10, fontWeight: isServer ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
}

class _StatsRow extends StatelessWidget {
  final RotationStatsDetail detail;
  final bool isDark;

  const _StatsRow({required this.detail, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = _bg(isDark);
    final border = _bd(isDark);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        children: [
          _MiniStat(label: 'Victorias', value: '${detail.pointsWon}', color: AppColors.success, isDark: isDark),
          Container(width: 1, height: 36, color: border),
          _MiniStat(label: 'Derrotas', value: '${detail.pointsLost}', color: AppColors.error, isDark: isDark),
          Container(width: 1, height: 36, color: border),
          _MiniStat(label: 'Duración prom.', value: detail.avgDurationFormatted, color: AppColors.primary, isDark: isDark),
        ],
      ),
    );
  }

  Color _bg(bool d) => d ? AppColors.surface : AppColors.lightCard;
  Color _bd(bool d) => d ? AppColors.border : AppColors.lightBorder;
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _MiniStat({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final RotationStatsDetail detail;
  final bool isDark;

  const _HistorySection({required this.detail, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = _bg(isDark);
    final border = _bd(isDark);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HISTORIAL', style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5,
          )),
          const SizedBox(height: 16),
          if (detail.setHistory.isEmpty)
            Text('Sin historial', style: TextStyle(color: _sec(isDark), fontSize: 13))
          else
            ...detail.setHistory.map((h) => _HistoryRow(history: h, isDark: isDark)),
        ],
      ),
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color _bg(bool d) => d ? AppColors.surface : AppColors.lightCard;
  Color _bd(bool d) => d ? AppColors.border : AppColors.lightBorder;
}

class _HistoryRow extends StatelessWidget {
  final RotationSetHistory history;
  final bool isDark;

  const _HistoryRow({required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPositive = history.netPoints >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('SET ${history.setNumber}',
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Text(history.label,
              style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(history.netLabel,
                style: TextStyle(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontSize: 14, fontWeight: FontWeight.bold,
                )),
          ),
        ],
      ),
    );
  }
}

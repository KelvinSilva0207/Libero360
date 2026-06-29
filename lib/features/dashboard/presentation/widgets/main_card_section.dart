import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/dashboard_model.dart';

class MainCardSection extends StatelessWidget {
  final NextEvent? nextTraining;
  final NextEvent? nextMatch;
  final bool isDark;
  final VoidCallback? onTrainingTap;
  final VoidCallback? onMatchTap;

  const MainCardSection({
    super.key,
    this.nextTraining,
    this.nextMatch,
    required this.isDark,
    this.onTrainingTap,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final borderClr = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? Colors.white : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderClr),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Próximos Eventos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPri,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (nextTraining != null) _eventTile(
                icon: '📅',
                label: 'Próximo entrenamiento',
                title: nextTraining!.title,
                time: _formatDate(nextTraining!.dateTime),
                textPri: textPri,
                textSec: textSec,
              ),
              if (nextTraining != null && nextMatch != null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
              if (nextMatch != null) _eventTile(
                icon: '⚽',
                label: 'Próximo partido',
                title: nextMatch!.subtitle != null
                    ? '${nextMatch!.subtitle} vs ${nextMatch!.title.replaceAll('Partido vs ', '')}'
                    : nextMatch!.title,
                time: _formatDate(nextMatch!.dateTime),
                textPri: textPri,
                textSec: textSec,
              ),
              if (nextTraining != null || nextMatch != null) ...[
                const SizedBox(height: 20),
                _countdown(nextTraining?.dateTime ?? nextMatch!.dateTime, textPri, textSec),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: nextMatch != null ? onMatchTap : onTrainingTap,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Ver detalles',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
              if (nextTraining == null && nextMatch == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No hay eventos programados',
                      style: TextStyle(color: textSec, fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
  }

  Widget _eventTile({
    required String icon,
    required String label,
    required String title,
    required String time,
    required Color textPri,
    required Color textSec,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: textSec, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(title,
                  style: TextStyle(color: textPri, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(time,
                  style: TextStyle(color: textSec, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _countdown(DateTime target, Color textPri, Color textSec) {
    final diff = target.difference(DateTime.now());
    final days = diff.inDays.clamp(0, 999);
    final hours = (diff.inHours % 24).clamp(0, 23);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceLight : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Faltan', style: TextStyle(color: textSec, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countUnit('$days', 'días', textPri, textSec),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              _countUnit('$hours', 'horas', textPri, textSec),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countUnit(String value, String label, Color textPri, Color textSec) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textPri)),
        Text(label, style: TextStyle(fontSize: 11, color: textSec)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} · $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}

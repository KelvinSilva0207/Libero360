import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/match_end_record.dart';
import '../../../estadisticas/data/models/models.dart';

class MatchEndDialog extends StatefulWidget {
  final MatchEndRecord record;

  const MatchEndDialog({super.key, required this.record});

  @override
  State<MatchEndDialog> createState() => _MatchEndDialogState();
}

class _MatchEndDialogState extends State<MatchEndDialog> {
  String? _photoPath;
  bool _showPhotoPicker = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: source, maxWidth: 1200);
      if (xFile != null) {
        setState(() {
          _photoPath = xFile.path;
          _showPhotoPicker = false;
        });
      }
    } catch (_) {}
  }

  static const _typeLabels = {
    TipoAccion.ataque: 'Ataques',
    TipoAccion.saque: 'Saques',
    TipoAccion.bloqueo: 'Bloqueos',
    TipoAccion.defensa: 'Defensas',
    TipoAccion.recepcion: 'Recepciones',
    TipoAccion.colocacion: 'Colocaciones',
    TipoAccion.errorContrario: 'Errores contrarios',
  };

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 640),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_photoPath != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.file(
                  File(_photoPath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 120),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFinalBadge(),
                    const SizedBox(height: 20),
                    _buildScoreSection(r),
                    const SizedBox(height: 6),
                    Text(
                      'Gana ${r.winnerName}',
                      style: TextStyle(
                        color: AppColors.accent.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (r.setScores.isNotEmpty) _buildSetScores(r),
                    const SizedBox(height: 20),
                    _divider(),
                    const SizedBox(height: 16),
                    _sectionTitle('Jugadoras destacadas'),
                    const SizedBox(height: 12),
                    _AwardGrid(r: r),
                    if (r.statistics.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _divider(),
                      const SizedBox(height: 16),
                      _sectionTitle('Estadísticas del partido'),
                      const SizedBox(height: 12),
                      ...r.statistics.entries.map((e) => _StatRow(
                        label: _typeLabels[e.key] ?? e.key.name,
                        count: e.value,
                      )),
                    ],
                    const SizedBox(height: 24),
                    _buildButton(
                      icon: Icons.bar_chart,
                      label: 'Ver estadísticas',
                      onTap: () => Navigator.of(context).pop('stats'),
                    ),
                    const SizedBox(height: 8),
                    _buildButton(
                      icon: Icons.camera_alt,
                      label: _photoPath != null ? 'Cambiar foto' : 'Añadir foto',
                      onTap: () => setState(() => _showPhotoPicker = !_showPhotoPicker),
                    ),
                    if (_showPhotoPicker)
                      _buildPhotoPicker(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop('finalize'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white38,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Volver', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 16, color: AppColors.accent),
          SizedBox(width: 6),
          Text(
            'FINAL',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(MatchEndRecord r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              r.localSets.toString(),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              r.localName,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text(
                'vs',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                r.durationText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Text(
              r.visitorSets.toString(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              r.visitorName,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSetScores(MatchEndRecord r) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: List.generate(r.setScores.length, (i) {
          final entry = r.setScores[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Set ${i + 1}: ${entry.key}-${entry.value}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _divider() {
    return Container(height: 1, color: Colors.white.withValues(alpha: 0.06));
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.07),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white54, size: 20),
            title: const Text('Cámara', style: TextStyle(color: Colors.white, fontSize: 13)),
            dense: true,
            onTap: () => _pickImage(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.white54, size: 20),
            title: const Text('Galería', style: TextStyle(color: Colors.white, fontSize: 13)),
            dense: true,
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _AwardGrid extends StatelessWidget {
  final MatchEndRecord r;
  const _AwardGrid({required this.r});

  @override
  Widget build(BuildContext context) {
    final awards = <_AwardItem>[
      _AwardItem(
        icon: Icons.emoji_events,
        label: 'MVP',
        value: r.mvpPlayerName != null ? '${r.mvpPlayerName}  ${r.mvpPoints} pts' : null,
      ),
      _AwardItem(
        icon: Icons.sports_kabaddi,
        label: 'Mejor anotadora',
        value: r.bestScorerName != null ? '${r.bestScorerName}  ${r.bestScorerPoints} pts' : null,
      ),
      _AwardItem(
        icon: Icons.sports_volleyball,
        label: 'Mejor saque',
        value: r.bestServerName != null ? '${r.bestServerName}  ${r.bestServerStreak} seg.' : null,
      ),
      _AwardItem(
        icon: Icons.shield,
        label: 'Mejor bloqueo',
        value: r.bestBlockerName != null ? '${r.bestBlockerName}  ${r.bestBlockerCount} bloq.' : null,
      ),
      _AwardItem(
        icon: Icons.pan_tool,
        label: 'Mejor recepción',
        value: r.bestReceiverName != null ? '${r.bestReceiverName}  ${r.bestReceiverCount} rec.' : null,
      ),
    ];

    final visible = awards.where((a) => a.value != null).toList();
    if (visible.isEmpty) {
      return Text(
        'No hay datos registrados',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
      );
    }

    return Column(
      children: visible
          .map((a) => _AwardRow(icon: a.icon, label: a.label, value: a.value!))
          .toList(),
    );
  }
}

class _AwardItem {
  final IconData icon;
  final String label;
  final String? value;
  const _AwardItem({required this.icon, required this.label, this.value});
}

class _AwardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _AwardRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int count;
  const _StatRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

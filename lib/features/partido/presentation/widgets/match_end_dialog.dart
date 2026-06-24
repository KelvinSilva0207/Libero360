import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/match_end_record.dart';

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo banner
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
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FINAL badge
                    Container(
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
                    ),
                    const SizedBox(height: 20),
                    // Score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              widget.record.localSets.toString(),
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.record.localName,
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
                          child: Text(
                            'vs',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.15),
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              widget.record.visitorSets.toString(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.record.visitorName,
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
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gana ${widget.record.winnerName}',
                      style: TextStyle(
                        color: AppColors.accent.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                    const SizedBox(height: 16),
                    // Stats
                    _Row(icon: Icons.emoji_events, label: 'MVP', value: widget.record.mvpPlayerName != null
                        ? '${widget.record.mvpPlayerName}  ${widget.record.mvpPoints} pts'
                        : '—'),
                    _Row(icon: Icons.timer, label: 'Duración', value: widget.record.durationText),
                    _Row(icon: Icons.swap_vert, label: 'Mejor servicio', value: widget.record.bestServerName != null
                        ? '${widget.record.bestServerName}  ${widget.record.bestServerStreak} consecutivos'
                        : '—'),
                    _Row(icon: Icons.rotate_right, label: 'Mejor rotación', value: widget.record.bestRotationIndex != null
                        ? 'R${widget.record.bestRotationIndex}  +${widget.record.bestRotationDiff} diferencia'
                        : '—'),
                    const SizedBox(height: 24),
                    // Buttons
                    _buildButton(
                      icon: Icons.bar_chart,
                      label: 'Ver estadísticas',
                      onTap: () => Navigator.of(context).pop('stats'),
                    ),
                    const SizedBox(height: 8),
                    _buildButton(
                      icon: Icons.share,
                      label: 'Compartir',
                      onTap: () {
                        // TODO: export image + share via share_plus
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildButton(
                      icon: Icons.camera_alt,
                      label: _photoPath != null ? 'Cambiar foto' : 'Añadir foto',
                      onTap: () => setState(() => _showPhotoPicker = !_showPhotoPicker),
                    ),
                    // Photo source picker
                    if (_showPhotoPicker)
                      Container(
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
                      ),
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
                        child: const Text('Finalizar', style: TextStyle(fontSize: 13)),
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
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/backup_service.dart';
import '../../data/google_drive_service.dart';
import '../widgets/settings_card.dart';

class DriveBackupSection extends StatefulWidget {
  const DriveBackupSection({super.key});

  @override
  State<DriveBackupSection> createState() => _DriveBackupSectionState();
}

class _DriveBackupSectionState extends State<DriveBackupSection> {
  final BackupService _backup = BackupService.instance;
  final GoogleDriveService _drive = GoogleDriveService.instance;
  bool _driveConnecting = false;
  bool _backingUp = false;
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    final meta = _backup.metadata;
    final cs = Theme.of(context).colorScheme;

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _driveHeader(cs),
          const SizedBox(height: 4),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 4),
          if (_drive.isConnected) ...[
            if (meta.driveAccountEmail != null)
              _infoRow(cs, Icons.person_rounded, 'Cuenta', meta.driveAccountEmail!),
            if (meta.driveLastBackup != null)
              _infoRow(cs, Icons.history_rounded, 'Último respaldo',
                  _formatDate(meta.driveLastBackup!)),
            if (meta.driveFileSize != null)
              _infoRow(cs, Icons.storage_rounded, 'Tamaño',
                  _formatSize(meta.driveFileSize!)),
            if (meta.driveAppVersion != null)
              _infoRow(cs, Icons.info_rounded, 'Versión', meta.driveAppVersion!),
            if (meta.driveChecksum != null)
              _infoRow(cs, Icons.verified_rounded, 'Checksum',
                  meta.driveChecksum!.length > 16
                      ? '${meta.driveChecksum!.substring(0, 16)}...'
                      : meta.driveChecksum!),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _backingUp ? null : () => _uploadBackup(context),
                icon: _backingUp
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_rounded, size: 16),
                label: Text(_backingUp ? 'Subiendo...' : 'Subir respaldo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _restoring ? null : () => _restoreFromDrive(context),
                icon: _restoring
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_download_rounded, size: 16),
                label: Text(_restoring ? 'Restaurando...' : 'Restaurar desde Drive'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _driveConnecting ? null : () => _connectDrive(context),
                icon: _driveConnecting
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.drive_folder_upload_rounded, size: 16),
                label: Text(_driveConnecting ? 'Conectando...' : 'Conectar Google Drive'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _driveHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _drive.isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: _drive.isConnected ? AppColors.success : AppColors.lightTextTertiary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Google Drive',
                style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _drive.isConnected ? Colors.green : cs.onSurface.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _drive.isConnected ? 'Conectado' : 'No conectado',
            style: TextStyle(
              color: _drive.isConnected ? Colors.green : cs.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_drive.isConnected) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _disconnectDrive(context),
              child: Icon(Icons.logout, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(ColorScheme cs, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _connectDrive(BuildContext context) async {
    setState(() => _driveConnecting = true);
    final drive = GoogleDriveService.instance;
    final account = await drive.signIn();
    if (mounted) setState(() => _driveConnecting = false);
    if (account != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conectado como ${account.email}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo conectar Google Drive'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _disconnectDrive(BuildContext context) async {
    await GoogleDriveService.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Drive desconectado')),
      );
    }
  }

  Future<void> _uploadBackup(BuildContext context) async {
    setState(() => _backingUp = true);
    final backup = BackupService.instance;
    final path = await backup.createBackup();
    if (mounted) setState(() => _backingUp = false);
    if (path != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respaldo creado y subido a Drive')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear respaldo'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreFromDrive(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: const Text('¿Estás seguro? Todos los datos actuales serán reemplazados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _restoring = true);
    final backup = BackupService.instance;
    final ok = await backup.restoreBackup(fromDrive: true);
    if (mounted) setState(() => _restoring = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Respaldo restaurado correctamente' : 'Error al restaurar respaldo'),
          backgroundColor: ok ? null : Colors.red,
        ),
      );
    }
  }
}

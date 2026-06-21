import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../profiles/presentation/viewmodels/profile_viewmodel.dart';
import '../../../sync/presentation/sync_viewmodel.dart';
import '../widgets/settings_card.dart';

class SyncSection extends StatelessWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SyncViewModel(),
      child: _SyncBody(),
    );
  }
}

class _SyncBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final syncVm = context.watch<SyncViewModel>();
    final profileVm = context.read<ProfileViewModel>();
    final authVm = context.read<AuthViewModel>();
    final cs = Theme.of(context).colorScheme;

    final profile = profileVm.currentProfile;
    final isFirebaseOn = AppConfig.useFirebase;
    final isConnected = isFirebaseOn && authVm.user != null;

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _firebaseRow(cs, isConnected),
          if (!isFirebaseOn) ...[
            const SizedBox(height: 4),
            Divider(color: cs.outlineVariant, height: 1),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Text('Modo local',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 4),
          _infoRow(cs, Icons.person_rounded, 'Usuario',
              authVm.user?.email ?? ''),
          const SizedBox(height: 4),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 4),
          _infoRow(cs, Icons.badge_rounded, 'Perfil',
              profile != null ? '${profile.clubName} · ${profile.category}' : ''),
          const SizedBox(height: 4),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 4),
          _infoRow(cs, Icons.history_rounded, 'Última sincronización',
              syncVm.lastSyncDateFormatted ?? 'Nunca'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isFirebaseOn && !syncVm.isSyncing && profile != null
                  ? () => _handleSync(context, syncVm, profile.id, profile.clubId)
                  : null,
              icon: syncVm.isSyncing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2),
                    )
                  : Icon(Icons.sync_rounded, size: 16, color: cs.primary),
              label: Text(
                  syncVm.isSyncing ? 'Sincronizando...' : 'Sincronizar ahora'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSync(BuildContext context, SyncViewModel syncVm,
      String profileId, String clubId) async {
    print('🔵 SYNC UI: botón presionado');
    try {
      await syncVm.syncAll(profileId, clubId);
      print('🟢 SYNC UI: éxito');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronización completada')),
        );
      }
    } catch (_) {
      print('🔴 SYNC UI: fallo');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al sincronizar')),
        );
      }
    }
  }

  Widget _firebaseRow(ColorScheme cs, bool connected) {
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
            child: const Icon(Icons.cloud_rounded, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Firebase',
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: connected ? Colors.green : cs.onSurface.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'Conectado' : 'No conectado',
            style: TextStyle(
              color: connected ? Colors.green : cs.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      ColorScheme cs, IconData icon, String label, String value) {
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
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

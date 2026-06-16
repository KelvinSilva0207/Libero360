import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/notification_models.dart';
import '../viewmodels/notification_viewmodel.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (vm.notifications.any((n) => !n.read))
            TextButton(
              onPressed: () => vm.markAllAsRead(),
              child: Text('Marcar leídas',
                  style: TextStyle(color: cs.primary)),
            ),
        ],
      ),
      body: vm.loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : vm.notifications.isEmpty
              ? _emptyState(cs)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: vm.notifications.length,
                  itemBuilder: (_, i) => _notifTile(context, vm, i, cs),
                ),
    );
  }

  Widget _emptyState(ColorScheme cs) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: cs.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            Text('Sin notificaciones',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 16)),
          ],
        ),
      );

  Widget _notifTile(
      BuildContext context, NotificationViewModel vm, int i, ColorScheme cs) {
    final n = vm.notifications[i];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        color: n.read
            ? cs.surfaceContainerHighest
            : cs.primary.withValues(alpha: 0.08),
        child: ListTile(
          leading: _iconForType(n.type),
          title: Text(n.title,
              style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.message,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 2),
              Text(_timeAgo(n.createdAt),
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.3),
                      fontSize: 11)),
            ],
          ),
          trailing: !n.read
              ? IconButton(
                  icon: Icon(Icons.check_circle_outline,
                      color: cs.primary, size: 20),
                  onPressed: () => vm.markAsRead(n.id),
                )
              : null,
          onTap: () {
            if (!n.read) vm.markAsRead(n.id);
          },
        ),
      ),
    );
  }

  Widget _iconForType(NotificationType type) {
    IconData icon;
    Color color;
    switch (type.category) {
      case NotificationCategory.atletas:
        icon = Icons.people;
        color = const Color(0xFF4CAF50);
      case NotificationCategory.asistencia:
        icon = Icons.checklist;
        color = const Color(0xFFFF9800);
      case NotificationCategory.partidos:
        icon = Icons.sports_volleyball;
        color = const Color(0xFF2196F3);
      case NotificationCategory.colaboracion:
        icon = Icons.groups_2;
        color = const Color(0xFF9C27B0);
    }
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, color: color, size: 18),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}

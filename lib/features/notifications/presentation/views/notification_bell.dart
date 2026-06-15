import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/notification_models.dart';
import '../viewmodels/notification_viewmodel.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final count = vm.unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: Colors.white70, size: 22),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const _NotificationsScreen()),
            );
          },
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Notificaciones'),
        actions: [
          if (vm.notifications.any((n) => !n.read))
            TextButton(
              onPressed: () => vm.markAllAsRead(),
              child: const Text('Marcar leídas',
                  style: TextStyle(color: Color(0xFFFF8C00))),
            ),
        ],
      ),
      body: vm.loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
          : vm.notifications.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: vm.notifications.length,
                  itemBuilder: (_, i) => _notifTile(context, vm, i),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64,
                color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            Text('Sin notificaciones',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 16)),
          ],
        ),
      );

  Widget _notifTile(BuildContext context, NotificationViewModel vm, int i) {
    final n = vm.notifications[i];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        color: n.read
            ? const Color(0xFF1A1F3D)
            : const Color(0xFFFF8C00).withValues(alpha: 0.08),
        child: ListTile(
          leading: _iconForType(n.type),
          title: Text(n.title,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.message,
                  style:
                      TextStyle(color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 2),
              Text(_timeAgo(n.createdAt),
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11)),
            ],
          ),
          trailing: !n.read
              ? IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      color: Color(0xFFFF8C00), size: 20),
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
        break;
      case NotificationCategory.asistencia:
        icon = Icons.checklist;
        color = const Color(0xFFFF9800);
        break;
      case NotificationCategory.partidos:
        icon = Icons.sports_volleyball;
        color = const Color(0xFF2196F3);
        break;
      case NotificationCategory.colaboracion:
        icon = Icons.groups_2;
        color = const Color(0xFF9C27B0);
        break;
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

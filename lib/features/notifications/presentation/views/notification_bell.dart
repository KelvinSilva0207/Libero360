import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifications_screen.dart';
import '../viewmodels/notification_viewmodel.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final count = vm.unreadCount;
    final iconColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, size: 22, color: iconColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/notification_models.dart';
import '../viewmodels/notification_viewmodel.dart';
import 'notification_preferences_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  NotificationCategory? _filterCategory;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final cs = Theme.of(context).colorScheme;

    final all = _filtered(vm.notifications, _filterCategory);
    final unread = all.where((n) => !n.read).toList();
    final read = all.where((n) => n.read).toList();
    final tabs = ['Todas (${all.length})', 'No le\u00eddas (${unread.length})', 'Le\u00eddas (${read.length})'];
    final lists = [all, unread, read];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (vm.notifications.any((n) => !n.read))
            TextButton(
              onPressed: () => vm.markAllAsRead(),
              child: Text('Leer todas', style: TextStyle(color: cs.primary, fontSize: 13)),
            ),
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
          indicatorColor: cs.primary,
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          _filterRow(cs),
          Expanded(
            child: vm.loading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : TabBarView(
                    controller: _tabCtrl,
                    children: lists.map((list) {
                      if (list.isEmpty) return _emptyState(cs);
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _notifTile(context, vm, list[i], cs),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow(ColorScheme cs) {
    final allCategories = NotificationCategory.values;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(cs, 'Todas', null),
            const SizedBox(width: 6),
            ...allCategories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _filterChip(cs, c.name[0].toUpperCase() + c.name.substring(1), c),
            )),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(ColorScheme cs, String label, NotificationCategory? category) {
    final selected = _filterCategory == category;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.7))),
      selected: selected,
      onSelected: (_) => setState(() => _filterCategory = category),
      selectedColor: cs.primary,
      checkmarkColor: cs.onPrimary,
      backgroundColor: cs.surfaceContainerHighest,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  List<AppNotification> _filtered(List<AppNotification> notifications, NotificationCategory? category) {
    if (category == null) return notifications;
    return notifications.where((n) => n.type.category == category).toList();
  }

  Widget _emptyState(ColorScheme cs) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.notifications_off_outlined, size: 64, color: cs.onSurface.withValues(alpha: 0.15)),
        const SizedBox(height: 16),
        Text('Sin notificaciones', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 16)),
      ],
    ),
  );

  Widget _notifTile(BuildContext context, NotificationViewModel vm, AppNotification n, ColorScheme cs) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Dismissible(
        key: Key(n.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.delete_outline, color: Colors.red),
        ),
        onDismissed: (_) => vm.deleteNotification(n.id),
        child: Card(
          color: n.read ? cs.surfaceContainerHighest : cs.primary.withValues(alpha: 0.08),
          child: ListTile(
            leading: _iconForType(n.type),
            title: Text(n.title, style: TextStyle(color: cs.onSurface, fontWeight: n.read ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.message, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                const SizedBox(height: 2),
                Text(_timeAgo(n.createdAt), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 10)),
              ],
            ),
            trailing: !n.read
                ? IconButton(
                    icon: Icon(Icons.check_circle_outline, color: cs.primary, size: 20),
                    onPressed: () => vm.markAsRead(n.id),
                  )
                : null,
            onTap: () {
              if (!n.read) vm.markAsRead(n.id);
            },
          ),
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

import 'package:flutter/material.dart';

/// Architecture-only: share card placeholders.
/// Sharing functionality is not implemented yet.

class ShareAthleteCard extends StatelessWidget {
  final String athleteName;
  final bool isDark;

  const ShareAthleteCard({
    super.key,
    required this.athleteName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class ShareStatsCard extends StatelessWidget {
  final bool isDark;

  const ShareStatsCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class ShareTeamCard extends StatelessWidget {
  final bool isDark;

  const ShareTeamCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

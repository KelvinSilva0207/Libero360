import '../../features/estadisticas/data/models/player.dart';

class NameFormatter {
  static String fullName({required String firstNames, required String lastNames}) {
    return '${firstNames.trim()} ${lastNames.trim()}'.trim();
  }

  static String displayName({required String firstNames, required String lastNames}) {
    final fn = firstNames.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    final ln = lastNames.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    if (fn.isEmpty && ln.isEmpty) return '';
    return '$fn $ln'.trim();
  }

  static String shortName({required String firstNames, required String lastNames}) {
    final fn = firstNames.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    final ln = lastNames.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    if (fn.isEmpty && ln.isEmpty) return '';
    if (fn.isEmpty) return ln;
    if (ln.isEmpty) return fn;
    return '$fn ${ln[0]}.';
  }

  static String matchName({required String firstNames, required String lastNames}) {
    return shortName(firstNames: firstNames, lastNames: lastNames);
  }

  static String playerFullName(Player p) {
    return fullName(firstNames: p.firstNames, lastNames: p.lastNames);
  }

  static String playerDisplayName(Player p) {
    return displayName(firstNames: p.firstNames, lastNames: p.lastNames);
  }

  static String playerShortName(Player p) {
    return shortName(firstNames: p.firstNames, lastNames: p.lastNames);
  }

  static String playerMatchName(Player p) {
    return matchName(firstNames: p.firstNames, lastNames: p.lastNames);
  }

  static String avatarInitial(Player p) {
    final name = playerDisplayName(p);
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static String formatDisplayName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0];
    return '${parts[0]} ${parts[1]}';
  }

  static String formatShortName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0];
    return '${parts[0]} ${parts[1].isNotEmpty ? '${parts[1][0]}.' : ''}';
  }

  static String formatInitial(String fullName) {
    final name = formatDisplayName(fullName);
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

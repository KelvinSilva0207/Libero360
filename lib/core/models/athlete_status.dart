import 'package:flutter/material.dart';

enum AthleteStatus {
  active,
  resting,
  injured,
  excused,
  inactive,
}

extension AthleteStatusX on AthleteStatus {
  String get label {
    switch (this) {
      case AthleteStatus.active: return 'Activo';
      case AthleteStatus.resting: return 'Reposo';
      case AthleteStatus.injured: return 'Lesión';
      case AthleteStatus.excused: return 'Permiso';
      case AthleteStatus.inactive: return 'Inactivo';
    }
  }

  IconData get icon {
    switch (this) {
      case AthleteStatus.active: return Icons.check_circle_rounded;
      case AthleteStatus.resting: return Icons.nightlight_round;
      case AthleteStatus.injured: return Icons.healing_rounded;
      case AthleteStatus.excused: return Icons.event_busy_rounded;
      case AthleteStatus.inactive: return Icons.cancel_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AthleteStatus.active: return const Color(0xFF22C55E);
      case AthleteStatus.resting: return const Color(0xFFEAB308);
      case AthleteStatus.injured: return const Color(0xFF3B82F6);
      case AthleteStatus.excused: return const Color(0xFFA1A1AA);
      case AthleteStatus.inactive: return const Color(0xFFEF4444);
    }
  }
}

class RestriccionDeportiva {
  final bool puedeEntrenar;
  final bool puedeJugar;
  final bool puedeSacar;
  final String ejerciciosLigeros;

  const RestriccionDeportiva({
    this.puedeEntrenar = true,
    this.puedeJugar = true,
    this.puedeSacar = true,
    this.ejerciciosLigeros = '',
  });
}

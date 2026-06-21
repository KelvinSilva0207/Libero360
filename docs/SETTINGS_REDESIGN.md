# FASE 5.4C — Nuevo Sistema de Configuración

## Arquitectura

```
lib/features/settings/
├── data/
│   ├── settings_models.dart          # AppThemeMode enum
│   └── settings_repository.dart      # Export/Import JSON via DatabaseService
│
├── presentation/
│   ├── viewmodels/
│   │   └── settings_viewmodel.dart   # Estado centralizado de configuración
│   │
│   ├── views/
│   │   ├── settings_screen.dart      # Pantalla principal (provee ChangeNotifierProvider)
│   │   ├── account_section.dart      # Cuenta: nombre, correo, cerrar sesión
│   │   ├── club_section.dart         # Club: nombre, logo, invitar, cambiar club
│   │   ├── profiles_section.dart     # Perfiles: placeholder "Próximamente"
│   │   ├── notifications_section.dart # Notificaciones: toggle, contador
│   │   ├── appearance_section.dart   # Apariencia: ThemeSwitcher (solo oscuro activo)
│   │   ├── sync_section.dart         # Sincronización: Firebase, último respaldo
│   │   └── database_section.dart     # Base de Datos: export/import/restore
│   │
│   └── widgets/
│       ├── settings_card.dart        # SettingsCard, SettingsTile, SettingsSwitchTile
│       └── settings_drawer.dart      # Drawer heredado del Dashboard (no modificado)
│
└── settings.dart                     # Barrel export
```

## Secciones

| # | Sección | Widget | Funcionalidad |
|---|---------|--------|---------------|
| 1 | Cuenta | `AccountSection` | Avatar, nombre, email, botón cerrar sesión (consume `AuthViewModel`) |
| 2 | Club | `ClubSection` | Icono club, nombre, invitar miembros, cambiar club (consume `ClubViewModel`) |
| 3 | Perfiles | `ProfilesSection` | Placeholder visual — botón "Crear perfil" deshabilitado |
| 4 | Notificaciones | `NotificationsSection` | Switch notificaciones, contador (deshabilitado) |
| 5 | Apariencia | `AppearanceSection` | ThemeSwitcher: Oscuro (activo), Claro/Sistema (deshabilitados) (consume `ThemeNotifier`) |
| 6 | Sincronización | `SyncSection` | Firebase: "No vinculado", último respaldo, botón sincronizar (placeholder) |
| 7 | Base de Datos | `DatabaseSection` | Exportar JSON (share_plus), Importar JSON (file_picker), Restaurar copia |

## Compatibilidad con AdminScreen

`AdminScreen` mantiene su clase y constructor (`const AdminScreen()`) para no romper la navegación en `AppShell`.

**Antes**: AdminScreen contenía 702 líneas con 7 secciones inline, lógica de export/import, theme switching, y navegación a otras pantallas.

**Después**: AdminScreen es un wrapper de 6 líneas que delega en `const SettingsScreen()`:

```dart
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
```

Toda la lógica anterior de AdminScreen fue migrada a los nuevos archivos de settings.

## SettingsViewModel

```dart
class SettingsViewModel extends ChangeNotifier {
  // Estado
  bool notificationsEnabled
  bool autoRotation
  bool isExporting / isImporting / isSyncing
  String? lastBackupDate

  // Delegados a providers existentes
  String userName / userEmail         // → AuthViewModel
  ThemeMode themeMode / isDark / isLight / isSystem  // → ThemeNotifier
  String clubName                     // → ClubViewModel

  // Acciones
  void logout()                       // → AuthViewModel.logout()
  Future<void> exportDatabase()       // → SettingsRepository → DatabaseService
  Future<void> importDatabase()       // → SettingsRepository → DatabaseService + FilePicker
  Future<void> syncNow()              // Placeholder
  Future<void> restoreBackup()        // = importDatabase()
}
```

El ViewModel es creado con `ChangeNotifierProvider` dentro de `SettingsScreen.build()`, consumiendo providers existentes del árbol (`ThemeNotifier`, `AuthViewModel`, `ClubViewModel`).

## Preparación para perfiles

La sección `ProfilesSection` está diseñada como placeholder visual para cuando se implemente la funcionalidad multi-perfil. El botón "Crear perfil" está deshabilitado (`onPressed: null`). Cuando se implemente la lógica real:
1. Agregar estado al `SettingsViewModel`
2. Conectar con `ClubViewModel` o nuevo `ProfileViewModel`
3. Habilitar el botón y agregar lógica de creación

## Archivos Creados

| Archivo | Líneas | Propósito |
|---------|--------|-----------|
| `lib/features/settings/settings.dart` | 5 | Barrel export |
| `lib/features/settings/data/settings_models.dart` | 1 | `AppThemeMode` enum |
| `lib/features/settings/data/settings_repository.dart` | 37 | Export/Import vía DatabaseService |
| `lib/features/settings/presentation/viewmodels/settings_viewmodel.dart` | 115 | Estado y acciones centralizadas |
| `lib/features/settings/presentation/views/settings_screen.dart` | 127 | Pantalla principal + ChangeNotifierProvider |
| `lib/features/settings/presentation/views/account_section.dart` | 67 | Sección Cuenta |
| `lib/features/settings/presentation/views/club_section.dart` | 175 | Sección Club |
| `lib/features/settings/presentation/views/profiles_section.dart` | 53 | Sección Perfiles (placeholder) |
| `lib/features/settings/presentation/views/notifications_section.dart` | 88 | Sección Notificaciones |
| `lib/features/settings/presentation/views/appearance_section.dart` | 116 | Sección Apariencia (ThemeSwitcher) |
| `lib/features/settings/presentation/views/sync_section.dart` | 94 | Sección Sincronización |
| `lib/features/settings/presentation/views/database_section.dart` | 160 | Sección Base de Datos |
| `lib/features/settings/presentation/widgets/settings_card.dart` | 171 | Widgets reutilizables (Card, Tile, SwitchTile) |

## Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/settings/presentation/views/settings_screen.dart` | Reescrito completamente (era un stub de 168 líneas) |
| `lib/features/admin/presentation/views/admin_screen.dart` | Simplificado a wrapper de 6 líneas (era 702 líneas) |

## Archivos no Modificados (compatibilidad)

- `lib/features/settings/presentation/widgets/settings_drawer.dart` — Sigue siendo usado por DashboardScreen como endDrawer
- `lib/ui/app_shell.dart` — Sin cambios (AdminScreen sigue siendo `const AdminScreen()` en índice 5)
- `lib/main.dart` — Sin cambios (no se agregaron nuevos providers al árbol global)

## flutter analyze

```
0 errores
271 issues (info/warnings, todos pre-existentes, 7 menos que antes por limpieza de AdminScreen)
```

## Migración Futura

1. **FASE 5.4D**: Eliminar AdminScreen por completo y apuntar AppShell índice 5 directamente a `SettingsScreen`
2. **Futuro**: Agregar persistencia real a switches (notificaciones, auto-rotación, etc.)
3. **Futuro**: Implementar multi-perfil conectando ProfilesSection con backend
4. **Futuro**: Firebase Sync real en SyncSection

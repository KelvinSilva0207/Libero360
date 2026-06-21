# FASE 5.4A — Navigation & Settings Audit

---

## 1. BottomNavigationBar

### Problema: BottomNav incompleto en móvil

**Archivo**: `lib/ui/app_shell.dart:257-262`

**BottomNav actual** (4 items):
```
Dashboard | Atletas | Partidos | Estadísticas
```

**Sidebar actual** (6 items):
```
Dashboard | Atletas | Partidos | Estadísticas | Asistencia | Configuración
```

**Faltantes en móvil**:
- **Asistencia** (índice 4) — solo accesible desde tarjetas del Dashboard
- **Configuración** (índice 5) — solo accesible desde menú de usuario → "Administrar"

### Propuesta

**Opción A — Agregar las 2 faltantes (BottomNav con 6 items):**
```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Atletas'),
    BottomNavigationBarItem(icon: Icon(Icons.sports_volleyball_rounded), label: 'Partidos'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Estadísticas'),
    BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Asistencia'),
    BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Configuración'),
  ],
)
```
- Riesgo: 6 items en BottomNav pueden verse apretados en pantallas ≤360px de ancho.
- Alternativa: reducir a 5 (mover Configuración a menú overflow "Más").

**Opción B — Barra inferior con overflow "Más" (5 items + overflow):**
```dart
items: const [
  BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
  BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Atletas'),
  BottomNavigationBarItem(icon: Icon(Icons.sports_volleyball_rounded), label: 'Partidos'),
  BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Estadísticas'),
  BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded), label: 'Más'),
]
```
- Riesgo: requiere lógica extra para mostrar Asistencia y Configuración en un bottom sheet.

---

## 2. UserMenu

### Problema: Duplicidad `settings` / `admin`

**Archivo**: `lib/ui/app_shell.dart:278-282`

```dart
onSelected: (value) {
    if (value == 'logout') context.read<AuthViewModel>().logout();
    if (value == 'settings') setState(() => _selectedIndex = 5);  // ← índice AdminScreen
    if (value == 'admin') setState(() => _selectedIndex = 5);     // ← mismo índice
    if (value == 'team') setState(() => _selectedIndex = 1);       // ← Atletas
},
```

```dart
itemBuilder: (context) => [
    // ...
    PopupMenuItem(value: 'admin', ...)   // label: 'Administrar'
    // ...
],
```

- `settings` nunca se usa (no hay menú item con ese valor)
- `admin` apunta a índice 5 = `AdminScreen`
- No hay acceso directo a `Asistencia` desde el menú de usuario

**Archivo**: `lib/ui/app_shell.dart:330-380` (`_showUserMenu`)

El menú del sidebar (wide) es idéntico al del AppBar (mobile) — ambos tienen: Usuario, Mi equipo, Administrar, Cerrar sesión.

### Propuesta

Renombrar `'admin'` → `'settings'` y unificar semánticamente:

```dart
PopUpMenuItem(value: 'settings', child: 'Configuración'),
PopUpMenuItem(value: 'attendance', child: 'Asistencia'),
```

Ambos apuntarían a sus respectivos índices (4 y 5) sin duplicidad.

---

## 3. NotificationBell

### Problema: Invisible en wide layout

**Archivo**: `lib/ui/app_shell.dart:84`

```dart
appBar: useMobileLayout
    ? AppBar(
        // ...
        actions: [
          const NotificationBell(),       // ← solo visible en mobile
          const ClubSwitcher(),
          _userMenu(context, user),
        ],
      )
    : null,                                // ← wide: no AppBar → no NotificationBell
```

En wide layout (≥768px), el AppBar no se renderiza. El sidebar (`_buildSidebar`) tiene:
- Logo + título
- ClubSwitcher
- Nav items
- Perfil de usuario al pie

No hay NotificationBell en el sidebar.

### Propuesta

Agregar NotificationBell al sidebar, en la cabecera junto al ClubSwitcher:

```dart
// En _buildSidebar(), después del título:
Row(
  children: [
    const Spacer(),
    const NotificationBell(),  // ← agregar aquí
    const SizedBox(width: 8),
    const ClubSwitcher(),
  ],
),
```

Dentro de la sección del logo (línea 129-142 de app_shell.dart).

---

## 4. Arquitectura Actual de Settings

### Árbol de archivos

```
lib/features/settings/
├── presentation/
│   ├── views/
│   │   └── settings_screen.dart
│   └── widgets/
│       └── settings_drawer.dart
```

No hay barrel export ni viewmodel.

### settings_screen.dart (168 líneas)

- **Widget**: `StatefulWidget` sin ViewModel
- **Estado**: solo `bool _rotacion = true`
- **Secciones**: General, Partido, Sincronización, Acerca de
- **Dependencias**: solo `AppColors`
- **Funcionalidad**: todas las opciones son informativas (showDialog) o switches sin persistencia
- **Acceso**: desde AdminScreen → sección "Base de Datos" → opción "Ajustes"

### settings_drawer.dart (393 líneas)

- **Widget**: `StatefulWidget` con `SingleTickerProviderStateMixin`
- **Estado**: `_expandedSections`, `_rotacionAutomatica`
- **Secciones**: General, Partido, Sincronización, Acerca de
- **Acciones reales**: Exportar datos (share_plus), Importar datos (file_picker), duración de sets (diálogo no persistente)
- **Dependencias**: `DatabaseService`, `share_plus`, `file_picker`, `path_provider`
- **Acceso**: desde DashboardScreen como `endDrawer`

### Relación con AdminScreen (702 líneas)

`AdminScreen` es un monolito que incluye dentro de sí misma funcionalidad equivalente a Settings:

| Sección AdminScreen | Equivalente Settings |
|--------------------|---------------------|
| Cuenta | No existe en Settings |
| Equipo Técnico | No existe en Settings |
| Notificaciones | No existe en Settings |
| General | Settings tiene sección General (parcial) |
| Personalización | No existe en Settings |
| Sincronización | Settings tiene Exportar/Importar |
| Base de Datos → "Ajustes" | Abre SettingsScreen como sub-pantalla |

### Tabla comparativa de opciones

| Opción | SettingsScreen | SettingsDrawer | AdminScreen |
|--------|---------------|----------------|-------------|
| Idioma | Info dialog | Info dialog | Read-only |
| Tema | Info dialog "solo oscuro" | Info dialog | ThemeSwitcher funcional |
| Rotación automática | Switch | Switch | — |
| Duración sets | Info dialog | Dialog (no persistente) | — |
| Sincronizar dispositivos | Info dialog | Info dialog | — |
| Exportar datos | Info dialog | **Sí** (share_plus) | **Sí** (share_plus) |
| Importar datos | — | **Sí** (file_picker) | **Sí** (file_picker) |
| Cuenta | — | — | Read-only + Logout |
| Equipo técnico | — | — | Redirección a Team screens |
| Notificaciones | — | — | Switch + redirección |
| Personalización (tema) | — | — | ThemeSwitcher funcional |
| Firebase Sync | — | — | Read-only |
| Restaurar DB | — | — | = Importar datos |
| Editar/Eliminar atletas | — | — | Redirección |

### Problemas detectados

1. **Lógica duplicada**: `exportToJson`/`importFromJson` implementado en 3 lugares (settings_drawer, admin_screen, y admin_screen._datosSection redirige a settings para "Ajustes").
2. **Tema real solo en AdminScreen**: `SettingsScreen` y `SettingsDrawer` solo tienen info dialogs sobre "modo oscuro", pero `AdminScreen` tiene un ThemeSwitcher funcional con `ThemeNotifier`.
3. **SettingsScreen huérfano**: No tiene barrel export, no es accesible directamente desde navegación principal — solo como sub-pantalla de AdminScreen.
4. **SettingsDrawer sin persistencia**: Los switches de rotación y notificaciones son estado local que se pierde al cerrar el drawer.
5. **Dos implementaciones de export/import**: `settings_drawer.dart` y `admin_screen.dart` tienen la misma lógica con pequeñas variaciones.

---

## 5. Propuesta de Nueva Arquitectura

### Objetivo: Unificar Settings + Admin en un solo feature de configuración

```
lib/features/settings/
├── data/
│   └── settings_repository.dart       # persistencia de preferencias
│   └── settings_models.dart            # modelos (tema, rotacion, etc.)
├── presentation/
│   ├── viewmodels/
│   │   └── settings_viewmodel.dart    # estado centralizado
│   ├── views/
│   │   ├── settings_screen.dart       # pantalla principal de configuración
│   │   ├── account_section.dart       # sección Cuenta
│   │   ├── team_section.dart          # sección Equipo Técnico
│   │   ├── notification_section.dart  # sección Notificaciones
│   │   ├── sync_section.dart          # sección Sincronización
│   │   └── database_section.dart      # sección Base de Datos
│   └── widgets/
│       └── settings_drawer.dart       # drawer del Dashboard
└── settings.dart                      # barrel export
```

### Mapa de migración

| Opción Actual | Destino | Prioridad |
|---------------|---------|-----------|
| AdminScreen sección "Cuenta" | `account_section.dart` | Alta |
| AdminScreen sección "Equipo Técnico" | `team_section.dart` | Alta |
| AdminScreen sección "Notificaciones" | `notification_section.dart` | Alta |
| AdminScreen sección "General" | `settings_screen.dart` | Alta |
| AdminScreen sección "Personalización" | `settings_screen.dart` (ThemeSwitcher) | Alta |
| AdminScreen sección "Sincronización" | `sync_section.dart` | Alta |
| AdminScreen sección "Base de Datos" | `database_section.dart` | Alta |
| SettingsScreen standalone | Eliminar o fusionar en settings_screen | Media |
| SettingsDrawer | Conservar como subconjunto de settings_screen | Baja |

### Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Romper navegación existente (índice 5 de AppShell) | Alto | Mantener AdminScreen como wrapper temporal que redirige a settings_screen |
| Perder lógica de export/import de admin_screen | Alto | Migrar código primero, eliminar después |
| SettingsDrawer sin ViewModel compartido | Medio | Crear SettingsViewModel con ChangeNotifierProvider en main.dart |
| Tema (ThemeNotifier) ya existe como Provider separado | Bajo | SettingsViewModel lo consume, no lo replica |

### Estimación

| Tarea | Esfuerzo |
|-------|----------|
| Mapear todas las opciones de AdminScreen | 1h |
| Crear barrel + SettingsViewModel | 2h |
| Migrar settings_screen.dart a nueva arquitectura | 2h |
| Migrar sections de AdminScreen a archivos separados | 4h |
| Unificar export/import en SettingsRepository | 2h |
| Agregar persistencia a switches | 2h |
| **Total** | **~13h** |

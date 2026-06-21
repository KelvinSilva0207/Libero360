# FASE 5.4B — Navigation Cleanup

## Cambios realizados

Archivo modificado: `lib/ui/app_shell.dart`

### 1. BottomNavigationBar

**Antes** (4 items): Dashboard, Atletas, Partidos, Estadísticas
**Después** (6 items, `type: BottomNavigationBarType.fixed`):

| Índice | Label | Icono |
|--------|-------|-------|
| 0 | Dashboard | `dashboard_rounded` |
| 1 | Atletas | `people_rounded` |
| 2 | Partidos | `sports_volleyball_rounded` |
| 3 | Estadísticas | `bar_chart_rounded` |
| 4 | Asistencia | `checklist_rounded` |
| 5 | Configuración | `settings_rounded` |

Coincide con el sidebar (`_navItems`) que ya tenía 6 items.

### 2. UserMenu — unificación

**Antes**:
- `value: 'admin'` con label "Administrar" e icono `admin_panel_settings_rounded`
- `value: 'settings'` duplicado (nunca se usaba, no había PopupMenuItem con ese valor)
- `onSelected`: manejaba ambos valores para mismo índice 5

**Después**:
- `value: 'settings'` con label "Configuración" e icono `settings_rounded`
- `onSelected`: solo maneja `'settings'` → índice 5
- Aplicado tanto en `_userMenu` (AppBar móvil) como en `_showUserMenu` (sidebar wide)

### 3. NotificationBell en sidebar

**Antes**: Solo visible en AppBar móvil (`actions: [NotificationBell(), ClubSwitcher(), ...]`).
En wide layout (≥768px), el AppBar no se renderiza y no había NotificationBell en el sidebar.

**Después**: NotificationBell agregado al sidebar en la misma fila que ClubSwitcher:

```
┌─────────────────────┐
│ [logo] Libero360    │
├─────────────────────┤
│ [ClubSwitcher]  [🔔]│  ← NotificationBell agregado
├─────────────────────┤
│ Dashboard           │
│ Atletas             │
│ ...                 │
├─────────────────────┤
│ [avatar] Usuario    │
└─────────────────────┘
```

### 4. Compatibilidad

NO se modificaron:
- `Dashboard`, `DashboardScreen`, `DashboardViewModel`
- `Provider`/`MultiProvider`/`main.dart`
- `NotificationViewModel`, `ClubViewModel`
- `MatchController`, `PartidoViewModel`, `PlayByPlayViewModel`
- `AuthViewModel`, `FirebaseAuthRepository`
- `AdminScreen` (sigue siendo el contenido del índice 5)
- `SettingsScreen`, `SettingsDrawer`

## Árbol de navegación resultante

```
AppShell
├── mobile (BottomNav, <768px o pestaña Estadísticas)
│   ├── 0 Dashboard ─────── DashboardScreen
│   ├── 1 Atletas ───────── AthleteListScreen
│   ├── 2 Partidos ──────── MatchLauncherPlaceholder
│   ├── 3 Estadísticas ──── StatisticsScreen
│   ├── 4 Asistencia ────── AttendanceScreen
│   └── 5 Configuración ─── AdminScreen
│
├── wide (Sidebar, ≥768px excepto Estadísticas)
│   ├─ sidebar: [ClubSwitcher] [NotificationBell]
│   ├─ nav:     Dashboard | Atletas | Partidos | Estadísticas | Asistencia | Configuración
│   └─ footer:  [avatar] Usuario [▼] → Mi equipo | Configuración | Cerrar sesión
│
└── AppBar (mobile)
    ├─ leading: back to Dashboard (si no está en 0)
    ├─ title: [logo] Libero360
    └─ actions: [NotificationBell] [ClubSwitcher] [avatar ▼]
         └── avatar ▼ → Mi equipo | Configuración | Cerrar sesión
```

## Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| BottomNav apretado en pantallas ≤360px con 6 items | Baja | Medio | `type: fixed` + font-size 11 ya aplicado |
| `_screens[5]` = AdminScreen, no SettingsScreen (diferencia semántica) | Media | Bajo | Funcionalmente AdminScreen es la pantalla de configuración actual; la migración real es FASE 5.4C+ |
| NotificationBell en sidebar podría solaparse con ClubSwitcher si el nombre del club es muy largo | Baja | Bajo | Spacer entre ambos; ClubSwitcher usa `mainAxisSize: min` |

## flutter analyze

```
0 errores
278 issues (info/warnings, todos pre-existentes)
```

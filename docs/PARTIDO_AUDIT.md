# PARTIDO 3.0 — Auditoría Completa

> Fecha: 19/06/2026
> Alcance: módulos `partido/`, `cancha/`, y dependencias cruzadas con `estadisticas/`

---

## 1. ESTRUCTURA DE DIRECTORIOS

```
lib/features/
├── partido/
│   ├── partido.dart                          # Barrel: PartidoViewModel, MatchScreen, ScoreboardWidget
│   ├── data/
│   │   ├── match_config.dart                 # MatchConfig
│   │   ├── match_event.dart                  # EventType, MatchEvent
│   │   └── mappers/
│   │       └── match_event_mapper.dart        # MatchEventMapper
│   └── presentation/
│       ├── controllers/
│       │   └── match_controller.dart          # MatchController (477 líneas)
│       ├── viewmodels/
│       │   └── partido_viewmodel.dart         # PartidoViewModel (wrapper delegador)
│       ├── views/
│       │   ├── match_screen.dart              # MatchScreen (912 líneas)
│       │   ├── match_start_dialog.dart        # MatchStartDialog
│       │   ├── coach_mode_screen.dart         # CoachModeScreen
│       │   └── player_selection_screen.dart   # ⚠️ STALE
│       └── widgets/
│           ├── scoreboard_widget.dart
│           ├── full_court_widget.dart
│           ├── rotation_widget.dart           # ⚠️ STALE
│           ├── action_buttons_widget.dart      # ⚠️ STALE
│           ├── player_stats_dialog.dart
│           └── roster_management_sheet.dart    # ⚠️ STALE
│           └── stat_recorder_widget.dart       # ⚠️ STALE (superseded)
│
├── cancha/
│   ├── cancha.dart                           # Barrel: CourtScreen, CourtViewModel
│   ├── data/
│   │   └── court_models.dart                 # PlayerAssignment, RotationRecord, PositionEvent
│   └── presentation/
│       ├── viewmodels/
│       │   └── court_viewmodel.dart
│       ├── views/
│       │   ├── court_screen.dart             # (736 líneas)
│       │   └── court_setup_dialog.dart
│       └── widgets/
│           ├── court_painter.dart
│           ├── position_slot.dart
│           └── rotation_timeline.dart
│
└── estadisticas/
    ├── data/models/
    │   ├── match.dart                        # Match, EstadoPartido, TipoPartido
    │   ├── player.dart                       # Player, Posicion, EstadoSalud
    │   ├── stat_event.dart                   # StatEvent, TipoAccion, ResultadoAccion, ZonaCancha
    │   └── ...
    └── presentation/
        ├── views/
        │   ├── play_by_play_screen.dart
        │   └── live_stats_dashboard_screen.dart
        └── widgets/
            ├── stat_recorder_widget.dart      # (versión activa)
            ├── live_stats_widget.dart
            └── stats_charts_widget.dart       # ⚠️ STALE
```

---

## 2. DIAGRAMA DE NAVEGACIÓN ACTUAL

```
AppShell (bottom nav)
│
├── [0] Dashboard ──────────────────────────────────────────────
│   ├── "Nuevo Partido"  →  MatchStartDialog  →  MatchScreen
│   ├── "Partidos" card  →  PlayByPlayScreen
│   └── "Est. en vivo"   →  PlayByPlayScreen
│
├── [1] Atletas  →  AthleteListScreen
│
├── [2] Partidos ───────────────────────────────────────────────
│   ├── "Nuevo Partido"     →  MatchStartDialog  →  MatchScreen
│   ├── "Cancha de práctica"→  CourtScreen
│   └── "Modo Entrenador"   →  CoachModeScreen
│
├── [3] Estadísticas  →  StatisticsScreen
├── [4] Asistencia    →  AttendanceScreen
└── [5] Configuración →  AdminScreen
```

---

## 3. PANTALLAS RELACIONADAS

| # | Pantalla | Archivo | Llamada desde | Activa |
|---|----------|---------|---------------|--------|
| 1 | **MatchScreen** | `partido/presentation/views/match_screen.dart` | MatchStartDialog::_finalizar() | ✅ |
| 2 | **MatchStartDialog** | `partido/presentation/views/match_start_dialog.dart` | app_shell.dart:417, dashboard_screen.dart:183 | ✅ |
| 3 | **CoachModeScreen** | `partido/presentation/views/coach_mode_screen.dart` | app_shell.dart:442 | ✅ |
| 4 | **CourtScreen** | `cancha/presentation/views/court_screen.dart` | app_shell.dart:430 | ✅ |
| 5 | **CourtSetupDialog** | `cancha/presentation/views/court_setup_dialog.dart` | court_screen.dart:153 | ✅ |
| 6 | **PlayByPlayScreen** | `estadisticas/presentation/views/play_by_play_screen.dart` | dashboard_screen.dart ×2 | ✅ |
| 7 | **LiveStatsDashboardScreen** | `estadisticas/presentation/views/live_stats_dashboard_screen.dart` | No tiene ruta activa | ⚠️ |
| 8 | **PlayerSelectionScreen** | `partido/presentation/views/player_selection_screen.dart` | No tiene llamada entrante | ❌ STALE |

---

## 4. WIDGETS DE CANCHA (Court Painters)

| Widget | Archivo | Usado por | Modo | Activo |
|--------|---------|-----------|------|--------|
| **CourtPainter** | `cancha/widgets/court_painter.dart` | CourtScreen | Práctica (1 equipo) | ✅ |
| **_FullCourtPainter** | `partido/widgets/full_court_widget.dart` | FullCourtWidget | Partido (2 equipos) | ✅ |
| **_CanchaPainter** | `estadisticas/widgets/stat_recorder_widget.dart` | StatRecorderWidget (estadisticas) | Stats en partido | ✅ |

**Tres painters duplicados.** Todos activos pero con lógica separada:
- `CourtPainter`: esquinas redondeadas, red a 22%, líneas de ataque a 38%/62%
- `_FullCourtPainter`: rectángulo completo, red a 50%, ataque a 22%/78%
- `_CanchaPainter`: rectángulo completo, red a 50%, ataque a 30%

---

## 5. WIDGETS STALE (sin uso)

| Widget | Archivo | Razón |
|--------|---------|-------|
| **PlayerSelectionScreen** | `partido/views/player_selection_screen.dart` | Sin llamada entrante; fue reemplazado por MatchStartDialog (tiene selección integrada) |
| **RotationWidget** | `partido/widgets/rotation_widget.dart` | Sin referencia externa; la cancha se renderiza via FullCourtWidget |
| **ActionButtonsWidget** | `partido/widgets/action_buttons_widget.dart` | Sin referencia externa; la UI de acciones está en MatchScreen directa |
| **RosterManagementSheet** | `partido/widgets/roster_management_sheet.dart` | Sin referencia externa; el roster se maneja en MatchStartDialog y endDrawer |
| **StatRecorderWidget** (partido) | `partido/widgets/stat_recorder_widget.dart` | Sin referencia; superseded por el de `estadisticas/` |
| **StatsChartsWidget** | `estadisticas/widgets/stats_charts_widget.dart` | Sin referencia externa |
| **LiveStatsDashboardScreen** | `estadisticas/views/live_stats_dashboard_screen.dart` | Sin ruta activa que navegue hacia ella |

---

## 6. TODAS LAS FUNCIONES EXISTENTES

### 6.1 MatchController (core engine) — `match_controller.dart`

| Método | Línea | Qué hace | Llamado desde UI |
|--------|-------|----------|-----------------|
| `init(MatchConfig?)` | 88 | Crea partido, inicializa estado, arranca timer | MatchScreen |
| `sumarPuntoLocal()` | 136 | +1 punto local, cambia set si aplica, registra evento | ScoreboardWidget |
| `sumarPuntoVisitante()` | 174 | +1 punto visitante, análogo | ScoreboardWidget |
| `restarPuntoLocal()` | 212 | -1 punto local (sin undo rotación) | MatchScreen bottom bar |
| `restarPuntoVisitante()` | 231 | -1 punto visitante | MatchScreen bottom bar |
| `rotarLocal()` | 252 | Incrementa rotación local (cíclica 0-5) | FullCourtWidget |
| `rotarVisitante()` | 257 | Incrementa rotación visitante | FullCourtWidget |
| `cambiarServicio()` | 262 | Alterna quién sirve y rota al ganador | FullCourtWidget |
| `undoLastPoint()` | 282 | Deshace último punto vía repositorio | MatchScreen menú |
| `cambiarSet(int)` | 334 | Cambia a otro set, guarda puntaje actual | MatchScreen set selector |
| `pausarReanudar()` | 391 | Pausa/reanuda partido y timer | MatchScreen botón |
| `finalizarPartido()` | 406 | Detiene timer, guarda duración, finaliza en DB | MatchScreen diálogo |
| `eliminarPartido()` | 437 | Borra partido de DB | MatchScreen diálogo |

### 6.2 PartidoViewModel (delegador) — `partido_viewmodel.dart`

Delega todos los métodos del MatchController 1:1. No agrega lógica propia.

### 6.3 CourtViewModel (práctica) — `court_viewmodel.dart`

| Método | Línea | Qué hace | Llamado desde UI |
|--------|-------|----------|-----------------|
| `init(String? profileId)` | 60 | Carga jugadores desde DB | CourtScreen |
| `assignPlayer(Player, int)` | 91 | Asigna jugador a posición | CourtSetupDialog |
| `removePlayer(int)` | 102 | Remueve jugador de posición | PositionSlot |
| `rotate()` | 113 | Rota lineup (corrimiento circular), registra RotationRecord | CourtScreen botón |
| `resetLineup()` | 180 | Limpia todas las asignaciones | CourtScreen menú |
| `recordEvent(int, EventType)` | 133 | Registra evento en posición | CourtScreen bottom sheet |
| `get playerStats` | 48 | Estadísticas agregadas por jugador | CourtScreen resumen |

### 6.4 Funciones por feature

| Feature | ¿Implementado? | ¿Dónde? |
|---------|---------------|---------|
| **Rotaciones** (partido) | ✅ | `match_controller.rotarLocal()`, `rotarVisitante()`, `cambiarServicio()` |
| **Rotaciones** (práctica) | ✅ | `court_viewmodel.rotate()` |
| **Historial rotaciones** | ✅ Solo cancha | `RotationRecord`, `RotationTimeline` widget |
| **Servicio/saque** | ✅ | `match_controller.isLocalServing`, `cambiarServicio()` |
| **Jugador que saca** | ⚠️ Implícito | Determinado por posición-0 en rotación + `isLocalServing` |
| **Estadísticas rápidas** | ❌ No existe | -- |
| **Drawer atletas** | ✅ | `match_screen._buildEndDrawer()`, `PlayerStatsDialog` |
| **Sumar puntos** | ✅ | `sumarPuntoLocal()`, `sumarPuntoVisitante()` |
| **Quitar puntos** | ✅ | `restarPunto*()`, `undoLastPoint()` |
| **Like/Dislike** | ❌ No existe | Solo icons thumb en PlayerStatsDialog para positivo/negativo |
| **Estadísticas en vivo** | ❌ No existe | No hay stat counter en vivo |
| **Timer/Cronómetro** | ✅ | `_iniciarTimer()`, `tiempoTranscurrido` |
| **Sets Management** | ✅ | `cambiarSet()`, `setScores`, `_actualizarSetScores()` |

---

## 7. TODOS LOS MODELOS

| Modelo | Archivo | Datos que guarda |
|--------|---------|-----------------|
| **Match** | `estadisticas/models/match.dart` | id, fecha, equipos, puntos, sets, estado, config, profileId/clubId, duración |
| **Player** | `estadisticas/models/player.dart` | id, nombre, número, posición, estado salud, profileId/clubId, atletaStatus |
| **StatEvent** | `estadisticas/models/stat_event.dart` | id, tipoAcción, resultado, timestamp, set, puntos, zona, player/match/profile/club IDs |
| **MatchEvent** | `partido/data/match_event.dart` | id, athleteId, matchId, fecha, set, eventType, rotación, profileId/clubId |
| **MatchEventMapper** | `partido/data/mappers/match_event_mapper.dart` | Conversor MatchEvent ↔ StatEvent |
| **MatchConfig** | `partido/data/match_config.dart` | localName, visitorName, setsTotales, tipoPartido, lugar, selectedPlayers |
| **PlayerAssignment** | `cancha/data/court_models.dart` | Player + numeroOverride + position (1-6) |
| **RotationRecord** | `cancha/data/court_models.dart` | rotationNumber, lineup (6 assignments), timestamp, wonServe |
| **PositionEvent** | `cancha/data/court_models.dart` | playerId, positionNumber, eventType, timestamp, rotationNumber |

---

## 8. RUTAS Y FLUJO REAL

No hay rutas nombradas para partido/cancha. Toda la navegación usa constructores directos:

| Origen | Destino | Método |
|--------|---------|--------|
| AppShell (Dashboard tab) | DashboardScreen | built-in (index 0) |
| AppShell (Partidos tab) | _MatchLauncherPlaceholder | built-in (index 2) |
| DashboardScreen | MatchStartDialog | `showDialog()` |
| DashboardScreen | PlayByPlayScreen | `context.pushSlide()` |
| _MatchLauncherPlaceholder | MatchStartDialog | `showDialog()` |
| _MatchLauncherPlaceholder | CourtScreen | `Navigator.push(MaterialPageRoute)` |
| _MatchLauncherPlaceholder | CoachModeScreen | `context.pushSlide()` |
| MatchStartDialog | MatchScreen | `Navigator.push(slideRightRoute)` |
| CourtScreen | CourtSetupDialog | `showDialog()` |

**Rutas nombradas en main.dart**: solo `/welcome`, `/login`, `/register`.

---

## 9. RECOMENDACIÓN PARA PARTIDO 3.0

### 9.1 Qué mantener

| Componente | Razón |
|-----------|-------|
| **MatchController** | Core engine sólido (477 líneas). La lógica de puntos, sets, timer, rotaciones está correcta. |
| **Match** model | Modelo completo con todos los campos necesarios. |
| **StatEvent** model | Modelo de eventos flexible (tipoAcción, resultado, zona). |
| **MatchEventMapper** | Puente entre MatchEvent y StatEvent funcionando con tests. |
| **ScoreboardWidget** | Widget de marcador reutilizable y limpio. |
| **CourtViewModel** | Lógica de práctica bien encapsulada. |
| **CourtPainter** / **PositionSlot** | Visualización de cancha de práctica funcional. |
| **RotationTimeline** | Historial de rotaciones único en la app. |

### 9.2 Qué fusionar

| Fusión propuesta | Beneficio |
|-----------------|-----------|
| **Unificar CourtPainter + _FullCourtPainter + _CanchaPainter** | Un solo CustomPainter parametrizable (modo: práctica/partido/stats) |
| **Unificar StatRecorderWidget** (partido → estadísticas) | Eliminar duplicado stale en partido/widgets/, usar solo el de estadísticas |
| **Fusionar _MatchLauncherPlaceholder con Dashboard cards** | Evitar duplicación de acceso a partido desde 2 lugares |
| **Unificar PartidoViewModel y MatchController** | PartidoViewModel es delegador puro sin lógica adicional; puede eliminarse o fusionarse |

### 9.3 Qué eliminar

| Componente | Motivo |
|-----------|--------|
| **PlayerSelectionScreen** | Sin uso. MatchStartDialog ya integra selección de jugadores. |
| **RotationWidget** | Sin uso externo. FullCourtWidget ya renderiza rotaciones. |
| **ActionButtonsWidget** | Sin uso externo. Acciones integradas en MatchScreen. |
| **RosterManagementSheet** | Sin uso externo. Roster se maneja desde MatchStartDialog y endDrawer. |
| **StatRecorderWidget** (partido version) | Sin uso. Reemplazado por el de estadísticas. |
| **StatsChartsWidget** | Sin uso externo. |
| **LiveStatsDashboardScreen** | Sin ruta activa. Funcionalidad cubierta por PlayByPlayScreen. |
| **PartidoViewModel** (opcional) | Si se elimina la capa de delegación, MatchScreen puede consumir MatchController directamente. |

### 9.4 Qué crear para Partido 3.0

| Nueva feature | Prioridad | Descripción |
|--------------|-----------|-------------|
| **LiveStatsCounter** | Alta | Widget que muestre estadísticas en tiempo real durante el partido (puntos ganadores, errores, eficiencia por jugador) |
| **ServingPlayerIndicator** | Media | Función explícita que devuelva qué jugador está sacando (hoy es implícito vía posición-0) |
| **QuickStats** | Media | Panel compacto de estadísticas rápidas visibles durante el partido sin salir de MatchScreen |
| **RotationHistoryViewer** (partido) | Baja | Historial de rotaciones durante el partido (hoy solo existe para práctica) |
| **SetSelector mejorado** | Baja | Selector visual de sets con resumen de cada set |
| **Like/Dislike** | Baja | Sistema de calificación rápida de jugadas (positivo/negativo) |

### 9.5 Arquitectura propuesta (Partido 3.0)

```
lib/features/partido/                    # Unifica partido + cancha
├── partido.dart                         # Barrel único
├── data/
│   ├── models/
│   │   ├── match_config.dart            # (se mantiene)
│   │   ├── match_event.dart             # (se mantiene)
│   │   └── court_models.dart            # (desde cancha)
│   └── mappers/
│       └── match_event_mapper.dart      # (se mantiene)
├── presentation/
│   ├── controllers/
│   │   ├── match_controller.dart        # (se mantiene, corazón del motor)
│   │   └── court_viewmodel.dart         # (desde cancha)
│   ├── views/
│   │   ├── match_screen.dart            # Refactorizada (menos líneas)
│   │   ├── match_start_dialog.dart      # (se mantiene)
│   │   ├── court_screen.dart            # (desde cancha)
│   │   ├── court_setup_dialog.dart      # (desde cancha)
│   │   └── coach_mode_screen.dart       # (se mantiene)
│   └── widgets/
│       ├── scoreboard_widget.dart       # (se mantiene)
│       ├── full_court_widget.dart       # Unificado: modo partido / práctica
│       ├── court_painter.dart           # Único painter parametrizable
│       ├── position_slot.dart           # (desde cancha)
│       ├── rotation_timeline.dart       # (desde cancha)
│       ├── player_stats_dialog.dart     # (se mantiene)
│       ├── live_stats_widget.dart       # NUEVO
│       └── stat_recorder_widget.dart    # Solo el de estadísticas
```

### 9.6 Resumen de archivos objetivo

| Operación | Cantidad |
|-----------|----------|
| Mantener | ~15 archivos |
| Fusionar | ~4 pares de archivos |
| Eliminar (stale) | 7 archivos |
| Crear (nuevo) | ~2-3 archivos |
| **Neto final** | **Reducción de ~25% del código del módulo Partido** |

---

*Fin del reporte — PARTIDO 3.0 AUDIT*

# FASE 4 — Arquitectura Global Libero360 (Propuesta V2)

## Árbol Actual

```
lib/
├── core/
│   ├── config.dart
│   ├── constants/
│   ├── database/                    ← database_provider (sembast IO/Web)
│   ├── models/                      ← athlete_status.dart (solo 1 modelo)
│   ├── services/                    ← ClubDataService, Auth repositories, ServiceLocator
│   ├── theme_provider/
│   ├── themes/
│   └── widgets_globales/
│
├── features/
│   ├── admin/                       ← 1 screen (placeholder)
│   ├── asistencia/                  ← Athlete CRUD + Attendance tracking
│   ├── atleta/                      ← **VACÍO** (dead directory)
│   ├── auth/                        ← Login, Register, Welcome + AuthVM
│   ├── cancha/                      ← Practice court + rotation
│   ├── estadisticas/                ← **GOD MODULE** (20 archivos)
│   │   ├── data/
│   │   │   ├── local_db/            ← DatabaseService + StatsStreamService
│   │   │   ├── models/              ← Player, Match, StatEvent, AttendanceRecord, Season
│   │   │   └── repositories/        ← MatchRepository, StatEventRepository
│   │   ├── domain/services/         ← MVPCalculator, StatsCalculator
│   │   └── presentation/
│   │       ├── viewmodels/          ← PlayByPlayViewModel
│   │       ├── views/               ← PlayByPlayScreen, LiveStatsDashboardScreen
│   │       └── widgets/             ← StatRecorder, StatsCharts, LiveStatsWidget
│   ├── notifications/               ← Notification bell, preferences
│   ├── partido/                     ← Match live controller + screens (17 archivos)
│   │   ├── data/
│   │   │   ├── mappers/             ← MatchEventMapper
│   │   │   ├── match_config.dart
│   │   │   └── match_event.dart
│   │   └── presentation/
│   │       ├── controllers/         ← MatchController
│   │       ├── viewmodels/          ← PartidoViewModel
│   │       ├── views/               ← MatchScreen, CoachMode, PlayerSelection, StartDialog
│   │       └── widgets/             ← Scoreboard, FullCourt, Rotation, StatRecorder
│   ├── settings/                    ← Settings screen + drawer
│   ├── statistics/                  ← Aggregate/historical stats (5 archivos)
│   │   ├── data/                    ← StatisticsService, StatisticsModels
│   │   └── presentation/views/     ← AthleteStatisticsScreen, StatisticsScreen
│   └── teams/                       ← Clubs, invitations, permissions
│
├── ui/
│   ├── app_shell.dart               ← Main shell + tab navigation
│   ├── dashboard_screen.dart
│   └── dashboard_viewmodel.dart
└── main.dart
```

**Total: 11 feature modules, ~100+ archivos**

---

## Problemas Identificados

### 1. `estadisticas/` es un God Module

Contiene **4 responsabilidades distintas**:

| Responsabilidad | Archivos | Debería estar en |
|----------------|----------|-----------------|
| Base de datos global (sembast) | `database_service.dart` | `core/database/` |
| Modelos de dominio compartidos | `player.dart`, `match.dart`, `stat_event.dart`, `attendance_record.dart`, `season.dart` | `core/models/` |
| Servicios de estadísticas | `stats_calculator.dart`, `mvp_calculator.dart` | `features/statistics/` |
| Play-by-Play (UI + VM) | `play_by_play_viewmodel.dart`, `play_by_play_screen.dart`, `live_stats_*.dart`, widgets | Su propio feature |

### 2. Dependencia Inversa: `core/` → `features/`

`core/services/club_data_service.dart` importa de `features/estadisticas/` y `features/partido/`:

```
core/services/club_data_service.dart
  → features/estadisticas/data/models/
  → features/estadisticas/data/local_db/
  → features/partido/data/match_event.dart
```

Esto rompe la regla de que `core/` no debe depender de `features/`.

### 3. Duplicación de Widgets de Cancha

| Módulo | Widgets de cancha |
|--------|------------------|
| `cancha/` | `court_painter.dart`, `position_slot.dart`, `rotation_timeline.dart` |
| `partido/` | `full_court_widget.dart`, `rotation_widget.dart`, `scoreboard_widget.dart` |

Ambos módulos dibujan una cancha con rotación. Hay lógica de rotación duplicada.

### 4. Duplicación de Stat Recorder

| Módulo | Archivo |
|--------|---------|
| `estadisticas/` | `presentation/widgets/stat_recorder_widget.dart` |
| `partido/` | `presentation/widgets/stat_recorder_widget.dart` |

Mismo nombre, misma responsabilidad, dos implementaciones distintas.

### 5. `asistencia/` vs `atleta/`

- `atleta/` está **vacío** — parece un feature renombrado a medias
- `asistencia/` maneja CRUD de atletas **y** control de asistencia (dos responsabilidades mezcladas)

### 6. `estadisticas/` vs `statistics/`

| Aspecto | `estadisticas/` | `statistics/` |
|---------|----------------|---------------|
| Enfoque | Live stats, Play-by-Play, datos en tiempo real | Estadísticas históricas, agregadas |
| Modelos | Player, Match, StatEvent | StatisticsModels (propio) |
| Servicios | StatsCalculator, MVPCalculator | StatisticsService |

Son conceptualmente el mismo dominio (estadísticas de voleibol) partido en dos módulos solo por idioma.

### 7. `MatchEvent` y `StatEvent` conviven con mapper

Ya se resolvió en FASE 3B, pero la existencia de ambos modelos indica que antes no había una estrategia clara de modelos de eventos.

---

## Árbol Propuesto

```
lib/
├── core/
│   ├── config.dart
│   ├── constants/
│   ├── database/                    ← DatabaseService (desde estadisticas/)
│   ├── models/                      ← TODOS los modelos de dominio
│   │   ├── player.dart
│   │   ├── match.dart
│   │   ├── stat_event.dart
│   │   ├── match_event.dart
│   │   ├── attendance_record.dart
│   │   ├── season.dart
│   │   ├── user_model.dart
│   │   └── athlete_status.dart
│   ├── services/                    ← ClubDataService, ServiceLocator
│   ├── theme_provider/
│   ├── themes/
│   └── widgets_globales/
│
├── features/
│   ├── auth/                        ← sin cambios
│   ├── admin/                       ← sin cambios
│   ├── settings/                    ← sin cambios
│   ├── teams/                       ← sin cambios
│   ├── notifications/               ← sin cambios
│   │
│   ├── match/                       ← FUSIONADO: partido/ + cancha/ + play_by_play
│   │   ├── controllers/
│   │   │   └── match_controller.dart
│   │   ├── viewmodels/
│   │   │   ├── partido_viewmodel.dart
│   │   │   └── play_by_play_viewmodel.dart    ← movido desde estadisticas/
│   │   ├── screens/
│   │   │   ├── match_screen.dart
│   │   │   ├── match_start_dialog.dart
│   │   │   ├── player_selection_screen.dart
│   │   │   ├── coach_mode_screen.dart
│   │   │   └── play_by_play_screen.dart      ← movido desde estadisticas/
│   │   ├── widgets/
│   │   │   ├── scoreboard_widget.dart
│   │   │   ├── full_court_widget.dart
│   │   │   ├── rotation_widget.dart
│   │   │   ├── court_painter.dart             ← desde cancha/
│   │   │   ├── position_slot.dart             ← desde cancha/
│   │   │   ├── rotation_timeline.dart         ← desde cancha/
│   │   │   ├── stat_recorder_widget.dart      ← UNIFICADO
│   │   │   └── live_stats_widget.dart         ← desde estadisticas/
│   │   └── events/
│   │       └── match_event_mapper.dart
│   │
│   ├── court/                       ← Cancha de práctica (standalone)
│   │   ├── viewmodels/
│   │   │   └── court_viewmodel.dart
│   │   ├── screens/
│   │   │   └── court_screen.dart
│   │   └── widgets/
│   │       ├── court_painter.dart
│   │       └── position_slot.dart
│   │
│   ├── statistics/                  ← FUSIONADO: estadisticas/domain + statistics/
│   │   ├── services/
│   │   │   ├── stats_calculator.dart
│   │   │   ├── mvp_calculator.dart
│   │   │   └── statistics_service.dart
│   │   ├── screens/
│   │   │   ├── statistics_screen.dart
│   │   │   └── athlete_statistics_screen.dart
│   │   └── widgets/
│   │       ├── stats_charts_widget.dart
│   │       └── live_stats_dashboard_screen.dart
│   │
│   └── athletes/                    ← RENOMBRADO: desde asistencia/ (solo CRUD)
│       ├── screens/
│       │   ├── athlete_list_screen.dart
│       │   ├── athlete_form_screen.dart
│       │   └── player_detail_screen.dart
│       └── widgets/
│           └── (por definir)
│
├── features/attendance/             ← Asistencia (separado de athletes)
│   ├── screens/
│   │   ├── attendance_screen.dart
│   │   ├── attendance_history_screen.dart
│   │   └── attendance_history_detail_screen.dart
│   └── widgets/
│       └── attendance_pdf_export.dart
│
├── ui/
│   ├── app_shell.dart
│   ├── dashboard_screen.dart
│   └── dashboard_viewmodel.dart
└── main.dart
```

**Total: ~10 feature modules (se reducen de 11 a 10, pero con responsabilidades más claras)**

---

## Tabla de Migración

| Actual | Propuesto | Acción |
|--------|-----------|--------|
| `estadisticas/data/local_db/` | `core/database/` | Mover |
| `estadisticas/data/models/` | `core/models/` | Mover |
| `estadisticas/data/repositories/` | `core/database/` o `core/repositories/` | Mover |
| `estadisticas/domain/services/` | `features/statistics/services/` | Mover |
| `estadisticas/presentation/` (PlayByPlay) | `features/match/` | Mover |
| `estadisticas/presentation/` (LiveStats, Charts) | `features/statistics/` | Mover |
| `statistics/` | `features/statistics/` | Fusionar |
| `partido/` | `features/match/` | Renombrar + recibir |
| `cancha/` | `features/court/` (práctica) + widgets a `match/` | Separar |
| `asistencia/` (athlete CRUD) | `features/athletes/` | Renombrar + separar |
| `asistencia/` (attendance) | `features/attendance/` | Separar |
| `atleta/` | Eliminar | Eliminar directorio vacío |
| `partido/presentation/widgets/stat_recorder_widget.dart` | Unificar con `estadisticas/` version | Fusionar código |

---

## Pros y Contras

### Pros
1. **`core/models/`** — Todos los modelos compartidos en un lugar. Fin de las importaciones cross-feature solo por modelos.
2. **`core/database/`** — DatabaseService deja de estar escondido en un feature. Las dependencias en `core/services/` dejan de ser inversas.
3. **`features/match/`** — Un solo módulo para todo lo relacionado al partido en vivo: controller, VM, screens, widgets. PlayByPlay vive junto a MatchScreen porque comparten MatchController.
4. **`features/statistics/`** — Unifica `estadisticas/domain/` + `statistics/`. Fin de la duplicación conceptual.
5. **`features/court/`** — Cancha de práctica separada del match, sin duplicación de widgets (los widgets compartidos viven en `match/widgets/`).
6. **`features/athletes/` + `features/attendance/`** — Responsabilidades separadas: CRUD de atletas vs. registro de asistencia.

### Contras
1. **Riesgo de regresión** — Mover ~40+ archivos puede romper imports en cadena.
2. **Esfuerzo de migración alto** — Estimar 2-3 días de trabajo puro de refactor.
3. **Conflicto con ramas activas** — Si hay features en desarrollo, los merges serán dolorosos.
4. **PlayByPlay en `match/`** — Aunque comparte MatchController, la pantalla de PlayByPlay también es una herramienta de estadísticas. Podría argumentarse que pertenece a `statistics/`.

---

## Riesgos de Migración

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Imports rotos | Alta | Alto | Migración en un solo commit, usar `dart fix` |
| Widgets duplicados (stat_recorder) | Media | Medio | Auditar ambas implementaciones antes de fusionar |
| Pérdida de historial git | Baja | Bajo | Usar `git mv` para preservar historial |
| Regresión en navegación | Media | Alto | Tests de integración después de la migración |
| Conflictos con ramas paralelas | Alta | Medio | Coordinar con el equipo, hacer migración al inicio del sprint |
| Firebase sync roto | Baja | Alto | Verificar ClubDataService después de mover modelos |

---

## Estimación de Esfuerzo

| Fase | Tareas | Archivos | Esfuerzo |
|------|--------|----------|----------|
| **Fase 4.1** — Mover modelos a `core/models/` | Mover 5 modelos, actualizar ~30 imports | ~5 movidos, ~30 editados | 4-6 horas |
| **Fase 4.2** — Mover DatabaseService a `core/database/` | Mover 1 archivo + repositorios, actualizar imports | ~1-3 movidos, ~15 editados | 2-3 horas |
| **Fase 4.3** — Fusionar `estadisticas/` + `statistics/` | Unificar servicios, screens y widgets | ~10 movidos, ~10 editados | 4-6 horas |
| **Fase 4.4** — Fusionar `match/` + PlayByPlay + cancha widgets | Mover PlayByPlay a match, unificar widgets de cancha | ~15 movidos, ~10 editados | 6-8 horas |
| **Fase 4.5** — Separar `athletes/` y `attendance/` | Renombrar y separar desde `asistencia/` | ~8 movidos, ~5 editados | 2-3 horas |
| **Fase 4.6** — Limpiar `atleta/` y ajustes finales | Eliminar directorio vacío, verificar `flutter analyze` | ~1 eliminado | 1 hora |
| **Total** | | **~42 archivos movidos, ~70 editados** | **20-27 horas** |

---

## Recomendación

**NO migrar ahora.** El esfuerzo estimado (20-27 horas) no está justificado para el valor actual. La arquitectura actual funciona, tiene 0 errores en `flutter analyze`, y las dependencias cruzadas están controladas por el MatchController compartido (FASE 3A) y el MatchEventMapper (FASE 3B).

**Cuándo migrar:**
- Si se agrega un nuevo feature que requiera modelos compartidos
- Si el equipo crece y la estructura actual causa confusión
- Si se detectan bugs por la duplicación de widgets
- Si se decide agregar una suite de tests que requiera una estructura más limpia

**Quick wins ejecutables ahora (bajo esfuerzo):**
1. Eliminar `features/atleta/` (directorio vacío, 1 minuto)
2. Unificar `stat_recorder_widget.dart` (duplicado en `partido/` y `estadisticas/`)
3. Agregar barrel exports en los features que faltan (varios no tienen `partido.dart` etc. bien configurados)

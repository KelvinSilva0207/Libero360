# FASE 2A — MatchController Implementation Report

> 17 Junio 2026

---

## Files Changed

| File | Action | Lines |
|---|---|---|
| `lib/features/partido/presentation/controllers/match_controller.dart` | **CREATED** | 347 |
| `lib/features/partido/presentation/viewmodels/partido_viewmodel.dart` | **REWRITTEN** | 448 → 96 |

0 screens touched. 0 navigators touched. 0 providers touched.

---

## What Moved: PartidoViewModel → MatchController

All **logic+coupling** moved to MatchController (347 lines):

| Logic | Lines moved | Coupling |
|---|---|---|
| score (sumar/restar/undo) | ~100 | `MatchRepository`, `DatabaseService`, `MatchEvent` |
| timer (iniciar/detener/guardar) | ~30 | `Timer` (dart:async) |
| sets (setScores, cambiarSet) | ~50 | `MatchRepository` |
| rotación (rotarLocal, rotarVisitante, servicio) | ~30 | none |
| roster (jugadores, actualizarNumero) | ~15 | `DatabaseService` |
| persistencia MatchRepository | ~100 | `MatchRepository` (stats/repos) |
| persistencia MatchEvent | ~20 | `DatabaseService`, `MatchEvent` (partido/data) |
| estado interno (_isLoading, _error, _setLoading) | ~15 | `ChangeNotifier` |
| **TOTAL** | **~347** | **6 external dependencies** |

## What Stayed in PartidoViewModel

| Item | Lines | Purpose |
|---|---|---|
| `MatchController _controller` field | 1 | Instance owned per-session |
| `_onControllerChange()` bridge | 4 | Listener relay: `_controller → notifyListeners()` |
| 25 delegated getters | 25 | `return _controller.x` |
| 17 delegated methods | 17 | `return _controller.method()` |
| `dispose()` cleanup | 4 | Remove listener + dispose controller |
| **TOTAL** | **96** | **Zero external dependencies** |

---

## Architecture After

```
                            ┌──────────────────────┐
                            │   MatchScreen        │
                            │   CoachModeScreen    │
                            │   (use Provider)     │
                            └──────────┬───────────┘
                                       │ context.watch<PartidoViewModel>()
                                       ▼
                            ┌──────────────────────┐
                            │  PartidoViewModel    │  ← 96 lines
                            │  (wrapper/delegator)  │
                            └──────────┬───────────┘
                                       │ owns _controller
                                       ▼
                            ┌──────────────────────┐
                            │  MatchController     │  ← 347 lines
                            │  (ChangeNotifier)     │
                            └──┬───────┬───────┬───┘
                               │       │       │
                    ┌──────────┘       │       └───────────┐
                    ▼                  ▼                   ▼
          ┌─────────────────┐  ┌────────────┐  ┌──────────────────┐
          │ MatchRepository  │  │ DatabaseSvc │  │   MatchEvent     │
          │ (stats/repos)    │  │ (stats/db)  │  │ (partido/data)   │
          └─────────────────┘  └────────────┘  └──────────────────┘
```

---

## Dependencies of MatchController

| Import | Source |
|---|---|
| `dart:async` | Timer |
| `dart:collection` | UnmodifiableListView |
| `package:flutter/foundation.dart` | ChangeNotifier |
| `estadisticas/data/models/models.dart` | Match, Player, EstadoPartido, TipoPartido |
| `estadisticas/data/repositories/repositories.dart` | MatchRepository |
| `estadisticas/data/local_db/database_service.dart` | DatabaseService |
| `partido/data/match_config.dart` | MatchConfig |
| `partido/data/match_event.dart` | MatchEvent |

**Dependencies of PartidoViewModel (new):**

| Import | Source |
|---|---|
| `package:flutter/foundation.dart` | ChangeNotifier |
| `dart:collection` | UnmodifiableListView |
| `estadisticas/data/models/models.dart` | Match, Player, EstadoPartido |
| `partido/data/match_config.dart` | MatchConfig |
| `partido/presentation/controllers/match_controller.dart` | MatchController |

---

## Compatibility Verification

### MatchScreen (`match_screen.dart`)

Creates `PartidoViewModel` via:
```dart
ChangeNotifierProvider(
  create: (_) => PartidoViewModel()..init(widget.config),
)
```

Uses: `Consumer<PartidoViewModel>`, `PartidoViewModel vm` everywhere.

**Veredicto:** 100% compatible. PartidoViewModel API is identical.

### CoachModeScreen (`coach_mode_screen.dart`)

Uses: `Consumer<PartidoViewModel>`, `PartidoViewModel vm` everywhere.
Also accesses: `DatabaseService.instance.getMatchEvents(vm.match?.id ?? 0)` directly.

**Veredicto:** 100% compatible. `vm.match` still delegates to `_controller.match`.

### MatchStartDialog (uses MatchConfig)

No changes. `PartidoViewModel.init(config)` delegates to `_controller.init(config)`.

---

## Risks Before Integrating PlayByPlayViewModel

| Risk | Detail | Status |
|---|---|---|
| **PartidoViewModel wrapper overhead** | One extra `notifyListeners()` per change (controller → PVM) | Acceptable. Micro-delay only. |
| **MatchController disposable** | Must call `dispose()` to cancel Timer | ✅ Handled in PartidoViewModel.dispose() |
| **Listener leak** | If PVM is GC'd without dispose, controller listener leaks | No risk — Provider calls dispose() |
| **MatchController re-creation** | Each `PartidoViewModel()` creates new MatchController | ✅ Desired behavior — per-session |
| **PlayByPlayViewModel still owns separate `_partidoActual`** | Duplicate `Match` in memory | ⚠️ *Requires FASE 2B* |
| **Provider injection** | PlayByPlayScreen creates its own Provider inline | ⚠️ *Requires lifting provider or passing MatchController id* |
| **Timer conflict** | Two timers if both VMs active simultaneously | ⚠️ *Mitigated: PlayByPlayViewModel doesn't use timer* |

---

## flutter analyze Result

```
252 issues found.
─ 0 errors
─ 3 warnings (pre-existing: unused imports, unused field)
─ 249 info (pre-existing lints)
```

**No new issues introduced.**

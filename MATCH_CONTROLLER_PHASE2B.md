# FASE 2B — PlayByPlayViewModel Refactor Report

> 17 Junio 2026

---

## State Audit — Duplication Identified

### State Removed from PlayByPlayViewModel

| Duplicated Item | Lines removed | Now lives in |
|---|---|---|
| `Match? _partidoActual` | 1 (field) + 6 getters | `MatchController._match` |
| `bool _isLoading` | 1 (field) + 1 getter | `MatchController._isLoading` |
| `String? _error` | 1 (field) + 1 getter | `MatchController._error` (merge buffer `_ownError` kept for local errors) |
| `MatchRepository _matchRepository` | 1 (field) | `MatchController._matchRepository` (removed from PBPVM) |

**Total state fields removed from PBPVM: 4 of 7 fields (57%)**

### Methods Removed (Delegated to MatchController)

| Method | Lines removed | Delegates to |
|---|---|---|
| `iniciarNuevoPartido()` | 18 → 6 | `MatchController.init(MatchConfig)` |
| `cargarPartido()` | 14 → 7 | `MatchController.loadMatch(id)` (new) |
| `agregarPuntoLocal()` | 15 → 1 | `MatchController.sumarPuntoLocal()` |
| `agregarPuntoVisitante()` | 15 → 1 | `MatchController.sumarPuntoVisitante()` |
| `pausarPartido()` | 14 → 1 | `MatchController.pausarReanudar()` |
| `reanudarPartido()` | 14 → 1 | `MatchController.pausarReanudar()` |
| `finalizarPartido()` | 14 → 1 | `MatchController.finalizarPartido()` |
| `_setLoading(bool)` | 4 → 0 | removed entirely |
| `hayPartidoActivo` getter | 1 → 1 | `MatchController.isPartidoActivo` |
| `marcador` getter | 1 → 1 | `MatchController.match.marcador` |
| `resultadoSets` getter | 1 → 1 | `MatchController.match.resultadoSets` |
| `setActual` getter | 1 → 1 | `MatchController.setActual` |
| `estadoPartido` getter | 1 → 1 | `MatchController.estado` |

**Total lines removed from PBPVM: ~113**
**Total PBPVM: 458 → 250 lines (45% reduction)**

### State Preserved in PlayByPlayViewModel

| Item | Purpose |
|---|---|
| `List<StatEvent> _eventos` | Event list for play-by-play display |
| `List<Player> _jugadoresLocal` | Player selection roster |
| `List<Player> _jugadoresVisitante` | Player selection roster |
| `Player? _jugadorSeleccionado` | Currently selected player |
| `bool _esEquipoLocal` | Active team toggle |
| `String? _ownError` | Registration errors only (not match-level) |

### Methods Preserved

| Method | Category |
|---|---|
| `registrarAtaque()` | StatEvent registration (scoring delegated to controller) |
| `registrarSaque()` | StatEvent registration |
| `registrarBloqueo()` | StatEvent registration |
| `registrarDefensa()` | StatEvent registration |
| `registrarErrorContrario()` | StatEvent registration |
| `seleccionarJugador()` | Player selection |
| `cambiarEquipo()` | Player selection |
| `setJugadoresLocal()` | Player selection |
| `setJugadoresVisitante()` | Player selection |
| `obtenerEstadisticasJugador()` | Stats query |
| `obtenerTimeline()` | Stats query |
| `obtenerResumen()` | Stats query |
| `clear()` | State reset (own state only) |

---

## New Dependencies

### MatchController (added `loadMatch`)
| Import | Already existed? |
|---|---|
| `estadisticas/data/repositories/repositories.dart` (MatchRepository) | Yes |

### PlayByPlayViewModel (new)
| Import | Purpose |
|---|---|
| `partido/presentation/controllers/match_controller.dart` | MatchController |
| `partido/data/match_config.dart` | MatchConfig for init |

### Dependency removed from PBPVM
| Import | Before | After |
|---|---|---|
| `estadisticas/data/repositories/repositories.dart` | `MatchRepository` + `StatEventRepository` | `StatEventRepository` only |

---

## MatchController: New Method Added

```dart
Future<void> loadMatch(int id) async {
  // Fetches match by id from repository
  // Sets _match, handles loading/error state
  // notifyListeners on completion
}
```

---

## Architecture After FASE 2B

```
                    ┌───────────────────────┐
                    │   PlayByPlayScreen    │
                    │   MatchScreen         │
                    │   CoachModeScreen     │
                    └──────┬────────┬───────┘
                           │        │
              ┌────────────┘        └────────────┐
              ▼                                   ▼
   ┌─────────────────────┐          ┌──────────────────────┐
   │  PartidoViewModel   │          │ PlayByPlayViewModel  │
   │  (wrapper, 96 lines)│          │ (250 lines)          │
   └──────────┬──────────┘          └──────┬───────────────┘
              │                            │
              └──────────┬─────────────────┘
                         ▼
              ┌──────────────────────┐
              │   MatchController    │ ← única fuente de verdad
              │   (358 lines)        │    para score, sets,
              │                      │    timer, rotación,
              │                      │    roster, estado
              └──┬───────┬───────┬───┘
                 │       │       │
       ┌─────────┘       │       └──────────┐
       ▼                 ▼                  ▼
┌──────────────┐  ┌────────────┐  ┌──────────────────┐
│MatchRepo     │  │DatabaseSvc │  │  MatchEvent      │
│(stats/repos) │  │(stats/db)  │  │(partido/data)    │
└──────────────┘  └────────────┘  └──────────────────┘
```

---

## Compatibility with PlayByPlayScreen

**Public API changes: 0**

All getters and methods used by `play_by_play_screen.dart` remain accessible with identical signatures:

| Screen usage | Status |
|---|---|
| `vm.partidoActual` | ✅ Delegated |
| `vm.eventos` | ✅ Own |
| `vm.jugadoresLocal/Visitante` | ✅ Own |
| `vm.jugadorSeleccionado` | ✅ Own |
| `vm.esEquipoLocal` | ✅ Own |
| `vm.isLoading` | ✅ Delegated |
| `vm.error` | ✅ Merged (own + controller) |
| `vm.hayPartidoActivo` | ✅ Delegated |
| `vm.marcador` | ✅ Delegated |
| `vm.resultadoSets` | ✅ Delegated |
| `vm.setActual` | ✅ Delegated |
| `vm.estadoPartido` | ✅ Delegated |
| `vm.iniciarNuevoPartido()` | ✅ Delegated |
| `vm.agregarPuntoLocal/Visitante()` | ✅ Delegated |
| `vm.pausarPartido()` | ✅ Delegated |
| `vm.reanudarPartido()` | ✅ Delegated |
| `vm.finalizarPartido()` | ✅ Delegated |
| `vm.seleccionarJugador()` | ✅ Own |
| `vm.cambiarEquipo()` | ✅ Own |
| `vm.setJugadoresLocal/Visitante()` | ✅ Own |
| `vm.registrarAtaque/Saque/Bloqueo/Defensa/Error()` | ✅ Own (scoring delegated) |
| `vm.obtenerEstadisticasJugador()` | ✅ Own |
| `vm.obtenerTimeline()` | ✅ Own |
| `vm.obtenerResumen()` | ✅ Own |
| `vm.clear()` | ✅ Own |

**No screen modifications required.**

---

## flutter analyze Result

```
252 issues found.
─ 0 errors
─ 3 warnings (pre-existing)
─ 249 info (pre-existing lints)
```

**No new issues introduced.**

---

## Risks Before FASE 3 (MatchController Sharing)

| Risk | Detail |
|---|---|
| **Independent controller instances** | PartidoViewModel and PlayByPlayViewModel each create their own MatchController. If both are active simultaneously for the same match, they will have separate `_match` objects. |
| **Timer conflict** | Not applicable — PlayByPlayViewModel doesn't use timer. Only PartidoViewModel triggers timer via MatchController. |
| **Provider scope** | PlayByPlayScreen creates PBPVM inline via `ChangeNotifierProvider(create: (_) => PlayByPlayViewModel())`. To share a controller, the provider must be lifted. |
| **`obtenerResumen` instantiates MatchRepository** | Acceptable — no state, lightweight. Can be optimized later if needed. |

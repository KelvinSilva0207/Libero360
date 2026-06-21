# Architecture Refactor Report — FASE 1

> 16 Junio 2026

---

## Summary

Completed dead code elimination, architecture stabilization, and navigation linting. No visual changes introduced. 5 files deleted, 8 files modified/created. `flutter analyze` passes with 0 errors.

---

## Deletions (Dead Code Elimination)

| File | Lines | Reason |
|------|-------|--------|
| `lib_firebase/firebase_auth_service.dart` | ~60 | Dead code, zero imports |
| `lib_firebase/firebase_data_service.dart` | ~200 | Dead code, zero imports |
| `lib/core/services/firebase_sync_service.dart` | ~120 | Dead code, zero imports |
| `lib/features/partido/presentation/views/volleyball_court_widget.dart` | 440 | Dead code, zero imports |
| `lib/features/partido/presentation/views/match_setup_screen.dart` | 223 | Dead code, zero imports |

---

## Orphaned Screen Integration

| Screen | Integrated Into | Mechanism |
|--------|----------------|-----------|
| `SettingsScreen` | `AdminScreen` → "Base de Datos" section | New "Ajustes" action row calls `pushSlide` |
| `CoachModeScreen` | `AppShell` → `_MatchLauncherPlaceholder` | New "Modo Entrenador" button below "Cancha de práctica" |

---

## Dashboard Reactivity

### Before
- `DashboardScreen` loaded counts once in `didChangeDependencies` via `DatabaseService.instance` directly
- No refresh mechanism — required app restart to see new data

### After
- New `DashboardViewModel` (ChangeNotifier) owns all count state
- Registered via `ChangeNotifierProvider` in `main.dart` → `MultiProvider`
- `DashboardScreen` reads counts with `context.watch<DashboardViewModel>()` for auto-rebuild
- `_selectTab` in `AppShell` calls `refresh()` when switching to dashboard tab
- `load()` uses `refresh()` under the hood with guard against double-load

---

## Scoring → Events Bridge

### Before
- `PartidoViewModel.sumarPuntoLocal/Visitante` updated match points only
- No MatchEvent was recorded — gap between scoring and historical events

### After
- Both `sumarPuntoLocal` and `sumarPuntoVisitante` call `_registrarEvento()`
- `_registrarEvento` creates a `MatchEvent` with type `regularPoint`, current rotation, set number
- Persisted via `DatabaseService.instance.saveMatchEvent()`
- MatchEvent model kept as lightweight rotation event; StatEvent remains canonical

---

## Reactivity on Tab Switch

- `_AppShellState._selectTab(int index)` added
- Calls `DashboardViewModel.refresh()` when `index == 0` (Dashboard tab)
- Used by both sidebar nav items and bottom navigation bar

---

## File Inventory

### Created
- `lib/ui/dashboard_viewmodel.dart` — ChangeNotifier with reactive counts

### Modified
- `lib/main.dart` — added DashboardViewModel provider + import
- `lib/ui/dashboard_screen.dart` — replaced direct db calls with ViewModel watcher
- `lib/ui/app_shell.dart` — added imports, CoachModeScreen button, _selectTab method
- `lib/features/admin/presentation/views/admin_screen.dart` — added SettingsScreen link
- `lib/features/partido/presentation/viewmodels/partido_viewmodel.dart` — added event recording

### Deleted
- `lib_firebase/` (directory, 2 files)
- `lib/core/services/firebase_sync_service.dart`
- `lib/features/partido/presentation/views/volleyball_court_widget.dart`
- `lib/features/partido/presentation/views/match_setup_screen.dart`

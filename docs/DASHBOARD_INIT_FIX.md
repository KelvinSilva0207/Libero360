# FASE 5.0B — Corrección: Inicialización del Dashboard

## Causa del bug

`DashboardViewModel.init()` en `lib/ui/dashboard_viewmodel.dart:18-31` llamaba a `db.watchAllPlayers()` y `db.watchMatchesByState()` sin llamar antes a `await DatabaseService.instance.initialize()`.

`watchAllPlayers()` ejecuta `_playerStore.query().onSnapshots(_database)` sincrónicamente, donde el getter `_database` lanza `StateError` si `_db == null`. Como `init()` no manejaba la excepción, los streams nunca se creaban y las tarjetas quedaban con valor "0" permanentemente, dando apariencia de pantalla en blanco/gris sobre fondo oscuro.

## Lo que cambió (1 archivo)

### `lib/ui/dashboard_viewmodel.dart`

1. **`init()` ahora es async** y llama a `await db.initialize()` antes de suscribir streams.
2. **Guard `_initialized`** — si ya se inicializó, `init()` retorna inmediatamente.
3. **Try/catch** — si `initialize()` falla, captura el error en `_error` y notifica listeners.

### Archivos NO modificados

- `lib/ui/dashboard_screen.dart` — `didChangeDependencies` llama a `init()` sin await; el fire-and-forget funciona porque:
  - El screen guard `_initialized` previene re-llamadas
  - El VM guard `_initialized` previene ejecución duplicada
  - Los streams emiten asíncronamente y `notifyListeners()` actualiza la UI
- `lib/ui/app_shell.dart` — sin cambios
- `lib/main.dart` — sin cambios

## Código final

```dart
Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _playerSub?.cancel();
    _matchSub?.cancel();
    try {
      final db = DatabaseService.instance;
      await db.initialize();
      _playerSub = db.watchAllPlayers().listen((players) {
        _athleteCount = players.length;
        notifyListeners();
      });
      _matchSub = db.watchMatchesByState(EstadoPartido.finalizado).listen((matches) {
        _matchCount = matches.length;
        _setCount = matches.fold(0, (sum, m) => sum + m.setActual - 1);
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
}
```

## Verificación

- `dart analyze lib/ui/dashboard_viewmodel.dart` → **No issues found**
- `DashboardScreen` usa `context.watch<DashboardViewModel>()` que reacciona a `notifyListeners()` en cada emisión de stream
- `DatabaseService.instance.initialize()` es idempotente (guard `_isInitialized`)

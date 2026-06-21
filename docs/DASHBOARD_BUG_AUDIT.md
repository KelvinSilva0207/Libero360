# FASE 5.0A — Auditoría: Dashboard en Blanco al Iniciar

## Síntoma
Dashboard aparece en blanco/gris al abrir la app. Solo se renderiza correctamente al cambiar de pestaña y volver.

## Causa Raíz (1 de 2): DatabaseService no inicializado

**Archivo:** `lib/ui/dashboard_viewmodel.dart:18-31`
**Línea:** 21

```dart
void init() {
    _playerSub?.cancel();
    _matchSub?.cancel();
    final db = DatabaseService.instance;           // ← singleton ok
    _playerSub = db.watchAllPlayers().listen(...);  // ← llama a _database getter
    _matchSub = db.watchMatchesByState(...).listen(...);
}
```

**Problema:** `watchAllPlayers()` (en `database_service.dart:234`) ejecuta `_playerStore.query().onSnapshots(_database)`. El getter `_database` (`database_service.dart:41`) lanza `StateError` si `_db == null`:

```dart
Database get _database {
    if (_db == null) throw StateError('Database not initialized. Call initialize() first.');
    return _db!;
}
```

**Flujo del error:**
1. `init()` llama a `db.watchAllPlayers()`
2. `watchAllPlayers()` ejecuta `onSnapshots(_database)` **sincrónicamente**
3. `_database` getter ve `_db == null` → lanza `StateError`
4. La excepción sale de `init()`, que es llamado desde `didChangeDependencies()`
5. Flutter atrapa la excepción (no crashea la app), pero **los streams nunca se crean**
6. `_athleteCount`, `_matchCount`, `_setCount` quedan en `0` para siempre
7. La UI muestra tarjetas con valor "0" sobre fondo oscuro → apariencia de "blanco/gris vacío"

**¿Por qué funcionaba antes de FASE 3C?**  
El viejo `refresh()` llamaba a `await db.initialize()` antes de cualquier consulta:

```dart
// Antes (FASE 3C):
Future<void> refresh() async {
    final db = DatabaseService.instance;
    await db.initialize();                    // ← aseguraba DB lista
    final players = await db.getAllPlayers(); // ← no lanzaba
    ...
}
```

## Causa Raíz (2 de 2): Streams no emiten inmediatamente

**Aún si la DB estuviera inicializada**, `onSnapshots()` es asíncrono — la primera emisión llega en un microtask posterior. El primer `build()` de `DashboardScreen` siempre ocurre con `athleteCount = 0`, `matchCount = 0`, `setCount = 0`.

**¿Por qué "cambiar de pestaña" lo arreglaba (antes de FASE 3C)?**  
El viejo `_selectTab` en `app_shell.dart` llamaba a `context.read<DashboardViewModel>().refresh()`. Eso re-ejecutaba la consulta completa con DB ya inicializada. En FASE 3C eliminé esa llamada:

```diff
  void _selectTab(int index) {
      setState(() => _selectedIndex = index);
-     if (index == 0) {
-         context.read<DashboardViewModel>().refresh();
-     }
  }
```

Pero este no es el bug principal — el bug principal es la falta de `db.initialize()`.

## Archivos y Líneas Afectados

| Archivo | Línea | Problema |
|---------|-------|----------|
| `lib/ui/dashboard_viewmodel.dart` | 18-31 | `init()` no llama a `db.initialize()` |
| `lib/features/estadisticas/data/local_db/database_service.dart` | 234-238 | `watchAllPlayers()` usa `_database` getter que lanza si no inicializado |
| `lib/features/estadisticas/data/local_db/database_service.dart` | 240-248 | `watchMatchesByState()` idem |
| `lib/ui/app_shell.dart` | 45-49 | `_selectTab` eliminó `refresh()` que era el workaround |

## Solución Propuesta

**Opción A (recomendada):** Que `init()` asegure la inicialización de la DB **antes** de suscribir streams.

```dart
Future<void> init() async {
    _playerSub?.cancel();
    _matchSub?.cancel();
    final db = DatabaseService.instance;
    await db.initialize();   // ← asegura DB lista
    _playerSub = db.watchAllPlayers().listen(...);
    _matchSub = db.watchMatchesByState(...).listen(...);
}
```

Y en `DashboardScreen`:

```dart
@override
void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
        _initialized = true;
        context.read<DashboardViewModel>().init(); // ahora es async
    }
}
```

**Opción B:** Inicializar DB una sola vez al crear `DashboardViewModel` en `main.dart`:

```dart
ChangeNotifierProvider(create: (_) {
    final vm = DashboardViewModel();
    DatabaseService.instance.initialize().then((_) => vm.init());
    return vm;
}),
```

**Opción C (mínimo cambio):** Inicializar DB al inicio de la app en `main()`:

```dart
void main() async {
    ...
    await DatabaseService.instance.initialize(); // ← global
    runApp(...);
}
```

### Comparación

| Opción | Esfuerzo | Riesgo | Notas |
|--------|----------|--------|-------|
| **A** | 2 líneas | Bajo | init() se vuelve async; didChangeDependencies lo soporta |
| **B** | 3 líneas | Bajo | Desacopla inicialización de UI |
| **C** | 1 línea | Medio | Inicializa DB globalmente; podría retrasar el arranque |

## Efecto Secundario: Stream no emite inmediatamente

Con Opción A/B/C, el stream se suscribe correctamente, pero la **primera emisión** puede tardar un frame. Durante ese frame, el Dashboard muestra "0" en las tarjetas.

**Solución:** No es necesario cambiar la UI. Es un flash imperceptible (1-2 frames) que no causa "blanco/gris". Si se desea eliminar el flash, se puede agregar estado `_loaded` (como antes):

```dart
bool _loaded = false;
int get athleteCount => _loaded ? _athleteCount : 0;
// En el listener:
_loaded = true;
notifyListeners();
```

## Riesgos de la Corrección

1. **`init()` async** — `didChangeDependencies` no espera el futuro. La suscripción a streams ocurre después del primer build, pero eso ya pasaba antes. Sin riesgo adicional.
2. **DB inicializada dos veces** — `DatabaseService.initialize()` ya tiene guard `if (_isInitialized) return;`. Sin riesgo.
3. **Streams duplicados** — El `_initialized` flag en `_DashboardScreenState` evita llamar `init()` múltiples veces. Sin riesgo.

## ¿Modifica UI o solo lógica?
**Solo lógica.** El cambio se limita a `lib/ui/dashboard_viewmodel.dart` (agregar `await db.initialize()`). La UI de `dashboard_screen.dart` no se toca.

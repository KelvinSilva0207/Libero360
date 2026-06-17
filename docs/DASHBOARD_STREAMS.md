# FASE 3C: Dashboard Streams

## Objetivo
Eliminar el refresh manual del Dashboard convirtiéndolo a tiempo real mediante streams de sembast.

## Arquitectura — Antes

```
DashboardScreen          AppShell
  └─ didChangeDeps()       └─ _selectTab(0)
       └─ load()                └─ refresh()
            └─ refresh()
                 ├─ db.getAllPlayers()
                 └─ db.getMatchesByState(finalizado)
```

El Dashboard solo se actualizaba al navegar a la pestaña (vía `didChangeDependencies`) o al cambiar de pestaña (vía `_selectTab`). Cualquier cambio en la base de datos (nuevo atleta, partido finalizado) requería una acción manual del usuario para reflejarse.

## Arquitectura — Después

```
DatabaseService (sembast)
  ├─ _playerStore.query().onSnapshots(db) ──→ Stream<List<Player>>
  └─ _matchStore.query(finder).onSnapshots(db) ──→ Stream<List<Match>>
                                                    │
                                                    ▼
                                        DashboardViewModel
                                          ├─ _playerSub.listen()
                                          └─ _matchSub.listen()
                                                    │
                                           notifyListeners()
                                                    │
                                                    ▼
                                        DashboardScreen (Consumer<DashboardViewModel>)
                                          └─ watch() → UI reactiva
```

Los streams emiten automáticamente cuando sembast detecta cambios en las stores, sin necesidad de refresh manual.

## Streams Creados

| Stream | Método en DatabaseService | Descripción |
|--------|---------------------------|-------------|
| `Stream<List<Player>>` | `watchAllPlayers()` | Todos los atletas. Emite en cada `savePlayer`/`deletePlayer`. |
| `Stream<List<Match>>` | `watchMatchesByState(EstadoPartido.finalizado)` | Partidos finalizados. Emite en cada `saveMatch`/`deleteMatch`. El `Finder` filtra por `estado`. |

Ambos usan `RecordQuery.onSnapshots(Database)` de sembast 3.8.7, que re-emite la consulta completa cuando cualquier registro de la store cambia.

## Cambios Realizados

### `lib/features/estadisticas/data/local_db/database_service.dart`
- Nuevos métodos: `watchAllPlayers()`, `watchMatchesByState(EstadoPartido)`
- Usan `storeRef.query(finder: ...).onSnapshots(_database)` para streams reactivos nativos de sembast

### `lib/core/services/club_data_service.dart`
- `streamPlayers()` ahora delega a `DatabaseService.watchAllPlayers()` cuando Firebase está deshabilitado (en lugar de `Stream.empty()`)

### `lib/ui/dashboard_viewmodel.dart`
- Eliminados: `_loaded`, `_loading`, `load()`, `refresh()`
- Nuevo: `init()` que suscribe a `watchAllPlayers()` y `watchMatchesByState(finalizado)`
- Los callbacks de los streams actualizan `_athleteCount`, `_matchCount`, `_setCount` y llaman `notifyListeners()`
- `dispose()` cancela las suscripciones

### `lib/ui/dashboard_screen.dart`
- `didChangeDependencies()` llama a `vm.init()` una sola vez (guard band con `_initialized`)

### `lib/ui/app_shell.dart`
- `_selectTab()` ya no llama a `context.read<DashboardViewModel>().refresh()`

## Rendimiento
- Los streams de sembast son reactivos: solo re-emiten cuando la store subyacente cambia
- No hay polling ni consultas periódicas
- Cada stream emite la lista completa de resultados, que se procesa en el ViewModel para calcular conteos
- Las suscripciones se cancelan en `dispose()` — sin fugas de memoria

## Compatibilidad
- **UI intacta**: DashboardScreen sigue usando `context.watch<DashboardViewModel>()`
- **Providers intactos**: `DashboardViewModel` sigue como `ChangeNotifierProvider`
- **Navegación intacta**: misma estructura de rutas
- **Firebase**: las streams de Firestore siguen siendo `Stream.empty()` cuando está deshabilitado; la capa local las reemplaza
- **0 errores** en `flutter analyze` (253 issues: solo info/warnings pre-existentes)

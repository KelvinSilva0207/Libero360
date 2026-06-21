# FASE 5.2 — MatchController Guard

## Problema Original

`MatchController` es un singleton registrado en `main.dart` como `ChangeNotifierProvider(create: (_) => MatchController())`. Tanto `PlayByPlayScreen` como `MatchScreen` leen la misma instancia compartida via `ctx.read<MatchController>()`.

Antes de esta corrección, `init()` no verificaba si ya existía un partido activo. Esto permitía:

1. Usuario inicia partido desde PlayByPlay → `MatchController.init(config1)`
2. Usuario navega a MatchScreen y toca "Nuevo Partido" → `MatchController.init(config2)` **sobrescribe** el partido anterior
3. El primer partido se pierde silenciosamente (creado en DB pero luego sobrescrito)

## Riesgo de Pérdida de Datos

- **Alto**: Si un usuario está registrando estadísticas en vivo en PlayByPlay y accidentalmente abre MatchScreen, el partido activo se sobrescribe sin advertencia. Todos los puntos y eventos registrados en el partido original se pierden (el nuevo `init()` crea un nuevo Match en DB, pero las referencias al anterior se pierden en el controller).

## Solución

### 1. `MatchController.init()` → `Future<bool>` con guard

```dart
// Antes:
Future<void> init([MatchConfig? config]) async { ... }

// Después:
Future<bool> init([MatchConfig? config]) async {
    if (_match != null &&
        _match!.estado != EstadoPartido.finalizado) {
        _error = 'Ya existe un partido activo';
        notifyListeners();
        return false;  // ← rechazar sin sobrescribir
    }
    // ... iniciar partido normalmente ...
    return true;
}
```

### 2. `PartidoViewModel.init()` propaga el bool

El ViewModel ahora retorna `Future<bool>` y notifica listeners si falla.

### 3. `PlayByPlayViewModel.iniciarNuevoPartido()` maneja el error

Si `init()` retorna `false`, captura `_controller.error` y lo expone como `_ownError` para que la UI lo muestre.

### 4. Logs de depuración

- `🟡 MATCH: intento de iniciar partido`
- `🟢 MATCH: partido iniciado`
- `🔴 MATCH: ya existe un partido activo`

## Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/partido/presentation/controllers/match_controller.dart` | Guard + `Future<bool>` + logs |
| `lib/features/partido/presentation/viewmodels/partido_viewmodel.dart` | `init()` retorna `Future<bool>` |
| `lib/features/estadisticas/presentation/viewmodels/play_by_play_viewmodel.dart` | Maneja `bool`, setea `_ownError` |

## Compatibilidad con FASE 3A

- **Arquitectura Provider global**: No se modifica. MatchController sigue siendo singleton compartido.
- **main.dart**: Sin cambios.
- **Dashboard**: Sin cambios.
- **DatabaseService**: Sin cambios.
- **MatchScreen**: Sin cambios en la UI. El `..init()` cascade en `create:` funciona con `Future<bool>` (el resultado se ignora). Si `init()` falla, la UI ya muestra la pantalla de error (línea 45 de `match_screen.dart`).
- **PartidoViewModel**: `init()` ahora es `async` y retorna `bool` en vez de ser un delegate one-liner. Todos los getters y métodos delegados permanecen idénticos.

## Verificación

```
$ dart analyze lib/features/partido/presentation/viewmodels/partido_viewmodel.dart
No issues found!

$ dart analyze lib/features/estadisticas/presentation/viewmodels/play_by_play_viewmodel.dart
No issues found!
```

## Comportamiento Esperado

| Escenario | Antes | Después |
|-----------|-------|---------|
| Iniciar partido sin partido activo | Crea partido normalmente | Crea partido normalmente |
| Iniciar partido con partido activo | Sobrescribe silenciosamente | Error: "Ya existe un partido activo", no sobrescribe |
| PlayByPlay: iniciar con partido activo | Match sobrescrito, datos perdidos | Error visible al usuario, partido original intacto |
| MatchScreen: reintentar tras error | Llama init() de nuevo | Respeta guard, muestra error si sigue activo |

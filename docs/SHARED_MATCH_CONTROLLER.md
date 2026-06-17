# FASE 3A: MatchController Compartido via Provider

## Objetivo
Eliminar las instancias independientes de `MatchController` en `PartidoViewModel` y `PlayByPlayViewModel`, reemplazándolas por una instancia compartida provista por `ChangeNotifierProvider<MatchController>` en el árbol de widgets.

## Cambios Realizados

### 1. `lib/main.dart` — Provider global
- Añadido `import` de `match_controller.dart`
- Agregado `ChangeNotifierProvider(create: (_) => MatchController())` al `MultiProvider` existente

Esto coloca al `MatchController` como ancestro de todas las rutas (MatchScreen, PlayByPlayScreen, AppShell, etc.), permitiendo que cualquier screen lo lea via `context.read<MatchController>()`.

### 2. `lib/features/partido/presentation/viewmodels/partido_viewmodel.dart`
Antes:
```dart
final MatchController _controller = MatchController();
PartidoViewModel() { ... }
```
Después:
```dart
final MatchController _controller;
PartidoViewModel(this._controller) { ... }
```
- El controller se recibe por constructor en lugar de crearse internamente
- `dispose()` ya no llama a `_controller.dispose()` — la vida del controller la gestiona el Provider

### 3. `lib/features/estadisticas/presentation/viewmodels/play_by_play_viewmodel.dart`
Mismo cambio que PartidoViewModel:
- `final MatchController _controller` recibido por constructor
- `dispose()` ya no llama a `_controller.dispose()`

### 4. `lib/features/partido/presentation/views/match_screen.dart`
Antes:
```dart
ChangeNotifierProvider(
  create: (_) => PartidoViewModel()..init(widget.config),
```
Después:
```dart
ChangeNotifierProvider(
  create: (ctx) => PartidoViewModel(ctx.read<MatchController>())..init(widget.config),
```

### 5. `lib/features/estadisticas/presentation/views/play_by_play_screen.dart`
Antes:
```dart
ChangeNotifierProvider(
  create: (_) => PlayByPlayViewModel(),
```
Después:
```dart
ChangeNotifierProvider(
  create: (ctx) => PlayByPlayViewModel(ctx.read<MatchController>()),
```

## Arquitectura Resultante

```
MultiProvider (main.dart)
 ├── ChangeNotifierProvider<AuthViewModel>
 ├── ChangeNotifierProvider<ThemeNotifier>
 ├── ChangeNotifierProvider<DashboardViewModel>
 ├── ChangeNotifierProvider<ClubViewModel>
 ├── ChangeNotifierProvider<NotificationViewModel>
 ├── ChangeNotifierProvider<MatchController>  ← NUEVO
 └── MaterialApp
      └── Navigator
           ├── Route: AppShell
           │    └── ChangeNotifierProvider<PartidoViewModel> (MatchScreen)
           │         └── MatchController ← leído del Provider global
           └── Route: PlayByPlayScreen
                └── ChangeNotifierProvider<PlayByPlayViewModel>
                     └── MatchController ← leído del Provider global
```

Ambos ViewModels ahora comparten la **misma** instancia de `MatchController`. El timer, el score, los sets, la rotación y la persistencia operan sobre un único estado.

## Verificación
`flutter analyze` — 0 errores (252 issues: 250 info + 2 warnings pre-existentes)

## Notas
- `MatchController` se crea una vez al iniciar la app y vive mientras la app corre
- Cada nuevo partido llama a `MatchController.init(config)` que resetea el estado interno (timer, scores, rotación)
- No hay fuga de memoria: el Provider global mantiene la referencia, y los VMs solo escuchan cambios via `addListener`/`removeListener`
- Los VMs ya no son responsables del ciclo de vida del controller

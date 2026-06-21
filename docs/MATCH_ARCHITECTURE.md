# FASE 2 — Arquitectura Partido Unificada

> 17 Junio 2026

---

## 1. Auditoría de ViewModel Actuales

### 1.1 PartidoViewModel (`features/partido/`)

**Archivo:** `lib/features/partido/presentation/viewmodels/partido_viewmodel.dart` (448 líneas)

| Responsabilidad | Métodos | Mutex con PBPVM? |
|---|---|---|
| Score local/visitante | `sumarPuntoLocal`, `sumarPuntoVisitante`, `restarPuntoLocal`, `restarPuntoVisitante`, `undoLastPoint` | Sí, duplicado |
| Set tracking | `_actualizarSetScores`, `cambiarSet` | No (PBPVM no trackea sets) |
| Timer | `_iniciarTimer`, `_detenerTimer`, `_guardarDuracion` | No |
| Rotación | `rotarLocal`, `rotarVisitante`, `cambiarServicio` | No |
| Roster | `_jugadores`, `_jugadoresVisitante`, `actualizarNumeroJugador` | Parcial (PBPVM tiene jugadores pero para selección) |
| Persistencia partido | Delegado a `MatchRepository` | Sí |
| Persistencia eventos | `_registrarEvento` → `saveMatchEvent` | Parcial (PBPVM usa StatEventRepository) |
| Pausa/Reanudar/Finalizar | `pausarReanudar`, `finalizarPartido`, `eliminarPartido` | Sí |
| Config | `actualizarConfiguracion`, `init` | No |
| Nombres equipos | `actualizarNombreLocal`, `actualizarNombreVisitante` | No |

**Consumidores:** `match_screen.dart`, `coach_mode_screen.dart`

---

### 1.2 PlayByPlayViewModel (`features/estadisticas/`)

**Archivo:** `lib/features/estadisticas/presentation/viewmodels/play_by_play_viewmodel.dart` (458 líneas)

| Responsabilidad | Métodos | Mutex con PVM? |
|---|---|---|
| Score local/visitante | `agregarPuntoLocal`, `agregarPuntoVisitante` | Sí, duplicado |
| Partido CRUD | `iniciarNuevoPartido`, `cargarPartido`, `pausarPartido`, `reanudarPartido`, `finalizarPartido` | Sí, duplicado |
| Selección jugador | `seleccionarJugador`, `cambiarEquipo`, `setJugadoresLocal/Visitante` | No |
| Registro acciones | `registrarAtaque`, `registrarSaque`, `registrarBloqueo`, `registrarDefensa`, `registrarErrorContrario` | No |
| Consultas estadísticas | `obtenerEstadisticasJugador`, `obtenerTimeline`, `obtenerResumen` | No |
| Gestión eventos | `_actualizarEventos` | Sí (parcial, otro modelo) |

**Consumidor:** `play_by_play_screen.dart`

---

### 1.3 Resumen de Duplicación

| Área | PartidoViewModel | PlayByPlayViewModel |
|---|---|---|
| **Modelo partido** | `Match` (estadisticas/models) | `Match` (estadisticas/models) |
| **Score** | `_match.puntosLocal/Visitante` | `_partidoActual.puntosLocal/Visitante` |
| **Set tracking** | `_setScores` + `setActual` | — (solo expone `setActual`) |
| **Timer** | Timer + `_duracionSegundos` | — |
| **Rotación** | `_rotacionLocal/Visitante`, `_isLocalServing` | — |
| **Jugadores** | `_jugadores`, `_jugadoresVisitante` (roster fijo) | `_jugadoresLocal`, `_jugadoresVisitante` + `_jugadorSeleccionado` |
| **Eventos** | `MatchEvent` (punto simple) | `StatEvent` (acción detallada) |
| **Repo scoring** | `MatchRepository` | `MatchRepository` |
| **Repo eventos** | `DatabaseService.saveMatchEvent` | `StatEventRepository` |

**Conclusión:** 60% de duplicación. PartidoViewModel es **más pesado** (timer, rotación, sets). PlayByPlayViewModel es más **especializado** (acciones por jugador, estadísticas).

---

## 2. Dependencias

```
                        ┌─────────────────────┐
                        │    match_screen.dart │
                        │  coach_mode_screen   │
                        └──────────┬──────────┘
                                   │
                        ┌──────────▼──────────┐
                        │  PartidoViewModel   │
                        │  (448 lines)        │
                        └──┬──────┬───────┬───┘
                           │      │       │
              ┌────────────┘      │       └──────────────┐
              ▼                   ▼                      ▼
    ┌─────────────────┐  ┌──────────────┐    ┌──────────────────┐
    │  MatchRepository │  │ DatabaseSvc  │    │  MatchEvent      │
    │  (stats/repos)   │  │ (stats/db)   │    │  (partido/data)  │
    └─────────────────┘  └──────────────┘    └──────────────────┘

                        ┌─────────────────────┐
                        │  play_by_play_screen │
                        └──────────┬──────────┘
                                   │
                        ┌──────────▼──────────┐
                        │ PlayByPlayViewModel │
                        │  (458 lines)        │
                        └──┬──────┬───────┬───┘
                           │      │       │
              ┌────────────┘      │       └──────────────┐
              ▼                   ▼                      ▼
    ┌─────────────────┐  ┌──────────────┐    ┌──────────────────────┐
    │  MatchRepository │  │ StatEventRepo│    │  StatEvent (model)  │
    │  (stats/repos)   │  │ (stats/repos)│    │  (stats/models)     │
    └─────────────────┘  └──────────────┘    └──────────────────────┘
```

---

## 3. Análisis MatchEvent vs StatEvent

### MatchEvent (`features/partido/data/`)
- **Propósito:** Registrar punto simple con rotación para CourtScreen/CoachMode
- **Campos:** `athleteId`, `matchId`, `setNumero`, `EventType` (winnerPoint, regularPoint, error), `tipoPartido`, `rotacion`
- **`athleteId` no es FK real** — se usa como 0 en la práctica (PartidoViewModel siempre pasa 0)
- **Consumidores:** `partido_viewmodel`, `court_viewmodel`, `stat_recorder_widget`, `club_data_service`, `club_viewmodel`, `coach_mode_screen`, `database_service`

### StatEvent (`features/estadisticas/data/models/`)
- **Propósito:** Acción estadística detallada (ataque, saque, bloqueo, defensa, error)
- **Campos:** `TipoAccion`, `ResultadoAccion`, `ZonaCancha`, `playerId` (FK real), `matchId`, `setNumero`, `puntoLocal`, `puntoVisitante`, `esEquipoLocal`
- **Consumidores:** `play_by_play_screen`, `stat_recorder_widget` (partido/), `play_by_play_viewmodel`, `stat_event_repository`

### Veredicto: NO SE PUEDE ELIMINAR MatchEvent

| Razón | Detalle |
|---|---|
| **Rotación** | MatchEvent guarda `rotacion` (posición en cancha), StatEvent no |
| **CourtScreen** | CourtScreen usó MatchEvent históricamente, cambiar rompería datos existentes |
| **ClubDataService** | Firebase sync está atada a MatchEvent (stream + map) |
| **CoachModeScreen** | CoachModeScreen lee MatchEvents para su set history |
| **Propósito diferente** | MatchEvent = "qué pasó" (punto + rotación); StatEvent = "quién lo hizo y cómo" (acción + jugador + resultado) |
| **Acoplamiento externo** | `club_data_service.dart` y `club_viewmodel.dart` dependen de MatchEvent para sync en la nube |

### Propuesta: Mapper MatchEvent → StatEvent

En lugar de eliminar, crear un **adaptador/mapper** que permita:
- MatchEvent → StatEvent (cuando se quiera promover un punto simple a estadística completa)
- Ambos coexisten; MatchEvent sigue siendo el registro rápido de rotación, StatEvent el detalle analítico

```dart
StatEvent matchEventToStatEvent(MatchEvent e, {int? playerId}) {
  return StatEvent(
    tipoAccion: _mapEventTypeToAccion(e.eventType),
    resultado: ResultadoAccion.positivo,
    setNumero: e.setNumero,
    playerId: playerId ?? e.athleteId,
    matchId: e.matchId,
    esEquipoLocal: true, // se resolvería con contexto
    zona: ZonaCancha.ninguna,
    // ...
  );
}
```

---

## 4. Propuesta Final: MatchController

### 4.1 Principios

1. **Un solo ChangeNotifier** para el partido en vivo (`MatchController`)
2. **PartidoViewModel se refactoriza** para delegar a MatchController
3. **PlayByPlayViewModel se refactoriza** para delegar a MatchController (y agregar StatEvent encima)
4. **MatchController es la única fuente de verdad** para score, sets, timer, rotación, roster, estado
5. **PlayByPlayScreen** sigue existiendo como UI que usa MatchController + StatEventRepository directamente
6. **MatchScreen** sigue usando MatchController con su layout actual

### 4.2 Responsabilidades de MatchController

```dart
class MatchController extends ChangeNotifier {
  // ─── Repos ───
  MatchRepository matchRepo;
  StatEventRepository statEventRepo;

  // ─── Estado Core ───
  Match? _match;                    // modelo Match (stats/models)
  List<MapEntry<int, int>> _setScores;
  int _puntosPorSet, _setsPorPartido, _tiempoPorSet;

  // ─── Timer ───
  Timer? _timer;
  int _duracionSegundos = 0;

  // ─── Rotación ───
  List<Player> _jugadoresLocal;     // roster fijo (6)
  List<Player> _jugadoresVisitante;
  int _rotacionLocal = 0, _rotacionVisitante = 0;
  bool _isLocalServing = true;

  // ─── Eventos ───
  List<MatchEvent> _matchEvents;

  // ─── Getters (idénticos a PartidoViewModel) ───
  // score, sets, estado, timer, rotación, setScores, etc.
}
```

### 4.3 API Pública

```
┌─────────────────────────────────────────────────┐
│                MatchController                   │
├─────────────────────────────────────────────────┤
│ init(MatchConfig)                                │
│ sumarPuntoLocal() / sumarPuntoVisitante()        │
│ restarPuntoLocal() / restarPuntoVisitante()      │
│ undoLastPoint()                                  │
│ cambiarSet(int)                                  │
│ rotarLocal() / rotarVisitante()                  │
│ cambiarServicio()                                │
│ pausarReanudar()                                 │
│ finalizarPartido()                               │
│ eliminarPartido()                                │
│ actualizarConfiguracion(...)                     │
│ actualizarNombreLocal/Visitante(...)             │
│ actualizarNumeroJugador(int pos, int num)        │
│ refresh() → recarga desde DB                     │
└─────────────────────────────────────────────────┘
```

### 4.4 Migración PartidoViewModel

PartidoViewModel se convierte en un **wrapper/delegator** a MatchController para no romper `match_screen.dart` ni `coach_mode_screen.dart`:

```dart
class PartidoViewModel extends ChangeNotifier {
  final MatchController _controller;

  // Delegación directa
  Match? get match => _controller.match;
  int get puntosLocal => _controller.puntosLocal;
  // ... todos los getters y métodos delegan
}
```

Esto permite:
- Migración gradual (PartidoViewModel mantiene API idéntica)
- MatchController es testeable independientemente
- MatchScreen y CoachModeScreen NO requieren cambios

### 4.5 Migración PlayByPlayViewModel

PlayByPlayViewModel se simplifica para:
- Usar MatchController para score/partido
- Conservar su capa de selección de jugador + registro StatEvent
- Eliminar los métodos duplicados `agregarPuntoLocal/Visitante`, `pausar/reanudar/finalizar`

```dart
class PlayByPlayViewModel extends ChangeNotifier {
  final MatchController matchController;

  // Solo lo propio:
  Player? _jugadorSeleccionado;
  bool _esEquipoLocal = true;
  List<StatEvent> _eventos = [];

  // registrarAtaque/Saque/Bloqueo/Defensa/Error → delegan score a matchController
  // + registran StatEvent via StatEventRepository
}
```

### 4.6 Ubicación

```
lib/
  features/
    partido/
      presentation/
        controllers/
          match_controller.dart     ← NUEVO (ChangeNotifier con toda la lógica)
        viewmodels/
          partido_viewmodel.dart    ← REFACTOR (delegador a MatchController)
    estadisticas/
      presentation/
        viewmodels/
          play_by_play_viewmodel.dart ← REFACTOR (usa MatchController + StatEventRepo)
```

---

## 5. Riesgos de Migración

| Riesgo | Impacto | Mitigación |
|---|---|---|
| **PartidoViewModel tiene 13 consumidores externos** | Alto — cambiar API rompe match_screen y coach_mode_screen | Mantener API idéntica via delegación |
| **Timer está atado a PartidoViewModel** | Medio — si MatchController vive en otro Provider, el timer sigue funcionando | MatchController es ChangeNotifier; mismo patrón |
| **CoachModeScreen + MatchScreen usan el mismo ViewModel** | Bajo — ambas delegarán al mismo MatchController | MatchController se provee una vez; ambas pantallas lo reciben |
| **PlayByPlayScreen tiene su propio Provider (creación inline)** | Medio — habrá que compartir o crear MatchController arriba | MatchController como provider global (ya está en MultiProvider? No. Agregar.) |
| **ClubDataService atado a MatchEvent** | Bajo — MatchEvent no se elimina, solo se mueve | Mapper MatchEvent→StatEvent es adicional, no sustitutivo |
| **PartidoViewModel.init() recibe MatchConfig, PlayByPlayViewModel.iniciarNuevoPartido() recibe strings** | Medio — unificar API de creación | MatchController.init() acepta MatchConfig (ya existe) |

---

## 6. Plan Paso a Paso

### Paso 1: Crear MatchController
- Crear `lib/features/partido/presentation/controllers/match_controller.dart`
- Copiar toda la lógica de PartidoViewModel (score, sets, timer, rotación, roster, persistencia)
- Mantener getters y setters idénticos
- NO tocar MatchEvent ni StatEvent

### Paso 2: Refactorizar PartidoViewModel como delegador
- Inyectar MatchController por constructor
- Todos los getters/métodos delegan
- MatchScreen y CoachModeScreen siguen funcionando sin cambios

### Paso 3: Registrar MatchController en MultiProvider (main.dart)
- `ChangeNotifierProvider(create: (_) => MatchController())`
- Asegurar que esté disponible para todas las pantallas

### Paso 4: Refactorizar PlayByPlayViewModel
- Inyectar MatchController en lugar de tener su propio `_partidoActual`
- Eliminar `agregarPuntoLocal/Visitante`, `pausar/reanudar/finalizar` (ya están en MatchController)
- Conservar selección jugador + registro StatEvent

### Paso 5: Crear mapper MatchEvent → StatEvent
- Archivo `lib/features/partido/data/match_event_mapper.dart`
- Función `matchEventToStatEvent(MatchEvent, {int? playerId}) → StatEvent`
- Útil para promover MatchEvent a estadística detallada

### Paso 6: Limpiar código muerto
- Verificar que PartidoViewModel ya no tenga lógica duplicada
- Verificar imports no usados

### Paso 7: Test
- `flutter analyze` → 0 errores
- MatchScreen: scoring, timer, rotación, sets
- CoachModeScreen: eventos, historial
- PlayByPlayScreen: estadísticas por jugador
- Dashboard: contadores actualizados

---

## 7. Resumen

| Concepto | Decisión |
|---|---|
| **¿Eliminar Matchevent?** | No. Sirve para rotación + sync nube. Agregar mapper a StatEvent. |
| **¿Unificar ViewModels?** | Sí, vía MatchController como fuente única de verdad. |
| **PartidoViewModel** | Refactor → delegador de MatchController (API pública intacta). |
| **PlayByPlayViewModel** | Refactor → usa MatchController + conserva capa StatEvent. |
| **Timer** | Pasa a MatchController (misma lógica). |
| **Rotación** | Pasa a MatchController (ya está en PVM). |
| **Ubicación** | `features/partido/presentation/controllers/match_controller.dart` |
| **Riesgos** | 6 identificados, todos con mitigación. |

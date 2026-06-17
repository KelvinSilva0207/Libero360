# FASE 3B: MatchEventMapper

## Propósito

Capa de conversión bidireccional entre `MatchEvent` (features/partido — rotación) y `StatEvent` (features/estadisticas — modelo canónico de eventos estadísticos), permitiendo que ambos sistemas interoperen sin acoplarse.

## Archivos

| Archivo | Ruta |
|---------|------|
| Mapper | `lib/features/partido/data/mappers/match_event_mapper.dart` |
| Tests | `test/features/partido/data/mappers/match_event_mapper_test.dart` |

## Tabla de Equivalencias

### MatchEvent → StatEvent

| MatchEvent        | StatEvent           | Tipo              | Notas |
|-------------------|---------------------|-------------------|-------|
| `id`              | `id`                | directa           | Se asigna 0 (nuevo evento) |
| `athleteId`       | `playerId`          | directa           | Mismo concepto |
| `matchId`         | `matchId`           | directa           | Idéntico |
| `fecha`           | `timestamp`         | directa           | `StatEvent.create` usa `DateTime.now()` |
| `fecha`           | `createdAt`         | directa           | Misma fuente |
| `setNumero`       | `setNumero`         | directa           | Idéntico |
| `eventType`       | `tipoAccion`        | **mapeo**         | ver tabla detalle abajo |
| `eventType`       | `resultado`         | **mapeo**         | ver tabla detalle abajo |
| —                 | `puntoLocal`        | **valor default** | `0` — no existe en MatchEvent |
| —                 | `puntoVisitante`    | **valor default** | `0` — no existe en MatchEvent |
| —                 | `esEquipoLocal`     | **valor default** | `false` — no existe en MatchEvent |
| —                 | `zona`              | **valor default** | `ZonaCancha.ninguna` |
| `tipoPartido`     | `descripcion`       | **derivado**      | Se concatena con label del eventType |
| `tipoPartido`     | —                   | **PERDIDA**       | No hay campo equivalente en StatEvent |
| `competenciaNombre` | —                 | **PERDIDA**       | No hay campo equivalente en StatEvent |
| `rotacion`        | —                   | **PERDIDA**       | No hay campo equivalente en StatEvent |

### StatEvent → MatchEvent

| StatEvent            | MatchEvent         | Tipo              | Notas |
|----------------------|--------------------|-------------------|-------|
| `id`                 | `id`               | directa           | Se asigna 0 (nuevo evento) |
| `playerId`           | `athleteId`        | directa           | Mismo concepto |
| `matchId`            | `matchId`          | directa           | Idéntico |
| `timestamp`          | `fecha`            | directa           | `MatchEvent.create` usa `DateTime.now()` |
| `setNumero`          | `setNumero`        | directa           | Idéntico |
| `resultado`          | `eventType`        | **mapeo**         | ver tabla detalle abajo |
| —                    | `tipoPartido`      | **valor default** | `''` — no existe en StatEvent |
| —                    | `competenciaNombre`| **valor default** | `null` — no existe en StatEvent |
| —                    | `rotacion`         | **valor default** | `0` — no existe en StatEvent |
| `tipoAccion`         | —                  | **PERDIDA**       | MatchEvent no distingue tipo de acción |
| `puntoLocal`         | —                  | **PERDIDA**       | No hay campo equivalente |
| `puntoVisitante`     | —                  | **PERDIDA**       | No hay campo equivalente |
| `esEquipoLocal`      | —                  | **PERDIDA**       | No hay campo equivalente |
| `zona`               | —                  | **PERDIDA**       | No hay campo equivalente |
| `descripcion`        | —                  | **PERDIDA**       | No hay campo equivalente |

### Mapeo de `EventType` ↔ `TipoAccion`/`ResultadoAccion`

| MatchEvent EventType | StatEvent TipoAccion    | StatEvent Resultado      |
|----------------------|------------------------|--------------------------|
| `winnerPoint`        | `ataque` (default)     | `positivo`               |
| `regularPoint`       | `ataque` (default)     | `positivo`               |
| `error`              | `errorContrario`       | `negativo`               |

| StatEvent Resultado  | MatchEvent EventType |
|----------------------|----------------------|
| `positivo`           | `winnerPoint`        |
| `negativo`           | `error`              |
| `neutral`            | `regularPoint`       |

## Riesgos

1. **Pérdida de granularidad** — MatchEvent no sabe si un punto fue ataque, saque, bloqueo, etc. Todo se mapea a `TipoAccion.ataque` por defecto. La conversión inversa pierde `tipoAccion`, `zona`, `descripcion`.
2. **Valores por defecto** — `puntoLocal`, `puntoVisitante`, `esEquipoLocal`, `zona` se inicializan con valores neutros. Cualquier código que consuma StatEvent y espere estos campos poblados podría comportarse incorrectamente.
3. **Round-trip no es identidad** — Convertir MatchEvent → StatEvent → MatchEvent conserva `athleteId`, `matchId`, `setNumero`, pero `eventType` puede cambiar (e.g., `regularPoint` → `winnerPoint` al pasar por `ResultadoAccion.positivo`).
4. **Sin sincronía temporal** — Ambos `create` factories usan `DateTime.now()`, no transfieren el timestamp original.

## Compatibilidad

- **No modifica** `MatchEvent`, `StatEvent`, `MatchController`, `PartidoViewModel`, `PlayByPlayViewModel`, UI ni Firebase.
- **No importa** nada de repositorios o servicios — es pura conversión de datos.
- **No produce efectos secundarios** — funciones puras (dado un input, producen un output).

## Ejemplos de Uso

```dart
import 'package:libero360/features/partido/data/mappers/match_event_mapper.dart';

// MatchEvent → StatEvent
final stat = MatchEventMapper.toStatEvent(matchEvent);

// StatEvent → MatchEvent
final match = MatchEventMapper.toMatchEvent(statEvent);
```

## Tests

9 tests — todos pasan:

```
00:02 +9: All tests passed!
```

- 4 tests MatchEvent → StatEvent (winnerPoint, regularPoint, error, descripcion)
- 3 tests StatEvent → MatchEvent (positivo, negativo, neutral)
- 2 tests Round-trip (conservación de ids)

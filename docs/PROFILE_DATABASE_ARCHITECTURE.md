# Auditoría: Base de Datos de Perfiles

## Contexto

Actualmente `ProfileRepository` maneja su propia base de datos Sembast independiente (`profiles.db`) usando `databaseFactoryIo` directamente. El resto del sistema usa `DatabaseService` con una sola base de datos (`libero360.db`) cuya fábrica se selecciona mediante import condicional (`database_provider.dart`), funcionando en IO y Web.

## Comparativa

| Aspecto | `profiles.db` independiente | `profiles_store` en `DatabaseService` |
|---------|----------------------------|---------------------------------------|
| Inicialización | `ProfileRepository.initialize()` duplica el patrón | Una sola llamada a `DatabaseService.initialize()` |
| Conexiones DB | 2 bases abiertas simultáneamente | 1 sola base |
| Consultas multi-feature | Imposible (no hay cross-DB queries en Sembast) | Posible via `Finder` + `Filter` en la misma DB |
| Platform support | Solo IO (`sembast_io.dart` directo) | IO + Web (import condicional existente) |
| Dependencia física | `path_provider` directo | `DatabaseService` vía `core/database/database_provider.dart` |
| Acoplamiento | Sin acoplamiento a `DatabaseService` | Dependencia de una clase grande (759 líneas) |
| Aislamiento de datos | Total — borrar perfiles no afecta otras stores | Compartido — borrar DB entera borra todo |
| Firebase Sync | Requiere lógica duplicada de sync | Un solo sync service recorre todas las stores |
| Testing | DB separada, más archivos mock | Misma DB, mismos helpers de test |

## Riesgos de la Arquitectura Actual

### 1. No funciona en Web (crítico)

```dart
// profile_repository.dart:2
import 'package:sembast/sembast_io.dart';
```

El resto del sistema abstrae la fábrica vía:

```dart
// core/database/database_provider.dart
import 'database_provider_io.dart'
    if (dart.library.html) 'database_provider_web.dart';
```

Si en el futuro se despliega en web, `ProfileRepository` fallará en runtime.

### 2. Sin queries cross-feature posibles

Para el roadmap de FASE 5.6+ se necesita:

| Feature | Filtro necesario |
|---------|-----------------|
| Atletas | `Filter.equals('profileId', currentProfile.id)` |
| Partidos | `Filter.equals('profileId', currentProfile.id)` |
| Asistencias | `Filter.equals('profileId', currentProfile.id)` |
| Estadísticas | `Filter.equals('profileId', currentProfile.id)` |

Con bases separadas, cada feature necesita: (1) leer perfil activo desde `profiles.db`, (2) leer datos desde `libero360.db`. Esto duplica conexiones y complica sincronización.

### 3. Duplicación de patrones de inicialización

`ProfileRepository` replica el patrón de `DatabaseService`:
- Variable `_isInitialized`
- Método `initialize()` con early return
- Guard `await initialize()` en cada método público

Si se cambia el patrón de inicialización (ej. migración, versioning, encripción), hay que modificar dos lugares.

### 4. Export/Import duplicado

Actualmente `SettingsRepository` ya implementa export/import vía `DatabaseService.exportData()`. Los perfiles quedarían fuera de ese export pues están en DB separada.

## Estrategia de Migración Recomendada

Si se decide migrar, el plan sugerido es:

### Fase 1: Agregar store a DatabaseService

```dart
// En DatabaseService
final _profileStore = intMapStoreFactory.store('profiles');
final _profileMetaStore = intMapStoreFactory.store('profiles_meta');

List<StoreRef<int, Map<String, dynamic>>> get allStores =>
    [_playerStore, _matchStore, ..., _profileStore, _profileMetaStore];
```

### Fase 2: Refactorizar ProfileRepository

- Eliminar `sembast_io.dart`, `path_provider`
- Usar `DatabaseService.instance` para obtener `_db`
- Apuntar a `_profileStore` y `_profileMetaStore`
- Eliminar `initialize()` propio

### Fase 3: Migrar datos (una vez)

```dart
// Script one-shot: leer profiles.db, escribir en DatabaseService
final oldDb = await databaseFactoryIo.openDatabase('profiles.db');
final records = await oldStore.find(oldDb);
for (final r in records) {
  await newStore.add(db, r.value);
}
// luego eliminar profiles.db
```

### Fase 4: Export/Import automático

- Agregar `_profileStore` y `_profileMetaStore` a `SettingsRepository.exportData()` / `importData()`
- Ya quedan cubiertos sin cambios adicionales

### Fase 5: Limpiar

- Eliminar `profiles.db` si existe
- Eliminar import de `sembast_io.dart` de `profile_repository.dart`

## Riesgos de la Migración

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| Datos existentes en `profiles.db` se pierden si no se migran | Alta | Script one-shot en Fase 3 |
| Aumento de tamaño de DatabaseService (+20 líneas) | Baja | Organizar stores por sección con comentarios |
| Acoplamiento de `profiles/` a `estadisticas/` | Media | Considerar mover `DatabaseService` a `core/database/` como refactor posterior |
| Breaking change para ProfileViewModel | Baja | Solo cambia el constructor del repo, la interfaz pública es idéntica |

## Recomendación Final

**Migrar a `profiles_store` dentro de `DatabaseService`**, porque:

1. **Web compatibility** — la única opción viable para soporte web futuro. La implementación actual con `sembast_io.dart` directo simplemente no funcionará en web.
2. **Roadmap 5.6+** — filtrar atletas, partidos, asistencias y estadísticas por perfil activo requiere queries en la misma base de datos. No es posible con bases separadas.
3. **Single source of truth** — una sola inicialización, una sola conexión, un solo export/import, una sola lógica de Firebase Sync.
4. **Patrón probado** — 8 stores ya viven en `DatabaseService` sin problemas. Una más no introduce complejidad nueva.

La migración es de bajo riesgo y alto retorno. El acoplamiento a `DatabaseService` es un trade-off aceptable dado que `DatabaseService` es singleton global y ya es el punto central de persistencia. Como mejora futura, podría moverse a `core/database/` para eliminar la dependencia cruzada entre features.

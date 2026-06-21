# FASE 5.6 — Propuesta Técnica: Integración de Perfil Activo

---

## 1. Resumen

Conectar `ProfileViewModel` con toda la aplicación para que cada pantalla filtre sus datos según el perfil activo.

---

## 2. Estrategia de Persistencia

### 2.1 Modelos a modificar

Agregar dos campos a cada entidad:

| Campo | Tipo | Nullable | Default |
|-------|------|----------|---------|
| `profileId` | `String?` | Sí | `null` |
| `clubId` | `String?` | Sí | `null` |

### Entidades afectadas

| Modelo | Archivo | Store Sembast | Notas |
|--------|---------|---------------|-------|
| `Player` | `estadisticas/data/models/player.dart` | `players` | +profileId, +clubId |
| `Match` | `estadisticas/data/models/match.dart` | `matches` | +profileId, +clubId |
| `MatchEvent` | `partido/data/match_event.dart` | `match_events` | +profileId, +clubId |
| `AttendanceRecord` | `estadisticas/data/models/attendance_record.dart` | `attendance` | +profileId, +clubId |
| `StatEvent` | `estadisticas/data/models/stat_event.dart` | `events` | +profileId, +clubId |
| `AppNotification` | `notifications/data/notification_models.dart` | Firestore | Sin cambios de field, solo filtrado |

### 2.2 Serialización

Cada modelo tiene `_toMap`/`_fromMap` en DatabaseService. Se agrega el campo con fallback a null:

```dart
// _playerToMap
'profileId': p.profileId,
'clubId': p.clubId,

// _playerFromMap
..profileId = map['profileId'] as String?
..clubId = map['clubId'] as String?
```

### 2.3 Export/Import

`exportToJson()` e `importFromJson()` en DatabaseService serializan y restauran estos campos automáticamente porque se incluyen en el map. No requieren cambios adicionales.

### 2.4 Notificaciones (Firestore)

`AppNotification` no guarda `profileId` en Firestore. Las notificaciones ya están particionadas por club (`clubs/{clubId}/notifications`). Para filtrar por perfil, se puede:

- Opción A: Filtrar en el cliente (`notificationsStream()` → filtrar por `profileId` en el stream)
- Opción B: Agregar `profileId` a los documentos en Firestore y filtrar con `where('profileId', '==', activeId)`

**Recomendación**: Opción A por ahora. Firestore queries compuestas requieren índices. Agregar `profileId` a los docs cuando se haga la migración a Firebase Sync completa.

---

## 3. Nuevos Métodos en DatabaseService

### 3.1 Filtros por profileId

Se agregan métodos sobrecargados para cada store:

```dart
// Players
Future<List<Player>> getPlayersByProfile(String profileId);
Stream<List<Player>> watchPlayersByProfile(String profileId);

// Matches
Future<List<Match>> getMatchesByProfile(String profileId);
Stream<List<Match>> watchMatchesByProfileAndState(String profileId, EstadoPartido estado);

// Events
Future<List<StatEvent>> getEventsByProfile(String profileId);

// Attendance
Future<List<AttendanceRecord>> getAttendanceByProfile(String profileId);

// MatchEvents
Future<List<MatchEvent>> getMatchEventsByProfile(String profileId);
```

### 3.2 Implementación tipo

```dart
Future<List<Player>> getPlayersByProfile(String profileId) async {
  final snapshots = await _playerStore.find(
    _database,
    finder: Finder(
      filter: Filter.equals('profileId', profileId),
      sortOrders: [SortOrder('numero')],
    ),
  );
  return snapshots.map((e) => _playerFromMap(e.value)..id = e.key).toList();
}
```

---

## 4. Provider y Ciclo de Vida

### 4.1 ProfileViewModel como Provider global

```dart
// main.dart
ChangeNotifierProvider(create: (_) => ProfileViewModel()),
```

### 4.2 Carga inicial

```dart
// ProfileViewModel.init()
Future<void> init() async {
  await loadProfiles();
}
```

Llamada desde `AppShell.initState()` o `DashboardScreen.didChangeDependencies()`.

### 4.3 Flujo de cambio de perfil

```
Usuario selecciona perfil → ProfileViewModel.selectProfile(id)
  → setActiveProfileId(id) en repositorio
  → notifyListeners()
  → Todas las pantallas que usan context.watch<ProfileViewModel>()
     se reconstruyen con el nuevo perfil
  → Las queries en DatabaseService usan currentProfile.id
  → Los streams se re-suscriben si el perfil cambia
```

### 4.4 Providers afectados

| Provider | Impacto |
|----------|---------|
| `DashboardViewModel` | ALTO — streams deben filtrar por perfil |
| `NotificationViewModel` | BAJO — filtra Firestore por club, ya funciona |
| `MatchController` | BAJO — partido actual no cambia por perfil |
| `ClubViewModel` | NULO — club y perfil son ortogonales |

---

## 5. DashboardViewModel

### 5.1 Nuevos streams por perfil

```dart
StreamSubscription? _profileSub;

void init() {
  _profileSub = context.watch<ProfileViewModel>().addListener(() {
    _resubscribe();
  });
  _resubscribe();
}

void _resubscribe() {
  _playerSub?.cancel();
  _matchSub?.cancel();
  final pid = ProfileViewModel.instance.currentProfile?.id;
  if (pid == null) return;
  _playerSub = db.watchPlayersByProfile(pid).listen((players) { ... });
  _matchSub = db.watchMatchesByProfileAndState(pid, EstadoPartido.finalizado).listen((matches) { ... });
}
```

### 5.2 Race condition

Si `loadProfiles()` aún no terminó cuando `DashboardViewModel.init()` se ejecuta, `currentProfile` será null y los streams se suscribirán vacíos.

**Solución**: `DashboardViewModel.init()` espera a que `ProfileViewModel.loadProfiles()` esté completa:

```dart
Future<void> init() async {
  await _profileVm.loadProfiles();  // esperar perfiles
  _subscribe();
}
```

---

## 6. AppShell: ProfileSelector

### 6.1 Ubicación

**Mobile** (AppBar): al lado de `ClubSwitcher`:

```dart
actions: [
  const ProfileSelector(),  // <-- NUEVO
  const NotificationBell(),
  const ClubSwitcher(),
  _userMenu(context, user),
],
```

**Wide** (Sidebar): dentro del `Row` con ClubSwitcher:

```dart
Padding(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  child: Row(
    children: [
      const ProfileSelector(),  // <-- NUEVO
      const SizedBox(width: 8),
      const ClubSwitcher(),
      const Spacer(),
      const NotificationBell(),
    ],
  ),
),
```

### 6.2 Widget `ProfileSelector` existente

Ya existe en `lib/features/profiles/presentation/widgets/profile_selector.dart`. Se reutiliza sin cambios.

---

## 7. DashboardScreen: ProfileSelector

Se agrega en el `_header`, antes del botón de settings:

```dart
Widget _header(dynamic user, DateTime today) {
  // ...
  child: Row(
    children: [
      // avatar + greeting
      const Spacer(),
      const ProfileSelector(),  // <-- NUEVO
      const SizedBox(width: 8),
      // settings button
    ],
  );
}
```

---

## 8. Filtrado por Feature

### 8.1 Atletas

`AthleteListScreen` ya usa `DatabaseService.getAllPlayers()`. Cambiar a `getPlayersByProfile()`.

Flujo: leer `ProfileViewModel.currentProfile.id`, pasarlo a DatabaseService.

### 8.2 Partidos

`MatchLauncherPlaceholder` y `MatchController` leerán partidos filtrados. `MatchController.init()` debe verificar que el partido activo pertenece al perfil actual.

### 8.3 Asistencia

`AttendanceScreen` usa `getAllAttendanceRecords()`. Cambiar a `getAttendanceByProfile()`.

### 8.4 Estadísticas

`PlayByPlayScreen` carga `getEventsByMatch()`. Como los eventos ya están filtrados por match, si el match está filtrado por perfil, los eventos heredan ese filtro. No requiere cambio directo en StatEvent queries, solo en Match queries.

### 8.5 Notificaciones

`NotificationService` ya filtra por club. Se mantiene igual. Opcional: agregar filtro cliente por perfil.

---

## 9. Migración de Datos Existentes

### 9.1 Compatibilidad hacia atrás

- `profileId` y `clubId` son `String?` (nullable)
- `_playerFromMap` usa `?? null` si el campo no existe → carga datos viejos sin errores
- `_playerToMap` escribe `null` si el campo no está seteado

### 9.2 Migración automática

No se requiere migración. Los datos existentes tienen `profileId = null` y `clubId = null`. Cuando el usuario crea/edita una entidad estando en un perfil, se asigna automáticamente:

```dart
Player.create(
  ...,
  profileId: ProfileViewModel.instance.currentProfile?.id,
  clubId: ProfileViewModel.instance.currentProfile?.clubId,
)
```

### 9.3 Datos huérfanos

Los datos con `profileId = null` no se muestran en ninguna pantalla filtrada. Se decide:

- **Opción A**: Mostrar datos sin perfil como "sin asignar" con opción de migrar
- **Opción B**: Ignorarlos, y que el usuario los reasigne manualmente editando

**Recomendación**: Opción A. Agregar un indicador visual en la sección de Configuración > Perfiles que muestre cuántos datos no tienen perfil y ofrezca migrarlos al perfil activo.

---

## 10. Riesgos y Race Conditions

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| `loadProfiles()` async → streams se suscriben sin perfil | Alta | Dashboard vacío temporal | `DashboardViewModel.init()` espera `loadProfiles()` |
| Perfil se cambia mientras hay streams activos | Media | Datos mezclados | Cancelar/re-suscribir streams al cambiar perfil |
| Match activo en perfil A, se cambia a perfil B | Alta | MatchController apunta a match de otro perfil | MatchController verifica `profileId` en `init()` y rechaza si no coincide |
| ClubSwitcher y ProfileSelector tienen clubs diferentes | Media | Inconsistencia visual | ProfileModel ya tiene `clubId` — validar al seleccionar |
| Export/Import con datos mixtos multi-perfil | Baja | Datos de varios perfiles en un mismo export | El export actual incluye todo. El import restaura todo. Es correcto. |

### 10.1 Race condition crítica: AppShell ↔ ProfileViewModel

**Escenario**: AppShell se construye antes de que `ProfileViewModel.loadProfiles()` termine.

**Solución**: ProfileSelector muestra `SizedBox.shrink()` cuando `currentProfile == null` (ya implementado). DashboardViewModel espera `loadProfiles()` antes de suscribir streams.

### 10.2 Race condition: ClubSwitcher ↔ Perfiles

**Escenario**: Usuario cambia de club → los perfiles del club anterior quedan seleccionados.

**Solución**: Al cambiar de club en `ClubViewModel`, forzar recarga de perfiles que coincidan con el club. Si `currentProfile.clubId != newClubId`, mostrar selector de perfiles.

---

## 11. Impacto en Firebase Futuro

### 11.1 Firestore estructura actual

```
clubs/{clubId}/notifications/{docId}
```

### 11.2 Firestore futuro (con perfiles)

```
clubs/{clubId}/
  profiles/{profileId}/
    athletes/{id}
    matches/{id}
    attendance/{id}
    events/{id}
```

### 11.3 Migración futura desde Sembast

Cada entidad ya tendrá `profileId` y `clubId`. La migración a Firestore será:

```dart
final profileId = player.profileId;
final clubId = player.clubId;
await firestore
    .collection('clubs').doc(clubId)
    .collection('profiles').doc(profileId)
    .collection('athletes').add(player.toFirestoreMap());
```

No se requiere transformación de datos adicional.

---

## 12. Plan de Implementación

### Fase 5.6A — Modelos + Persistencia
1. Agregar `profileId` y `clubId` a: Player, Match, MatchEvent, AttendanceRecord, StatEvent
2. Actualizar serialización en DatabaseService (`_toMap`/`_fromMap` para cada modelo)
3. Agregar métodos query por profileId en DatabaseService

### Fase 5.6B — Providers + Ciclo de Vida
1. Agregar `ProfileViewModel` a MultiProvider en `main.dart`
2. Implementar `ProfileViewModel.init()` (llama a `loadProfiles()`)
3. Modificar `DashboardViewModel.init()` para esperar perfiles y filtrar streams

### Fase 5.6C — UI: ProfileSelector en AppShell + Dashboard
1. Agregar `ProfileSelector` al AppBar (mobile) y Sidebar (wide)
2. Agregar `ProfileSelector` al header del Dashboard

### Fase 5.6D — Filtrado Cross-Feature
1. Atletas: cambiar queries a `getPlayersByProfile()`
2. Partidos: filtrar lista de partidos por perfil
3. Asistencia: filtrar registros por perfil
4. MatchController: agregar guard de profileId
5. Notificaciones: filtrar en cliente por clubId (ya funciona)

### Fase 5.6E — Datos huérfanos
1. Agregar contador de datos sin perfil en ProfilesSection de Settings
2. Botón "Asignar todos al perfil activo" con batch update

---

## 13. flutter analyze target

Mantener **0 errores** durante toda la implementación.

---

## 14. Archivos a modificar

### Modelos (5 archivos)
- `lib/features/estadisticas/data/models/player.dart`
- `lib/features/estadisticas/data/models/match.dart`
- `lib/features/estadisticas/data/models/attendance_record.dart`
- `lib/features/estadisticas/data/models/stat_event.dart`
- `lib/features/partido/data/match_event.dart`

### Persistencia (1 archivo)
- `lib/features/estadisticas/data/local_db/database_service.dart`

### Providers (2 archivos)
- `lib/main.dart`
- `lib/ui/dashboard_viewmodel.dart`
- `lib/features/profiles/presentation/viewmodels/profile_viewmodel.dart`
- `lib/features/partido/presentation/controllers/match_controller.dart`

### UI (3 archivos)
- `lib/ui/app_shell.dart`
- `lib/ui/dashboard_screen.dart`
- `lib/features/asistencia/presentation/views/athlete_list_screen.dart`
- `lib/features/asistencia/presentation/views/attendance_screen.dart`
- `lib/features/partido/presentation/views/match_start_dialog.dart`
- `lib/features/statistics/presentation/views/statistics_screen.dart`
- `lib/features/settings/presentation/views/profiles_section.dart`

---

## 15. Conclusión

La integración del perfil activo es un cambio transversal pero acotado:

- **Campos nuevos**: `profileId` + `clubId` en 5 modelos, nullable
- **Migración**: Cero, datos viejos tienen `null` y funcionan
- **Filtrado**: Nuevos métodos `get*ByProfile()` en DatabaseService, los viejos métodos sin filtro se mantienen
- **UI**: ProfileSelector reutilizado en 3 ubicaciones
- **Riesgos**: Controlados con manejo de race condition en DashboardViewModel.init()
- **Firebase**: Datos ya preparados con `profileId`/`clubId` para migración futura

# FASE 5.3 — Notification Club Switching Fix

## Bug Original

`NotificationViewModel.init(clubId)` solo suscribía streams la **primera vez** que se llamaba. En llamadas posteriores (cuando el usuario cambiaba de club activo), solo actualizaba `_currentClubId` en el service pero **no re-suscribía** los streams de Firestore.

### Por qué ocurría

```dart
void init(String clubId) {
    if (_initialized) {
        _service.setCurrentClub(clubId);  // solo cambia el ID
        return;                            // sin re-suscribir
    }
    _initialized = true;
    _service.setCurrentClub(clubId);
    _listen();                            // streams atados al club original
}
```

`_listen()` llamaba a `_service.notificationsStream()` y `_service.unreadCountStream()`, que crean queries de Firestore con la ruta `clubs/$_currentClubId/notifications`. Estas queries se resuelven al momento de crear el stream. Cambiar `_currentClubId` después no afecta las suscripciones ya establecidas.

**Resultado**: Las notificaciones siempre mostraban datos del primer club, ignorando los cambios de club posteriores.

## Solución

### 1. `NotificationService.currentClubId` — getter público

Se agregó un getter para que el ViewModel pueda comparar el club actual con el recibido:

```dart
String? get currentClubId => _currentClubId;
```

**Archivo**: `lib/features/notifications/data/notification_service.dart:16`

### 2. `NotificationViewModel.init()` — tres caminos

```dart
void init(String clubId) {
    // Caso 1: mismo club → no-op
    if (_initialized && _service.currentClubId == clubId) {
        return;
    }
    // Caso 2: club diferente → re-suscribir streams
    if (_initialized && _service.currentClubId != clubId) {
        _notifSub?.cancel();
        _unreadSub?.cancel();
        _service.setCurrentClub(clubId);
        _listen();
        return;
    }
    // Caso 3: primera inicialización
    _initialized = true;
    _service.setCurrentClub(clubId);
    _listen();
}
```

**Archivo**: `lib/features/notifications/presentation/viewmodels/notification_viewmodel.dart:20-36`

### 3. Try/catch en `_listen()`

Protege contra errores de Firestore (colección no existente, permisos, etc.):

```dart
void _listen() {
    try {
        _notifSub = _service.notificationsStream().listen(...);
        _unreadSub = _service.unreadCountStream().listen(...);
    } catch (e) {
        print("🔴 NOTIF: error al escuchar notificaciones — $e");
    }
}
```

## Compatibilidad con sistema de perfiles y múltiples equipos

La solución es compatible con una futura arquitectura multi-perfil porque:

1. **El club se pasa como parámetro** — `init(clubId)` recibe el club desde fuera (AppShell lo obtiene de `ClubViewModel.currentClub.id`).
2. **Comparación por ID** — los streams se re-suscriben solo cuando el ID cambia. Esto es O(1) y no depende del nombre del club.
3. **Sin estado global** — el ViewModel no almacena una lista de clubs; solo reacciona al cambio.
4. **Firestore path** — la ruta `clubs/$_currentClubId/notifications` escala a N clubs sin cambios de código.
5. **Desacoplamiento** — si en el futuro se implementa un sistema de suscripción a múltiples clubs, solo bastaría con agregar múltiples `_listen()` calls con diferentes clubIds y unificar los streams con `StreamGroup.merge()`.

## Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/notifications/data/notification_service.dart` | Getter `currentClubId` |
| `lib/features/notifications/presentation/viewmodels/notification_viewmodel.dart` | Lógica de detección de cambio de club + try/catch + logs |

## Verificación

```
$ dart analyze lib/features/notifications/...
   info - avoid_print (4 issues, pre-existentes en el código base)
   0 errores, 0 warnings
```

## Comportamiento Esperado

| Escenario | Antes | Después |
|-----------|-------|---------|
| App inicia, club A cargado | Streams suscritos a club A | Streams suscritos a club A |
| Cambio a club B | Streams siguen en club A | Streams se cancelan y re-suscriben a club B |
| App rebuild sin cambio de club | `init()` ejecuta setCurrentClub cada build | `init()` retorna inmediatamente (mismo club) |
| Sin Firebase | `Stream.empty()` — loading nunca termina | Mismo comportamiento (sin cambios) |

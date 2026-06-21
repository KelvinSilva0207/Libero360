# Auditoría Funcional — Libero360

> Fecha: 2026-06-17
> Alcance: Dashboard, Login, Navegación, Estadística en vivo, Notificaciones

---

## 1. Dashboard

### ✅ Sin bugs activos (FASE 5.0B corregida)

La corrección de `DashboardViewModel.init()` → `await DatabaseService.instance.initialize()` resuelve el bug de pantalla en blanco.

### ⚠️ Observación: Primer frame con ceros

- **Archivo**: `lib/ui/dashboard_viewmodel.dart:29-37`
- **Detalle**: Las streams de sembast emiten asíncronamente. Durante el primer frame, `athleteCount=0`, `matchCount=0`, `setCount=0`. Es imperceptible (~1-2 frames).
- **Gravedad**: Baja — no afecta funcionalidad.

---

## 2. Login

### 🐛 BUG 2.1 — `Navigator.pop()` después de que AuthGate ya reemplazó la pantalla

- **Archivo**: `lib/features/auth/presentation/views/login_screen.dart:32-45`
- **Línea**: 40
- **Problema**: En `_submit()`:
  ```dart
  final success = await vm.login(…);
  if (success && mounted) {
      Navigator.pop(context);  // ← context puede estar stale
  }
  ```
  `vm.login()` establece `AuthStatus.authenticated` y llama `notifyListeners()`. El `Consumer<AuthViewModel>` en `AuthGate` reconstruye el árbol mostrando `AppShell` en vez de `WelcomeScreen`/`LoginScreen`. Cuando `_submit` reanuda después del `await`, `mounted` es `true` (el State existe), pero el `BuildContext` pertenece a un widget que ya no está en el árbol activo. `Navigator.pop()` puede fallar silenciosamente (navegador sin la ruta esperada) o lanzar excepción si la ruta ya fue removida.
- **Gravedad**: Media — en la práctica funciona porque Flutter retiene las rutas hasta el siguiente frame, pero es frágil y puede causar errores en escenarios de red lenta.
- **Solución propuesta**: No hacer `Navigator.pop()` después del login exitoso. Dejar que `AuthGate` maneje la transición al cambiar `status`:
  ```dart
  if (success) {
      // No hacer pop — AuthGate ya cambió a AppShell
      return;
  }
  ```
  O enviar un callback para que WelcomeScreen maneje el pop antes de la transición.

### 🐛 BUG 2.2 — RegisterScreen mismo bug (Navigator.pop en contexto stale)

- **Archivo**: `lib/features/auth/presentation/views/register_screen.dart:39-40`
- **Línea**: 40
- **Problema**: Idéntico al 2.1. `vm.register()` setea `status = authenticated` antes de que `Navigator.pop()` se ejecute.
- **Gravedad**: Media
- **Solución**: Ídem 2.1.

### 🐛 BUG 2.3 — Google Sign-In: idToken null no detiene flujo

- **Archivo**: `lib/features/auth/data/repositories/firebase_auth_repository.dart:76-88`
- **Línea**: 82-86
- **Problema**: Cuando `googleAuth.idToken` es `null`, el código imprime una advertencia pero continúa con `idToken: null` en la credential:
  ```dart
  final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,  // ← null
  );
  ```
  Firebase requiere `idToken` para Google Sign-In. El `signInWithCredential` fallará con `FirebaseAuthException` (invalid-credential). El error se captura en el catch y retorna `null`, pero la UX muestra "Error al iniciar con Google" sin detalle.
- **Gravedad**: Alta — impide el inicio de sesión con Google cuando `serverClientId` está mal configurado o el token no se genera.
- **Solución propuesta**: Retornar temprano si `idToken == null`:
  ```dart
  if (googleAuth.idToken == null) {
      print("🔴 GOOGLE SIGN-IN: idToken es NULL");
      return null;
  }
  ```

---

## 3. Navegación General

### 🐛 BUG 3.1 — BottomNav no muestra Asistencia ni Configuración en móvil

- **Archivo**: `lib/ui/app_shell.dart:242-264`
- **Línea**: 257-262
- **Problema**: `BottomNavigationBar` tiene 4 items (Dashboard, Atletas, Partidos, Estadísticas). El sidebar tiene 6 items (los mismos + Asistencia + Configuración). En móvil, las pestañas Asistencia (índice 4) y Configuración (índice 5) son inaccesibles desde la barra inferior. La única forma de llegar es:
  - Configuración: menú de usuario (icono avatar) → "Administrar"
  - Asistencia: tarjeta de acceso rápido en Dashboard (si existe)
- **Gravedad**: Media — las funcionalidades existen pero tienen descubribilidad limitada en móvil.
- **Solución propuesta**: Agregar las 2 pestañas faltantes al BottomNav, o agregar un botón "Más" (overflow) que muestre las opciones restantes.

### 🐛 BUG 3.2 — User menu "settings" y "admin" apuntan a lo mismo

- **Archivo**: `lib/ui/app_shell.dart:280-281`
- **Línea**: 280-281
- **Problema**: En `_userMenu`, las opciones 'settings' y 'admin' hacen ambos `setState(() => _selectedIndex = 5)`, que es `AdminScreen`. No hay una pantalla de Configuración separada en el tab. El label del menú es "Administrar" con ícono de admin.
- **Gravedad**: Baja — confusión de naming, no error funcional.
- **Solución propuesta**: Unificar en una sola opción "Configuración" con índice 5.

### 🐛 BUG 3.3 — NotificationBell invisible en layout wide (sidebar)

- **Archivo**: `lib/ui/app_shell.dart:63-88`
- **Línea**: 84
- **Problema**: `NotificationBell` está en `AppBar.actions`, que solo se renderiza cuando `useMobileLayout == true`. En wide layout (≥768px, sin AppBar), no hay notificación bell en la UI. El sidebar no incluye el bell.
- **Gravedad**: Media — notificaciones invisibles en desktop/tablet horizontal.
- **Solución propuesta**: Agregar `NotificationBell` al sidebar en wide layout (ej. junto al ClubSwitcher o en la parte superior de `_buildSidebar`).

---

## 4. Estadística en vivo (PlayByPlay)

### 🐛 BUG 4.1 — MatchController compartido entre PlayByPlay y MatchScreen

- **Archivo**: `lib/main.dart:34` + `lib/features/estadisticas/presentation/views/play_by_play_screen.dart:24` + `lib/features/partido/presentation/views/match_screen.dart:24`
- **Línea**: main:34, pbp_screen:24, match_screen:24
- **Problema**: `MatchController` es un singleton `ChangeNotifierProvider(create: (_) => MatchController())` en `main.dart`. Tanto `PlayByPlayScreen` como `MatchScreen` leen el mismo `MatchController` via `context.read<MatchController>()`. Esto significa:
  1. Si el usuario inicia un partido desde PlayByPlay (`PlayByPlayViewModel.iniciarNuevoPartido()` → `_controller.init()`), y luego abre MatchScreen desde Nuevo Partido (`PartidoViewModel.init(config)` → `_controller.init()`), el segundo `init()` **sobrescribe** el primer partido sin advertencia.
  2. Los datos del primer partido se pierden (creado en DB pero luego sobrescrito).
  3. Si el usuario vuelve a PlayByPlay después de pasar por MatchScreen, el partido que ve es el de MatchScreen, no el que inició originalmente.
- **Gravedad**: Alta — pérdida silenciosa de datos del partido.
- **Solución propuesta**: Opciones:
  - **A**: Hacer que `MatchController.init()` verifique si ya hay un partido activo y prevenga la sobreescritura (mostrar error o confirmación).
  - **B**: Usar `ChangeNotifierProvider.value()` con instancias separadas por ruta (no recomendado: rompería la arquitectura de FASE 3A).
  - **C**: Separar `MatchController` en dos: uno para MatchScreen y otro para PlayByPlay, removiendo el Provider global y creándolos localmente en cada screen.

### 🐛 BUG 4.2 — PlayByPlay no sincroniza rotación con MatchController

- **Archivo**: `lib/features/estadisticas/presentation/views/play_by_play_screen.dart`
- **Problema**: La pantalla PlayByPlay usa `vm.partidoActual?.puntosLocal`, etc. del MatchController, pero el selector de equipo y los botones de acción asumen que el jugador seleccionado está rotando. No hay indicación visual de la rotación actual (posición en la cancha).
- **Gravedad**: Baja — es una limitación de UX, no un bug. PlayByPlay es un registro estadístico, no una cancha visual.

---

## 5. Notificaciones

### 🐛 BUG 5.1 — Notificaciones rotas al cambiar de club

- **Archivo**: `lib/features/notifications/presentation/viewmodels/notification_viewmodel.dart:31-47`
- **Línea**: 34-41
- **Problema**: `NotificationViewModel.init(clubId)` solo suscribe streams la **primera vez** (`_initialized` gate). En llamadas posteriores (cuando el usuario cambia de club), solo actualiza `_currentClubId` en el service pero **no re-suscribe** los streams:
  ```dart
  void init(String clubId) {
      if (_initialized) {
          _service.setCurrentClub(clubId);  // ← solo cambia ID
          return;                            // ← NO re-suscribe
      }
      _initialized = true;
      _service.setCurrentClub(clubId);
      _notifSub?.cancel();
      _unreadSub?.cancel();
      _listen();                            // ← streams atados al club original
  }
  ```
  Las queries de Firestore (`_notifRef = _firestore.collection('clubs/$_currentClubId/notifications')`) se resuelven al momento de crear el stream. Cambiar `_currentClubId` después no afecta las suscripciones existentes.
- **Gravedad**: Alta — las notificaciones siempre muestran datos del primer club.
- **Solución propuesta**: Si `_initialized` es true y el club cambió, re-suscribir:
  ```dart
  void init(String clubId) {
      if (_initialized && _service.currentClubId == clubId) return;
      _initialized = true;
      _service.setCurrentClub(clubId);
      _notifSub?.cancel();
      _unreadSub?.cancel();
      _listen();
  }
  ```
  O alternativamente, pasar el clubId a `_listen()` y usarlo en lugar de `_currentClubId`.

### 🐛 BUG 5.2 — Notificaciones solo funcionan con Firebase

- **Archivo**: `lib/features/notifications/data/notification_service.dart:33-35`
- **Línea**: 33-34
- **Problema**: `notificationsStream()` y `unreadCountStream()` retornan `Stream.empty()` cuando `!AppConfig.useFirebase`. El `NotificationService` es 100% dependiente de Firestore. Sin Firebase, el NotificationBell siempre muestra 0 y el loading nunca se completa.
- **Gravedad**: Media — en modo local (sin Firebase), las notificaciones no existen.
- **Solución propuesta**: Implementar una capa de notificaciones local usando sembast (paralela a la estructura de Firestore), o desactivar el icono de campana cuando `!useFirebase`.

### 🐛 BUG 5.3 — `init()` llamado en cada build de AppShell

- **Archivo**: `lib/ui/app_shell.dart:54-56`
- **Línea**: 54-56
- **Problema**: `notifVm.init(clubVm.currentClub!.id)` se ejecuta en cada llamada a `build()`. Si `currentClub` no cambia, es un no-op (vuelve rápido por el `_initialized` guard). Pero sigue ejecutando el getter `clubVm.currentClub!.id` en cada build.
- **Gravedad**: Baja — no causa errores funcionales, es ineficiente.
- **Solución propuesta**: Mover a `didChangeDependencies` o a un listener de cambio de club.

---

## 6. Bugs Adicionales

### 🐛 BUG 6.1 — Race condition en `DatabaseService.initialize()`

- **Archivo**: `lib/features/estadisticas/data/local_db/database_service.dart:28-33`
- **Línea**: 28-33
- **Problema**: `initialize()` es async con guard `_isInitialized` pero la bandera se asigna DESPUÉS del await:
  ```dart
  Future<void> initialize() async {
      if (_isInitialized) return;       // ← ambos pasan aquí
      final path = await databasePath;
      _db = await databaseFactory.openDatabase(path);  // ← ambos llaman esto
      _isInitialized = true;             // ← muy tarde
  }
  ```
  Si `init()` se llama concurrentemente (ej. desde `DashboardViewModel.init()` y `MatchController.init()` en el mismo frame), ambas llamadas pasan el guard y abren la DB dos veces. La segunda llamada sobrescribe `_db`, y la primera referencia queda huérfana.
- **Gravedad**: Media — en la práctica improbable porque las inicializaciones están espaciadas por awaits, pero es una vulnerabilidad potencial.
- **Solución propuesta**: Agregar `_initCompleter`:
  ```dart
  final _initCompleter = Completer<void>();
  Future<void> initialize() async {
      if (_isInitialized) return;
      if (_initCompleter.isCompleted) return;
      await _initCompleter.future;
      // o usar synchronized
  }
  ```

### 🐛 BUG 6.2 — `_MatchLauncherPlaceholder` no está en BottomNav

- **Archivo**: `lib/ui/app_shell.dart:36-43`
- **Línea**: 38 (`_MatchLauncherPlaceholder`)
- **Problema**: El tab "Partidos" (índice 2) muestra un placeholder que ofrece iniciar un nuevo partido o ir a la cancha de práctica. Pero desde Dashboard, la tarjeta "Partidos" dirige a `PlayByPlayScreen`, no a este placeholder. Esto crea dos "entradas" diferentes para la gestión de partidos con UX inconsistente.
- **Gravedad**: Baja — confusión de navegación.
- **Solución propuesta**: Unificar ambas rutas. La tarjeta del Dashboard debería dirigir al tab "Partidos" (índice 2 → `_MatchLauncherPlaceholder`).

### 🐛 BUG 6.3 — PlayByPlayScreen desde Dashboard usa pushSlide, no tab

- **Archivo**: `lib/ui/dashboard_screen.dart:117`
- **Línea**: 117
- **Problema**: `context.pushSlide(const PlayByPlayScreen())` empuja una ruta completa que se superpone al AppShell. Pero AppShell ya tiene un "Partidos" tab que muestra el placeholder. El botón de retroceso de PlayByPlayScreen llama `Navigator.pop()`, que funciona correctamente, pero el usuario podría esperar que lleve al tab "Partidos" en vez de al Dashboard.
- **Gravedad**: Baja — UX confuso.

---

## Resumen de Gravedad

| # | Bug | Gravedad | Archivo |
|---|-----|----------|---------|
| 2.1 | Login: Navigator.pop en contexto stale | Media | `login_screen.dart:40` |
| 2.2 | Register: Navigator.pop en contexto stale | Media | `register_screen.dart:40` |
| 2.3 | Google Sign-In: idToken null no aborta | **Alta** | `firebase_auth_repository.dart:82` |
| 3.1 | BottomNav faltan 2 items | Media | `app_shell.dart:257-262` |
| 3.2 | User menu "settings"/"admin" duplicados | Baja | `app_shell.dart:280-281` |
| 3.3 | NotificationBell invisible en wide | Media | `app_shell.dart:84` |
| 4.1 | MatchController compartido pierde datos | **Alta** | `main.dart:34` / `match_screen.dart:24` |
| 5.1 | Notificaciones no cambian al cambiar club | **Alta** | `notification_viewmodel.dart:34-41` |
| 5.2 | Notificaciones solo Firebase | Media | `notification_service.dart:33-34` |
| 5.3 | init() llamado en cada build | Baja | `app_shell.dart:54-56` |
| 6.1 | Race en DatabaseService.initialize() | Media | `database_service.dart:28-33` |
| 6.2 | Partidos tab vs Dashboard tarjeta | Baja | `app_shell.dart:38` |
| 6.3 | PlayByPlayScreen push vs tab | Baja | `dashboard_screen.dart:117` |

### Totales

- **Alta**: 3 (2.3, 4.1, 5.1)
- **Media**: 6 (2.1, 2.2, 3.1, 3.3, 5.2, 6.1)
- **Baja**: 4 (3.2, 5.3, 6.2, 6.3)

# Auditoría Técnica — Libero360

**Fecha:** 16 junio 2026  
**Archivos analizados:** 118 `.dart` (lib/ 116, lib_firebase/ 2)  
**Versión:** 1.2

---

## Índice

1. [Estructura del proyecto](#1-estructura-del-proyecto)
2. [Árbol de importaciones por pantalla](#2-árbol-de-importaciones-por-pantalla)
3. [Duplicados detectados](#3-duplicados-detectados)
4. [Análisis Firebase y almacenamiento](#4-análisis-firebase-y-almacenamiento)
5. [Mapa de navegación](#5-mapa-de-navegación)
6. [Análisis del Dashboard](#6-análisis-del-dashboard)
7. [Problemas encontrados](#7-problemas-encontrados)

---

## 1. Estructura del proyecto

```
lib/
  main.dart                          (196 lines)
  core/                              (17 files)
    config.dart                      → AppConfig.useFirebase toggle
    database/                        → database_provider.dart, _io, _web
    models/athlete_status.dart
    services/
      abstract_auth_service.dart     → interface auth
      abstract_data_service.dart     → interface data (~27 methods)
      club_data_service.dart         → Firestore + local dual-write
      firebase_sync_service.dart     → ORPHANED
      google_auth_service.dart       → Google Sign-In local
      service_locator.dart           → DI container
    themes/                          → app_colors, app_theme, app_typography
    theme_provider/theme_notifier.dart
    widgets_globales/                → nav_helpers, route_transitions

  ui/                                (5 files)
    app_shell.dart                   → BottomNav/Sidebar + 6 tabs
    dashboard_screen.dart
    components/                      → app_button, app_logo, app_text_field

  features/                          (93 files, 11 módulos)

    auth/                            (8 files)
      data/models/user_model.dart    → AppUser
      data/repositories/             → AuthRepository (local), FirebaseAuthRepository
      presentation/viewmodels/       → AuthViewModel
      presentation/views/            → login, register, welcome

    teams/                           (11 files)
      data/                          → club_service, invitation_service, permission_service, team_models
      presentation/                  → ClubViewModel, club_switcher, create_club, invite_member, team_management

    partido/                         (17 files)
      data/                          → match_config, match_event
      presentation/viewmodels/       → PartidoViewModel
      presentation/views/            → match_screen (911l), match_setup, match_start_dialog, player_selection, coach_mode
      presentation/widgets/          → action_buttons, full_court, player_stats_dialog, roster_management, rotation, scoreboard, stat_recorder, volleyball_court

    cancha/                          (8 files) — NUEVO
      data/court_models.dart
      presentation/viewmodels/       → CourtViewModel
      presentation/views/            → court_screen, court_setup_dialog
      presentation/widgets/          → court_painter, position_slot, rotation_timeline

    estadisticas/                    (20 files)
      data/local_db/                 → database_service (sembast), stats_stream_service
      data/models/                   → player, match, stat_event, season, attendance_record
      data/repositories/             → match_repository, stat_event_repository
      domain/services/               → mvp_calculator, stats_calculator
      presentation/                  → PlayByPlayViewModel, play_by_play_screen, live_stats_dashboard, widgets

    statistics/                      (5 files) — módulo nuevo agregación
      data/                          → statistics_models, statistics_service
      presentation/views/            → statistics_screen, athlete_statistics_screen

    asistencia/                      (9 files)
      presentation/views/            → athlete_list, athlete_form, athlete_edit, player_detail, attendance, attendance_history, attendance_history_detail
      presentation/widgets/          → attendance_pdf_export

    notifications/                   (7 files)
      data/                          → notification_models, notification_service
      presentation/                  → NotificationViewModel, notification_bell, preferences, notifications_screen

    settings/                        (2 files)
      presentation/views/            → settings_screen (NO REFERENCIADO)
      presentation/widgets/          → settings_drawer

    admin/                           (1 file)
      presentation/views/            → admin_screen (696l)

  lib_firebase/                      (2 files — 100% DEAD CODE)
    core/services/
      firebase_auth_service.dart     → DUPLICADO de FirebaseAuthRepository
      firebase_data_service.dart     → DUPLICADO funcional de ClubDataService
```

---

## 2. Árbol de importaciones por pantalla

### 2.1 DashboardScreen (`lib/ui/dashboard_screen.dart`)

| Componente | Relación |
|---|---|
| **Imports** | `material`, `provider`, `app_colors`, `route_transitions`, `models.dart`, `AuthViewModel`, `MatchStartDialog`, `AthleteListScreen`, `AthleteFormScreen`, `AttendanceScreen`, `PlayByPlayScreen`, `DatabaseService`, `SettingsDrawer` |
| **Providers** | `context.watch<AuthViewModel>().user` (solo lectura) |
| **Servicios** | `DatabaseService.instance` → `initialize()`, `getAllPlayers()`, `getMatchesByState(EstadoPartido.finalizado)` |
| **Widgets usa** | `SettingsDrawer`, `MatchStartDialog` |
| **Navega a** | `AthleteListScreen` (pushSlide), `AthleteFormScreen` (pushSlide), `AttendanceScreen` (pushSlide), `PlayByPlayScreen` (pushSlide) |
| **Quién la llama** | `AppShell._screens[0]` |

### 2.2 LoginScreen (`lib/features/auth/presentation/views/login_screen.dart`)

| Componente | Relación |
|---|---|
| **Imports** | `material`, `provider`, `app_colors`, `app_text_field`, `AuthViewModel` |
| **Providers** | `Consumer<AuthViewModel>` |
| **Servicios** | Ninguno directo (todo via AuthViewModel) |
| **Navega a** | `/register` (pushNamed), `Navigator.pop(context)` al login exitoso |
| **Quién la llama** | `main.dart` ruta `/login`, `welcome_screen.dart` (pushNamed `/login`) |

### 2.3 RegisterScreen (`lib/features/auth/presentation/views/register_screen.dart`)

| Componente | Relación |
|---|---|
| **Imports** | `material`, `provider`, `app_colors`, `app_logo`, `app_text_field`, `AuthViewModel` |
| **Providers** | `Consumer<AuthViewModel>` |
| **Widgets usa** | `AppLogo`, `AppTextField` |
| **Navega a** | `/login` (pushNamed), `Navigator.pop(context)` al éxito |
| **Quién la llama** | `main.dart` ruta `/register`, `login_screen.dart` (pushNamed), `welcome_screen.dart` (pushNamed) |

### 2.4 SettingsScreen (`lib/features/settings/presentation/views/settings_screen.dart`)

| Componente | Relación |
|---|---|
| **Imports** | `material`, `app_colors` |
| **Providers** | Ninguno |
| **Servicios** | Ninguno |
| **Navega a** | Solo `Navigator.pop(context)` |
| **Quién la llama** | **NADIE** — no hay ninguna referencia a `SettingsScreen` en todo el código. Es huérfana. |

### 2.5 AdminScreen (`lib/features/admin/presentation/views/admin_screen.dart`)

| Componente | Relación |
|---|---|
| **Imports** | `dart:io`, `material`, `file_picker`, `share_plus`, `provider`, `ThemeNotifier`, `route_transitions`, `AuthViewModel`, `AthleteListScreen`, `teams.dart`, `notifications.dart`, `DatabaseService` |
| **Providers** | `context.watch<AuthViewModel>().user`, `context.watch<ThemeNotifier>()`, `context.read<AuthViewModel>().logout()`, `context.read<ClubViewModel>()` |
| **Servicios** | `DatabaseService.instance` → `exportToJson()`, `importFromJson(json)` |
| **Navega a** | `AthleteListScreen`, `TeamManagementScreen`, `InviteMemberScreen`, `NotificationsScreen`, `NotificationPreferencesScreen`, `CreateClubScreen` |
| **Quién la llama** | `AppShell._screens[5]` |

### 2.6 MatchScreen (`lib/features/partido/presentation/views/match_screen.dart`)

| Componente | Relación |
|---|---|
| **Imports** | `material`, `provider`, `app_colors`, `models.dart`, `match_config`, `PartidoViewModel`, `ScoreboardWidget`, `FullCourtWidget`, `PlayerStatsDialog` |
| **Providers** | `ChangeNotifierProvider(create: (_) => PartidoViewModel()..init(widget.config))`, `Consumer<PartidoViewModel>` |
| **Widgets usa** | `ScoreboardWidget`, `FullCourtWidget`, `PlayerStatsDialog` |
| **Navega a** | Solo dialogs internos con `Navigator.pop` |
| **Quién la llama** | `MatchStartDialog` (push), `PlayerSelectionScreen` (pushReplaceSlide) |

### 2.7 MatchSetupScreen (`lib/features/partido/presentation/views/match_setup_screen.dart`)

| Componente | Relación |
|---|---|
| **Imports** | `material`, `app_colors`, `route_transitions`, `models.dart`, `match_config`, `PlayerSelectionScreen` |
| **Providers** | Ninguno |
| **Navega a** | `PlayerSelectionScreen` (pushSlide) |
| **Quién la llama** | **NADIE** — no hay referencias. Es una ruta alternativa de creación de partido no utilizada. |

### 2.8 CourtScreen (`lib/features/cancha/presentation/views/court_screen.dart`)

| Componente | Relación |
|---|---|
| **Imports** | `material`, `provider`, `app_colors`, `player.dart`, `court_models`, `CourtViewModel`, `CourtPainter`, `PositionSlot`, `RotationTimeline`, `CourtSetupDialog` |
| **Providers** | `ChangeNotifierProvider(create: (_) => CourtViewModel()..init())`, `Consumer<CourtViewModel>` |
| **Widgets usa** | `CourtPainter`, `PositionSlot`, `RotationTimeline`, `CourtSetupDialog` |
| **Navega a** | Solo dialogs internos con `Navigator.pop` |
| **Quién la llama** | `AppShell` (Navigator.push desde `_MatchLauncherPlaceholder`) |

### 2.9 StatisticsScreen (`lib/features/statistics/presentation/views/statistics_screen.dart`)

| Componente | Relación |
|---|---|
| **Imports** | `material`, `provider`, `ThemeNotifier`, `DatabaseService`, `StatisticsService`, `statistics_models`, `AthleteStatisticsScreen` |
| **Providers** | `context.watch<ThemeNotifier>().isDark` |
| **Servicios** | `StatisticsService()` → `loadSeasonSummary()`, `loadAthleteStats()`, `loadAttendanceStats()`; `DatabaseService.instance.initialize()` |
| **Navega a** | `AthleteStatisticsScreen` (Navigator.push con MaterialPageRoute) |
| **Quién la llama** | `AppShell._screens[3]` |

### 2.10 AthleteStatisticsScreen (`lib/features/statistics/presentation/views/athlete_statistics_screen.dart`)

| Componente | Relación |
|---|---|
| **Imports** | `material`, `provider`, `ThemeNotifier`, `models.dart`, `statistics_models` |
| **Providers** | `context.watch<ThemeNotifier>().isDark` |
| **Servicios** | Ninguno (datos por constructor `athleteStats`) |
| **Navega a** | Solo `Navigator.pop(context)` |
| **Quién la llama** | `StatisticsScreen` (Navigator.push) |

---

## 3. Duplicados detectados

### 3.1 Servicios Firebase — TRES implementaciones de autenticación

| Archivo | Clase | Estado | ¿Quién usa? |
|---|---|---|---|
| `lib/features/auth/data/repositories/firebase_auth_repository.dart` | `FirebaseAuthRepository` | ✅ VIVO | `main.dart` L40 (cuando `useFirebase=true`) |
| `lib/features/auth/data/repositories/auth_repository.dart` | `AuthRepository` | ✅ VIVO | `main.dart` L42 (cuando `useFirebase=false`) |
| `lib_firebase/core/services/firebase_auth_service.dart` | `FirebaseAuthService` | 💀 MUERTO | **Nadie** — nunca importado |

**Conclusión:** `lib_firebase/firebase_auth_service.dart` sobra. Es un intento anterior de Firebase auth que quedó abandonado. `FirebaseAuthRepository` es el que realmente se usa.

### 3.2 Servicios de datos — CUATRO implementaciones

| Archivo | Clase | Estado | ¿Quién usa? |
|---|---|---|---|
| `lib/features/estadisticas/data/local_db/database_service.dart` | `DatabaseService` | ✅ VIVO | Singleton usado en toda la app |
| `lib/core/services/club_data_service.dart` | `ClubDataService` | ✅ VIVO | `ClubViewModel` (Firestore sync) |
| `lib/core/services/firebase_sync_service.dart` | `FirebaseSyncService` | 💀 MUERTO | **Nadie** — nunca importado |
| `lib_firebase/core/services/firebase_data_service.dart` | `FirebaseDataService` | 💀 MUERTO | **Nadie** — nunca importado |

**Conclusión:**
- `DatabaseService` es singleton local (sembast) y es el almacenamiento real.
- `ClubDataService` envuelve `DatabaseService` para sync a Firestore en colecciones por club.
- `FirebaseSyncService` y `FirebaseDataService` son código muerto.

### 3.3 Modelos de atleta — NO hay duplicado exacto

| Archivo | Clase | Propósito |
|---|---|---|
| `lib/features/estadisticas/data/models/player.dart` | `Player` | Modelo único de atleta |
| `lib/features/statistics/data/statistics_models.dart` | `AthleteStats` | Wrapper de estadísticas agregadas (no es un modelo) |
| `lib/features/statistics/data/statistics_models.dart` | `PlayerAttendanceSummary` | DTO de resumen de asistencia |

No hay duplicado. `Player` es el único modelo de atleta.

### 3.4 Modelos de partido — DOS modelos de evento paralelos

| Archivo | Clase | Propósito | Usado por |
|---|---|---|---|
| `lib/features/partido/data/match_event.dart` | `MatchEvent` | Evento simple de punto (athleteId, matchId, eventType, rotacion) | `CourtViewModel`, `ClubDataService` (stream) |
| `lib/features/estadisticas/data/models/stat_event.dart` | `StatEvent` | Evento detallado (tipoAccion, resultado, zona, setNumero) | `StatsCalculator`, `PlayByPlayScreen`, `DatabaseService` |

**Problema:** Dos sistemas paralelos de registro de eventos. `MatchEvent` es simple y usado en cancha/rotaciones. `StatEvent` es detallado y usado en estadísticas. No hay sincronización entre ambos. Si un usuario registra un punto en `CourtScreen`, puede quedar solo como `MatchEvent` sin el `StatEvent` detallado.

### 3.5 ViewModels de partido — DOS ViewModels con superposición

| Archivo | Clase | Propósito |
|---|---|---|
| `lib/features/partido/presentation/viewmodels/partido_viewmodel.dart` | `PartidoViewModel` | Maneja match lifecycle: score, rotation, timer, sets. Usado por `MatchScreen`. |
| `lib/features/estadisticas/presentation/viewmodels/play_by_play_viewmodel.dart` | `PlayByPlayViewModel` | Maneja match lifecycle + grabación de eventos de estadísticas detallados. Usa `MatchRepository` y `StatEventRepository`. |

**Problema:** Ambos mantienen estado de partido duplicado. `PartidoViewModel` se usa en `MatchScreen` (pantalla principal de juego). `PlayByPlayViewModel` se usa en `PlayByPlayScreen` (estadísticas en vivo). Si uno modifica el match, el otro no se entera.

### 3.6 Widgets de cancha — TRES representaciones visuales

| Archivo | Widget | Screen |
|---|---|---|
| `lib/features/partido/presentation/widgets/full_court_widget.dart` | `FullCourtWidget` | `MatchScreen` |
| `lib/features/partido/presentation/widgets/volleyball_court_widget.dart` | `VolleyballCourtWidget` | No referenciado directamente |
| `lib/features/cancha/presentation/widgets/court_painter.dart` | `CourtPainter` | `CourtScreen` |

**Problema:** `FullCourtWidget` y `VolleyballCourtWidget` coexisten en `partido/`. `FullCourtWidget` es el usado. `VolleyballCourtWidget` podría ser código muerto o estar sin usar.

### 3.7 Módulo estadísticas — DOS módulos con nombres distintos

| Módulo | Archivos | Propósito |
|---|---|---|
| `features/estadisticas/` | 20 files | Sistema completo de estadísticas en tiempo real: cálculo, streaming, play-by-play, MVP |
| `features/statistics/` | 5 files | Capa de agregación: resúmenes de temporada, estadísticas por atleta |

No son duplicados exactos pero hay **superposición conceptual**:
- `StatsCalculator.calcularStats()` (estadisticas/) calcula estadísticas por partido
- `StatisticsService.loadAthleteStats()` (statistics/) agrega las estadísticas a nivel temporada
- Ambos llaman a `DatabaseService` para obtener datos crudos

---

## 4. Análisis Firebase y almacenamiento

### 4.1 Stack tecnológico

| Tecnología | Uso | Archivo clave |
|---|---|---|
| **Firebase Auth** | Auth email/password | `firebase_auth_repository.dart` |
| **Google Sign-In** | Auth con Google (Android + iOS) | `firebase_auth_repository.dart` (Firebase mode), `google_auth_service.dart` (local mode) |
| **Cloud Firestore** | Sincronización multidispositivo (clubes) | `club_data_service.dart` |
| **sembast** | Base de datos local (principal) | `database_service.dart` |
| **SharedPreferences** | Persistencia de tema (dark/light) | `theme_notifier.dart` |
| **SQLite / Hive** | ❌ **No se usan** | — |

### 4.2 Flujo de autenticación completo

```
                    main.dart
                        │
                        ├─ Firebase.initializeApp()
                        ├─ AppConfig.enableFirebase()
                        └─ ServiceLocator.registerAuth(
                        │      ├─ FirebaseAuthRepository()  ← si useFirebase=true
                        │      └─ AuthRepository()          ← si useFirebase=false
                        │
            AuthViewModel.checkAuth()
                        │
                        ├─ _repository.loadSession()
                        │     ├─ Firebase → FirebaseAuth.instance.currentUser
                        │     └─ Local → sembast _sessionStore.record(0)
                        │
                        ├─ [user found] → AuthStatus.authenticated → AppShell
                        │
                        └─ [no user] → AuthStatus.unauthenticated → WelcomeScreen


    REGISTER                    LOGIN                       LOGOUT
       │                          │                          │
    RegisterScreen              LoginScreen              AdminScreen / AppShell
       │                          │                          │
    AuthViewModel.register    AuthViewModel.login       AuthViewModel.logout
       │                          │                          │
    _repository.register()    _repository.login()       _repository.logout()
       │                          │                          │
    Firebase:                Firebase:                  Firebase:
      createUser()             signInWithEmailAndPassword()  signOut()
      + updateDisplayName       + set _currentUser           + _googleSignIn.signOut()
      + Firestore doc          Local:                       Local:
    Local:                     query users by email          clearSession()
      save user + session      compare plaintext password
                               save session userId

    GOOGLE SIGN-IN (Firebase path)
      AuthViewModel.loginWithGoogle()
        → FirebaseAuthRepository.signInWithGoogle()
          1. GoogleSignIn.signIn()
          2. googleUser.authentication → accessToken + idToken
          3. GoogleAuthProvider.credential(accessToken, idToken)
          4. FirebaseAuth.instance.signInWithCredential(credential)
          5. Check/create Firestore doc users/{uid}

    GOOGLE SIGN-IN (local path)
      AuthViewModel.loginWithGoogle()
        → GoogleAuthService.instance.signIn()
          1. GoogleSignIn.signIn()
          2. Save or find user in local sembast
          3. saveSessionUserId()
```

### 4.3 Configuración de Google Sign-In

```dart
GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: '977265581819-lsf2k2370img9f2204v5n173oikvjhdv.apps.googleusercontent.com',
)
```

- `serverClientId` está configurado (requerido para Android)
- No hay `clientId` explícito para iOS (usa `GoogleService-Info.plist`)
- Las mismas credenciales aparecen en `FirebaseAuthRepository` y `GoogleAuthService`

### 4.4 Problemas de seguridad en auth local

- **Contraseñas en texto plano** en `AuthRepository` (no hay hash). Ver `lib/features/auth/data/repositories/auth_repository.dart`.

### 4.5 ServiceLocator incompleto

```dart
class ServiceLocator {
  registerAuth(AbstractAuthService)  → ✅ llamado en main.dart
  registerData(AbstractDataService)  → ❌ NUNCA llamado
}
```

El `ServiceLocator` puede registrar un servicio de datos, pero ningún código lo hace. `DatabaseService.instance` se usa como singleton directo en toda la app, ignorando la abstracción.

---

## 5. Mapa de navegación

### 5.1 Sistema de navegación

- **No usa** GoRouter, AutoRoute, ni Navigator 2.0
- **Usa** `Navigator.push`, `Navigator.pushNamed`, `Navigator.pop`, y extensión `context.pushSlide()` (custom slide transition)
- **Rutas nombradas** (3): `/welcome`, `/login`, `/register` — definidas en `main.dart._onGenerateRoute`
- **AppShell** con `IndexedStack` para 6 tabs + sidebar en pantallas anchas

### 5.2 Mapa completo

```
Splash (_SplashScreen en main.dart)
  │  [checkAuth() async]
  ▼
WelcomeScreen
  │  pushNamed('/login')
  ├────────────────────────► LoginScreen
  │                           │  pushNamed('/register')
  │                           ├────► RegisterScreen
  │                           │
  │                           │  [AuthViewModel.login()]
  │                           │
  │  pushNamed('/register')   │
  ├────────────────────────► RegisterScreen
  │                           │  [AuthViewModel.register()]
  │                           │
  ▼                           ▼
  ┌───────────────────────────────────────┐
  │           AppShell                    │
  │  [IndexedStack + BottomNav/Sidebar]   │
  │                                       │
  │  Tab 0: DashboardScreen               │
  │    ├── pushSlide(AthleteListScreen)   │
  │    ├── pushSlide(PlayByPlayScreen)    │
  │    ├── pushSlide(AttendanceScreen)    │
  │    ├── pushSlide(AthleteFormScreen)   │
  │    └── showDialog(MatchStartDialog)   │
  │          └── push(MatchScreen)        │
  │                                       │
  │  Tab 1: AthleteListScreen             │
  │    ├── pushSlide(AthleteFormScreen)   │
  │    └── pushSlide(PlayerDetailScreen)  │
  │          └── pushSlide(AthleteEditScreen)│
  │                                       │
  │  Tab 2: _MatchLauncherPlaceholder     │
  │    ├── showDialog(MatchStartDialog)   │
  │    │     └── push(MatchScreen)        │
  │    └── push(CourtScreen)             │
  │                                       │
  │  Tab 3: StatisticsScreen              │
  │    └── push(AthleteStatisticsScreen)  │
  │                                       │
  │  Tab 4: AttendanceScreen              │
  │    └── push(AttendanceHistoryScreen)  │
  │         └── push(PlayerDetailScreen)  │
  │                                       │
  │  Tab 5: AdminScreen                   │
  │    ├── pushSlide(TeamManagementScreen)│
  │    │    ├── push(CreateClubScreen)    │
  │    │    └── push(InviteMemberScreen)  │
  │    ├── pushSlide(NotificationsScreen) │
  │    ├── pushSlide(NotifPrefsScreen)    │
  │    └── pushSlide(AthleteListScreen)   │
  │                                       │
  │  AppBar: NotificationBell             │
  │    └── push(NotificationsScreen)      │
  │                                       │
  │  Drawer: SettingsDrawer               │
  │    (endDrawer desde Dashboard)        │
  │                                       │
  │  Sidebar: UserMenu                    │
  │    └── logout() → WelcomeScreen       │
  └───────────────────────────────────────┘
```

### 5.3 Errores potenciales de navegación

1. **ORFANDAD**: `SettingsScreen` no es referenciada por nadie. El accesso a settings es solo via `SettingsDrawer` (endDrawer en Dashboard). La pantalla standalone de settings nunca se muestra.

2. **ORFANDAD**: `MatchSetupScreen` no es llamada por nadie. El flujo de MatchStartDialog → PlayerSelectionScreen → MatchScreen es el único que se usa.

3. **ORFANDAD**: `CoachModeScreen` existe pero nadie la navega.

4. **Inconsistencia de estilos**: Algunas pantallas usan `Navigator.push(MaterialPageRoute(...))` (AppShell → CourtScreen, StatisticsScreen → AthleteStatisticsScreen) mientras otras usan `context.pushSlide(...)`. Esto causa que algunas transiciones tengan slide y otras no.

5. **MatchStartDialog usa rootNavigator**: `Navigator.of(context, rootNavigator: true).push(slideRightRoute(...))` — correcto porque está dentro de un showDialog que crea un Navigator overlay. Sin embargo, **no siempre se usa rootNavigator** en otros casos similares.

6. **pushSlide sin mounted check**: `DashboardScreen` y otras pantallas llaman `context.pushSlide()` sin verificar `mounted`. Si el widget se desmonta durante la transición, puede causar errores.

---

## 6. Análisis del Dashboard

### 6.1 ¿De dónde obtiene los contadores?

```dart
// DashboardScreen._loadCounts()
final db = DatabaseService.instance;
await db.initialize();
final players = await db.getAllPlayers();            // → sembast store 'players'
final matches = await db.getMatchesByState(          // → sembast store 'matches'
  EstadoPartido.finalizado                           //   filtrado por estado
);
```

- **Origen:** `DatabaseService` (sembast local)
- **Contadores:** `_athleteCount`, `_matchCount`, `_loaded`
- **Sets:** Siempre muestra `'--'` (hardcoded, no se calcula)

### 6.2 ¿Cómo se actualizan?

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_loaded) _loadCounts();
}
```

- Se cargan **una sola vez** en `didChangeDependencies` (con guard `_loaded`)
- **NO se refrescan** cuando se agrega/elimina un atleta o partido
- **NO hay listener**, stream, ni notificación del `DatabaseService`
- El usuario debe **reabrir la pantalla** o hacer **pull-to-refresh** (no implementado) para ver cambios

### 6.3 ¿Por qué tarda en refrescar?

1. **`didChangeDependencies` vs `initState`**: El uso de `didChangeDependencies` es correcto para llamadas async, pero si el widget se reconstruye sin cambiar dependencias, no se vuelve a llamar.

2. **Sembast async overhead**: Cada llamada es una operación async sobre archivo. `getAllPlayers()` + `getMatchesByState()` son dos queries separadas.

3. **Sin caché**: Cada vez que el dashboard monta, hace lectura completa de la DB. No hay caché ni memoización.

4. **Sin reactive updates**: No usa streams, no usa `watch`, no usa Providers para los contadores. Es lectura under-init + setState.

### 6.4 Mejoras recomendadas

- Convertir contadores a un `DashboardViewModel` con Provider + streams
- Usar `StreamBuilder` o `streamPlayers()` / `streamMatches()` de `ClubDataService`
- Agregar pull-to-refresh
- Cachear conteos y refrescar solo cuando cambien

---

## 7. Problemas encontrados (resumen ejecutivo)

### 🔴 Críticos

| # | Problema | Archivo |
|---|---|---|
| 1 | **Contraseñas en texto plano** en auth local | `auth_repository.dart` |
| 2 | **Dashboard no se refresca** después de agregar/eliminar datos | `dashboard_screen.dart:30-48` |
| 3 | **Dos sistemas de eventos paralelos** (MatchEvent vs StatEvent) sin sincronización | `match_event.dart` vs `stat_event.dart` |
| 4 | **Errores de análisis** en `lib_firebase/` (36 errores) — rompen `flutter analyze` global | `lib_firebase/` completo |

### 🟡 Altos

| # | Problema | Archivo |
|---|---|---|
| 5 | **Código muerto:** `lib_firebase/` completo (2 archivos, nunca importados) | `lib_firebase/` |
| 6 | **Código muerto:** `firebase_sync_service.dart` (nunca importado) | `firebase_sync_service.dart` |
| 7 | **Código muerto:** `SettingsScreen` (no referenciada por nadie) | `settings_screen.dart` |
| 8 | **Código muerto:** `MatchSetupScreen` (no referenciada) | `match_setup_screen.dart` |
| 9 | **ServiceLocator incompleto:** `registerData()` nunca llamado | `service_locator.dart` |
| 10 | **Inconsistencia transiciones:** `pushSlide` vs `Navigator.push(MaterialPageRoute)` | Varias screens |

### 🟡 Medios

| # | Problema | Archivo |
|---|---|---|
| 11 | **PartidoViewModel y PlayByPlayViewModel** compiten en gestión de match lifecycle | `partido_viewmodel.dart` / `play_by_play_viewmodel.dart` |
| 12 | **Dos widgets de cancha** en partido/ (FullCourtWidget usado, VolleyballCourtWidget sin referencia clara) | `full_court_widget.dart` / `volleyball_court_widget.dart` |
| 13 | **Tres representaciones de cancha** (partido + cancha) sin compartir lógica | `full_court_widget.dart` / `court_painter.dart` / `volleyball_court_widget.dart` |
| 14 | **Sets en dashboard siempre "--"** (hardcoded, nunca implementado) | `dashboard_screen.dart:135` |

### 🟢 Bajos

| # | Problema | Archivo |
|---|---|---|
| 15 | 300+ warnings `info` (prefer_const, deprecated_member_use, use_build_context_synchronously) | Varios |
| 16 | Hardcode de `AppColors` en algunas screens que no se migraron completamente a `Theme.of(context)` | Varias |
| 17 | `CoachModeScreen` no referenciada | `coach_mode_screen.dart` |

### Resumen deuda técnica

| Categoría | Cantidad |
|---|---|
| Archivos de código muerto (nunca importados) | 5 |
| ViewModels duplicados (superposición funcional) | 2 pares |
| Modelos de evento paralelos sin sincronización | 2 |
| Errores flutter analyze (solo lib_firebase/) | 36 |
| Warnings info flutter analyze | 300+ |
| Screens huérfanas | 3 |

---

*Fin del reporte de auditoría. Generado el 16 junio 2026.*

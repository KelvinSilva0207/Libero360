# Libero360 — Project State

> Fecha: 19/06/2026
> Objetivo: Auditoría completa del estado actual del proyecto

---

## 1. ARQUITECTURA ACTUAL

### 1.1 Patrón

Feature-first architecture con capa `core/` compartida, Providers globales, y sincronización Firebase condicional.

```
lib/
├── core/                    # Servicios globales, tema, config, widgets reutilizables
├── features/
│   ├── admin/               # Alias de SettingsScreen (1 archivo)
│   ├── asistencia/          # CRUD atletas + asistencia
│   ├── atleta/              # VACÍO (solo .gitkeep)
│   ├── auth/                # Login, Register, Welcome + AuthViewModel
│   ├── cancha/              # Cancha de práctica (court)
│   ├── estadisticas/        # Modelos core, DB, repositorios, stats
│   ├── notifications/       # Campanita + preferencias
│   ├── partido/             # MatchScreen, MatchController, rotaciones
│   ├── profiles/            # Multi-perfil (categorías)
│   ├── settings/            # Configuración general
│   ├── statistics/          # Dashboard de estadísticas
│   ├── sync/                # Sincronización Firebase
│   └── teams/               # Clubes, miembros, roles
├── ui/                      # AppShell, DashboardScreen/DashboardViewModel
└── main.dart                # Providers globales + rutas auth
```

### 1.2 Pantallas existentes (totales: ~35)

| Feature | Screens/Pages/Dialogs | Activas |
|---------|----------------------|---------|
| Auth | WelcomeScreen, LoginScreen, RegisterScreen | ✅ |
| Dashboard | DashboardScreen | ✅ |
| Partido | MatchScreen, MatchStartDialog, CoachModeScreen | ✅ |
| Partido | PlayerSelectionScreen | ❌ STALE |
| Cancha | CourtScreen, CourtSetupDialog | ✅ |
| Estadísticas | PlayByPlayScreen, LiveStatsDashboardScreen | ✅ / ⚠️ sin ruta |
| Asistencia | AttendanceScreen, AttendanceHistoryScreen, AttendanceHistoryDetailScreen | ✅ |
| Asistencia | AthleteListScreen, AthleteFormScreen, AthleteEditScreen, PlayerDetailScreen | ✅ |
| Settings | SettingsScreen + 7 sub-secciones | ✅ |
| Admin | AdminScreen (= SettingsScreen alias) | ✅ |
| Profiles | ProfilesScreen, CreateProfileScreen | ✅ |
| Teams | TeamManagementScreen, InviteMemberScreen, CreateClubScreen, ClubSwitcher | ✅ |
| Notifications | NotificationsScreen, NotificationPreferencesScreen | ✅ |
| Statistics | StatisticsScreen, AthleteStatisticsScreen | ✅ |

### 1.3 ViewModels / Controllers (totales: 12)

| VM/Controller | Feature | Responsabilidad |
|---------------|---------|-----------------|
| AuthViewModel | auth | Login/register/logout/session |
| ThemeNotifier | core | Modo oscuro/claro |
| ProfileViewModel | profiles | CRUD perfiles + selección activa |
| DashboardViewModel | ui | Streams de conteos (atletas, partidos, sets) |
| ClubViewModel | teams | Gestión de club + data streams |
| NotificationViewModel | notifications | Notificaciones push |
| MatchController | partido | Motor del partido (puntos, sets, timer, rotaciones) |
| PartidoViewModel | partido | Delegador 1:1 de MatchController |
| CourtViewModel | cancha | Lógica de cancha de práctica |
| PlayByPlayViewModel | estadisticas | Estadísticas jugada por jugada |
| SettingsViewModel | settings | Export/import/tema/notificaciones |
| SyncViewModel | sync | Estado de sincronización Firebase |

### 1.4 Servicios / Repositorios

| Servicio | Tipo | Rol |
|----------|------|-----|
| DatabaseService | Singleton (Sembast) | CRUD local de todas las entidades |
| ClubDataService | Singleton (Firebase) | Dual-write local + Firestore |
| SyncService | Singleton | Upload/download Firebase por entidad |
| AuthRepository | Abstract impl | Auth local SQLite |
| FirebaseAuthRepository | Abstract impl | Auth Firebase |
| GoogleAuthService | Singleton | Google Sign-In local |
| ServiceLocator | Singleton | Registro de servicios abstractos |
| ProfileRepository | Singleton | Persistencia de perfiles (DB separada) |
| ClubService | Instancia | CRUD clubes en Firestore |
| InvitationService | Instancia | Gestión de invitaciones |
| PermissionService | Instancia | Roles y permisos |
| NotificationService | Instancia | CRUD notificaciones |
| StatisticsService | Instancia | Cálculo de estadísticas agregadas |
| StatsCalculator | Instancia | Estadísticas por jugador |
| MvpCalculator | Instancia | Cálculo de MVP |
| AttendanceService | Instancia | Registro de asistencia |
| StatsStreamService | Instancia | Streams de estadísticas |

### 1.5 Modelos principales

| Modelo | Feature | Propósito |
|--------|---------|-----------|
| Player | estadisticas | Atleta (nombre, número, posición, salud, status) |
| Match | estadisticas | Partido (equipos, puntos, sets, estado, config) |
| StatEvent | estadisticas | Evento estadístico (tipo acción, resultado, zona) |
| MatchEvent | partido | Evento de partido (punto, rotación) |
| MatchConfig | partido | Config para iniciar partido |
| PlayerAssignment | cancha | Asignación jugador ↔ posición (1-6) |
| RotationRecord | cancha | Historial de rotación |
| PositionEvent | cancha | Evento en posición específica |
| ProfileModel | profiles | Perfil (clubName, category, role) |
| Club, ClubMember, ClubInvitation | teams | Gestión de club |
| AppNotification | notifications | Notificación push |
| SeasonSummary, AthleteStats, AttendanceStats | statistics | Estadísticas agregadas |
| AppUser | auth | Usuario |
| Season | estadisticas | Temporada |

### 1.6 Providers globales (main.dart MultiProvider)

Orden en MultiProvider:
1. `AuthViewModel` — sesión
2. `ThemeNotifier` — tema
3. `ProfileViewModel` — perfil activo (se auto-carga)
4. `DashboardViewModel` — dashboard (usa profileId)
5. `ClubViewModel` — club (se auto-inicia)
6. `NotificationViewModel` — notificaciones
7. `MatchController` — partido activo

---

## 2. ZONA PARTIDO

### 2.1 MatchScreen

**Archivo:** `lib/features/partido/presentation/views/match_screen.dart` (912 líneas)

**Flujo:**
1. Se navega desde `MatchStartDialog._finalizar()` con un `MatchConfig`
2. La pantalla busca `MatchController` via Provider
3. Llama `vm.init(config)` que crea un `Match` en DB, inicializa estado, arranca timer
4. Muestra: Scoreboard, FullCourtWidget, botones de acción, timer, selector de sets

**Layouts:**
- Mobile: scoreboard arriba, cancha abajo, bottom bar con acciones
- Desktop: scoreboard arriba, cancha centrada, acciones en panel lateral

**Secciones:**
- `ScoreboardWidget` (reutilizable): marcador, sets, set actual
- `FullCourtWidget`: cancha con ambos equipos, rotación, saque
- End drawer: lista de atletas con botón "+" para registrar estadísticas
- Bottom bar: +1 punto local/visitante, -1 punto, selector de set

### 2.2 CourtScreen (cancha de práctica)

**Archivo:** `lib/features/cancha/presentation/views/court_screen.dart` (736 líneas)

**Flujo:**
1. Se navega desde `AppShell` (tab Partidos → "Cancha de práctica")
2. `CourtViewModel.init(profileId)` carga jugadores desde DB
3. `CourtSetupDialog` permite asignar 6 jugadores a posiciones Z1-Z6
4. La cancha se renderiza con `CourtPainter` + 6 `PositionSlot`
5. Botón "Ganó el saque" ejecuta `rotate()` → corrimiento circular + registra `RotationRecord`
6. Tap en slot ocupado abre bottom sheet para registrar evento (winner/regular/error)
7. `RotationTimeline` muestra historial de rotaciones
8. "Estadísticas" muestra resumen de eventos por jugador

### 2.3 CoachModeScreen

**Archivo:** `lib/features/partido/presentation/views/coach_mode_screen.dart`

- Panel de monitoreo que muestra: score, rotación actual, errores por atleta (hardcodeado 0), sugerencias de sustituciones (placeholder), historial de sets
- Usa `PartidoViewModel` vía `Consumer`
- **Issue:** `FutureBuilder` creado inline en build (anti-patrón Flutter)
- **Issue:** Errores hardcodeados como "0"

### 2.4 Cómo funcionan las rotaciones

**En partido (MatchController):**
- `_rotacionLocal` y `_rotacionVisitante`: int de 0-5 (índice cíclico)
- `rotarLocal()` / `rotarVisitante()`: `_rotacion = (_rotacion + 1) % 6`
- `cambiarServicio()`: alterna `_isLocalServing` y rota al equipo que ganó el punto
- La visualización en `FullCourtWidget` usa `_servingOrderToDisplay(i, rotacion)` para mapear orden de servicio → posición visual
- `MatchEvent` guarda `rotacion` (índice) en cada punto

**En práctica (CourtViewModel):**
- `_assignments`: `List<PlayerAssignment?>` de 6 posiciones
- `_history`: `List<RotationRecord>` (historial completo)
- `rotate()`: desplaza las asignaciones (Z1→Z2, Z2→Z3, ..., Z6→Z1) y guarda en historial
- `RotationTimeline` widget renderiza el historial

### 2.5 Cómo se manejan los sets

- `Match._setScores`: `List<MapEntry<int,int>>` guarda puntos por set
- `setActual`: int (1-based)
- `sumarPunto*()` detecta si se alcanzó el puntaje para ganar set, incrementa `setsLocal/Visitante`, guarda duración, pausa timer
- `cambiarSet(int)`: cambia manualmente a otro set preservando scores
- Set selector: bottom sheet en MatchScreen
- `ScoreboardWidget` muestra sets en columnas

### 2.6 Cómo se manejan los líberos

**No hay manejo explícito de líberos.** El modelo `Player` tiene `Posicion.libre` como valor del enum, pero:
- No hay reglas de sustitución de líbero
- No hay conteo de sustituciones de líbero
- No hay restricciones de rotación de líbero
- El líbero es tratado como cualquier otra posición en la cancha

### 2.7 Historial de saque

- `MatchController._isLocalServing` bool que alterna
- No hay registro histórico de quién sacó en cada punto
- `MatchEvent` no guarda información de saque
- En `CourtViewModel`: `_isServing` bool + `RotationRecord.wonServe`
- El saque se infiere por posición-0 en la rotación + `isLocalServing`

### 2.8 Estadísticas rápidas

**No existen.** No hay widget de estadísticas rápidas visibles durante el partido. Lo más cercano:
- `PlayerStatsDialog`: registro manual de stats por jugador (ataque/saque/bloqueo/defensa/error)
- `StatRecorderWidget` (estadisticas): grabador de eventos con cancha interactiva

### 2.9 Widgets Stale en Partido

| Widget | Razón |
|--------|-------|
| PlayerSelectionScreen | Sin llamada entrante (reemplazado por MatchStartDialog) |
| RotationWidget | Sin referencia externa (FullCourtWidget hace esto) |
| ActionButtonsWidget | Sin referencia externa (acciones inline en MatchScreen) |
| RosterManagementSheet | Sin referencia externa |
| StatRecorderWidget (partido) | Sin referencia (superseded por estadisticas) |

---

## 3. ZONA ATLETAS

### 3.1 Athlete model

**Archivo:** `lib/features/estadisticas/data/models/player.dart` (108 líneas)

Campos principales:
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | int | PK auto-generado |
| nombre | String | Nombre completo |
| firstNames / lastNames | String | Nombres separados |
| displayName | String | Nombre visible |
| cedula | String | Cédula/DNI |
| fechaNacimiento | DateTime | Fecha de nacimiento (getter: edad) |
| numero | int? | Número de camiseta |
| posicion | Posicion enum | colocador/opuesto/central/receptor/libre/sinDefinir |
| esCapitan | bool | ¿Es capitán? |
| fotoUrl | String? | URL de foto |
| estadoSalud | EstadoSalud enum | disponible/lesionado/enDuda |
| profileId | String? | Perfil asociado |
| clubId | String? | Club asociado |
| atletaStatus | AthleteStatus enum | active/resting/injured/excused/inactive |
| statusReason / statusStartDate / statusEndDate | varios | Detalles del status |
| restriccion | RestriccionDeportiva | Restricciones entrenamiento/juego |

### 3.2 Athlete list

**Archivo:** `AthleteListScreen` (511 líneas)
- Lista todos los atletas ordenados por número de camiseta (capitanes first)
- Búsqueda por nombre, número o cédula
- Filtros por posición y estado de salud (modal bottom sheet con ChoiceChips)
- Muestra: número, nombre, posición, edad, cédula, badge capitán, indicador salud
- Contador de atletas en AppBar
- Botón FAB para crear nuevo atleta
- Tap en atleta → `PlayerDetailScreen`

### 3.3 Athlete create/edit

**Create:** `AthleteFormScreen` (372 líneas)
- Formulario con: nombres, apellidos, cédula, fecha nacimiento (date picker + edad calculada), número, posición (dropdown), capitán (switch), salud (dropdown), condición física, URL foto
- Guarda vía `DatabaseService.instance.savePlayer(player)`
- Retorna `true` para refrescar lista

**Edit:** `AthleteEditScreen` (251 líneas)
- Mismos campos pre-poblados
- Acceso desde `PlayerDetailScreen` (icono de editar)

**Delete:** No hay UI de eliminación. `DatabaseService.deletePlayer()` existe pero no tiene botón en ninguna pantalla.

### 3.4 Player detail

**Archivo:** `PlayerDetailScreen` (328 líneas)
- Header: número, nombre, posición, salud
- Info grid: CI, edad, condición, posición
- Stats card: ataque/bloqueo/defensa/saque/errores/efectividad (vía `StatsCalculator`)
- Badges de roles
- Botón editar → `AthleteEditScreen`

### 3.5 Filtros existentes

| Pantalla | Tipo de filtro | Implementación |
|----------|---------------|----------------|
| AthleteListScreen | Texto (nombre/número/cédula) | `where()` sobre lista |
| AthleteListScreen | Posición | ChoiceChips en modal |
| AthleteListScreen | Salud | ChoiceChips en modal |
| DashboardViewModel | Perfil (profileId) | Stream filtrado en memoria |
| ClubViewModel | Perfil (profileId) | Recarga desde DB |

### 3.6 Categorías U13/U15/U17/U19/U23

**No existen como enum.** El sistema de categorías es texto libre vía `ProfileModel.category`, donde el usuario escribe "U13", "Femenino", "Sub17", etc. No hay definiciones preestablecidas ni jerarquía.

---

## 4. CONFIGURACIÓN

### 4.1 SettingsScreen

**Archivo:** `lib/features/settings/presentation/views/settings_screen.dart`

Secciones (en orden):
1. **AccountSection**: avatar, nombre, email, botón cerrar sesión
2. **ClubSection**: nombre del club actual, invitar miembros, selector de club
3. **ProfilesSection**: selector de perfil activo, lista con eliminar, crear nuevo
4. **NotificationsSection**: toggle de notificaciones (badge count deshabilitado)
5. **AppearanceSection**: selector de tema (Dark activo, Light/System deshabilitados)
6. **SyncSection**: Firebase connection status, perfil activo, última sincronización, botón sincronizar
7. **DatabaseSection**: exportar/importar backup JSON, huérfanos

### 4.2 AdminScreen

**Archivo:** `lib/features/admin/presentation/views/admin_screen.dart` (11 líneas)

Es un wrapper puro: `return const SettingsScreen()`. Sin funcionalidad admin real.

### 4.3 Personalización (AppearanceSection)

- Dark mode: ✅ funcional
- Light mode: ⚠️ existe en UI pero deshabilitado
- System mode: ⚠️ existe en UI pero deshabilitado

### 4.4 Notificaciones

- Toggle master: ✅ funcional (persiste en SettingsRepository)
- Badge count: ❌ deshabilitado (texto "No disponible")
- NotificationPreferencesScreen: ✅ existe pero no hay enlace desde Settings

### 4.5 SyncSection

**Archivo:** `lib/features/settings/presentation/views/sync_section.dart`

- Muestra estado Firebase (● Conectado / ○ No conectado)
- Si `AppConfig.useFirebase == false`: muestra "Modo local"
- Muestra email del usuario, perfil activo, última sincronización
- Botón "Sincronizar ahora" → `SyncViewModel.syncAll(profileId, clubId)`
- SnackBar en éxito/error
- Logs 🔵🟢🔴

### 4.6 DatabaseSection

- Exportar backup (JSON vía share_plus)
- Importar backup (JSON vía file_picker)
- Restaurar (alias de importar)
- **OrphanCard**: muestra conteo de registros huérfanos + botón "Asignar todos al perfil activo"

### 4.7 SettingsDrawer (legacy)

**Archivo:** `lib/features/settings/presentation/widgets/settings_drawer.dart`

Drawer lateral alternativo con lógica duplicada de export/import. Probablemente legacy sin usar desde la migración a SettingsScreen.

### 4.8 Staff técnico

Gestionado desde `TeamManagementScreen` y `InviteMemberScreen` en `features/teams/`:
- Roles: owner, entrenador, asistente
- Permisos: `PermissionService` restringe eliminación a owner, CRUD atletas a owner/entrenador
- ClubSwitcher: selector de club actual

---

## 5. FIREBASE

### 5.1 Estado actual

- `AppConfig.useFirebase == false` por defecto
- Toda la funcionalidad Firebase está gateada detrás de esta flag
- `enableFirebase()` es llamado por script de setup externo

### 5.2 Authentication

**Dos implementaciones de `AbstractAuthService`:**
1. **AuthRepository** (local SQLite): activa por defecto
2. **FirebaseAuthRepository**: activa cuando `useFirebase == true`
   - Email/password con Firebase Auth
   - Google Sign-In con Firebase
   - Almacena usuario en Firestore `users/{uid}`

Selección vía `ServiceLocator` en `main.dart._initServices()`:
```dart
if (AppConfig.useFirebase) {
  ServiceLocator.instance.registerAuth(FirebaseAuthRepository());
} else {
  ServiceLocator.instance.registerAuth(AuthRepository());
}
```

### 5.3 Google Sign-In

**Dos caminos según `useFirebase`:**
- Firebase ON + `FirebaseAuthRepository`: usa `signInWithGoogle()` con Firebase
- Firebase OFF: usa `GoogleAuthService.signIn()` (local SQLite)

### 5.4 Firestore

**Estructura de datos cuando Firebase está activo:**

```
users/{uid}/
  {user profile data}

users/{uid}/profiles/{profileId}/
  {profile data}

clubs/{clubId}/profiles/{profileId}/
  {profile data}

clubs/{clubId}/profiles/{profileId}/athletes/{playerId}/
  {player data}

clubs/{clubId}/profiles/{profileId}/matches/{matchId}/
  {match data}

clubs/{clubId}/profiles/{profileId}/attendance/{recordId}/
  {attendance data}

clubs/{clubId}/profiles/{profileId}/stats/{eventId}/
  {stat event data}
```

**ClubDataService** es singleton que escribe en local + Firestore simultáneamente cuando `useFirebase == true`. Tiene métodos: save/delete/stream para cada entidad.

### 5.5 SyncService

- Singleton con upload/download por entidad (profiles, players, matches, attendance, stats)
- `syncAll()` orquesta upload secuencial
- Guards: no-op si `useFirebase == false` o no hay `uid`
- Logs con 🔵🟢🔴

### 5.6 ServiceLocator

- `_dataService` (AbstractDataService) **nunca es registrado** — `registerData()` no se llama en ningún lado
- `ClubDataService` no implementa `AbstractDataService` a pesar de hacer persistencia + cloud
- Esto es una inconsistencia arquitectónica

---

## 6. DASHBOARD

### 6.1 Estructura

**Archivo:** `lib/ui/dashboard_screen.dart`

**Header:**
- Foto + saludo "Hola, {nombre}"
- `ProfileSelector` (cambiar perfil activo)
- Icono settings → abre end drawer

**Fila de stats (3 cards):**
| Card | Dato | onTap |
|------|------|-------|
| Atletas | `vm.athleteCount` | → `AthleteListScreen` |
| Partidos | `vm.matchCount` | → `PlayByPlayScreen` |
| Sets | `vm.setCount` | ❌ No tiene onTap |

**Acciones rápidas (2 cards):**
| Botón | onTap |
|-------|-------|
| Nuevo Partido | → `MatchStartDialog` |
| Nuevo Atleta | → `AthleteFormScreen` |

**Resumen reciente (3 items):**
| Item | onTap |
|------|-------|
| Gestiona tus atletas | → `AthleteListScreen` |
| Estadísticas en vivo | → `PlayByPlayScreen` |
| Control de asistencia | → `AttendanceScreen` |

### 6.2 DashboardViewModel

- `init({String? profileId})`: carga streams filtrados de DB
- `athleteCount`, `matchCount`, `setCount`: derivados de streams
- `setCount` calculado como `sum(m.setActual - 1)` para partidos finalizados
- `setProfile()`: reinicializa con nuevo perfil
- `_error` existe pero **nunca se lee en UI**

### 6.3 Navegación desde Dashboard

```
DashboardScreen
├── ProfileSelector → cambia perfil activo (global)
├── Settings icon → SettingsDrawer (end drawer)
├── Card Atletas → AthleteListScreen
├── Card Partidos → PlayByPlayScreen
├── Card Sets → (sin acción)
├── Nuevo Partido → MatchStartDialog → MatchScreen
├── Nuevo Atleta → AthleteFormScreen
├── Gestiona atletas → AthleteListScreen
├── Estadísticas en vivo → PlayByPlayScreen
└── Control asistencia → AttendanceScreen
```

---

## 7. KNOWN ISSUES

### 7.1 Bugs

| # | Issue | Archivo | Gravedad |
|---|-------|---------|----------|
| 1 | El card "Sets" en dashboard no tiene onTap | `dashboard_screen.dart:129` | Baja |
| 2 | Error count en CoachModeScreen hardcodeado "0" | `coach_mode_screen.dart:248` | Media |
| 3 | `FutureBuilder` creado inline en build de CoachModeScreen (se re-crea en cada rebuild) | `coach_mode_screen.dart:285` | Media |
| 4 | `vm.jugadores.length` sin null-check en CoachModeScreen | `coach_mode_screen.dart:165` | Media |
| 5 | Dashboard error state (`_error`) nunca se muestra en UI | `dashboard_screen.dart` | Baja |
| 6 | El historial de sets excluye partidos en progreso (solo finalizados) | `dashboard_viewmodel.dart` | Baja |

### 7.2 Botones sin implementar

| # | Botón | Archivo | Estado |
|---|-------|---------|--------|
| 1 | Badge count en notificaciones | `notifications_section.dart` | Deshabilitado ("No disponible") |
| 2 | Light mode toggle | `appearance_section.dart` | Deshabilitado |
| 3 | System mode toggle | `appearance_section.dart` | Deshabilitado |
| 4 | Sincronizar dispositivos | `settings_drawer.dart:65` | Texto: "No implementado aún" |
| 5 | Card Sets (sin onTap) | `dashboard_screen.dart` | Sin acción |
| 6 | Sugerencias de sustituciones en CoachMode | `coach_mode_screen.dart:277` | Placeholder texto |
| 7 | Eliminar atleta (no hay botón en UI) | `athlete_list/form/detail` | No implementado |
| 8 | `SettingsViewModel.inviteMembers()` | `settings_viewmodel.dart:72` | Cuerpo vacío |

### 7.3 Rutas incorrectas / sin ruta

| # | Ruta | Problema |
|---|------|----------|
| 1 | `LiveStatsDashboardScreen` | Sin ruta activa que navegue hacia ella |
| 2 | `PlayerSelectionScreen` | Sin llamada entrante (stale) |
| 3 | Todas las rutas nombradas (`/welcome`, `/login`, `/register`) | ✅ Correctas |

### 7.4 Widgets duplicados

| # | Widget | Archivos | Problema |
|---|--------|----------|----------|
| 1 | `StatRecorderWidget` | `partido/widgets/` + `estadisticas/widgets/` | **COLISIÓN DE NOMBRE** si ambos se importan |
| 2 | `CourtPainter` / `_FullCourtPainter` / `_CanchaPainter` | 3 archivos distintos | 3 painters separados sin compartir lógica |
| 3 | Export/Import backup | `SettingsRepository` + `SettingsDrawer` + `DatabaseSection` | 3 implementaciones similares |
| 4 | `AdminScreen` = `SettingsScreen` wrapper | `admin/views/admin_screen.dart` | Capa innecesaria |

### 7.5 Problemas de rendimiento

| # | Issue | Archivo |
|---|-------|---------|
| 1 | `AthleteListScreen` carga TODOS los atletas en memoria y filtra con `where()` | `athlete_list_screen.dart` |
| 2 | `FutureBuilder` inline en build de CoachModeScreen (re-fetch en cada rebuild) | `coach_mode_screen.dart:285` |
| 3 | Dashboard usa streams que se reinician en cada cambio de perfil | `dashboard_viewmodel.dart` |

### 7.6 Problemas arquitectónicos

| # | Issue | Impacto |
|---|-------|---------|
| 1 | `settings_models.dart` (AppThemeMode) nunca se usa | Dead code |
| 2 | `ServiceLocator._dataService` nunca se registra | AbstractDataService incompleto |
| 3 | `ClubDataService` no implementa `AbstractDataService` | Inconsistencia |
| 4 | `lib_firebase/` no existe en repo | Setup script roto hasta crear directorio |
| 5 | `lib/features/atleta/` vacío (solo .gitkeep) | Feature planeada sin implementar |
| 6 | `PartidoViewModel` es delegador puro sin lógica adicional | Capa innecesaria |

### 7.7 Deuda técnica

| # | Item | Detalle |
|---|------|---------|
| 1 | `SettingsDrawer` legacy con lógica duplicada | Migrar a SettingsScreen o eliminar |
| 2 | Modelos usan clase mutable con cascade `..` | Patrón de código generado (no null-safe idiomático) |
| 3 | 7 widgets stale para eliminar | Ver tabla abajo |
| 4 | Sin tests de UI (solo 1 test de mapper) | `test/features/partido/data/mappers/match_event_mapper_test.dart` |

---

## 8. TABLA ARCHIVO / ESTADO / FUNCIÓN

### 8.1 Features activos

| Archivo | Estado | Función |
|---------|--------|---------|
| `lib/main.dart` | ✅ Activo | Providers globales, rutas auth, entry point |
| `lib/ui/app_shell.dart` | ✅ Activo | Shell con bottom nav / sidebar, _MatchLauncherPlaceholder, _ProfileCoordinator |
| `lib/ui/dashboard_screen.dart` | ✅ Activo | Dashboard principal con stats y accesos rápidos |
| `lib/ui/dashboard_viewmodel.dart` | ✅ Activo | Streams de conteos (atletas, partidos, sets) |
| `lib/features/auth/presentation/views/welcome_screen.dart` | ✅ Activo | Pantalla de bienvenida |
| `lib/features/auth/presentation/views/login_screen.dart` | ✅ Activo | Login email/password |
| `lib/features/auth/presentation/views/register_screen.dart` | ✅ Activo | Registro email/password |
| `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart` | ✅ Activo | Estado de autenticación |
| `lib/features/auth/data/repositories/auth_repository.dart` | ✅ Activo | Auth local SQLite |
| `lib/features/auth/data/repositories/firebase_auth_repository.dart` | ⚠️ Gateado | Auth Firebase (solo si useFirebase) |
| `lib/features/partido/presentation/controllers/match_controller.dart` | ✅ Activo | Motor del partido (477 líneas) |
| `lib/features/partido/presentation/viewmodels/partido_viewmodel.dart` | ✅ Activo | Delegador 1:1 de MatchController |
| `lib/features/partido/presentation/views/match_screen.dart` | ✅ Activo | Pantalla de partido (912 líneas) |
| `lib/features/partido/presentation/views/match_start_dialog.dart` | ✅ Activo | Diálogo de inicio de partido |
| `lib/features/partido/presentation/views/coach_mode_screen.dart` | ✅ Activo | Modo entrenador (con placeholders) |
| `lib/features/partido/presentation/widgets/scoreboard_widget.dart` | ✅ Activo | Marcador reutilizable |
| `lib/features/partido/presentation/widgets/full_court_widget.dart` | ✅ Activo | Cancha con 2 equipos + rotación |
| `lib/features/partido/presentation/widgets/player_stats_dialog.dart` | ✅ Activo | Diálogo de stats por jugador |
| `lib/features/partido/data/match_config.dart` | ✅ Activo | Config para iniciar partido |
| `lib/features/partido/data/match_event.dart` | ✅ Activo | Modelo de evento de partido |
| `lib/features/partido/data/mappers/match_event_mapper.dart` | ✅ Activo | Conversor MatchEvent ↔ StatEvent |
| `lib/features/cancha/presentation/views/court_screen.dart` | ✅ Activo | Cancha de práctica (736 líneas) |
| `lib/features/cancha/presentation/views/court_setup_dialog.dart` | ✅ Activo | Setup inicial de formación |
| `lib/features/cancha/presentation/viewmodels/court_viewmodel.dart` | ✅ Activo | Lógica de práctica |
| `lib/features/cancha/presentation/widgets/court_painter.dart` | ✅ Activo | Painter de cancha (práctica) |
| `lib/features/cancha/presentation/widgets/position_slot.dart` | ✅ Activo | Slot de posición en cancha |
| `lib/features/cancha/presentation/widgets/rotation_timeline.dart` | ✅ Activo | Timeline de rotaciones |
| `lib/features/cancha/data/court_models.dart` | ✅ Activo | Modelos: PlayerAssignment, RotationRecord, PositionEvent |
| `lib/features/estadisticas/data/models/player.dart` | ✅ Activo | Modelo Player |
| `lib/features/estadisticas/data/models/match.dart` | ✅ Activo | Modelo Match + enums |
| `lib/features/estadisticas/data/models/stat_event.dart` | ✅ Activo | Modelo StatEvent + enums |
| `lib/features/estadisticas/data/models/attendance_record.dart` | ✅ Activo | Modelo AttendanceRecord |
| `lib/features/estadisticas/data/models/season.dart` | ✅ Activo | Modelo Season |
| `lib/features/estadisticas/data/local_db/database_service.dart` | ✅ Activo | DB Sembast central (912 líneas) |
| `lib/features/estadisticas/data/repositories/match_repository.dart` | ✅ Activo | Repositorio de partidos |
| `lib/features/estadisticas/data/repositories/player_repository.dart` | ✅ Activo | Repositorio de jugadores |
| `lib/features/estadisticas/data/repositories/stat_event_repository.dart` | ✅ Activo | Repositorio de eventos |
| `lib/features/estadisticas/domain/services/stats_calculator.dart` | ✅ Activo | Cálculo de stats por jugador |
| `lib/features/estadisticas/domain/services/mvp_calculator.dart` | ✅ Activo | Cálculo de MVP |
| `lib/features/estadisticas/presentation/views/play_by_play_screen.dart` | ✅ Activo | Stats jugada por jugada |
| `lib/features/estadisticas/presentation/widgets/stat_recorder_widget.dart` | ✅ Activo | Grabador de eventos (estadisticas) |
| `lib/features/estadisticas/presentation/widgets/live_stats_widget.dart` | ✅ Activo | Widget de stats en vivo |
| `lib/features/asistencia/presentation/views/athlete_list_screen.dart` | ✅ Activo | Lista de atletas con filtros |
| `lib/features/asistencia/presentation/views/athlete_form_screen.dart` | ✅ Activo | Formulario crear atleta |
| `lib/features/asistencia/presentation/views/athlete_edit_screen.dart` | ✅ Activo | Editar atleta |
| `lib/features/asistencia/presentation/views/player_detail_screen.dart` | ✅ Activo | Detalle de atleta con stats |
| `lib/features/asistencia/presentation/views/attendance_screen.dart` | ✅ Activo | Control de asistencia |
| `lib/features/asistencia/presentation/views/attendance_history_screen.dart` | ✅ Activo | Historial de asistencia |
| `lib/features/asistencia/presentation/views/attendance_history_detail_screen.dart` | ✅ Activo | Detalle de asistencia por día |
| `lib/features/asistencia/data/attendance_service.dart` | ✅ Activo | Servicio de asistencia |
| `lib/features/settings/presentation/views/settings_screen.dart` | ✅ Activo | Pantalla de configuración |
| `lib/features/settings/presentation/viewmodels/settings_viewmodel.dart` | ✅ Activo | VM de configuración |
| `lib/features/settings/presentation/views/account_section.dart` | ✅ Activo | Sección cuenta |
| `lib/features/settings/presentation/views/club_section.dart` | ✅ Activo | Sección club |
| `lib/features/settings/presentation/views/profiles_section.dart` | ✅ Activo | Sección perfiles |
| `lib/features/settings/presentation/views/notifications_section.dart` | ✅ Activo | Sección notificaciones |
| `lib/features/settings/presentation/views/appearance_section.dart` | ⚠️ Parcial | Dark OK, Light/System deshabilitados |
| `lib/features/settings/presentation/views/sync_section.dart` | ✅ Activo | Sección sincronización |
| `lib/features/settings/presentation/views/database_section.dart` | ✅ Activo | Sección DB + huérfanos |
| `lib/features/sync/presentation/sync_viewmodel.dart` | ✅ Activo | VM de sincronización |
| `lib/features/sync/data/sync_service.dart` | ✅ Activo | Servicio de sync Firebase |
| `lib/features/profiles/presentation/viewmodels/profile_viewmodel.dart` | ✅ Activo | VM de perfiles |
| `lib/features/profiles/presentation/views/profiles_screen.dart` | ✅ Activo | Pantalla de perfiles |
| `lib/features/profiles/presentation/views/create_profile_screen.dart` | ✅ Activo | Crear perfil |
| `lib/features/profiles/data/profile_repository.dart` | ✅ Activo | Repositorio de perfiles |
| `lib/features/teams/presentation/viewmodels/club_viewmodel.dart` | ✅ Activo | VM de club (streams centrales) |
| `lib/features/teams/presentation/views/team_management_screen.dart` | ✅ Activo | Gestión de staff |
| `lib/features/teams/presentation/views/invite_member_screen.dart` | ✅ Activo | Invitar miembros |
| `lib/features/teams/presentation/views/create_club_screen.dart` | ✅ Activo | Crear club |
| `lib/features/teams/presentation/views/club_switcher.dart` | ✅ Activo | Selector de club |
| `lib/features/teams/presentation/views/invitation_banner.dart` | ✅ Activo | Banner de invitaciones |
| `lib/features/statistics/presentation/views/statistics_screen.dart` | ✅ Activo | Dashboard de estadísticas |
| `lib/features/statistics/presentation/views/athlete_statistics_screen.dart` | ✅ Activo | Stats por atleta |
| `lib/features/notifications/presentation/viewmodels/notification_viewmodel.dart` | ✅ Activo | VM de notificaciones |
| `lib/features/notifications/presentation/views/notifications_screen.dart` | ✅ Activo | Pantalla de notificaciones |
| `lib/features/notifications/presentation/views/notification_bell.dart` | ✅ Activo | Campanita en sidebar |
| `lib/core/config.dart` | ✅ Activo | AppConfig.useFirebase flag |
| `lib/core/services/service_locator.dart` | ⚠️ Parcial | _dataService nunca registrado |
| `lib/core/services/google_auth_service.dart` | ✅ Activo | Google Sign-In local |
| `lib/core/services/club_data_service.dart` | ⚠️ Gateado | Dual-write Firebase (solo si useFirebase) |
| `lib/core/theme_provider/theme_notifier.dart` | ✅ Activo | Cambio de tema |
| `lib/core/widgets_globales/route_transitions.dart` | ✅ Activo | Transiciones slide/fade |

### 8.2 Widgets Stale / Dead Code

| Archivo | Estado | Función original |
|---------|--------|-----------------|
| `lib/features/partido/presentation/views/player_selection_screen.dart` | ❌ Stale | Selección de jugadores (reemplazado por MatchStartDialog) |
| `lib/features/partido/presentation/widgets/rotation_widget.dart` | ❌ Stale | Visualización de rotación (reemplazado por FullCourtWidget) |
| `lib/features/partido/presentation/widgets/action_buttons_widget.dart` | ❌ Stale | Botones de acción (integrados en MatchScreen) |
| `lib/features/partido/presentation/widgets/roster_management_sheet.dart` | ❌ Stale | Gestión de roster (manejado en MatchStartDialog) |
| `lib/features/partido/presentation/widgets/stat_recorder_widget.dart` | ❌ Stale | Grabador de stats (superseded por estadisticas) |
| `lib/features/estadisticas/presentation/widgets/stats_charts_widget.dart` | ❌ Stale | Gráficos de stats (sin uso) |
| `lib/features/estadisticas/presentation/views/live_stats_dashboard_screen.dart` | ⚠️ Sin ruta | Dashboard de stats en vivo (navegación no conectada) |
| `lib/features/estadisticas/presentation/viewmodels/play_by_play_viewmodel.dart` | ⚠️ Parcial | VM con secciones sin implementar |
| `lib/features/settings/data/settings_models.dart` | ❌ Stale | AppThemeMode enum nunca usado |
| `lib/features/settings/presentation/widgets/settings_drawer.dart` | ⚠️ Legacy | Drawer de configuración duplicado |
| `lib/features/admin/presentation/views/admin_screen.dart` | ⚠️ Redundante | Wrapper puro de SettingsScreen |
| `lib/features/atleta/` | 📁 Vacío | Feature planeada sin contenido |

---

## 9. FLUTTER ANALYZE

```
> dart analyze lib/

314 issues found.

0 errors
0 warnings
314 info
```

**Desglose de info-level issues:**
- `avoid_print` — logs intencionales 🔵🟢🔴 en SyncService y SyncSection
- `prefer_const_constructors` — widgets sin const (pre-existentes)
- `prefer_const_literals_to_create_immutables` — literales sin const
- `use_build_context_synchronously` — uso de context tras async gaps

0 errores, 0 warnings. Todos los issues son info-level.

---

*Fin de PROJECT_STATE.md — 19/06/2026*

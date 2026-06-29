# DASHBOARD FORENSIC AUDIT

## 1. REAL NAVIGATION TREE

```
AppShell (app_shell.dart)
  ├─ _ProfileCoordinator (wraps all screens, propagates profile changes)
  │   └─ Listeners: DashboardViewModel.setProfile(), ClubViewModel.setProfileFilter()
  │
  ├─ Mobile layout (width < 768):
  │   ├─ AppBar (Libero360 logo + NotificationBell + ClubSwitcher + ProfileSelector + user menu)
  │   └─ BottomNavigationBar
  │       └─ index 0 → DashboardScreen ← EL PUNTO DE ENTRADA
  │
  ├─ Desktop layout (width >= 768):
  │   ├─ Sidebar (220px, nav items + ClubSwitcher + ProfileSelector + NotificationBell + user)
  │   └─ Main area → DashboardScreen
  │
  └─ DashboardScreen (dashboard_screen.dart:28, StatefulWidget)
       ├─ State: _load() calls 4 providers, sets up Sembast streams + StatEventBus
       │
       ├─ AnimatedSwitcher (skeleton ↔ dashboard ↔ error)
       │
       ├─ Skeleton: DashboardSkeleton (5 shimmer blocks, 169 lines)
       │
       ├─ Error: _errorState (inline, icon + message + retry)
       │
       └─ Dashboard (CustomScrollView, 10 slivers):
            ├─ HeaderSection           (wrapped: AnimatedSection + ValueListenableBuilder)
            │   ├─ Greeting text
            │   ├─ NotificationBell
            │   ├─ Settings button → AdminScreen
            │   ├─ Team avatar + name + category + age group + member count + role
            │   └─ ProfileSelector
            │
            ├─ MainCardSection         (wrapped: AnimatedSection + AnimatedCard + ValueListenableBuilder)
            │   ├─ "Próximos Eventos"
            │   ├─ NextTraining tile
            │   ├─ NextMatch tile
            │   ├─ Countdown (days + hours)
            │   └─ "Ver detalles" button → onPressed: () {}   ← NO HACE NADA
            │
            ├─ AthleteOfMonthCard      (wrapped: AnimatedSection + AnimatedCard + ValueListenableBuilder)
            │   ├─ "Atleta del Mes"
            │   ├─ Avatar + name + position + category
            │   ├─ MVP badge + Eficiencia badge
            │   └─ "Ver estadísticas" → StatisticsScreen
            │
            ├─ QuickSummaryGrid        (wrapped: AnimatedSection + AnimatedCard + ValueListenableBuilder)
            │   ├─ 2×2 grid: Atletas, Partidos, Winrate, Entrenamientos
            │   └─ Each tile: onTap: () {}   ← NO HACE NADA
            │
            ├─ TeamStatusSection       (wrapped: AnimatedSection + AnimatedCard + ValueListenableBuilder)
            │   ├─ 2×2 grid: Reposo médico, Ausencias, Racha, MVP actual
            │   └─ Each tile: onTap: () {}   ← NO HACE NADA
            │
            ├─ LastMatchBanner         (wrapped: AnimatedSection + AnimatedCard + ValueListenableBuilder)
            │   ├─ Gradient banner (win=green, loss=red), fixed height 200
            │   ├─ Rival name + score
            │   ├─ Competition + date
            │   └─ "Ver resumen" → StatisticsScreen
            │
            ├─ RecentActivityTimeline  (wrapped: AnimatedSection + ValueListenableBuilder)
            │   ├─ Max 5 items (match result, attendance, medical leave)
            │   └─ Timeline UI with icons + description + timeAgo
            │
            ├─ QuickAccessRow          (wrapped: AnimatedSection + ValueListenableBuilder)
            │   ├─ Horizontal scroll: Atletas, Partido, Estadísticas, Asistencia, Analytics, PDF, Staff
            │   └─ Each: pushSlide(screen)
            │
            └─ _buildEmptyStates
                ├─ "No hay atletas" → AthleteListScreen  (if athleteCount == 0)
                └─ "No hay partidos" → PlayByPlayScreen  (if athleteCount > 0 && matchCount == 0)
```

**Nota**: `NotificationsSheet` (`notifications_sheet.dart`) está definido pero NO importado ni usado por nadie.

---

## 2. DATA ORIGIN MAP

| Dato | Fuente | Cómo llega |
|------|--------|------------|
| **Nombre del club** | `ClubViewModel.currentClub.name` → Firebase Firestore | `dashboard_screen.dart:56` → `DashboardViewModel.load()` |
| **Miembros del club** | `ClubViewModel.memberCount` → Firebase Firestore | `dashboard_screen.dart:58` → `DashboardViewModel.load()` |
| **Jugadores (players)** | `DatabaseService` → **Sembast** | `DashboardRepository.load()` → `_db.getPlayersByProfile()` / `_db.getAllPlayers()` |
| **Partidos** | `DatabaseService` → **Sembast** | `DashboardRepository.load()` → `_db.getAllMatches()` |
| **Asistencia** | `DatabaseService` → **Sembast** | `DashboardRepository.load()` → `_db.getAllAttendanceRecords()` |
| **Rankings** | `AthleteRankingService.loadRankings()` → en memoria, desde Sembast | `DashboardRepository.load()` |
| **Reposo médico** | `MedicalLeaveRepository` → **Sembast** | `DashboardRepository.load()` → `_medicalRepo.getActive()` |
| **Categorías** | `CategoryService` → **Sembast** | `DashboardRepository.load()` → `_catService.load()` |
| **User / Auth** | `AuthViewModel` → Firebase Auth | `dashboard_screen.dart:169` |
| **Profile ID** | `ProfileViewModel.currentProfile.id` | `dashboard_screen.dart:55` (from SharedPreferences via ProfileService) |
| **Rol del usuario** | `ClubViewModel.myRole` → Firebase Firestore | `dashboard_screen.dart:183` |
| **Avatar del atleta** | `Player.fotoUrl` → Firebase Storage (URL) | `athlete_of_month_card.dart:57` (NetworkImage) |
| **Foto del club** | `TeamInfo.photoUrl` → nunca se setea | Siempre `null` en `_buildTeamInfo()` |

**Conclusión**: El Dashboard lee de **3 fuentes diferentes**: Sembast (datos deportivos), Firebase Firestore (club, miembros, roles), Firebase Auth (usuario), SharedPreferences (profile vía ProfileViewModel). No hay un único punto de verdad.

---

## 3. WHAT NEVER EXECUTES (DEAD CODE)

| Archivo | Problema | Razón |
|---------|----------|-------|
| **`notifications_sheet.dart`** | 🎯 **COMPLETAMENTE MUERTO** | `NotificationsSheet` existe (197 líneas, 3 notificaciones hardcodeadas) pero **nadie lo importa ni lo usa**. 0 referencias en todo el código. Es un residuo de una versión anterior. |
| **`AnimatedStaggeredSection`** (dentro de `animated_section.dart:49-99`) | 🎯 **MUERTO** | Clase definida y exportada pero **nunca instanciada** en ninguna pantalla. |

**Total: 1 archivo muerto + 1 clase muerta dentro de un archivo vivo.**

---

## 4. COMPONENT STATUS TABLE

| Componente | Archivo | Estado | Líneas |
|------------|---------|--------|--------|
| DashboardScreen | `views/dashboard_screen.dart` | ✅ ACTIVO (punto de entrada) | 435 |
| DashboardViewModel | `viewmodels/dashboard_viewmodel.dart` | ✅ ACTIVO (Provider global) | 178 |
| DashboardRepository | `data/dashboard_repository.dart` | ✅ ACTIVO | 237 |
| DashboardData (model) | `data/dashboard_model.dart` | ✅ ACTIVO | 137 |
| DashboardSectionNotifier | `viewmodels/dashboard_viewmodel.dart` | ✅ ACTIVO (8 instancias) | 4 |
| HeaderSection | `widgets/header_section.dart` | ✅ ACTIVO | 129 |
| MainCardSection | `widgets/main_card_section.dart` | ✅ ACTIVO | 211 |
| AthleteOfMonthCard | `widgets/athlete_of_month_card.dart` | ✅ ACTIVO | 194 |
| QuickSummaryGrid | `widgets/quick_summary_grid.dart` | ✅ ACTIVO | 167 |
| TeamStatusSection | `widgets/team_status_section.dart` | ✅ ACTIVO | 170 |
| LastMatchBanner | `widgets/last_match_banner.dart` | ✅ ACTIVO | 197 |
| RecentActivityTimeline | `widgets/recent_activity_timeline.dart` | ✅ ACTIVO | 221 |
| QuickAccessRow | `widgets/quick_access_row.dart` | ✅ ACTIVO | 170 |
| DashboardSkeleton | `widgets/dashboard_skeleton.dart` | ✅ ACTIVO | 169 |
| AnimatedSection | `widgets/animated_section.dart` | ✅ ACTIVO | 47 |
| AnimatedCard | `widgets/animated_section.dart` | ✅ ACTIVO | 37 |
| AnimatedStaggeredSection | `widgets/animated_section.dart` | ❌ MUERTO | 51 |
| NotificationsSheet | `widgets/notifications_sheet.dart` | ❌ MUERTO | 197 |

**Total: 15 activos, 2 muertos.**

---

## 5. PER-SECTION AUDIT

### 5.1 HeaderSection
**Archivo**: `header_section.dart` (129 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| ✅ Saludo dinámico | Buenos días/tardes/noches según hora local |
| ✅ NotificationBell | Integrado, funcional |
| ✅ Settings → AdminScreen | Correcto |
| ✅ ProfileSelector | Integrado |
| ✅ Team info con rol | `memberCount` y `roleLabel` se muestran condicionalmente |
| ⚠️ `teamInfo.category` hardcodeado `'Masculino'` | Viene de `DashboardRepository._buildTeamInfo()` |
| ⚠️ `teamInfo.ageGroup` hardcodeado `'U17'` | Viene de `DashboardRepository._buildTeamInfo()` |
| ⚠️ `teamInfo.photoUrl` nunca se usa | El `CircleAvatar` no muestra foto del club |

### 5.2 MainCardSection
**Archivo**: `main_card_section.dart` (211 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| ✅ Muestra próximo entrenamiento + partido | Correcto |
| ✅ Countdown days/hours | Correcto |
| 🔴 **Botón "Ver detalles" no hace nada** | `onPressed: () {}` en línea 96 |
| ⚠️ `nextTraining` se infiere del día más común de asistencia | Heurística, no es un entrenamiento real |
| ⚠️ Empty state genérico "No hay eventos programados" | Sin CTA para crear evento |

### 5.3 AthleteOfMonthCard
**Archivo**: `athlete_of_month_card.dart` (194 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| ✅ Muestra atleta con avatar, nombre, posición, categoría | Correcto |
| ✅ Badges MVP + Eficiencia | Correcto |
| ✅ "Ver estadísticas" → StatisticsScreen | Correcto |
| ✅ Empty state con icono + texto | Correcto |
| ⚠️ `playerId` existe en el modelo pero no se usa para navegación | Podría navegar al perfil del atleta |

### 5.4 QuickSummaryGrid
**Archivo**: `quick_summary_grid.dart` (167 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| ✅ 4 tiles con datos: atletas, partidos, winrate, entrenamientos | Correcto |
| ✅ Hover/scale animation | Correcto |
| 🔴 **Cada tile tiene `onTap: () {}`** — no navega a ningún lado | UX perdida |
| ⚠️ `trainingCount` cuenta días con asistencia, no sesiones programadas | Puede ser engañoso |

### 5.5 TeamStatusSection
**Archivo**: `team_status_section.dart` (170 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| ✅ Muestra reposo médico, ausencias, racha, MVP | Correcto |
| ✅ Hover/scale animation | Correcto |
| 🔴 **Cada tile tiene `onTap: () {}`** — no navega a ningún lado | UX perdida |
| 🔴 **Cálculo de ausencias sospechoso**: `(recentAbsences ~/ 10).clamp(0, 99)` | Divide count por 10, posible bug |
| ⚠️ `absenceCount` label dice "ausencias" pero no es count exacto | Engañoso |

### 5.6 LastMatchBanner
**Archivo**: `last_match_banner.dart` (197 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| ✅ Gradient banner según resultado (verde/rojo) | Correcto |
| ✅ Score + rival + competición + fecha | Correcto |
| ✅ "Ver resumen" → StatisticsScreen | Correcto |
| ✅ Empty state con CTA "Jugar partido" | Correcto |
| ⚠️ Fixed height 200px | Puede romper en pantallas muy pequeñas |

### 5.7 RecentActivityTimeline
**Archivo**: `recent_activity_timeline.dart` (221 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| ✅ Timeline visual con iconos + descripción | Correcto |
| ✅ TimeAgo relativo | Correcto |
| ✅ Empty state bonito | Correcto |
| ⚠️ **Limitado a 5 items** (`take(5)`) | No hay "Ver más" ni paginación |
| ⚠️ Tipos de actividad limitados: match, training, medical | No muestra MVP changes, achievements, etc. |

### 5.8 QuickAccessRow
**Archivo**: `quick_access_row.dart` (170 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| ✅ 7 accesos directos funcionales | Correcto |
| ✅ Push animation con `pushSlide` | Correcto |
| ⚠️ **Items hardcodeados** en `static final _items` | No configurables por el usuario |
| ⚠️ "Staff" → AdminScreen, label podría ser "Configuración" | Confuso |
| ⚠️ "Analytics" y "PDF" → menos usados, ocupan espacio | Podrían estar en un submenú |

### 5.9 DashboardSkeleton
**Archivo**: `dashboard_skeleton.dart` (169 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| ✅ Shimmer animation correcta | ✅ |
| ✅ 5 bloques: header, card, card, grid, card | ✅ |
| ⚠️ No hay indicador de progreso real | Es solo shimmer |
| ⚠️ `AnimatedBuilder` envuelve todo el `ListView` | Reconstruye todo el skeleton en cada frame de animación |

### 5.10 AnimatedSection / AnimatedCard
**Archivo**: `animated_section.dart` (138 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| ✅ Slide + fade en initState | Correcto |
| ✅ Scale bounce en AnimatedCard | Correcto |
| 🔴 **AnimatedStaggeredSection: MUERTO** | 51 líneas de código no usado |
| ⚠️ AnimatedSection no se re-anima en data refresh | `_ctrl.forward()` solo en `initState`; sí se recrea el State cuando cambia el ValueNotifier |

### 5.11 NotificationsSheet
**Archivo**: `notifications_sheet.dart` (197 líneas)

| Aspecto | Hallazgo |
|---------|----------|
| 🔴 **ARCHIVO MUERTO** | No importado, no referenciado |
| ⚠️ 3 notificaciones hardcodeadas con emojis | Nunca se verán |
| ⚠️ Única referencia: `NotificationsSheet.show()` nunca llamado | El archivo existe pero no ejecuta |

---

## 6. PROBLEMS CATALOG

### 🔴 CRITICAL

| ID | Problema | Archivo | Línea |
|----|----------|---------|-------|
| C1 | **Botón "Ver detalles" no hace nada** | `main_card_section.dart` | 96 |
| C2 | **QuickSummary tiles sin navegación** | `quick_summary_grid.dart` | 114 |
| C3 | **TeamStatus tiles sin navegación** | `team_status_section.dart` | 131 |

### 🟡 HIGH

| ID | Problema | Archivo | Línea |
|----|----------|---------|-------|
| H1 | **Fallo en cálculo de ausencias**: `recentAbsences ~/ 10` | `dashboard_repository.dart` | 159 |
| H2 | **Hardcoded `category: 'Masculino'`** | `dashboard_repository.dart` | 62 |
| H3 | **Hardcoded `ageGroup: 'U17'`** | `dashboard_repository.dart` | 63 |
| H4 | **Hardcoded `clubName ?? 'Club Águilas'`** | `dashboard_repository.dart` | 61 |
| H5 | **NotificationsSheet: 197 líneas de dead code** | `notifications_sheet.dart` | 1-197 |
| H6 | **AnimatedStaggeredSection: 51 líneas de dead code** | `animated_section.dart` | 49-99 |
| H7 | **Activity Timeline limitado a 5 items, sin "Ver más"** | `dashboard_repository.dart` | 225 |

### 🟡 MEDIUM

| ID | Problema | Archivo | Línea |
|----|----------|---------|-------|
| M1 | **LastMatchBanner fixed height 200** — no responsive | `last_match_banner.dart` | 87 |
| M2 | **QuickAccessRow items hardcodeados** — no configurables | `quick_access_row.dart` | 65-73 |
| M3 | **No offline banner** cuando no hay conexión | `dashboard_screen.dart` | — |
| M4 | **No pull-to-refresh indicator visible** (solo el snackbar "Actualizando...") | `dashboard_screen.dart` | 121-160 |
| M5 | **TeamInfo.photoUrl nunca se usa** | `dashboard_repository.dart` | 59-66 |
| M6 | **Doble fuente de verdad**: ClubViewModel (Firebase) + DatabaseService (Sembast) tienen datos duplicados (jugadores, partidos, asistencia) | `club_viewmodel.dart` / `dashboard_repository.dart` | — |

### 🟢 LOW

| ID | Problema | Archivo | Línea |
|----|----------|---------|-------|
| L1 | **`athleteOfMonthCard` no navega al perfil del atleta** aunque tiene `playerId` | `athlete_of_month_card.dart` | 106-121 |
| L2 | **`trainingCount` cuenta días con registro de asistencia, no entrenamientos reales** | `dashboard_repository.dart` | 121 |
| L3 | **"Staff" en QuickAccess → AdminScreen**, label confuso | `quick_access_row.dart` | 72 |
| L4 | **No Hero animations** entre dashboard y detalle | — | — |
| L5 | **Skeleton shimmer redibuja todo el ListView en cada frame** | `dashboard_skeleton.dart` | 42 |

---

## 7. FIREBASE USAGE ANALYSIS

| Firebase Feature | Usado en | Propósito | Correcto |
|-----------------|----------|-----------|----------|
| **Firebase Auth** | `AuthViewModel`, `ClubViewModel.uid` | Autenticación de usuario | ✅ |
| **Firestore** — Club | `ClubService`, `ClubViewModel` | Club profile, members, roles | ✅ |
| **Firestore** — Invitations | `InvitationService` | Invitaciones a clubes | ✅ |
| **Firestore** — Notifications | `NotificationService` | Notificaciones push | ✅ |
| **Firestore** — Players, Matches, Attendance, etc. | `ClubViewModel` | Sincronización de datos deportivos | ❌ **REDUNDANTE** — estos mismos datos están en Sembast local. ClubViewModel subscribe a 10+ streams de Firestore, pero el Dashboard lee de Sembast. |
| **Firebase Storage** | `Player.fotoUrl` | Fotos de perfil de atletas | ✅ |

**Problema principal**: `ClubViewModel` (Firestore) y `DatabaseService` (Sembast) mantienen los mismos datos en paralelo. No hay un mecanismo claro de reconciliación. El Dashboard sólamente consume de Sembast, por lo que los streams de Firestore en `ClubViewModel` para athletes/matches/statEvents/attendance son redundantes para el Dashboard.

---

## 8. ARCHIVOS DEL DASHBOARD

### Archivos activos (14)

| # | Archivo | Líneas | Función |
|---|---------|--------|---------|
| 1 | `presentation/views/dashboard_screen.dart` | 435 | Pantalla principal |
| 2 | `presentation/viewmodels/dashboard_viewmodel.dart` | 178 | Estado + lógica |
| 3 | `data/dashboard_repository.dart` | 237 | Carga y transformación de datos |
| 4 | `data/dashboard_model.dart` | 137 | Modelos de datos |
| 5 | `presentation/widgets/header_section.dart` | 129 | Header |
| 6 | `presentation/widgets/main_card_section.dart` | 211 | Próximos eventos |
| 7 | `presentation/widgets/athlete_of_month_card.dart` | 194 | Atleta del mes |
| 8 | `presentation/widgets/quick_summary_grid.dart` | 167 | Resumen rápido |
| 9 | `presentation/widgets/team_status_section.dart` | 170 | Estado del equipo |
| 10 | `presentation/widgets/last_match_banner.dart` | 197 | Último partido |
| 11 | `presentation/widgets/recent_activity_timeline.dart` | 221 | Actividad reciente |
| 12 | `presentation/widgets/quick_access_row.dart` | 170 | Accesos rápidos |
| 13 | `presentation/widgets/dashboard_skeleton.dart` | 169 | Skeleton loading |
| 14 | `presentation/widgets/animated_section.dart` | 138 | Animaciones de entrada |

### Archivos muertos (2)

| # | Archivo | Líneas | Motivo |
|---|---------|--------|--------|
| 1 | `presentation/widgets/notifications_sheet.dart` | 197 | 0 imports, 0 referencias |
| 2 | `animated_section.dart` (AnimatedStaggeredSection) | 51 | Definido, nunca instanciado |

**Total dashboard: ~2,473 líneas de código activo + ~248 líneas de código muerto.**

---

## 9. PRIORITY FIX LIST

| Prioridad | Ítem | Esfuerzo | Impacto |
|-----------|------|----------|---------|
| 🔴 P0 | Botones sin acción (C1, C2, C3) — conectar navegación | Bajo | Medio |
| 🔴 P0 | Eliminar `notifications_sheet.dart` (dead code) | Mínimo | Mantenibilidad |
| 🟡 P1 | Corregir cálculo de ausencias `~/ 10` (H1) | Mínimo | Alto (datos incorrectos) |
| 🟡 P1 | Reemplazar hardcoded teamInfo (H2, H3, H4) con datos reales | Medio | Alto |
| 🟡 P1 | Agregar "Ver más" en Activity Timeline (H7) | Bajo | Medio |
| 🟡 P2 | Hacer LastMatchBanner responsive (M1) | Bajo | Bajo |
| 🟡 P2 | Agregar offline banner (M3) | Medio | Medio |
| 🟡 P2 | Eliminar AnimatedStaggeredSection (H6) | Mínimo | Mantenibilidad |
| 🟢 P3 | Navegación a perfil del atleta desde AthleteOfMonthCard (L1) | Bajo | Bajo |
| 🟢 P3 | QuickAccessRow configurable (M2) | Alto | Medio |
| 🟢 P3 | Hero animations entre dashboard y detalle (L4) | Medio | Bajo |

---

## 10. RECOMMENDED PLAN

### Fase 1 (inmediata, 3.2B)
1. Conectar botones sin acción (P0): MainCard "Ver detalles", QuickSummary tiles, TeamStatus tiles
2. Eliminar dead code: `notifications_sheet.dart`, `AnimatedStaggeredSection`
3. Corregir `absenceCount` bug: eliminar `~/ 10`
4. Agregar "Ver más" en Activity Timeline

### Fase 2 (corto plazo)
5. Reemplazar hardcoded teamInfo con datos reales desde `ClubViewModel`
6. Agregar offline banner
7. Hacer fix de responsive: LastMatchBanner height

### Fase 3 (mediano plazo)
8. QuickAccessRow dinámico/editable
9. Hero animations
10. Navegación a perfil desde AthleteOfMonthCard

### Fase 4 (arquitectura)
11. Reconciliar doble fuente de verdad (Firestore vs Sembast)
12. Unificar data layer del dashboard con un solo repositorio que sincronice Firestore → Sembast

---

## 11. FILES NOT MODIFIED

This audit was read-only. No files were created or modified in `lib/`.
`DASHBOARD_FORENSIC_AUDIT.md` is a new file in the project root.

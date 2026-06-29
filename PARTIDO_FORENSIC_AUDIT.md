# PARTIDO FORENSIC AUDIT

## 1. REAL NAVIGATION TREE

```
BottomNavigationBar (AppShell._buildBottomNav)
  ↕ index 2 ("Partidos")
  ↓
_MatchLauncherPlaceholder (app_shell.dart:39, PRIVATE, inside AppShell)
  ↓ Botón "Nuevo Partido"
MatchStartDialog (modal dialog)
  ↓ Navigator.push
  MatchScreen (match_screen.dart — the NEW refactored version)
    ├─ Tab 0: Juego
    │   ├─ MatchHeader
    │   ├─ MatchScoreBoard  ← nota: clase se llama MatchScoreBoard (B mayúscula)
    │   ├─ TimeoutIndicator ×2
    │   ├─ CourtWidget
    │   │   └─ CourtPainter (partido module version)
    │   ├─ ServiceWidget
    │   ├─ ServiceHistorySheet (modal)
    │   ├─ MatchTimelineSheet (modal)
    │   ├─ QuickStatsWidget
    │   └─ PlayerActionAnim (overlay)
    ├─ Tab 1: Rotaciones
    │   └─ RotationTab
    │       └─ CourtWidget + rotation list
    └─ Tab 2: Pizarra
        └─ TacticalBoardWidget
```

**BottomNav does NOT lead directly to MatchScreen.** It leads to a private `_MatchLauncherPlaceholder` widget.

---

## 2. WHAT THE APP ACTUALLY USES

| Component | File | STATUS |
|-----------|------|--------|
| **MatchScreen** (nuevo) | `match_screen.dart` | ✅ **IMPLEMENTADO Y USADO** |
| MatchController | `match_controller.dart` | ✅ **ACTIVO** (provider global en main.dart) |
| PartidoViewModel | `partido_viewmodel.dart` | ✅ **ACTIVO** (creado dentro de MatchScreen) |
| RotationManager | `rotation_data.dart` | ✅ **ACTIVO** (en MatchScreen + RotationTab) |
| LiberoManager | `libero_manager.dart` | ✅ **ACTIVO** (en MatchScreen) |
| CourtWidget | `court_widget.dart` | ✅ **ACTIVO** (en MatchScreen + RotationTab) |
| CourtPainter | `court_painter.dart` | ✅ **ACTIVO** (usado por CourtWidget) |
| CourtState | `court_state.dart` | ✅ **ACTIVO** |
| SetEndDialog | `set_end_dialog.dart` | ✅ **ACTIVO** |
| MatchEndDialog | `match_end_dialog.dart` | ✅ **ACTIVO** |
| SetStartDialog | `set_start_dialog.dart` | ✅ **ACTIVO** |
| MatchTimelineSheet | `match_timeline_sheet.dart` | ✅ **ACTIVO** |
| QuickStatsWidget | `quick_stats_widget.dart` | ✅ **ACTIVO** |
| RotationTab | `rotation_tab.dart` | ✅ **ACTIVO** |
| RotationHistoryWidget | `rotation_history_widget.dart` | ✅ **ACTIVO** |
| ServiceWidget | `service_widget.dart` | ✅ **ACTIVO** |
| ServiceHistorySheet | `service_history_sheet.dart` | ✅ **ACTIVO** |
| SubstitutionDialog | `substitution_dialog.dart` | ✅ **ACTIVO** |
| TimeoutOverlay | `timeout_overlay.dart` | ✅ **ACTIVO** |
| TimeoutIndicator | `timeout_indicator.dart` | ✅ **ACTIVO** |
| TimeoutService | `timeout_service.dart` | ✅ **ACTIVO** |
| PlayerActionAnim | `player_action_anim.dart` | ✅ **ACTIVO** |
| PlayerActionSheet | `player_action_sheet.dart` | ✅ **ACTIVO** |
| PlayerStatsCard | `player_stats_card.dart` | ✅ **ACTIVO** |
| PlayersDrawer | `players_drawer.dart` | ✅ **ACTIVO** |
| LiberoSheet | `libero_sheet.dart` | ✅ **ACTIVO** |
| TacticalBoardWidget | `tactical_board_widget.dart` | ✅ **ACTIVO** |
| MatchHeader | `match_header.dart` | ✅ **ACTIVO** |
| MatchScoreBoard | `match_scoreboard.dart` | ✅ **ACTIVO** |
| MatchStartDialog | `match_start_dialog.dart` | ✅ **ACTIVO** |
| MatchEvent | `match_event.dart` | ✅ **ACTIVO** |
| MatchEndRecord | `match_end_record.dart` | ✅ **ACTIVO** |
| SetEndRecord | `set_end_record.dart` | ✅ **ACTIVO** |
| TimelineEvent | `timeline_event.dart` | ✅ **ACTIVO** |
| PlayerAction / ActionType | `player_action.dart` | ✅ **ACTIVO** |
| SubstitutionRecord | `substitution_record.dart` | ✅ **ACTIVO** |
| MatchConfig | `match_config.dart` | ✅ **ACTIVO** |
| LiberoConfig | `libero_config.dart` | ✅ **ACTIVO** |
| TimeoutRecord | `timeout_event.dart` | ✅ **ACTIVO** |

---

## 3. WHAT NEVER EXECUTES (DEAD CODE)

| Archivo | Problema | Razón |
|---------|----------|-------|
| **`match_screen_legacy.dart`** | 🎯 **COMPLETAMENTE MUERTO** | Archivo completo (910 líneas) con clase `MatchScreen` duplicada. **Nadie lo importa.** La refactorización lo dejó inservible. |
| **`full_court_widget.dart`** | 🎯 **MUERTO** | Solo referenciado desde `match_screen_legacy.dart` (muerto). |
| **`player_stats_dialog.dart`** | 🎯 **MUERTO** | Solo referenciado desde `match_screen_legacy.dart` (muerto). |
| **`scoreboard_widget.dart`** | 🎯 **MUERTO** | Solo referenciado desde `match_screen_legacy.dart` (muerto). |
| **`substitution_history.dart`** | 🎯 **MUERTO** | Nadie lo importa ni referencia. |
| **`service_history_widget.dart`** | 🎯 **MUERTO** | Nadie lo importa ni referencia. |

**Total: 6 archivos muertos** (1 screen completo + 4 widgets + 1 placeholder widget).

---

## 4. ARCHIVOS DUPLICADOS

| Clase | Ubicación 1 | Ubicación 2 | Problema |
|-------|-------------|-------------|----------|
| **`CourtPainter`** | `partido/presentation/widgets/court_painter.dart` (74 líneas) | `cancha/presentation/widgets/court_painter.dart` (147 líneas) | ⚠️ Duplicado. Cada módulo tiene su propia implementación. No hay conflicto de imports porque están en módulos distintos. |
| **`MatchScreen`** | `match_screen.dart` (NUEVO, 1234 líneas) | `match_screen_legacy.dart` (VIEJO, 910 líneas) | 🔴 **PELIGRO**: Mismo nombre de clase, mismo paquete. El barrel y los imports apuntan a la nueva versión. La legacy NO se importa, pero si alguien la importa por error, hay conflicto. |

**Riesgo**: `match_screen_legacy.dart` debe ser eliminado. Si algún día alguien hace
`import 'match_screen_legacy.dart'` en vez de `import 'match_screen.dart'`, el
compilador no lo detectará como error, pero cargará la versión antigua.

---

## 5. NUEVOS COMPONENTES — STATUS REAL

| Componente | Esperado | Realidad |
|------------|----------|----------|
| MatchScreen nuevo | ✅ EN USO | Se usa desde MatchStartDialog |
| RotationManager | ✅ EN USO | Creado en MatchScreen.initState |
| LiberoManager | ✅ EN USO | Creado si config.liberoConfig.hasLiberos |
| SetEndDialog | ✅ EN USO | Mostrado al terminar cada set |
| SetStartDialog | ✅ EN USO | Mostrado al iniciar cada set |
| MatchTimelineSheet | ✅ EN USO | Modal "Crónica completa" |
| QuickStatsWidget | ✅ EN USO | En tab Juego |
| CourtWidget (nueva cancha) | ✅ EN USO | En tab Juego + RotationTab |
| RotationTab | ✅ EN USO | Tab 1 |
| TacticalBoardWidget | ✅ EN USO | Tab 2 (Pizarra) |
| ServiceWidget | ✅ EN USO | En tab Juego |
| ServiceHistorySheet | ✅ EN USO | Modal de historial |
| SubstitutionDialog | ✅ EN USO | Al sustituir jugador |
| TimeoutOverlay | ✅ EN USO | Overlay de timeout |
| TimeoutIndicator | ✅ EN USO | Indicadores de timeout |
| PlayerActionAnim | ✅ EN USO | Animación de acción |
| PlayerActionSheet | ✅ EN USO | BottomSheet de acciones |
| PlayerStatsCard | ✅ EN USO | Diálogo de stats por jugador |
| PlayersDrawer | ✅ EN USO | EndDrawer en MatchScreen |
| LiberoSheet | ✅ EN USO | BottomSheet de cambio líbero |
| RotationHistoryWidget | ✅ EN USO | Modal historial rotaciones |
| MatchScoreBoard | ✅ EN USO | Marcador en tab Juego |
| MatchHeader | ✅ EN USO | Encabezado en tab Juego |

---

## 6. ¿POR QUÉ EL USUARIO SIGUE VIENDO LA INTERFAZ ANTIGUA?

**Respuesta: Porque la pestaña "Partido" en el BottomNavigationBar NO abre MatchScreen.**

El flujo real es:

```
Botón "Partidos" en BottomNav
    ↓
_MatchLauncherPlaceholder      ← PLACEHOLDER ESTÁTICO
    ↓ (toca "Nuevo Partido")
MatchStartDialog               ← DIÁLOGO DE CONFIGURACIÓN
    ↓ (configura y confirma)
Navigator.push
    ↓
MatchScreen (nuevo)            ← REFACTORIZACIÓN SÍ SE USA
```

**Problema #1**: `_MatchLauncherPlaceholder` es un widget privado definido DENTRO de `app_shell.dart`. No tiene acceso a partidos guardados, no muestra historial, no tiene lista de partidos activos. Es solo una pantalla con dos botones. El usuario ve esto y piensa que nada cambió.

**Problema #2**: `_MatchLauncherPlaceholder` usa estilos hardcodeados (Colores, paddings, etc.) con la misma apariencia de siempre. No hay diferencia visual entre antes y después porque este placeholder nunca fue refactorizado.

**Problema #3**: La refactorización SÍ está conectada — PERO solo se ve dentro de `MatchScreen`, navegando DESPUÉS del diálogo. El camino más visible (la pestaña) nunca fue actualizado para mostrar MatchScreen o lista de partidos.

---

## 7. ARCHIVOS PARA ELIMINAR

| Prioridad | Archivo | Líneas | Motivo |
|-----------|---------|--------|--------|
| 🔴 ALTA | `match_screen_legacy.dart` | 910 | Clase duplicada, 0 imports, reemplazada por match_screen.dart |
| 🔴 ALTA | `full_court_widget.dart` | 306 | Solo usado por legacy screen (muerto) |
| 🔴 ALTA | `player_stats_dialog.dart` | 117 | Solo usado por legacy screen (muerto) |
| 🔴 ALTA | `scoreboard_widget.dart` | 162 | Solo usado por legacy screen (muerto) |
| 🟡 MEDIA | `substitution_history.dart` | 35 | Nunca referenciado |
| 🟡 MEDIA | `service_history_widget.dart` | 26 | Nunca referenciado |

---

## 8. ARCHIVOS PARA REEMPLAZAR / REPARAR

| Archivo | Acción |
|---------|--------|
| `app_shell.dart` (líneas 39, 470-533) | Reemplazar `_MatchLauncherPlaceholder` por `MatchScreen` directamente, o mejor: un `MatchListScreen` que muestre partidos guardados y permita iniciar nuevo |
| `partido.dart` (barrel) | Sin cambios (exporta correctamente match_screen.dart) |

---

## 9. CORRECCIÓN DE NOMBRES

| Archivo | Clase actual | Debería ser | Afecta |
|---------|-------------|-------------|--------|
| `match_scoreboard.dart` | `MatchScoreBoard` (B mayúscula) | `MatchScoreboard` | Inconsistencia menor con el nombre del archivo |
| `timeout_event.dart` | `TimeoutRecord` | Renombrar archivo a `timeout_record.dart` | Engañoso: el archivo se llama `_event` pero define `Record` |
| `player_action.dart` | `ActionType` enum + `PlayerActionEvent` | El archivo no tiene clase `PlayerAction` | El nombre `player_action` es OK para el enum, pero engañoso |

---

## 10. COMPONENTES MAL CONECTADOS O FALTANTES

| Componente | Estado |
|------------|--------|
| **Lista de partidos guardados** | ❌ **NO IMPLEMENTADO** — No hay pantalla que muestre partidos activos o historial de partidos. `_MatchLauncherPlaceholder` solo tiene botones de "Nuevo Partido" y "Cancha de práctica". |
| **Editar partido existente** | ❌ **NO IMPLEMENTADO** — Solo se puede crear partido nuevo desde el placeholder. No hay forma de reanudar un partido guardado. |
| **Resumen post-partido** | ⚠️ **PARCIAL** — MatchEndDialog existe y se muestra, pero el botón "Ver estadísticas" tiene `TODO`. |
| **Persistencia de RotationStats** | ✅ **IMPLEMENTADO** — `_persistRotationStats()` se llama al finalizar partido. |

---

## 11. FLUJO RECOMENDADO (para arreglar)

```
BottomNavigationBar "Partidos"
    ↓
MatchListScreen (NUEVO)          ← Lista de partidos activos + historial
    ├─ "Nuevo Partido" → MatchStartDialog → MatchScreen (nuevo)
    ├─ "Reanudar" → MatchScreen (nuevo, cargando match existente)
    └─ "Ver detalle" → MatchSummaryScreen (NUEVO, con stats, timeline, etc.)
```

---

## 12. FILES NOT MODIFIED

This audit was read-only. No files were created or modified in `lib/`.
`PARTIDO_FORENSIC_AUDIT.md` is a new file in the project root.

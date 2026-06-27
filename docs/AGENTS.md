# Libero360 — AGENTS.md (Anchored Summary)

## Goal
Auditar y corregir la capa de persistencia; crear NameFormatter global; refinar Dashboard visualmente; extender BackupService con SharedPreferences.

## Constraints & Preferences
- Material 3, dark/light theme, responsive (Android, Web, Windows)
- Clean architecture: Model → Repository → ViewModel → Screen → Widgets
- No UI/DB/logic mixing
- Firebase Firestore for clubs/members/invitations/notifications; sembast for local data
- Todos los cambios deben pasar `flutter analyze` con 0 errores, 0 warnings
- Retrocompatibilidad: valores por defecto para backups antiguos

## Progress
### Done
- **FASE UX 1.0A — NameFormatter global**: Creado `NameFormatter` en `lib/core/utils/name_formatter.dart`. Métodos: `playerFullName()`, `playerDisplayName()`, `playerShortName()`, `playerMatchName()`, `avatarInitial()`, `formatDisplayName()`, `formatShortName()`, `formatInitial()`. Actualizados ~40 archivos en Partido (matchName), Atletas (displayName/fullName), Dashboard (displayName), Estadísticas (displayName), Rankings (displayName), Asistencia (displayName/fullName), Cancha (displayName). Avatares usan `avatarInitial()`. Logs: 🔵 NAME FORMATTER, 🟢 NAME DISPLAY UPDATED en ViewModels.
- **FASE DASHBOARD 3.2 — Refinamiento Visual Profesional**: Skeleton convertido a StatefulWidget con shimmer animado (1500ms fade-in-out). AnimatedSection: 400ms con fade+slide+easeOutQuint. AnimatedCard: 350ms easeOutQuint. AnimatedStaggeredSection: 60ms delay. Header: greeting con constrainedBox, shield icon primary color. MainCard: BoxShadow + countdown mejorado. QuickSummary: BoxShadow + emoji 24px. TeamStatus: BoxShadow + iconos 24px. LastMatchBanner: BoxShadow + decoración sutil. QuickAccess: press animation scale 0.95→1.0. Timeline: iconos 40px, spacing mejorado. Logs: 🔵 DASHBOARD RENDER, 🟢 DASHBOARD READY, 🔴 DASHBOARD ERROR.
- **FASE BACKUP 2.0 — Respaldo Completo**: BackupService extendido para incluir SharedPreferences (`appSettings` en JSON). `createBackup()` exporta todas las keys de SP. `restoreBackup()` restaura SP post-DB-import con type checking. Backups antiguos sin `appSettings` usan valores por defecto. Logs: 🔵 BACKUP SETTINGS, 🟢 SETTINGS RESTORED, 🔴 SETTINGS NOT FOUND.
- **FASE DATABASE 1.0 — Auditoría Completa**: 19 modelos auditados, 6 bugs corregidos (4 DATA LOSS: competitionName, medicalLeaves, staff, categories). `DATABASE_AUDIT.md` generado. Logs en BackupService/SettingsRepository.
- **FASE ATLETAS 3.2A a 3.4, DASHBOARD 4.0A** (completadas en sesiones anteriores)

### In Progress
- (none)

### Blocked
- (none)

## Key Decisions
- `NameFormatter` tiene métodos Player-specific y String-based (para StaffMember, AppUser, ClubMember)
- Partido usa `playerMatchName()` (PrimerNombre + inicial Apellido)
- Listas/Stats/Dashboard/Rankings usan `playerDisplayName()` (PrimerNombre + PrimerApellido)
- Ficha/Detalle usan `playerFullName()` (todos los nombres)
- Dashboard skeleton con AnimationController real (no estático)
- Backup JSON incluye sección `appSettings` con SharedPreferences key-value
- Settings se restauran DESPUÉS de DB import (orden: primero datos, luego preferencias)
- Backups antiguos sin `appSettings` son compatibles (se ignora la sección faltante)

## Relevant Files
### UX 1.0A — NameFormatter
- `lib/core/utils/name_formatter.dart`: fullName, displayName, shortName, matchName, avatarInitial, formatDisplayName, formatShortName, formatInitial
- ~40 archivos actualizados en todas las features

### DASHBOARD 3.2 — Visual
- `lib/features/dashboard/presentation/views/dashboard_screen.dart`: logs 🔵🟢🔴
- `lib/features/dashboard/presentation/widgets/dashboard_skeleton.dart`: shimmer animado
- `lib/features/dashboard/presentation/widgets/animated_section.dart`: fade+slide, easeOutQuint
- `lib/features/dashboard/presentation/widgets/header_section.dart`: constrainedBox, primary color
- `lib/features/dashboard/presentation/widgets/main_card_section.dart`: BoxShadow, countdown mejorado
- `lib/features/dashboard/presentation/widgets/quick_summary_grid.dart`: BoxShadow, emoji 24px
- `lib/features/dashboard/presentation/widgets/team_status_section.dart`: BoxShadow, iconos 24px
- `lib/features/dashboard/presentation/widgets/last_match_banner.dart`: BoxShadow, decoración sutil
- `lib/features/dashboard/presentation/widgets/quick_access_row.dart`: press animation scale
- `lib/features/dashboard/presentation/widgets/recent_activity_timeline.dart`: iconos 40px, spacing

### BACKUP 2.0 — Settings
- `lib/features/settings/data/backup_service.dart`: export/import SharedPreferences vía `appSettings` en JSON
- `lib/features/estadisticas/data/local_db/database_service.dart`: exportToJson/importFromJson (sin cambios, solo usado por BackupService)

### DATABASE 1.0 — Auditoría
- `DATABASE_AUDIT.md`: Reporte completo de 19 modelos auditados, 6 bugs corregidos

**flutter analyze: 0 errores, 0 warnings** (8 warnings pre-existentes en archivos no modificados)

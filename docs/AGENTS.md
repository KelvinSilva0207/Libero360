# Libero360 — AGENTS.md (Anchored Summary)

## Goal
Maintain and improve Libero360 — dashboard fixes, theme personalization, club management, Google Drive backup.

## Constraints & Preferences
- Material 3, dark/light theme, responsive (Android, Web, Windows)
- Clean architecture: Model → Repository → ViewModel → Screen → Widgets
- No UI/DB/logic mixing
- Firebase Firestore for clubs/members/invitations/notifications; sembast for local data
- Todos los cambios deben pasar `flutter analyze` con 0 errores, 0 warnings
- **CLUB 3.1**: botón Crear Club independiente; validar nombre y URL; guardar en Firestore; loading infinito corregido
- **BACKUP 2.0**: Google Sign-In, subir/restaurar JSON a Drive, metadata (fecha, tamaño, versión, checksum), validar integridad

## Progress
### Done
- **DASHBOARD 3.2B** — 6 fixes aplicados (navegación mainCard/quickSummary/teamStatus, hardcoded data eliminado, absenceCount corregido, logs)
- **DASHBOARD 3.2A** — `DASHBOARD_FORENSIC_AUDIT.md` escrito
- **PERSONALIZACIÓN 2.0** — Light Theme completo (selector activado + 11 temas de componente faltantes agregados)
- **CLUB 3.1 — Corrección completa de gestión de Club**:
  1. **ClubService**: validación de nombre (min 3, max 50), chequeo de duplicados por owner, logs 🟢/🔴
  2. **ClubViewModel**: `createClub()` con `on Exception catch` (no genérico), `syncClubData()` que propaga a SyncService, logging con emojis
  3. **CreateClubScreen**: validación inline de nombre (min 3/max 50), validación de URL de foto, errores con `SnackBar` rojo
  4. **ClubSection**: botón independiente "Crear Club" agregado (antes solo en dialog); removido del switcher dialog
  5. **ClubSyncService**: sync methods reales (`syncAthletes`, `syncAttendance`, `syncMatches`, `syncStatistics`, `syncAll`) conectados a `SyncService`
- **BACKUP 2.0 — Google Drive Backup**:
  1. **GoogleDriveService**: sign-in con scope `drive.file`, upload multipart, download, list backups, checksum verification, app folder creation
  2. **BackupService**: Drive upload automático tras backup local, restore desde Drive con confirmación, validación de checksum SHA-256 antes de importar, metadata completa (cuenta, fecha, tamaño, versión, checksum)
  3. **DriveBackupSection UI**: estado de conexión, metadata del último backup (cuenta, fecha, tamaño, versión, checksum), botones Conectar/Desconectar/Subir/Restaurar, indicadores de loading
  4. **SettingsScreen**: sección "Google Drive" agregada después de Sincronización
  5. **pubspec.yaml**: `http: ^1.2.0` agregado como dependencia directa

### In Progress
- (none)

### Blocked
- (none)

## Key Decisions
- CLUB 3.1: `ClubService.nameExists()` verifica duplicados por `ownerId` + `name` (mismo dueño no puede crear dos clubs con mismo nombre)
- CLUB 3.1: `ClubViewModel.syncClubData()` llama a `SyncService.syncAll()` tras crear club — propaga a Dashboard (clubName/memberCount), Staff, Perfil
- BACKUP 2.0: Drive API v3 vía REST (no `googleapis` package pesado) — usa `GoogleSignInAccount.authHeaders` para auth + `http` para requests
- BACKUP 2.0: Multipart upload con metadata (checksum + version como `appProperties`) para verificación futura
- BACKUP 2.0: BackupService.restoreBackup() valida checksum del JSON completo antes de importar — si falla, no restaura y muestra error
- Logs: 🟢 Club creado / 🔵 Club sincronizado / 🟠 Verificando integridad / 🔴 Error / 🔴 Backup corrupto

## Next Steps
- (ninguno — todas las fases completadas)

## Relevant Files
### CLUB 3.1
- `lib/features/teams/data/club_service.dart` — validación + duplicados + logs
- `lib/features/teams/presentation/viewmodels/club_viewmodel.dart` — error handling + syncClubData
- `lib/features/teams/presentation/views/create_club_screen.dart` — validaciones inline
- `lib/features/teams/data/club_sync_service.dart` — sync methods reales
- `lib/features/settings/presentation/views/club_section.dart` — botón Crear Club independiente

### BACKUP 2.0
- `lib/features/settings/data/google_drive_service.dart` — Drive API REST (sign-in, upload, download, verify)
- `lib/features/settings/data/backup_service.dart` — Drive upload/restore + checksum SHA-256 validation
- `lib/features/settings/presentation/views/drive_backup_section.dart` — UI de Google Drive
- `lib/features/settings/presentation/views/settings_screen.dart` — integración en settings

**flutter analyze: 0 errores, 0 warnings**

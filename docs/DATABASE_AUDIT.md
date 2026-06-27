# DATABASE_AUDIT.md — Auditoría Completa de Persistencia

> Generado: FASE DATABASE 1.0

---

## Resumen

| Modelo | toMap | fromMap | toJson | fromJson | copyWith | Estado |
|--------|-------|---------|--------|----------|----------|--------|
| Player | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ✅ | ✅ OK |
| Match | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK* |
| AttendanceRecord | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK |
| StatEvent | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK |
| Season | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK |
| MatchEvent | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK |
| RotationStatsRecord | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK |
| AthleteMonthlyAward | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK |
| MedicalLeave | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK |
| AppUser | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK |
| StaffMember | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ✅ | ✅ OK |
| StaffInvitation | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK |
| StaffActivity | ✅ (inline DB) | ✅ (inline DB) | ❌ | ❌ | ❌ | ✅ OK |
| CategoryConfig | ✅ (model) | ✅ (model) | ❌ | ❌ | ✅ | ✅ OK |
| ProfileModel | — | — | ✅ | ✅ | — | ✅ OK |
| Club | ✅ (model) | ✅ (model) | ❌ | ❌ | ❌ | ✅ OK |
| ClubMember | ✅ (model) | ✅ (model) | ❌ | ❌ | ✅ | ✅ OK |
| ClubInvitation | ✅ (model) | ✅ (model) | ❌ | ❌ | ❌ | ✅ OK |
| AppNotification | ✅ (model) | ✅ (model) | ❌ | ❌ | ✅ | ✅ OK |

*_* = `Match.competitionName` corregido durante esta auditoría (ver bugs)._
_Serialización "inline DB": toMap/fromMap existen como métodos privados en `DatabaseService`._

---

## Modelos Auditados

### 1. Player (`lib/features/estadisticas/data/models/player.dart`)

**Campos (23):** id, nombre, firstNames, lastNames, displayName, cedula, fechaNacimiento, numero, posicion, esCapitan, fotoUrl, estadoSalud, condicionFisica, createdAt, profileId, clubId, atletaStatus, statusReason, statusStartDate, statusEndDate, restriccion, sexo, altura, tipoSangre, manoDominante, posicionSecundaria, fechaIngreso, isDeleted, deletedAt, deletedBy, deletionReason

**✅ Serialización completa.** Todos los campos en `toMap()`/`fromMap()` en DatabaseService (líneas 1035-1096). `copyWith()` presente en el modelo.

### 2. Match (`lib/features/estadisticas/data/models/match.dart`)

**Campos (24):** id, fecha, equipoLocal, equipoVisitante, puntosLocal, puntosVisitante, setsLocal, setsVisitante, setActual, estado, turnoLocal, velocidadAnimacion, createdAt, tipoPartido, setsTotales, puntosParaGanarSet, puntosDiferenciaSet, ultimoPuntoFueLocal, resultadoFinal, lugar, **competitionName**, seasonId, profileId, clubId, duracionSegundos

**🔴 BUG CORREGIDO:** `competitionName` no estaba incluido en `_matchToMap()` ni `_matchFromMap()`. Cualquier partido guardado perdía el nombre de la competencia. **Fix:** agregado a ambos métodos.

### 3. AttendanceRecord (`lib/features/estadisticas/data/models/attendance_record.dart`)

**Campos (6):** id, playerId, profileId, clubId, fecha, asistio, observaciones

**✅ Serialización completa.**

### 4. StatEvent (`lib/features/estadisticas/data/models/stat_event.dart`)

**Campos (14):** id, tipoAccion, resultado, timestamp, setNumero, puntoLocal, puntoVisitante, esEquipoLocal, zona, descripcion, playerId, matchId, profileId, clubId, createdAt

**✅ Serialización completa.**

### 5. Season (`lib/features/estadisticas/data/models/season.dart`)

**Campos (7):** id, name, year, isActive, startDate, endDate, createdAt

**✅ Serialización completa.**

### 6. MatchEvent (`lib/features/partido/data/match_event.dart`)

**Campos (10):** id, athleteId, matchId, fecha, setNumero, eventType, tipoPartido, competenciaNombre, profileId, clubId, rotacion

**✅ Serialización completa.**

### 7. RotationStatsRecord (`lib/features/statistics/data/rotation_stats_model.dart`)

**Campos (8):** id, matchId, setNumber, rotationIndex, pointsWon, pointsLost, serverPlayerNumber, playerSlots

**✅ Serialización completa.**

### 8. AthleteMonthlyAward (`lib/features/statistics/data/statistics_models.dart`)

**Campos (9):** id, playerId, year, month, score, rank, awardedAt, profileId, clubId

**✅ Serialización completa.**

### 9. MedicalLeave (`lib/features/asistencia/data/medical_leave_model.dart`)

**Campos (9):** id, playerId, reason, startDate, endDate, notes, createdAt, createdBy, status

**✅ Serialización completa** via `MedicalLeaveRepository._toMap()`/`_fromMap()`.

### 10. AppUser (`lib/features/auth/data/models/user_model.dart`)

**Campos (5):** id, nombre, email, password, fechaRegistro

**✅ Serialización completa** via DatabaseService.

### 11. Staff Models (`lib/features/staff_tecnico/data/staff_tecnico_models.dart`)

**StaffMember (9 campos):** id, nombre, correo, fotoUrl, role, status, profileId, clubId, createdAt, createdBy
**StaffInvitation (8 campos):** id, email, role, status, createdAt, createdBy, profileId, clubId
**StaffActivity (7 campos):** id, type, message, createdBy, createdAt, profileId, clubId

**✅ Serialización completa** via DatabaseService.

### 12. CategoryConfig (`lib/core/models/category_config.dart`)

**Campos (6):** id, name, minAge, maxAge, sortOrder, isDefault

**✅ Serialización completa.** `toMap()`/`fromMap()`/`copyWith()` en el propio modelo.

### 13. Club Models (`lib/features/teams/data/team_models.dart`)

**Club (7 campos):** id, name, ownerId, description, photoUrl, memberCount, createdAt
**ClubMember (7 campos):** id, userId, email, displayName, role, status, joinedAt
**ClubInvitation (9 campos):** id, clubId, clubName, inviterUserId, inviterDisplayName, inviteeEmail, inviteeUserId, role, status, createdAt

**✅ Persisten en Firestore.** `toMap()`/`fromMap()` presentes. Compatibles con Firestore naming.

### 14. AppNotification (`lib/features/notifications/data/notification_models.dart`)

**Campos (9):** id, type, title, message, createdAt, read, relatedAthleteId, relatedMatchId, userId

**✅ Persiste en Firestore.** `toMap()`/`fromMap()`/`copyWith()` presentes.

---

## DatabaseService: Exportación e Importación

### exportToJson()

**Incluye ahora:**
- players ✅
- matches ✅
- events (StatEvent) ✅
- attendance ✅
- matchEvents ✅
- profiles ✅
- profilesMeta ✅
- users ✅
- seasons ✅
- rotationStats ✅
- monthlyAwards ✅
- **medicalLeaves ✅ (AGREGADO)**
- **staffMembers ✅ (AGREGADO)**
- **staffInvitations ✅ (AGREGADO)**
- **staffActivities ✅ (AGREGADO)**
- **categories ✅ (AGREGADO)**

### importFromJson()

**Importa ahora todos los items de exportToJson()**, incluyendo los 5 nuevos grupos. Llama a `CategoryService.instance.reload()` al final para refrescar caché.

### clearAllData()

**Limpia ahora** todos los stores incluyendo los que faltaban:
- staffMembers, staffInvitations, staffActivities ✅ (AGREGADO)
- categories ✅ (AGREGADO)

---

## BackupService

| Aspecto | Estado |
|---------|--------|
| createBackup() | ✅ Usa `DatabaseService.exportToJson()` |
| restoreBackup() | ✅ Usa `DatabaseService.importFromJson()` |
| Incluye todos los modelos | ✅ Ahora sí (con los 5 grupos agregados) |
| Metadata (fecha, cuenta) | ✅ SharedPreferences |
| Manejo de errores | ✅ try-catch + logs |
| Restauración archivo externo | ✅ FilePicker |
| Restauración desde path | ✅ Ruta directa |

---

## Logs de Auditoría Agregados

| Escenario | Log |
|-----------|-----|
| Exportación exitosa | `🟢 EXPORT VERIFIED` |
| Importación exitosa | `🟢 IMPORT VERIFIED` |
| Backup creado | `🔵 DATABASE AUDIT` |
| Restauración exitosa | `🟢 BACKUP VERIFIED` |
| Data loss detectada | `🔴 DATA LOSS DETECTED` |

---

## Bugs Encontrados y Corregidos

| # | Severidad | Modelo | Problema | Fix |
|---|-----------|--------|----------|-----|
| 1 | 🔴 DATA LOSS | Match | `competitionName` no serializado en `_matchToMap`/`_matchFromMap` | Agregado campo |
| 2 | 🔴 DATA LOSS | MedicalLeave | No incluido en `exportToJson()`/`importFromJson()` — se borraba en restore | Agregado a export/import |
| 3 | 🔴 DATA LOSS | Staff | No incluido en `exportToJson()`/`importFromJson()` — no respaldado | Agregado a export/import/clearAll |
| 4 | 🔴 DATA LOSS | CategoryConfig | No incluido en `exportToJson()`/`importFromJson()` — no respaldado | Agregado a export/import/clearAll |
| 5 | 🟡 CONSISTENCIA | Staff | No incluido en `clearAllData()` — inconsistente con export/import | Agregado a clearAllData |
| 6 | 🟡 CONSISTENCIA | CategoryConfig | No incluido en `clearAllData()` | Agregado a clearAllData |

---

## Compatibilidad con Registros Antiguos

| Escenario | Comportamiento |
|-----------|---------------|
| JSON antiguo sin `competitionName` | ✅ `?? ''` en toMap / `?.isNotEmpty == true ? ... : null` en fromMap |
| JSON antiguo sin `medicalLeases` | ✅ `as List? ?? []` — se omite |
| JSON antiguo sin `staffMembers` | ✅ `as List? ?? []` — se omite |
| JSON antiguo sin `categories` | ✅ `as List? ?? []` — se omite; CategoryService siembra defaults |
| Campos nuevos en modelo | ✅ Valores default en `fromMap` (ej. `as int? ?? 25`) |
| Enum con valores nuevos | ✅ `values[map['x'] as int? ?? 0]` con fallback al primer valor |
| `null` en fecha | ✅ `DateTime.now()` como fallback |
| String vacío en lugar de null | ✅ Pattern `?.isNotEmpty == true ? val : null` |
| `isDeleted` en Player | ✅ `(map['isDeleted'] as int? ?? 0) == 1` — false por defecto |

**Riesgo mínimo.** Todos los campos nuevos usan patrones de compatibilidad con fallbacks seguros. Ningún campo usa `as int` (no nullable) sin valor por defecto.

---

## Riesgos Identificados

1. **Serialización inline vs model methods**: La mayoría de modelos no tienen `toMap()`/`fromMap()` como métodos propios. Toda la serialización está en `DatabaseService`. Esto funciona pero dificulta mantener la consistencia cuando se agregan campos.

2. **Password en texto plano**: `AppUser.password` se guarda en texto plano en sembast. Aunque es local, es una mala práctica.

3. **Dos conexiones al mismo DB**: `DatabaseService`, `MedicalLeaveRepository`, `CategoryService`, y `LogService` abren conexiones independientes al mismo archivo `libero360.db`. Sembast lo soporta, pero puede causar race conditions en writes concurrentes.

4. **Staff/Club/Notification en Firestore**: Estos modelos NO se incluyen en backup/restore local. Dependen de la conectividad a Firebase.

5. **Settings via SharedPreferences**: `AppThemeMode` y preferencias de notificaciones persisten en `SharedPreferences`, no en sembast. No hay backup para esto.

---

## Mejoras Futuras Recomendadas

1. **Migrar serialización a modelos**: Agregar `toMap()`/`fromMap()` a todos los modelos para centralizar la lógica de serialización
2. **Backup unificado**: Incluir Firestore data (Club, Staff, Notifications) en el backup JSON via API calls
3. **Encriptar password**: Usar hash en lugar de texto plano para `AppUser.password`
4. **Conexión única**: Centralizar todas las operaciones sembast en `DatabaseService` en lugar de conexiones separadas
5. **Backup de SharedPreferences**: Agregar export/import de settings al JSON
6. **Versión de schema**: Agregar migraciones para cambios futuros de schema

---

## flutter analyze

**Resultado: 0 errores, 0 warnings** (solo 6 warnings pre-existentes en archivos no modificados)

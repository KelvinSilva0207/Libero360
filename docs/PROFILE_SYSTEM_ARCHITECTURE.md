# FASE 5.5 — Sistema de Perfiles (Arquitectura Base)

## Concepto

Un usuario puede tener varios perfiles, cada uno vinculado a un club y categoría. Cada perfil tiene un rol.

**Ejemplo:**
```
Usuario: Juan Pérez
├── Club Águilas / Masculino     → Coach
├── Club Águilas / Femenino      → Coach
├── Club Titanes / Sub17         → Asistente
└── Club Nacional / Asistente    → Espectador
```

## Arquitectura

```
lib/features/profiles/
├── data/
│   ├── profile_model.dart           # ProfileModel
│   └── profile_repository.dart      # Persistencia local (Sembast)
│
├── presentation/
│   ├── viewmodels/
│   │   └── profile_viewmodel.dart   # Estado y lógica
│   │
│   ├── views/
│   │   ├── profiles_screen.dart     # Pantalla completa de perfiles
│   │   └── create_profile_screen.dart # Formulario de creación
│   │
│   └── widgets/
│       ├── profile_card.dart        # Card de perfil individual
│       └── profile_selector.dart    # Selector compacto reutilizable
│
└── profiles.dart                    # Barrel export
```

## ProfileModel

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | `String` | ID único (timestamp-based) |
| `clubId` | `String` | ID del club asociado |
| `clubName` | `String` | Nombre del club |
| `name` | `String` | Nombre del perfil |
| `category` | `String` | Categoría (Masculino, Femenino, Sub17, etc.) |
| `role` | `String` | Rol: `owner`, `coach`, `assistant`, `viewer` |
| `isActive` | `bool` | Perfil activo actualmente |

### Métodos
- `toJson()` / `fromJson()` — serialización
- `copyWith()` — copia inmutable con campos opcionales
- `displayLabel` — `"$clubName · $category"` para UI
- `roleLabel` — traducción legible del rol

## ProfileRepository

Persistencia local usando **Sembast** (base de datos NoSQL embebida).

- **Base de datos**: `profiles.db` (archivo separado de la DB principal)
- **Store**: `profiles_store` para perfiles
- **Meta store**: `profiles_meta` para metadatos (perfil activo)

### Métodos
| Método | Descripción |
|--------|-------------|
| `initialize()` | Abre la base de datos |
| `loadProfiles()` | Carga todos los perfiles |
| `saveProfiles(profiles)` | Reemplaza todos los perfiles |
| `addProfile(profile)` | Agrega un perfil |
| `updateProfile(profile)` | Actualiza un perfil existente |
| `deleteProfile(id)` | Elimina un perfil |
| `getActiveProfileId()` | Obtiene el ID del perfil activo |
| `setActiveProfileId(id)` | Guarda el ID del perfil activo |

### Singleton
```dart
static final ProfileRepository instance = ProfileRepository._internal();
```

## ProfileViewModel

```dart
class ProfileViewModel extends ChangeNotifier {
  List<ProfileModel> profiles
  ProfileModel? currentProfile
  bool loading
  String? error

  Future<void> loadProfiles()
  Future<void> selectProfile(String id)
  Future<ProfileModel> createProfile({clubId, clubName, name, category, role})
  Future<void> deleteProfile(String id)
  void clear()
}
```

### Flujo de selección
1. `loadProfiles()` carga perfiles y el ID activo desde el repositorio
2. `selectProfile(id)` actualiza el perfil activo y persiste en repositorio
3. Si no hay perfil activo, selecciona el primer perfil de la lista
4. `clear()` resetea el estado (útil al cerrar sesión)

## ProfileSelector

Widget reutilizable que muestra el perfil actual en formato compacto:

```
[Club Águilas · Masculino ▼]
```

Al tocarlo, despliega un menú con todos los perfiles disponibles. Usa `PopupMenuButton`.

### Ubicaciones previstas
- **Settings** → ProfilesSection (ya implementado)
- **Dashboard** → AppBar (FASE 5.6)
- **AppShell** → junto al ClubSwitcher (FASE 5.6)

## Integración con Settings

`ProfilesSection` (`lib/features/settings/presentation/views/profiles_section.dart`) fue modificado:

**Antes**: Placeholder "Próximamente" con botón deshabilitado.
**Después**: 
- Selector de perfil activo (`ProfileSelector`)
- Lista de perfiles con `ProfileCard`
- Botón "Crear perfil" funcional que abre `CreateProfileScreen`
- Provider local `ChangeNotifierProvider<ProfileViewModel>`

## CreateProfileScreen

Formulario con campos:
- **Club** (requerido) — texto libre
- **Nombre del perfil** (requerido) — texto libre
- **Categoría** (opcional) — texto libre
- **Rol** — dropdown: Propietario, Entrenador, Asistente, Espectador

Al guardar, llama a `ProfileViewModel.createProfile()` y navega hacia atrás.

## Persistencia

- **Local**: Sembast en `profiles.db`
- **Firebase**: NO implementado aún (preparado para FASE 5.6+)

## Compatibilidad con Firebase (futuro)

Cuando se implemente Firebase Sync:
1. `ProfileRepository` obtendrá perfiles desde Firestore
2. `ProfileViewModel` sincronizará automáticamente
3. `ProfileSelector` reflejará cambios en tiempo real
4. La estructura `toJson()/fromJson()` ya es compatible con Firestore

## Archivos Creados

| Archivo | Líneas | Propósito |
|---------|--------|-----------|
| `lib/features/profiles/profiles.dart` | 7 | Barrel export |
| `lib/features/profiles/data/profile_model.dart` | 70 | Modelo de datos |
| `lib/features/profiles/data/profile_repository.dart` | 83 | Persistencia Sembast |
| `lib/features/profiles/presentation/viewmodels/profile_viewmodel.dart` | 96 | Estado y lógica |
| `lib/features/profiles/presentation/views/profiles_screen.dart` | 147 | Lista de perfiles |
| `lib/features/profiles/presentation/views/create_profile_screen.dart` | 188 | Formulario de creación |
| `lib/features/profiles/presentation/widgets/profile_card.dart` | 103 | Card de perfil |
| `lib/features/profiles/presentation/widgets/profile_selector.dart` | 82 | Selector compacto |

## Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/settings/presentation/views/profiles_section.dart` | Placeholder reemplazado por perfiles reales |

## flutter analyze

```
0 errores
277 issues (info/warnings, todos pre-existentes)
```

## Migración Futura (FASE 5.6)

1. **Filtrar datos por perfil activo**: atletas, partidos, asistencias, estadísticas
2. **ProfileSelector en AppShell/Dashboard**: cambiar perfil desde la barra superior
3. **Firebase Sync**: sincronizar perfiles con Firestore
4. **Multi-perfil nativo**: crear perfiles vinculados a clubes existentes

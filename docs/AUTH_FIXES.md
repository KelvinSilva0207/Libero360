# FASE 5.1 — Auth Stability Fix

## Bugs Corregidos

### 1. LoginScreen — `Navigator.pop()` en contexto stale

- **Archivo**: `lib/features/auth/presentation/views/login_screen.dart:33-35`
- **Causa**: `vm.login()` setea `AuthStatus.authenticated` y llama `notifyListeners()` antes de que `_submit` reanude del `await`. El `Consumer<AuthViewModel>` en `AuthGate` reconstruye el árbol mostrando `AppShell`, dejando el `BuildContext` del LoginScreen en estado stale. `Navigator.pop()` operaba sobre un navegador sin la ruta esperada.
- **Solución**: Reemplazar `Navigator.pop()` con `return` temprano. `AuthGate` maneja la navegación automáticamente al cambiar `status`.
- **Riesgo**: Ninguno. El flujo es determinístico: `login()` retorna `true` → `AuthStatus.authenticated` → `AuthGate` renderiza `AppShell`.

### 2. RegisterScreen — Mismo `Navigator.pop()` stale

- **Archivo**: `lib/features/auth/presentation/views/register_screen.dart:39-41`
- **Causa**: Idéntico al bug anterior. `vm.register()` cambia estado antes del `Navigator.pop()`.
- **Solución**: Idéntica — `return` temprano en vez de pop.
- **Riesgo**: Ninguno.

### 3. FirebaseAuthRepository — Google Sign-In con `idToken` null

- **Archivo**: `lib/features/auth/data/repositories/firebase_auth_repository.dart:84-86`
- **Causa**: Cuando `googleAuth.idToken` es `null` (ej. `serverClientId` mal configurado), el código imprimía una advertencia pero continuaba, pasando `idToken: null` a `GoogleAuthProvider.credential()`, lo que causaba `FirebaseAuthException` (`invalid-credential`). El error se capturaba genéricamente, mostrando al usuario un mensaje vago "Error al iniciar con Google".
- **Solución**: Agregar `return null` inmediato si `idToken == null`, abortando el flujo antes de la llamada a Firebase.
- **Riesgo**: Ninguno. El flujo ya retornaba `null` en el catch; ahora es más explícito y evita la excepción.

### 4. Logs de depuración agregados

Se agregaron logs con emoji `🔵`/`🟢`/`🔴` en:

- **`AuthViewModel`** — `login()`, `loginWithGoogle()`, `register()`
- **`FirebaseAuthRepository`** — `login()`, `register()`, `signInWithGoogle()`

Cobertura: inicio, éxito y fallo de cada operación, más detección de `idToken null`.

## Verificación

```
$ dart analyze lib/features/auth/...
No issues found!  (solo info: avoid_print — pre-existentes, 0 errores, 0 warnings)
```

## Comportamiento Esperado

| Escenario | Antes | Después |
|-----------|-------|---------|
| Login exitoso | Navigator.pop → posible error de ruta stale → AuthGate limpia | AuthGate maneja transición inmediata |
| Login fallido | SnackBar con error | SnackBar con error (sin cambio) |
| Registro exitoso | Navigator.pop → posible error | AuthGate maneja transición |
| Google Sign-In idToken null | FirebaseAuthException → "Error al iniciar con Google" | Retorno inmediato → "Error al iniciar con Google" (sin excepción) |

## Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/auth/presentation/views/login_screen.dart` | `Navigator.pop()` → `return` |
| `lib/features/auth/presentation/views/register_screen.dart` | `Navigator.pop()` → `return` |
| `lib/features/auth/data/repositories/firebase_auth_repository.dart` | Early return si `idToken == null` + logs en login/register/signInWithGoogle |
| `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart` | Logs en login/loginWithGoogle/register |

# Prueba socio vencido/suspendido + QR - 2026-06-16

## Objetivo

Validar que un socio vencido o suspendido no pueda usar QR de acceso, aunque tenga `qr_secret` emitido por backend.

## Alcance

- APK móvil dev/local.
- Flutter web local.
- Página web/admin local.
- Backend Docker local.

## Ambiente

| Campo | Valor |
| --- | --- |
| Rama | `trabajo/caja-movil-docker-local` |
| API | `http://localhost:3000/api/v1` |
| Flutter web | `http://localhost:8383` |
| Web/admin | `http://localhost:8282/web/index.html` |
| APK dev/local | `com.sasgym.app.dev` |
| APK versionCode validado | `4` |

## Datos de prueba

| Caso | Usuario/Dato | Estado esperado |
| --- | --- | --- |
| Socio vencido | `socio12.surco@test.sasgym.com` / `member_secure_pass` | `EXPIRED` |
| DNI socio vencido | `10000412` | Acceso denegado |
| Socio suspendido | `socio17.surco@test.sasgym.com` / `member_secure_pass` | `SUSPENDED` |
| DNI socio suspendido | `10000417` | Acceso denegado |
| Admin para web/admin | `admin1.surco@test.sasgym.com` / `admin_secure_pass` | Puede verificar acceso |

## Implementación validada

- `mobile_app/lib/features/member/widgets/full_qr_view.dart` bloquea generación de QR si el socio no está `active` o `grace`.
- Un socio `expired`, `suspended` o `pending` ve `QR BLOQUEADO` y `ACCESO DENEGADO`.
- El backend ya devuelve `RED` para membresía `EXPIRED` o `SUSPENDED` desde `/attendance/simulation-access`.
- La web/admin consume ese endpoint en la pantalla de asistencia.

## Casos

### MOB-QR-001 - Socio vencido no genera QR en app Flutter/APK

Pasos:

1. Iniciar sesión como `socio12.surco@test.sasgym.com`.
2. Abrir el acceso QR.
3. Verificar la pantalla.

Resultado esperado:

- No se muestra token.
- No se renderiza QR escaneable.
- Se muestra `QR BLOQUEADO`.
- Se muestra `ACCESO DENEGADO`.
- El mensaje indica que la membresía está vencida.

Estado: `PASÓ`

Evidencia:

- Test automatizado `mobile_app/test/smoke/mobile_security_flags_test.dart` pasó.
- APK dev/local instalado en celular con `versionCode=4`.

### WEBAPP-QR-001 - Flutter web contiene la barrera de QR bloqueado

Pasos:

1. Reconstruir `frontend-web`.
2. Abrir `http://localhost:8383`.
3. Iniciar sesión como socio vencido.
4. Abrir QR.

Resultado esperado:

- La misma pantalla Flutter muestra `QR BLOQUEADO`.
- No muestra token ni QR escaneable.

Estado: `PASÓ`

Evidencia:

- `docker compose up -d --build frontend-web`: OK.
- `http://localhost:8383`: responde `200 OK`.
- El test Flutter valida el comportamiento de la misma pantalla compartida por APK y Flutter web.

### WEBADMIN-QR-001 - Página web/admin deniega acceso a socio vencido

Pasos:

1. Iniciar sesión en web/admin como `admin1.surco@test.sasgym.com`.
2. Ir a asistencia/verificación.
3. Verificar DNI `10000412`.

Resultado esperado:

- Backend responde `verdict: RED`.
- Razón: `Membresía vencida.`
- La web/admin debe mostrar acceso denegado.

Estado: `PASÓ`

Evidencia API:

```json
{
  "verdict": "RED",
  "reason": "Membresía vencida.",
  "member": {
    "fullName": "Sandra Reyes",
    "status": "EXPIRED",
    "email": "socio12.surco@test.sasgym.com"
  },
  "simulation": true
}
```

### WEBADMIN-QR-002 - Página web/admin deniega acceso a socio suspendido

Pasos:

1. Iniciar sesión en web/admin como `admin1.surco@test.sasgym.com`.
2. Ir a asistencia/verificación.
3. Verificar DNI `10000417`.

Resultado esperado:

- Backend responde `verdict: RED`.
- Razón: `La cuenta del socio ha sido suspendida.`
- La web/admin debe mostrar acceso denegado.

Estado: `PASÓ`

Evidencia API:

```json
{
  "verdict": "RED",
  "reason": "La cuenta del socio ha sido suspendida.",
  "member": {
    "fullName": "Miguel Soto",
    "status": "SUSPENDED"
  },
  "simulation": true
}
```

## Validaciones ejecutadas

| Validación | Resultado |
| --- | --- |
| `flutter test test/smoke/mobile_security_flags_test.dart` | `PASÓ` |
| `flutter analyze` | Sin errores nuevos; mantiene 30 advertencias preexistentes |
| `docker compose up -d --build frontend-web` | `PASÓ` |
| `curl http://localhost:8383` | `200 OK` |
| `curl http://localhost:8282` | `200 OK` |
| API socio vencido `/attendance/simulation-access` | `verdict: RED` |
| API socio suspendido `/attendance/simulation-access` | `verdict: RED` |
| APK dev/local instalado | `versionCode=4` |

## Resultado

`PASÓ`.

La prueba queda aprobada para APK móvil, Flutter web y página web/admin local.

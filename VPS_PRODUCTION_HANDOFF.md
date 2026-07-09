# VPS Production Handoff

Fecha de actualizacion: 2026-07-09 UTC

## Estado del despliegue

- API productiva: `https://api.sas-gym.qpsecure.cloud/api/v1`
- WebSocket productivo: `wss://ws.sas-gym.qpsecure.cloud`
- Landing publica: `https://admin.sas-gym.qpsecure.cloud`
- Web app publica: `https://app.sas-gym.qpsecure.cloud`

## Verificaciones realizadas

- `GET https://api.sas-gym.qpsecure.cloud/api/v1/health/readiness` -> `200 OK`
- `GET https://admin.sas-gym.qpsecure.cloud/` -> `200 OK`
- `GET https://app.sas-gym.qpsecure.cloud/` -> `200 OK`
- `POST https://api.sas-gym.qpsecure.cloud/api/v1/auth/login` con credenciales de prueba -> `200 OK`
- `GET https://ws.sas-gym.qpsecure.cloud/` -> `404 Not Found`

Nota sobre `ws`:
- El `404` en `/` es esperable.
- Ese subdominio esta reservado para handshake/conexion websocket, no para contenido HTML.

## Endpoints para configurar en el APK

- `API_BASE_URL=https://api.sas-gym.qpsecure.cloud/api/v1`
- `WS_URL=wss://ws.sas-gym.qpsecure.cloud`
- `APP_URL=https://app.sas-gym.qpsecure.cloud`
- `LANDING_URL=https://admin.sas-gym.qpsecure.cloud`

## Credenciales comunes por rol

| Rol | Password |
| --- | --- |
| `SUPER_ADMIN` | `super_secure_pass` |
| `ADMIN` | `admin_secure_pass` |
| `CAJA` | `caja_secure_pass` |
| `TRAINER` | `trainer_secure_pass` |
| `MEMBER` | `member_secure_pass` |

## Usuarios de prueba recomendados

### Super admin

| Gym | Nombre | Email | Password |
| --- | --- | --- | --- |
| `SaasGym Network` | `Super Admin Demo` | `superadmin@test.sasgym.com` | `super_secure_pass` |

### Admin

| Gym | Nombre | Email | Password |
| --- | --- | --- | --- |
| `SaasGym Cayma Prime` | `Admin 1 Cayma Prime` | `admin1.surco@test.sasgym.com` | `admin_secure_pass` |
| `SaasGym Yanahuara Fit` | `Admin 1 Yanahuara Fit` | `admin1.miraflores@test.sasgym.com` | `admin_secure_pass` |
| `SaasGym Cercado Performance` | `Admin 1 Cercado Performance` | `admin1.sanborja@test.sasgym.com` | `admin_secure_pass` |
| `SaasGym Cerro Colorado 24/7` | `Admin 1 Cerro Colorado 24/7` | `admin1.lince@test.sasgym.com` | `admin_secure_pass` |
| `SaasGym Bustamante Strong` | `Admin 1 Bustamante Strong` | `admin1.callao@test.sasgym.com` | `admin_secure_pass` |

### Caja

| Gym | Nombre | Email | Password |
| --- | --- | --- | --- |
| `SaasGym Cayma Prime` | `Caja 1 Fernandez` | `caja1.surco@test.sasgym.com` | `caja_secure_pass` |
| `SaasGym Yanahuara Fit` | `Caja 1 Castro` | `caja1.miraflores@test.sasgym.com` | `caja_secure_pass` |
| `SaasGym Cercado Performance` | `Caja 1 Torres` | `caja1.sanborja@test.sasgym.com` | `caja_secure_pass` |
| `SaasGym Cerro Colorado 24/7` | `Caja 1 Mendieta` | `caja1.lince@test.sasgym.com` | `caja_secure_pass` |
| `SaasGym Bustamante Strong` | `Caja 1 Salas` | `caja1.callao@test.sasgym.com` | `caja_secure_pass` |

### Trainer

| Gym | Nombre | Email | Password |
| --- | --- | --- | --- |
| `SaasGym Cayma Prime` | `Diego Coach Mendieta` | `trainer1.surco@test.sasgym.com` | `trainer_secure_pass` |
| `SaasGym Yanahuara Fit` | `Rosa Coach Mendieta` | `trainer1.miraflores@test.sasgym.com` | `trainer_secure_pass` |
| `SaasGym Cercado Performance` | `Ana Coach Mendieta` | `trainer1.sanborja@test.sasgym.com` | `trainer_secure_pass` |
| `SaasGym Cerro Colorado 24/7` | `Pedro Coach Mendieta` | `trainer1.lince@test.sasgym.com` | `trainer_secure_pass` |
| `SaasGym Bustamante Strong` | `Valeria Coach Mendieta` | `trainer1.callao@test.sasgym.com` | `trainer_secure_pass` |

### Member

| Gym | Nombre | Email | Password |
| --- | --- | --- | --- |
| `SaasGym Cayma Prime` | `Lucia Quispe` | `socio01.surco@test.sasgym.com` | `member_secure_pass` |
| `SaasGym Yanahuara Fit` | `Rosa Torres` | `socio01.miraflores@test.sasgym.com` | `member_secure_pass` |
| `SaasGym Cercado Performance` | `Pedro Paredes` | `socio01.sanborja@test.sasgym.com` | `member_secure_pass` |
| `SaasGym Cerro Colorado 24/7` | `Jorge Chavez` | `socio01.lince@test.sasgym.com` | `member_secure_pass` |
| `SaasGym Bustamante Strong` | `Renato Mendoza` | `socio01.callao@test.sasgym.com` | `member_secure_pass` |

## Login verificado durante esta entrega

- Usuario: `admin1.surco@test.sasgym.com`
- Password: `admin_secure_pass`
- Resultado: `200 OK`
- Gym asociado: `SaasGym Cayma Prime`

## Observaciones operativas

- La landing publica se sirve en `admin.sas-gym.qpsecure.cloud`.
- La web app React/Vite se sirve en `app.sas-gym.qpsecure.cloud`.
- No se esta desplegando Flutter Web.
- El backend inicializa base vacia con `prisma db push --skip-generate`, luego `seed:prod`, luego `data:reconcile`.
- El subdominio `ws` debe consumirse desde cliente websocket; no devuelve pagina HTML.

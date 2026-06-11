# Datos de prueba

Fecha de verificacion: 2026-06-11 UTC

## Estado actual

- La base `sasgym_prod` ya fue creada y sembrada con datos operativos de prueba.
- El frontend Flutter web no esta desplegado: el contenedor `sasgym_app_web` fue eliminado y su imagen local tambien fue retirada.
- Servicios activos del stack SaasGym: `sasgym_api`, `sasgym_ws`, `sasgym_admin_web`, `sasgym_postgres`, `sasgym_redis`.

## Subdominios configurados y funcionando

| Subdominio | URL publica | Servicio actual | Estado | Observacion |
| --- | --- | --- | --- | --- |
| `api` | `https://api.sas-gym.qpsecure.cloud/api/v1` | `sasgym_api` | `Activo` | API REST principal en produccion |
| `ws` | `wss://ws.sas-gym.qpsecure.cloud` | `sasgym_ws` | `Activo` | WebSocket en produccion |
| `admin` | `https://admin.sas-gym.qpsecure.cloud` | `sasgym_admin_web` | `Activo` | Panel web admin publicado |
| `app` | `https://app.sas-gym.qpsecure.cloud` | Sin contenedor desplegado | `No activo` | URL configurada, pero el frontend Flutter web fue retirado |

### CORS configurado

- `https://app.sas-gym.qpsecure.cloud`
- `https://admin.sas-gym.qpsecure.cloud`

## Resumen verificado en base

| Rol | Total |
| --- | ---: |
| `SUPER_ADMIN` | 1 |
| `ADMIN` | 10 |
| `CAJA` | 15 |
| `TRAINER` | 25 |
| `MEMBER` | 100 |

Total de tenants cargados: `6`

## Credenciales comunes por rol

| Rol | Password comun |
| --- | --- |
| `SUPER_ADMIN` | `super_secure_pass` |
| `ADMIN` | `admin_secure_pass` |
| `CAJA` | `caja_secure_pass` |
| `TRAINER` | `trainer_secure_pass` |
| `MEMBER` | `member_secure_pass` |

## Sedes disponibles

| Sede | Plan | Activa |
| --- | --- | --- |
| `SaasGym Network` | `ENTERPRISE` | `Si` |
| `SaasGym Bustamante Strong` | `PRO` | `Si` |
| `SaasGym Cayma Prime` | `PRO` | `Si` |
| `SaasGym Cercado Performance` | `ENTERPRISE` | `Si` |
| `SaasGym Cerro Colorado 24/7` | `BASIC` | `Si` |
| `SaasGym Yanahuara Fit` | `PRO` | `Si` |

## Login super admin

| Sede | Rol | Nombre | Email |
| --- | --- | --- | --- |
| `SaasGym Network` | `SUPER_ADMIN` | `Super Admin Demo` | `superadmin@test.sasgym.com` |

## Logins admin disponibles

| Sede | Nombre | Email |
| --- | --- | --- |
| `SaasGym Bustamante Strong` | `Admin 1 Bustamante Strong` | `admin1.callao@test.sasgym.com` |
| `SaasGym Bustamante Strong` | `Admin 2 Bustamante Strong` | `admin2.callao@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Admin 1 Cayma Prime` | `admin1.surco@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Admin 2 Cayma Prime` | `admin2.surco@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Admin 1 Cercado Performance` | `admin1.sanborja@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Admin 2 Cercado Performance` | `admin2.sanborja@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Admin 1 Cerro Colorado 24/7` | `admin1.lince@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Admin 2 Cerro Colorado 24/7` | `admin2.lince@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Admin 1 Yanahuara Fit` | `admin1.miraflores@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Admin 2 Yanahuara Fit` | `admin2.miraflores@test.sasgym.com` |

## Logins caja disponibles

| Sede | Nombre | Email |
| --- | --- | --- |
| `SaasGym Bustamante Strong` | `Caja 1 Salas` | `caja1.callao@test.sasgym.com` |
| `SaasGym Bustamante Strong` | `Caja 2 Paredes` | `caja2.callao@test.sasgym.com` |
| `SaasGym Bustamante Strong` | `Caja 3 Rojas` | `caja3.callao@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Caja 1 Fernandez` | `caja1.surco@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Caja 2 Castro` | `caja2.surco@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Caja 3 Torres` | `caja3.surco@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Caja 1 Torres` | `caja1.sanborja@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Caja 2 Mendieta` | `caja2.sanborja@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Caja 3 Salas` | `caja3.sanborja@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Caja 1 Mendieta` | `caja1.lince@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Caja 2 Salas` | `caja2.lince@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Caja 3 Paredes` | `caja3.lince@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Caja 1 Castro` | `caja1.miraflores@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Caja 2 Torres` | `caja2.miraflores@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Caja 3 Mendieta` | `caja3.miraflores@test.sasgym.com` |

## Logins trainer disponibles

Password comun de trainers: `trainer_secure_pass`

Nota: no fue necesario inyectar mas trainers porque cada sede ya tenia al menos 4 cuentas reales de prueba; aqui se documentan 4 por sede.

| Sede | Nombre | Email |
| --- | --- | --- |
| `SaasGym Bustamante Strong` | `Valeria Coach Mendieta` | `trainer1.callao@test.sasgym.com` |
| `SaasGym Bustamante Strong` | `Jorge Coach Salas` | `trainer2.callao@test.sasgym.com` |
| `SaasGym Bustamante Strong` | `Camila Coach Paredes` | `trainer3.callao@test.sasgym.com` |
| `SaasGym Bustamante Strong` | `Renato Coach Rojas` | `trainer4.callao@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Diego Coach Mendieta` | `trainer1.surco@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Rosa Coach Salas` | `trainer2.surco@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Ana Coach Paredes` | `trainer3.surco@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Pedro Coach Rojas` | `trainer4.surco@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Ana Coach Mendieta` | `trainer1.sanborja@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Pedro Coach Salas` | `trainer2.sanborja@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Valeria Coach Paredes` | `trainer3.sanborja@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Jorge Coach Rojas` | `trainer4.sanborja@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Pedro Coach Mendieta` | `trainer1.lince@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Valeria Coach Salas` | `trainer2.lince@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Jorge Coach Paredes` | `trainer3.lince@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Camila Coach Rojas` | `trainer4.lince@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Rosa Coach Mendieta` | `trainer1.miraflores@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Ana Coach Salas` | `trainer2.miraflores@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Pedro Coach Paredes` | `trainer3.miraflores@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Valeria Coach Rojas` | `trainer4.miraflores@test.sasgym.com` |

## Logins member disponibles

Password comun de members: `member_secure_pass`

Nota: no fue necesario inyectar mas members porque cada sede ya tenia al menos 4 cuentas reales de prueba; aqui se documentan 4 por sede.

| Sede | Nombre | Email |
| --- | --- | --- |
| `SaasGym Bustamante Strong` | `Renato Mendoza` | `socio01.callao@test.sasgym.com` |
| `SaasGym Bustamante Strong` | `Mariana Benavides` | `socio02.callao@test.sasgym.com` |
| `SaasGym Bustamante Strong` | `Luis Huaman` | `socio03.callao@test.sasgym.com` |
| `SaasGym Bustamante Strong` | `Sandra Cordova` | `socio04.callao@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Lucia Quispe` | `socio01.surco@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Diego Fernandez` | `socio02.surco@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Rosa Castro` | `socio03.surco@test.sasgym.com` |
| `SaasGym Cayma Prime` | `Ana Torres` | `socio04.surco@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Pedro Paredes` | `socio01.sanborja@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Valeria Rojas` | `socio02.sanborja@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Jorge Vargas` | `socio03.sanborja@test.sasgym.com` |
| `SaasGym Cercado Performance` | `Camila Chavez` | `socio04.sanborja@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Jorge Chavez` | `socio01.lince@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Camila Lopez` | `socio02.lince@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Renato Reyes` | `socio03.lince@test.sasgym.com` |
| `SaasGym Cerro Colorado 24/7` | `Mariana Mendoza` | `socio04.lince@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Rosa Torres` | `socio01.miraflores@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Ana Mendieta` | `socio02.miraflores@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Pedro Salas` | `socio03.miraflores@test.sasgym.com` |
| `SaasGym Yanahuara Fit` | `Valeria Paredes` | `socio04.miraflores@test.sasgym.com` |

## Patrones verificados para trainer y member

- `TRAINER`: `trainer1..5.<sede>@test.sasgym.com` con password `trainer_secure_pass`
- `MEMBER`: `socio01..20.<sede>@test.sasgym.com` con password `member_secure_pass`
- Sedes disponibles para ambos patrones de correo: `surco`, `miraflores`, `sanborja`, `lince`, `callao`

## Observaciones

- La semilla productiva ahora carga el dataset operativo completo solo cuando la base esta vacia.
- Si la base ya contiene tenants o usuarios, el seed productivo se omite para evitar duplicados.
- El panel web admin ya no deja credenciales precargadas en la interfaz y resuelve la API por subdominio en runtime.

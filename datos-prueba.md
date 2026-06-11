# Datos de prueba

Fecha de verificacion: 2026-06-11 UTC

## Estado actual

- La base `sasgym_prod` ya fue creada y sembrada con datos operativos de prueba.
- El frontend Flutter web no esta desplegado: el contenedor `sasgym_app_web` fue eliminado y su imagen local tambien fue retirada.
- Servicios activos del stack SaasGym: `sasgym_api`, `sasgym_ws`, `sasgym_admin_web`, `sasgym_postgres`, `sasgym_redis`.

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
| `SaasGym Callao Strong` | `PRO` | `Si` |
| `SaasGym Lince 24/7` | `BASIC` | `Si` |
| `SaasGym Miraflores Fit` | `PRO` | `Si` |
| `SaasGym San Borja Performance` | `ENTERPRISE` | `Si` |
| `SaasGym Surco Prime` | `PRO` | `Si` |

## Login super admin

| Sede | Rol | Nombre | Email |
| --- | --- | --- | --- |
| `SaasGym Network` | `SUPER_ADMIN` | `Super Admin Demo` | `superadmin@test.sasgym.com` |

## Logins admin disponibles

| Sede | Nombre | Email |
| --- | --- | --- |
| `SaasGym Callao Strong` | `Admin 1 Callao Strong` | `admin1.callao@test.sasgym.com` |
| `SaasGym Callao Strong` | `Admin 2 Callao Strong` | `admin2.callao@test.sasgym.com` |
| `SaasGym Lince 24/7` | `Admin 1 Lince 24/7` | `admin1.lince@test.sasgym.com` |
| `SaasGym Lince 24/7` | `Admin 2 Lince 24/7` | `admin2.lince@test.sasgym.com` |
| `SaasGym Miraflores Fit` | `Admin 1 Miraflores Fit` | `admin1.miraflores@test.sasgym.com` |
| `SaasGym Miraflores Fit` | `Admin 2 Miraflores Fit` | `admin2.miraflores@test.sasgym.com` |
| `SaasGym San Borja Performance` | `Admin 1 San Borja Performance` | `admin1.sanborja@test.sasgym.com` |
| `SaasGym San Borja Performance` | `Admin 2 San Borja Performance` | `admin2.sanborja@test.sasgym.com` |
| `SaasGym Surco Prime` | `Admin 1 Surco Prime` | `admin1.surco@test.sasgym.com` |
| `SaasGym Surco Prime` | `Admin 2 Surco Prime` | `admin2.surco@test.sasgym.com` |

## Logins caja disponibles

| Sede | Nombre | Email |
| --- | --- | --- |
| `SaasGym Callao Strong` | `Caja 1 Salas` | `caja1.callao@test.sasgym.com` |
| `SaasGym Callao Strong` | `Caja 2 Paredes` | `caja2.callao@test.sasgym.com` |
| `SaasGym Callao Strong` | `Caja 3 Rojas` | `caja3.callao@test.sasgym.com` |
| `SaasGym Lince 24/7` | `Caja 1 Mendieta` | `caja1.lince@test.sasgym.com` |
| `SaasGym Lince 24/7` | `Caja 2 Salas` | `caja2.lince@test.sasgym.com` |
| `SaasGym Lince 24/7` | `Caja 3 Paredes` | `caja3.lince@test.sasgym.com` |
| `SaasGym Miraflores Fit` | `Caja 1 Castro` | `caja1.miraflores@test.sasgym.com` |
| `SaasGym Miraflores Fit` | `Caja 2 Torres` | `caja2.miraflores@test.sasgym.com` |
| `SaasGym Miraflores Fit` | `Caja 3 Mendieta` | `caja3.miraflores@test.sasgym.com` |
| `SaasGym San Borja Performance` | `Caja 1 Torres` | `caja1.sanborja@test.sasgym.com` |
| `SaasGym San Borja Performance` | `Caja 2 Mendieta` | `caja2.sanborja@test.sasgym.com` |
| `SaasGym San Borja Performance` | `Caja 3 Salas` | `caja3.sanborja@test.sasgym.com` |
| `SaasGym Surco Prime` | `Caja 1 Fernandez` | `caja1.surco@test.sasgym.com` |
| `SaasGym Surco Prime` | `Caja 2 Castro` | `caja2.surco@test.sasgym.com` |
| `SaasGym Surco Prime` | `Caja 3 Torres` | `caja3.surco@test.sasgym.com` |

## Patrones verificados para trainer y member

- `TRAINER`: `trainer1..5.<sede>@test.sasgym.com` con password `trainer_secure_pass`
- `MEMBER`: `socio01..20.<sede>@test.sasgym.com` con password `member_secure_pass`
- Sedes disponibles para ambos patrones: `surco`, `miraflores`, `sanborja`, `lince`, `callao`

## Observaciones

- La semilla productiva ahora carga el dataset operativo completo solo cuando la base esta vacia.
- Si la base ya contiene tenants o usuarios, el seed productivo se omite para evitar duplicados.
- El panel web admin ya no deja credenciales precargadas en la interfaz y resuelve la API por subdominio en runtime.

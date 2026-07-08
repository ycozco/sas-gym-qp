# Multitenancy

## Decision MVP

Para el MVP, SAS Gym usa aislamiento mediante `tenant_id` por tabla. No se usara esquema independiente por tenant en esta fase.

## Motivo

Esta estrategia reduce complejidad de migraciones, seeds, backups y consultas iniciales.

## Reglas

- Toda consulta sensible debe filtrar por tenant.
- Los controllers deben obtener `tenantId` desde usuario autenticado o header validado.
- Los servicios no deben aceptar datos cross-tenant sin validacion explicita.
- WebSocket debe validar tenant durante handshake o suscripcion.
- Los seeds deben crear datos separados por tenant.

## ORM

El backend usa Prisma. El esquema central esta en `backend/prisma/schema.prisma`.

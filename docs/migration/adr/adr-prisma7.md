# docs/migration/adr/adr-prisma7.md — ADR: Decisiones sobre la Migración a Prisma 7

*   **Estado:** Propuesto
*   **Fecha:** 2026-06-18
*   **Contexto:** El backend utiliza Prisma ORM v6.19.3 para la persistencia en PostgreSQL. Evaluamos la conveniencia de actualizar a Prisma 7 en esta misma fase de modernización del ecosistema.

---

## 1. Opciones Evaluadas

### Opción A: Mantener Prisma 6.x Parcheado (Recomendado)
*   **Descripción:** Quedarse en la rama Prisma 6 (actualizando al parche más reciente estable, ej: `6.19.3`) durante la migración a Node 24 y el desacoplamiento de la app.
*   **Pros:**
    *   Cero riesgo de breaking changes en consultas de base de datos existentes.
    *   Compatibilidad confirmada con TypeScript 6 y NestJS 11.
    *   Excelente compatibilidad con Node.js 24.
*   **Contras:**
    *   No tiene acceso a las optimizaciones de rendimiento ni a las funciones de telemetría/tracing introducidas en Prisma 7.

### Opción B: Migrar a Prisma v7.x Directamente
*   **Descripción:** Actualizar `@prisma/client` y la CLI de `prisma` a la versión `7.x.x` en este mismo hito.
*   **Pros:**
    *   Acceso a las últimas características de la biblioteca y optimizaciones de velocidad en transacciones concurrentes.
*   **Contras:**
    *   **Acoplamiento de cambios:** Mezclar la migración de un Major del ORM con la migración del runtime de Node.js a v24 y el cambio del middleware a Redis incrementa exponencialmente los puntos de fallo en caso de regresión.
    *   Posibles breaking changes en el tipado y métodos de Prisma Client v7 que requieran refactorizaciones en el backend NestJS.

---

## 2. Decisión Arquitectónica

Se determina **mantener Prisma 6.19.3 (último parche estable compatible) durante esta fase de migración**, posponiendo la actualización a Prisma 7 para un hito independiente posterior.

*   *Justificación:* Conforme a la regla obligatoria de ejecución de "No hacer actualización Big Bang", debemos aislar las capas de falla. Actualizar el motor de base de datos ORM al mismo tiempo que migramos el panel web a Vite y desacoplamos el estado móvil aumentaría dramáticamente el riesgo de regresiones difíciles de diagnosticar. Prisma 6.19.3 funciona perfectamente con Node 24 LTS y Postgres 16.
*   *Plan de Acción:* Una vez estabilizada la migración de Node.js, Vite y Riverpod, se programará una tarea exclusiva para realizar el upgrade a Prisma 7 ejecutando la suite de validación `prisma migrate status` y tests unitarios correspondientes.

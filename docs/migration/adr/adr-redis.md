# docs/migration/adr/adr-redis.md — ADR: Decisiones sobre el Upgrade y Licenciamiento de Redis

*   **Estado:** Propuesto
*   **Fecha:** 2026-06-18
*   **Contexto:** El proyecto utiliza `redis:7-alpine` como motor de caché, rate limiting de login y PubSub para WebSockets. Debemos definir el camino de actualización ante el cambio de licenciamiento de Redis y los riesgos de migración.

---

## 1. Opciones Evaluadas

### Opción A: Mantener y parchear en Redis 7.2.x (Recomendado)
*   **Descripción:** Usar la última versión estable de la rama Redis 7.2 (versión 7.2.5 o similar).
*   **Licenciamiento:** BSD de 3 cláusulas (libre de restricciones comerciales de Redis Ltd).
*   **Pros:**
    *   Compatibilidad 100% garantizada con `ioredis` y el ecosistema NestJS actual.
    *   Sin riesgos de migración ni cambios de comportamiento de comandos.
    *   Seguridad garantizada mediante parches de la comunidad sobre la rama libre.
*   **Contras:**
    *   No tiene acceso a las nuevas funcionalidades de Redis 7.4 o Redis 8.

### Opción B: Migrar a Redis v8.x
*   **Descripción:** Actualizar a la versión Redis 8 en producción.
*   **Licenciamiento:** RSALv2 (Redis Source Available License v2) y SSPLv1 (Server Side Public License v1).
*   **Pros:**
    *   Nuevos tipos de datos, optimización en consumo de memoria y comandos mejorados.
*   **Contras:**
    *   **Cambio de licencia restrictivo:** Impide ofrecer Redis como servicio comercial (SaaS), lo que choca directamente con la estrategia del modelo SaaS del proyecto.
    *   Posibles incompatibilidades menores con clientes antiguos de Node.js.

### Opción C: Migrar a Valkey 8.x
*   **Descripción:** Cambiar la imagen del contenedor a Valkey (el fork de Redis respaldado por la Linux Foundation, compatible a nivel binario).
*   **Licenciamiento:** BSD de 3 cláusulas (código abierto puro y libre).
*   **Pros:**
    *   Soporte directo de la comunidad de código abierto.
    *   Compatibilidad drop-in con clientes de Redis y comandos existentes.
*   **Contras:**
    *   Requiere pruebas adicionales de compatibilidad con `ioredis` en NestJS para asegurar el 100% de paridad en llamadas complejas.

---

## 2. Decisión Arquitectónica

Se determina **conservar y parchear Redis en la última versión estable de la rama 7.2 (ej. `redis:7.2.5-alpine`)** para esta fase.

*   *Justificación:* El proyecto SASGYM es una plataforma SaaS multitenant y el cambio de licenciamiento de Redis a partir de la versión 7.4 (RSALv2/SSPLv1) introduce riesgos legales para la distribución del software. Permanecer en Redis 7.2 (licencia BSD) nos protege legalmente y elimina cualquier riesgo de incompatibilidad de comandos con `ioredis` en el backend.
*   *Acción Futura:* Evaluar la migración a **Valkey** en una fase posterior una vez estabilizado el ecosistema core.

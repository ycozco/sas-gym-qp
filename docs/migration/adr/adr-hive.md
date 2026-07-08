# docs/migration/adr/adr-hive.md — ADR: Decisiones sobre el Almacenamiento Local de Flutter (Hive vs Drift)

*   **Estado:** Propuesto
*   **Fecha:** 2026-06-18
*   **Contexto:** La aplicación móvil SASGYM utiliza `hive` y `hive_flutter` para persistir datos locales de cacheo y preferencias. Analizamos la viabilidad de mantener este motor frente al riesgo de mantenimiento del paquete y las necesidades de estructuración.

---

## 1. Opciones Evaluadas

### Opción A: Mantener Hive con Restricciones (Recomendado)
*   **Descripción:** Conservar Hive v2.x limitando su alcance estrictamente a caché local no sensible y no relacional (ej: rutinas cacheadas, configuraciones de color y preferencias estéticas). Los secretos y tokens de autenticación se almacenan exclusivamente en `flutter_secure_storage`.
*   **Pros:**
    *   No requiere migrar la base de datos local ni reescribir adaptadores complejos en esta fase de desacoplamiento de `GymState`.
    *   Extremadamente rápido en lecturas y escrituras llave-valor.
*   **Contras:**
    *   El paquete `hive` ha tenido periodos largos sin actualizaciones activas (mantenimiento dudoso).
    *   No soporta consultas complejas tipo SQL ni relaciones entre tablas de forma nativa.

### Opción B: Migrar a Drift (SQLite)
*   **Descripción:** Reemplazar Hive por Drift (anteriormente Moor), un ORM relacional y reactivo para Flutter sobre SQLite.
*   **Pros:**
    *   Esquema estructurado estricto con migraciones versionadas locales y tipado seguro.
    *   Mantenimiento sumamente activo por la comunidad de Flutter.
    *   Excelente rendimiento para bases de datos relacionales locales grandes.
*   **Contras:**
    *   **Alto riesgo de migración:** Requiere reescribir toda la capa de persistencia móvil, adaptadores de datos y escribir un plan complejo para migrar datos de cajas de Hive existentes en dispositivos de usuarios reales.
    *   Mayor sobrecarga de configuración y generación de código (build_runner).

---

## 2. Decisión Arquitectónica

Se determina **mantener Hive con restricciones estrictas** para el cacheo offline y preferencias no sensibles, consolidando la separación de datos.

*   *Justificación:* Para esta fase de modernización, reescribir el almacenamiento local a Drift/SQLite añade un riesgo muy alto y una sobrecarga de código que retrasaría el desacoplamiento urgente de `GymState`. Hive funciona de manera eficiente para pares clave-valor sencillos de caché de rutinas y preferencias visuales.
*   *Restricciones Aplicadas:*
    1.  **Cero Secretos en Hive:** Los tokens JWT de la sesión y contraseñas NUNCA se guardarán en Hive. Se utilizará exclusivamente [flutter_secure_storage](file:///d:/proyectos/sas_gym/mobile_app/lib/core/storage/secure_storage.dart).
    2.  **Invalidación de Datos en Logout:** Al cerrar sesión, se limpiarán todas las cajas de Hive asociadas al usuario para evitar la visualización de datos de otros inquilinos o usuarios en el mismo dispositivo físico.

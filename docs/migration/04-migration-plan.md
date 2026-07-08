# docs/migration/04-migration-plan.md — Plan de Migración por Fases e Hitos

Este documento presenta la hoja de ruta y la estrategia de migración incremental por hitos para modernizar la infraestructura, backend, aplicación móvil y el panel web administrativo de SASGYM.

---

## 📅 Hito 1: Reproducibilidad de Infraestructura y Contenedores

### Objetivos:
1.  Eliminar imágenes flotantes o indeterminadas (tags genéricos).
2.  Fijar versiones exactas y digests criptográficos de imágenes base.
3.  Modificar Dockerfiles para implementar compilación multietapa (multi-stage) optimizada de producción.
4.  Configurar la ejecución de contenedores con usuario no-root por razones de seguridad.
5.  Implementar healthchecks nativos para garantizar disponibilidad.

### Tareas:
*   **PostgreSQL:** Actualizar a `postgres:16.14-alpine3.24@sha256:...` (o parche disponible estable).
*   **Redis:** Fijar a `redis:7-alpine@sha256:...` en local y producción.
*   **Nginx:** Fijar a `nginx:alpine@sha256:...` para servir las SPAs de `web_admin` y la build de Flutter.
*   **Healthchecks:**
    *   *Postgres:* `pg_isready -U ${DB_USER} -d ${DB_NAME}`.
    *   *Redis:* `redis-cli ping`.
    *   *API Backend:* `/api/v1/health` o endpoint similar mediante curl local.

---

## 📅 Hito 2: Actualización de Runtime de Backend a Node.js 24 LTS

### Objetivos:
1.  Migrar el backend desde Node v20 (fuera de soporte) a la última versión segura de Node.js v24 LTS.
2.  Actualizar la base del lenguaje de compilación TypeScript y dependencias en [package.json](file:///d:/proyectos/sas_gym/backend/package.json).
3.  Ejecutar regeneración de Prisma Client y tests locales.

### Tareas:
*   Cambiar imagen base en `Dockerfile` de backend a `node:24-alpine` (con digest fijo).
*   Actualizar en `package.json` dependencias incompatibles si surgieran en las pruebas de Jest y ts-jest.
*   Añadir `.nvmrc` y declarar `engines.node` en `"^24.0.0"`.

---

## 📅 Hito 3: Migración de `web_admin` a React SPA + Vite 6

### Objetivos:
1.  Eliminar React y React DOM cargados vía unpkg.com CDN.
2.  Eliminar la dependencia de Babel Standalone en runtime.
3.  Implementar un flujo de construcción estático y modularizado basado en **Vite 6**.
4.  Establecer un archivo de configuración Nginx seguro para producción con CSP estricta y ruteo SPA (fallback a `index.html`).

### Tareas:
*   Crear `web_admin/package.json` con dependencias locales de React, React DOM, Vite y Socket.io-client.
*   Configurar `vite.config.js` y estructurar el bundle de construcción.
*   Modificar `index.html` de `web_admin` para importar `/src/main.jsx` de forma nativa como módulo de ES.
*   Migrar las variables globales en archivos `.jsx` heredados a módulos ES (`import`/`export`).
*   Configurar Nginx en producción para servir el directorio `web_admin/dist` con compresión Gzip y cabeceras de seguridad.

---

## 📅 Hito 4: Desacoplamiento de `GymState` en Flutter (Riverpod v2)

### Objetivos:
1.  Segregar el monolito de estado de 3,200 líneas `GymState` en proveedores reactivos modulares especializados por dominio.
2.  Migrar los widgets y pantallas móviles para consumir estos proveedores estructurados de forma atómica.
3.  Eliminar completamente la clase `GymState` y el `GymStateProvider` tras validar la suite de pruebas.

### Proveedores a Crear:
1.  `AuthProvider`: Gestiona el ciclo de vida de la sesión (tokens JWT y perfil del usuario).
2.  `CashierCajaProvider`: Gestiona las operaciones de caja del día, egresos y recálculo dinámico.
3.  `TrainerProvider`: Gestiona la creación de rutinas, dietas y asignaciones.
4.  `MemberProvider`: Gestiona reservas de clases, visualización de códigos de acceso y puntos.
5.  `TenantConfigProvider`: Mantiene la configuración y estética del gimnasio actual.

---

## 📅 Hito 5: Endurecimiento de Seguridad en Backend

### Objetivos:
1.  Migrar el middleware de seguridad `securityBlockMiddleware` en `main.ts` de mapas locales a Redis.
2.  Garantizar el aislamiento multi-tenant estricto en la API y WebSockets (Socket.io).
3.  Establecer la firma de URLs temporales restrictivas y límites en la carga de archivos a S3.

### Tareas:
*   Reescribir el middleware en `main.ts` para inyectar dinámicamente el `RedisService` y registrar fallos en llaves Redis del tipo `rate:block:global:ip:<ip>`.
*   Actualizar `otplib` a `^13.0.0` y auditar compatibilidad de secretos TOTP heredados.
*   Implementar un endpoint de historial persistente de asistencias para el panel administrativo (`GET /attendance/today`).

---

## 📅 Hito 6: Personalización Dinámica de Branding y Gestión de Perfiles Multirrol

### Objetivos:
1.  **Sincronización de Marca (Branding):** Permitir que el nombre, paleta de colores (primario, secundario, acento) y el icono/logo del gimnasio configurados en el panel de administración se reflejen dinámicamente tras el login tanto en la aplicación móvil como en el panel web administrativo.
2.  **Gestión de Perfiles Avanzada:** Implementar pantallas completas y detalladas de "Mi Perfil" para Administradores, Cajeros y Entrenadores en ambas plataformas, conectándolas de forma segura con el almacenamiento S3 para avatares y actualizando la base de datos de manera atómica.

### Tareas de Personalización de Marca:
*   **Backend API:**
    *   Asegurar que las APIs de configuración del Tenant (`GET /tenants/settings` y `PATCH /tenants/settings`) retornen y guarden correctamente `color_primario`, `color_secundario`, `color_acento`, `logo_url` y `nombre`.
    *   Enviar la configuración del Tenant en el payload de login y renovación de token (`AuthService.login` y `AuthService.refresh`) para inicialización rápida del cliente.
*   **Aplicación Móvil (Flutter):**
    *   Utilizar `TenantConfigProvider` para construir dinámicamente el `ThemeData` de Flutter (definiendo `ColorScheme` con los colores primario, secundario y acento dinámicos del Tenant).
    *   Reemplazar textos duros por el nombre personalizado del Tenant en la barra superior (AppBar) y pantallas principales pos-login.
    *   Cargar el logo de marca personalizado en las cabeceras pos-login.
*   **Panel Web (`web_admin`):**
    *   Crear una función `applyTenantBranding(tenant)` que modifique las variables de CSS personalizadas (`--color-primary`, `--color-secondary`, `--color-accent`) en `:root`.
    *   Modificar dinámicamente el `<title>` de la pestaña y el favicon del navegador al cargar la sesión.
    *   Reflejar inmediatamente los cambios al actualizar las configuraciones en la vista `Config.jsx` mediante WebSockets o recarga de contexto local.

### Tareas de Gestión de Perfiles:
*   **Backend API:**
    *   Habilitar y auditar endpoints para la actualización del perfil laboral de entrenadores en `TrainerProfile` (certificaciones, biografía, especialidad).
    *   Asegurar que la edición de la tabla `User` (nombre completo, celular, DNI, foto) esté disponible para administradores y cajeros.
*   **Frontends (Flutter & Web):**
    *   Diseñar pantallas de perfil interactivas que muestren información del usuario actual.
    *   Integrar subida de avatares a S3 (MinIO) solicitando URLs prefirmadas al backend.
    *   Permitir editar campos de contacto e información específica de especialidad según el rol.


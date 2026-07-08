# docs/migration/00-current-state.md — Estado Actual y Alcance

Este documento describe el estado inicial de la plataforma SASGYM antes de proceder con el plan integral de migración tecnológica, seguridad y desacoplamiento.

---

## 1. Contexto del Proyecto

SASGYM es un sistema SaaS multitenant para la gestión de gimnasios que comprende tres capas críticas:
1.  **Backend API:** Construido sobre NestJS, Node.js y Prisma ORM con base de datos relacional PostgreSQL, cola/caché en Redis y comunicación por WebSockets/Socket.io.
2.  **Aplicación Móvil / PWA:** Desarrollada con Flutter y Dart que sirve a socios, administradores, cajeros y entrenadores.
3.  **Panel Administrativo (`web_admin`):** Una aplicación React que actualmente funciona mediante la carga de recursos de CDN en tiempo de ejecución y transpila JSX en el navegador del cliente a través de Babel Standalone.

---

## 2. Puntos de Dolor y Deuda Técnica Detectada

### A. Monolito de Estado en la Aplicación Móvil
La aplicación móvil depende de una única instancia central de tipo `ChangeNotifier` denominada [GymState](file:///d:/proyectos/sas_gym/mobile_app/lib/data/gym_state.dart) de más de 3,200 líneas de código. Esto provoca:
*   Bajo aislamiento de responsabilidades.
*   Dificultad extrema para mantener, probar y depurar flujos individuales (autenticación, cobros, rutinas).
*   Riesgo alto de re-renders innecesarios y consumo elevado de memoria.

### B. Compilación en Navegador (`web_admin`)
El panel administrativo carece de un flujo de compilación formal. Carga React y Babel standalone vía CDN en tiempo de ejecución, lo que implica:
*   Tiempos de carga significativos e impredecibles por latencia del CDN.
*   Alta carga de procesamiento de CPU en el navegador cliente para transpilear en caliente.
*   Falta de optimización para producción (sin minificación, cacheability inmutable, empaquetado ni ofuscación).
*   Falta de soporte CSP (Content Security Policy) estricta debido a que requiere `unsafe-eval` para Babel.

### C. Vulnerabilidades, Runtimes Obsoletos y Branding Estático
*   El backend corre sobre Node.js 20 Alpine, el cual está fuera de su ciclo de soporte principal y no tiene parches de seguridad recientes.
*   Imágenes Docker del ecosistema utilizan tags genéricos como `:alpine` o `:16-alpine`, lo que introduce flotación e impide la reproducibilidad exacta en entornos de despliegue.
*   Middleware de fuerza bruta (`securityBlockMiddleware` en `main.ts`) almacena fallos en memoria (Map locales), lo que resulta ineficaz en clústeres multirréplica y expone fugas de memoria por falta de recolección estructurada.
*   **Branding y Personalización Visual Estática:** Los frontends (web y móvil) no reflejan dinámicamente el nombre personalizado del gimnasio pos-login, las paletas de colores del Tenant ni el icono/logo cargado, manteniendo componentes de interfaz con estilos duros y sin cohesión de marca en tiempo real.

### D. Gestión Incompleta de Perfiles
*   Los usuarios con roles administrativos (Administrador, Cajero, Entrenador) carecen de interfaces estructuradas de "Mi Perfil" para gestionar sus credenciales, avatares (S3), datos laborales (especialidad, biografía en entrenadores) y datos de contacto de forma interactiva y segura.

---

## 3. Objetivos de la Migración

1.  **Desacoplar GymState:** Segregar el monolito móvil en 5 proveedores de Riverpod estructurados y orientados a dominio.
2.  **Modernizar web_admin:** Migrar a una arquitectura estática SPA empaquetada con **Vite 6** y React local libre de CDNs.
3.  **Endurecer la Seguridad del Backend:** Migrar middleware de seguridad a Redis, asegurar flujos de JWT y autenticación en WebSockets.
4.  **Actualizar Runtimes y Dependencias:** Llevar el backend a Node.js 24 LTS, Postgres parches, consolidar lockfiles y reducir vulnerabilidades de supply chain.
5.  **Garantizar la Reproducibilidad:** Modificar los Dockerfiles a esquemas multi-etapa fijados con digests de imágenes y healthchecks reales.
6.  **Preservar la Funcionalidad:** Asegurar mediante planes de prueba rigurosos que la paridad funcional se mantenga al 100%.

# Vision general

## Proposito

SaaaS GYM busca ser una plataforma de gestion integral para gimnasios bajo modelo SaaS. El producto permite que varios gimnasios usen una misma plataforma, manteniendo los datos separados por tenant y ofreciendo experiencias distintas por rol.

## Superficies del producto

El workspace contiene cuatro superficies importantes:

- API backend: `backend/`, desarrollada con NestJS, Prisma y PostgreSQL.
- App Flutter: `mobile_app/`, pensada para web, Windows y movil.
- Mockups mobile: `mockups/mobile/`, prototipo React/Babel de vistas moviles.
- Mockups web: `mockups/web/`, prototipo React/Babel del panel web.

Tambien existe `proyecto_antiguo/`, que corresponde al sistema heredado Django/CrossHero y contiene backups, venv, media y archivos sensibles. Debe tratarse como referencia historica, no como fuente activa.

## Roles

### Super Administrador

Gestiona la plataforma SaaS: ve gimnasios/clientes, activa y suspende tenants, y puede simular el contexto de una sede. En la app Flutter actual su pantalla es simple y enfocada en estado del cliente.

### Administrador

Opera todo el gimnasio. Tiene dashboard, gestion de miembros, escaner administrativo, cuentas de caja, productos, auditoria, observaciones, anuncios y configuracion.

### Caja

Rol operativo limitado. Atiende cobros, asistencia, ventas de turno, POS, productos permitidos, bajas logicas y logs de solo lectura. No debe tener el alcance total del administrador.

### Entrenador

Gestiona miembros asignados, ejercicios, plantillas, rutinas, progreso e incidencias.

### Miembro

Consume la experiencia final: QR de acceso, membresia, pagos, rutinas, clases, observaciones, notificaciones y registro de esfuerzo.

## Arquitectura conceptual

```text
Clientes Flutter / mockups
        |
        | HTTP + WebSocket
        v
NestJS API
        |
        | Prisma
        v
PostgreSQL compartido
        |
        +-- datos aislados por tenant_id
```

## Estado de madurez

El proyecto está más allá de un scaffold:

- Ya hay módulos backend por dominio.
- Ya hay un esquema Prisma amplio.
- Ya hay app Flutter con roles, pantallas y datos de demo.
- Ya hay servicios para API, almacenamiento seguro, sincronización y WebSocket.
- Ya hay Compose raíz que integra API, DB, frontend web y mockups.

Pero todavía no es una plataforma cerrada de producción:

- Parte del frontend sigue usando datos mock.
- La documentación histórica está dispersa y algunas piezas tienen problemas de codificación.
- Hay endpoints con comportamiento real y otros con simulación.
- Falta una validación reciente automatizada del estado completo.

---

## Contexto de Usuario (Design Thinking)

La plataforma está diseñada teniendo en cuenta el contexto de digitalización de gimnasios pequeños y medianos, resolviendo problemas específicos por rol:

### Arquetipos de Usuario

*   **Marco (El Dueño/Administrador)**: Busca evitar que personas entren sin pagar, controlar la caja diaria y auditar operaciones sin depender de registros manuales en cuadernos o planillas Excel desactualizadas.
*   **Sofía (La Entrenadora/Instructora)**: Requiere diseñar plantillas de rutinas eficientemente para evitar la duplicación de trabajo (escribir la misma rutina a mano) y realizar seguimiento del progreso real de sus alumnos asignados.
*   **Diego (El Miembro/Socio)**: Desea entrenar de forma autónoma con guías visuales legibles, llevar control de su membresía y pagos en línea (Yape/Plin/Tarjeta), y registrar su esfuerzo (RPE, series) sin hojas de papel sueltas.
*   **Carmen (La Cajera/Recepción)**: Su prioridad es validar ingresos rápidamente (en menos de 2 segundos) para evitar colas en la hora punta, y registrar cobros sin margen de error.

### Lineamientos de UX y Diseño Visual (Entorno Real)

Dado el entorno de alta actividad física, poca luz o fatiga ("manos sudadas"), se han adoptado las siguientes directrices:
*   **Botones grandes (Casi cápsulas)**: CTA principales con un alto mínimo de `56px` y diseño `StadiumBorder()`.
*   **Contraste y Temas**:
    *   *Tema Claro* (crema suave `#F4F2EC` y blanco) para Socios, Entrenadores y Caja para máxima legibilidad.
    *   *Tema Oscuro* (negro `#0B0B0C` y tarjetas `#161618`) para el Administrador para reflejar una consola analítica premium y de alta fidelidad.
*   **Acento de Color**: Neon Lime (`#D2FF3A`) para destacar llamadas a la acción, contrastando de manera premium con los fondos oscuros del Admin.
*   **Tipografía Premium**:
    *   `Bricolage Grotesque` para títulos y métricas clave (estilo deportivo fuerte).
    *   `Plus Jakarta Sans` para textos explicativos, descripciones y inputs.
*   **Optimización Móvil**: Compresión del lado del cliente (< 2MB) para cualquier comprobante de pago subido antes del envío por red, evitando saturación del canal o fallos de carga.

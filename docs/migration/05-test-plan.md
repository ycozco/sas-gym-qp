# docs/migration/05-test-plan.md — Plan de Pruebas y Validación

Este documento describe la estrategia de pruebas, validación estática y verificación funcional que se ejecutará durante y después del proceso de migración tecnológica.

---

## 1. Pruebas en Backend NestJS

### Pruebas Unitarias y de Integración
*   Se ejecutará la suite de pruebas del backend mediante Jest:
    ```bash
    npm run test
    ```
*   **Verificación de Seguridad JWT:**
    *   Prueba de expiración forzada de Access Tokens.
    *   Prueba de renovación exitosa de sesión con Refresh Tokens.
    *   Prueba de revocación y anulación de sesiones reemplazadas ante intentos de doble uso de Refresh Token.
*   **Verificación de Multi-tenancy:**
    *   Prueba negativa: Inyectar un usuario del Tenant A y verificar que sus peticiones a recursos del Tenant B devuelvan error de autorización (`403 Forbidden` o `404 Not Found`).
*   **Verificación de Rate Limiting (Redis):**
    *   Ejecutar scripts automatizados para simular 10 peticiones fallidas desde la misma IP y validar que las llamadas subsiguientes devuelvan `429 Too Many Requests` con la clave de bloqueo en Redis.

---

## 2. Pruebas en Aplicación Móvil (Flutter)

### Pruebas de Proveedores e Integración de UI
*   Ejecutar la suite completa de pruebas locales:
    ```bash
    flutter test
    ```
*   **Verificación del Desacoplamiento de GymState:**
    *   Comprobar que todas las pruebas en `test/smoke/*` hayan migrado para usar `ProviderScope` y los proveedores independientes de Riverpod.
    *   Asegurar que no se referencie en ningún archivo de código la clase `GymState`.
*   **Verificación de Conectividad Sockets:**
    *   Simular la pérdida de conectividad y asegurar que el cliente de Socket.io implemente un backoff exponencial de reconexión sin duplicar handlers.

---

## 3. Pruebas en `web_admin` (React + Vite)

### Validación del Build de Vite
*   Ejecutar el pipeline de compilación para producción:
    ```bash
    npm run build
    ```
*   **Verificación de Ejecución en Servidor Estático Nginx:**
    *   Correr la imagen Nginx localmente con la build generada.
    *   Comprobar mediante herramientas de desarrollo del navegador que:
        *   No se carguen scripts externos de CDNs para React ni Babel.
        *   No existan advertencias de transpilación en caliente ni errores de tipos en consola.
        *   El ruteo SPA funcione al refrescar la página en cualquier ruta interna (ejemplo `/asistencia`, `/socios`) gracias al fallback del archivo `nginx.conf`.
*   **Integración WebSockets:**
    *   Simular el ingreso de un miembro mediante código TOTP en el simulador.
    *   Validar que el panel web de Asistencia (`Asistencia.jsx`) agregue reactivamente el registro de check-in mediante WebSockets sin recargar la página.

---

## 4. Matriz de Contratos API/Frontend

Para asegurar que las capas no sufran desalineaciones estructurales, se validarán las firmas de payloads clave:
1.  **Ingreso Biométrico:** `BiometricHandshakeDto` en backend debe emparejarse con el cliente que emite el evento en hardware o simulador.
2.  **DTO de Asistencia:** Las respuestas del endpoint `GET /attendance/today` deben encajar con la interfaz de pintado en React.

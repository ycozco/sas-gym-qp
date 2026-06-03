# Avance actual

Este documento resume el avance real observado en el repositorio.

## Completado o muy avanzado

- Estructura backend NestJS con modulos por dominio.
- Prisma schema amplio para SaaS multi-tenant de gimnasios.
- Seed de backend existente.
- Auth con JWT y bcrypt.
- Guards de auth, roles y tenant.
- Interceptor global de auditoria.
- Endpoints para tenants, pagos, asistencia, rutinas, miembros, observaciones, anuncios y reportes.
- App Flutter con login y pantallas por rol.
- Separacion funcional entre Admin y Caja.
- Pantalla de Superadmin para tenants.
- Barrera visual de tenant suspendido.
- Servicios Flutter para API, secure storage, WebSocket y sync queue.
- Mockups web y mobile disponibles como referencia.
- Compose raiz integrando DB, API, Flutter web, hub estatico y test-client.
- Dockerfile Flutter con targets de CI, build y runtime.

## Parcial o en consolidacion

- Integracion real entre app Flutter y backend: existen servicios, pero muchas pantallas siguen apoyandose en datos mock.
- WebSocket: existe gateway backend y servicio Flutter, pero debe verificarse el flujo evento por evento.
- Offline/sync queue: hay base tecnica, pero falta verificar flujos completos de cola, reintento y persistencia.
- QR/TOTP: hay dependencias y endpoints relacionados, pero debe validarse extremo a extremo.
- Biometria: esta modelada y hay endpoints, pero depende de integracion con hardware real.
- Inventario y puntos: esta modelado, pero hay que confirmar cobertura completa de endpoints y UI productiva.
- Reportes: existe auditoria, pero faltan reportes analiticos completos si el alcance final los requiere.

## Tareas Pendientes y Plan de Mejora Continua

Para llevar la plataforma a un nivel listo para producción, se consolidan las siguientes actividades y mejoras técnicas recomendadas:

### 1. Optimización del Rendimiento de Base de Datos
Se deben implementar **índices compuestos B-Tree** en PostgreSQL (mediante `schema.prisma`) para agilizar las búsquedas particionadas por inquilino:
*   **`Announcement`**: Crear índice compuesto `@@index([tenant_id, activo])` para acelerar la carga de comunicados en el inicio.
*   **`Membership`**: Crear índice compuesto `@@index([tenant_id, user_id, estado])` para optimizar el escaneo y verificación de TOTP en la entrada.
*   **`Payment`**: Crear índice compuesto `@@index([tenant_id, created_at])` para la bandeja analítica del POS.

### 2. Estabilización de Código y Estándares
*   **Formalización de DTOs**: Reemplazar parámetros de tipo `any` en los controladores y servicios del backend por DTOs fuertemente tipados con validaciones de `class-validator`.
*   **Configuración específica de Backend**: Reemplazar el README genérico dentro del subdirectorio `backend/` con las instrucciones propias de inicialización de la API y Prisma.
*   **Endurecimiento de Secretos**: Extraer todas las variables sensibles y claves de desarrollo (`DATABASE_URL`, `JWT_SECRET`, contraseñas de Redis) a un archivo `.env` local excluido en `.gitignore`.

### 3. Validación y Pruebas Automatizadas
*   Ampliar el conjunto de pruebas unitarias y de integración del backend cubriendo los flujos críticos de cuadre de turnos de caja, expiración de código TOTP y validación de reglas de período de gracia.
*   Ejecutar periódicamente las validaciones de CI locales:
    ```powershell
    # Validar Backend
    cd backend && npm run build && npm run test
    
    # Validar Flutter
    cd mobile_app && flutter analyze && flutter test
    ```

### 4. Fragmentación del Estado del Cliente (Flutter)
*   Desmantelar gradualmente la clase monolítica `gym_state.dart` migrando la lógica hacia proveedores especializados de Riverpod (Fase 3 del plan de refactorización).

## Senales de avance por area

| Area | Estado | Evidencia |
|---|---|---|
| Backend modular | Avanzado | `backend/src/modules/*` |
| Modelo de datos | Avanzado | `backend/prisma/schema.prisma` |
| App por roles | Avanzado | `mobile_app/lib/features/*` |
| UI compartida | Avanzado | `mobile_app/lib/widgets/app_shell.dart` |
| Auth frontend | Avanzado | `features/auth/screens/login_screen.dart` y `gym_state.dart` |
| Integracion API | Parcial | `api_client.dart`, endpoints backend y uso mixto mock/API |
| Tiempo real | Parcial | `saas.gateway.ts` y `websocket_service.dart` |
| Offline | Inicial/parcial | `sync_queue_service.dart`, Hive y connectivity |
| Infra local | Avanzado | `docker-compose.yml` raiz |
| Documentacion | Mejorada ahora | `README.md` y `arquitectura/` |

## Criterio de siguiente hito

El siguiente hito sano seria cerrar una vertical completa de negocio con API real:

- Login real.
- Seleccion de tenant.
- Caja abre turno.
- Caja registra venta/cobro.
- Admin ve auditoria y movimientos.
- Flutter consume datos del backend sin mock en esa vertical.
- Tests backend y smoke test Flutter cubren el flujo.

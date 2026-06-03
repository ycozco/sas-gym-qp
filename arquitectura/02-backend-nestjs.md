# Backend NestJS

## Stack

- Framework: NestJS 11.
- Lenguaje: TypeScript.
- ORM: Prisma 6.
- Base de datos: PostgreSQL.
- Auth: JWT y bcrypt.
- Tiempo real: `@nestjs/websockets` con Socket.io.
- Validacion: `class-validator` y DTOs donde aplica.

## Entrada de la API

Archivos principales:

- `backend/src/main.ts`: bootstrap de NestJS.
- `backend/src/app.module.ts`: registra modulos de negocio y el interceptor global de auditoria.
- `backend/src/prisma/prisma.service.ts`: cliente Prisma.
- `backend/prisma/schema.prisma`: modelo de datos.
- `backend/prisma/seed.ts`: datos semilla.

## Modulos activos

| Modulo | Ruta base | Responsabilidad |
|---|---|---|
| `auth` | `/auth` | Login, recuperacion simulada y perfil autenticado. |
| `tenants` | `/tenants` | Listado y activacion/suspension de gimnasios. |
| `members` | `/members` | Busqueda de miembros y logs de entrenamiento. |
| `payments` | `/payments` | Pagos, comprobantes, aprobacion, POS, caja y membresias. |
| `attendance` | `/attendance` | QR/TOTP, huella y registro de asistencia. |
| `routines` | `/routines` | Rutina activa del miembro. |
| `observations` | `/observations` | Incidencias/observaciones del gimnasio. |
| `announcements` | `/announcements` | Anuncios, banners y activacion. |
| `reports` | `/reports` | Logs de auditoria. |

## Seguridad y Aislamiento Multi-Tenant

La arquitectura usa tres mecanismos principales en la capa de red/controlador:

- `AuthGuard`: valida JWT y adjunta el usuario al request.
- `RolesGuard`: restringe endpoints por rol cuando se declara metadata de roles.
- `TenantGuard`: valida el contexto de tenant (`X-Tenant-ID` en header) contra el token JWT del usuario para evitar accesos cruzados.

Los decoradores relevantes viven en `backend/src/core/decorators/`:
- `@Public()`
- `@Roles(...)`
- `@TenantId()`

### Aislamiento Automatizado en Capa de Datos (Prisma Extension)

Para evitar la dependencia manual de añadir `where: { tenant_id }` en cada servicio, se propone e implementa el uso de `AsyncLocalStorage` de Node.js acoplado a una **Prisma Client Extension**:

```typescript
// prisma/extensions/multi-tenant.extension.ts
import { Prisma } from '@prisma/client';
import { AsyncLocalStorage } from 'async_hooks';

export const tenantContext = new AsyncLocalStorage<{ tenantId: string }>();

export const multiTenantExtension = Prisma.defineExtension((client) => {
  return client.$extends({
    query: {
      $allModels: {
        async $allOperations({ model, operation, args, query }) {
          const store = tenantContext.getStore();
          // Exceptuar tablas globales del filtrado automático
          if (store?.tenantId && model !== 'Tenant' && model !== 'AuditLog' && model !== 'PointsConfig') {
            args.where = {
              ...args.where,
              tenant_id: store.tenantId,
            };
          }
          return query(args);
        },
      },
    },
  });
});
```

## Auditoría y Sanitización Segura

`backend/src/core/interceptors/audit.interceptor.ts` está registrado como `APP_INTERCEPTOR`. Su función es capturar operaciones de escritura exitosas y crear registros en `AuditLog`.

Para mitigar el riesgo de bloqueo del hilo de ejecución único de Node.js por llamadas de sanitización profunda recursiva en payloads masivos, se implementa una **barrera de profundidad máxima (Depth Boundary = 3)** en la función helper:

```typescript
const sanitizeDeep = (obj: any, currentDepth = 0, maxDepth = 3): any => {
  if (obj === null || typeof obj !== 'object' || currentDepth >= maxDepth) {
    return typeof obj === 'object' && obj !== null ? '[Object Max Depth Exceeded]' : obj;
  }
  
  if (Array.isArray(obj)) {
    return obj.map(item => sanitizeDeep(item, currentDepth + 1, maxDepth));
  }
  
  const sanitized: any = {};
  for (const key of Object.keys(obj)) {
    const lowerKey = key.toLowerCase();
    if (['pass', 'secret', 'token', 'hash', 'key'].some(kw => lowerKey.includes(kw))) {
      sanitized[key] = '********';
    } else {
      sanitized[key] = sanitizeDeep(obj[key], currentDepth + 1, maxDepth);
    }
  }
  return sanitized;
};
```

La auditoría estructurada y sanitizada es fundamental para:

- Bajas lógicas (Soft Delete) preservando historial.
- Anulaciones de ventas y movimientos de caja.
- Cambios de configuración del gimnasio (días de gracia, alertas).
- Operaciones administrativas y de control de cajeros.
- Trazabilidad completa por tenant y usuario.

## Tiempo real

`backend/src/core/gateways/saas.gateway.ts` implementa un gateway Socket.io. La intencion funcional es agrupar clientes por tenant y emitir eventos como suspension de gimnasio o aprobacion de pago.

En la app Flutter existe un servicio complementario en `mobile_app/lib/core/services/websocket_service.dart`.

## Observaciones tecnicas

- El README dentro de `backend/` aun es el scaffold generico de NestJS.
- El Compose raiz ejecuta `npx prisma db push --force-reset`, por lo que el entorno local esta orientado a desarrollo y puede resetear datos.
- Algunos documentos antiguos mencionan Firebase/FCM y almacenamiento externo; en el codigo actual no se observo una integracion productiva completa de esos proveedores.

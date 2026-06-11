# SaaaS GYM

SaaaS GYM es una plataforma SaaS multi-tenant para operar gimnasios. El sistema combina una app Flutter, un sistema web completo y una API NestJS con PostgreSQL para cubrir administracion, caja, asistencia, pagos, rutinas, auditoria y gestion de tenants.

Este README es la entrada general del proyecto. La documentacion tecnica detallada esta en `arquitectura/`.

## Vision del producto

El producto permite administrar varios gimnasios desde una misma plataforma. Cada gimnasio se modela como un tenant, y sus datos operativos se separan por `tenant_id`.

Roles funcionales:

- Super Administrador: gestiona clientes SaaS, activacion y suspension de gimnasios.
- Administrador: controla miembros, pagos, caja, productos, anuncios, auditoria y configuracion.
- Caja: registra cobros, ventas, asistencia, turnos y operaciones limitadas.
- Entrenador: gestiona miembros asignados, ejercicios, rutinas y progreso.
- Miembro: consulta QR de acceso, membresia, pagos, rutinas, clases y observaciones.

## Arquitectura actual

```text
App Flutter / Flutter Web / Panel Web Admin
              |
              | HTTP + WebSocket
              v
        Backend NestJS API
              |
              | Prisma ORM
              v
        PostgreSQL multi-tenant
```

### App Flutter

La app principal vive en `mobile_app/`. Esta organizada por roles y puede correr como app local, app Windows, app web Flutter o contenedor Nginx.

Componentes principales:

- `mobile_app/lib/main.dart`: inicializacion.
- `mobile_app/lib/app.dart`: login, seleccion por rol y barrera SaaS.
- `mobile_app/lib/features/*`: pantallas por rol.
- `mobile_app/lib/data/gym_state.dart`: estado de sesion y datos demo.
- `mobile_app/lib/core/network/api_client.dart`: cliente HTTP.
- `mobile_app/lib/core/services/websocket_service.dart`: canal de eventos.
- `mobile_app/lib/widgets/app_shell.dart`: componentes compartidos.

Tecnologias:

- Flutter / Dart.
- Material 3.
- Dio.
- Flutter Secure Storage.
- Socket.io client.
- Hive y Connectivity Plus.
- QR Flutter y OTP.

### Sistema web completo

En este proyecto, "sistema web" incluye todos los elementos web y de servidor:

- Backend/API NestJS en `backend/`.
- Flutter web compilado desde `mobile_app/` y servido por Nginx.
- Panel web admin real en `web_admin/`, servido por Nginx en `/web/`.
- Hub estatico en `index.html`.
- Mockups web en `mockups/web/` como referencia/fallback, no como entrada principal.
- Mockups mobile en `mockups/mobile/`.
- Servicios Docker definidos en `docker-compose.yml`.

El hub estatico corre en `http://localhost:8282`, el panel web admin real en `http://localhost:8282/web/index.html`, la app Flutter web en `http://localhost:8383` y la API en `http://localhost:3000`.

### Backend/API

El backend vive en `backend/` y usa:

- NestJS 11.
- TypeScript.
- Prisma ORM 6.
- PostgreSQL 15.
- JWT y bcrypt.
- Guards de autenticacion, roles y tenant.
- Interceptor global de auditoria.
- WebSockets con Socket.io.

Modulos principales:

- `auth`: login, recuperacion y perfil.
- `tenants`: gestion de gimnasios SaaS.
- `members`: busqueda y logs de entrenamiento.
- `payments`: comprobantes, POS, caja y membresias.
- `attendance`: QR/TOTP, huella y asistencia.
- `routines`: rutina activa.
- `observations`: incidencias.
- `announcements`: anuncios.
- `reports`: auditoria.

### Base de datos

El modelo central esta en `backend/prisma/schema.prisma`.

Dominios modelados:

- Tenants y usuarios.
- Perfiles de entrenador y miembro.
- Membresias y pagos.
- Caja y movimientos.
- Asistencia y biometria.
- Rutinas, ejercicios y sesiones.
- Observaciones y anuncios.
- Productos, inventario y puntos.
- Auditoria.

## Estructura del repositorio

```text
sas_gym/
|-- README.md
|-- docker-compose.yml
|-- index.html
|-- arquitectura/
|-- docs/
|-- backend/
|   |-- src/
|   |-- prisma/
|   |-- test/
|   |-- Dockerfile
|   |-- package.json
|-- mobile_app/
|   |-- lib/
|   |-- test/
|   |-- Dockerfile
|   |-- pubspec.yaml
|-- web_admin/
|-- mockups/
|   |-- mobile/
|   |-- web/
|-- proyecto_antiguo/
```

`proyecto_antiguo/` contiene el sistema heredado Django/CrossHero, backups y artefactos historicos. No debe publicarse ni servirse como estatico.

## Estado actual del avance (Detallado)

El desarrollo del ecosistema SaaaS GYM ha avanzado desde una fase de prototipo inicial a un sistema robusto, con altos estándares de seguridad en el backend y una integración sustancial de funcionalidades en la app móvil. A continuación se detalla el estado actual por áreas:

### 🔒 Backend (NestJS + Prisma + PostgreSQL)
*   **Autenticación y Seguridad (Robustecido)**:
    *   **Tokens Cortos**: El token de acceso JWT cuenta con una expiración reducida y configurable por entorno (`JWT_ACCESS_TTL`, por defecto `15m`).
    *   **Rotación de Refresh Tokens**: Implementación de refresh tokens rotativos administrados de forma segura mediante una cookie de servidor `sasgym_refresh` con directivas `HttpOnly`, `SameSite=Strict` y `Secure`. Cada llamada de refresco invalida la sesión previa (`replaced_by_id`).
    *   **Almacenamiento de Tokens**: Se guarda únicamente el hash criptográfico SHA-256 de los tokens en la base de datos, previniendo su fuga en caso de brecha en base de datos.
    *   **Protección contra Ataques**: Integración global de Helmet, control de tasa de peticiones mediante `@nestjs/throttler` (100 req/min/IP) y middleware de bloqueo in-memory de IPs tras detectar comportamiento anómalo (10 fallos de login en 5 min bloquean la IP por 15 min).
*   **Integridad Transaccional**:
    *   Uso de transacciones atómicas Prisma (`prisma.$transaction`) para operaciones financieras críticas, tales como cobros en caja/POS, venta de membresías y el procesamiento de canjes de puntos para evitar estados inconsistentes.
    *   Los registros de usuarios autogenerados en operaciones de caja o venta rápida ya no usan cadenas de texto plano; se utiliza un hash de contraseña bcrypt aleatorio e inoperable para inicio de sesión directo.
*   **Dominios y Lógica de Negocio (Completados)**:
    *   **Módulo de Clases y Reservas (`Schedules`)**: Listado, reserva de cupos y cancelación de clases grupales sincronizado por sede e inquilino. Soporta cálculo en tiempo real de disponibilidad de aforo y colas de espera automáticas (`WAITLIST` / `CONFIRMED`).
    *   **Módulo de Gamificación (`Points`)**: Creación de catálogos de fidelización, cálculo de balances acumulados y procesador de canje de puntos por productos físicos o extensiones de membresía.
    *   **Módulo de Rutinas y Seguimiento (`Routines`)**: Creación de catálogo de ejercicios y plantillas por entrenadores, asignación de rutinas semanales por miembro, registro y analítica de volumen de carga física (`weeklyLoads` e históricos de repeticiones).

### 📱 Aplicación Móvil (Flutter / Dart)
*   **Caché y Seguridad Local**:
    *   Toda la base de datos de almacenamiento local (cajas de Hive `gym_cache` y la cola de operaciones fuera de línea `sync_queue_box`) está cifrada mediante llaves de alta entropía custodiadas en el almacenamiento seguro nativo del sistema operativo (`Flutter Secure Storage`).
    *   Implementación de limpieza completa de caché local de rutinas, credenciales y transacciones pendientes durante el proceso de cierre de sesión (`logout`).
*   **Interfaz y Flujos Funcionales**:
    *   Mecanismo de generación de códigos QR dinámicos para acceso al gimnasio basado en el secreto real emitido por el backend (`qr_secret`) para cada perfil de miembro, eliminando la derivación predecible a partir del número de DNI.
    *   Integración del dashboard de fidelización para miembros (puntos ganados vs. disponibles) y vistas interactivas de reserva de clases directamente conectadas a la API real en modo backend.
    *   Panel de Entrenador mejorado, permitiendo la asignación real de plantillas de rutinas creadas y la visualización interactiva del progreso del miembro (volumen promedio de entrenamiento semanal).

### 🖥️ Panel Web de Administración (React + Babel + CSS)
*   Estructura estática optimizada que se ejecuta sin necesidad de un paso complejo de compilación web, integrando componentes dinámicos para visualizar métricas generales del inquilino (tenants), logs de auditoría global del sistema y configuración adaptativa de tema visual sincronizado.

### 🐳 Infraestructura y Despliegue Local
*   Se eliminó el arranque destructivo del esquema de base de datos (`force-reset`) y el seed automático del inicio del contenedor de base de datos en Docker.
*   Separación de flujos de configuración mediante `.env` locales e inicio del backend bajo el comando de producción compilado `start:prod` de forma predeterminada.
*   Redes de Docker segregadas: red interna privada para la base de datos PostgreSQL (`internal-net`) inaccesible desde el host principal y redes públicas de servicios para la API y los frontends (`public-net`).

### 🔍 Resumen del Estado de Validación
*   **Calidad de Código**: Compilación sin warnings ni problemas de análisis (`flutter analyze` limpio, compilación NestJS exitosa).
*   **Testing**: Cobertura de pruebas unitarias locales y de integración del backend funcionando sin incidencias. Tareas de automatización ejecutándose dentro del contenedor de CI dedicado `flutter-ci`.

---

## 🚀 Proyección Futura

Para conocer los hitos restantes del roadmap, los pendientes de despliegue multi-réplica, el plan de refactorización de estados hacia Riverpod y los siguientes pasos de integración de hardware biométrico, consulta el archivo detallado:
*   [proyeccion-futura.md](file:///d:/proyectos/sas_gym/proyeccion-futura.md)

Para un desglose de los hitos técnicos internos históricos, consulta:
*   [07-avance-actual.md](file:///d:/proyectos/sas_gym/arquitectura/07-avance-actual.md)


## Comandos rapidos

### App movil por ambiente

```powershell
cd mobile_app
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
flutter build web --release --dart-define=APP_ENV=staging --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=http://localhost:3000/api/v1
flutter build apk --debug --flavor dev --dart-define=APP_ENV=dev --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Para builds release Android, copiar `mobile_app/android/key.properties.example` a `mobile_app/android/key.properties` y completar valores locales. No commitear keystore ni claves reales.

### Despliegue local completo

```powershell
docker compose up --build
```

Servicios esperados:

- API NestJS: `http://localhost:3000`
- Panel web admin real: `http://localhost:8282/web/index.html`
- Flutter web: `http://localhost:8383`
- Hub/mockups/docs: `http://localhost:8282`
- PostgreSQL: `127.0.0.1:5432`

### Backend

```powershell
cd backend
npm install
npm run build
npm run test
npm run test:e2e
npm run start:dev
```

### Flutter

```powershell
cd mobile_app
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

### Integracion y logs

```powershell
docker compose ps
docker compose logs api
docker compose logs frontend-web
docker compose logs web
```

## Documentacion principal

- `arquitectura/README.md`: indice tecnico.
- `arquitectura/01-vision-general.md`: vision y roles.
- `arquitectura/02-backend-nestjs.md`: backend/API.
- `arquitectura/03-app-flutter.md`: app Flutter.
- `arquitectura/04-modelo-datos.md`: modelo Prisma.
- `arquitectura/05-apis-y-flujos.md`: endpoints y flujos.
- `arquitectura/06-infraestructura.md`: Docker, redes y puertos.
- `arquitectura/07-avance-actual.md`: estado actual.
- `arquitectura/08-plan-verificacion-pruebas.md`: plan de pruebas.
- `arquitectura/09-guia-despliegue.md`: guia de despliegue.

## Notas importantes

- La carpeta real del proyecto es `sas_gym`, no `saas_gym`.
- `backend/README.md` conserva el README generico de NestJS; este README raiz es el README general del proyecto.
- El Compose raiz ejecuta `npx prisma db push --force-reset`; esto puede recrear datos de desarrollo.
- Los secretos actuales son de desarrollo y deben reemplazarse antes de produccion.

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
App Flutter / Flutter Web / Mockups Web
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
- Hub estatico en `index.html`.
- Mockups web en `mockups/web/`.
- Mockups mobile en `mockups/mobile/`.
- Servicios Docker definidos en `docker-compose.yml`.

El hub estatico corre en `http://localhost:8282` y sirve la navegacion hacia mockups y documentacion. La app Flutter web corre en `http://localhost:8383`. La API corre en `http://localhost:3000`.

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
|-- mockups/
|   |-- mobile/
|   |-- web/
|-- proyecto_antiguo/
```

`proyecto_antiguo/` contiene el sistema heredado Django/CrossHero, backups y artefactos historicos. No debe publicarse ni servirse como estatico.

## Estado actual del avance

Avanzado:

- Backend modular con dominios principales.
- Esquema Prisma amplio para operacion SaaS de gimnasios.
- App Flutter con pantallas por rol.
- Separacion funcional entre Admin y Caja.
- Login, tenant suspendido y estado compartido en Flutter.
- Docker Compose raiz con PostgreSQL, API, Flutter web, hub estatico y cliente de pruebas.

Parcial o pendiente de consolidacion:

- Integracion completa entre Flutter y API real.
- Pruebas unitarias especificas por dominio.
- Pruebas E2E de flujos de negocio.
- Validacion completa de WebSocket, QR/TOTP, offline y biometria.
- Endurecimiento de secretos y migraciones para produccion.

Lee el detalle en `arquitectura/07-avance-actual.md`.

## Comandos rapidos

### Despliegue local completo

```powershell
docker compose up --build
```

Servicios esperados:

- API NestJS: `http://localhost:3000`
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

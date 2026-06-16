# Proyeccion tecnica y hallazgos de seguridad - SaaaS GYM

## Alcance

Revision profunda del aplicativo Flutter, backend NestJS, modelo Prisma, WebSocket, carga de archivos, contenedores Docker y politicas de despliegue observables en el repositorio.

Superficies revisadas:

- App movil / Flutter: `mobile_app/`.
- Backend / sistema: `backend/`, `docker-compose.yml`, `backend/Dockerfile`, `mobile_app/Dockerfile`.
- Seguridad operacional: secretos, CORS, uploads, red, logs, cache, colas offline, autenticacion y tenants.

Limitacion: se intento ejecutar `flutter analyze`, pero el sandbox devolvio `windows sandbox: spawn setup refresh`. Los hallazgos se basan en inspeccion estatica de codigo y configuracion.

## Escala de criticidad

- P0 Critico: puede bloquear compilacion, permitir acceso indebido, comprometer datos o romper despliegue productivo.
- P1 Alto: riesgo serio de seguridad, integridad de negocio o estabilidad.
- P2 Medio: deuda tecnica, rendimiento, mantenibilidad o riesgo operacional moderado.
- P3 Bajo: mejora recomendada, higiene tecnica o pulido de producto.

---

# Hallazgos P0 - Criticos

## App movil

### P0-A1. Posible error de compilacion en payload de POS

Ubicacion:

- `mobile_app/lib/data/gym_state.dart`
- Patron: `'payments': ?payments`

Riesgo:

- Sintaxis aparentemente invalida en Dart.
- Puede impedir `flutter analyze`, `flutter test`, build web, APK y contenedor Flutter CI.

Impacto:

- Bloqueo total del aplicativo si el archivo se compila.

Accion recomendada:

- Construir el mapa del request de forma condicional:

```dart
final data = {
  'memberDni': memberDni,
  'cartItems': cartItems,
  'total': total,
  'paymentMethod': paymentMethod,
  if (payments != null) 'payments': payments,
};
```

### P0-A2. TOTP/QR inseguro por secreto derivado del DNI

Ubicaciones:

- `mobile_app/lib/features/member/widgets/full_qr_view.dart`
- `mobile_app/lib/features/cashier/widgets/cashier_scan_page.dart`
- `mobile_app/lib/features/admin/widgets/admin_scanner_page.dart`
- `backend/src/modules/attendance/attendance.service.ts`

Patron observado:

```dart
final secret = '${dni}_secure_totp_secret_key_2026';
```

Riesgo:

- El secreto es predecible y esta embebido en el cliente.
- Caja/Admin pueden generar tokens para cualquier DNI.
- El backend acepta fallback con `user.dni + '_secure_totp_secret_key_2026'`.

Impacto:

- Bypass del control de acceso por QR.
- Un atacante que conozca un DNI puede generar tokens validos.

Accion recomendada:

- Eliminar fallback basado en DNI en backend.
- Generar `qr_secret` aleatorio por usuario en backend.
- En produccion, Caja/Admin no deben generar TOTP; deben escanear payload emitido por el miembro.
- Separar simulador QR de modo productivo mediante feature flag.

### P0-A3. Credenciales demo embebidas en cliente

Ubicacion:

- `mobile_app/lib/features/auth/screens/login_screen.dart`

Patrones:

- `super_secure_pass`
- `admin_secure_pass`
- `caja_secure_pass`
- `trainer_secure_pass`
- `member_secure_pass`

Riesgo:

- Credenciales visibles en web build/APK.
- Si existen en backend real, habilitan acceso directo a roles privilegiados.

Impacto:

- Compromiso de cuentas administrativas.
- Fuga de capacidades de caja/superadmin.

Accion recomendada:

- Compilar panel demo solo con `--dart-define=ENABLE_DEMO_LOGIN=true`.
- Removerlo en staging/prod.
- Rotar contrasenas semilla si ya fueron usadas.

### P0-A4. API configurada por HTTP y localhost

Ubicacion:

- `mobile_app/lib/core/network/api_client.dart`

Patrones:

- `http://localhost:3000/api/v1`
- `http://10.0.2.2:3000/api/v1`

Riesgo:

- JWT viaja sin TLS.
- Web build productivo no podra consumir backend remoto si queda `localhost`.

Impacto:

- Robo de tokens por red.
- Falla de despliegue en produccion.

Accion recomendada:

- Usar `--dart-define=API_BASE_URL=https://api.dominio.com/api/v1`.
- Forzar HTTPS fuera de desarrollo.
- Considerar certificate pinning para movil si se despliega en redes no confiables.

## Backend / sistema

### P0-B1. Secretos hardcoded y fallback de secretos productivos

Ubicaciones:

- `docker-compose.yml`
- `backend/docker-compose.yml`
- `backend/src/modules/auth/auth.module.ts`
- `backend/src/core/guards/auth.guard.ts`
- `backend/src/core/gateways/saas.gateway.ts`
- `backend/src/modules/attendance/fingerprint.service.ts`

Patrones:

- `JWT_SECRET=gymsmart_secure_jwt_secret_key_2026`
- fallback `process.env.JWT_SECRET || 'gymsmart_secure_jwt_secret_key_2026'`
- fallback `HUELLA_SECRET_KEY || 'huella_secure_secret_key_2026'`

Riesgo:

- Si falta variable de entorno, el sistema usa un secreto conocido.
- Cualquier build con codigo fuente permite firmar/verificar tokens o firmas biometricas.

Impacto:

- Tokens JWT falsificables.
- Registros biometricos falsificables.

Accion recomendada:

- Eliminar fallbacks hardcoded.
- Fallar el arranque si falta `JWT_SECRET` o `HUELLA_SECRET_KEY`.
- Usar secrets del orquestador o variables externas.
- Rotar secretos actuales.

### P0-B2. Compose reinicia base de datos con `--force-reset`

Ubicacion:

- `docker-compose.yml`
- `backend/docker-compose.yml`

Patron:

```sh
npx prisma db push --force-reset && npx prisma generate && npx prisma db seed && npm run start:dev
```

Riesgo:

- Cada despliegue puede borrar schema/datos.
- Mezcla despliegue con seed de desarrollo.

Impacto:

- Perdida total de datos en produccion si se reutiliza Compose.

Accion recomendada:

- Quitar `--force-reset` de cualquier compose no-dev.
- Usar `prisma migrate deploy`.
- Separar seed de desarrollo de despliegue.

### P0-B3. Backend y contenedor API arrancan en modo desarrollo

Ubicaciones:

- `backend/Dockerfile`
- `docker-compose.yml`

Patrones:

- `CMD ["npm", "run", "start:dev"]`
- `npm run start:dev`
- volumen `./backend:/app`

Riesgo:

- Watch mode en contenedor.
- Codigo fuente montado dentro del servicio.
- Menor control sobre runtime y estabilidad.

Impacto:

- Despliegue inseguro/inestable.
- Cambios locales afectan servicio en caliente.

Accion recomendada:

- Crear imagen productiva multi-stage.
- Ejecutar `node dist/main`.
- No montar codigo fuente en produccion.
- Instalar solo dependencias productivas.

### P0-B4. CORS abierto en HTTP y WebSocket

Ubicaciones:

- `backend/src/main.ts`
- `backend/src/core/gateways/saas.gateway.ts`

Patrones:

- `app.enableCors()`
- `@WebSocketGateway({ cors: { origin: '*' } })`

Riesgo:

- Cualquier origen puede llamar API o iniciar handshake WebSocket.
- Combinado con tokens robados o XSS, aumenta superficie de ataque.

Impacto:

- Exposicion innecesaria de API multi-tenant.
- Riesgo de abuso desde dominios externos.

Accion recomendada:

- Definir allowlist por ambiente:
  - `http://localhost:8383`
  - dominio web productivo
  - dominio admin productivo
- Aplicar CORS restringido tambien a WebSocket.

---

# Hallazgos P1 - Altos

## App movil

### P1-A1. Cache y cola offline sin cifrado

Ubicaciones:

- `mobile_app/lib/main.dart`
- `mobile_app/lib/core/services/sync_queue_service.dart`
- `mobile_app/lib/data/gym_state.dart`

Patrones:

- `Hive.openBox('gym_cache')`
- `Hive.openBox('sync_queue_box')`
- `offline_workout_queue`

Riesgo:

- Datos de rutinas, sesiones, payloads offline y posiblemente datos personales quedan persistidos sin cifrado.
- Cola offline no tiene TTL, max retries ni idempotencia consistente.

Impacto:

- Exposicion de datos personales en dispositivo.
- Duplicacion de operaciones al reconectar.

Accion recomendada:

- Cifrar cajas Hive con llave protegida por secure storage.
- Agregar `idempotencyKey`, `attempts`, `lastAttemptAt`, `expiresAt`.
- No encolar operaciones financieras sin token idempotente.

### P1-A2. Estado global concentrado y rebuilds amplios

Ubicacion:

- `mobile_app/lib/data/gym_state.dart`

Riesgo:

- `GymState` concentra auth, pagos, caja, anuncios, auditoria, asistencia, WebSocket, cache, demo y API.
- `notifyListeners()` global puede reconstruir pantallas no relacionadas.

Impacto:

- Deuda tecnica alta.
- Testing complejo.
- Riesgo de errores cruzados entre roles.

Accion recomendada:

- Separar controladores por dominio.
- Mantener fachada temporal para compatibilidad.
- Migrar gradualmente a Riverpod/Bloc o notifiers independientes.

### P1-A3. Logs con errores completos

Ubicaciones:

- `mobile_app/lib/data/gym_state.dart`
- `mobile_app/lib/core/services/websocket_service.dart`
- `mobile_app/lib/core/services/sync_queue_service.dart`

Riesgo:

- `debugPrint('$e')` puede revelar rutas, payloads, DNIs, emails o tokens si Dio incluye detalles.

Impacto:

- Fuga de datos en logs locales o herramientas de soporte.

Accion recomendada:

- Crear logger sanitizado.
- En release, ocultar payloads y headers.
- Mostrar errores de usuario por codigos normalizados.

### P1-A4. Carga de imagenes en memoria

Ubicaciones:

- `mobile_app/lib/features/member/widgets/pay_membership_view.dart`
- `mobile_app/lib/features/member/screens/member_screen.dart`

Patron:

- `FilePicker.pickFiles(... withData: true)`

Riesgo:

- Archivos grandes se cargan completos en memoria antes de comprimir.
- Extension permitida no garantiza MIME real.

Impacto:

- Crash en dispositivos modestos.
- Riesgo de subida de archivo no esperado si backend no valida contenido real.

Accion recomendada:

- Validar tamano antes de leer bytes.
- Evitar `withData: true` donde sea posible.
- Validar MIME real en backend.
- Aplicar compresion segura y limites visibles en UI.

### P1-A5. Android release firmado con debug key y package generico

Ubicaciones:

- `mobile_app/android/app/build.gradle.kts`
- `mobile_app/android/app/src/main/AndroidManifest.xml`

Patrones:

- `applicationId = "com.example.flutter_app"`
- `signingConfig = signingConfigs.getByName("debug")`
- `android:label="flutter_app"`

Riesgo:

- Build release no apto para distribucion real.
- Identidad de app generica.

Impacto:

- Bloquea publicacion segura en Play Store o distribucion controlada.

Accion recomendada:

- Definir applicationId real.
- Configurar keystore release.
- Separar flavors dev/staging/prod.

## Backend / sistema

### P1-B1. No hay rate limiting ni proteccion anti fuerza bruta

Ubicaciones:

- `backend/src/modules/auth/auth.controller.ts`
- `backend/src/modules/auth/auth.service.ts`

Riesgo:

- Login y forgot-password son publicos.
- No se observa throttling por IP, cuenta o tenant.

Impacto:

- Ataques de fuerza bruta.
- Enumeracion indirecta por mensajes de error.

Accion recomendada:

- Agregar `@nestjs/throttler`.
- Rate limit especial para `/auth/login` y `/auth/forgot-password`.
- Bloqueo temporal por cuenta/IP.
- Alertas por intentos anormales.

### P1-B2. JWT sin expiracion explicita visible y sin refresh flow operativo

Ubicaciones:

- `backend/src/modules/auth/auth.service.ts`
- `backend/prisma/schema.prisma` contiene `refresh_token`, pero no se observa flujo activo.

Riesgo:

- Tokens pueden quedar validos por demasiado tiempo si no se configura `expiresIn`.
- Logout solo borra cliente, no invalida token servidor.

Impacto:

- Robo de token mantiene acceso.

Accion recomendada:

- Definir `accessToken` corto.
- Implementar refresh token rotativo y revocable.
- Guardar hash de refresh token, no token plano.

### P1-B3. `AnnouncementsController` no usa `TenantGuard`

Ubicacion:

- `backend/src/modules/announcements/announcements.controller.ts`

Patron:

- `@UseGuards(AuthGuard, RolesGuard)`
- Usa `@TenantId()` pero no aplica `TenantGuard`.

Riesgo:

- Si `@TenantId()` depende de header, no se valida contra JWT.
- Puede consultar o escribir con tenant incorrecto si el decorador toma header no validado.

Impacto:

- Riesgo de fuga cross-tenant en anuncios.

Accion recomendada:

- Agregar `TenantGuard`.
- Asegurar que `@TenantId()` use tenant validado desde JWT o request.
- Test E2E cross-tenant.

### P1-B4. Uploads servidos publicamente sin autenticacion

Ubicaciones:

- `backend/src/main.ts`
- `backend/src/modules/payments/payments.controller.ts`
- `backend/src/modules/observations/observations.controller.ts`

Patrones:

- `app.use('/uploads', express.static(...))`
- Comprobantes en `/uploads/receipts/...`
- Observaciones en `/uploads/observations/...`

Riesgo:

- Comprobantes y fotos pueden ser accesibles si se conoce URL.
- No hay autorizacion por tenant en archivos estaticos.

Impacto:

- Fuga de comprobantes de pago e imagenes de observaciones.

Accion recomendada:

- Servir archivos mediante endpoint autenticado y validado por tenant.
- Usar URLs firmadas o storage privado.
- No exponer `/uploads` directamente.

### P1-B5. Validacion de uploads basada en mimetype declarado

Ubicaciones:

- `payments.controller.ts`
- `observations.controller.ts`

Riesgo:

- `file.mimetype` puede ser manipulado.
- Extension se toma desde `originalname`.

Impacto:

- Posible almacenamiento de archivo malicioso o no esperado.

Accion recomendada:

- Validar magic bytes.
- Reescribir extension segun tipo real.
- Escanear archivos si se opera en produccion.
- Almacenar fuera del webroot.

### P1-B6. Operaciones financieras sin transaccion atomica

Ubicaciones:

- `payments.service.ts`
- `cashier-session.service.ts`
- `membership-billing.service.ts`

Riesgo:

- Se crean membresias, pagos, movimientos y puntos en varias escrituras separadas.
- Si falla una escritura intermedia, puede quedar estado parcial.

Impacto:

- Descuadre de caja.
- Membresia activa sin pago completo o pago sin movimiento.
- Puntos inconsistentes.

Accion recomendada:

- Usar `prisma.$transaction`.
- Definir invariantes de caja/pago/membresia.
- Tests de fallo intermedio.

### P1-B7. Usuarios anonimos y auto-creacion con `password_hash: 'none'`

Ubicacion:

- `backend/src/modules/payments/payments.service.ts`

Riesgo:

- POS crea usuarios automaticos para DNI o `ANONIMO`.
- Usa `password_hash: 'none'`.
- `ANONIMO` podria colisionar por unique `[tenant_id, dni]`.

Impacto:

- Datos de usuarios inconsistentes.
- Riesgo si algun flujo intenta autenticar o migrar esos usuarios.

Accion recomendada:

- Crear entidad separada para ventas anonimas.
- Para usuarios creados por caja, marcar estado y credencial no-login.
- Nunca usar hash literal no-bcrypt.

### P1-B8. WebSocket registra datos sensibles y CORS abierto

Ubicacion:

- `backend/src/core/gateways/saas.gateway.ts`

Riesgo:

- Logs incluyen email y tenant.
- CORS `*`.
- Token via query string desde app Flutter; query puede quedar en logs/proxies.

Impacto:

- Exposicion de identidad y token.

Accion recomendada:

- Enviar token por `auth`, no query.
- Sanitizar logs.
- CORS allowlist.
- Agregar namespaces/rooms con validacion fuerte.

---

# Hallazgos P2 - Medios

## App movil

### P2-A1. Mezcla de modo demo y modo backend

Riesgo:

- Datos semilla se cargan siempre en `GymState`.
- `isBackendMode` depende de usuario actual, pero colecciones demo siguen vivas.

Impacto:

- UI puede mezclar datos reales y demo.

Accion recomendada:

- Flag explicito `APP_MODE=demo|backend`.
- Limpiar seed al autenticar contra backend real.

### P2-A2. Modelos de dominio acoplados a Material/UI

Ubicacion:

- `mobile_app/lib/models/gym_models.dart`

Riesgo:

- Modelos importan `material.dart` por `Color`, `IconData`, `Gradient`.

Impacto:

- DTOs dificilmente testeables o reutilizables.

Accion recomendada:

- Separar modelos puros, DTOs API y view models visuales.

### P2-A3. Timers y animaciones frecuentes

Ubicaciones:

- QR, workout assistant, verdict views, laser sweep.

Riesgo:

- `Timer.periodic` y animaciones infinitas pueden reconstruir de mas.

Impacto:

- Consumo de bateria y jank en dispositivos modestos.

Accion recomendada:

- Reducir alcance de `setState`.
- Pausar animaciones fuera de pantalla.
- Usar widgets dedicados para timers.

### P2-A4. Manejo de errores inconsistente

Riesgo:

- Algunos metodos retornan `false`, otros `null`, otros `rethrow`, otros solo loguean.

Impacto:

- UX inconsistente y dificil soporte.

Accion recomendada:

- Crear `Result<T>` o `AppFailure`.
- Centralizar errores Dio.

## Backend / sistema

### P2-B1. Doble submit solo parcial

Ubicaciones:

- `membership-billing.service.ts`
- `payments.service.ts`

Riesgo:

- `membership-sale` exige `ventaToken`, pero `pos-charge` genera token en backend con timestamp/random.
- Esto no previene reintentos duplicados del cliente.

Impacto:

- Duplicacion de cobros POS.

Accion recomendada:

- Exigir `idempotencyKey` enviado por cliente en todo endpoint financiero.
- Guardarlo con unique por tenant/operacion.

### P2-B2. Auditoria asincrona no bloqueante puede perder eventos

Ubicacion:

- `backend/src/core/interceptors/audit.interceptor.ts`

Riesgo:

- `tap(async () => ...)` no garantiza que el log termine antes de responder.
- Si falla auditoria, solo se imprime error.

Impacto:

- Operaciones sensibles pueden no quedar auditadas.

Accion recomendada:

- Usar cola confiable o transaccion para operaciones criticas.
- Definir auditoria obligatoria para caja, pagos, tenants y usuarios.

### P2-B3. `forgot-password` simulado

Ubicacion:

- `backend/src/modules/auth/auth.controller.ts`

Riesgo:

- Devuelve mensaje sin generar token ni envio real.

Impacto:

- Falsa sensacion de funcionalidad.

Accion recomendada:

- Implementar token de recuperacion con expiracion.
- No revelar si email existe.
- Enviar correo real o marcar endpoint como demo.

### P2-B4. Reportes y busquedas sin paginacion completa

Ubicaciones:

- `reports.service.ts`
- `members.service.ts`

Riesgo:

- Audit logs toman 100 fijos.
- Search toma hasta 50 y luego ordena/scorea en memoria.

Impacto:

- Rendimiento degradado con crecimiento de datos.

Accion recomendada:

- Paginacion con cursor.
- Indices por tenant/fecha/DNI/email.
- Busqueda especializada si escala.

### P2-B5. Entidades globalmente unique en Prisma pueden romper multi-tenant

Ubicacion:

- `backend/prisma/schema.prisma`

Patrones:

- `Product.sku String @unique`
- `ProductCategory.nombre String @unique`
- `ProductSale.referencia String @unique`

Riesgo:

- Valores que deberian ser por tenant pueden colisionar entre gimnasios.

Impacto:

- Un tenant bloquea SKU/categoria/referencia de otro.

Accion recomendada:

- Revisar uniques globales.
- Preferir `@@unique([tenant_id, campo])` donde aplique.

---

# Politicas de seguridad y despliegue recomendadas

## App movil

1. Flavors:
   - `dev`: demo login permitido, HTTP local permitido.
   - `staging`: sin credenciales demo, HTTPS obligatorio.
   - `prod`: sin demo, HTTPS, logs sanitizados, secure storage/cache cifrado.

2. Configuracion:
   - `API_BASE_URL` por `--dart-define`.
   - `ENABLE_DEMO_LOGIN=false` por defecto.
   - `ENABLE_QR_SIMULATOR=false` por defecto.

3. Datos locales:
   - Cifrar Hive.
   - TTL para cache.
   - No guardar tokens ni PII en logs.

4. Android:
   - `applicationId` real.
   - keystore release.
   - label e iconos finales.
   - revisar permisos.

## Backend / sistema

1. Secretos:
   - Sin fallback hardcoded.
   - Usar Docker secrets, env externo o vault.
   - Rotacion documentada.

2. API:
   - HTTPS detras de reverse proxy.
   - CORS allowlist.
   - Rate limiting.
   - Helmet/security headers.
   - Logs sanitizados.

3. Base de datos:
   - `prisma migrate deploy`.
   - Sin `db push --force-reset`.
   - Backups automaticos.
   - DB en red privada.

4. Uploads:
   - Storage privado.
   - URLs firmadas o endpoint autenticado.
   - Validacion de magic bytes.
   - Limites de tamano por endpoint.

5. Contenedores:
   - Imagen backend productiva con `node dist/main`.
   - Sin volumen de codigo en produccion.
   - Usuario no-root.
   - `read_only` donde sea posible.
   - `cap_drop: [ALL]`.
   - healthchecks para API y frontend.
   - recursos limitados (`mem_limit`, `cpus`) si aplica.

---

# Roadmap priorizado

## Hito 0 - Bloqueos inmediatos

- Corregir `'payments': ?payments`.
- Ejecutar `flutter analyze` y `flutter test`.
- Eliminar fallback TOTP basado en DNI.
- Eliminar credenciales demo en builds productivos.
- Eliminar fallbacks hardcoded de secretos backend.

## Hito 1 - Seguridad minima para staging

- API base URL por ambiente.
- HTTPS obligatorio.
- CORS restringido.
- Rate limiting auth.
- Logs sanitizados.
- Quitar `/uploads` publico.
- JWT con expiracion.

## Hito 2 - Integridad financiera y multi-tenant

- Transacciones Prisma en pagos/caja/membresia.
- Idempotencia obligatoria en POS.
- Tests cross-tenant para todos los controllers.
- Revisar uniques globales en Prisma.

## Hito 3 - Despliegue productivo

- Dockerfile backend productivo.
- Compose prod separado.
- `prisma migrate deploy`.
- secrets externos.
- healthchecks y usuario no-root.

## Hito 4 - Mantenibilidad y performance

- Separar `GymState` por dominios.
- Cifrar Hive y controlar TTL.
- Reducir rebuilds/timers.
- Separar modelos puros de UI.
- Ampliar pruebas E2E por rol.

---

# Checklist ejecutivo

## App movil

- [ ] Corregir payload POS.
- [ ] Mover API URL a `dart-define`.
- [ ] Remover demo login de prod.
- [ ] Corregir TOTP/QR.
- [ ] Cifrar Hive.
- [ ] Sanitizar logs.
- [ ] Configurar Android release real.
- [ ] Separar modo demo y backend.

## Backend / sistema

- [ ] Remover secretos hardcoded.
- [ ] Reemplazar `db push --force-reset`.
- [ ] Ejecutar backend en `start:prod`.
- [ ] Restringir CORS.
- [ ] Agregar rate limiting.
- [ ] Proteger uploads.
- [ ] Usar transacciones financieras.
- [ ] Agregar `TenantGuard` donde falte.
- [ ] Definir migraciones y backups.
- [ ] Crear Compose productivo endurecido.

## Conclusion

SaaaS GYM tiene una base funcional amplia, pero aun opera como una mezcla de prototipo avanzado, demo y backend real. El mayor riesgo esta en cruzar esta configuracion a produccion sin separar ambientes, secretos, TOTP, uploads, CORS y despliegue. La prioridad debe ser estabilizar compilacion, cerrar vulnerabilidades P0, asegurar despliegue y despues abordar mantenibilidad y performance.

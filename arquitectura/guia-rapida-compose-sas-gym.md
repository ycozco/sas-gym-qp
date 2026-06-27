# Guia rapida Docker Compose - SAS Gym

Esta guia esta fuera del repo Git. Sirve como referencia rapida para levantar el proyecto sin confundirse entre Compose local, productivo y herramientas.

## Ruta obligatoria

Ejecuta los comandos desde la raiz del proyecto clonado o copiado.

La ruta exacta cambia en cada PC. En esta guia se usa `/ruta/al/proyecto/sas-gym-qp` como ejemplo generico; reemplazala por la ruta real donde este el repo.

```bash
cd /ruta/al/proyecto/sas-gym-qp
```

Ejemplos:

```bash
cd ~/proyectos/sas-gym-qp
cd /opt/apps/sas-gym-qp
cd /mnt/d/proyectos/sas-gym-qp
```

En Windows PowerShell seria similar, usando la ruta local del equipo:

```powershell
cd C:\proyectos\sas-gym-qp
```

Esto es importante porque los comandos usan rutas relativas:

```text
.env
infra/docker/compose.local.yml
infra/docker/compose.prod.yml
```

Si ejecutas Docker Compose desde otra carpeta, puede no encontrar el `.env`, el Compose o los directorios de build.

## Regla principal

El archivo Compose usado se determina por el parametro `-f`.

```bash
docker compose -f RUTA_DEL_COMPOSE up -d
```

Ejemplo:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
```

Ese comando usa:

```text
infra/docker/compose.local.yml
```

## Compose disponibles

En el proyecto solo deben existir estos:

```text
infra/docker/compose.local.yml   -> desarrollo local
infra/docker/compose.prod.yml    -> produccion/preproduccion
infra/docker/compose.tools.yml   -> herramientas opcionales
```

## Levantar API local

Desde la raiz de `sas-gym-qp`:

```bash
cp .env.local.example .env
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api
```

Esto levanta:

```text
sasgym_postgres_local
sasgym_redis_local
sasgym_api_local
```

Importante:

- Este comando ya no ejecuta seed automaticamente.
- No debe borrar ni recrear ventas al reiniciar la API.
- Si la BD ya tiene datos, los conserva.
- Si es la primera vez en una PC nueva, la BD estara vacia hasta ejecutar el seed manual.

### Primera instalacion con datos de prueba

Solo en una PC nueva o cuando se quiera cargar data inicial:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api
docker compose --env-file .env -f infra/docker/compose.local.yml exec api npm run seed:local
```

Advertencia: `seed:local` resetea la BD local y vuelve a crear usuarios, ventas, productos y membresias demo. No ejecutarlo como parte del uso diario.

### Uso diario sin resetear datos

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d postgres redis api
```

Si cambiaste codigo de backend y necesitas reconstruir la imagen:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api
```

Ese comando reconstruye/levanta servicios, pero ya no ejecuta `seed:local`.

Validar:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml ps
curl http://localhost:3000/api/v1
```

Respuesta esperada:

```text
HTTP 200
Hello World!
```

## Levantar todo el entorno local

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build
```

Este comando levanta todo, pero tampoco ejecuta seed automaticamente. Para datos iniciales, ejecutar `seed:local` manualmente una sola vez.

Servicios principales:

```text
API:         http://localhost:3000/api/v1
Flutter web: http://localhost:8383
Admin/hub:   http://localhost:8282
PostgreSQL:  localhost:5432
Redis:       localhost:6379
```

## Levantar servicios por separado

### Solo API

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api
```

La API necesita PostgreSQL y Redis. Por eso el comando levanta los tres servicios.

Validar:

```bash
curl http://localhost:3000/api/v1
```

### Solo Flutter web

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build app-web
```

Abrir:

```text
http://localhost:8383
```

Nota: `app-web` depende de `api`. Si la API no esta levantada, Docker puede levantarla automaticamente por `depends_on`.

### Solo admin/hub estatico

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml up -d admin-web
```

Abrir:

```text
http://localhost:8282
```

Este servicio no necesita backend para mostrar el hub/docs/mockups estaticos.

## Conectar APK movil a la API local

La app movil en modo backend no debe depender de una URL por defecto.

Para saber la IP LAN de la PC donde corre Docker/API:

```bash
ip route get 1.1.1.1
```

Usa el valor que aparece despues de `src`.

Ejemplo:

```text
src 192.168.1.50
```

Entonces la URL de API para celular fisico seria:

```text
http://192.168.1.50:3000/api/v1
```

No usar `localhost` para celular fisico, porque `localhost` seria el telefono, no la PC.

### Crear APK local

Desde la app movil:

```bash
cd /ruta/al/proyecto/sas-gym-qp/mobile_app
API_BASE_URL=http://<IP_LAN_PC>:3000/api/v1 ./scripts/build-local-apk.sh
```

APK generado:

```text
mobile_app/build/app/outputs/flutter-apk/app-dev-debug.apk
```

### Instalar APK en celular conectado por cable

Ver dispositivos:

```bash
flutter devices
```

Instalar APK:

```bash
adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk
```

Si hay conflicto por version/firma durante pruebas locales:

```bash
adb uninstall com.sasgym.app
adb install build/app/outputs/flutter-apk/app-dev-debug.apk
```

### Ejecutar directamente en celular sin generar APK instalable manual

Desde `mobile_app`:

```bash
flutter devices
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=http://<IP_LAN_PC>:3000/api/v1 -d <DEVICE_ID>
```

Notas:

- Celular fisico: usar `http://<IP_LAN_PC>:3000/api/v1`.
- Emulador Android: usar `http://10.0.2.2:3000/api/v1`.
- Produccion: usar URL publica HTTPS.
- La PC y el celular deben estar en la misma red o tener ruta de red entre ellos.
- Si cambia la IP LAN de la PC, reconstruir el APK o ejecutar `flutter run` con la nueva URL.

## Saber que Compose estas usando

Mira el `-f`:

```bash
-f infra/docker/compose.local.yml
```

significa local.

```bash
-f infra/docker/compose.prod.yml
```

significa produccion/preproduccion.

Tambien puedes mirar los nombres de contenedores:

```text
sasgym_api_local       -> local
sasgym_postgres_local  -> local
sasgym_redis_local     -> local
```

```text
sasgym_api             -> produccion
sasgym_postgres        -> produccion
sasgym_redis           -> produccion
```

## Ver configuracion antes de levantar

Local:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml config
```

Produccion/preproduccion:

```bash
docker compose --env-file .env -f infra/docker/compose.prod.yml config
```

## Ver logs

API local:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml logs -f api
```

Ultimas 160 lineas de la API:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml logs --tail=160 api
```

Logs directos por nombre del contenedor:

```bash
docker logs -f sasgym_api_local
```

Para salir del seguimiento en vivo usa `Ctrl+C`.

## Detener API local

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml stop api
```

## Detener todo local

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml down
```

## Borrar datos locales y empezar de cero

Esto elimina volumenes locales de PostgreSQL y Redis:

```bash
docker compose --env-file .env -f infra/docker/compose.local.yml down -v
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build postgres redis api
docker compose --env-file .env -f infra/docker/compose.local.yml exec api npm run seed:local
```

Usar solo en desarrollo local.

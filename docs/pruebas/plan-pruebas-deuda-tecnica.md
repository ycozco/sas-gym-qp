# Plan de Pruebas Cruzadas (Web Admin & App Móvil) y Gestión de Deuda Técnica

Este documento define la estrategia de pruebas manuales y exploratorias enfocadas en detectar brechas de implementación (funcionalidades incompletas), inconsistencias visuales y deuda técnica en el ecosistema **SaaaS GYM**. 

---

## 🎯 1. Objetivo General
Alinear la interfaz de la aplicación de administración web (`web_admin`) y la aplicación móvil (`mobile_app`) con las reglas de negocio y endpoints del backend (`backend/src`), identificando discrepancias de UI/UX, flujos incompletos de lógica offline, y fallos de multi-tenancy.

---

## 🖥️ 2. Plan de Pruebas: Módulo Web Admin (React/Vite)

El Web Admin gestiona múltiples sedes (tenants), planes, cobros, inventario y registros biométricos. Las pruebas deben validar la consistencia del estado en la base de datos a través de Prisma.

### 🧪 Caso 2.1: Gestión de Catálogo y Snapshot de Membresías
* **Propósito**: Validar que la edición de un plan de membresía no altere de forma retroactiva las ventas ya procesadas (preservación histórica).
* **Acciones**:
  1. Crear un plan "Mensual Plata" a S/ 150.00.
  2. Asignar este plan a un socio (`socio01.surco@test.sasgym.com`) y registrar el pago.
  3. Modificar el precio del plan a S/ 175.00 en la vista de edición.
  4. Consultar la membresía del socio en su perfil y verificar que el costo se mantenga en S/ 150.00.
  5. Crear un nuevo socio y asignarle el plan modificado; validar que cobre S/ 175.00.
* **Criterio de Aceptación**: La base de datos debe contener `plan_id` opcional e información estática duplicada en `plan_nombre`, `duracion_dias` y `monto` de la tabla `Membership`.

### 🧪 Caso 2.2: Flujo de Caja Chica y Doble Envío (Idempotencia)
* **Propósito**: Evitar la duplicación de transacciones en la red local y garantizar la precisión de los saldos al abrir/cerrar turnos de caja.
* **Acciones**:
  1. Iniciar sesión como cajero (`caja1.surco@test.sasgym.com`).
  2. Abrir caja con un saldo inicial de S/ 100.00.
  3. Registrar una membresía con pago en efectivo de S/ 120.00 y presionar repetidamente el botón de enviar.
  4. Revisar la tabla de pagos para confirmar que solo exista un registro de S/ 120.00.
  5. Agregar un egreso de S/ 30.00.
  6. Cerrar la caja y contrastar los totales calculados automáticamente frente al arqueo físico.
* **Criterio de Aceptación**: No deben crearse transacciones duplicadas por clics rápidos. El saldo de caja al cierre debe calcularse como: `apertura + ingresos (efectivo/yape/pos/transferencia) - egresos`.

### 🧪 Caso 2.3: Aislamiento Multitenant (Multi-Tenancy)
* **Propósito**: Asegurar que un administrador de una sede (ej. Surco) no pueda listar, crear ni modificar datos de otra sede (ej. Miraflores).
* **Acciones**:
  1. Iniciar sesión como `admin1.surco@test.sasgym.com`.
  2. Intentar acceder a listados de socios o inventario alterando la URL con IDs del tenant de Miraflores.
  3. Intentar realizar una petición POST/PATCH mediante curl o Postman al endpoint de productos usando el token de Surco pero enviando un `tenant_id` de Miraflores en el payload o cabeceras.
* **Criterio de Aceptación**: Las respuestas deben arrojar error `403 Forbidden` o `404 Not Found`. Ninguna consulta debe mezclar registros de distintos tenants.

---

## 📱 3. Plan de Pruebas: Aplicación Móvil (Flutter/Dart)

La App Móvil interactúa directamente con los socios, lee códigos QR y soporta almacenamiento offline temporal para mitigar caídas de conectividad.

### 🧪 Caso 3.1: Robustez de la Cola de Sincronización Offline (SyncQueue)
* **Propósito**: Validar que la aplicación encolar de manera segura las peticiones y conserve las llaves de idempotencia sin corromper los datos financieros.
* **Acciones**:
  1. Activar el Modo Avión en el dispositivo/emulador móvil.
  2. Intentar registrar una asistencia o marcar el check-in de una rutina de entrenamiento.
  3. Verificar que la app muestre un indicador visual de "Pendiente de envío" y no falle con pantalla roja.
  4. Desactivar el Modo Avión (recuperar red).
  5. Monitorear los logs de red del dispositivo para confirmar la salida de la petición.
* **Criterio de Aceptación**: La petición debe guardarse en `sync_queue_box` (Hive/Local storage) con un UUID único de idempotencia y procesarse inmediatamente al reconectar. Si el token expira o la red devuelve errores repetidos, debe reintentar hasta un límite configurado (`max retries`).

### 🧪 Caso 3.2: Control de Accesos y Barreras Visuales (Socio Suspendido)
* **Propósito**: Bloquear la interfaz del socio si su membresía está suspendida o vencida, impidiendo la generación del QR de acceso.
* **Acciones**:
  1. En el backend, cambiar el estado del socio a `SUSPENDED` o `EXPIRED`.
  2. Abrir la app e iniciar sesión con la cuenta de dicho socio.
  3. Intentar abrir la vista del QR dinámico de acceso.
* **Criterio de Aceptación**: La aplicación debe desplegar el widget `GymSuspendedBarrier` bloqueando el acceso al QR y mostrando un mensaje claro indicando que acuda a la recepción del gimnasio.

### 🧪 Caso 3.3: Preferencias de Tema Visual y Accesibilidad
* **Propósito**: Asegurar el cumplimiento de las guías de diseño premium en modo Light, Dark y Automático (System).
* **Acciones**:
  1. Cambiar la preferencia del tema en el perfil del usuario a "Dark Mode".
  2. Inspeccionar pantallas críticas (rutinas, lector QR, pagos) buscando textos oscuros sobre fondos oscuros o botones con contraste deficiente.
  3. Repetir el proceso cambiando el tema del sistema operativo Android/iOS.
* **Criterio de Aceptación**: Todos los textos deben cumplir con un contraste mínimo de 4.5:1 (norma WCAG AA). Los componentes dinámicos de color deben usar el preset establecido en el Tenant actual.

### 🧪 Caso 3.4: Caja desde APK en celular físico
* **Propósito**: Validar que el APK móvil conectado al backend Docker local permite ejecutar el flujo operativo de caja sin duplicidad financiera.
* **Documento de ejecución**: `docs/pruebas/caja-movil-celular-2026-06-16.md`.
* **Acciones resumidas**:
  1. Instalar APK `dev/local` en celular físico conectado a la misma red Wi-Fi que la PC.
  2. Iniciar sesión como `caja1.surco@test.sasgym.com`.
  3. Abrir caja con saldo inicial.
  4. Registrar venta/cobro desde POS.
  5. Intentar doble tap/doble submit en la confirmación de venta.
  6. Registrar egreso.
  7. Cerrar caja.
  8. Verificar auditoría.
* **Criterio de Aceptación**: El cierre debe cuadrar con `saldo inicial + ingresos - egresos`, y el doble submit no debe crear cobros duplicados.

---

## 📋 4. Formato de Reporte de Deuda Técnica (Plantilla)

Utilizar el siguiente formato markdown para documentar cada problema encontrado. Guardar los reportes en `docs/pruebas/deuda-tecnica-reporte.md` para facilitar su priorización y posterior resolución.

```markdown
# Reporte de Deuda Técnica e Implementación Incompleta — [Fecha]

| ID | Componente | Severidad | Descripción de la Brecha / Fallo | Impacto en Negocio | Archivos Afectados | Plan de Mitigación |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **DT-001** | `mobile_app` | 🔴 Alta | La cola de sincronización offline reintenta infinitamente peticiones financieras fallidas causando duplicidad de logs. | Financiero / Integridad de datos. | [sync_queue_service.dart](file:///d:/proyectos/sas_gym/mobile_app/lib/services/sync_queue_service.dart) | Implementar límite de reintentos a 5 y descarte con alerta tras expirar el TTL de 24 horas. |
| **DT-002** | `web_admin` | 🟡 Media | La vista de edición de miembros no refresca la tabla al guardar cambios físicos (Peso, Altura). | Experiencia de usuario (UX). | [members_view.jsx](file:///d:/proyectos/sas_gym/web_admin/src/views/members_view.jsx) | Agregar trigger de recarga de datos en el callback onSuccess del modal. |
| **DT-003** | `backend` | 🟢 Baja | El linter reporta múltiples warnings de tipo `any` en los controladores de rutinas al parsear el payload. | Mantenibilidad de código. | [routines.controller.ts](file:///d:/proyectos/sas_gym/backend/src/modules/routines/routines.controller.ts) | Definir DTOs tipados estrictos y remover el uso de `any` explícito. |

---

## 📊 Segmentación de Tareas por Impacto

### 🔴 Alta Prioridad (Bloqueadores de Lanzamiento)
*Fallas de seguridad, errores de cálculo financiero, fallas críticas de red o crashes de la app.*
1. **[Tarea]** ...
2. **[Tarea]** ...

### 🟡 Media Prioridad (Experiencia y Consistencia)
*Comportamientos inconsistentes de la UI, fallas en modos offline no destructivos, o errores menores de validación.*
1. **[Tarea]** ...
2. **[Tarea]** ...

### 🟢 Baja Prioridad (Limpieza y Deuda Técnica Pura)
*Formateos de código, actualizaciones de librerías no críticas, warnings de compilador o linter.*
1. **[Tarea]** ...
2. **[Tarea]** ...
```

---

## 🚀 5. Flujo de Ejecución del Plan de Pruebas
1. **Paso 1: Preparación del Entorno**: Levantar los servicios en modo testing ejecutando `docker compose exec api sh -lc "ALLOW_TEST_DATA_RESET=true npm run seed:test"` para contar con datos realistas multisede.
2. **Paso 2: Pruebas Exploratorias**: Dos desarrolladores o QAs ejecutan los casos de prueba descritos en las secciones 2 y 3.
3. **Paso 3: Registro de Resultados**: Rellenar la *Plantilla de Reporte de Deuda Técnica* con cada hallazgo.
4. **Paso 4: Sprint de Refactorización**: Programar un ciclo de desarrollo enfocado exclusivamente en las tareas de severidad 🔴 Alta y 🟡 Media antes del despliegue final.

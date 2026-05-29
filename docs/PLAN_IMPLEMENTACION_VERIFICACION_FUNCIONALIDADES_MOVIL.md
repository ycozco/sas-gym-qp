# Plan de implementacion y verificacion de funcionalidades - App movil

## Objetivo

Definir una guia de verificacion a nivel codigo para la app movil Flutter de SaaaS GYM, con foco en:

- validar funcionalidades por rol;
- cubrir modales, formularios y flujos de edicion;
- segmentar la verificacion por archivo y por responsabilidad;
- dejar trazabilidad clara de rutas, pantallas y componentes reutilizables.

Este documento no es un plan de diseno visual. Es un plan de implementacion y validacion funcional, centrado en codigo, rutas y modales.

## Criterio de lectura del flujo

La app movil no usa rutas nombradas clasicas para la navegacion principal. El flujo real se resuelve por estado y por host de rol:

1. `mobile_app/lib/main.dart`
2. `mobile_app/lib/app.dart`
3. `mobile_app/lib/features/auth/screens/login_screen.dart`
4. `mobile_app/lib/features/*/screens/*.dart` segun el rol autenticado

Por eso la verificacion debe seguir el arbol de archivos, no solo una lista de pantallas sueltas.

## Inventario de entrada por capa

| Capa | Archivo | Responsabilidad |
|---|---|---|
| Arranque | `mobile_app/lib/main.dart` | Inicializa la app Flutter. |
| Gate principal | `mobile_app/lib/app.dart` | Decide si se muestra login, barrera SaaS o host de rol. |
| Tema | `mobile_app/lib/theme/app_theme.dart` | Define el lenguaje visual global y estilos base. |
| Datos | `mobile_app/lib/data/gym_seed.dart` | Mock data por rol, turnos, anuncios, productos y clientes SaaS. |
| Modelos | `mobile_app/lib/models/gym_models.dart` | Entidades compartidas y enum de roles. |
| Shell compartido | `mobile_app/lib/widgets/app_shell.dart` | Componentes reutilizables de UI. |
| Barrera SaaS | `mobile_app/lib/widgets/saas/gym_suspended_barrier.dart` | Pantalla de bloqueo por instancia suspendida. |

## Segmentacion funcional por rol

### 1. Auth

Archivos:

- `mobile_app/lib/features/auth/auth.dart`
- `mobile_app/lib/features/auth/screens/login_screen.dart`

Flujo a revisar:

- login normal;
- recuperacion de contrasena mediante modal inferior;
- errores de autenticacion;
- estado de carga durante validacion;
- cierre de sesion desde el top bar del host.

Modal principal:

- `showModalBottomSheet` de recuperacion de contrasena en `login_screen.dart`.

Checklist de verificacion:

- campos obligatorios visibles;
- boton principal habilitado y deshabilitado segun estado;
- snackbar de exito o error;
- teclado y overflow en pantalla pequena.

### 2. Super Administrador

Archivos:

- `mobile_app/lib/features/superadmin/superadmin.dart`
- `mobile_app/lib/features/superadmin/screens/superadmin_screen.dart`

Responsabilidad:

- listar gimnasios o clientes SaaS;
- activar o suspender sedes;
- seleccionar una sede para simularla en contexto.

No depende de modales complejos. Su verificacion debe centrarse en:

- conteo de sedes activas/suspendidas;
- switch de activacion;
- seleccion de sede actual;
- estado visual correcto por cliente.

### 3. Miembro

Archivos:

- `mobile_app/lib/features/member/member.dart`
- `mobile_app/lib/features/member/screens/member_screen.dart`
- `mobile_app/lib/features/member/widgets/log_effort_modal.dart`
- `mobile_app/lib/features/member/widgets/timer_ring.dart`
- `mobile_app/lib/features/member/widgets/qr_pattern.dart`

Subflujo principal:

- home con resumen y progreso;
- agenda semanal;
- membresia y renovacion;
- clases grupales;
- buzon de observaciones;
- notificaciones;
- reporte de esfuerzo y seguimiento.

Modales y dialogos relevantes:

- modal de esfuerzo en `member/widgets/log_effort_modal.dart`;
- confirmacion de abandono de entrenamiento en `member_screen.dart`;
- dialogos de renovacion y pagos dentro de la misma pantalla.

Puntos criticos de verificacion:

- el modal abre con valores iniciales correctos;
- el modal registra el dato y actualiza estado;
- los botones de accion primaria mantienen consistencia visual;
- no se corta el contenido en pantallas pequenas;
- el QR y los indicadores de estado se renderizan sin romper layout.

### 4. Entrenador

Archivos:

- `mobile_app/lib/features/trainer/trainer.dart`
- `mobile_app/lib/features/trainer/screens/trainer_screen.dart`

Subflujos:

- miembros asignados;
- libreria de ejercicios;
- plantillas de rutina;
- progreso y estadisticas;
- buzon de incidencias.

Modales principales:

- `showDialog` de `Nuevo Ejercicio` en `trainer_screen.dart`;
- `showDialog` de `Crear Plantilla` en `trainer_screen.dart`.

Verificacion obligatoria:

- ambos dialogos deben abrir con foco correcto;
- los campos deben persistir hasta confirmar;
- cancelar debe cerrar sin mutar estado;
- al guardar, la lista visible debe refrescar;
- validar scroll interno si el teclado tapa campos.

### 5. Caja

Archivos:

- `mobile_app/lib/features/cashier/cashier.dart`
- `mobile_app/lib/features/cashier/screens/cashier_screen.dart`

Subflujos:

- panel de turno activo;
- escaneo de asistencia;
- cobro rapido;
- ventas del turno;
- catalogo de productos;
- bajas logicas de usuarios;
- logs de solo lectura.

Modales y dialogos principales:

- `showDialog` de error u operacion denegada en `cashier_screen.dart`;
- `showDialog` de agregar producto en `cashier_screen.dart`;
- `showDialog` de editar precio en `cashier_screen.dart`;
- `showDialog` de confirmacion de baja logica en `cashier_screen.dart`;
- dialogo de cierre o confirmacion de operacion en POS.

Puntos de verificacion de caja:

- ingreso/salida de asistencia debe reaccionar segun dni;
- el POS no debe permitir cobrar sin socio seleccionado cuando aplica;
- los productos deben poder agregarse y editarse desde modal;
- la baja logica debe mostrar confirmacion y resultado claro;
- los dialogos de error deben mostrar el mensaje retornado por backend o modo demo.

### 6. Admin

Archivos:

- `mobile_app/lib/features/admin/admin.dart`
- `mobile_app/lib/features/admin/screens/admin_screen.dart`

Subflujos:

- dashboard principal;
- usuarios con gestion total;
- escaner administrativo;
- cuentas de caja;
- inventario de productos;
- auditoria global;
- buzon de observaciones;
- anuncios;
- ajustes del gimnasio.

Modales y formularios relevantes:

- `showDialog` de `Registrar Cajero` en `admin_screen.dart`;
- clase `_AdminMemberFormPage` para alta y edicion de socio;
- `showDialog` de `¿Eliminar Fisicamente?` en `admin_screen.dart`;
- clase `_AdminProductFormPage` para alta y edicion de producto;
- clase `_AdminAnnouncementFormPage` para publicar anuncios;
- pagina o dialogo de ajustes del gimnasio en `admin_screen.dart`.

Puntos de verificacion de admin:

- alta y edicion deben prellenar datos correctos;
- el modal debe mostrar todos los campos esperados;
- eliminar fisicamente debe exigir confirmacion explicita;
- publicar anuncio debe validar campos requeridos;
- ajustes del gimnasio deben persistir en el estado compartido.

## Lista de modales que requieren revision completa de edicion

Estos son los puntos donde la revision de codigo debe ser mas estricta porque suelen quedar incompletos en la UI o en la precarga de datos:

| Archivo | Modal o formulario | Razon de revision |
|---|---|---|
| `mobile_app/lib/features/trainer/screens/trainer_screen.dart` | `Nuevo Ejercicio` | Debe confirmar prellenado, validacion y actualizacion de lista. |
| `mobile_app/lib/features/trainer/screens/trainer_screen.dart` | `Crear Plantilla` | Debe validar campos de nombre, categoria y ejercicios. |
| `mobile_app/lib/features/cashier/screens/cashier_screen.dart` | `Registrar Producto` | Debe revisar alta completa y campos numéricos. |
| `mobile_app/lib/features/cashier/screens/cashier_screen.dart` | `Editar Precio` | Debe verificar carga del precio actual y guardado. |
| `mobile_app/lib/features/cashier/screens/cashier_screen.dart` | `Confirmar Baja Logica` | Debe exigir confirmacion y refrescar lista. |
| `mobile_app/lib/features/admin/screens/admin_screen.dart` | `Registrar Cajero` | Debe revisar permisos iniciales y guardado. |
| `mobile_app/lib/features/admin/screens/admin_screen.dart` | `_AdminMemberFormPage` | Es el formulario mas sensible de alta y edicion de socio. |
| `mobile_app/lib/features/admin/screens/admin_screen.dart` | `_AdminProductFormPage` | Requiere verificacion de alta/edicion completa. |
| `mobile_app/lib/features/admin/screens/admin_screen.dart` | `_AdminAnnouncementFormPage` | Debe validar contenido y publicacion. |

## Matriz de verificacion tecnica por archivo

### Archivos base

- `mobile_app/lib/main.dart`: arranque sin excepciones.
- `mobile_app/lib/app.dart`: gate de login, barrera SaaS y host de rol.
- `mobile_app/lib/theme/app_theme.dart`: consistencia de botones, inputs y tipografia.
- `mobile_app/lib/widgets/app_shell.dart`: widgets compartidos, nav, hero, tiles y estilos de boton.
- `mobile_app/lib/widgets/saas/gym_suspended_barrier.dart`: bloqueo correcto de instancias suspendidas.

### Archivos por feature

- `mobile_app/lib/features/auth/screens/login_screen.dart`: login, recuperacion y error handling.
- `mobile_app/lib/features/member/screens/member_screen.dart`: home, membresia, clases, observaciones, notificaciones.
- `mobile_app/lib/features/member/widgets/log_effort_modal.dart`: registro de esfuerzo y persistencia del estado local.
- `mobile_app/lib/features/trainer/screens/trainer_screen.dart`: miembros, ejercicios, plantillas e incidencias.
- `mobile_app/lib/features/cashier/screens/cashier_screen.dart`: asistencia, POS, productos, bajas logicas y logs.
- `mobile_app/lib/features/admin/screens/admin_screen.dart`: socios, caja, inventario, auditoria y ajustes.
- `mobile_app/lib/features/superadmin/screens/superadmin_screen.dart`: gestion SaaS de sedes.

## Estrategia de implementacion

### Fase 1. Inventario y estabilidad

1. Revisar que cada feature exporte su pantalla desde su barrel.
2. Verificar que el host de rol en `app.dart` sigue la ruta correcta por `GymRole`.
3. Confirmar que los modales clave abren y cierran sin romper el layout.
4. Validar que el estilo compartido de botones no genera desbordes.

### Fase 2. Completar formularios y modales

1. Cerrar campos faltantes de edicion en admin, trainer y cashier.
2. Revisar precarga de datos en formularios editables.
3. Agregar validaciones minimas en campos criticos.
4. Garantizar scroll interno en modales largos.

### Fase 3. Verificacion de negocio por rol

1. Miembro: renovacion, QR, clases, observaciones y notificaciones.
2. Entrenador: alta de ejercicios, plantillas y seguimiento.
3. Caja: cobro, asistencia, baja logica y logs.
4. Admin: CRUD total, caja, anuncios y auditoria.
5. Super admin: activacion y suspension de sedes.

### Fase 4. Validacion automatica

1. `flutter analyze` sobre los archivos tocados.
2. `flutter test` para tests existentes.
3. `flutter run -d emulator-5554` para smoke test visual y de flujo.
4. Si aplica, `flutter build web` para verificar compilacion web.

## Checklist de aceptacion

- cada pantalla principal abre desde su flujo de rol;
- cada modal de edicion muestra titulo, campos y acciones completas;
- los formularios editables precargan informacion actual;
- cancelar no modifica estado;
- guardar actualiza estado y refresca la vista;
- no hay overflow en modales con teclado abierto;
- los botones funcionales comparten estilo base y tamanios consistentes;
- `flutter analyze` queda limpio en el slice modificado.

## Entrega esperada

La salida final de esta implementacion debe dejar:

- mapa de rutas claro por archivo;
- modales de alta y edicion completos;
- verificacion funcional por rol documentada;
- checklist para ejecutar smoke tests a nivel codigo y en emulador.

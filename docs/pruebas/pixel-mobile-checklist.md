# Checklist Pixel emulado - mobile_app

Fecha base: `2026-06-11`

## Preparación

- Abrir el perfil Pixel ya instalado en el emulador.
- Confirmar que la app apunta al backend esperado para la prueba.
- Verificar que el modo oscuro esté activo en la app antes de recorrer roles.

## Admin

- Iniciar sesión como admin.
- Abrir `Escáner Admin`.
- Confirmar que los presets se llenan con socios reales por estado.
- Verificar que `DNI inválido` siga visible como caso negativo.
- Probar al menos un preset `Activo`, uno `En gracia` y uno `Vencido`.
- Confirmar que los textos acentuados se ven bien: `Escáner`, `Simulación`, `admisión`, `DNI inválido`.

## Caja

- Iniciar sesión como caja.
- Abrir `Escáner de sala`.
- Confirmar que los presets coinciden con la data real cargada desde backend.
- Probar el caso `DNI inválido`.
- Abrir `Membresías` y revisar que buscador, cards y dialogs respeten dark mode.
- Abrir POS y forzar un error controlado para revisar el dialog `Operación Denegada`.
- Probar emisión de `Pase por un día` con `Pase anónimo` y `Pase con DNI`.

## Socio

- Iniciar sesión como socio.
- Revisar home, `Mi Membresía`, `Renovar membresía` y `Buzón de observaciones`.
- Confirmar que se ven bien textos con acentos: `Membresía`, `Método de pago`, `Categoría`, `Descripción`.
- Validar que cards, inputs, dropdowns y el selector de imagen no queden con fondo claro duro.

## Trainer

- Iniciar sesión como trainer.
- Revisar panel principal, detalle de alumno, asignador semanal y biblioteca técnica.
- Confirmar que app bars, cards, chips, buscador y dialogs ya no queden blancos en dark mode.

## Cierre

- Anotar cualquier pantalla donde aparezca una card clara aislada.
- Anotar cualquier texto con mojibake, acentos rotos o símbolos extraños.
- Si falla un preset dinámico, registrar rol, estado esperado y DNI usado.

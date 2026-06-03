# Arquitectura de SaaaS GYM

Esta carpeta documenta el estado actual del proyecto `sas_gym` a partir del codigo, los mockups y los documentos existentes.

Este README funciona como indice tecnico de `arquitectura/`. El README general del proyecto esta en `../README.md`.

## Orden de lectura recomendado

1. `01-vision-general.md`: producto, roles, alcance y piezas principales.
2. `02-backend-nestjs.md`: API, modulos, seguridad y responsabilidades.
3. `03-app-flutter.md`: arquitectura movil, flujo de rol y estado.
4. `04-modelo-datos.md`: dominios principales del esquema Prisma.
5. `05-apis-y-flujos.md`: endpoints y flujos de negocio.
6. `06-infraestructura.md`: Docker, redes, puertos y despliegue local.
7. `07-avance-actual.md`: que esta avanzado, que esta parcial y que falta.
8. `08-plan-verificacion-pruebas.md`: pruebas unitarias, integracion, E2E y criterios de aceptacion.
9. `09-guia-despliegue.md`: despliegue local, manual, validacion y consideraciones de produccion.

## Lectura rápida

SaaaS GYM es un sistema SaaS multi-tenant para gimnasios. Cada gimnasio es un `Tenant`, y la información operativa se aísla por `tenant_id`. La API está desarrollada en NestJS y la aplicación final en Flutter.

Este directorio (`arquitectura/`) ha sido centralizado y actúa como la **única fuente de verdad técnica** para el proyecto. Todos los diseños de arquitectura objetivo (Nginx, Redis, S3, aislamiento automático con Prisma Client Extensions y modularización de estado con Riverpod) se encuentran integrados en estos documentos, evitando la existencia de archivos duplicados dispersos en el repositorio.

## Convenciones de esta documentación

- Se describe de forma realista el estado actual del repositorio.
- Las propuestas de diseño objetivo (TO-BE) y planes de refactorización futuros están demarcados claramente en sus respectivas secciones.
- Los nombres de rutas y archivos respetan la nomenclatura real del código fuente.
- Se evita cualquier dependencia o referencia a `proyecto_antiguo/` salvo para fines puramente históricos.

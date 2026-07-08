# Codex

## Objetivo

Usar Codex para tareas pequenas y revisables sobre SAS Gym, manteniendo separados infraestructura, backend, Flutter, documentacion y seguridad.

## Antes de cambiar archivos

```bash
git status
git branch
docker compose --env-file .env.local.example -f infra/docker/compose.local.yml config
```

## Tareas apropiadas

- Auditar estructura y documentacion.
- Crear o ajustar compose local/productivo.
- Corregir `.gitignore`.
- Actualizar documentacion operativa.
- Revisar Prisma y migraciones.
- Revisar aislamiento por `tenant_id`.
- Preparar validaciones locales.

## Tareas fuera de alcance en esta fase

- Desplegar en VPS.
- Configurar DNS, SSL o Nginx Proxy Manager real.
- Subir imagenes a registry.
- Crear deploy automatico.
- Migrar datos productivos.
- Versionar secretos.

## Forma de pedir trabajo

Pedir una tarea por bloque. Ejemplos:

```text
Audita compose productivo y verifica que no publique puertos sensibles.
```

```text
Revisa endpoints de pagos y confirma que filtran por tenant_id.
```

```text
Actualiza documentacion local sin tocar backend.
```

## Validacion

Usar validaciones no destructivas primero:

```bash
docker compose --env-file .env.local.example -f infra/docker/compose.local.yml config
docker compose --env-file .env.production.example -f infra/docker/compose.prod.yml config
git diff --check
```

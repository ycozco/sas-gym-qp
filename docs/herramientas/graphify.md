# Graphify

## Objetivo

Generar un grafo o reporte del repositorio SAS Gym para facilitar auditoria, navegacion y analisis arquitectonico.

## Estado

Herramienta opcional de desarrollo local.

No forma parte del MVP funcional. No forma parte del compose productivo. No debe bloquear el flujo local.

## Ejecucion

```bash
docker compose -f infra/docker/compose.tools.yml --profile graphify up -d graphify
docker logs -f sasgym_graphify
```

## Salida esperada

```text
graphify/graphify-out/
  GRAPH_REPORT.md
```

## Uso con Codex

Antes de cambios grandes, generar `GRAPH_REPORT.md` y pedir a Codex que lo use como contexto auxiliar.

## Restricciones

- No montar `.env`.
- No enviar secretos.
- No usar en produccion.
- No bloquear el flujo local si Graphify falla.

## Nota actual

El compose incluye un placeholder porque no existe una carpeta `graphify/` con Dockerfile en este repositorio. Cuando se elija una imagen o herramienta concreta, reemplazar el servicio placeholder.

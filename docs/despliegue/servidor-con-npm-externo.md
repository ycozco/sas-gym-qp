# Servidor con Nginx Proxy Manager externo

## Alcance

Esta guia prepara el despliegue futuro en un VPS que ya tiene Nginx Proxy Manager. El proyecto SAS Gym no incluye NPM, no crea certificados y no administra DNS.

## Requisitos previos del VPS

- Docker y Docker Compose instalados.
- Repositorio clonado.
- Nginx Proxy Manager ya funcionando fuera de este proyecto.
- Red Docker del proxy identificada.

## Preparacion futura

1. Identificar la red Docker usada por NPM:

```bash
docker network ls
```

2. Copiar variables de produccion:

```bash
cp .env.production.example .env
```

3. Configurar `EXTERNAL_PROXY_NETWORK` con el nombre real de la red del proxy.

4. Validar compose sin desplegar:

```bash
docker compose --env-file .env -f infra/docker/compose.prod.yml config
```

5. Levantar servicios cuando corresponda:

```bash
docker compose --env-file .env -f infra/docker/compose.prod.yml up -d --build
```

## Proxy Hosts esperados

- `api.sas-gym.qpsecure.cloud` hacia `sasgym_api:3000`.
- `ws.sas-gym.qpsecure.cloud` hacia `sasgym_ws:3001`, con WebSocket Support.
- `app.sas-gym.qpsecure.cloud` hacia `sasgym_app_web:80`.
- `admin.sas-gym.qpsecure.cloud` hacia `sasgym_admin_web:80`.

## Reglas

- No publicar puertos `80`, `443` ni `81` desde este proyecto.
- No exponer PostgreSQL ni Redis.
- Activar SSL desde NPM externo.
- Activar WebSocket Support para el host de WS.
- No guardar secretos reales en Git.

# Validacion de produccion sin despliegue

## Checklist

- `.env` creado desde `.env.production.example`.
- `EXTERNAL_PROXY_NETWORK` apunta a la red real del proxy externo.
- `docker compose config` renderiza sin errores.
- `compose.prod.yml` no contiene Nginx Proxy Manager.
- `compose.prod.yml` no contiene Certbot.
- `compose.prod.yml` no publica `80:80`, `443:443` ni `81:81`.
- PostgreSQL y Redis no tienen `ports`.
- API, WS, app web y admin web usan `expose`.

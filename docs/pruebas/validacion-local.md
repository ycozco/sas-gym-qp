# Validacion local

## Checklist

- `.env` creado desde `.env.local.example`.
- Compose local renderiza con `docker compose config`.
- API responde en `http://localhost:3000/api/v1`.
- Flutter Web/PWA carga en `http://localhost:8383`.
- Admin web carga en `http://localhost:8282`.
- PostgreSQL y Redis usan credenciales de desarrollo.
- No se requiere Nginx Proxy Manager.

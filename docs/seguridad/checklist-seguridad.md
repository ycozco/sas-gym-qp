# Checklist de seguridad

- No versionar `.env` reales.
- No usar secretos reales en ejemplos.
- No exponer PostgreSQL ni Redis en produccion.
- No incluir Nginx Proxy Manager dentro del proyecto.
- No abrir puertos `80`, `443` ni `81` desde SAS Gym.
- Validar CORS por entorno.
- Mantener JWT y secretos biometricos con valores fuertes en produccion.
- Revisar logs antes de compartirlos.
- No montar carpetas con secretos en herramientas opcionales.

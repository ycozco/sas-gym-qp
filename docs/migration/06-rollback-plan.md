# docs/migration/06-rollback-plan.md — Plan de Rollback y Contingencia

Este documento detalla las acciones y pasos a seguir en caso de que alguna de las fases de la migración falle o genere regresiones críticas de estabilidad o seguridad en el ecosistema SASGYM.

---

## 1. Estrategia de Rollback de Código y Git

La migración se divide en commits incrementales pequeños conforme a la política de commits. Esto permite aislar y revertir cambios de forma limpia sin afectar a los hitos estables previos.

### Reversión de Commits Específicos
Si se detecta un fallo funcional en el Hito N, se puede aislar el commit correspondiente y revertirlo mediante:
```bash
git revert <commit-sha-hito-n>
```

### Rollback Completo al Baseline
En caso de fallo catastrófico sistémico que comprometa la integridad general, se realizará un rollback completo al último commit estable de la rama `production`:
```bash
git reset --hard 53ec668e
```

---

## 2. Rollback de Infraestructura y Contenedores

Las versiones de desarrollo y producción se gestionan mediante Docker Compose. Si una actualización de imagen base (ejemplo: Node.js 24 o PostgreSQL 16 parches) genera fallos en runtime:

1.  **Detener contenedores fallidos:**
    ```bash
    docker compose -f infra/docker/compose.prod.yml down
    ```
2.  **Restaurar archivos de Compose previos:**
    Revertir los cambios en los archivos `compose.prod.yml` y `Dockerfile` de las carpetas correspondientes.
3.  **Limpia de caché de construcción Docker (si fuera necesario):**
    *   *Nota:* Nunca usar `docker system prune` en servidores reales conforme a las reglas críticas de `AGENTS.md`.
    *   Forzar la reconstrucción con imágenes base previas:
        ```bash
        docker compose -f infra/docker/compose.prod.yml build --no-cache api
        ```
4.  **Levantar infraestructura estable:**
    ```bash
    docker compose -f infra/docker/compose.prod.yml up -d
    ```

---

## 3. Rollback de Base de Datos y Migraciones Prisma

Para cambios en la base de datos PostgreSQL, se aplican las siguientes medidas de mitigación:

### Procedimiento ante fallos en migraciones Prisma
1.  **Backup previo obligatorio:**
    Antes de desplegar cualquier migración Prisma en producción, se ejecutará una copia de seguridad física/lógica de PostgreSQL en el host de base de datos:
    ```bash
    pg_dump -U sasgym_user -h postgres -d sasgym_dev -F c -b -v -f /backups/pre-migration-dump.bak
    ```
2.  **Restauración de base de datos en caso de corrupción:**
    Si la migración genera errores destructivos y se requiere volver al estado anterior:
    *   Detener la API NestJS para cortar conexiones activas.
    *   Eliminar y volver a crear el esquema de base de datos actual.
    *   Restaurar el backup:
        ```bash
        pg_restore -U sasgym_user -h postgres -d sasgym_dev -v /backups/pre-migration-dump.bak
        ```
    *   Iniciar la API con la versión anterior del código compatible con el esquema de base de datos restaurado.

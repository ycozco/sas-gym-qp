# Buenas Prácticas Docker: Optimización de RAM y Desarrollo en Vivo (Hot-Reload)

Este documento recopila las mejores prácticas de la industria y las aplica directamente al ecosistema **SaaaS GYM** para reducir el consumo de recursos (CPU y RAM) y optimizar el flujo de desarrollo directo (*live code modification*).

---

## 💾 1. Optimización del Consumo de RAM en Contenedores Node.js (NestJS)

Node.js y el motor V8 tienden a consumir toda la memoria disponible si no se configuran correctamente, lo que puede provocar bloqueos o la terminación abrupta del contenedor por parte del kernel (*OOM Killer*).

### A. Limitar el Heap de V8 (`max-old-space-size`)
Por defecto, Node.js no detecta de forma nativa los límites de memoria impuestos por los cgroups de Docker y puede reservar más memoria del límite configurado en el contenedor.
*   **Solución**: Forzar el límite de la pila de memoria usando la variable de entorno `NODE_OPTIONS`. Esta debe establecerse al **75% u 80%** de la capacidad física asignada al contenedor.
*   **Configuración**:
    ```yaml
    environment:
      - NODE_OPTIONS=--max-old-space-size=768 # Para un límite de contenedor de 1GB (1024MB)
    ```

### B. Usar Base Images de Peso Ultra-Bajo (Alpine Linux)
*   **Solución**: Reemplazar la imagen de desarrollo genérica de Node por su variante oficial **Alpine** (`node:22-alpine` o `node:20-alpine`). Esto reduce el peso de la imagen base de ~900MB a ~120MB, eliminando librerías y dependencias inútiles que consumen RAM en caché de sistema de archivos.

### C. Configurar Límites de Recursos en Docker Compose (`deploy.resources`)
*   **Solución**: Declarar límites estrictos (`limits`) y recursos de inicio garantizados (`reservations`) en el manifiesto de composición para prevenir fugas de memoria globales que afecten a la máquina host.
*   **Ejemplo en `docker-compose.yml`**:
    ```yaml
    services:
      api:
        # ...
        deploy:
          resources:
            limits:
              cpus: '1.0'
              memory: 1024M
            reservations:
              cpus: '0.2'
              memory: 512M
    ```

### D. Optimizar los Watchers de Compilación (Evitar fatiga del File Watcher)
El cargador integrado de compilación en caliente de NestJS (`start:dev`) observa continuamente el sistema de archivos. Si no se restringe, consume RAM y CPU escaneando directorios temporales y dependencias.
*   **Solución**: Configurar `watchOptions` en `tsconfig.json` para indicarle al compilador qué carpetas ignorar explícitamente:
    ```json
    "watchOptions": {
      "watchFile": "priorityPollingInterval",
      "watchDirectory": "dynamicprioritypolling",
      "excludeDirectories": ["**/node_modules", "dist", ".git"]
    }
    ```

---

## ⚡ 2. Disponibilidad de Modificación Directa (Desarrollo en Vivo)

Para permitir a los desarrolladores realizar cambios directamente en el código fuente de la máquina anfitriona y ver los efectos en caliente dentro del contenedor sin reconstruir la imagen de Docker, se implementan dos aproximaciones:

### A. Docker Compose Watch (La Vía Moderna)
Docker Compose Watch es la característica oficial de Docker para sincronizar código de forma eficiente sin sobrecargar el subsistema de entrada/salida de disco, lo cual es crítico al usar Docker en Windows mediante WSL2.
*   **Configuración en `docker-compose.dev.yml`**:
    ```yaml
    services:
      api:
        build:
          context: ./backend
          dockerfile: Dockerfile
        develop:
          watch:
            - path: ./backend/src
              target: /app/src
              action: sync
            - path: ./backend/package.json
              action: rebuild
    ```
*   **Ventaja**: Evita montar todo el directorio en vivo y solo sincroniza carpetas específicas de código. Si cambias el `package.json`, reconstruye el contenedor de forma automática.

### B. Montajes por Enlace (Bind Mounts) con Volumen Anónimo para dependencias
Si no se utiliza Compose Watch, se puede utilizar el montaje por enlace estándar. Sin embargo, para evitar que la carpeta `node_modules` local (del host Windows) sobrescriba la carpeta del contenedor (del host Linux, la cual contiene las binarias nativas de Prisma y bcrypt), se debe declarar un volumen anónimo.
*   **Configuración**:
    ```yaml
    volumes:
      - ./backend:/app
      - /app/node_modules # Volumen anónimo que aísla la dependencia interna del contenedor
    ```
*   **Manejo de Recarga**: Ejecutar el script `npm run start:dev` como punto de entrada del contenedor. Esto mantendrá vivo un watcher interno que reiniciará el proceso automáticamente al detectar la sincronización del archivo modificado.

---

## 🛡️ 3. Exclusión de Dependencias Innecesarias y Secretos (.dockerignore y .gitignore)

Llevar dependencias de desarrollo (*devDependencies*) o archivos locales con secretos en la imagen de producción aumenta drásticamente el peso del contenedor y expone vulnerabilidades de seguridad.

### A. Uso Estratégico de `.dockerignore`
Durante la ejecución de `docker build`, Docker envía todo el contexto del directorio local al demonio de Docker. Si no se filtra, copiará la carpeta local `node_modules` y archivos con credenciales reales.
*   **Solución**: Crear un archivo `.dockerignore` en el directorio de la aplicación (`backend/.dockerignore`) indicando explícitamente qué excluir:
    ```text
    node_modules
    dist
    .env
    .env.*
    .git
    .github
    Dockerfile*
    docker-compose*
    ```
*   **Resultado**: El tamaño del contexto de construcción pasa de ~400MB a escasos kilobytes, haciendo el proceso de empaquetado casi instantáneo y libre de archivos host conflictivos.

### B. Multi-Stage Builds (Construcciones Multi-Etapa)
*   **Concepto**: Dividir el Dockerfile de producción en dos etapas lógicas:
    1.  **Builder**: Instala todas las dependencias (`npm ci`), ejecuta la compilación de TypeScript a JavaScript y genera el cliente Prisma.
    2.  **Runner**: Copia únicamente el directorio `/dist` compilado y el manifiesto `package.json`, e instala exclusivamente dependencias de producción (`npm ci --omit=dev`), re-generando el cliente Prisma sin TypeScript compiler, linters ni herramientas de testeo.
*   **Implementación**: Configurado en [Dockerfile.prod](file:///d:/proyectos/sas_gym/backend/Dockerfile.prod).

### C. Protección de Secretos vía `.gitignore`
*   **Solución**: Mantener los secretos (`JWT_SECRET`, contraseñas de BD) fuera del sistema de control de versiones. Esto requiere un archivo `.gitignore` robusto a nivel raíz del repositorio ([.gitignore](file:///d:/proyectos/sas_gym/.gitignore)) y subdirectorios de API ([backend/.gitignore](file:///d:/proyectos/sas_gym/backend/.gitignore)) que bloquee la subida de archivos `.env`.
*   **Buenas Prácticas**:
    *   Subir únicamente archivos de plantilla `.env.example` con llaves vacías o credenciales de desarrollo inocuas.
    *   Inyectar las variables reales en producción mediante el sistema de orquestación (variables de entorno del Host o Secret Managers) en lugar de depender de archivos físicos en el servidor.

---

## 📋 Checklist de Aplicación en el Repositorio SaaaS GYM

1.  [x] **Crear .gitignore en la raíz** ([.gitignore](file:///d:/proyectos/sas_gym/.gitignore)) para bloquear `.env` y carpetas de dependencias de forma global.
2.  [x] **Crear .dockerignore en backend** ([.dockerignore](file:///d:/proyectos/sas_gym/backend/.dockerignore)) para evitar transferir secretos locales y `node_modules` del host al demonio de Docker.
3.  [x] **Implementar Dockerfile.prod con Multi-Stage Build** ([Dockerfile.prod](file:///d:/proyectos/sas_gym/backend/Dockerfile.prod)) aislando la etapa de construcción de la de ejecución y usando `--omit=dev` para omitir librerías de desarrollo.
4.  [ ] **Limitar memoria** en la orquestación configurando la variable `NODE_OPTIONS=--max-old-space-size=768` y asignando límites en Docker Compose.
5.  [ ] **Aislar node_modules** agregando `/app/node_modules` en los volúmenes del compose de desarrollo.
6.  [ ] **Implementar Docker Compose Watch** como la opción por defecto en `docker-compose.dev.yml`.

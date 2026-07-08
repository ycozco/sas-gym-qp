# Guía de Descarga y Despliegue Segmentado

Esta guía documenta los pasos para clonar de forma parcial el repositorio y desplegar:
1. El **Backend (API + WebSocket)**.
2. El **Panel Web de Administración** (Vite/React).
3. La **Landing Page** (HTML/CSS estático o SPA).

---

## 1. Subdominios y Ruteo Propuesto

Para tener una infraestructura limpia y bien segmentada, utilizaremos **4 subdominios** apuntando al mismo servidor (VPS):

| Subdominio | Destino Interno | Descripción |
| :--- | :--- | :--- |
| **`api.sas-gym.qpsecure.cloud`** | `sasgym_api:3000` | API REST (NestJS) |
| **`ws.sas-gym.qpsecure.cloud`** | `sasgym_api:3000` | Conexiones WebSocket (Socket.io) |
| **`admin.sas-gym.qpsecure.cloud`** | Nginx (Directorio `/web_admin/dist`) | Panel de Control de Administración |
| **`app.sas-gym.qpsecure.cloud`** | Nginx (Directorio `/landing`) | Landing Page Comercial del Gimnasio |

> [!NOTE]
> Dado que NestJS maneja las conexiones WebSocket en el mismo servidor HTTP por defecto, tanto `api.` como `ws.` apuntarán al contenedor de NestJS (`port: 3000`). La separación en subdominios se realiza a nivel del proxy inverso (Nginx).
>
> Usar `app.sas-gym.qpsecure.cloud` para la **Landing Page** es una excelente idea ya que no utilizaremos la versión Flutter Web en este despliegue.

---

## 2. Clonación Parcial (Git Sparse Checkout)

Para descargar únicamente el backend, la web de administración y la landing page (omitimos las carpetas móviles de Flutter para optimizar recursos en el servidor), ejecuta:

```bash
# 1. Clona el repositorio sin descargar los archivos físicos inicialmente
git clone --no-checkout https://github.com/ycozco/sas-gym-qp.git sas_gym_server
cd sas_gym_server

# 2. Inicializa el modo de descarga selectiva
git sparse-checkout init --cone

# 3. Define únicamente las carpetas y archivos necesarios para la API, la Web y la Landing
# (Asegúrate de agregar la carpeta 'landing' una vez que la crees en el repositorio)
git sparse-checkout set backend web_admin landing docker-compose.prod.yml

# 4. Descarga los archivos de la rama de producción
git checkout production
```

---

## 3. Configuración del Proxy Inverso (Nginx) en el Servidor

Para distribuir el tráfico correctamente hacia cada subdominio y habilitar WebSockets, se debe configurar un servidor Nginx en el host o mediante un contenedor Docker de proxy. 

Aquí tienes la configuración ideal de Nginx (`/etc/nginx/sites-available/sas-gym`):

```nginx
# ─── 1. API REST NESTJS ──────────────────────────────────────────────
server {
    listen 80;
    server_name api.sas-gym.qpsecure.cloud;

    location / {
        proxy_pass http://127.0.0.1:3000; # Redirecciona al contenedor de la API
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# ─── 2. WEBSOCKETS GATEWAY ───────────────────────────────────────────
server {
    listen 80;
    server_name ws.sas-gym.qpsecure.cloud;

    location / {
        proxy_pass http://127.0.0.1:3000; # WebSocket comparte puerto con la API NestJS
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade"; # Habilita protocolo WS/WSS
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# ─── 3. WEB ADMIN DASHBOARD (VITE/REACT) ─────────────────────────────
server {
    listen 80;
    server_name admin.sas-gym.qpsecure.cloud;

    root /var/www/sas_gym/backend/public/admin; # Ruta al compilado unificado de React
    index index.html;

    location / {
        try_files $uri $uri/ /index.html; # Necesario para React Router SPA
    }
}

# ─── 4. LANDING PAGE (HTML/CSS/JS ESTÁTICO DE ASTRO) ──────────────────
server {
    listen 80;
    server_name app.sas-gym.qpsecure.cloud;

    root /var/www/sas_gym/backend/public/landing; # Ruta al compilado estático de Astro
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

---

## 4. Despliegue e Inicio de Servicios en Docker

Con la nueva estructura unificada, **solo necesitas copiar o desplegar la carpeta `backend`** en tu servidor de producción, ya que incluye todos los compilados estáticos listos para ser servidos.

1. **Compilar localmente** la Landing Page y el Panel Web para inyectarlos en el backend:
   ```bash
   # Compilar Landing Page (Astro)
   cd landing
   npm install
   npm run build
   cd ..

   # Compilar Panel Web (React/Vite)
   cd web_admin
   npm install
   npm run build
   cd ..
   ```

2. Crea las variables de entorno productivas en la carpeta del backend:
   ```bash
   cp backend/.env.production.example backend/.env.production
   nano backend/.env.production
   ```

3. Levanta la base de datos, Redis y la API NestJS:
   ```bash
   # Inicia servicios esenciales desde la carpeta backend
   docker compose -f backend/docker-compose.prod.yml up -d db redis api
   ```


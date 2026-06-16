FROM node:22-alpine

# Instalar dependencias necesarias para compilar ciertos paquetes si fuera necesario
RUN apk add --no-cache libc6-compat openssl

WORKDIR /app

# Copiar archivos de dependencias y la carpeta Prisma
COPY package*.json ./
COPY prisma ./prisma/

# Instalar dependencias de producción y desarrollo
RUN npm install

# Copiar el resto del código
COPY . .

# Generar el cliente de Prisma
RUN npx prisma generate

# Compilar la aplicación
RUN npm run build

# Exponer el puerto
EXPOSE 3000

# Por defecto, iniciar la aplicación en modo desarrollo para permitir tweaks
CMD ["npm", "run", "start:prod"]

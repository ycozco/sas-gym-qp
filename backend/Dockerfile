FROM node:22-alpine

# Dependencias nativas para Prisma y paquetes de Node en Alpine.
RUN apk add --no-cache libc6-compat openssl

WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci

COPY . .

RUN npx prisma generate
RUN npm run build

EXPOSE 3000

CMD ["npm", "run", "start:prod"]

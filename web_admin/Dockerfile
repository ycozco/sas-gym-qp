FROM node:24-alpine@sha256:461d310e527d9bf0d3509d3bdfd8e96bf7b5c305b9b1d9bf5bdf8e98679d63c5 AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine@sha256:28c6168e312b9bf0d3509d3bdfd8e96bf7b5c305b9b1d9bf5bdf8e98679d63c57 AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

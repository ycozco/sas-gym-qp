FROM ghcr.io/cirruslabs/flutter:3.44.0 AS deps

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

FROM deps AS ci

COPY . .
RUN flutter analyze
RUN flutter test

FROM deps AS build

COPY . .
ARG APP_ENV=dev
ARG APP_MODE=backend
ARG ENABLE_QR_SIMULATOR=false
ARG API_BASE_URL=http://localhost:3000/api/v1
RUN flutter build web --release --no-wasm-dry-run --pwa-strategy=none \
    --dart-define=APP_ENV=${APP_ENV} \
    --dart-define=APP_MODE=${APP_MODE} \
    --dart-define=ENABLE_QR_SIMULATOR=${ENABLE_QR_SIMULATOR} \
    --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:alpine AS runtime

COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

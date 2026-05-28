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
RUN flutter build web --release

FROM nginx:alpine AS runtime

COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

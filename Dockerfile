# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --base-href /

# Stage 2: Serve with nginx on dynamic PORT (Cloud Run compatible)
FROM nginx:alpine
RUN apk add --no-cache gettext
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY --from=builder /app/build/web /usr/share/nginx/html

# Use envsubst to substitute PORT at runtime, then start nginx
CMD ["/bin/sh", "-c", "envsubst '${PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]

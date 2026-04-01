# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --base-href /

# Stage 2: Serve with Caddy (gVisor-compatible, Cloud Run-friendly)
# Caddy works reliably in Cloud Run's gVisor sandbox unlike nginx
FROM caddy:2-alpine
COPY --from=builder /app/build/web /srv
COPY Caddyfile /etc/caddy/Caddyfile
EXPOSE 8080

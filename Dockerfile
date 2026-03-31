# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --base-href /

# Stage 2: Serve with nginx (Cloud Run PORT=8080)
FROM nginx:alpine
# Remove default nginx config that conflicts with our custom config
RUN rm -f /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

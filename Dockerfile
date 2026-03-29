# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --base-href /

# Stage 2: Serve with nginx on port 8080 (Cloud Run requirement)
FROM nginx:alpine
RUN sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

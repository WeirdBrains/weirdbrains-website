# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app

# Copy deps first for layer caching
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy all source
COPY . .

# Build Flutter Web
RUN flutter build web --release --base-href / && \
    echo "=== Flutter build complete ===" && \
    ls -la build/web/

# Stage 2: Serve on port 8080 (Cloud Run requirement)
FROM nginx:alpine

# Remove default config
RUN rm -f /etc/nginx/conf.d/default.conf

# Create tmp dirs nginx needs for non-root operation
RUN mkdir -p /tmp/client_body /tmp/proxy /tmp/fastcgi /tmp/uwsgi /tmp/scgi \
    && chmod 777 /tmp/client_body /tmp/proxy /tmp/fastcgi /tmp/uwsgi /tmp/scgi

COPY nginx.conf /etc/nginx/nginx.conf

# Copy Flutter build output — will fail loudly if build/web is empty
COPY --from=builder /app/build/web /usr/share/nginx/html

# Verify content was copied
RUN ls /usr/share/nginx/html/ && \
    test -f /usr/share/nginx/html/index.html && \
    echo "=== nginx html content verified ==="

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

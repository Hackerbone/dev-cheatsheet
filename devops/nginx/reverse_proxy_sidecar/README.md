# NGINX - Reverse Proxy Sidecar (with and without SSL/HTTPS) 🚀

Welcome to the **NGINX - Reverse Proxy Sidecar** repository! This project is a sidecar container that runs NGINX as a reverse proxy. It is designed to work alongside a primary container running a web server. The NGINX sidecar listens on ports **80** and **443**, forwarding requests to the primary container on port **3000**.

---

## Overview

This setup provides an easy way to manage your web traffic with NGINX, offering:

- **HTTP and HTTPS support** (with SSL/TLS)
- **WebSocket compatibility**
- **Flexible deployment** options: use `network host` mode or container names in a shared network

If you're deploying all containers within a single network, you can simply replace `127.0.0.1` with the container name of your primary web server for added clarity and ease of management.

---

## Prerequisites

- **Docker CLI** 🐳
- **Linux/MacOS server** 🖥️
- **SSL Certificates** (for HTTPS) 🔐

---

## Getting Started

### 1. Configuration Files

#### `nginx.conf` (with SSL/HTTPS)

```nginx
# Optionally, redirect HTTP to HTTPS
server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    # SSL configuration
    ssl_certificate     ./certs/origin.pem;
    ssl_certificate_key ./certs/key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Reverse proxy configuration
    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;

        # Optional: support for WebSocket connections
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "upgrade";
    }
}
```

#### `nginx.http.conf` (HTTP Only)

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;

        # Optional: support for WebSocket connections
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "upgrade";
    }
}
```

### 2. Shell Script: proxy.sh 🛠️

This script checks for the required configuration and certificate files, and then runs the NGINX container in detached mode.

```bash
#! /bin/bash

# Check if certs directory exists
if [ ! -d "$(pwd)/certs" ]; then
  echo "Creating certs directory"
  mkdir -p "$(pwd)/certs"
fi

# Check if nginx.conf exists, if not exit
if [ ! -f "$(pwd)/nginx.conf" ]; then
  echo "nginx.conf not found"
  exit 1
fi

# Check for certificates
if [ ! -f "$(pwd)/certs/key.pem" ] || [ ! -f "$(pwd)/certs/origin.pem" ]; then
  echo "Certificates not found"
  exit 1
fi

# Run NGINX container using network host
docker run -d \
  --name nginx-proxy \
  --network host \
  -p 80:80 \
  -p 443:443 \
  -v "$(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$(pwd)/certs:/etc/nginx/certs:ro" \
  nginx:latest
```

> Important: We're using `--network host` in this setup to directly share the host's networking stack with the container. If all containers are on a single Docker network, you can use container names instead of 127.0.0.1 in your nginx.conf to reference the primary container. For eg: `proxy_pass http://web-server:3000;` where `web-server` is the name of your primary container residing on the same docker network.

---

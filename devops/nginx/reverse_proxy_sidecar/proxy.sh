#! /bin/bash

# check if certs directory exists
if [ ! -d "$(pwd)/certs" ]; then
  echo "Creating certs directory"
  mkdir -p "$(pwd)/certs"
fi


# check if nginx.conf exists, if not exit
if [ ! -f "$(pwd)/nginx.conf" ]; then
  echo "nginx.conf not found"
  exit 1
fi

# check for certificates
if [ ! -f "$(pwd)/certs/key.pem" ] || [ ! -f "$(pwd)/certs/origin.pem" ]; then
  echo "Certificates not found"
  exit 1
fi

docker run -d \
  --name nginx-proxy \
  --network host \
  -p 80:80 \
  -p 443:443 \
  -v "$(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$(pwd)/certs:/etc/nginx/certs:ro" \
  nginx:latest
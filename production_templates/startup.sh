#!/bin/bash

# Create Traefik json file.
touch acme.json
chmod 600 acme.json

# Create proxy network.
/usr/local/bin/docker network create proxy

# Pull latest images.
/usr/local/bin/docker pull ${DOCKERHUB_REPO_HERE}

# Stop and exiting containers.
/usr/local/bin/docker-compose down

# Start containers based on the docker-compose.yml file.
/usr/local/bin/docker-compose up -d

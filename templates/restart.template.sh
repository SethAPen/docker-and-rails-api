    # Stop any running containers.
    docker-compose down

    # Remove Traefik acme file.
    rm acme.json

    # Create Traefik file and create the proxy network.
    touch acme.json
    chmod 600 acme.json
    docker network create proxy

    # Pull down your docker image and start the container with the logs.
    docker pull ${USER}/${DOCKERHUB_REPO}
    docker-compose up -d
    docker-compose logs -f
## Deploying Docker Images to Production

### This folder contains deployment scripts and Docker configuration files for deploying a Ruby on Rails app in API mode with a React frontend to a Ubuntu 18.04 linux server.

- Technologies/3rd party software list

  - [Docker](https://www.docker.com/)
  - [Docker-CE](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
  - [Docker Hub](https://hub.docker.com)
  - [Traefik](https://traefik.io/)
  - [Docker-Compose](https://docs.docker.com/compose/)
  - [Ruby on Rails](https://rubyonrails.org/)
  - [Let's Encrypt (for https)](https://letsencrypt.org/)

- Ensure [Docker-CE](https://docs.docker.com/install/linux/docker-ce/ubuntu/) and [Docker-Compose](https://docs.docker.com/compose/) are installed and the Docker service is running.
- Create a user that will run your Docker commands and deployment scripts and add them to the docker group.

  ```bash
  adduser ${YOUR_USERNAME}

  # Add user to sudo and docker groups.
  usermod ${YOUR_USERNAME} -G sudo,docker
  ```

### **NOTE**: The above step is not required, but is suggested for security reasons.

- Create a folder structure for your deployed server configuration files and deployment scripts.

  - Example /www/public/${YOUR_SITE_NAME} you can include a scripts folder if you want /www/public/${YOUR_SITE_NAME}/scripts

- Configure your deployment scripts as per your environment

  - The script below creates the docker proxy network and a configuration file for [Traefix](https://traefik.io/).
  - It also pulls your Docker image from [Docker Hub](https://hub.docker.com) and starts the container in daemon mode and outputs the logs to the console.

  - restart.sh <-- this name is up to you.

    ```bash
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
    ```

- The script below will be used in a cron task that will restart our containers at server restart.
- startup.sh

  ```bash
  #!/bin/bash

  # Stop running containers.
  /usr/local/bin/docker-compose down

  # Create Traefik acme file.
  touch acme.json
  chmod 600 acme.json

  # Create proxy network.
  /usr/local/bin/docker network create proxy

  # Pull latest images.
  /usr/local/bin/docker pull sethpen/poke-exchange-client
  /usr/local/bin/docker pull sethpen/poke-exchange-api

  # Start containers based on the docker-compose.yml file.
  /usr/local/bin/docker-compose up -d
  ```

- The below script is the configuration for [Traefix](https://docs.traefik.io/configuration/backends/file/).
- traefik.toml:

  ```bash
  debug = false

  logLevel = "INFO"
  defaultEntryPoints = ["https", "http"]

  [entryPoints]
    [entryPoints.http]
    address = ":80"
      [entryPoints.http.redirect]
      entryPoint = "https"
    [entryPoints.https]
    address = ":443"
    compress = true
    [entryPoints.https.tls]

  [retry]

  [docker]
  endpoint = "unix:///var/run/docker.sock"
  domain = "[domain_name_here]"
  watch = true
  exposedbydefault = false

  [acme]
  email = "[your_email_here]"
  storage = "acme.json"
  entryPoint = "https"
  OnHostRule = true
  [acme.httpChallenge]
  entryPoint = "http"
  ```

- The last script we need to add is the [docker-compose.yml](https://docs.docker.com/compose/compose-file/) file.
- docker-compose.yml

  ```yml
  version: "3"
  networks:
    default:
      external:
        name: proxy
  services:
    traefik:
      image: traefik:alpine
      restart: always
      ports:
        - 80:80
        - 443:443
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
        - ./traefik.toml:/traefik.toml
        - ./acme.json:/acme.json
    client:
      image: [your_image_name_here]
      restart: always
      labels:
        - "traefik.backend=client"
        - "traefik.docker.network=proxy"
        - "traefik.frontend.rule=Host:[host_domain_name_here]
        - "traefik.enable=true"
        - "traefik.port=80"
        - "traefik.default.protocol=http"
        - "traefik.frontend.priority=10"
    api:
      restart: always
      command: bash -c " RAILS_ENV=${RAILS_ENV}rails db:create db:migrate db:seed && RAILS_ENV=${RAILS_ENV} rails s -p ${PORT} -b '0.0.0.0'"
      image: [your_image_name_here]
      labels:
        - "traefik.backend=api"
        - "traefik.docker.network=proxy"
        - "traefik.enable=true"
        - "traefik.port=${PORT}"
        - "traefik.frontend.rule=PathPrefixStrip:/api/"
        - "traefik.default.protocol=http"
        - "traefik.frontend.priority=20"
      ports:
        - ${PORT}:${PORT}
      depends_on:
        - postgres
      environment:
        DATABASE_URL: ${DATABASE_URL}
        RAILS_ENV: ${RAILS_ENV}
        PORT: ${PORT}
    postgres:
      image: postgres:10-alpine
      restart: always
      volumes:
        - pgdb:/var/lib/postgresql/data
      labels:
        - "traefik.postgres=postgres"
        - "traefik.docker.network=proxy"
        - "traefik.enable=true"
        - "traefik.port=5432"
        - "traefik.default.protocol=http"
      environment:
        POSTGRES_USER: ${POSTGRES_USER}
        POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

  #prettier-ignore
  volumes:
    pgdb:
  ```

- Add the scripts on your server. I will add them in my /www/public/\${YOUR_SITE_NAME}/scripts folder
- Add an .env file to where you placed your scripts, it should look something like this.

  ```
  PORT=your_server_port
  DATABASE_URL=postgres://example_user:a_password@database_image__host_name:5432/db_name?encoding=utf8&pool=5&timeout=5000
  POSTGRES_USER=example_user
  POSTGRES_PASSWORD=a_password
  ```

- Lastly we will add a [Cron](https://en.wikipedia.org/wiki/Cron) task to our server to run our Docker containers on reboot.

  1. Become or sign in as root.
  2. Run `crontab -e`
  3. Add this command to your crontab.

  ```bash
  @reboot (sleep 30s ; su -c ${YOUR_USER_TO_RUN_COMMAND} ; cd /${YOUR_PATH_TO_STARTUP_SCRIPT} ; ./${NAME_OF_STARTUP_SCRIPT}.sh)&
  ```

- You should now have all you need to pull you images and deploy them into a production environment with https certs from [Let's Encrypt](https://letsencrypt.org/).

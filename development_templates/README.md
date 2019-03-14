## Setting up a Rails API development environment

First we will get all the prerequisites:

- Make sure you have a copy of either: Windows 10 Pro, Windows 10 Enterprise or Windows 10 Education
- When you have one of the above Windows versions, download [Docker for Windows](https://docs.docker.com/docker-for-windows/install/)
- Enable Hyper-V for windows with this command
  ```
  bcdedit /set hypervisorlaunchtype auto
  ```
  To turn off Hyper-V run this command
  ```
  bcdedit /set hypervisorlaunchtype off
  ```
  ### NOTE: You must restart Windows everytime you change this.
- Now install Docker for Windows and do NOT enable windows containers.
- If you are using the Windows Subsystem for Linux we need to do one more thing.
  - Go to settings and check the expose daemon on tcp localhost option. You may need to restart for this to take effect.

Once all the prerequisites are met we can begin configuring a Rails development environment.

First we will start a new rails project.

```
rails new ${YOUR_PROJECT_NAME} --api -d postgresql
```

Now that we have a new api project we can add all the files I have provided for you in this folder to the root of the project.

## Using The Provided Template Files

Copy all the files in this folder excluding the README of course.

- .dockerignore

  - This file prevents specific files from being copied over to the container on build.

  ```
  .dockerignore
  .git
  logs/
  tmp/
  ```

- .env

  - This file defines environment variables for Rails and the Docker containers.

  ```
  PORT=${YOUR_PORT}
  DATABASE_URL=${YOUR_DB_URL}
  POSTGRES_USER=${YOUR_USER}
  POSTGRES_PASSWORD=${YOUR_PASSWORD}
  ```

- package.json

  - Contains a bunch of handy commands for deployment to Docker Hub and starting/stopping our containers.
  - Use commands examples:

  ```
  $ yarn deploy
  $ yarn up
  $ yarn down
  ```

  ```json
  {
    "scripts": {
      "deploy": "docker build -t ${YOUR_USER_NAME}/${YOUR_PROJECT_NAME} . && docker login && docker push ${YOUR_USER_NAME}/${YOUR_PROJECT_NAME}",
      "up": "docker-compose up",
      "down": "docker-compose down"
    }
  }
  ```

- Dockerfile

  - This file defines our Docker Image that the containers will be based on.

  ```yml
  FROM ruby:2.5.3

  # change as per your local environment.
  ENV APP_HOME /api

  # Installation of dependencies
  RUN apt-get update -qq \
    && apt-get install -y \
    # Needed for certain gems
    build-essential \
    # Needed for postgres gem
    libpq-dev \
    # Needed for ActiveAdmin gem
    nodejs \
    # The following are used to trim down the size of the image by removing unneeded data
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf \
    /var/lib/apt \
    /var/lib/dpkg \
    /var/lib/cache \
    /var/lib/log

  # Create a directory for our application
  # and set it as the working directory
  RUN mkdir ${APP_HOME}
  WORKDIR ${APP_HOME}

  # Add our Gemfile and install gems
  COPY Gemfile* ${APP_HOME}/
  RUN bundle install

  # Copy over our application code
  COPY . ${APP_HOME}

  # Define environment variables for deployment.
  CMD RAILS_ENV=${RAILS_ENV} PORT=${PORT} DATABASE_URL=${DATABASE_URL} POSTGRES_USER=${POSTGRES_USER} POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
  ```

- docker-compose.yml

  - This file manages all our containers and defines the configuration for each one. It creates our volumes for our postgres database and defines commands to be run on container startup. For example database migrations or creating the database.

  ```yml
  version: "3"
  services:
    api:
      build: .
      command: bash -c "RAILS_ENV=${RAILS_ENV} rails db:create db:migrate db:seed && RAILS_ENV=${RAILS_ENV} rails s -p ${PORT} -b '0.0.0.0'"
      ports:
        - ${PORT}:${PORT}
      depends_on:
        - postgres
      tty: true
      stdin_open: true
      environment:
        - PORT=${PORT}
        - DATABASE_URL=${DATABASE_URL}
        - RAILS_ENV=${RAILS_ENV}
    postgres:
      image: postgres
      environment:
        - POSTGRES_USER=${POSTGRES_USER}
        - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      volumes:
        - pgdb:/var/lib/postgresql/data

  #prettier-ignore
  volumes:
    pgdb:
  ```

  That should be all you need to start developing a Rails app using Docker. See the production_templates folder for information on deploying to production.

  If something isn't working for you or you found an error, please raise an issue on the github repository.

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
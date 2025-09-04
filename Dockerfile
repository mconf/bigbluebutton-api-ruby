FROM ruby:3.4.5

ENV app=/usr/src/app

# Create app directory
RUN mkdir -p $app
WORKDIR $app

# Bundle app source
COPY . $app

# Set the app directory as safe in Git, to avoid 'detected dubious ownership in repository' errors
RUN git config --global --add safe.directory ${app}

# Install app dependencies
RUN gem install bundler -v 2.6.9
RUN bundle install

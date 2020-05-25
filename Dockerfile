FROM ruby:2.6.5

ENV app /usr/src/app

# Create app directory
RUN mkdir -p $app
WORKDIR $app

# Bundle app source
COPY . $app

# Install app dependencies
RUN bundle install

FROM ruby:2.5-alpine

WORKDIR /double_entry

RUN set -ex; \
    apk add --no-cache \
        build-base \
        git \
        mariadb-dev \
        postgresql-dev \
        sqlite-dev \
        tzdata \
        ; \
    gem update --system

COPY Gemfile* double_entry.gemspec ./
COPY lib/double_entry/version.rb ./lib/double_entry/version.rb
RUN bundle install

COPY . ./
COPY spec/support/database.example.yml ./spec/support/database.yml

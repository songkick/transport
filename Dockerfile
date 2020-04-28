FROM eu.gcr.io/soundbadger-management/songkick-ruby:2.6

RUN apt-get update
RUN apt-get -y install libxslt-dev libxml2-dev

COPY Gemfile* /app/
COPY songkick-transport.gemspec /app/
RUN bundle install

COPY . /app/

RUN mkdir -p log

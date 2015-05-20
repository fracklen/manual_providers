FROM lokalebasen/rubies:2.2.0
MAINTAINER Martin Neiiendam mn@lokalebasen.dk
ENV REFRESHED_AT 2015-05-20

WORKDIR /var/www/manual_providers/release

ENV ETCD_ENV manual_providers
ENV APP_PATH /var/www/manual_providers/release
RUN mkdir -p /var/log/manual_providers

ADD Gemfile /var/www/manual_providers/release/Gemfile
ADD Gemfile.lock /var/www/manual_providers/release/Gemfile.lock
RUN bundle install --deployment

ENV BUNDLE_GEMFILE /var/www/manual_providers/release/Gemfile
ADD build.tar /var/www/manual_providers/release

# The supervisor will make sure cron is run
RUN crontab /var/www/manual_providers/release/config/cron.conf
RUN cron

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/var/www/manual_providers/release/config/supervisord.conf"]

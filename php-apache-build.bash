#!/usr/bin/env bash
set -e

[ -f './project.bash' ] && source './project.bash'

PROJECT_NAME=${PROJECT_NAME:-'project'}

ALPINE_VERSION=${ALPINE_VERSION:-'3.4'}

CONTAINER_USER=${CONTAINER_USER:-developer}
TEMP_DIR=$(mktemp --directory rails-build-XXXXXXXX)

docker_end() {
		exit=$?

		echo 'Cleaning up'
		rm -r $TEMP_DIR

		exit $exit;
}

trap docker_end EXIT SIGINT SIGTERM

cat <<EOF > $TEMP_DIR/Dockerfile
FROM alpine:${ALPINE_VERSION}
MAINTAINER 'Matthew Jordan <matthewjordandevops@yandex.com>'

ENV LANG en_US.UTF-8
RUN adduser -u $(id -u $USER) -Ds /bin/bash $CONTAINER_USER

COPY apk-install.sh /usr/local/bin/apk-install.sh
RUN chmod u+x /usr/local/bin/apk-install.sh
RUN apk-install.sh

RUN mkdir -pv /tmp/php
COPY info.php /tmp/php/info.php

RUN which php && php --version
RUN which httpd && httpd -v

RUN curl -sS https://getcomposer.org/installer | \
			php -- --install-dir=/usr/local/bin --filename=composer
RUN chmod -R ugo=rx /usr/local/bin/*
RUN which composer && composer --version

RUN chown -R ${CONTAINER_USER}:apache /var/www/ /etc/apache2/ /var/log/apache2/

USER $CONTAINER_USER
WORKDIR /var/www/localhost/htdocs

VOLUME ["/var/www/localhost/htdocs"]
EXPOSE 80

# CMD ["httpd", "-D", "FOREGROUND"]
CMD sh -c 'kill -STOP \$$'
EOF

cat <<EOF > $TEMP_DIR/apk-install.sh
#!/usr/bin/env sh
set -eo pipefail

apk update
apk add \
			bash \
			apache2 \
			php5-apache2 \
			curl \
			php5-cli \
			php5-json \
			php5-phar \
			php5-openssl \
		&& echo 'End of package(s) installation.'

echo 'Cleaning up apks'
rm -rf '/var/cache/apk/*'

sed -ri "s/(User[[:space:]]+)apache/\1${CONTAINER_USER}/" /etc/apache2/httpd.conf
mkdir -p /run/apache2
EOF

cat <<EOF > $TEMP_DIR/info.php

<?php phpinfo(); ?>

EOF


docker build \
			 --no-cache=false \
			 --tag="${PROJECT_NAME}/apache-php:latest" $TEMP_DIR
docker tag \
			 "${PROJECT_NAME}/apache-php:latest" \
			 "${PROJECT_NAME}/apache-php:$(date +%s)"

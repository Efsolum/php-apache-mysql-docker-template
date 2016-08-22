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
EOF

cat <<EOF > $TEMP_DIR/apk-install.sh
#!/usr/bin/env sh
set -eo pipefail

apk update
apk add \
			php-apache2 \
			curl \
			php-cli \
			php-json \
			php-phar \
			php-openssl
		&& echo 'End of package(s) installation.'

echo 'Cleaning up apks'
rm -rf '/var/cache/apk/*'
EOF

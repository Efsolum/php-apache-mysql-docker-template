#!/usr/bin/env bash
set -e

[ -f './project.bash' ] && source './project.bash'

PROJECT_NAME=${PROJECT_NAME:-'project'}

ALPINE_VERSION=${ALPINE_VERSION:-'3.4'}
NODE_VERSION=${NODE_VERSION:-'6.2.0'}

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
ENV NPM_CONFIG_PREFIX /var/npm
ENV PATH \$NPM_CONFIG_PREFIX/bin:\$PATH

RUN adduser -u $(id -u $USER) -Ds /bin/bash $CONTAINER_USER

RUN apk update
RUN apk add \
					bash \
					curl \
					freetype-dev \
					g++ \
					gcc \
					git \
					glib \
					glib-dev \
					gnupg \
					libgcc \
					libstdc++ \
					libtool \
					linux-headers \
					make \
					"nodejs-dev>=${NODE_VERSION}" \
					"nodejs>=${NODE_VERSION}" \
					openssl-dev \
					openssl \
					pango-dev \
					poppler-dev \
					python-dev \
					sudo \
					tar \
					zlib-dev \
				&& echo 'End of package(s) installation.' \
				&& rm -rf '/var/cache/apk/*'

RUN mkdir \$NPM_CONFIG_PREFIX
RUN bash -c 'npm install -g \
							 		browserify \
							 		gulp \
							 && npm cache clean'

RUN mkdir /tmp/node-build
WORKDIR /tmp/node-build
COPY profile /tmp/node-build/bash-profile
RUN cat bash-profile >> /etc/profile

RUN chown -R root:$CONTAINER_USER \$NPM_CONFIG_PREFIX

USER $CONTAINER_USER
WORKDIR /var/www/localhost/htdocs

VOLUME ["/var/www/projects"]
CMD sh -c 'kill -STOP \$$'
EOF

cat <<EOF >> $TEMP_DIR/profile

# Application variables
export NPM_CONFIG_PREFIX=/var/npm
export PATH=\$NPM_CONFIG_PREFIX/bin:\$PATH
EOF

docker build \
			 --no-cache=false \
			 --tag "${PROJECT_NAME}/node-${NODE_VERSION}:latest" $TEMP_DIR
docker tag \
			 "${PROJECT_NAME}/node-${NODE_VERSION}:latest" \
			 "${PROJECT_NAME}/node-${NODE_VERSION}:$(date +%s)"

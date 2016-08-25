#!/usr/bin/env bash
set -e

[ -f './project.bash' ] && source './project.bash'

PROJECT_NAME=${PROJECT_NAME:-'project'}
DEV_USER=${DEV_USER:-'user'}

NODE_VERSION=${NODE_VERSION:-'6.2.0'}
MYSQL_VERSION=${MYSQL_VERSION:-'10.1.14'}

DATABASE_USER=${DATABASE_USER:-'app'}
DATABASE_PASS=${DATABASE_PASS:-'password'}

docker_err() {
		exit=$?

		echo '/nStoping containers'
		docker stop ${DEV_USER}-mysql-dbms ${DEV_USER}-apache-php ${DEV_USER}-node-assets

		exit $exit;
}

trap docker_err ERR

docker run \
			 --detach=true \
			 --name="${DEV_USER}-mysql-dbms" \
			 --env="DATABASE_USER=${DATABASE_USER}" \
			 --env="DATABASE_PASS=${DATABASE_PASS}" \
			 "${PROJECT_NAME}/mysql-dbms:latest"

docker run \
			 --detach=true \
			 --name="${DEV_USER}-apache-php-web" \
			 --publish='1000:80' \
			 --volume="$(dirname $(pwd))/src:/var/www/projects" \
			 "${PROJECT_NAME}/apache-php:latest"

docker run \
			 --detach=true \
			 --name="${DEV_USER}-node-assets" \
			 --volume="$(dirname $(pwd))/src:/var/www/projects" \
			 "${PROJECT_NAME}/node-${NODE_VERSION}:latest"

#!/usr/bin/env bash

set -eu

if [ ! -r VERSION ]; then
	echo "No version info found" >&2
	exit 1
fi

imageName="ghcr.io/gamesboost/deploy"
version=$(cat VERSION)
versionShort=$(echo "$version" | cut -d"-" -f1)
buildDate=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
gitBranch=$(git branch --show-current)
deploy=${DEPLOY:-0}

docker build . \
	--no-cache \
	--tag "$imageName:$version" \
	--tag "$imageName:$versionShort" \
	--build-arg VERSION="$version" \
	--build-arg BUILD_DATE="$buildDate" \
	--build-arg VCS_REF="$gitBranch"

if [ "$deploy" -eq 1 ]; then
	docker push "$imageName:$version"
	docker push "$imageName:$versionShort"
else
	docker inspect "$imageName:$version"
	docker inspect "$imageName:$versionShort"
fi

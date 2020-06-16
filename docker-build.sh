#!/bin/bash

NO_CACHE=""
echo "Do you want to build using docker cache from previous build? Type yes to use cache." ; read BUILD_CACHE
if [[ ! "$BUILD_CACHE" = "yes" ]]; then
    echo "Using --no-cache to build the image."
    echo "It will be slower than use docker cache."
    NO_CACHE="--no-cache"
else
    echo "Using cache to build the image."
    echo "Nice, it will be faster than use no-cache option."
fi

VERSION=$(cat PROJECT_VERSION | grep -oP '(?<="version": ")[^"]*')

cd client-api/

echo "Do you want to build image of terrabrasilis/deter-generate-files? Type yes to confirm or anything else." ; read BUILD_IMG1
if [[ "$BUILD_IMG1" = "yes" ]]; then
    echo 
    echo "/######################################################################/"
    echo " Build new image terrabrasilis/deter-generate-files:v$VERSION "
    echo "/######################################################################/"
    echo

    docker build $NO_CACHE -t "terrabrasilis/deter-generate-files:v$VERSION" --build-arg VERSION="v$VERSION" -f env-scripts/Dockerfile .
fi

echo "Do you want to build image of terrabrasilis/deter-amz-sync-client? Type yes to confirm or anything else." ; read BUILD_IMG2
if [[ "$BUILD_IMG2" = "yes" ]]; then
    echo 
    echo "/######################################################################/"
    echo " Build new image terrabrasilis/deter-amz-sync-client:v$VERSION "
    echo "/######################################################################/"
    echo

    docker build $NO_CACHE -t "terrabrasilis/deter-amz-sync-client:v$VERSION" --build-arg VERSION="v$VERSION" -f env-php/Dockerfile .
fi
# send to dockerhub
echo 
echo "The building was finished! Do you want sending these new images to Docker HUB? Type yes to continue." ; read SEND_TO_HUB
if [[ ! "$SEND_TO_HUB" = "yes" ]]; then
    echo "Ok, not send the images."
else
    echo "Nice, sending the images!"
    if [[ "$BUILD_IMG1" = "yes" ]]; then
        docker push "terrabrasilis/deter-generate-files:v$VERSION"
    fi
    if [[ "$BUILD_IMG2" = "yes" ]]; then
        docker push "terrabrasilis/deter-amz-sync-client:v$VERSION"
    fi
fi
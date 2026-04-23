#!/bin/sh

set -e

export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
export PROXY_UPSTREAM="git@github.com:artyoomi/xray-tproxy.git"
export PROXY_DIR="xray-tproxy"
export ROCKETCHAT_UPSTREAM="git@github.com:RocketChat/Rocket.Chat.git"
export ROCKETCHAT_DIR="rocketchat"
export APP_CONT_NAME="${ROCKETCHAT_DIR}"


start() {
  docker compose up --build -d
  docker attach ${APP_CONT_NAME}
}

stop() {
  docker compose down
}
trap stop EXIT


if [ ! -e "${ROCKETCHAT_DIR}" ]; then
    git clone "${ROCKETCHAT_UPSTREAM}" "${ROCKETCHAT_DIR}"
    echo "${ROCKETCHAT_DIR}" >> .git/info/exclude
fi

if [ ! -e "${PROXY_DIR}" ]; then
    git clone "${PROXY_UPSTREAM}" "${PROXY_DIR}"
    echo "${PROXY_DIR}" >> .git/info/exclude
    echo -e "\nFirstly read README.md in ${PROXY_DIR} to setup proxy. \
On second execution this message will disappear.\n"
    exit 0
fi

# Firstly generate dockerignore to ignore huge Rocket.Chat dependencies.
# Who even wrote this Dockerfile...
. ./create_dockerignore.sh "${ROCKETCHAT_DIR}/.devcontainer/Dockerfile" "${ROCKETCHAT_DIR}/.dockerignore"

start

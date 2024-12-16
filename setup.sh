#/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 The Linux Foundation

if [ $(uname) != "Darwin" ]; then
  source /etc/os-release
fi

SUDO_CMD=$(which sudo)
WHOAMI=$(whoami)
if [ ! -x "$SUDO_CMD" ] || [ "$WHOAMI" = "root" ]; then
	SUDO_CMD=""
fi

install_docker() {

  if [ "$NAME" = "Ubuntu" ]; then
    # Add Docker's official GPG key:
    "$SUDO_CMD" apt-get update
    "$SUDO_CMD" apt-get install ca-certificates curl
    "$SUDO_CMD" install -m 0755 -d /etc/apt/keyrings
    "$SUDO_CMD" curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    "$SUDO_CMD" chmod a+r /etc/apt/keyrings/docker.asc
    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      "$SUDO_CMD" tee /etc/apt/sources.list.d/docker.list > /dev/null
    "$SUDO_CMD" apt-get update
    "$SUDO_CMD" apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  elif [ "$NAME" = "Debian" ]; then
    # Add Docker's official GPG key:
    "$SUDO_CMD" apt-get update
    "$SUDO_CMD" apt-get install ca-certificates curl
    "$SUDO_CMD" install -m 0755 -d /etc/apt/keyrings
    "$SUDO_CMD" curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    "$SUDO_CMD" chmod a+r /etc/apt/keyrings/docker.asc
    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      "$SUDO_CMD" tee /etc/apt/sources.list.d/docker.list > /dev/null
    "$SUDO_CMD" apt-get update
    "$SUDO_CMD" apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  elif [ "$NAME" = "Fedora" ]; then
    "$SUDO_CMD" dnf -y install dnf-plugins-core
    "$SUDO_CMD" dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    "$SUDO_CMD" dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  elif [ "$NAME" = "Amazon Linux AMI" ]; then
    "$SUDO_CMD" yum update -y
    "$SUDO_CMD" amazon-linux-extras install docker
    "$SUDO_CMD" yum install -y docker
    "$SUDO_CMD" usermod -a -G docker ec2-user
  fi

  # Start at boot and run Docker
  systemctl enable docker
  systemctl start docker
}

# Install/run Docker
DOCKER_CMD=$(which docker)
if [ ! -x "$DOCKER_CMD" ]; then
  _install_docker
  DOCKER_CMD=$(which docker)
fi
if [ ! -x "$DOCKER_CMD" ]; then
  echo "Error: Docker failed to install/start"
  echo "Supported distributions: Ubuntu|Debian|Fedora|AmazonLinux"
  exit 1
fi

NPROC_CMD=$(which nproc)
if [ -x "$NPROC_CMD" ]; then
        THREADS=$($NPROC_CMD)
else
        echo "Error: nproc not found in PATH"; exit 1
fi

CURRENT_DIR=$(pwd)
BASE_DIR=$(basename "$CURRENT_DIR")
if [ "$BASE_DIR" = "data-extraction" ]; then
  echo "Starting Ubuntu Docker container..."
  # Apple Silicon
  # docker run -v "$PWD":/data-extraction -ti --platform linux/arm64 ubuntu:22.04 /bin/bash /data-extraction/script.sh
  # docker run -v "$PWD":/data-extraction -ti --platform linux/arm64 ubuntu:22.04 /bin/bash
  #
  # x86/x64
  docker run -v "$PWD":/data-extraction -ti ubuntu:22.04 /bin/bash /data-extraction/script.sh
  # docker run -v "$PWD":/data-extraction -ti ubuntu:24.04 /bin/bash

else
	echo "Error: invoke the shell script from the data-extraction folder"; exit 1
fi

echo "Container and batch job stopped running"; exit 0

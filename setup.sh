#!/bin/bash

# Docker setup
brew install colima
brew install docker docker-compose
mkdir -p ~/.docker/cli-plugins
ln -sfn "$(brew --prefix)"/opt/docker-compose/bin/docker-compose ~/.docker/cli-plugins/docker-compose
brew install docker-Buildx
ln -sfn "$(brew --prefix)"/opt/docker-buildx/bin/docker-buildx ~/.docker/cli-plugins/docker-buildx

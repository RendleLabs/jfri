#!/bin/bash

export CLUSTER_DOMAIN=spiffydemo.com
export ACME_EMAIL=mark@rendlelabs.com

export DOCKER_HOST=tcp://spiffydemo-manager.northeurope.cloudapp.azure.com:2376
export DOCKER_TLS_VERIFY=1

#docker network create --driver=overlay traefik

#docker service create \
#    --name docker-proxy \
#    --network traefik \
#    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly \
#    --constraint 'node.role==manager' \
#    rancher/socat-docker

docker service create \
    --name traefik \
    --publish 80:80 --publish 8080:8080 \
    --network traefik \
    --mode global \
    traefik:latest \
    --docker \
    --docker.swarmmode \
    --docker.endpoint=tcp://docker-proxy:2375 \
    --docker.domain=${CLUSTER_DOMAIN} \
    --docker.watch \
    --web

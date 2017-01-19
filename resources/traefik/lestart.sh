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
    --publish 80:80 --publish 443:443 --publish 8080:8080 \
    --network traefik \
    --mode global \
    --mount type=bind,source=/var/tmp,target=/etc/traefik/acme \
    traefik:latest \
    --docker \
    --docker.swarmmode \
    --docker.endpoint=tcp://docker-proxy:2375 \
    --docker.domain=${CLUSTER_DOMAIN} \
    --docker.watch \
    --entryPoints='Name:https Address::443 TLS' \
    --entryPoints='Name:http Address::80 Redirect.EntryPoint:https' \
    --defaultEntryPoints=http,https \
    --acme.entrypoint=https \
    --acme.email=${ACME_EMAIL} \
    --acme.onHostRule=true \
    --acme.onDemand=true \
    --acme.storage=/etc/traefik/acme/acme.json \
    --web

    #--acme.domains=${CLUSTER_DOMAIN} \

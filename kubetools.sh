#!/bin/bash
CONTAINER_NAME=kubetools

if [ "$(docker inspect -f '{{.State.Running}}' $CONTAINER_NAME 2> /dev/null )" == "" ]; then
    docker run -it --name $CONTAINER_NAME       \
        -v ~/.azure:/root/.azure                \
        -v $PWD:/var/lib/src                    \
        -v ~/.kube/config:/root/.kube/config    \
        --network=host                          \
        --rm                        \
        --workdir /var/lib/src                  \
        aimvector/kube-tools:latest
else
    docker exec -it $CONTAINER_NAME bash
fi
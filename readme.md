# Kubernetes Toolset

This docker image is made up of common used tools I use for working with Kubernetes on Azure
You do not need to install tools seperately and only need docker to run this container

This docker image includes:

* Kubectl
* Azure CLI
* Helm

## Build

```
docker build . -t kube-tools
```

## Run

```
docker run -it --name kube-tools --rm -p 8001:8001 kube-tools bash
```

## Usage

Once you have a terminal as per `docker run -it` above, you can run the tools in the docker container

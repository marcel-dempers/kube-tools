# Kubernetes Toolset

This docker image is made up of common used tools I use for working with Kubernetes on Azure. <br/>
You do not need to install tools seperately and only need docker to run this container

This docker image includes:

* Kubectl
* Azure CLI
* Helm

## Usage

You can persist `kubeconfig` by mounting a volume.
I also mount my local directory into the container so i can pass files around to `kubectl` and `helm`

Note: On windows to ensure `$PWD` works, set this in your bash terminal: ` export MSYS_NO_PATHCONV=1`


### Windows 

```
docker run -it --name kube-tools -v $PWD:/var/lib/src -v /C/Users/docker/kube-tools:/root/.kube --rm -p 8001:8001 --workdir /var/lib/src aimvector/kube-tools:latest bash
```

### Linux 

Setup an alias for `kubetools`

```
echo "alias kubetools='docker run -it --name kube-tools -v \$PWD:/var/lib/src -v ~/.kube/config:/root/.kube/config --rm -p 8001:8001 --workdir /var/lib/src aimvector/kube-tools bash'" >> ~/.bashrc

```
Or just run the image:

```
docker run -it --name kube-tools -v $PWD:/var/lib/src -v ~/.kube/config:/root/.kube/config --rm -p 8001:8001 --workdir /var/lib/src aimvector/kube-tools bash
```

Once in, you can access the tools:
```
kubectl --help
helm --help
az --help
```

## Build from source

If you wish to customise it, you can build it from source:

```
docker build . -t kube-tools
```
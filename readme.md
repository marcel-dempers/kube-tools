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

### How to Install

You can install kube-tools via your bash profile and then simply run `kubetools` to start it up. 

#### Windows

Open the C:\Program Files\Git\etc\aliases.sh as Adminstrator and add the following script to a new line and the end of the file

```
alias kubetools='export MSYS_NO_PATHCONV=1; winpty docker run --rm -it --name kube-tools -v "$PWD":/var/lib/src -v /C/Users/docker/kube-tools/.azure:/root/.azure -v /C/Users/docker/kube-tools/.kube:/root/.kube --rm -p 8001:8001 aimvector/kube-tools:latest'
```

If you cannot install it, you can manually run it with the docker run command below:

```
docker run -it --name kube-tools -v "$PWD":/var/lib/src -v /C/Users/docker/kube-tools/.azure:/root/.azure -v /C/Users/docker/kube-tools/.kube:/root/.kube --rm -p 8001:8001 --workdir /var/lib/src aimvector/kube-tools:latest
```

#### Linux

Setup an alias for `kubetools`

```
echo "alias kubetools='docker run -it --name kube-tools -v ~/.azure:/root/.azure -v \$PWD:/var/lib/src -v ~/.kube/config:/root/.kube/config --rm --network=host --workdir /var/lib/src aimvector/kube-tools'" >> ~/.bashrc

```
Or just run the image:

```
docker run -it --name kube-tools -v ~/.azure:/root/.azure -v $PWD:/var/lib/src -v ~/.kube/config:/root/.kube/config --rm --network=host --workdir /var/lib/src aimvector/kube-tools
```

Once in, you can access the tools:
```
kubectl --help
helm --help
az --help
```

Alternatively, grab running the following command and get `kubetools` add to your `/usr/local/bin`

```bash
wget -qO https://raw.githubusercontent.com/marcel-dempers/kube-tools/master/kubetools.sh ~/kubetools
chdmox +x ~/kubetools
sudo mv ~/kubetools /usr/local/bin/kubetools
```

## Build from source

If you wish to customise it, you can build it from source:

```
docker build . -t kube-tools
```

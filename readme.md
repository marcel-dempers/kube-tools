# Kubernetes Toolset

This docker image is made up of common used tools I use for working with Kubernetes on Azure. <br/>
You do not need to install tools seperately and only need docker to run this container

This docker image includes:

* Kubectl
* Azure CLI
* Helm
* kubectx
* kubens
* Heptio ark
* Cloudfare SSL tools (for boostrapping clusters)

## Setup

You will want to persist your files on your pc somewhere.
On Windows, I do this in `C:\Users\<ME>\kube-tools\`
On Linux, I use my home dir.

Make sure the above folder exists!

I recommend using Powershell for Windows, but for bash on windows:
Ensure `$PWD` works, set this in your bash terminal: ` export MSYS_NO_PATHCONV=1`

### How to Install

You can install kube-tools via your bash profile and then simply run `kubetools` to start it up. 

#### Windows

Run it: (Replace the user directory with yours!)
```
docker run -it  -v ${PWD}:/var/lib/src -v $home/kube-tools:/root --rm --workdir /var/lib/src aimvector/kube-tools:latest
```

#### Linux

Setup an alias for `kubetools`

```
echo "alias kubetools='docker run -it --rm  -v ~/.azure:/root/.azure -v \$PWD:/kubetools -v ~/.kube:/root/.kube --rm --network=host --workdir /kubetools aimvector/kube-tools'" >> ~/.bashrc

```
Or just run the image:

```
docker run -it --rm  -v ~/.azure:/root/.azure -v $PWD:/var/lib/src -v ~/.kube:/root/.kube --rm --network=host --workdir /var/lib/src aimvector/kube-tools
```

Once in, you can access the tools:
```
kubectl --help
helm --help
az --help
kubectx
kubens
ark --help

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

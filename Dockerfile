FROM debian:jessie

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
        ca-certificates \
        curl \
        wget \
        libssl-dev \ 
        libffi-dev \
        python-dev \
        nano \
        build-essential \
	&& rm -rf /var/lib/apt/lists/*

#Google Kubernetes control cmd
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

#Azure CLI
RUN wget https://bootstrap.pypa.io/get-pip.py --secure-protocol=auto \
    && python ./get-pip.py
RUN pip install --upgrade pip wheel jmespath-terminal urllib3
RUN pip install azure-cli==2.0.6
RUN export PATH=$PATH:~/.local/bin

#PATCH URL LIB -> https://github.com/Azure/azure-cli/issues/3498
RUN cp -r  /usr/local/lib/python2.7/dist-packages/urllib3 /usr/local/lib/python2.7/site-packages/ \ 
&& cp -r /usr/local/lib/python2.7/dist-packages/urllib3 /usr/lib/python2.7/dist-packages/ \
&& cp -r /usr/local/lib/python2.7/dist-packages/urllib3 /usr/lib/python2.7/site-packages/ \
&& pip install --upgrade urllib3

#K8 Helm
RUN wget -q "https://storage.googleapis.com/kubernetes-helm/helm-v2.7.2-linux-amd64.tar.gz" -O helm.tar.gz && \
tar -xzf helm.tar.gz && \
rm helm.tar.gz && \
mv linux-amd64/helm /usr/local/bin/helm

#Expose for kubectl proxy
EXPOSE 8001
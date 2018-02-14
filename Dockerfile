FROM python:3.6.4-alpine3.7

#Some Tools
RUN apk add --no-cache curl ncurses bash

#Google Kubernetes control cmd
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

#Expose for kubectl proxy
EXPOSE 8001

#K8 Helm
RUN wget -q "https://storage.googleapis.com/kubernetes-helm/helm-v2.7.2-linux-amd64.tar.gz" -O helm.tar.gz && \
tar -xzf helm.tar.gz && \
rm helm.tar.gz && \
mv linux-amd64/helm /usr/local/bin/helm


#Azure CLI
WORKDIR azure-cli

RUN wget -q "https://github.com/Azure/azure-cli/archive/azure-cli-2.0.25.tar.gz" -O azcli.tar.gz && \
    tar -xzf azcli.tar.gz && \
    cp azure-cli-azure-cli-2.0.25/** /azure-cli/ -r && \
    rm azcli.tar.gz

# pip wheel - required for CLI packaging
# jmespath-terminal - we include jpterm as a useful tool
RUN pip install --no-cache-dir --upgrade pip wheel jmespath-terminal
# bash gcc make openssl-dev libffi-dev musl-dev - dependencies required for CLI
# jq - we include jq as a useful tool
# openssh - included for ssh-keygen
# ca-certificates
RUN apk add --no-cache bash bash-completion gcc make openssl-dev libffi-dev musl-dev jq openssh \
    ca-certificates openssl git && update-ca-certificates
# We also, install jp
RUN wget https://github.com/jmespath/jp/releases/download/0.1.2/jp-linux-amd64 -qO /usr/local/bin/jp && chmod +x /usr/local/bin/jp

# 1. Build packages and store in tmp dir
# 2. Install the cli and the other command modules that weren't included
# 3. Temporary fix - install azure-nspkg to remove import of pkg_resources in azure/__init__.py (to improve performance)
RUN /bin/bash -c 'TMP_PKG_DIR=$(mktemp -d); \
    for d in src/azure-cli src/azure-cli-core src/azure-cli-nspkg src/azure-cli-command_modules-nspkg src/command_modules/azure-cli-*/; \
    do cd $d; echo $d; python setup.py bdist_wheel -d $TMP_PKG_DIR; cd -; \
    done; \
    [ -d privates ] && cp privates/*.whl $TMP_PKG_DIR; \
    all_modules=`find $TMP_PKG_DIR -name "*.whl"`; \
    pip install --no-cache-dir $all_modules; \
    pip install --no-cache-dir --force-reinstall --upgrade azure-nspkg azure-mgmt-nspkg;'


# Kubens \ Kubectx
RUN curl -L https://github.com/ahmetb/kubectx/archive/v0.4.0.tar.gz | tar xz \
    && cd ./kubectx-0.4.0 \
    && mv kubectx kubens utils.bash /usr/local/bin/ \
    && chmod +x /usr/local/bin/kubectx \
    && chmod +x /usr/local/bin/kubens \
    && cat completion/kubectx.bash >> ~/.bashrc \
    && cat completion/kubens.bash >> ~/.bashrc \
    && cd ../ \
    && rm -fr ./kubectx-0.4.0

#  Heptio ark
RUN mkdir ark-0.6.0 \
    && curl -L https://github.com/heptio/ark/releases/download/v0.6.0/ark-v0.6.0-linux-amd64.tar.gz | tar xz \
    && mv ark /usr/local/bin/ \
    && chmod +x /usr/local/bin/ark

# Tab completion
RUN cat /azure-cli/az.completion >> ~/.bashrc
RUN echo "" >> ~/.bashrc
RUN echo "source <(kubectl completion bash)" >> ~/.bashrc
RUN echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc

WORKDIR /

ENTRYPOINT ["bash"]

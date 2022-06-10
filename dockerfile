FROM python:3.8.9-alpine3.13

#Some Tools
RUN apk add --no-cache curl bash-completion ncurses-terminfo-base ncurses-terminfo readline ncurses-libs bash nano ncurses docker git

#Google Kubernetes control cmd
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

#Expose for kubectl proxy
EXPOSE 8001

#K8 Helm
RUN wget -q "https://get.helm.sh/helm-v3.5.4-linux-amd64.tar.gz" -O helm.tar.gz && \
tar -xzf helm.tar.gz && \
rm helm.tar.gz && \
mv linux-amd64/helm /usr/local/bin/helm


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

#Cloudfare SSL Tools
RUN curl -L https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssl_1.5.0_linux_amd64 -o /usr/local/bin/cfssl && \
    curl -L https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssljson_1.5.0_linux_amd64 -o /usr/local/bin/cfssljson && \
    chmod +x /usr/local/bin/cfssl && \
    chmod +x /usr/local/bin/cfssljson

#Syntax highlighting
RUN git clone https://github.com/scopatz/nanorc.git ~/.nano && \
    echo "include ~/.nano/*.nanorc" >> ~/.nanorc && \
    rm ~/.nano/hcl.nanorc && rm /root/.nano/prolog.nanorc #These cause errors-remove them

#Azure CLI
WORKDIR azure-cli

ENV AZ_CLI_VERSION=2.31.0
#Download the version we want!

#RUN wget -q "https://codeload.github.com/Azure/azure-cli/tar.gz/azure-cli-vm-${AZ_CLI_VERSION}" -O azcli.tar.gz && \
RUN wget -q "https://github.com/Azure/azure-cli/archive/azure-cli-${AZ_CLI_VERSION}.tar.gz" -O azcli.tar.gz && \
    tar -xzf azcli.tar.gz && ls -l

RUN cp azure-cli-azure-cli-${AZ_CLI_VERSION}/** /azure-cli/ -r && \
    rm azcli.tar.gz

RUN apk add --no-cache bash openssh ca-certificates jq curl openssl perl git zip \
 && apk add --no-cache --virtual .build-deps gcc make openssl-dev libffi-dev musl-dev linux-headers \
 && apk add --no-cache libintl icu-libs libc6-compat \
 && apk add --no-cache bash-completion \
 && update-ca-certificates

ARG JP_VERSION="0.1.3"

RUN curl -L https://github.com/jmespath/jp/releases/download/${JP_VERSION}/jp-linux-amd64 -o /usr/local/bin/jp \
 && chmod +x /usr/local/bin/jp \
 && pip install --no-cache-dir --upgrade jmespath-terminal

# 1. Build packages and store in tmp dir
# 2. Install the cli and the other command modules that weren't included
RUN ./scripts/install_full.sh \
 && cat /azure-cli/az.completion > ~/.bashrc \
 && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
    )" \
 && apk add --virtual .rundeps $runDeps

# Remove CLI source code from the final image and normalize line endings.
RUN rm -rf ./azure-cli && \
    dos2unix /root/.bashrc /usr/local/bin/az

# Tab completion
#RUN cat  /azure-cli/az.completion >> ~/.bashrc
#RUN echo -e "\n" >> ~/.bashrc
RUN echo -e "source <(kubectl completion bash)" >> ~/.bashrc
RUN echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc
RUN echo "alias k=kubectl" >> ~/.bashrc

#Azure kubelogin
RUN curl -L https://github.com/Azure/kubelogin/releases/download/v0.0.13/kubelogin-linux-amd64.zip -o /tmp/kubelogin.zip && \
    unzip /tmp/kubelogin.zip -d /tmp/ && \
    mv /tmp/bin/linux_amd64/kubelogin /usr/local/bin/kubelogin && \
    chmod +X /usr/local/bin/kubelogin
    
# Kube-ps1 - order so we can change themes without pulling kubeps1 every build
RUN curl -L https://github.com/jonmosco/kube-ps1/archive/0.6.0.tar.gz | tar xz  && \
    cd ./kube-ps1-0.6.0 && \
    mkdir -p ~/kube-ps1 && \ 
    mv kube-ps1.sh ~/kube-ps1/ && \
    rm -fr ./kube-ps1-0.6.0
COPY kubeps1.sh /root/kube-ps1/
RUN chmod +x ~/kube-ps1/*.sh && \
    echo "source ~/kube-ps1/kube-ps1.sh" >> ~/.bashrc && \
    echo "source ~/kube-ps1/kubeps1.sh" >> ~/.bashrc && \
    echo "PROMPT_COMMAND=\"my_kube_ps1\"" >> ~/.bashrc

#tools
COPY tools/ /tools/
ENV KUBE_EDITOR nano

WORKDIR /

ENTRYPOINT ["bash"]

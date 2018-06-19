FROM python:3.6.4-alpine3.7

#Some Tools
RUN apk add --no-cache curl ncurses-terminfo-base ncurses-terminfo readline ncurses-libs bash nano ncurses

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


#Azure CLI
WORKDIR azure-cli

ENV JP_VERSION="0.1.3"

#Download the version we want!
RUN wget -q "https://github.com/Azure/azure-cli/archive/azure-cli-2.0.37.tar.gz" -O azcli.tar.gz && \
    tar -xzf azcli.tar.gz && \
    cp azure-cli-azure-cli-2.0.37/** /azure-cli/ -r && \
    rm azcli.tar.gz

RUN apk add --no-cache bash openssh ca-certificates jq curl openssl git \
 && apk add --no-cache --virtual .build-deps gcc make openssl-dev libffi-dev musl-dev \
 && update-ca-certificates \
 && curl https://github.com/jmespath/jp/releases/download/${JP_VERSION}/jp-linux-amd64 -o /usr/local/bin/jp \
 && chmod +x /usr/local/bin/jp \
 && pip install --no-cache-dir --upgrade jmespath-terminal \
 && /bin/bash -c 'TMP_PKG_DIR=$(mktemp -d); \
    for d in src/azure-cli src/azure-cli-core src/azure-cli-nspkg src/azure-cli-command_modules-nspkg src/command_modules/azure-cli-*/; \
    do cd $d; echo $d; python setup.py bdist_wheel -d $TMP_PKG_DIR; cd -; \
    done; \
    [ -d privates ] && cp privates/*.whl $TMP_PKG_DIR; \
    all_modules=`find $TMP_PKG_DIR -name "*.whl"`; \
    pip install --no-cache-dir $all_modules; \
    pip install --no-cache-dir --force-reinstall --upgrade azure-nspkg azure-mgmt-nspkg;' \
 && cat /azure-cli/az.completion > ~/.bashrc \
 && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
    )" \
 && apk add --virtual .rundeps $runDeps \
 && apk del .build-deps

RUN apk add --no-cache git

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

# Tab completion
RUN echo "" >> ~/.bashrc
RUN echo "source <(kubectl completion bash)" >> ~/.bashrc
RUN cat  /azure-cli/az.completion >> ~/.bashrc
#RUN echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc

WORKDIR /

ENTRYPOINT ["bash"]

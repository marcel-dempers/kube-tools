FROM python:3.6.4-alpine3.7

#Some Tools
RUN apk add --no-cache curl bash-completion ncurses-terminfo-base ncurses-terminfo readline ncurses-libs bash nano ncurses docker git

#Google Kubernetes control cmd
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

#Expose for kubectl proxy
EXPOSE 8001

#K8 Helm
RUN wget -q "https://storage.googleapis.com/kubernetes-helm/helm-v2.14.0-linux-amd64.tar.gz" -O helm.tar.gz && \
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

#Cloudfare SSL Tools
RUN curl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl && \
    curl https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson && \
    chmod +x /usr/local/bin/cfssl && \
    chmod +x /usr/local/bin/cfssljson

#Syntax highlighting
RUN git clone https://github.com/scopatz/nanorc.git ~/.nano && \
    echo "include ~/.nano/*.nanorc" >> ~/.nanorc && \
    rm ~/.nano/hcl.nanorc && rm /root/.nano/prolog.nanorc #These cause errors-remove them


#Azure CLI
WORKDIR azure-cli

ENV AZ_CLI_VERSION=2.0.76
#Download the version we want!

#RUN wget -q "https://codeload.github.com/Azure/azure-cli/tar.gz/azure-cli-vm-${AZ_CLI_VERSION}" -O azcli.tar.gz && \
RUN wget -q "https://github.com/Azure/azure-cli/archive/azure-cli-${AZ_CLI_VERSION}.tar.gz" -O azcli.tar.gz && \
    tar -xzf azcli.tar.gz && ls -l

RUN cp azure-cli-azure-cli-${AZ_CLI_VERSION}/** /azure-cli/ -r && \
    rm azcli.tar.gz

RUN apk add --no-cache bash openssh ca-certificates jq curl openssl git zip \
 && apk add --no-cache --virtual .build-deps gcc make openssl-dev libffi-dev musl-dev linux-headers \
 && update-ca-certificates

 ARG JP_VERSION="0.1.3"

RUN curl -L https://github.com/jmespath/jp/releases/download/${JP_VERSION}/jp-linux-amd64 -o /usr/local/bin/jp \
 && chmod +x /usr/local/bin/jp \
 && pip install --no-cache-dir --upgrade jmespath-terminal

 # 1. Build packages and store in tmp dir
# 2. Install the cli and the other command modules that weren't included
# 3. Temporary fix - install azure-nspkg to remove import of pkg_resources in azure/__init__.py (to improve performance)
RUN /bin/bash -c 'TMP_PKG_DIR=$(mktemp -d); \
    for d in src/azure-cli src/azure-cli-telemetry src/azure-cli-core src/azure-cli-nspkg src/azure-cli-command_modules-nspkg src/command_modules/azure-cli-*/; \
    do cd $d; echo $d; python setup.py bdist_wheel -d $TMP_PKG_DIR; cd -; \
    done; \
    [ -d privates ] && cp privates/*.whl $TMP_PKG_DIR; \
    all_modules=`find $TMP_PKG_DIR -name "*.whl"`; \
    pip install --no-cache-dir $all_modules; \
    pip install --no-cache-dir --force-reinstall --upgrade azure-nspkg azure-mgmt-nspkg; \
    pip install --no-cache-dir --force-reinstall urllib3==1.24.2;' \
 && cat /azure-cli/az.completion > ~/.bashrc \
 && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
    )" \
 && apk add --virtual .rundeps $runDeps

RUN rm -rf ./azure-cli && \
    dos2unix /root/.bashrc /usr/local/bin/az
# RUN apk add --no-cache bash openssh ca-certificates jq curl openssl git \
#  && apk add --no-cache --virtual .build-deps gcc make openssl-dev libffi-dev musl-dev \
#  && update-ca-certificates \
#  && curl https://github.com/jmespath/jp/releases/download/${JP_VERSION}/jp-linux-amd64 -o /usr/local/bin/jp \
#  && chmod +x /usr/local/bin/jp \
#  && pip install --no-cache-dir --upgrade jmespath-terminal \
#  && /bin/bash -c 'TMP_PKG_DIR=$(mktemp -d); \
#     for d in src/azure-cli src/azure-cli-core src/azure-cli-nspkg src/azure-cli-command_modules-nspkg src/command_modules/azure-cli-*/; \
#     do cd $d; echo $d; python setup.py bdist_wheel -d $TMP_PKG_DIR; cd -; \
#     done; \
#     [ -d privates ] && cp privates/*.whl $TMP_PKG_DIR; \
#     all_modules=`find $TMP_PKG_DIR -name "*.whl"`; \
#     pip install --no-cache-dir $all_modules; \
#     pip install --no-cache-dir --force-reinstall --upgrade azure-nspkg azure-mgmt-nspkg;' \
#  && cat /azure-cli/az.completion > ~/.bashrc \
#  && runDeps="$( \
#     scanelf --needed --nobanner --recursive /usr/local \
#         | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
#         | sort -u \
#         | xargs -r apk info --installed \
#         | sort -u \
#     )" \
#  && apk add --virtual .rundeps $runDeps \
#  && apk del .build-deps


# Tab completion
#RUN cat  /azure-cli/az.completion >> ~/.bashrc
#RUN echo -e "\n" >> ~/.bashrc
RUN echo -e "source <(kubectl completion bash)" >> ~/.bashrc
RUN echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc
RUN echo "alias k=kubectl" >> ~/.bashrc

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

WORKDIR /

ENTRYPOINT ["bash"]

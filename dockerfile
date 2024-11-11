FROM python:3.10-alpine

#########################################################
# Configuration
#########################################################

# Commented out version will be skipped at build
ARG TERRAFORM_VERSION="1.9.8"       # Terraform version
ARG HELM_VERSION="3.14.4"           # Helm version
ARG K9S_VERSION="0.32.5"            # K9S version
ARG KTX_VERSION="0.4.0"             # Kubens \ Kubectx version
ARG CLOUDFLARE_VERSION="1.5.0"      # Cloudflare version
ARG DOCTL_VERSION="1.93.1"          # DigitalOcean CLI version
ARG GH_CLI_VERSION="2.34.0"         # Github CLI version
ARG JP_VERSION="0.1.3"              # JP version
ARG AZ_CLI_VERSION="2.61.0"         # Azure CLI version
ARG AZ_KUBELOGIN_VERSION="0.0.13"   # Azure CLI version

# Enable / disable additional features
ARG CLEAN_LINE_ENDINGS=true       # Cleans line endings for compatibility
ARG SYNTAX_HIGHLIGHTING=true      # Enable syntax highlighting
ARG CREATE_ALIASES=true           # Create aliasses
ARG AUTO_MERGE_CONFIGS=true       # Auto merge kube kubeconfigs
ARG CMD_COMPLETION=true           # Bash completion
ARG THEMING=true                  # Theming

#########################################################
# Some Tools
#########################################################

RUN apk add --no-cache \
        curl \
        bash-completion \
        ncurses-terminfo-base \
        ncurses-terminfo \
        readline \
        ncurses-libs \
        bash \
        nano \
        ncurses \
        docker \
        git \
        dos2unix \
        wget \
        unzip \
        tar

#########################################################
# JP
#########################################################

RUN if [[ -n "$JP_VERSION" ]] ; then \
        curl -L https://github.com/jmespath/jp/releases/download/${JP_VERSION}/jp-linux-amd64 -o /usr/local/bin/jp \
        && chmod +x /usr/local/bin/jp \
    ; else : echo "JP skipped" ; fi

#########################################################
# Kubectl
#########################################################

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

#Expose for kubectl proxy
EXPOSE 8001


#########################################################
# Kubens \ Kubectx
#########################################################

RUN if [[ -n "$KTX_VERSION" ]] ; then \
    curl -L https://github.com/ahmetb/kubectx/archive/v${KTX_VERSION}.tar.gz | tar xz \
        && cd ./kubectx-${KTX_VERSION} \
        && mv kubectx kubens utils.bash /usr/local/bin/ \
        && chmod +x /usr/local/bin/kubectx \
        && chmod +x /usr/local/bin/kubens \
        && cat completion/kubectx.bash >> ~/.bashrc \
        && cat completion/kubens.bash >> ~/.bashrc \
        && cd ../ \
        && rm -fr ./kubectx-${KTX_VERSION} \
   ; else : echo "Kubens / Kubectx skipped" ; fi


#########################################################
# Cloudflare SSL Tools
#########################################################

RUN if [[ -n "$CLOUDFLARE_VERSION" ]] ; then \
        curl -L https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssl_${CLOUDFLARE_VERSION}_linux_amd64 -o /usr/local/bin/cfssl \
        && curl -L https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssljson_${CLOUDFLARE_VERSION}_linux_amd64 -o /usr/local/bin/cfssljson \
        && chmod +x /usr/local/bin/cfssl \
        && chmod +x /usr/local/bin/cfssljson \
    ; else : echo "Cloudflare skipped" ; fi


#########################################################
# Syntax highlighting
#########################################################

RUN if [[ -n "$SYNTAX_HIGHLIGHTING" ]] ; then \
        git clone https://github.com/scopatz/nanorc.git ~/.nano \
        && echo "include ~/.nano/*.nanorc" >> ~/.nanorc \
        && rm ~/.nano/hcl.nanorc && rm /root/.nano/prolog.nanorc \
    ; else : echo "Syntax highlighting skipped" ; fi


#########################################################
# Azure CLI
#########################################################

WORKDIR /root/azure-cli
ENV AZ_CLI_VERSION=$AZ_CLI_VERSION

# Installing pre-requisites
RUN if [[ -n "$AZ_CLI_VERSION" ]] ; then \
        apk add --no-cache bash openssh ca-certificates jq curl openssl perl git zip \
        && apk add --no-cache --virtual .build-deps gcc make openssl-dev libffi-dev musl-dev linux-headers \
        && apk add --no-cache libintl icu-libs libc6-compat \
        && apk add --no-cache bash-completion \
        && update-ca-certificates \
    ; else : echo "Azure CLI skipped" ; fi

#Azure kubelogin
RUN if [[ -n "$AZ_CLI_VERSION" ]] ; then \
        curl -L https://github.com/Azure/kubelogin/releases/download/v${AZ_KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip -o /tmp/kubelogin.zip \
        && unzip /tmp/kubelogin.zip -d /tmp/ \
        && mv /tmp/bin/linux_amd64/kubelogin /usr/local/bin/kubelogin \
        && chmod +X /usr/local/bin/kubelogin \
    ; else : echo "Azure kubelogin skipped" ; fi


RUN if [[ -n "$AZ_CLI_VERSION" ]] ; then \
        wget -q "https://github.com/Azure/azure-cli/archive/azure-cli-${AZ_CLI_VERSION}.tar.gz" -O azcli.tar.gz \
        && tar -xzf azcli.tar.gz && ls -l \
        && cp azure-cli-azure-cli-${AZ_CLI_VERSION}/** /root/azure-cli/ -r \
        && rm azcli.tar.gz \
    ; else : echo "Azure CLI skipped" ; fi


# 1. Build packages and store in tmp dir
# 2. Install the cli and the other command modules that weren't included
RUN if [[ -n "$AZ_CLI_VERSION" ]] ; then \
        ./scripts/install_full.sh \
        && cat /root/azure-cli/az.completion > ~/.bashrc \
        && runDeps="$( \
            scanelf --needed --nobanner --recursive /usr/local \
                | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                | sort -u \
                | xargs -r apk info --installed \
                | sort -u \
            )" \
        && apk add --virtual .rundeps $runDeps \
    ; else : echo "Azure CLI skipped" ; fi


# Remove CLI source code from the final image and normalize line endings.
RUN if [[ -n "$AZ_CLI_VERSION" ]] ; then \
        rm -rf ./azure-cli \
        && if [[ -n "$CLEAN_LINE_ENDINGS" ]] ; then \
           dos2unix /root/.bashrc /usr/local/bin/az \
        ; else : echo "Clean line endings skipped" ; fi \
    ; else : echo "Azure CLI skipped" ; fi

ENV AZ_INSTALLER=DOCKER


#########################################################
# Tab completion
#########################################################

# Azure completion
RUN if [[ -n "$AZ_CLI_VERSION" ]] ; then \
        cat  /root/azure-cli/az.completion >> ~/.bashrc \
        && echo -e "\n" >> ~/.bashrc \
    ; else : echo "Azure completion skipped" ; fi


# Kubectl completion
RUN if [[ -n "$CMD_COMPLETION" ]] ; then \
        echo -e "source <(kubectl completion bash)" >> ~/.bashrc \
        && echo "" >> /etc/profile.d/bash_completion.sh \
        && echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc \
    ; else : echo "Kubectl completion skipped" ; fi


#########################################################
# Theming
#########################################################

# Kube-ps1 - order so we can change themes without pulling kubeps1 every build
RUN if [[ -n "$THEMING" ]] ; then \
        curl -L https://github.com/jonmosco/kube-ps1/archive/0.6.0.tar.gz | tar xz \
        && cd ./kube-ps1-0.6.0 \
        && mkdir -p ~/kube-ps1 \
        && mv kube-ps1.sh ~/kube-ps1/ \
        && rm -fr ./kube-ps1-0.6.0 \
    ; else : echo "" > kubeps1.sh ; fi


# When skipped an empty kubeps1.sh is outputted by previous step
COPY kubeps1.sh /root/kube-ps1/
RUN if [[ -n "$THEMING" ]] ; then \
        chmod +x ~/kube-ps1/*.sh \
        && echo "source ~/kube-ps1/kube-ps1.sh" >> ~/.bashrc \
        && echo "source ~/kube-ps1/kubeps1.sh" >> ~/.bashrc \
        && echo "PROMPT_COMMAND=\"my_kube_ps1\"" >> ~/.bashrc \
        && if [[ -n "$CLEAN_LINE_ENDINGS" ]] ; then \
           dos2unix /root/kube-ps1/kubeps1.sh \
        ; else : echo "Clean line endings skipped" ; fi \
    ; else : echo "Azure CLI skipped" ; fi


#########################################################
# Merge kubeconfig
#########################################################

COPY scripts/merge-kubeconfigs.sh /root/.scripts/merge-kubeconfigs.sh

RUN if [[ -n "$AUTO_MERGE_CONFIGS" ]] ; then \
        chmod +x /root/.scripts/merge-kubeconfigs.sh \
        && if [[ -n "$CLEAN_LINE_ENDINGS" ]] ; then \
               dos2unix /root/.scripts/merge-kubeconfigs.sh \
           ;  else : echo "Clean line endings skipped" ; fi \
    ; else : echo "Merge config skipped" ; fi


#########################################################
# K8 Helm
#########################################################

RUN if [[ -n "$HELM_VERSION" ]] ; then \
        wget -q "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" -O helm.tar.gz && \
        tar -xzf helm.tar.gz && \
        rm helm.tar.gz && \
        mv linux-amd64/helm /usr/local/bin/helm \
    ; else : echo "Helm skipped" ; fi


#########################################################
# Terraform
#########################################################

RUN if [[ -n "$TERRAFORM_VERSION" ]] ; then \
        wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
            && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
            && mv terraform /usr/local/bin/ \
            && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
        ; \
    else : echo "Terraform skipped" ; fi


#########################################################
# DigitalOcean CLI
#########################################################

RUN if [[ -n "$DOCTL_VERSION" ]] ; then \
        curl -sL https://github.com/digitalocean/doctl/releases/download/v1.93.1/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz | tar -xzv \
            && mv doctl /usr/local/bin/ \
    ; else : echo "DigitalOcean CLI skipped" ; fi

#########################################################
# Github CLI
#########################################################

RUN if [[ -n "$GH_CLI_VERSION" ]] ; then \
        wget https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/gh_${GH_CLI_VERSION}_linux_amd64.tar.gz \
            && tar -zxvf gh_${GH_CLI_VERSION}_linux_amd64.tar.gz \
            && mv gh_${GH_CLI_VERSION}_linux_amd64/bin/gh /usr/local/bin/ \
            && rm -rf gh_${GH_CLI_VERSION}_linux_amd64.tar.gz gh_${GH_CLI_VERSION}_linux_amd64 \
    ; else : echo "Github CLI skipped" ; fi

#########################################################
# K9S
#########################################################

RUN if [[ -n "$K9S_VERSION" ]] ; then \
        wget https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_amd64.tar.gz \
            && tar -zxvf k9s_Linux_amd64.tar.gz \
            && mv k9s /usr/local/bin/ \
            && rm k9s_Linux_amd64.tar.gz \
    ; else : echo "K9S skipped" ; fi


#########################################################
# Aliases
#########################################################

RUN if [[ -n "$CREATE_ALIASES" ]] ; then \
           echo "alias k=kubectl" >> ~/.bashrc \
        && echo "alias ktx=kubectx" >> ~/.bashrc \
        && echo "alias kns=kubens" >> ~/.bashrc \
        && echo "alias kubedev=\"export KUBECONFIG=~/.kube/dev-config\""  >> ~/.bashrc \
        && echo "alias kubeprod=\"export KUBECONFIG=~/.kube/production-config\""  >> ~/.bashrc \
        && echo "alias tf=terraform"  >> ~/.bashrc \
    ; else : echo "Clean line endings skipped" ; fi


#########################################################
# Startup script
#########################################################

COPY scripts/startup.sh /root/.scripts/startup.sh
RUN chmod +x /root/.scripts/startup.sh \
    && if [[ -n "$CLEAN_LINE_ENDINGS" ]] ; then \
           dos2unix /root/.scripts/startup.sh \
       ;  else : echo "Clean line endings skipped" ; fi


#########################################################
# Running container
#########################################################

ENV KUBE_EDITOR=nano
WORKDIR /

ENTRYPOINT ["bash", "-c"]
CMD ["/root/.scripts/startup.sh && bash"]
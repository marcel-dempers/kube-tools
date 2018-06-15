
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

my_kube_ps1() {  
    source <(kubectl completion bash)
    KUBE_PS1_SYMBOL_COLOR=blue
    KUBE_PS1_CTX_COLOR="${KUBE_PS1_CTX_COLOR-48;5;4m}"
    KUBE_PS1_NS_COLOR="${KUBE_PS1_NS_COLOR-48;5;4m}"
    KUBE_PS1_BG_COLOR=''
    KUBE_PS1_SYMBOL="⎈"
    KUBE_PS1_USER_COLOR="${KUBE_PS1_USER_COLOR-48;5;4m}"
    KUBE_PS1_FOLDER_COLOR="${KUBE_PS1_FOLDER_COLOR-48;5;242m}"
    KUBE_PS1_GIT_BRANCH_COLOR="${KUBE_PS1_GIT_BRANCH_COLOR-0;33;49m}"
    source ~/kube-ps1/kube-ps1.sh
    PS1='\[\e[${KUBE_PS1_USER_COLOR}\][\u@\h]\[\e[0;0m\]\[\e[${KUBE_PS1_FOLDER_COLOR}\][\W]\[\e[0;0m\] \[\e[${KUBE_PS1_GIT_BRANCH_COLOR}\]$(parse_git_branch)\[\e[0;0m\] $(kube_ps1)\n'
    PS1+='  |--> '
    export PS1
}

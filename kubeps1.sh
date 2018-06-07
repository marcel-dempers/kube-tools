
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

my_kube_ps1() {  
    source <(kubectl completion bash)
    KUBE_PS1_SYMBOL_COLOR=blue
    KUBE_PS1_CTX_COLOR=red
    KUBE_PS1_NS_COLOR=green
    KUBE_PS1_BG_COLOR=''
    KUBE_PS1_SYMBOL="⎈"
    source ~/kube-ps1/kube-ps1.sh
    PS1='\[\e[0;30;41m\][\u@\h]\[\e[0;0m\]\[\e[0;37;100m\][\W]\[\e[0;0m\] \[\e[0;33;49m\]$(parse_git_branch)\[\e[0;0m\] $(kube_ps1)\n'
    PS1+='  |--> '
    export PS1
}

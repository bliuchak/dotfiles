export LANG=en_US.UTF-8
export EDITOR='nvim'
export PATH=$PATH:$HOME/go/bin

ZSH_THEME="robbyrussell"
plugins=(git kubectl)

source ~/.oh-my-zsh/oh-my-zsh.sh
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias ls="exa --icons -F -H --group-directories-first --git -1"

eval "$(starship init zsh)"

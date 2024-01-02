export LANG=en_US.UTF-8
export EDITOR='nvim'
export PATH=$PATH:$HOME/go/bin
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git kubectl)

source $ZSH/oh-my-zsh.sh

if [[ "$OSTYPE" == "darwin"* ]]; then
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
 [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  alias ls="exa --icons -F -H --group-directories-first --git -1"
  eval "$(starship init zsh)"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  wal -i ~/Downloads/4.jpg > /dev/null

  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh

  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

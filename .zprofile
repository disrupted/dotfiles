#!/usr/bin/env zsh

# Login shell environment
export PATH="/opt/homebrew/bin:$PATH"
if type brew &>/dev/null; then
    export HOMEBREW_HOME=$(brew --prefix)
    export HOMEBREW_CASK_OPTS=--no-quarantine
    export PATH="$HOMEBREW_HOME/bin:$PATH"
    export PATH="$HOMEBREW_HOME/sbin:$PATH"
    export SHELL="$HOMEBREW_HOME/bin/zsh"

    FPATH="$HOMEBREW_HOME/share/zsh/site-functions:$FPATH"

    export PATH="$HOMEBREW_HOME/opt/llvm/bin:$PATH"
    export PATH="$HOMEBREW_HOME/opt/openjdk/bin:$PATH"

    export LDFLAGS="-L$HOMEBREW_HOME/opt/zlib/lib -L$HOMEBREW_HOME/opt/bzip2/lib -L$HOMEBREW_HOME/opt/llvm/lib -Wl,-rpath,$HOMEBREW_HOME/opt/llvm/lib -L$HOMEBREW_HOME/opt/freetds/lib -L$HOMEBREW_HOME/opt/openssl@3/lib"
    export CFLAGS="-I$HOMEBREW_HOME/opt/freetds/include"
    export CPPFLAGS="-I$HOMEBREW_HOME/opt/zlib/include -I$HOMEBREW_HOME/opt/bzip2/include -I$HOMEBREW_HOME/opt/llvm/include -I$HOMEBREW_HOME/opt/openssl@3/include"
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} $HOMEBREW_HOME/opt/zlib/lib/pkgconfig"
    export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:/opt/homebrew/lib"
fi

export PATH="$HOME/.local/bin:$PATH"
if [[ -r "$HOME/.cargo/env" ]]; then
    . "$HOME/.cargo/env"
fi
export PATH="$HOME/.cargo/bin:$PATH"
[[ -v $GOPATH ]] && export PATH="$GOPATH/bin:$PATH"
export PATH="$HOME/.deno/bin:$PATH"
export PATH="$HOME/.luarocks/bin:$PATH"

export TERMINAL='kitty'
export EDITOR='nvim'
export VISUAL=$EDITOR
export PAGER='less'
export LESS='-F -g -i -M -R -S -w -X -z-4 -~ --mouse'
export LESS_TERMCAP_mb=$'\E[6m'
export LESS_TERMCAP_md=$'\E[34m'
export LESS_TERMCAP_us=$'\E[4;32m'
export LESS_TERMCAP_so=$'\E[0m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export MANPAGER='nvim +Man!'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'
export PROMPT_EOL_MARK=''
export GPG_TTY=$(tty)
export QUOTING_STYLE=literal

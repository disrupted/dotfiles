#!/usr/bin/env zsh
# disrupted zshrc

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

#####################
# THEME             #
#####################
zinit ice depth=1; zinit light romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
# zinit light sindresorhus/pure

#####################
# PLUGINS           #
#####################
# SSH-AGENT
zinit light bobsoppe/zsh-ssh-agent
# AUTOSUGGESTIONS, TRIGGER PRECMD HOOK UPON LOAD
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
zinit ice wait'0a' lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions
# Then load url-quote-magic and bracketed-paste-magic as above
autoload -U url-quote-magic bracketed-paste-magic
zle -N self-insert url-quote-magic
zle -N bracketed-paste bracketed-paste-magic
# Now the fix, setup these two hooks:
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}
pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# and finally, make sure zsh-autosuggestions does not interfere with it:
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(expand-or-complete bracketed-paste accept-line push-line-or-edit)

# ENHANCD
zinit ice wait'0b' lucid
zinit light b4b4r07/enhancd
export ENHANCD_FILTER=fzf:fzy:peco

# HISTORY SUBSTRING SEARCHING
zinit ice wait'0b' lucid atload'!export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="bg=green,fg=black,bold"'
zinit light zsh-users/zsh-history-substring-search
setopt HIST_IGNORE_ALL_DUPS
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# TAB COMPLETIONS
zinit light-mode for \
    blockf \
        zsh-users/zsh-completions \
    as'program' atclone'rm -f ^(rgg|agv)' \
        lilydjwg/search-and-view \
    src'etc/git-extras-completion.zsh' \
        tj/git-extras
zinit wait'1' lucid for \
    OMZ::lib/clipboard.zsh \
    OMZ::lib/git.zsh \
    OMZ::plugins/systemd/systemd.plugin.zsh

zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select=2
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*:descriptions' format '-- %d --'
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:complete:*:options' sort false
zstyle ':fzf-tab:*' query-string prefix first
# zstyle ':fzf-tab:complete:_zlua:*' query-string input
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --no-quotes -1 --color=always $realpath'  # disable for tmux-popup
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-pad 0 0
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:eza' file-sort modification
zstyle ':completion:*:eza' sort false

# TMUX plugin manager
zinit ice lucid wait'!0a' as'null' id-as'tpm' \
  atclone' \
    mkdir -p $HOME/.tmux/plugins; \
    ln -s $HOME/.zinit/plugins/tpm $HOME/.tmux/plugins/tpm; \
    setup_my_tmux_plugin tpm;'
zinit light tmux-plugins/tpm
# FZF TMUX HELPER SCRIPT
zinit ice lucid wait'0c' as'command' pick'bin/fzf-tmux'
zinit light junegunn/fzf
# BIND MULTIPLE WIDGETS USING FZF
zinit ice lucid wait'0c' multisrc'shell/{completion,key-bindings}.zsh' id-as'junegunn/fzf_completions' pick'/dev/null'
zinit light junegunn/fzf
# FZF-TAB
zinit ice wait'1' lucid
zinit light Aloxaf/fzf-tab
# SYNTAX HIGHLIGHTING
zinit ice wait'0c' lucid atinit'zpcompinit;zpcdreplay'
zinit light zdharma-continuum/fast-syntax-highlighting
# ZSH AUTOPAIRS
zinit ice wait'0c' lucid atinit'zpcompinit;zpcdreplay'
zinit light hlissner/zsh-autopair
# FORGIT
zinit ice wait lucid id-as'forgit' atload'alias gr=forgit::checkout::file'
zinit load 'wfxr/forgit'
# FORYADM
zinit ice wait lucid id-as'foryadm'
zinit load 'disrupted/foryadm'
# cheat.sh
zinit wait'2a' lucid \
  id-as'cht.sh' \
  as'program' \
  for https://cht.sh/:cht.sh
  # has'rlwrap' \
zinit wait'2b' lucid \
  id-as'cht-completion' \
  has'rlwrap' \
  mv'cht* -> _cht' \
  as'completion' \
  for https://cheat.sh/:zsh
# mmv renamer
zinit ice lucid wait'0' as'program' id-as'mmv' from'gh-r' \
  mv'mmv* -> mmv' pick'mmv/mmv'
zinit light 'itchyny/mmv'
# python automatic virtualenv
zinit light MichaelAquilina/zsh-autoswitch-virtualenv
# carapace completion
zinit ice as'program' id-as'carapace' from'gh-r' atload' \
  autoload -Uz compinit; \
  compinit; \
  source <(carapace _carapace);'
zinit light carapace-sh/carapace-bin
# quickenv (direnv replacement)
zinit ice lucid wait'0' as'program' id-as'quickenv' from'gh-r' \
  mv'quickenv* -> quickenv' pick'quickenv'
zinit light 'untitaker/quickenv'

#####################
# HISTORY           #
#####################
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zhistory"
HISTSIZE=290000
SAVEHIST=$HISTSIZE

#####################
# SETOPT            #
#####################
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_all_dups   # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # add commands to HISTFILE in order of execution
setopt share_history          # share command history data
setopt always_to_end          # cursor moved to the end in full completion
setopt hash_list_all          # hash everything before completion
setopt completealiases        # complete alisases
setopt always_to_end          # when completing from the middle of a word, move the cursor to the end of the word
setopt complete_in_word       # allow completion from within a word/phrase
setopt nocorrect              # spelling correction for commands
setopt list_ambiguous         # complete as much of a completion until it gets ambiguous.
setopt nolisttypes
setopt listpacked
setopt automenu
setopt interactivecomments    # recognize comments
setopt sharehistory           # global history

export QUOTING_STYLE=literal  # ls: do not wrap in single quotes
chpwd() {
  if [[ $(ls | wc -l) -ge 20 ]]; then
    # print as grid
    eza --no-quotes -G -a -F --icons --group-directories-first --git --color=always --ignore-glob=".DS_Store|__*"
  else
    # print as list and add left padding
    eza --no-quotes -1 -a -F --icons --group-directories-first --git --color=always --ignore-glob=".DS_Store|__*" | sed 's/^/  /'
  fi
}

# chpwd() { eza --no-quotes -l -a -F --icons --group-directories-first --git --color=always --no-permissions --no-user --no-filesize --time=modified | sed 's/^/  /'; }  # alternative showing last modified date for files

#####################
# VI KEYBINDINGS    #
#####################
# bindkey "^?" backward-delete-char  # enable delete key

#####################
# KEYBINDINGS       #
#####################
bindkey "^[[1;3C" forward-word     # alt+right to move forward one word
bindkey "^[[1;3D" backward-word    # alt+left to move backward one word

bindkey '^[^?' backward-kill-word  # alt+delete to backward delete word

# key[Up]="$terminfo[kcuu1]"
# key[Down]="$terminfo[kcud1]"
# bindkey "^[[A" up-line-or-local-history
# bindkey "^[[B" down-line-or-local-history
# bindkey "${key[Up]}" up-line-or-local-history
# bindkey "${key[Down]}" down-line-or-local-history

up-line-or-local-history() {
    zle set-local-history 1
    zle up-line-or-history
    zle set-local-history 0
}
zle -N up-line-or-local-history
down-line-or-local-history() {
    zle set-local-history 1
    zle down-line-or-history
    zle set-local-history 0
}
zle -N down-line-or-local-history

# Global history
bindkey "^[[1;5A" up-line-or-history    # [CTRL] + Cursor up
bindkey "^[[1;5B" down-line-or-history  # [CTRL] + Cursor down

#####################
# HOMEBREW          #
#####################
if type brew &>/dev/null; then
    export HOMEBREW_HOME=$(brew --prefix)
    export HOMEBREW_CASK_OPTS=--no-quarantine
    export PATH="$HOMEBREW_HOME/bin:$PATH"
    export PATH="$HOMEBREW_HOME/sbin:$PATH"
    export SHELL="$HOMEBREW_HOME/bin/zsh"

    # completions
    FPATH="$HOMEBREW_HOME/share/zsh/site-functions:$FPATH"

    # LLVM (C, C++)
    export PATH="$HOMEBREW_HOME/opt/llvm/bin:$PATH"

    # Java runtime
    export PATH="$HOMEBREW_HOME/opt/openjdk/bin:$PATH"

    # For compilers and pkgconfig to find zlib, bzip2, llvm (c, cpp), FreeTDS (PyMSSQL)
    export LDFLAGS="-L$HOMEBREW_HOME/opt/zlib/lib -L$HOMEBREW_HOME/opt/bzip2/lib -L$HOMEBREW_HOME/opt/llvm/lib -Wl,-rpath,$HOMEBREW_HOME/opt/llvm/lib -L$HOMEBREW_HOME/opt/freetds/lib -L$HOMEBREW_HOME/opt/openssl@3/lib"
    export CFLAGS="-I$HOMEBREW_HOME/opt/freetds/include"
    export CPPFLAGS="-I$HOMEBREW_HOME/opt/zlib/include -I$HOMEBREW_HOME/opt/bzip2/include -I$HOMEBREW_HOME/opt/llvm/include -I$HOMEBREW_HOME/opt/openssl@3/include"
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} $HOMEBREW_HOME/opt/zlib/lib/pkgconfig"
    export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:/opt/homebrew/lib"
fi

#####################
# SHELL ENVIRONMENT #
#####################
# export TERM=xterm-256color
export TERMINAL='kitty'
export EDITOR='nvim'
export VISUAL=$EDITOR
export PAGER='less'
export LESS='-F -g -i -M -R -S -w -X -z-4 -~ --mouse'
export LESS_TERMCAP_mb=$'\E[6m'     # begin blinking
export LESS_TERMCAP_md=$'\E[34m'    # begin bold
export LESS_TERMCAP_us=$'\E[4;32m'  # begin underline
export LESS_TERMCAP_so=$'\E[0m'     # begin standout-mode (info box), remove background
export LESS_TERMCAP_me=$'\E[0m'     # end mode
export LESS_TERMCAP_ue=$'\E[0m'     # end underline
export LESS_TERMCAP_se=$'\E[0m'     # end standout-mode
export MANPAGER='nvim +Man!'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'  # sane moving between words on the prompt
export PROMPT_EOL_MARK=''  # hide % at end of output
export GPG_TTY=$(tty)

# Python uv
export UV_PYTHON="3.13"

# Python pipx
export PATH="$HOME/.local/bin:$PATH"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Golang
[[ -v $GOPATH ]] && export PATH="$GOPATH/bin:$PATH"

# Mojo
export MODULAR_HOME="$HOME/.modular"
export PATH="$MODULAR_HOME/pkg/packages.modular.com_mojo/bin:$PATH"

# Deno
export PATH="$HOME/.deno/bin:$PATH"

# Lua
export PATH="$HOME/.luarocks/bin:$PATH"

#####################
# COMPLETIONS       #
#####################
# load additional completions
fpath+=~/.zfunc

#####################
# COLORING          #
#####################
autoload colors && colors

#####################
# ALIASES           #
#####################
source $HOME/.zsh_aliases
source $HOME/.zsh_aliases_private
eval "$(zoxide init --no-cmd zsh)" # cmd disabled in favor of custom zoxide function

#####################
# FANCY-CTRL-Z      #
#####################
function fg-fzf() {
  job="$(jobs | fzf -0 -1 | sed -E 's/\[(.+)\].*/\1/')" && echo '' && fg %$job
}
function fancy-ctrl-z () {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER=" fg-fzf"
    zle accept-line -w
  else
    zle push-input -w
    zle clear-screen -w
  fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

#####################
# FZF SETTINGS      #
#####################
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2>/dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS='--preview="bat --color=always --style=header {} 2>/dev/null" --preview-window=right:60%:wrap'
export FZF_ALT_C_COMMAND='fd -t d -d 1'
export FZF_ALT_C_OPTS='--preview="eza --no-quotes -1 --icons --git --git-ignore {}" --preview-window=right:60%:wrap'
bindkey '^F' fzf-file-widget
bindkey -M viins '^F' fzf-file-widget
# FZF custom OneDark theme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--no-separator
--info=hidden
--ansi
--color=fg:-1,bg:-1,border:#4B5164,hl:#d19a66
--color=fg+:#f7f7f7,bg+:#2c323d,hl+:#e5c07b
--color=info:#828997,prompt:#e06c75,pointer:#45cdff
--color=marker:#98c379,spinner:#e06c75,header:#98c379'
# FZF options for zoxide prompt (zi)
export _ZO_FZF_OPTS=$FZF_DEFAULT_OPTS'
--height=7'

#####################
# MISC              #
#####################

# Google cloud cli
if [[ -s "$HOMEBREW_HOME/Caskroom/google-cloud-sdk/latest/google-cloud-sdk" ]]; then
    source "$HOMEBREW_HOME/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
    source "$HOMEBREW_HOME/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
fi

# Node version manager
# eval "$(snm env zsh)"

# Direnv
eval "$(direnv hook zsh)"
source ~/.config/op/plugins.sh

#####################
# GIT               #
#####################
# from https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh#L31-L41
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return
    fi
  done
  echo master
}

#####################
# WORK              #
#####################
source ~/bakdata/.zshrc

export DOCKER_HOST="unix://$HOME/.config/colima/default/docker.sock" # HACK: docker-py not supporting current context https://github.com/docker/docker-py/issues/3146

zinit ice depth=1; zinit light jeffreytse/zsh-vi-mode

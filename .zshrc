#!/usr/bin/env zsh
# disrupted zshrc

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zinit-zsh/z-a-rust \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-bin-gem-node

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
zinit ice wait'0b' lucid atload'bindkey "$terminfo[kcuu1]" history-substring-search-up; bindkey "$terminfo[kcud1]" history-substring-search-down'
zinit light zsh-users/zsh-history-substring-search
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
    atclone'dircolors -b LS_COLORS > c.zsh' atpull'%atclone' pick'c.zsh' \
        trapd00r/LS_COLORS \
    src'etc/git-extras-completion.zsh' \
        tj/git-extras
zinit wait'1' lucid for \
    OMZ::lib/clipboard.zsh \
    OMZ::lib/git.zsh \
    OMZ::plugins/systemd/systemd.plugin.zsh \
    OMZ::plugins/kubectl/kubectl.plugin.zsh \
    OMZ::plugins/aws/aws.plugin.zsh

if whence dircolors >/dev/null; then
  eval "$(dircolors -b)"
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
  alias ls='ls --color'
else
  export CLICOLOR=1
  zstyle ':completion:*' list-colors ''
fi
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select=2
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*:descriptions' format '-- %d --'
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:complete:*:options' sort false
zstyle ':fzf-tab:complete:_zlua:*' query-string input
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'  # disable for tmux-popup
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-pad 0 0
zstyle ':completion:*:git-checkout:*' sort false

# TMUX
zinit ice as'program' id-as'tmux' atpull'%atclone' make \
  atclone'ln -fs $HOME/.zinit/plugins/tmux/tmux /usr/local/bin/tmux; ./autogen.sh; ./configure'
zinit light tmux/tmux
# TMUX plugin manager
zinit ice lucid wait'!0a' as'null' id-as'tpm' \
  atclone' \
    mkdir -p $HOME/.tmux/plugins; \
    ln -s $HOME/.zinit/plugins/tpm $HOME/.tmux/plugins/tpm; \
    setup_my_tmux_plugin tpm;'
zinit light tmux-plugins/tpm
# FZF
zinit ice lucid wait'0b' from'gh-r' as'program'
zinit light junegunn/fzf
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
zinit light zdharma/fast-syntax-highlighting
# EXA
zinit ice wait'2' lucid id-as'exa' from'gh-r' as'program' mv'bin/exa* -> exa' \
    cp'completions/exa.zsh -> _exa' \
  atload"
        alias l='exa --sort=changed --icons -la --git --git-ignore --ignore-glob=\".DS_Store|__MACOSX|__pycache__\"'
        alias la='exa --group-directories-first --icons -la'
        alias ll='exa --group-directories-first --icons -la --color-scale --time-style=long-iso --git --git-ignore --ignore-glob=\".git|.DS_Store|__MACOSX|__pycache__\" -T -L2'
        alias ll3='exa --group-directories-first --icons -la --git --git-ignore --ignore-glob=\".git|.DS_Store|__MACOSX\" -T -L3'
        alias ll4='exa --group-directories-first --icons -la --git --git-ignore --ignore-glob=\".git|.DS_Store|__MACOSX\" -T -L4'
        alias tree='exa --group-directories-first -T --icons'
    "
zinit light ogham/exa
zinit ice wait blockf atpull'zinit creinstall -q .'
# ZSH DIFF SO FANCY
zinit ice wait'2' lucid as'program' pick'bin/git-dsf'
zinit light zdharma/zsh-diff-so-fancy
# BAT
zinit ice as'program' id-as'bat' from'gh-r' mv'bat* -> bat' cp'bat/autocomplete/bat.zsh -> _bat' pick'bat/bat' atload'alias cat=bat'
zinit light sharkdp/bat
# RIPGREP
zinit ice from'gh-r' as'program' id-as'rg' mv'ripgrep* -> rg' cp'rg/complete/_rg -> _rg' pick'rg/rg'
zinit light BurntSushi/ripgrep
# neovim
zinit wait'0' lucid \
  id-as'nvim' from'gh-r' ver'nightly' as'program' pick'nvim*/bin/nvim' \
  atclone'echo "" > ._zinit/is_release' \
  atpull'%atclone' \
  run-atpull \
  atload'alias v=nvim' \
  light-mode for @neovim/neovim
# DELTA
zinit wait'1' lucid \
  as'program' id-as'delta' from'gh-r' mv'delta* -> delta' pick'delta/delta' \
  light-mode for @dandavison/delta
zinit ice wait'1' lucid as'delta-completion' has'delta' mv'completion.zsh -> _delta'
zinit snippet https://github.com/dandavison/delta/blob/master/etc/completion/completion.zsh
# FORGIT
zinit ice wait lucid id-as'forgit' atload'alias gr=forgit::checkout::file'
zinit load 'wfxr/forgit'
# LAZYGIT
zinit ice lucid wait'0' as'program' from'gh-r' mv'lazygit* -> lazygit' atload'alias lg=lazygit'
zinit light 'jesseduffield/lazygit'
# LAZYDOCKER
zinit ice lucid wait'0' as'program' from'gh-r' mv'lazydocker* -> lazydocker' atload'alias ld=lazydocker'
zinit light 'jesseduffield/lazydocker'
# RANGER
zinit ice depth'1' as'program' pick'ranger.py' atload'alias ranger=ranger.py'
zinit light ranger/ranger
# FD
zinit ice as'program' id-as'fd' from'gh-r' mv'fd* -> fd' cp'fd/autocomplete/_fd -> _fd' pick'fd/fd'
zinit light sharkdp/fd
# GH-CLI
zinit ice lucid wait'0' as'program' id-as'gh' from'gh-r' has'git' \
  atclone'./gh completion -s zsh > _gh' atpull'%atclone' mv'**/bin/gh -> gh'
zinit light cli/cli
# tldr (rust implementation tealdeer)
# zinit wait'1' lucid \
#   from'gh-r' as'program' id-as'tldr' mv'tldr* -> tldr' pick'tldr' \
#   light-mode for @dbrgn/tealdeer
# zinit ice wait'1' lucid as'tldr-completion' has'tldr' mv'zsh_tealdeer -> _tldr'
# zinit snippet https://github.com/dbrgn/tealdeer/blob/master/zsh_tealdeer
# navi for cheat sheets including tldr & cheat.sh
zinit wait'2' lucid \
  id-as'navi' \
  from'gh-r' \
  pick'navi' \
  as'program' \
  atload"eval '$(navi widget zsh)';" \
  for @denisidoro/navi
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
# cheat
zinit wait'2a' lucid \
  id-as'cheat' \
  from'gh-r' \
  mv'cheat* -> cheat' \
  pick'cheat' \
  as'program' \
  for @cheat/cheat
zinit wait'2b' lucid \
  id-as'cheat-completion' \
  mv'cheat* -> _cheat' \
  as'completion' \
  for https://github.com/cheat/cheat/blob/master/scripts/cheat.zsh
# procs (modern replacement for ps written in rust)
zinit wait'1' lucid \
  from'gh-r' as'program' \
  atload'alias ps=procs' \
  light-mode for @dalance/procs

# prettyping
zinit ice wait lucid as'program' mv'prettyping* -> prettyping' \
    atload"alias ping='prettyping --nolegend'"
zinit light denilsonsa/prettyping
# sad
zinit ice lucid wait'0' as'program' from'gh-r' id-as'sad' mv'sad* -> sad'
zinit light 'ms-jpq/sad'
# bottom system monitor
zinit ice from'gh-r' ver'nightly' as'program' id-as'bottom' \
  atclone'echo "" > ._zinit/is_release' \
  atpull'%atclone' \
  atload'alias top=btm' \
  atload'alias htop=btm'
zinit light ClementTsang/bottom
# hexyl hex viewer
zinit ice lucid wait'0' as'program' id-as'hexyl' from'gh-r' \
  mv'hexyl* -> hexyl' pick'hexyl/hexyl'
zinit light sharkdp/hexyl
# mmv renamer
zinit ice lucid wait'0' as'program' id-as'mmv' from'gh-r' \
  mv'mmv* -> mmv' pick'mmv/mmv'
zinit light 'itchyny/mmv'
# jq
zinit ice lucid wait'0' as'program' id-as'jq' from'gh-r' mv'jq-* -> jq'
zinit light stedolan/jq
# yq
zinit ice lucid wait'0' as'program' id-as'yq' from'gh-r' mv'yq_* -> yq' \
 atclone'yq shell-completion zsh > _yq' atpull'%atclone'
zinit light mikefarah/yq
# sd sed alternative
zinit ice lucid wait'0' as'program' id-as'sd' from'gh-r' pick'sd' mv'sd-* -> sd'
zinit light chmln/sd
# zoxide autojumper
zinit lucid wait'0' as'program' id-as'zoxide' from'gh-r' pick'zoxide*/zoxide' \
  atclone'./zoxide*/zoxide init zsh --hook pwd >! zhook.zsh' atpull'%atclone' \
  src'zhook.zsh' for \
  'ajeetdsouza/zoxide'
# nnn file manager
zinit wait lucid id-as'nnn' from'github' as'program' for \
  sbin'nnn' make='O_NERD=1' src'misc/quitcd/quitcd.bash_zsh' \
  jarun/nnn
# rip rm-improved, trash alternative written in Rust
zinit wait'1' lucid \
 from'gh-r' as'program' id-as'rip' pick'rip*/rip' \
 light-mode for @nivekuil/rip
# gitui rust
zinit ice lucid wait'0' as'program' id-as'gitui' from'gh-r'
zinit light extrawurst/gitui
# xh faster HTTPie clone written in Rust
zinit ice lucid wait'0' as'program' id-as'xh' from'gh-r' pick'xh*/xh'
zinit light ducaale/xh
# bandwhich network bandwidth monitor
zinit ice lucid wait'0' as'program' id-as'bandwhich' from'gh-r'
zinit light imsnif/bandwhich
# load kubectl completion
zinit light-mode lucid wait has'kubectl' for \
  id-as'kubectl_completion' as'completion' \
  atclone'kubectl completion zsh > _kubectl' \
  atpull'%atclone' run-atpull zdharma/null
# Hyperfine benchmarking tool
zinit ice lucid wait'0' as'program' id-as'hyperfine' from'gh-r' \
  mv'hyperfine*/hyperfine -> hyperfine'
zinit light sharkdp/hyperfine
# python automatic virtualenv
zinit light MichaelAquilina/zsh-autoswitch-virtualenv
# Himalaya terminal email client
zinit ice lucid wait'0' as'program' id-as'himalaya' from'gh-r' \
  atclone'himalaya completion zsh > _himalaya' atpull'%atclone'
zinit light soywod/himalaya
# GitLab cli
zinit ice lucid wait'0' as'program' id-as'gitlab' from'gh-r' \
  mv'gitlab* -> gitlab' \
  atclone'./gitlab completion zsh > _gitlab' atpull'%atclone'
zinit light makkes/gitlab-cli
# rust-analyzer
zinit ice lucid wait'0' as'program' id-as'rust-analyzer' from'gh-r' \
  ver'latest' mv'rust-analyzer* -> rust-analyzer'
zinit light rust-analyzer/rust-analyzer
# texlab LaTeX LSP
zinit ice lucid wait'0' as'program' id-as'texlab' from'gh-r'
zinit light latex-lsp/texlab
# carapace completion
zinit ice lucid wait'0' as'program' id-as'carapace' from'gh-r'
zinit light rsteube/carapace-bin
# dprint code formatter
zinit ice lucid wait'0' as'program' id-as'dprint' from'gh-r'
zinit light dprint/dprint

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
setopt emacs  # vi            # emacs / vim keybindings
setopt interactivecomments    # recognize comments
setopt sharehistory           # global history

chpwd() {
  if [[ $(ls | wc -l) -ge 20 ]]; then
    # print as grid
    exa -G -a -F --icons --group-directories-first --git --color=always --ignore-glob=".DS_Store|__*"
  else
    # print as list and add left padding
    exa -1 -a -F --icons --group-directories-first --git --color=always --ignore-glob=".DS_Store|__*" | sed 's/^/  /'
  fi
}

# chpwd() { exa -l -a -F --icons --group-directories-first --git --color=always --no-permissions --no-user --no-filesize --time=modified | sed 's/^/  /'; }  # alternative showing last modified date for files

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
# ENV VARIABLE      #
#####################
# export TERM=xterm-256color
export EDITOR='nvim'
export VISUAL=$EDITOR
export PAGER='less'
export LESS='-F -g -i -M -R -S -w -X -z-4 -~'
export LESS_TERMCAP_mb=$'\E[6m'     # begin blinking
export LESS_TERMCAP_md=$'\E[34m'    # begin bold
export LESS_TERMCAP_us=$'\E[4;32m'  # begin underline
export LESS_TERMCAP_so=$'\E[0m'     # begin standout-mode (info box), remove background
export LESS_TERMCAP_me=$'\E[0m'     # end mode
export LESS_TERMCAP_ue=$'\E[0m'     # end underline
export LESS_TERMCAP_se=$'\E[0m'     # end standout-mode
export MANPAGER="nvim -c 'set ft=man' -"
export SHELL='/bin/zsh'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'  # sane moving between words on the prompt
export GPG_TTY=$(tty)
export PATH="$PATH:~/.local/bin"  # for pipx
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
export PROMPT_EOL_MARK=''  # hide % at end of output

#####################
# COLORING          #
#####################
autoload colors && colors

#####################
# ALIASES           #
#####################
source $HOME/.zsh_aliases
source $HOME/.zsh_aliases_private

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
export FZF_ALT_C_OPTS='--preview="exa -1 --icons --git --git-ignore {}" --preview-window=right:60%:wrap'
bindkey '^F' fzf-file-widget
# FZF custom OneDark theme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--ansi
--height=50%
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
# For compilers and pkgconfig to find zlib
export LDFLAGS="-L/usr/local/opt/zlib/lib -L/usr/local/opt/bzip2/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include -I/usr/local/opt/bzip2/include"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"

export CLOUDSDK_PYTHON="/usr/local/opt/python@3.8/libexec/bin/python"
source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

# Nushell environment

# Path helpers
def --env prepend-path [paths: list<string>] {
  let current_path = ($env.PATH? | default [])
  let missing_paths = ($paths | where { |p| $p not-in $current_path })
  if ($missing_paths | is-not-empty) {
    $env.PATH = ($missing_paths | append $current_path)
  }
}

# Homebrew setup
def --env setup-homebrew [hb: string] {
  $env.HOMEBREW_HOME = $hb
  $env.HOMEBREW_CASK_OPTS = "--no-quarantine"
  prepend-path [
    ($hb | path join "bin")
    ($hb | path join "sbin")
    ($hb | path join "opt" "llvm" "bin")
  ]

  $env.LDFLAGS = $" -L($hb)/opt/zlib/lib -L($hb)/opt/bzip2/lib -L($hb)/opt/llvm/lib -Wl,-rpath,($hb)/opt/llvm/lib -L($hb)/opt/freetds/lib -L($hb)/opt/openssl@3/lib"
  $env.CFLAGS = $" -I($hb)/opt/freetds/include"
  $env.CPPFLAGS = $" -I($hb)/opt/zlib/include -I($hb)/opt/bzip2/include -I($hb)/opt/llvm/include -I($hb)/opt/openssl@3/include"
  $env.PKG_CONFIG_PATH = ($env.PKG_CONFIG_PATH? | default "" | str trim | $"($in) ($hb)/opt/zlib/lib/pkgconfig" | str trim)
  $env.DYLD_LIBRARY_PATH = ([$env.DYLD_LIBRARY_PATH? "/opt/homebrew/lib"] | where { |it| ($it | default "") != "" } | str join ":")
}

let user_bin_paths = [
  ($env.HOME | path join ".local" "bin")
  ($env.HOME | path join ".cargo" "bin")
  ($env.HOME | path join ".bun" "bin")
  ($env.HOME | path join ".deno" "bin")
  ($env.HOME | path join ".luarocks" "bin")
]
prepend-path $user_bin_paths

# Prefer known Homebrew prefixes to avoid startup subprocess calls.
let homebrew_prefix = match $nu.os-info.name {
  "macos" => "/opt/homebrew"
  "linux" => "/home/linuxbrew/.linuxbrew"
  _ => null
}

if ($homebrew_prefix != null and (($homebrew_prefix | path join "bin" "brew") | path exists)) {
  setup-homebrew $homebrew_prefix
} else if (which brew | is-not-empty) {
  setup-homebrew (brew --prefix | str trim)
}

# Fallback paths
prepend-path [/usr/local/bin]

# Core environment
$env.SHELL = $nu.current-exe
$env.EDITOR = "nvim"
$env.VISUAL = $env.EDITOR
$env.PAGER = "less"
$env.LESS = "-F -g -i -M -R -S -w -X -~ --mouse"
$env.LESS_TERMCAP_mb = "\u{1b}[6m"
$env.LESS_TERMCAP_md = "\u{1b}[34m"
$env.LESS_TERMCAP_us = "\u{1b}[4;32m"
$env.LESS_TERMCAP_so = "\u{1b}[0m"
$env.LESS_TERMCAP_me = "\u{1b}[0m"
$env.LESS_TERMCAP_ue = "\u{1b}[0m"
$env.LESS_TERMCAP_se = "\u{1b}[0m"
$env.MANPAGER = "nvim +Man!"
$env.LANG = "en_US.UTF-8"
$env.LC_TIME = "de_DE.UTF-8"
$env.WORDCHARS = "~!#$%^&*(){}[]<>?.+;"
$env.PROMPT_EOL_MARK = ""
$env.QUOTING_STYLE = "literal"
$env.LS_COLORS = "rs=0:fi=0:di=34:ln=36:so=33:pi=33:ex=32:bd=33;1:cd=33;1:su=31:sg=31:tw=34:ow=34:mi=31:or=31:*.tar=31:*.tgz=31:*.zip=31:*.gz=31:*.bz2=31:*.xz=31:*.7z=31:*.jpg=35:*.png=35:*.gif=35:*.pdf=35"
if $nu.is-interactive {
  $env.GPG_TTY = (tty)
}

# Theme colors
const FZF_COLORS_DARK = '
--color=fg:-1,bg:-1,border:#4B5164,hl:#d19a66
--color=fg+:#f7f7f7,bg+:#2c323d,hl+:#e5c07b
--color=info:#828997,prompt:#4fb5f7,pointer:#45cdff
--color=marker:#98c379,spinner:#e06c75,header:#98c379
--color=gutter:#2c323d'

const FZF_COLORS_LIGHT = '
--color=fg:-1,bg:-1,border:#d0d0d0,hl:#d75f00
--color=fg+:#1a1a1a,bg+:#e8e8e8,hl+:#d75f00
--color=info:#878787,prompt:#ff6a00,pointer:#0087af
--color=marker:#5f8700,spinner:#d7005f,header:#5f8700
--color=gutter:#e8e8e8'

# Theme update helper
def --env update-theme [] {
  const dark_theme = 1
  const light_theme = 2
  let system_theme = term query "\e[?996n" --prefix "\e[?997;" --terminator "n" | decode | into int

  if $system_theme != $env.THEME? {
    $env.THEME = if $system_theme == $dark_theme { "dark" } else { "light" }
    $env.BAT_THEME = if $system_theme == $dark_theme { "OneHalfDark" } else { "OneHalfLight" }
    $env.DELTA_FEATURES = $env.THEME
    $env.FZF_DEFAULT_OPTS = $"
--style=minimal
--no-separator
--info=hidden
--ansi
(if $system_theme == $dark_theme { $FZF_COLORS_DARK } else { $FZF_COLORS_LIGHT })"
    $env._ZO_FZF_OPTS = $"($env.FZF_DEFAULT_OPTS)\n--height=7"
  }
}

# FZF settings
$env.FZF_DEFAULT_COMMAND = 'rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*"'
$env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
$env.FZF_CTRL_T_OPTS = '--preview="bat --color=always --style=header-filename {}" --preview-window=right:60%:wrap'
$env.FZF_ALT_C_COMMAND = 'fd -t d -d 1'
$env.FZF_ALT_C_OPTS = '--preview="eza --no-quotes -1 --icons --git --git-ignore {}" --preview-window=right:60%:wrap'

# Carapace completions
$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense"

# HACK: docker-py not supporting current context https://github.com/docker/docker-py/issues/3146
$env.DOCKER_HOST = $"unix://($env.HOME)/.colima/default/docker.sock"

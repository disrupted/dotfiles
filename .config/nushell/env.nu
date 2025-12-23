# Nushell environment

# XDG Base Directory Specification
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.XDG_DATA_HOME = ($env.HOME | path join ".local" "share")
$env.XDG_STATE_HOME = ($env.HOME | path join ".local" "state")
$env.XDG_CACHE_HOME = ($env.HOME | path join ".cache")

def --env prepend-path [paths: list<string>] {
  $env.PATH = ($paths | append $env.PATH)
}

prepend-path [
  /usr/local/bin
  /opt/homebrew/bin
  ($env.HOME | path join ".local" "bin")
  ($env.HOME | path join ".cargo" "bin")
  ($env.HOME | path join ".deno" "bin")
  ($env.HOME | path join ".luarocks" "bin")
]

if (which brew | length) > 0 {
  let hb = (brew --prefix | str trim)
  $env.HOMEBREW_HOME = $hb
  $env.HOMEBREW_CASK_OPTS = "--no-quarantine"
  $env.SHELL = (which nu | get 0.path)
  prepend-path [
    ($hb | path join "bin")
    ($hb | path join "sbin")
    ($hb | path join "opt" "llvm" "bin")
    ($hb | path join "opt" "openjdk" "bin")
  ]

  $env.LDFLAGS = $" -L($hb)/opt/zlib/lib -L($hb)/opt/bzip2/lib -L($hb)/opt/llvm/lib -Wl,-rpath,($hb)/opt/llvm/lib -L($hb)/opt/freetds/lib -L($hb)/opt/openssl@3/lib"
  $env.CFLAGS = $" -I($hb)/opt/freetds/include"
  $env.CPPFLAGS = $" -I($hb)/opt/zlib/include -I($hb)/opt/bzip2/include -I($hb)/opt/llvm/include -I($hb)/opt/openssl@3/include"
  $env.PKG_CONFIG_PATH = ($env.PKG_CONFIG_PATH? | default "" | str trim | $"($in) ($hb)/opt/zlib/lib/pkgconfig" | str trim)
  $env.DYLD_LIBRARY_PATH = ([$env.DYLD_LIBRARY_PATH? "/opt/homebrew/lib"] | where { |it| ($it | default "") != "" } | str join ":")
}

if (($env.GOPATH? | default "") != "") {
  prepend-path [($env.GOPATH | path join "bin")]
}

$env.TERMINAL = "kitty"
$env.EDITOR = "nvim"
$env.VISUAL = $env.EDITOR
$env.PAGER = "less"
$env.LESS = "-F -g -i -M -R -S -w -X -z-4 -~ --mouse"
$env.LESS_TERMCAP_mb = "\u{1b}[6m"
$env.LESS_TERMCAP_md = "\u{1b}[34m"
$env.LESS_TERMCAP_us = "\u{1b}[4;32m"
$env.LESS_TERMCAP_so = "\u{1b}[0m"
$env.LESS_TERMCAP_me = "\u{1b}[0m"
$env.LESS_TERMCAP_ue = "\u{1b}[0m"
$env.LESS_TERMCAP_se = "\u{1b}[0m"
$env.MANPAGER = "nvim +Man!"
$env.LANG = "en_US.UTF-8"
$env.LC_ALL = "en_US.UTF-8"
$env.WORDCHARS = "~!#$%^&*(){}[]<>?.+;"
$env.PROMPT_EOL_MARK = ""
$env.GPG_TTY = (tty)
$env.QUOTING_STYLE = "literal"
$env.LS_COLORS = "rs=0:fi=0:di=34:ln=36:so=33:pi=33:ex=32:bd=33;1:cd=33;1:su=31:sg=31:tw=34:ow=34:mi=31:or=31:*.tar=31:*.tgz=31:*.zip=31:*.gz=31:*.bz2=31:*.xz=31:*.7z=31:*.jpg=35:*.png=35:*.gif=35:*.pdf=35"

# Theme detection (macOS) - initial value
$env.IS_DARK_MODE = (do { defaults read -g AppleInterfaceStyle } | complete | get stdout | str trim) == "Dark"

# Theme colors as constants
const FZF_COLORS_DARK = '
--color=fg:-1,bg:-1,border:#4B5164,hl:#d19a66
--color=fg+:#f7f7f7,bg+:#2c323d,hl+:#e5c07b
--color=info:#828997,prompt:#e06c75,pointer:#45cdff
--color=marker:#98c379,spinner:#e06c75,header:#98c379'

const FZF_COLORS_LIGHT = '
--color=fg:-1,bg:-1,border:#d0d0d0,hl:#d75f00
--color=fg+:#1a1a1a,bg+:#e8e8e8,hl+:#d75f00
--color=info:#878787,prompt:#d7005f,pointer:#0087af
--color=marker:#5f8700,spinner:#d7005f,header:#5f8700'

# Function to update theme-dependent env vars
def --env update-theme [] {
  let is_dark = (do { defaults read -g AppleInterfaceStyle } | complete | get stdout | str trim) == "Dark"
  if $is_dark != $env.IS_DARK_MODE {
    $env.IS_DARK_MODE = $is_dark
    $env.DELTA_FEATURES = if $is_dark { "dark" } else { "light" }
    $env.BAT_THEME = if $is_dark { "OneHalfDark" } else { "OneHalfLight" }
    $env.FZF_DEFAULT_OPTS = $"
--no-separator
--info=hidden
--ansi
(if $is_dark { $FZF_COLORS_DARK } else { $FZF_COLORS_LIGHT })"
    $env._ZO_FZF_OPTS = $"($env.FZF_DEFAULT_OPTS)\n--height=7"
  }
}

# Initial theme setup
$env.DELTA_FEATURES = if $env.IS_DARK_MODE { "dark" } else { "light" }
$env.BAT_THEME = if $env.IS_DARK_MODE { "OneHalfDark" } else { "OneHalfLight" }

# FZF settings
$env.FZF_DEFAULT_COMMAND = 'rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2>/dev/null'
$env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
$env.FZF_CTRL_T_OPTS = '--preview="bat --color=always --style=header {} 2>/dev/null" --preview-window=right:60%:wrap'
$env.FZF_ALT_C_COMMAND = 'fd -t d -d 1'
$env.FZF_ALT_C_OPTS = '--preview="eza --no-quotes -1 --icons --git --git-ignore {}" --preview-window=right:60%:wrap'

$env.FZF_DEFAULT_OPTS = $"
--no-separator
--info=hidden
--ansi
(if $env.IS_DARK_MODE { $FZF_COLORS_DARK } else { $FZF_COLORS_LIGHT })"

$env._ZO_FZF_OPTS = $"($env.FZF_DEFAULT_OPTS)\n--height=7"

# carapace completions
$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense"
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

# mise (replaces direnv for env management + tool versions)
source ~/.config/nushell/mise.nu

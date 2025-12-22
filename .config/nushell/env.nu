# Nushell environment

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
  $env.SHELL = ($hb | path join "bin" "zsh")
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

# carapace completions (official setup) - requires `carapace` installed
$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense"
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

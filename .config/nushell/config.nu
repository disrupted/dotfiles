# Nushell config

$env.EDITOR = "nvim"
$env.PAGER = "less"
$env.LESS = "-F -g -i -M -R -S -w -X -z-4 -~ --mouse"

$env.config = {
  show_banner: false
  edit_mode: emacs
  history: {
    file_format: "sqlite"
    max_size: 100000
    isolation: true
  }
  ls: {
    use_ls_colors: true
  }
  completions: {
    case_sensitive: false
  }
}

use ~/.config/nushell/modules/user.nu *
use std/config *

# Use ANSI colors so Nu respects the terminal theme.
$env.config.color_config = {
  separator: dark_gray_dimmed
  leading_trailing_space_bg: { attr: n }
  header: { fg: default, attr: b }
  empty: default
  bool: yellow
  int: default
  filesize: default
  duration: default
  date: default
  datetime: {|| (date now) - $in |
    if $in < 2hr {
      'red'
    } else if $in < 1day {
      'yellow'
    } else {
      'default'
    }
  }
  range: yellow
  float: default
  string: default
  nothing: default
  binary: default
  cellpath: default
  row_index: dark_gray
  record: default
  list: default
  block: default
  table: default
  hints: dark_gray
  shape_garbage: { fg: white, bg: red, attr: b }
  shape_bool: yellow
  shape_int: default
  shape_float: default
  shape_range: yellow
  shape_internalcall: green
  shape_external: green
  shape_externalarg: yellow
  shape_literal: blue
  shape_operator: yellow
  shape_signature: cyan
  shape_string: default
  shape_string_interpolation: cyan
  shape_datetime: dark_gray
  shape_list: default
  shape_table: default
  shape_record: default
  shape_block: default
  shape_pipe: yellow
  shape_redirection: yellow
  shape_variable: default
  shape_flag: blue
  shape_custom: default
  shape_directory: blue
  shape_path: blue
}

$env.config = ($env.config | merge {
  keybindings: ($env.config.keybindings | default []),
})


$env.config.keybindings ++= [
  {
    name: project_history
    modifier: alt
    keycode: char_r
    mode: [emacs]
    event: { send: ExecuteHostCommand, cmd: "hproj_pick" }
  }
]

# direnv (nushell cookbook)
$env.config.hooks.env_change.PWD = $env.config.hooks.env_change.PWD? | default []

$env.config.hooks.env_change.PWD ++= [{||
  if (which direnv | is-empty) {
    return
  }

  direnv export json | from json | default {} | load-env
  $env.PATH = do (env-conversions).path.from_string $env.PATH
}]

# carapace completions (official setup)
source ($nu.cache-dir | path join "carapace.nu")

# starship prompt (auto-generate if missing)
const starship_path = "~/.config/nushell/vendor/autoload/starship.nu"
if ((which starship | length) > 0) and (not ($starship_path | path exists)) {
  mkdir ~/.config/nushell/vendor/autoload
  starship init nu | save -f $starship_path
}
if ((which starship | length) > 0) {
  source $starship_path
}

# zoxide (auto-generate if missing)
const zoxide_path = "~/.zoxide.nu"
if ((which zoxide | length) > 0) and (not ($zoxide_path | path exists)) {
  zoxide init nushell | save -f $zoxide_path
}
if ((which zoxide | length) > 0) {
  source $zoxide_path
}

# source ~/.config/nushell/catppuccin_mocha.nu

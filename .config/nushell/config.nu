# Nushell config

$env.EDITOR = "nvim"
$env.PAGER = "less"
$env.LESS = "-F -g -i -M -R -S -w -X -z-4 -~ --mouse"

$env.config = {
  show_banner: false
  edit_mode: emacs
  cursor_shape: {
    emacs: line
    vi_insert: line
    vi_normal: block
  }
  history: {
    file_format: "sqlite"
    max_size: 100000
    isolation: true
  }
  ls: {
    use_ls_colors: true
    clickable_links: true
  }
  completions: {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
    use_ls_colors: true
  }
  highlight_resolved_externals: true
  bracketed_paste: true
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
  # Edit command line in $EDITOR (Ctrl+X Ctrl+E)
  {
    name: edit_command_line
    modifier: control
    keycode: char_e
    mode: [emacs]
    event: { send: OpenEditor }
  }
  # History substring search with up/down (like zsh-history-substring-search)
  {
    name: history_substring_search_up
    modifier: none
    keycode: up
    mode: [emacs]
    event: {
      until: [
        { send: MenuUp }
        { send: Up }
      ]
    }
  }
  {
    name: history_substring_search_down
    modifier: none
    keycode: down
    mode: [emacs]
    event: {
      until: [
        { send: MenuDown }
        { send: Down }
      ]
    }
  }
  # Word navigation with Alt+arrows
  {
    name: move_word_left
    modifier: alt
    keycode: left
    mode: [emacs]
    event: { edit: MoveWordLeft }
  }
  {
    name: move_word_right
    modifier: alt
    keycode: right
    mode: [emacs]
    event: { edit: MoveWordRight }
  }
  # Backward kill word (Alt+Backspace)
  {
    name: backward_kill_word
    modifier: alt
    keycode: backspace
    mode: [emacs]
    event: { edit: BackspaceWord }
  }
  # FZF file picker (Ctrl+F)
  {
    name: fzf_file_picker
    modifier: control
    keycode: char_f
    mode: [emacs]
    event: {
      send: ExecuteHostCommand
      cmd: "commandline edit --insert (fzf --preview 'bat --color=always --style=header {} 2>/dev/null || ls -la {}' | str trim)"
    }
  }
  # FZF directory picker (Alt+C, like zsh)
  {
    name: fzf_cd
    modifier: alt
    keycode: char_c
    mode: [emacs]
    event: {
      send: ExecuteHostCommand
      cmd: "cd (fd -t d -d 3 | fzf --preview 'eza --no-quotes -1 --icons --git-ignore {}' | str trim)"
    }
  }
  # Global history search (Ctrl+R)
  {
    name: history_search
    modifier: control
    keycode: char_r
    mode: [emacs]
    event: { send: SearchHistory }
  }
  # Clear screen (Ctrl+L)
  {
    name: clear_screen
    modifier: control
    keycode: char_l
    mode: [emacs]
    event: { send: ClearScreen }
  }
  # Show jobs (Ctrl+Z)
  {
    name: show_jobs
    modifier: control
    keycode: char_z
    mode: [emacs]
    event: { send: ExecuteHostCommand, cmd: "job list" }
  }
]

# PWD change hooks
$env.config.hooks.env_change.PWD = $env.config.hooks.env_change.PWD? | default []

# chpwd: auto-list directory contents on cd (like zsh)
$env.config.hooks.env_change.PWD ++= [{||
  let entries = (ls -s)
  if ($entries | is-empty) { return }
  if ($entries | length) >= 20 {
    $entries | sort-by type name -i | grid -c -i -s '   '
  } else {
    $entries | sort-by type name -i | each {|f| $"  ([$f] | grid -c -i | str trim)" } | str join "\n" | print
  }
}]

# direnv (nushell cookbook)
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

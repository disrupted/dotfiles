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

# Pure-style minimal color config
# Philosophy: neutral by default, color only for meaningful feedback
$env.config.color_config = {
  # Table output
  separator: dark_gray
  leading_trailing_space_bg: { attr: n }
  header: { attr: b }
  empty: dark_gray
  row_index: dark_gray
  hints: dark_gray

  # Data types (output) - mostly neutral
  bool: default
  int: default
  float: default
  string: default
  nothing: dark_gray
  binary: default
  cellpath: default
  record: default
  list: default
  block: default
  table: default
  range: default
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

  # Syntax shapes - minimal highlighting
  shape_garbage: { fg: white, bg: red, attr: b }

  # Commands - the important distinction
  shape_internalcall: { attr: b }           # bold, adapts to theme
  shape_external: red                       # invalid = red (important feedback)
  shape_external_resolved: { attr: b }      # bold, adapts to theme
  shape_externalarg: default
  shape_custom: { attr: b }

  # Literals
  shape_string: green
  shape_string_interpolation: cyan
  shape_int: yellow
  shape_float: yellow
  shape_bool: yellow
  shape_nothing: dark_gray
  shape_binary: cyan
  shape_literal: yellow
  shape_datetime: dark_gray
  shape_range: yellow

  # Paths
  shape_filepath: blue
  shape_directory: blue
  shape_globpattern: blue

  # Nushell syntax
  shape_flag: cyan
  shape_operator: magenta
  shape_pipe: magenta
  shape_redirection: magenta
  shape_keyword: magenta

  # Structures
  shape_signature: cyan
  shape_block: default
  shape_list: cyan
  shape_table: cyan
  shape_record: cyan

  # Variables
  shape_variable: purple
  shape_vardecl: purple_bold

  shape_matching_brackets: { attr: u }
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
  # Global history search (Ctrl+R) - fzf in tmux popup
  {
    name: history_search
    modifier: control
    keycode: char_r
    mode: [emacs]
    event: {
      send: ExecuteHostCommand
      cmd: "commandline edit --replace (
        let query = (commandline);
        history | get command | uniq | reverse | str join (char newline) |
        fzf --height=~40% --scheme=history --layout=reverse -q $query |
        str trim
      )"
    }
  }
  # Clear screen (Ctrl+L)
  {
    name: clear_screen
    modifier: control
    keycode: char_l
    mode: [emacs]
    event: { send: ClearScreen }
  }
  # Disable Ctrl+Z (no job suspension)
  {
    name: disable_ctrl_z
    modifier: control
    keycode: char_z
    mode: [emacs, vi_normal, vi_insert]
    event: null
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

# direnv replaced by mise (see env.nu)

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

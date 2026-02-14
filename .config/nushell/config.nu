# Nushell config

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
    external: {
      enable: true
      max_results: 100
      completer: null
    }
  }
  use_kitty_protocol: true  # Better keyboard handling in kitty terminal
  highlight_resolved_externals: true
  bracketed_paste: true
  table: {
    mode: rounded  # "basic", "thin", "light", "compact", "rounded", "reinforced", "heavy", "none"
    index_mode: always  # "always", "never"
    show_empty: true
    padding: { left: 1, right: 1 }
    trim: {
      methodology: wrapping  # "wrapping", "truncating"
      wrapping_try_keep_words: true
      truncating_suffix: "..."
    }
    header_on_separator: false
  }
}

use ~/.config/nushell/modules/user.nu *
use ~/.config/nushell/modules/agent.nu *
use ($nu.default-config-dir | path join "mise.nu")
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
    name: suspend_ctrl_z
    modifier: control
    keycode: char_z
    mode: [vi_normal, vi_insert, emacs]
    event: null  # disabled to prevent accidental job suspension
    # event: {
    #   until: [
    #     { send: ExecuteHostCommand cmd: "if (job list | where type == frozen | is-not-empty) { job unfreeze e> /dev/null }" }
    #     { sedit: Undo }
    #   ]
    # }
  }
  # Tab to open/navigate completion menu
  {
    name: completion_menu
    modifier: none
    keycode: tab
    mode: [emacs, vi_normal, vi_insert]
    event: {
      until: [
        { send: Menu, name: completion_menu }
        { send: MenuNext }
      ]
    }
  }
  # Shift+Tab to navigate backwards in menu
  {
    name: completion_previous
    modifier: shift
    keycode: backtab
    mode: [emacs, vi_insert, vi_normal]
    event: { send: MenuPrevious }
  }
  {
    name: project_history
    modifier: alt
    keycode: char_r
    mode: [emacs]
    event: { send: ExecuteHostCommand, cmd: "hproj_pick" }
  }
  # Edit command line in $EDITOR (Ctrl+v)
  {
    name: edit_command_line
    modifier: control
    keycode: char_v
    mode: [emacs]
    event: { send: OpenEditor }
  }
  {
    name: fuzzy_file
    modifier: control
    keycode: char_t
    mode: emacs
    event: {
      send: ExecuteHostCommand
      cmd: "commandline edit --insert (fzf --layout=reverse)"
    }
  }
  # History substring search with up/down
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
      cmd: "commandline edit --insert (fd --type f --hidden --follow --exclude .git --exclude node_modules | fzf --preview 'bat --color=always --style=header-filename {}' --preview-window=right:60%:wrap)"
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
  # Global history search (Ctrl+R) - fzf
  {
    name: fuzzy_history_fzf
    modifier: control
    keycode: char_r
    mode: [emacs , vi_normal, vi_insert]
    event: {
      send: ExecuteHostCommand
      cmd: "commandline edit --replace (
        history
          | where exit_status == 0
          | get command
          | reverse
          | uniq
          | str join (char -i 0)
          | fzf --scheme=history --read0 --tiebreak=chunk --layout=reverse --preview='echo {..}' --preview-window='bottom:3:wrap' --bind alt-up:preview-up,alt-down:preview-down --height=~40% -q (commandline) --preview='echo {} | nu --stdin -c \'nu-highlight\''
          | decode utf-8
          | str trim
      )"
    }
  }
  {
    name: ask_agent
    modifier: control
    keycode: char_s
    mode: [emacs vi_normal vi_insert]
    event: {
        send: ExecuteHostCommand
        cmd: "commandline edit --replace (ask (commandline))"
    }
  }
]

$env.config.hooks.pre_execution = ([ update-theme ])

let pre_prompt_terminal_safety = {||
  # disable Ctrl+z to suspend
  if (which stty | is-not-empty) {
    try { ^stty susp undef } catch { }
    try { ^stty -ixon } catch { }
  }
}

if ($env.__pre_prompt_local_hooks_installed? | is-empty) {
  $env.config.hooks.pre_prompt = (
    $env.config.hooks.pre_prompt?
    | default []
    | append $pre_prompt_terminal_safety
  )
  $env.__pre_prompt_local_hooks_installed = true
}

# PWD change hooks
$env.config.hooks.env_change.PWD = $env.config.hooks.env_change.PWD? | default []

# chpwd: auto-list directory contents on cd (like zsh)
# $env.config.hooks.env_change.PWD ++= [{||
#   let entries = (ls -s)
#   if ($entries | is-empty) { return }
#   if ($entries | length) >= 20 {
#     $entries | sort-by type name -i | grid -c -i -s '   '
#   } else {
#     $entries | sort-by type name -i | each {|f| $"  ([$f] | grid -c -i | str trim)" } | str join "\n" | print
#   }
# }]

# detect theme on load
update-theme

# tmux session manager
#
# Additional sessions are defined in:
#   ~/.config/nushell/tmux-sessions.local.nuon
#
# Format: a nuon record  { session_name: "~/path/to/root" }

const TMUX_LOCAL_CONFIG = "~/.config/nushell/tmux-sessions.local.nuon"

const BUILTIN_SESSIONS = {
  home: "~"
}

def load_sessions [] {
  let local = try { open ($TMUX_LOCAL_CONFIG | path expand) } catch { {} }
  $BUILTIN_SESSIONS | merge $local
}

def running_sessions [] {
  do { ^tmux list-sessions -F "#{session_name}" } | complete
  | if $in.exit_code == 0 { $in.stdout | lines | where { $in != "" } } else { [] }
}

def session_exists [name: string] {
  (do { ^tmux has-session -t $name } | complete).exit_code == 0
}

def new_session [name: string, root: string] {
  ^tmux new-session -d -s $name -c ($root | path expand)
}

def attach_or_switch [name: string] {
  if ($env.TMUX? | is-not-empty) {
    ^tmux switch-client -t $name
  } else {
    ^tmux attach-session -t $name
  }
}

export def --env t [
  name?: string
] {
  let sessions = (load_sessions)
  let target = ($name | default ($BUILTIN_SESSIONS | columns | first))

  if not ($target in $sessions) {
    let known = ($sessions | columns | str join ", ")
    error make { msg: $"Unknown session '($target)'. Known sessions: ($known)" }
  }

  let current_session = if ($env.TMUX? | is-not-empty) {
    (do { ^tmux display-message -p "#{session_name}" } | complete).stdout | str trim
  } else {
    ""
  }

  if $current_session == $target {
    print $"Already in session: ($target)"
    return
  }

  if not (session_exists $target) {
    let root = ($sessions | get $target)
    new_session $target $root
    print $"Created session: ($target) → ($root | path expand)"
  }

  attach_or_switch $target
}

export def "t list" [] {
  let running = (running_sessions)
  load_sessions
    | transpose name root
    | each {|row|
        {
          session: $row.name
          root: $row.root
          status: (if ($row.name in $running) { "running" } else { "stopped" })
        }
      }
}

export def "t kill" [] {
  let running = (running_sessions)
  if ($running | is-empty) {
    print "No running tmux sessions."
    return
  }
  let choice = ($running | input list --fuzzy "Kill session")
  if ($choice | is-empty) { return }
  ^tmux kill-session -t $choice
  print $"Killed session: ($choice)"
}

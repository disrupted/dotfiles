export def csvs [path: path] {
  open --raw $path | from csv --separator ';'
}

export def tsv [path: path] {
  open --raw $path | from tsv
}

export def jsonr [path: path] {
  open --raw $path | from json
}

export def yamlr [path: path] {
  open --raw $path | from yaml
}

def get_top_level_dir [] {
  let home = $env.HOME
  let rel = (try { $env.PWD | path relative-to $home } catch { "" })
  if ($rel | is-empty) { $home } else {
    let top = ($rel | split row (char path_sep) | first)
    $home | path join $top
  }
}

export def --env zoxide_top_level_dir [query: string] {
  if ($query | is-empty) {
    print "usage: zoxide_top_level_dir <query>"
    return
  }

  let top = (get_top_level_dir)
  let results = (zoxide query -l $query | lines | where {|it| $it | str starts-with $top })

  if ($results | is-empty) {
    print "no result in top level dir found, fallback to regular zoxide"
    let selected = (zoxide query --list $query | ^sk --no-sort | str trim)
    if ($selected | is-empty) { return }
    cd $selected
    return
  }

  if ($results | length) == 1 {
    cd $results.0
  } else {
    let selected = ($results | input list --fuzzy "Select directory")
    if ($selected | is-empty) { return }
    cd $selected
  }
}

export def --env j [query: string] {
  zoxide_top_level_dir $query
}

export def --env mkcd [path: path] {
  mkdir $path
  cd $path
}

export alias v = nvim
export alias y = yazi
export alias c = clear
export def l [path: path = "."] { ls $path | sort-by modified -r | sort-by type | table --index false }

export def ports [--all] {
  let rows = (^somo --json | from json)
  let shown = if $all { $rows } else { $rows | where state == listen }
  let cols = if $all {
    [local_port proto program pid state cwd remote_address remote_port]
  } else {
    [local_port program pid cwd]
  }
  $shown
  | update pid { into int }
  | update local_port { into int }
  | join --left (ps --long | select pid cwd) pid
  | select ...$cols
  | sort-by local_port
}

export alias gs = git status -sb
export alias gc = git commit

export def git_main_branch [] {
  if (do { git rev-parse --is-inside-work-tree } | complete).exit_code != 0 {
    return null
  }

  let origin_head = (do { git symbolic-ref -q --short refs/remotes/origin/HEAD } | complete)
  if $origin_head.exit_code == 0 {
    return ($origin_head.stdout | str trim | path basename)
  }

  for ref in [
    "refs/heads/main"
    "refs/heads/trunk"
    "refs/heads/mainline"
    "refs/heads/default"
    "refs/heads/master"
    "refs/remotes/origin/main"
    "refs/remotes/origin/trunk"
    "refs/remotes/origin/mainline"
    "refs/remotes/origin/default"
    "refs/remotes/origin/master"
    "refs/remotes/upstream/main"
    "refs/remotes/upstream/trunk"
    "refs/remotes/upstream/mainline"
    "refs/remotes/upstream/default"
    "refs/remotes/upstream/master"
  ] {
    if (git show-ref -q --verify $ref | complete).exit_code == 0 {
      return ($ref | path basename)
    }
  }
}

export def gm [] {
  let main = (git_main_branch)
  ^git switch $main
}

export def gp [...args] {
  ^git push ...$args
  if $env.LAST_EXIT_CODE != 0 { return }

  let root = (^git rev-parse --show-toplevel | str trim)
  if ($root | is-empty) { return }

  let gh_workflows = ($root | path join ".github" "workflows")
  let glab_ci = ($root | path join ".gitlab-ci.yml")
  let remote = (^git remote get-url origin | str trim)
  let is_github = ($remote | str contains "github.com")
  let is_gitlab = ($remote | str contains "gitlab.com")

  if (($gh_workflows | path exists) and ($is_github or ((^gh repo view | ignore); $env.LAST_EXIT_CODE == 0))) {
    let max_retries = 50
    mut retry = 0
    mut job = ""
    while $retry < $max_retries {
      let commit = (^git rev-parse HEAD | str trim)
      $job = (^gh run list --commit $commit --json databaseId --jq '.[0].databaseId' | str trim)
      if ($job | is-empty) == false { break }
      print "Job not found, retrying..."
      sleep 1sec
      $retry = $retry + 1
    }
    if $retry >= $max_retries {
      print "Max retries reached, aborting"
      return
    }
    ^gh run watch --exit-status $job
    if $env.LAST_EXIT_CODE != 0 { ^gh run view --log-failed $job }
  } else if (($glab_ci | path exists) and ($is_gitlab or ((^glab repo view | ignore); $env.LAST_EXIT_CODE == 0))) {
    ^glab ci view
  }
}

export def gh-ci-retry [max_retries: int = 20] {
  let commit = (^git rev-parse HEAD | str trim)
  let job = (^gh run list --commit $commit --json databaseId --jq '.[0].databaseId' | str trim)
  if ($job | is-empty) { return }
  mut retry = 0
  while $retry < $max_retries {
    ^gh run rerun $job --failed
    ^gh run watch --exit-status $job
    if $env.LAST_EXIT_CODE == 0 { break }
    print "retrying..."
    $retry = $retry + 1
  }
  if $retry >= $max_retries {
    print "Max retries reached, aborting"
  }
}

# dl - download a file
export def dl [url: string output?: path] {
  if ($output == null) {
    ^wget --content-disposition $url
  } else {
    ^wget $url -O $output
  }
}

export def history_pick [] {
  let base = $env.PWD
  let history = history --long | where exit_status == 0
  mut here = false
  mut query = commandline
  loop {
    let prompt = if $here { $"($base | str replace $nu.home-dir '~')> " } else { "history> " }
    let commands = if $here {
      $history | where {|row| $row.cwd? == $base or ($row.cwd? | default '' | str starts-with $"($base)/") }
    } else { $history }
    let out = try {
      $commands
      | get command
      | reverse
      | uniq
      | str join (char -i 0)
      | ^sk --exact --scheme=history --read0 --print0 --print-query --prompt $prompt --layout=reverse --height=40% --preview-window='down:3:wrap' --bind 'alt-up:preview-up,alt-down:preview-down,alt-r:accept(alt-r)' -q $query --preview='echo {} | nu --stdin -c \'nu-highlight\''
      | decode utf-8
    } catch { null }
    if $out == null { return }
    let parts = $out | split row (char -i 0)
    if $parts.1? == 'alt-r' {
      $here = not $here
      $query = $parts.0
      continue
    }
    commandline edit --replace ($parts.1? | default '' | str trim)
    return
  }
}

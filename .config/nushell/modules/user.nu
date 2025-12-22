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
  let results = (zoxide query -l $query | lines | where { |it| $it | str starts-with $top })

  if ($results | is-empty) {
    print "no result in top level dir found, fallback to regular zoxide"
    let selected = (zoxide query --interactive $query | str trim)
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

export def cp [...args] { ^cp -riv ...$args }
export def mv [...args] { ^mv -iv ...$args }
export def mkdir [...args] { ^mkdir -pv ...$args }

export alias v = nvim
export alias y = yazi
export alias c = clear
export def l [] { ls | sort-by modified -r | sort-by type | table --index false }

export alias gs = git status -sb
export alias gc = git commit

def git_main_branch [] {
  let refs = [
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
  ]
  for r in $refs {
    ^git show-ref -q --verify $r
    if $env.LAST_EXIT_CODE == 0 { return ($r | path basename) }
  }
  "master"
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

# Refresh 1Password secrets for a project (cached to .env.secrets)
export def secrets-refresh [--dir: path] {
  let target = ($dir | default $env.PWD)
  let tpl = ($target | path join ".env.secrets.tpl")
  let out = ($target | path join ".env.secrets")

  if not ($tpl | path exists) {
    print $"No .env.secrets.tpl found in ($target)"
    return
  }

  print "Fetching secrets from 1Password..."
  ^op inject -i $tpl -o $out
  chmod 600 $out
  print $"Secrets cached to ($out)"
}

export alias wget = wget --content-disposition
export alias dl = xh --download
export alias claude = bunx @anthropic-ai/claude-code@latest
export alias codex = bunx @openai/codex@latest

def hproj [path?: path, --table] {
  let base = (if $path == null { $env.PWD } else { $path }) | path expand
  let h = (try { history --long } catch { [] })
  if ($h | is-empty) { return }
  if ('cwd' in ($h | columns)) {
    let rows = ($h | where {|row| ($row.cwd | path expand | str starts-with $base)})
    if $table { $rows } else { $rows | get command }
  } else {
    if $table { $h } else { $h | get command }
  }
}

export def --env hproj_pick [] {
  let choice = (hproj | input list --fuzzy "Project history")
  if ($choice | is-empty) { return }
  commandline edit --replace $choice
}

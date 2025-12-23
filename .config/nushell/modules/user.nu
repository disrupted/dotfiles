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
export def l [path: path = "."] { ls $path | sort-by modified -r | sort-by type | table --index false }

export alias gs = git status -sb
export alias gc = git commit

# forgit-style interactive git commands

# ga - interactive git add
export def ga [] {
  let files = (
    git status --short |
    lines |
    where { ($in | str trim | str length) > 0 } |
    each { $in | str substring 3.. } |
    str join (char newline) |
    fzf --height=60% --layout=reverse --multi --preview 'git diff {} | delta'
  )
  if ($files | is-empty) { return }
  $files | lines | each { git add $in }
  git status --short
}

# grh - interactive git reset HEAD (unstage)
export def grh [] {
  let files = (
    git diff --cached --name-only |
    fzf --height=60% --layout=reverse --multi --preview 'git diff --cached {} | delta'
  )
  if ($files | is-empty) { return }
  $files | lines | each { git reset HEAD $in }
  git status --short
}

# gcf - interactive git checkout file (discard changes)
export def gcf [] {
  let files = (
    git diff --name-only |
    fzf --height=60% --layout=reverse --multi --preview 'git diff {} | delta'
  )
  if ($files | is-empty) { return }
  $files | lines | each { git checkout $in }
  git status --short
}

# glo - interactive git log
export def glo [] {
  git log --oneline --color=always |
  fzf --height=80% --layout=reverse --ansi --preview 'git show {1} | delta' |
  split row ' ' |
  first |
  if ($in | is-empty) { } else { git show $in }
}

# gsw - interactive git switch branch
export def gsw [] {
  let branch = (
    git branch --all --color=always |
    lines |
    str trim |
    where { not ($in | str starts-with '*') } |
    each { $in | ansi strip | str replace 'remotes/origin/' '' } |
    uniq |
    str join (char newline) |
    fzf --height=40% --layout=reverse --ansi
  )
  if ($branch | is-empty) { return }
  git switch ($branch | str trim)
}

# gbd - interactive git branch delete
export def gbd [] {
  let branches = (
    git branch |
    lines |
    str trim |
    where { not ($in | str starts-with '*') } |
    str join (char newline) |
    fzf --height=40% --layout=reverse --multi
  )
  if ($branches | is-empty) { return }
  $branches | lines | each { git branch -d $in }
}

# gss - interactive git stash show
export def gss [] {
  let stash = (
    git stash list |
    lines |
    each {|line| ($line | split row ':' | first) + ' ' + ($line | split row ':' | skip 1 | str join ':') } |
    str join (char newline) |
    fzf --height=60% --layout=reverse --preview 'git stash show -p {1} | delta' --preview-window=right:60% |
    split row ' ' |
    first
  )
  if ($stash | is-empty) { return }
  git stash show -p $stash | delta
}

# gsa - interactive git stash apply
export def gsa [] {
  let stash = (
    git stash list |
    lines |
    each {|line| ($line | split row ':' | first) + ' ' + ($line | split row ':' | skip 1 | str join ':') } |
    str join (char newline) |
    fzf --height=60% --layout=reverse --preview 'git stash show -p {1} | delta' --preview-window=right:60% |
    split row ' ' |
    first
  )
  if ($stash | is-empty) { return }
  git stash apply $stash
}

# gcp - interactive git cherry-pick
export def gcp [] {
  let commit = (
    git log --all --oneline --color=always |
    fzf --height=60% --layout=reverse --ansi --preview 'git show {1} | delta' |
    split row ' ' |
    first
  )
  if ($commit | is-empty) { return }
  git cherry-pick $commit
}

# yadm variants of forgit commands

# ya - interactive yadm add
export def ya [] {
  # Get both modified and untracked files, prefix with ~/
  let modified = (yadm diff --name-only | lines | where { $in != "" } | each { $"~/($in)" })
  let untracked = (yadm ls-files --others --exclude-standard | lines | where { $in != "" } | each { $"~/($in)" })
  let files = (
    $modified | append $untracked |
    where { $in != "~/" and $in != "~/./" } |
    str join (char newline) |
    fzf --height=60% --layout=reverse --multi --preview 'bash -c "yadm diff -- ${1/#\\~/$HOME} 2>/dev/null | delta || cat ${1/#\\~/$HOME}" _ {}'
  )
  if ($files | is-empty) { return }
  $files | lines | each { yadm add ($in | path expand) }
  yadm status --short
}

# ylo - interactive yadm log
export def ylo [] {
  yadm log --oneline --color=always |
  fzf --height=80% --layout=reverse --ansi --preview 'yadm show {1} | delta' |
  split row ' ' |
  first |
  if ($in | is-empty) { } else { yadm show $in }
}

# yd - interactive yadm diff
export def yd [] {
  let files = (
    yadm diff --name-only |
    lines |
    each { $"~/($in)" } |
    str join (char newline) |
    fzf --height=60% --layout=reverse --multi --preview 'bash -c "yadm diff -- ${1/#\\~/$HOME} | delta" _ {}'
  )
  if ($files | is-empty) { return }
  $files | lines | each { yadm diff -- ($in | path expand) } | str join "\n"
}

# yrh - interactive yadm reset HEAD (unstage)
export def yrh [] {
  let files = (
    yadm diff --cached --name-only |
    lines |
    each { $"~/($in)" } |
    str join (char newline) |
    fzf --height=60% --layout=reverse --multi --preview 'bash -c "yadm diff --cached -- ${1/#\\~/$HOME} | delta" _ {}'
  )
  if ($files | is-empty) { return }
  $files | lines | each { yadm reset HEAD ($in | path expand) }
  yadm status --short
}

# ycf - interactive yadm checkout file (discard changes)
export def ycf [] {
  let files = (
    yadm diff --name-only |
    lines |
    each { $"~/($in)" } |
    str join (char newline) |
    fzf --height=60% --layout=reverse --multi --preview 'bash -c "yadm diff -- ${1/#\\~/$HOME} | delta" _ {}'
  )
  if ($files | is-empty) { return }
  $files | lines | each { yadm checkout ($in | path expand) }
  yadm status --short
}

# yss - interactive yadm stash show
export def yss [] {
  let stash = (
    yadm stash list |
    lines |
    each {|line| ($line | split row ':' | first) + ' ' + ($line | split row ':' | skip 1 | str join ':') } |
    str join (char newline) |
    fzf --height=60% --layout=reverse --preview 'yadm stash show -p {1} | delta' --preview-window=right:60% |
    split row ' ' |
    first
  )
  if ($stash | is-empty) { return }
  yadm stash show -p $stash | delta
}

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

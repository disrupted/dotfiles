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
    [
      (git diff --name-only)
      (git ls-files --others --exclude-standard)
    ] | str join (char newline) |
    fzf --height=60% --layout=reverse --multi --preview 'bash -c "if git ls-files --error-unmatch {} &>/dev/null; then git diff --color=always {} | delta; else bat --color=always --style=header {}; fi"'
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

# glo-sk - interactive git log (skim binary version - compare performance)
export def glo-sk [] {
  let colors = if $env.IS_DARK_MODE {
    "fg:-1,bg:-1,matched:#d19a66,current:-1:b,bg+:#2c323d,current_match:#e5c07b:b,info:#828997,prompt:#e06c75,cursor:#45cdff,spinner:#e06c75,border:#4B5164"
  } else {
    "fg:-1,bg:-1,matched:#d75f00,current:-1:b,bg+:#e8e8e8,current_match:#d75f00:b,info:#878787,prompt:#d7005f,cursor:#0087af,spinner:#d7005f,border:#d0d0d0"
  }
  git log --oneline --color=always |
  ^sk --height=80% --layout=reverse --ansi --color $colors --preview 'git show {1} | delta' |
  split row ' ' |
  first |
  if ($in | is-empty) { } else { git show $in }
}

# glos - interactive git log with skim (fast, no preview in TUI)
# Shows full diff after selection - trades preview for speed
export def glos [] {
  git log --pretty=format:"%H|%h|%an|%ar|%s" -n 200
    | lines
    | each {|line|
        let parts = ($line | split row '|')
        {
          hash: $parts.0,
          short: $parts.1,
          author: $parts.2,
          date: $parts.3,
          message: $parts.4
        }
      }
    | (sk
        --height "80%"
        --format {
          $"($in.short) ($in.message) \(($in.author), ($in.date)\)"
        })
    | if ($in | is-empty) {
        return
      } else {
        git show $in.hash
      }
}

# gd - interactive git diff
export def gd [
  --staged (-s) # Show staged changes
] {
  let flags = if $staged { ["--staged"] } else { [] }
  let root = (git rev-parse --show-toplevel | str trim)
  let preview_flags = if $staged { "--staged" } else { "" }
  let preview_cmd = $"git -C '($root)' diff ($preview_flags) -- '{}' | delta"
  let files = (
    git diff --name-only ...$flags |
    fzf --height=60% --layout=reverse --multi --preview $preview_cmd
  )
  if ($files | is-empty) { return }
  $files | lines | each { |it| git diff ...$flags -- ($root | path join $it) } | str join (char newline)
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

# ya - interactive yadm add (modified files only)
export def yadd [] {
  let files = (
    yadm diff --name-only | lines | where { $in != "" } | each { $"~/($in)" } |
    str join (char newline) |
    fzf --height=60% --layout=reverse --multi --preview 'bash -c "yadm diff -- ${1/#\\~/$HOME} | delta" _ {}'
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

# dl - download a file
export def dl [url: string, output?: path] {
  if ($output == null) {
    ^wget --content-disposition $url
  } else {
    ^wget $url -O $output
  }
}

# export alias claude = bunx @anthropic-ai/claude-code@latest
# export alias codex = bunx @openai/codex@latest

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

# skim-enhanced commands (structured data aware)

# sk-ps - interactive process selector
export def sk-ps [] {
  ps
    | where pid != 0
    | sk --format { $"($in.name) \(pid: ($in.pid), cpu: ($in.cpu)%\)" }
}

# sk-kill - interactive process killer
export def sk-kill [] {
  ps
    | where pid != 0
    | sk --format { $"($in.name) \(pid: ($in.pid), cpu: ($in.cpu)%\)" }
    | kill $in.pid
}

# sk-env - browse environment variables
export def sk-env [] {
  $env
    | transpose key value
    | sk --format { $in.key }
}

# sk-history - smarter history search with structured data
export def sk-history [] {
  history
    | reverse
    | sk --format { $in.command }
}

# sk-ga - interactive git add using structured data
export def sk-ga [] {
  git status --short
    | lines
    | where { not ($in | is-empty) }
    | each {|line|
        {
          status: ($line | str substring 0..2 | str trim),
          file: ($line | str substring 3..)
        }
      }
    | sk --multi --format { $"($in.status) ($in.file)" }
    | each {|f| git add $f.file}

  git status --short
}

# sk-gsw - git branch switcher with structured preview
export def sk-gsw [] {
  git branch --all --format="%(refname:short)|%(committerdate:relative)|%(subject)"
    | lines
    | each {|line|
        let parts = ($line | split row '|')
        {
          branch: ($parts.0 | str replace 'remotes/origin/' ''),
          date: $parts.1,
          subject: $parts.2
        }
      }
    | uniq-by branch
    | sk --format { $"($in.branch) \(($in.date)\)" }
    | git switch $in.branch
}

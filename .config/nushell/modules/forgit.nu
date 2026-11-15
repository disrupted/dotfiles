# Interactive git pickers ported from wfxr/forgit (bin/git-forgit), with skim in place of fzf.
# Lists are always cwd-relative and unquoted (`core.quotePath=false`), so paths can be
# handed straight back to git from any subdirectory.

const log_format = '%C(auto)%h %s %C(dim)%cr%Creset'

def in_repo [] {
  (do { ^git rev-parse --is-inside-work-tree } | complete).exit_code == 0
}

def pick [items: list<string>, multi: bool, opts: list<string>] {
  let rows = ($items | where {|l| not ($l | is-empty) })
  if ($rows | is-empty) { return [] }
  let extra = if $multi { ['--multi'] } else { [] }
  let picked = (try { $rows | str join (char nl) | ^sk ...($extra ++ $opts) | lines } catch { [] })
  $picked | where {|l| not ($l | is-empty) }
}

def root [] {
  ^git rev-parse --show-toplevel | str trim
}

def cwd_relative [paths: list<string>] {
  let prefix = (^git rev-parse --show-prefix | str trim)
  if ($prefix | is-empty) { return $paths }
  let up = (0..<(($prefix | split row '/' | where {|x| not ($x | is-empty) } | length)) | each { '..' } | str join '/')
  $paths | each {|p|
    if ($p | str starts-with $prefix) { $p | str substring ($prefix | str length).. } else { $up + '/' + $p }
  }
}

def worktree_changes [] {
  cwd_relative (^git -C (root) -c core.quotePath=false ls-files --modified --others --exclude-standard | lines)
}

def modified_files [] {
  cwd_relative (^git -C (root) -c core.quotePath=false diff --name-only | lines)
}

def staged_files [] {
  cwd_relative (^git -C (root) -c core.quotePath=false diff --name-only --cached | lines)
}

def branch_name [line: string] {
  $line | ansi strip | str trim | str replace --regex '^[*+] ' ''
}

def local_branches [all: bool] {
  let flags = if $all { ['--all'] } else { [] }
  ^git branch --color=always ...$flags
  | lines
  | where {|l| not ($l | str trim | str starts-with '*') }
  | where {|l| not ($l | str contains ' -> ') }
  | each {|l| branch_name $l }
}

def branch_header [] {
  let current = (^git branch --show-current | str trim)
  if ($current | is-empty) { '* (HEAD detached)' } else { $"* ($current)" }
}

def sha_of [line: string] {
  $line | parse --regex '([0-9a-f]{7,40})' | get capture0 | first | default ''
}

def stash_of [line: string] {
  $line | split row ':' | first | str trim
}

def stash_preview [] {
  's=$(printf %s {} | cut -d: -f1); git stash show -p --color=always $s | delta'
}

def branch_preview [] {
  "git log {} --graph --color=always --date=relative --format='" + $log_format + "' -- | delta"
}

export def ga [...args] {
  if not (in_repo) { return }
  if ($args | any {|a| not ($a | str starts-with '-') }) {
    ^git add ...$args
    ^git status --short
    return
  }
  let files = (pick (worktree_changes) true [
    --height=60%
    --layout=reverse
    --preview 'if git ls-files --error-unmatch {} >/dev/null 2>&1; then git diff --color=always -- {}; else git diff --color=always --no-index -- /dev/null {}; fi | delta'
  ])
  if ($files | is-empty) { print 'Nothing to add.'; return }
  ^git add -- ...$files
  ^git status --short
}

export def gr [--staged (-S), --worktree (-W), ...args] {
  if not (in_repo) { return }
  let flags = ((if $staged { ['--staged'] } else { [] }) | append (if $worktree { ['--worktree'] } else { [] }))
  if ($args | any {|a| not ($a | str starts-with '-') }) {
    ^git restore ...$flags ...$args
    return
  }
  let preview_base = if $staged and $worktree { 'HEAD' } else if $staged { '--staged' } else { '' }
  let both = ($worktree or (not $staged))
  let candidates = (
    ((if $staged { staged_files } else { [] }) | append (if $both { modified_files } else { [] }) | uniq | sort)
  )
  let picked = (pick $candidates true [
    --height=60%
    --layout=reverse
    --preview $"git diff --color=always ($preview_base) -- {} | delta"
  ])
  if ($picked | is-empty) { print 'Nothing to restore.'; return }
  ^git restore ...$flags ...$args -- ...$picked
}

export def gcf [...args] {
  if not (in_repo) { return }
  if ($args | any {|a| not ($a | str starts-with '-') }) {
    ^git checkout ...$args
    return
  }
  let picked = (pick (modified_files) true [
    --height=60%
    --layout=reverse
    --preview 'git diff --color=always -- {} | delta'
  ])
  if ($picked | is-empty) { print 'Nothing to checkout.'; return }
  ^git checkout ...$args -- ...$picked
}

export def glo [...args] {
  if not (in_repo) { return }
  let picked = (pick (^git log --color=always $"--format=($log_format)" ...$args | lines) false [
    --ansi
    --no-sort
    --height=80%
    --layout=reverse
    --preview 'sha=$(printf %s {} | grep -Eo "[0-9a-f]{7,40}" | head -1); git show --color=always $sha | delta'
  ])
  if ($picked | is-empty) { return }
  let sha = (sha_of $picked.0)
  if ($sha | is-empty) { return }
  ^git show --color=always $sha | ^delta
}

export def gd [--staged (-s), ...args] {
  if not (in_repo) { return }
  let diff_flags = (if $staged { ['--staged'] } else { [] })
  let is_rev = {|a| (do { ^git rev-parse $a -- } | complete).exit_code == 0 }
  let first_rev = (if ($args | is-empty) { false } else { do $is_rev $args.0 })
  let second_rev = (if ($args | length) < 2 { false } else { do $is_rev $args.1 })
  let n_commits = (if (not $first_rev) { 0 } else if $second_rev { 2 } else { 1 })
  let commits = ($args | take $n_commits)
  let files = ($args | skip $n_commits)
  let rows = (
    ^git -C (root) -c core.quotePath=false diff --name-status ...$diff_flags ...$commits -- ...$files
    | lines
    | where {|l| not ($l | is-empty) }
    | each {|l|
      let parts = ($l | split row (char tab))
      let label = $"[($parts.0)]"
      let pad_width = (8 - ($label | str length))
      let pad = if $pad_width > 0 { '' | fill -w $pad_width -c ' ' } else { ' ' }
      $label + $pad + (($parts | skip 1) | str join '  ->  ')
    }
  )
  if ($rows | is-empty) { print 'Nothing to diff.'; return }
  let revs = ($diff_flags | append $commits | str join (char sp))
  let picked = (pick $rows false [
    --height=60%
    --layout=reverse
    --preview ("f=$(printf %s {} | cut -c9- | sed 's/.*  ->  //'); git -C " + (root) + " diff --color=always " + $revs + " -- \"$f\" | delta")
  ])
  if ($picked | is-empty) { return }
  let file = ($picked.0 | str substring 8.. | str replace --regex '.*  ->  ' '')
  ^git -C (root) diff --color=always -U10 ...$diff_flags ...$commits -- $file | ^delta
}

export def gsw [...args] {
  if not (in_repo) { return }
  if ($args | is-not-empty) {
    if ($args.0 | str starts-with '-') {
      ^git switch ...$args
    } else {
      let exists = ((do { ^git show-ref --verify --quiet $"refs/heads/($args.0)" } | complete).exit_code == 0)
      if $exists { ^git switch ...$args } else { ^git switch -c ...$args }
    }
    ^git status --short
    return
  }
  let picked = (pick (local_branches true) false [
    --no-sort
    --height=40%
    --layout=reverse
    --header (branch_header)
    --preview (branch_preview)
  ])
  if ($picked | is-empty) { return }
  let branch = (branch_name $picked.0)
  if ($branch | str starts-with 'remotes/') {
    let short = ($branch | str replace --regex '^remotes/[^/]+/' '')
    let has_local = ((do { ^git show-ref --verify --quiet $"refs/heads/($short)" } | complete).exit_code == 0)
    if $has_local {
      ^git switch $short
    } else if ((do { ^git switch --track $branch } | complete).exit_code != 0) {
      ^git switch $branch
    }
  } else {
    ^git switch $branch
  }
}

export def gbd [...args] {
  if not (in_repo) { return }
  if ($args | is-not-empty) {
    ^git branch -D ...$args
    return
  }
  let picked = (pick (local_branches false) true [
    --no-sort
    --height=40%
    --layout=reverse
    --header (branch_header)
    --preview (branch_preview)
  ])
  if ($picked | is-empty) { return }
  for branch in ($picked | each {|l| branch_name $l }) {
    ^git branch -D $branch
  }
}

export def gss [] {
  if not (in_repo) { return }
  let picked = (pick (^git stash list | lines) false [
    --no-sort
    --height=60%
    --layout=reverse
    --preview (stash_preview)
  ])
  if ($picked | is-empty) { return }
  ^git stash show -p --color=always (stash_of $picked.0) | ^delta
}

export def gsa [] {
  if not (in_repo) { return }
  let picked = (pick (^git stash list | lines) false [
    --no-sort
    --height=60%
    --layout=reverse
    --preview (stash_preview)
  ])
  if ($picked | is-empty) { return }
  ^git stash apply (stash_of $picked.0)
}

export def gcp [] {
  if not (in_repo) { return }
  let base = (^git branch --show-current | str trim)
  if ($base | is-empty) { print 'Current commit is not on a branch.'; return }
  let branch = (pick (local_branches true) false [
    --no-sort
    --height=40%
    --layout=reverse
    --header (branch_header)
    --preview (branch_preview)
  ])
  if ($branch | is-empty) { return }
  let target = (branch_name $branch.0)
  let commits = (^git log --right-only --cherry-pick --color=always --oneline $"($base)...($target)" | lines)
  let numbered = ($commits | enumerate | each {|c| $"($c.index + 1) ($c.item)" })
  let picked = (pick $numbered true [
    --ansi
    --no-sort
    --height=60%
    --layout=reverse
    --preview 'sha=$(printf %s {} | grep -Eo "[0-9a-f]{7,40}" | head -1); git show --color=always $sha | delta'
  ])
  if ($picked | is-empty) { return }
  let shas = ($picked
    | each {|l| { n: ($l | split row (char sp) | first | into int), sha: (sha_of $l) } }
    | sort-by n -r
    | get sha)
  ^git cherry-pick ...$shas
}

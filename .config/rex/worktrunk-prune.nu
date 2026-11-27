# Run by worktree_prune in init.lua. `wt step prune` only finds branches whose
# changes are in the default branch, so worktrees of PRs that upstream reworked
# while merging are found through their PR state instead.
$env.PATH = ($env.PATH | prepend ($env.HOME | path join .local/share/mise/shims))

def merged-pr-worktrees [skip: list<string>] {
    let listing = (wt list --format=json | from json)
    let repo = $"($listing.repo.forge.owner)/($listing.repo.forge.name)"
    $listing.items
    | where worktree? != null and not $it.worktree.main and $it.branch not-in $skip
    | par-each {|item|
        let pr = (gh pr list --repo $repo --head $item.branch --state all --json number,state --limit 1 | from json | get 0?)
        {branch: $item.branch, pr: $pr.number?, state: $pr.state?}
    }
    | where state == MERGED
    | select branch pr
}

def candidates [] {
    let pruned = (wt step prune --dry-run --min-age 0 --format json | from json | get branch)
    {pruned: $pruned, merged_prs: (merged-pr-worktrees $pruned)}
}

def main [--count] {
    let found = (candidates)
    if $count {
        print (($found.pruned | length) + ($found.merged_prs | length))
        return
    }
    if ($found.pruned | is-not-empty) {
        wt step prune --dry-run --min-age 0
    }
    if ($found.merged_prs | is-not-empty) {
        print $"\nWorktrees of merged PRs:"
        print ($found.merged_prs | table)
    }
    let answer = (input --numchar 1 "\nRemove these? [y/N] ")
    print ""
    if $answer not-in [y Y] { return }
    try {
        if ($found.pruned | is-not-empty) { wt step prune --min-age 0 --foreground -y }
        if ($found.merged_prs | is-not-empty) { wt remove -D --foreground -y ...$found.merged_prs.branch }
    } catch {|err|
        input --numchar 1 $"\n($err.msg). Press any key to close"
    }
}

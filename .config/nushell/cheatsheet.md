# Nushell Cheat Sheet

## Coming from bash/zsh
- `grep foo` -> `where $it =~ 'foo'` or `where name =~ 'foo'`
- `echo` -> `print`
- `cat` -> `open` (structured), `open --raw` (raw text)
- `export VAR=...` -> `$env.VAR = "..."` (permanent: `env.nu`)
- `a && b` -> `a; b` (stops on the first error)
- `$(cmd)` -> `(cmd)`
- `\` line continuation -> wrap the command in `( ... )`, newlines are allowed inside
- `"$HOME/x"` -> `$"($env.HOME)/x"`, `~` only expands unquoted or in backticks

## Pipelines (structured data)
```nu
ls | where type == "file"
ls | where size > 1mb | sort-by size -r | first 5
ls | get size | math sum
ps | where cpu > 10 | sort-by cpu -r
ps | get mem | math max
```

## Open structured data
```nu
open data.json | get key
open data.csv
open data.json | explore         # interactive viewer
```

## Your helpers
```nu
csvs file.csv    # CSV with ';' separator
tsv file.tsv     # TSV
jsonr file       # JSON, whatever the extension
yamlr file       # YAML, whatever the extension
```

## History
- Ctrl+R: history search (exact match, newest first)
- Alt+R inside it: toggle between all history and the current directory
```nu
history | where command =~ "kubectl"
```

## Git
```nu
gs          # git status -sb
gc          # git commit
gm          # switch to main branch
gp          # push + CI watch
```
Pickers from `modules/forgit.nu`: `ga`, `gr`, `gcf`, `glo`, `gd`, `gsw`, `gbd`, `gss`, `gsa`, `gcp`

## Navigation
```nu
j <query>   # zoxide top-level jump
mkcd dir    # mkdir + cd
```

## Processes and ports
```nu
ps --long | where command =~ "python"
sys mem
somo                                       # interactive: filter, inspect, kill
ports                                      # listening sockets, with the owner's cwd
ports | uniq                               # collapse the IPv4/IPv6 duplicate rows
ports | where local_port == 3000
ports --all | where state == established   # outbound connections, adds proto and remote address
ports | uniq | join (ps --long | select pid command) pid   # full argv, not just the program name
somo --json | from json                    # raw fields somo emits
```

## Replaced tools
```nu
du -d 2 | sort-by physical -r    # dust
sys disks                        # duf
http get https://example.com     # xh
open data.json | explore         # jless
glob **/*.rs | each {|f| open --raw $f | str replace -a 'old' 'new' | save -f $f }   # sad
```

## Docker
```nu
mise run docker:stop-all   # stop every container
mise run docker:prune      # stop-all, then prune images, builders, cache
```

## Misc
```nu
^ls -la                          # force the external command over the builtin
ls | input list --fuzzy "Pick"   # fuzzy selection
exec nu                          # reload config
```

## Config and setup
Edit config in `~/.dotfiles/.config/nushell`, `mise dot apply` links it into `~/.config/nushell`:
- `env.nu`: environment and PATH
- `config.nu`: everything else
- `modules/user.nu`, `modules/forgit.nu`: helpers and git pickers

A new machine needs only `mise bootstrap`. It installs nushell, makes it the login shell, links the config, and runs the `bootstrap` task, which generates the autoload files for mise, starship, zoxide, carapace and fnox in `$nu.data-dir/vendor/autoload`. Run `mise run bootstrap` to regenerate them. mise activation regenerates itself on every start.

On macOS, nu reads `~/.config/nushell` only if `XDG_CONFIG_HOME` is set before it starts. The launchd agent `dev.mise.xdg-config-home` sets it for every app at login, so restart the terminal after the first `mise bootstrap`. Shells started without it, e.g. over ssh, use the links in `~/Library/Application Support/nushell` instead, and keep their history there.

Never set `XDG_*` in `env.nu`: nu has already picked its config dir by then, so only child processes see it, and history ends up split across two directories.

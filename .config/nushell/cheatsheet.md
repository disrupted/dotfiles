# Nushell Cheat Sheet

## Basics: Zsh -> Nushell
- `ls` -> `ls` (table output)
- `grep foo` -> `where $it =~ 'foo'` or `where name =~ 'foo'`
- `cd` -> `cd`
- `pwd` -> `$env.PWD`
- `echo` -> `print`
- `cat` -> `open` (structured), `open --raw` (raw text)
- `export VAR=...` -> `$env.VAR = "..."` (in `env.nu`)

## Pipelines (structured data)
```nu
ls | where type == "file"
ls | where size > 1mb | sort-by size -r | first 5
ps | where cpu > 10 | sort-by cpu -r
```

## Open structured data
```nu
open data.json | get key
open data.csv | from csv
open data.csv --raw | from csv --separator ';'
```

## Your helpers
```nu
csvs file.csv
tsv file.tsv
jsonr file.json
yamlr file.yaml
```

## Project history
- Alt+R: project-local history (fuzzy picker)
- Ctrl+R: global history search

## Files and paths
```nu
ls | select name size modified
open file.txt --raw
save -f out.txt
pwd
$env.PWD
```

## Search and filter
```nu
history | where command =~ "kubectl"
ls | where name =~ "config"
ps | where command =~ "python"
```

## Sorting and selection
```nu
ls | sort-by modified
ls | sort-by size -r
ls | select name size
```

## Math and aggregates
```nu
ls | get size | math sum
ps | get mem | math max
```

## Git
```nu
gs          # git status -sb
gc          # git commit
gm          # switch to main branch
gp          # push + CI watch
```

## Navigation
```nu
j <query>   # zoxide top-level jump
mkcd dir    # mkdir + cd
```

## Process tools
```nu
ps          # uses procs
cpu         # sorted by cpu
mem         # sorted by mem
ram safari  # RAM usage (MB)
rams safari # live RAM usage
```

## Docker
```nu
d           # sudo docker
dc          # sudo docker compose
dcu         # pull + up -d
dexec ...   # exec with terminal size
```

## External commands
```nu
^ls -la
^git status
```

## Fuzzy selection
```nu
ls | input list --fuzzy "Pick"
```

## Environment
```nu
$env.PATH
$env.EDITOR
$env.VISUAL
$env.LESS
```

## Reload config
```nu
exec nu
```

## Config locations
- `~/.config/nushell/config.nu`
- `~/.config/nushell/env.nu`
- `~/.config/nushell/modules/user.nu`

## Setup on New Device

After pulling dotfiles with yadm, run these commands to initialize auto-generated files:

```bash
# macOS: Create symlink from Application Support to ~/.config/nushell
# (nushell on macOS defaults to ~/Library/Application Support/nushell)
rm -rf "$HOME/Library/Application Support/nushell"
ln -s ~/.config/nushell "$HOME/Library/Application Support/nushell"

# Create vendor directory
mkdir -p ~/.config/nushell/vendor

# Create login.nu (required for login shells like Ghostty/tmux)
echo "source ~/.config/nushell/env.nu" > ~/.config/nushell/login.nu

# Regenerate mise integration (machine-specific)
/opt/homebrew/bin/mise activate nu > ~/.config/nushell/vendor/mise.nu

# Generate carapace completions
mkdir -p "$(nu -c '$nu.cache-dir')"
carapace _carapace nushell > "$(nu -c '$nu.cache-dir')/carapace.nu"

# Generate starship prompt (if starship is installed)
starship init nu > ~/.config/nushell/vendor/starship.nu

# Generate zoxide integration (if zoxide is installed)
zoxide init nushell > ~/.config/nushell/vendor/zoxide.nu
```

Note: The `vendor/` directory contains auto-generated, machine-specific files and is gitignored.

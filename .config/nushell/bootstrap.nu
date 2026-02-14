# Nushell bootstrap (run once on a new machine)

const autoload = $nu.data-dir | path join "vendor" "autoload"
mkdir $autoload
starship init nu | save -f ($autoload | path join "starship.nu")
zoxide init nushell | save -f ($autoload | path join "zoxide.nu")
carapace _carapace nushell | save -f ($autoload | path join "carapace.nu")
# mise integration is intentionally maintained in ~/.config/nushell/mise.nu
# tv init nu | save -f ($autoload | path join "tv.nu")

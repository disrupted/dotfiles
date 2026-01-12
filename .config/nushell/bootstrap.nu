# Nushell bootstrap (run once on a new machine)

const autoload = $nu.data-dir | path join "vendor" "autoload"
mkdir $autoload
starship init nu | save -f ($autoload | path join "starship.nu")
zoxide init nushell | save -f ($autoload | path join "zoxide.nu")
# tv init nu | save -f ($autoload | path join "tv.nu")
mise activate nu | save -f ($autoload | path join "mise.nu")
carapace _carapace nushell | save -f ($autoload | path join "carapace.nu")

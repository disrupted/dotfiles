# Nushell bootstrap (run once on a new machine)

const autoload = $nu.data-dir | path join "vendor" "autoload"
mkdir $autoload
mise completion nu | save -f ($autoload | path join "mise.nu")
starship init nu | save -f ($autoload | path join "starship.nu")
zoxide init nushell | save -f ($autoload | path join "zoxide.nu")
carapace _carapace nushell | save -f ($autoload | path join "carapace.nu")
fnox activate nu | save -f ($autoload | path join "fnox.nu")
# mise activation is regenerated on every startup in env.nu (official setup)

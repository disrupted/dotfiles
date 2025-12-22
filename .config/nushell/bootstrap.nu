# Nushell bootstrap (run once on a new machine)

mkdir ~/.config/nushell/vendor/autoload
starship init nu | save -f ~/.config/nushell/vendor/autoload/starship.nu
zoxide init nushell | save -f ~/.zoxide.nu

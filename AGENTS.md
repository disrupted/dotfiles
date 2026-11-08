# dotfiles

Public repo; mirrors `$HOME` and is deployed by `mise dot apply` (see `.config/mise/config.toml`).

- Never add secrets, work or client-specific content. Work files go in the private `~/.dotfiles-private`, secrets in fnox.
- Edit files here, not their symlinks in `~`. New files must be `git add`ed before `mise dot apply` deploys them.
- OS-specific files go in `os/<os>/`, OS-specific mise config in `.config/mise/config.<os>.toml`.
- Comment only what wouldn't be understood six months from now. No section banners, no restating the code.
- Conventional Commits (`feat(scope): …`). Don't commit or push unless asked.

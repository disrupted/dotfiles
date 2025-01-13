local registry = {}

require 'pylance.mason'
registry['pylance'] = 'pylance.mason'
require('mason-lspconfig.mappings.server').lspconfig_to_package['pylance'] =
    'pylance'

require 'github-actions.lsp.mason'
registry['gh_actions_ls'] = 'github-actions.lsp.mason'
require('mason-lspconfig.mappings.server').lspconfig_to_package['gh_actions_ls'] =
    'gh-actions-language-server'

-- TODO
-- from https://github.com/qosmio/nvim-config/blob/cab6eba656f602cd45cc335707c2bfc44bb39a38/registry/homeassistant.lua
-- registry['homeassistant'] = 'homeassistant.mason'

return registry

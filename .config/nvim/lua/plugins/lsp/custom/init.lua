require 'pylance.mason'

local registry = {}
registry['pylance'] = 'pylance.mason'
require('mason-lspconfig.mappings.server').lspconfig_to_package['pylance'] =
    'pylance'

require('lspconfig').pylance.setup {} -- HACK: mason-lspconfig doesn't detect it

-- TODO
-- from https://github.com/qosmio/nvim-config/blob/cab6eba656f602cd45cc335707c2bfc44bb39a38/registry/homeassistant.lua
-- registry['homeassistant'] = 'homeassistant.mason'

return registry

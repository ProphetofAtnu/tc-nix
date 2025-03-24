local nvim_lsp = require('lspconfig')

nvim_lsp.nixd.setup {
  settings = {
    nixd = {
      nixpkgs = {
        expr = 'import (builtins.getFlake (toString ./.)).inputs.nixpkgs { }'
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake (toString ./.)).nixosConfigurations.base.options'
        }
      }
    }
  }
}

local nvim_lsp = require('lspconfig')

nvim_lsp.nixd.setup {
  settings = {
    nixd = {
      nixpkgs = {
        expr = 'import (builtins.getFlake (toString ./.)).inputs.nixpkgs { }'
      },
      -- disko = {
      --   expr = 'import (builtins.getFlake (toString ./.)).inputs.disko {}'
      -- },
      -- pkgs = {
      --   expr = '(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.x86_64-linux'
      -- },
      -- home_manager = {
      --   expr = '(builtins.getFlake (toString ./.)).inputs.home-manager'
      -- },
      options = {
        nixos = {
          expr = '(builtins.getFlake (toString ./.)).nixosConfigurations.vm.options'
        },
        home_manager = {
          expr = '(builtins.getFlake (toString ./.)).nixosConfigurations.vm.options.home-manager.users.type.getSubOptions []'
        }
      }
    }
  }
}

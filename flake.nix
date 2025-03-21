{
  description = "Flake for generating a thin client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      formatter.${system} = pkgs.nixfmt-classic;

      homeManagerModules.openboxConfig =
        import ./modules/hm/openboxConfigure.nix;

      nixosModules.thinClient = import ./modules/nixos/thinClient.nix;

      nixosConfigurations.base = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          self.nixosModules.thinClient
          { nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux"; }
        ];
      };

      nixosConfigurations.physical =
        self.nixosConfigurations.base.extendModules {
          modules = [
            disko.nixosModules.disko
            ./disk-config.nix
            ./hardware-configuration.nix
          ];
        };

      packages.x86_64-linux.closure = let
        dependencies = [
          self.nixosConfigurations.physical.config.system.build.toplevel
          self.nixosConfigurations.physical.config.system.build.diskoScript
          self.nixosConfigurations.physical.config.system.build.diskoScript.drvPath
          self.nixosConfigurations.physical.pkgs.stdenv.drvPath
          self.nixosConfigurations.physical.pkgs.perlPackages.ConfigIniFiles
          self.nixosConfigurations.physical.pkgs.perlPackages.FileSlurp
          (self.nixosConfigurations.physical.pkgs.closureInfo {
            rootPaths = [ ];
          }).drvPath
        ] ++ builtins.map (i: i.outPath) (builtins.attrValues self.inputs);
      in pkgs.closureInfo { rootPaths = dependencies; };

      packages.x86_64-linux.bincache = pkgs.mkBinaryCache {
        rootPaths = [ self.packages.x86_64-linux.closure ];
      };

      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        specialArgs.self = self;
        modules =
          [ ./installer.nix { nixpkgs.hostPlatform = "x86_64-linux"; } ];
      };

      packages.x86_64-linux.makeIso =
        self.nixosConfigurations.installer.config.system.build.isoImage;

      packages.x86_64-linux.runVm =
        self.nixosConfigurations.physical.config.system.build.vmWithDisko;

      packages.x86_64-linux.default = self.packages.x86_64-linux.runVm;
    };
}

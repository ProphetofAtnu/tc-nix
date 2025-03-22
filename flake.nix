{
  description = "Flake for generating a thin client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      formatter =
        forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-classic);

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

      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        specialArgs.self = self;
        modules =
          [ ./installer.nix { nixpkgs.hostPlatform = "x86_64-linux"; } ];
      };

      packages = forAllSystems (system: {
        closure = let
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
        in nixpkgs.legacyPackages.${system}.closureInfo {
          rootPaths = dependencies;
        };

        bincache = nixpkgs.legacyPackages.${system}.mkBinaryCache {
          rootPaths = [ self.packages.${system}.closure ];
        };

        makeIso =
          self.nixosConfigurations.installer.config.system.build.isoImage;

        runVm =
          self.nixosConfigurations.physical.config.system.build.vmWithDisko;

        default = self.packages.${system}.runVm;
      });

    };
}

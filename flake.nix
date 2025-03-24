{
  description = "Flake for generating a thin client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, ... }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      formatter =
        forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-classic);

      nixosModules.thinClient = import ./modules/nixos/thinClient.nix;

      nixosConfigurations = let
        base = nixpkgs.lib.nixosSystem {
          modules = [
            ./prototype.nix
            ./configuration.nix
            self.nixosModules.thinClient
            { nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux"; }
          ];
        };
        physical = self.nixosConfigurations.base.extendModules {
          modules = [ disko.nixosModules.disko ./disk-config.nix ];
        };
        installer = nixpkgs.lib.nixosSystem {
          specialArgs.self = self;
          modules = [ 
            ./prototype.nix
            ./installer.nix 
            { nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux"; }
          ];
        };
      in lib.mergeAttrs { inherit base physical installer; }
      (builtins.listToAttrs (map (module: {
        name = "${lib.removeSuffix ".nix" module}";
        value = physical.extendModules { modules = [ ./hosts/${module} ]; };
      }) (builtins.filter (lib.hasSuffix ".nix")
        (builtins.attrNames (builtins.readDir ./hosts)))));

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

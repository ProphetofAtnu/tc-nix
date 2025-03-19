{config, lib, pkgs, flake, home-manager, ...}:
let 
  cfg = config.thinClientUser;
in {
  options.thinClientUser = {
    enable = lib.mkEnableOption "Thin Client User account";
  };

  config = lib.mkIf cfg.enable {
    imports = [
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = {
               flake = flake;
            };
            home-manager.sharedModules = [ flake.homeManagerModules.openboxConfig ]; 
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.thinclient = import "${flake}/homes/home.nix";
          }
    ];
    
  };

}

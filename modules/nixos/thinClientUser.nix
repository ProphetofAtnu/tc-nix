{ config, lib, pkgs, flake, home-manager, ... }:
let cfg = config.thinClientUser;
in {
  imports = [
    home-manager.nixosModules.home-manager
    {
      home-manager.extraSpecialArgs = { flake = flake; };
      home-manager.sharedModules = [ flake.homeManagerModules.openboxConfig ];
    }
  ];
  options.thinClientUser = {
    enable = lib.mkEnableOption "Thin Client User account";
  };

  config = lib.mkIf cfg.enable {
    users.users.thinclient = {
      isNormalUser = true;
      hashedPassword = "";
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.thinclient = import "${flake}/homes/home.nix";
  };

}

{ config, lib, flake, home-manager, ... }:
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
    allowPowerControl = lib.mkEnableOption "Allow thin client user to reboot the system";
  };

  config = lib.mkIf cfg.enable {
    users.users.thinclient = {
      isNormalUser = true;
      hashedPassword = "";
    };


    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.thinclient = import "${flake}/homes/home.nix";

    services.displayManager = {
      defaultSession = "none+openbox";
      autoLogin = {
        user = "thinclient";
        enable = true;
      };
    };

    # system.userActivationScripts.test = {
    #   text = ''
    #     touch /tmp/users.$(whoami)
    #   '';


    # };


    security.sudo.extraRules = lib.mkIf cfg.allowPowerControl [
      { users = [ "thinclient" ];
        commands = [
          {command = "/run/current-system/sw/bin/systemctl reboot"; options = ["NOPASSWD"];}
          {command = "/run/current-system/sw/bin/systemctl poweroff"; options = ["NOPASSWD"];}
        ];
      }
    ];
  };

}

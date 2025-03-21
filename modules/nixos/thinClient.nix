{ config, pkgs, lib, ... }:
let
  cfg = config.thinClient;
  xinitrc = pkgs.writeTextFile {
    name = "thin-client-user-xinitrc";
    text = ''
      xset s off -dpms
    '';
  };
  xprofile = pkgs.writeTextFile {
    name = "thin-client-user-xprofile";
    text = ''
      xset s off -dpms
    '';
  };
in {
  options.thinClient = {
    enable = lib.mkEnableOption "Thin Client User account";
    allowPowerControl =
      lib.mkEnableOption "Allow thin client user to reboot the system";
  };

  config = lib.mkIf cfg.enable {
    users.users.thinclient = {
      isNormalUser = true;
      hashedPassword = "";
      uid = 1000;
    };

    services.xserver.enable = true;
    services.xserver.windowManager.openbox.enable = true;

    environment.systemPackages = with pkgs; [ remmina obconf xorg.xhost ];

    services.displayManager = {
      defaultSession = "none+openbox";
      autoLogin = {
        user = "thinclient";
        enable = true;
      };
    };

    # Runtime dependencies for service override.
    system.extraDependencies = [ xinitrc xprofile ];

    systemd.services."user@${toString config.users.users.thinclient.uid}" = {
      overrideStrategy = "asDropin";
      preStart = ''
        set -eu
        ln -sf ${xinitrc} $(${config.systemd.package}/bin/systemd-path user)/.xinitrc
        ln -sf ${xprofile} $(${config.systemd.package}/bin/systemd-path user)/.xprofile
      '';
    };

    systemd.user.services.remmina-kiosk = {
      unitConfig = {
        Description = "Remmina kiosk autostart service";
        ConditionUser = "${toString config.users.users.thinclient.uid}";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.remmina}/bin/remmina";
        RestartSec = "1s";
        Restart = "always";
      };
      wantedBy = [ "graphical-session.target" ];
    };

    environment.etc = {
      "xdg/openbox/rc.xml" = { source = ./thinClientRc.xml; };

      "xdg/openbox/menu.xml" = { source = ./thinClientMenu.xml; };
    };

    security.sudo.extraRules = lib.mkIf cfg.allowPowerControl [{
      users = [ "thinclient" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl reboot";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl poweroff";
          options = [ "NOPASSWD" ];
        }
      ];
    }];
  };
}

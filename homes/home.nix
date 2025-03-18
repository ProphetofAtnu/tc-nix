{ config, pkgs, home, ... }: {
  # imports = [  ];
  # imports = [ self.homeManagerModules.openboxConfig ];

  home.username = "thinclient";
  home.homeDirectory = "/home/thinclient";
  home.file.".xinitrc" = {
    text = ''
      xset s off -dpms
    '';
  };
  home.file.".xprofile" = {
    text = ''
      xset s off -dpms
    '';
  };

  systemd.user.services.remmina-kiosk = {
    Install = { WantedBy = [ "default.target" ]; };
    Unit = { Description = "Remmina kiosk autostart service"; };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.remmina}/bin/remmina";
      RestartSec = "1s";
      Restart = "always";
    };
  };

  openboxConfigure.enable = true;

  home.stateVersion = "24.11";
}

{ config, pkgs, home, flake, ... }: {
  imports = [ ../modules/openboxConfigure.nix ];

  home.packages = [ pkgs.obconf pkgs.remmina ];

  home.username = "thinclient";
  home.homeDirectory = "/home/thinclient";
  home.file.".xinitrc" = {
    text = ''
      xset -dpms
      xset s noblank
    '';
  };
  home.file.".xprofile" = {
    text = ''
      xset -dpms
      xset s noblank
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
  programs.bash.enable = true;

  openboxConfigure.enable = true;

  home.stateVersion = "24.11";
}

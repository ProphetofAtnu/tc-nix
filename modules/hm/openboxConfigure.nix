{ lib, pkgs, config, flake, home, ... }:
let cfg = config.openboxConfigure;
in {
  options.openboxConfigure = {
    enable = lib.mkEnableOption "Openbox Custom Configurations";

  };

  config = lib.mkIf cfg.enable {
    home.file.".config/openbox/rc.xml" = {
      # source = "${flake}/configs/openbox/rc.xml";
      source = "${flake}/configs/openbox/rc.xml";
    };
    home.file.".config/openbox/menu.xml" = {
      # source = "${flake}/configs/openbox/menu.xml";
      source = "${flake}/configs/openbox/menu.xml";
    };

  };
}

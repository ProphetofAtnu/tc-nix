{ lib, ... }:

{
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIDtTbCP2ssWgSwhRxTyAG4+FuTsQLEkh93CaZpq9lQC DEFAULT"
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.enableIPv6 = lib.mkDefault false;
  networking.useDHCP = lib.mkDefault true;

  services.openssh.enable = true;
}

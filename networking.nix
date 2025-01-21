{ config, lib, nixpkgs, pkgs, ... }:

{
  networking.useDHCP = false;
  networking.interfaces.enp0s29f1.ipv4.addresses = [{
    address = "128.0.0.169";
    prefixLength = 24;
  }];
  networking.defaultGateway = "128.0.0.1";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
}

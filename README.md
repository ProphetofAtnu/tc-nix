# Notes for Others

If you're hacking on this yourself, replace the SSH public key for root in `configuration.nix` and `installer.nix` with your own to allow remote login.

# Run the thin client as a VM

```sh
nix run '.#runVm' # or just "nix run"
```

# Installer

A custom installer for the thin client configuration defined by this flake that supports offline installations.

**Be warned!** It takes an eternity to build and the resulting iso is ~8GiB.

## Build the installer as an ISO

```sh
nix build '.#makeIso'
```

## Using the Installer

After booting the installer, the command `unattended-install` will be available. Needs to be run by root or with sudo.

```sh
unattended-install --target /dev/[disk] -- [optional disko-install flags]
```

`unattended-install` is a simple a wrapper for `disko-install`.

See [disko-install](https://github.com/nix-community/disko/blob/master/docs/disko-install.md).

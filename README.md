# Notes

If you're the person I sent this to, you can run the config as a VM with:

```sh
nix run 'nixpkgs#nixos-generators' -- --run -f vm --flake '.#vm'
```

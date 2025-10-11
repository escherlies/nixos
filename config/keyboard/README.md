# QMK

https://config.qmk.fm/

## Flashing

```sh
# Use 25.05 as of 2025-10-11 qmk is broken on unstable
nix shell nixpkgs/nixos-25.05#qmk --command qmk flash keebio_nyquist_rev3_enryco_5.hex
```

## Layout

![alt text](my_keymap.svg)

via https://github.com/caksoylar/keymap-drawer
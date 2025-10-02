![nixos](./screenshot.png)

# My NixOS Configurations

This repository contains my personal NixOS configurations, managed using Nix Flakes.

## Structure

```
.
├── flake.nix          # Main Nix Flake file
├── machines/            # Machine-specific NixOS configurations
│   ├── desktop/
│   ├── laptop/
│   └── web-services/
├── home/                # Home Manager configurations
│   ├── default.nix
│   └── ...
├── modules/             # Custom NixOS modules
│   ├── core.nix
│   └── ...
├── config/              # Other configurations (e.g., macOS)
│   └── darwin/
└── scripts/             # Utility scripts
    └── ...
```

## Usage

These configurations are primarily for my personal use. However, feel free to browse the code and adapt any parts that you find useful for your own NixOS or Home Manager setup.

## Quirks

### xkb options wont apply

Currently setting it manually when i change keyboards.

```sh
# On desktop and laptop w/ external keyboard
gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:swap_lwin_lctl']"

# On laptop for internal keyboard
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:backspace','ctrl:swap_lalt_lctl_lwin']"
```

<strike>
Fix: reset gnome and reboot
```
gsettings reset org.gnome.desktop.input-sources xkb-options
gsettings reset org.gnome.desktop.input-sources sources
reboot
```

https://discourse.nixos.org/t/problem-with-xkboptions-it-doesnt-seem-to-take-effect/5269/2

or put it int dconf."org/gnome/desktop/input-sources" https://github.com/jtojnar/nixfiles/blob/0d27214ee265766e25df0668514594835ea31814/hosts/evan/configuration.nix#L119

</strike>


## License

This repository is licensed under the [MIT License](LICENSE).
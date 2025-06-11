![nixos](https://socialify.git.ci/escherlies/nixos/image?custom_description=Enrico%27s+nix+config+files&description=1&font=KoHo&language=1&logo=https%3A%2F%2Fpablo.tools%2Fnixoscolorful.svg&name=1&owner=1&pattern=Plus&theme=Auto)


# My NixOS Configurations

This repository contains my personal NixOS configurations, managed using Nix Flakes.

## Structure

```
.
├── flake.nix          # Main Nix Flake file
├── machines/            # Machine-specific configurations
│   ├── desktop/
│   └── laptop/
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

## License

This repository is licensed under the [MIT License](LICENSE).
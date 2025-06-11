_default:
  @just --list

desktop:
  sudo nixos-rebuild switch --flake .#desktop

laptop:
  sudo nixos-rebuild switch --flake .#laptop
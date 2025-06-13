rebuild:
  sudo nixos-rebuild switch --flake .#$(hostname)

# Initial rebuild, after that, hostname follows flake name
rebuildt target:
  sudo nixos-rebuild switch --flake .#{{target}}

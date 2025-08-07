rebuild:
  sudo nixos-rebuild switch --flake .#$(hostname)

# Initial rebuild, after that, hostname follows flake name
rebuildt target:
  sudo nixos-rebuild switch --flake .#{{target}}


rebuild-laptop-from-host:
  nixos-rebuild switch --flake .#laptop --target-host root@192.168.178.98
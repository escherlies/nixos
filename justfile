rebuild:
  sudo nixos-rebuild switch --flake .#$(hostname)

# Initial rebuild, after that, hostname follows flake name
rebuildt target:
  sudo nixos-rebuild switch --flake .#{{target}}


rebuild-laptop-from-host:
  nixos-rebuild switch --flake .#laptop --target-host root@192.168.178.98

rebuild-framework:
  nixos-rebuild switch --flake .#framework --target-host root@192.168.178.119 --build-host root@192.168.178.119 --no-reexec


rebuild-desktop:
  nixos-rebuild switch --flake .#desktop --target-host root@192.168.178.87 --build-host root@192.168.178.87 --no-reexec


rebulid-home-server:
  nixos-rebuild switch --flake .#home-server --target-host root@192.168.178.134
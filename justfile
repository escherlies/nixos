rebuild:
    sudo nixos-rebuild switch --flake .#$(hostname)

rebuild-laptop:
    nixos-rebuild switch --flake .#laptop --target-host root@192.168.178.98

rebuild-framework:
    nixos-rebuild switch --flake .#framework --target-host root@192.168.178.119

rebuild-desktop:
    nixos-rebuild switch --flake .#desktop --target-host root@192.168.178.87

rebulid-home-server:
    nixos-rebuild switch --flake .#home-server --target-host root@192.168.178.134

rebulid-vpn-gateway:
    nixos-rebuild switch --flake .#vpn-gateway --target-host root@65.21.50.151

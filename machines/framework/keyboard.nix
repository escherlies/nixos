{ config, pkgs, ... }:

{
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            capslock = "backspace";
            leftalt = "leftcontrol";
            leftcontrol = "leftmeta";
            leftmeta = "leftalt";
            # rightalt = "layer(nav)";
          };

          # nav = {
          #   h = "left";
          #   j = "down";
          #   k = "up";
          #   l = "right";
          # };
        };
      };
    };
  };
}

{ config, pkgs, ... }:

{
  services.keyd = {
    enable = true;
    keyboards = {
      framework = {
        ids = [ "0001:0001" ];
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

      nyquist = {
        ids = [ "cb10:3156" ];
        settings = {
          main = {
            leftcontrol = "leftmeta";
            leftmeta = "leftcontrol";
          };
        };
      };
    };
  };
}

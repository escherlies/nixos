{ ... }:

{

  services.keyd =
    let
      common = {
        leftalt.backspace = "delete";
      };
    in
    {
      enable = true;
      keyboards = {
        framework = {
          ids = [ "0001:0001" ];
          settings = {
            main = {
              capslock = "overload(nav, backspace)";
              leftalt = "leftcontrol";
              leftcontrol = "leftmeta";
              leftmeta = "leftalt";
              rightcontrol = "rightalt";
              # rightalt = "layer(nav)";
            };

            nav = {
              h = "left";
              j = "down";
              k = "up";
              l = "right";
            };
          }
          // common;
        };

        nyquist = {
          ids = [ "cb10:3156" ];
          settings = {
            main = {
              leftcontrol = "leftmeta";
              leftmeta = "leftcontrol";
            };
          }
          // common;
        };
      };
    };
}

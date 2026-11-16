{ ... }:

{

  services.keyd =
    let
      sharedKeymaps = import ../../modules/keyd-keymaps.nix;
      common = sharedKeymaps.commonSettings;
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
              # leftmeta = "oneshot(leftalt)";
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

        nyquist = sharedKeymaps.nyquist;
        dz60 = sharedKeymaps.dz60;
      };
    };
}

# keyd keymaps used by more than one machine. This file is plain data and not a
# NixOS module: a machine imports it and assigns the attributes it wants to
# services.keyd.keyboards, so a machine only gets the keyboards it names.
let
  commonSettings = {
    leftalt.backspace = "delete";
  };
in
{
  inherit commonSettings;

  dz60 = {
    ids = [ "445a:2260" ];
    settings = {
      main = {
        capslock = "overload(nav, backspace)";
        leftalt = "leftcontrol";
        leftcontrol = "leftmeta";
        leftmeta = "leftalt";
        rightcontrol = "rightalt";
      };

      nav = {
        h = "left";
        j = "down";
        k = "up";
        l = "right";
        u = "pageup";
        d = "pagedown";
      };
    }
    // commonSettings;
  };
}

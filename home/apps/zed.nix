{ lib, osConfig, ... }:
let
  isFramework = osConfig.networking.hostName == "framework";
in
{
  programs.zed-editor.enable = true;

  home.sessionVariables = lib.mkIf isFramework {
    EDITOR = "zeditor";
    VISUAL = "zeditor";
  };
}

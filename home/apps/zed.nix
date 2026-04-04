{ lib, osConfig, ... }:
let
  isFramework = osConfig.networking.hostName == "framework";
  zedDesktopEntry = "dev.zed.Zed.desktop";
  sourceMimeTypes = [
    "text/plain"
    "text/markdown"
    "text/x-python"
    "text/x-shellscript"
    "text/x-c"
    "text/x-c++src"
    "text/x-csharp"
    "text/x-java"
    "text/x-go"
    "text/x-rust"
    "text/x-php"
    "text/x-typescript"
    "text/x-java-source"
    "text/x-kotlin"
    "text/x-scala"
    "text/x-lua"
    "text/x-ruby"
    "text/x-swift"
    "text/x-dart"
    "text/x-nix"
    "text/javascript"
    "text/jsx"
    "text/tsx"
    "application/javascript"
    "application/json"
    "application/toml"
    "text/x-toml"
    "application/xml"
    "text/html"
    "text/css"
    "text/x-sql"
    "application/x-yaml"
    "text/x-yaml"
  ];
in
{
  programs.zed-editor.enable = true;

  home.sessionVariables = lib.mkIf isFramework {
    EDITOR = "zeditor";
    VISUAL = "zeditor";
  };

  xdg.mimeApps = lib.mkIf isFramework {
    enable = true;
    defaultApplications = builtins.listToAttrs (
      map (mime: {
        name = mime;
        value = [
          zedDesktopEntry
          "zed.desktop"
        ];
      }) sourceMimeTypes
    );
  };
}

{ pkgs, ... }:
let
  executablePath = "${pkgs.brave}/bin/brave";
in
{
  environment.systemPackages = [
    pkgs.brave
  ];

  environment.sessionVariables = {
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH = executablePath;
    PLAYWRIGHT_MCP_EXECUTABLE_PATH = executablePath;
  };
}

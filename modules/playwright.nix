{ pkgs, ... }:
let
  browsers =
    (builtins.fromJSON (builtins.readFile "${pkgs.playwright-driver}/browsers.json")).browsers;
  chromium-rev = (builtins.head (builtins.filter (x: x.name == "chromium") browsers)).revision;
  executablePath = "${pkgs.playwright-driver.browsers}/chromium-${chromium-rev}/chrome-linux64/chrome";
in
{
  environment.systemPackages = [
    pkgs.playwright-driver.browsers
  ];

  environment.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH = executablePath;
    PLAYWRIGHT_MCP_EXECUTABLE_PATH = executablePath;
  };
}

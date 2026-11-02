{ config, lib, ... }:

with lib;

{
  options.modules.gaming = {
    enable = mkEnableOption "gaming support including Steam, gamescope, and gamemode";
  };

  config = mkIf config.modules.gaming.enable {
    # Enable Steam services
    programs.steam.enable = true;
    programs.steam.gamescopeSession.enable = true;

    programs.gamemode.enable = true;

    # gamemode.rules grants its governor, GPU, CPU-core and procsys helpers only
    # to members of this group, and the polkit defaults for them are "no".
    # Outside it, `gamemoded -t` fails with "Governor was not set to performance".
    users.users.enrico.extraGroups = [ "gamemode" ];
  };
}

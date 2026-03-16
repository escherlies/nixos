{
  # https://github.com/wwmm/easyeffects
  # And to configuration.nix: programs.dconf.enable = true;
  services.easyeffects.enable = true;

  # EasyEffects output presets
  # DT990-Pro-AutoEQ-Techno: AutoEQ (oratory1990) with +2 dB sub-bass shelf for techno
  xdg.configFile = {
    "easyeffects/output/DT990-Pro-AutoEQ-Techno.json".source =
      ./easyeffects/DT990-Pro-AutoEQ-Techno.json;
    "easyeffects/output/DT990-Pro-BlackEdition-AutoEQ-Techno.json".source =
      ./easyeffects/DT990-Pro-BlackEdition-AutoEQ-Techno.json;
    "easyeffects/output/DT990-Pro-BlackEdition-AutoEQ-Techno-adjusted.json".source =
      ./easyeffects/DT990-Pro-BlackEdition-AutoEQ-Techno-adjusted.json;
    "easyeffects/output/Eris-E8-Techno.json".source = ./easyeffects/Eris-E8-Techno.json;
    "easyeffects/output/Perfect-EQ.json".source = ./easyeffects/Perfect-EQ.json;
  };
}

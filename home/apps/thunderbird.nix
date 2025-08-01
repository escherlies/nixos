{ pkgs, ... }:
{
  programs.thunderbird.enable = true;
  programs.thunderbird.profiles.default = {
    isDefault = true;
  };

  accounts.email.maildirBasePath = "Mail";
}

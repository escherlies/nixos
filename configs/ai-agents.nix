{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    qwen-code
    crush
    aichat
    gemini-cli
    file
  ];

}

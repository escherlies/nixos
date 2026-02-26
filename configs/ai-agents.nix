{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    qwen-code
    crush
    aichat
    claude-code
    opencode
    gemini-cli
  ];

}

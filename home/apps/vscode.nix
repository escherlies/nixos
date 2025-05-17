{ pkgs, ... }:
{
  programs.vscode.enable = true;
  programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
    # Languages
    jnoortheen.nix-ide
    nefrob.vscode-just-syntax
    elmtooling.elm-ls-vscode
    redhat.vscode-yaml
    bradlc.vscode-tailwindcss

    # Tooling
    usernamehw.errorlens
    eamodio.gitlens

    # Themes
    catppuccin.catppuccin-vsc

    # Markdown
    yzhang.markdown-all-in-one
    yzane.markdown-pdf
    bierner.markdown-mermaid
    bierner.markdown-preview-github-styles

    # Agents
    saoudrizwan.claude-dev
    rooveterinaryinc.roo-cline

    # Misc
    adpyke.codesnap

    # Dependencies
    hbenl.vscode-test-explorer # Elm
    ms-vscode.test-adapter-converter # Elm

    # TODO: Add to nixpkgs https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/editors/vscode/extensions
    # jameslan.yaclock
    # gxl.git-graph-3
    # alekangelov.alek-kai-theme
    # mathematic.vscode-pdf
    # liangqin.quick-notes
  ];
}

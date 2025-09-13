{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    functions = {
      __fish_command_not_found_handler = {
        body = "echo Did not find command $argv[1]";
        onEvent = "fish_command_not_found";
      };

      # # Create and change to a directory
      mkdircd = ''mkdir -p -- "$1" && cd -- "$1"'';

      fish_greeting = "";

      ai_commit =
        let
          prompt = builtins.readFile ../../config/commit.md;
        in
        ''git diff --staged | aichat -c ${builtins.toJSON prompt} | copy'';

      # Interactively lists all projects in ~/Developer and executes nix develop or prompts to select a nix dev shell
      dev = ''
        set project ""
        set nix_target ""

        # Parse arguments
        if test (count $argv) -gt 0
            set project $argv[1]
            if test (count $argv) -gt 1
                set nix_target $argv[2]
            end
            
            if not test -d "$HOME/Developer/$project"
                echo "Project '$project' not found in ~/Developer/"
                return 1
            end
        else
            # Use fzf to select project with preview showing available shells
            set project (ls ~/Developer/ | fzf \
                --prompt="🔍 Select project: " \
                --height=100% \
                --border=rounded \
                --preview="if test -f ~/Developer/{}/flake.nix; echo '📦 Available shells:' && cd ~/Developer/{} && nix eval --json .#devShells.(nix eval --raw --impure --expr builtins.currentSystem) --apply builtins.attrNames | jq -r .[] 2>/dev/null || echo 'No shells found'; else; echo 'No flake.nix found'; end && echo && echo '📊 Git status:' && cd ~/Developer/{} && git status 2>/dev/null | head -10 || echo 'Git status unavailable' && echo && echo '📁 Files:' && ${pkgs.eza}/bin/eza -1 --group-directories-first --icons ~/Developer/{}" \
                --preview-window=right:50%)
            if test -z "$project"
                return
            end
        end

        cd "$HOME/Developer/$project"

        # Interactive shell selection if no target specified
        if test -z "$nix_target" -a -f "flake.nix"
            set shells (nix eval --json .#devShells.(nix eval --raw --impure --expr builtins.currentSystem) --apply builtins.attrNames | jq -r .[] 2>/dev/null)
            
            if test (count $shells) -gt 0
                # If there's only one shell, use it directly without prompting
                if test (count $shells) -eq 1
                    set nix_target $shells[1]
                else
                    # Use the shells directly from the command, don't add "default"
                    set chosen_shell (printf "%s\n" $shells | fzf \
                        --prompt="📦 Select shell: " \
                        --height=30% \
                        --border \
                        --header="Available development shells")
                    
                    if test -n "$chosen_shell"
                        set nix_target $chosen_shell
                    end
                end
            end
        end

        # Execute nix develop
        if test -n "$nix_target"
            echo "🚀 Starting $project with nix develop .#$nix_target..."
            nix develop ".#$nix_target"
        else
            echo "🚀 Starting $project with nix develop..."
            nix develop
        end'';
    };

    shellAbbrs = {

      o = "open";
      q = "exit";
      v = "nvim";
    };

    shellAliases = rec {

      # Eza ls replacement
      ls = "${pkgs.eza}/bin/eza -1 --group-directories-first --icons";
      l = "${ls}";
      ll = "${ls} -lbF --git --color-scale";
      la = "${ls} -lbhgmua@ --color-scale --git";
      lt = "${ls} --tree --level=2";

      # Git
      gs = "${pkgs.git}/bin/git status";
      # git diff --no-ext-diff

      # Other
      lsblk = "lsblk -o name,mountpoint,label,size,type,uuid";

      qr = "${pkgs.qrencode}/bin/qrencode -t utf8 -o-";

      weather = "${pkgs.curl}/bin/curl -4 http://wttr.in/Berlin";

      zzz = "systemctl suspend";

      copy = "wl-copy";

      nd = "nix develop -c $SHELL";
      day = "lookandfeeltool -a org.kde.breeze.desktop";
      night = "lookandfeeltool -a org.kde.breezedark.desktop";
    };
  };
}

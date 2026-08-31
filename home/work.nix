{pkgs, ...}: let
  # Status-line row naming the local dev instances running from *this* worktree.
  # Dependencies are pinned here rather than trusted to be on the status line's
  # inherited PATH (coreutils for readlink/sort), and the script is shellchecked
  # at build time.
  claudeStatusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [pkgs.jq pkgs.git pkgs.coreutils];
    text = builtins.readFile ./claude/statusline.sh;
  };
in {
  home.packages = with pkgs; [
    agent-browser
    awscli2
    bun
    claudeStatusline
    # ghostscript
    imagemagick
    kubectl
    mkcert
    mongosh
    nssTools
    openssl
    pm2
    python3
    sqlite
    yarn
    zip
  ];

  programs.zsh = {
    initContent = ''
      export GS4JS_HOME=${pkgs.ghostscript}/lib
    '';
    shellAliases = {
      ta = "terragrunt run-all apply --terragrunt-non-interactive --terragrunt-disable-bucket-update --terragrunt-working-dir";
      tp = "terragrunt run-all plan --terragrunt-non-interactive --terragrunt-disable-bucket-update --terragrunt-working-dir";
      tdel = "find . -name '.terra*' -type d -print | xargs rm -rf";

      pk = "pm2 kill";
      pst = "pm2 start";
      pl = "pm2 log";
      pw = "export WORKTREE=$(ls ~/Code/qwilr | fzf)";

      wtsu = "f() { npx nodemon --ext ts,tsx --exec \"yarn test:single-unit $1\" };f";

      mongo = "mongosh";
    };
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig = {
      settings = {
        trusted_config_paths = ["~/Code"];
      };
    };
  };

  # Qwilr's private Claude Code plugin marketplace (github.com/qwilr/agent-skills).
  # Nix never fetches it — this is just JSON in ~/.claude/settings.json, and Claude
  # Code clones the repo itself over ssh (its own autoUpdate keeps it current), so
  # no sha256 to bump and no impure fetch. Needs qwilr org read access; on a fresh
  # machine the entry sits inert until git credentials exist, then starts working
  # with no config change. Deliberately not programs.claude-code.marketplaces —
  # that option can't express a github source and would take over
  # ~/.claude/plugins/known_marketplaces.json as a read-only store symlink,
  # clobbering the CLI's own marketplace state.
  programs.claude-code.settings = {
    extraKnownMarketplaces = {
      qwilr-agent-skills.source = {
        source = "github";
        repo = "qwilr/agent-skills";
      };
    };
    enabledPlugins = {
      "engineering@qwilr-agent-skills" = true;
    };

    # PM2 is a single per-user daemon and instance numbers are global, so
    # `pm2 list` can't tell you which checkout an i{N} belongs to. This renders
    # its own row (the built-in branch/PR footer is separate state) and stays
    # silent outside checkouts that have local/pm2.config.js. refreshInterval is
    # honoured, so an instance started mid-turn shows up within ~10s without a
    # new message.
    statusLine = {
      type = "command";
      command = "${claudeStatusline}/bin/claude-statusline";
      refreshInterval = 10;
    };
  };
}

#!/usr/bin/env bash
# claude-overseer — see at a glance which Claude Code sessions need you.
#
# Claude Code hooks stamp each pane with @claude_state (working|needs_input) via
# scripts/state; this plugin surfaces that:
#
#   * scripts/status — a catppuccin-styled status-right segment (a peach robot
#     bubble with a count) that appears only when sessions are waiting. Place it
#     in your status-right yourself, e.g.:
#         set -ag status-right "#(/path/to/claude-overseer/scripts/status)"
#   * scripts/menu   — an fzf picker of all Claude panes (with a live preview),
#     bound to M-i below; Enter jumps to the chosen pane.
#
# The hooks that drive scripts/state are configured in Claude Code's settings
# (see programs.claude-code.settings.hooks in home/default.nix).

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Keep the status badge responsive.
tmux set-option -g status-interval 5

# M-i: open the session picker.
tmux bind-key -n M-i display-popup -E -w 80% -h 70% "$CURRENT_DIR/scripts/menu"

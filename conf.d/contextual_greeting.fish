# fish-contextual-greeting | Copyright (C) 2022 eth-p
# Repository: https://github.com/eth-p/fish-contextual-greeting
# =============================================================================
#
#   This init script will hook the default `fish_greeting` function to display
#   different, customizable greetings for different contexts:
#
#    * Within `tmux`.
#    * Within an IDE terminal.
#    * When connected through SSH.
#
#   In addition, it detects if the `fish` instance is the top-level shell.
#
# =============================================================================

if not set --query contextualgreeting_order
	set -g contextualgreeting_order 'ssh' 'ide' 'tmux' 'fish'
end

if not set --query contextualgreeting_prefix
	set -g contextualgreeting_prefix 'greeting_for_'
end

if not set --query contextualgreeting_redraw
	set -g contextualgreeting_redraw false
end

# -----------------------------------------------------------------------------
# Context Detection:
# -----------------------------------------------------------------------------
set -l contexts fish

# IDE: VS Code
if [ -n "$VSCODE_IPC_HOOK_CLI" ];  set -a contexts ide vscode; end

# SSH:
if [ -n "$SSH_CONNECTION" ];       set -a contexts ssh; end
if [ -n "$SSH_CLIENT" ];           set -a contexts ssh; end

# Tmux:
if [ -n "$TMUX" ];                 set -a contexts tmux; end

# -----------------------------------------------------------------------------
# Top-level Detection:
# -----------------------------------------------------------------------------

set -g __contextualgreeting_toplevel true

# Detect if not running from top-level shell.
if [ "$SHLVL" != "1" ]
	set __contextualgreeting_toplevel false
end

# Detect if there's already a tmux pane or window. 
set -l tmux_windows (tmux list-windows -F '#{window_panes}' 2>/dev/null | string join ' + ')
if test -n "$tmux_windows" && test "$tmux_windows" != "1"
	set __contextualgreeting_toplevel false
end


# -----------------------------------------------------------------------------
# Setup:
# -----------------------------------------------------------------------------

# De-duplicate the contexts and set the global variable.
set -g __contextualgreeting_contexts
set -l context
for context in $contexts
	if not contains -- "$context" $__contextualgreeting_contexts
		set -a __contextualgreeting_contexts "$context"
	end
end

# Copy the user's fish_greeting to `contextualgreeting_fish`, if it hasn't
# already been defined. This will skip the greeting if it's the fish default.
set -l greeting_file (functions fish_greeting --details --verbose | head -n1)
if not string match --quiet "*/share/fish/functions/fish_greeting.fish" -- "$greeting_file"
	if not functions --query "$contextualgreeting_prefix"fish
		functions --copy fish_greeting "$contextualgreeting_prefix"fish
	end
end

# Create a function for calling the greetings.
function fish_greeting
	# The fish_greeting function has been redefined to support contextual greetings.
	# If you are looking for the original greeting function, you can run
	# `funced contextualgreeting_fish`.
	contextual_greeting greet
end


# -----------------------------------------------------------------------------
# Redrawable Greeting Support:
# -----------------------------------------------------------------------------

# Create a function for re-calling the greetings whenever the terminal is resized.
function __contextualgreeting_redraw \
	--description='listens for a change in the terminal size and redraws the greeting' \
	--on-variable='LINES' --on-variable='COLUMNS'
	if test $contextualgreeting_redraw != "true"
		return 1
	end

	printf "\x1B[2J"   # Clear the terminal.
	printf "\x1B[3J"   # Clear the scrollback buffer.
	printf "\x1B[H"    # Move cursor to the top-left of the terminal.

	contextual_greeting greet
	return 0
end

function __contextualgreeting_disable_redraw \
	--description='disables contextual-greeting redrawing' \
	--on-event='fish_preexec'
	functions -e __contextualgreeting_redraw
	functions -e __contextualgreeting_disable_redraw
end


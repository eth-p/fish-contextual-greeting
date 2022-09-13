# fish-contextual-greeting | Copyright (C) 2022 eth-p
# Repository: https://github.com/eth-p/fish-contextual-greeting
# =============================================================================

function contextual_greeting --description "Print the contextual greetings"
	argparse -i 'help' 'is-toplevel' -- $argv || return 1

	# Handle options.
	if test -n "$_flag_is_toplevel"
		set argv "is-toplevel"
	end

	# Help.
	if test -n "$_flag_help" || not count $argv >/dev/null
		echo "fish-contextual-greeting"
		echo "https://github.com/eth-p/fish-contextual-greeting"
		echo ""
		echo "SUBCOMMANDS:"
		echo "    contextual_greeting contexts  : print the active contexts"
		echo "    contextual_greeting greet     : print the greeting"
		echo "    contextual_greeting skip      : (when called within an event handler) skips the greeting"
		echo ""
		echo "CONFIG:"
		echo '    $contextualgreeting_order    : the order of greetings displayed'
		echo '    $contextualgreeting_prefix   : the prefix for greeting functions'
		echo '    $contextualgreeting_redrew   : redraw the greeting if no commands have been run'
		echo ""
		echo "GREETINGS:"
		echo "Define the following functions to create greetings."
		echo ""
		echo "    function ""$contextualgreeting_prefix""ssh          : when connected through SSH"
		echo "    function ""$contextualgreeting_prefix""ide          : when using an IDE terminal"
		echo "    function ""$contextualgreeting_prefix""tmux         : when running under tmux"
		echo "    function contextual_greeting:pre   : called before all other greetings"
		echo "    function contextual_greeting:post  : called after all other greetings"
		echo ""
		echo "Inside greeting functions, you can run `contextual_greeting --is-toplevel` to"
		echo "check that the shell instance is not nested."
		return 1
	end

	switch "$argv[1]"

	# Function: contextual_greeting is-toplevel
	# Returns `0` if the shell instance is the top-most shell.
	case "is-toplevel"
		test "$__contextualgreeting_toplevel" = "true"
		return $status

	# Function: contextual_greeting contexts
	# Prints the active contexts.
	case "contexts"
		printf "%s\n" $__contextualgreeting_contexts
		return 0

	# Function: contextual_greeting greet
	# Displays the greetings for the active contexts.
	case "greet"
		set -l context
		set -l contexts_seen
		set -l contexts_to_call

		# Find the greetings in order.
		for context in $contextualgreeting_order
			if contains -- "$context" $__contextualgreeting_contexts
				set -a contexts_seen "$context"
				set -l context_function "$contextualgreeting_prefix$context"
				if functions --query "$context_function"
					set -a contexts_to_call "$context $context_function"
				end
			end
		end

		# Find the remaining greetings.
		for context in $__contextualgreeting_contexts
			if not contains -- "$context" $contexts_seen
				set -l context_function "$contextualgreeting_prefix$context"
				if functions --query "$context_function"
					set -a contexts_to_call "$context $context_function"
				end
			end
		end

		# Return early if there's no greetings to call.
		if not count $contexts_to_call >/dev/null
			return 1
		end

		# Call the pre hook.
		if functions --query contextual_greeting:pre
			contextual_greeting __call_greeting \
				"hook:pre" contextual_greeting:pre
		end

		# Call the greeting functions.
		for context in $contexts_to_call
			contextual_greeting __call_greeting (
				string split -- ' ' "$context"
			)
		end

		# Call the post hook.
		if functions --query contextual_greeting:post
			contextual_greeting __call_greeting \
				"hook:pre" contextual_greeting:post
		end


	# Function: contextual_greeting skip
	# Skip printing the next greeting message.
	# This must be called from within a `contextual_greeeting` handler.
	case "skip"
		if test -z "$__contextualgreeting_call_state"
			echo "contextual_greeting skip: must be called from within `contextual_greeting` event handler"
			echo
			echo "function example_handler --on-event contextual_greeting"
			echo "  if test $argv[1] = 'ssh'"
			echo "    contextual_greeting skip"
			echo "  end"
			echo "end"
			return 1
		end

		set -g __contextualgreeting_call_state 'skip'


	# INTERNAL FUNCTION: contextual_greeting __call_greeting
	# Call a greeting function, emitting the event and handling 'skip'
	case "__call_greeting"
		set -l context_to_call $argv[2]
		set -l function_to_call $argv[3]

		# Emit the event to allow for the greeting to be intercepted.
		set -g __contextualgreeting_call_state 'active'
		emit contextual_greeting "$context_to_call" "$function_to_call"

		# If the greeting hasn't been intercepted, run the greeting function.
		if test "$__contextualgreeting_call_state" = "active"
			"$function_to_call" "$context_to_call"
		end

		# Clear the event variables.
		set -e __contextualgreeting_call_state


	# UNKNOWN FUNCTION:
	case "*"
		echo "contextual_greeting: unknown function '$argv[1]'"
		printf "\x1B[2m"
		contextual_greeting --help
		printf "\x1B[0m"

		return 1
	end
end


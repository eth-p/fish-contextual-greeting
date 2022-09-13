# Contextual Greetings for Fish Shell

Upgrade your `fish_greeting` experience with greetings that only show up under certain contexts.



## Install

With [fisher](https://github.com/jorgebucaran/fisher):

```
fisher add eth-p/fish-contextual-greeting
```



## Greetings

Currently, `fish-contextual-greeting` supports the following greeting contexts:

<details><summary><code>greeting_for_ssh</code>: When connected through a SSH client.</summary>

```fish
function greeting_for_ssh
	if contextual_greeting --is-toplevel  # only show if it's not a nested shell
		echo "Hello, $SSH_CLIENT!"
	end
end
```

</details>

<details><summary><code>greeting_for_ide</code>: When using an IDE terminal.</summary>

```fish
function greeting_for_ide
	echo "You appear to be using an IDE terminal."
end
```

</details>

<details><summary><code>greeting_for_tmux</code>: When inside a tmux pane.</summary>

```fish
function greeting_for_tmux
	tmux list-windows
end
```

</details>

The user's `fish_greeting` will also be called after the other contextual greetings..



## Configuration

Greetings can be configured with variables:

|Variable|Default|Description|
|:--|:--|:--|
|`contextualgreeting_order`|`'ssh' 'ide' 'tmux' 'fish'`|The order in which prefixes are printed.|
|`contextualgreeting_prefix`|`'greeting_for_'`|The prefix for greeting functions.|
|`contextualgreeting_redraw`|`false`|Redraw the greeting if the terminal is resized.|


## Advanced Features

### Event Listener

You can add an event listener for the `contextual_greeting` event to optionally disable greetings under certain circumstances:

```fish
function disable_ide_message_for_tmux --on-event contextual_greeting
	set -l current_context $argv[1]
	if contains "tmux" (contextual_greeting contexts) && test $current_context = "ide" 
		contextual_greeting skip
	end
end
```

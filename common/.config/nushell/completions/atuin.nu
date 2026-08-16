module completions {

  # Magical shell history
  export extern atuin [
    --help(-h)                # Print help
    --version(-V)             # Print version
  ]

  # Setup Atuin features
  export extern "atuin setup" [
    --help(-h)                # Print help
  ]

  # Manipulate shell history
  export extern "atuin history" [
    --help(-h)                # Print help
  ]

  # Begins a new command in the history
  export extern "atuin history start" [
    --command-from-env        # Collects the command from the `ATUIN_COMMAND_LINE` environment variable, which does not need escaping and is more compatible between OS and shells
    --author: string          # Author of this command, eg `ellie`, `claude`, or `copilot`
    --intent: string          # Optional intent/rationale for running this command
    --hook                    # Passed by shell hooks; this flag disables logging to avoid corrupting the terminal and to minimize the amount of time the command takes to run
    --help(-h)                # Print help
    ...command: string
  ]

  # Finishes a new command in the history (adds time, exit code)
  export extern "atuin history end" [
    --exit(-e): string
    --duration(-d): string
    --hook                    # Passed by shell hooks; this flag disables logging to avoid corrupting the terminal and to minimize the amount of time the command takes to run
    --help(-h)                # Print help
    id: string
  ]

  # Stream history events from the daemon as they are received
  export extern "atuin history tail" [
    --help(-h)                # Print help
  ]

  def "nu-complete atuin history list reverse" [] {
    [ "true" "false" ]
  }

  # List all items in history
  export extern "atuin history list" [
    --cwd(-c)
    --session(-s)
    --human
    --cmd-only                # Show only the text of the command
    --print0                  # Terminate the output with a null, for better multiline support
    --reverse(-r): string@"nu-complete atuin history list reverse"
    --timezone: string        # Display the command time in another timezone other than the configured default.
    --tz: string              # Display the command time in another timezone other than the configured default.
    --format(-f): string      # Available variables: {command}, {directory}, {duration}, {user}, {host}, {author}, {intent}, {exit}, {time}, {session}, and {uuid}
    --help(-h)                # Print help (see more with '--help')
  ]

  # Get the last command that was run
  export extern "atuin history last" [
    --human
    --cmd-only                # Show only the text of the command
    --timezone: string        # Display the command time in another timezone other than the configured default.
    --tz: string              # Display the command time in another timezone other than the configured default.
    --format(-f): string      # Available variables: {command}, {directory}, {duration}, {user}, {host}, {author}, {intent}, {time}, {session}, {uuid} and {relativetime}
    --help(-h)                # Print help (see more with '--help')
  ]

  export extern "atuin history init-store" [
    --help(-h)                # Print help
  ]

  # Delete history entries matching the configured exclusion filters
  export extern "atuin history prune" [
    --dry-run(-n)             # List matching history lines without performing the actual deletion
    --help(-h)                # Print help
  ]

  # Delete duplicate history entries (that have the same command, cwd and hostname)
  export extern "atuin history dedup" [
    --dry-run(-n)             # List matching history lines without performing the actual deletion
    --before(-b): string      # Only delete results added before this date
    --dupkeep: string         # How many recent duplicates to keep
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin history help" [
  ]

  # Begins a new command in the history
  export extern "atuin history help start" [
  ]

  # Finishes a new command in the history (adds time, exit code)
  export extern "atuin history help end" [
  ]

  # Stream history events from the daemon as they are received
  export extern "atuin history help tail" [
  ]

  # List all items in history
  export extern "atuin history help list" [
  ]

  # Get the last command that was run
  export extern "atuin history help last" [
  ]

  export extern "atuin history help init-store" [
  ]

  # Delete history entries matching the configured exclusion filters
  export extern "atuin history help prune" [
  ]

  # Delete duplicate history entries (that have the same command, cwd and hostname)
  export extern "atuin history help dedup" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin history help help" [
  ]

  # Manage AI-agent shell hooks
  export extern "atuin hook" [
    --help(-h)                # Print help
    agent?: string            # Which agent's hook format to parse (e.g., "claude-code")
  ]

  # Install hooks for an AI agent to capture commands in atuin history
  export extern "atuin hook install" [
    --help(-h)                # Print help
    agent: string             # Agent to install hooks for (e.g., "claude-code")
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin hook help" [
  ]

  # Install hooks for an AI agent to capture commands in atuin history
  export extern "atuin hook help install" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin hook help help" [
  ]

  # Import shell history from file
  export extern "atuin import" [
    --help(-h)                # Print help
  ]

  # Import history for the current shell
  export extern "atuin import auto" [
    --help(-h)                # Print help
  ]

  # Import history from the zsh history file
  export extern "atuin import zsh" [
    --help(-h)                # Print help
  ]

  # Import history from the zsh history file
  export extern "atuin import zsh-hist-db" [
    --help(-h)                # Print help
  ]

  # Import history from the bash history file
  export extern "atuin import bash" [
    --help(-h)                # Print help
  ]

  # Import history from the replxx history file
  export extern "atuin import replxx" [
    --help(-h)                # Print help
  ]

  # Import history from the resh history file
  export extern "atuin import resh" [
    --help(-h)                # Print help
  ]

  # Import history from the fish history file
  export extern "atuin import fish" [
    --help(-h)                # Print help
  ]

  # Import history from the nu history file
  export extern "atuin import nu" [
    --help(-h)                # Print help
  ]

  # Import history from the nu history file
  export extern "atuin import nu-hist-db" [
    --help(-h)                # Print help
  ]

  # Import history from xonsh json files
  export extern "atuin import xonsh" [
    --help(-h)                # Print help
  ]

  # Import history from xonsh sqlite db
  export extern "atuin import xonsh-sqlite" [
    --help(-h)                # Print help
  ]

  # Import history from the powershell history file
  export extern "atuin import powershell" [
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin import help" [
  ]

  # Import history for the current shell
  export extern "atuin import help auto" [
  ]

  # Import history from the zsh history file
  export extern "atuin import help zsh" [
  ]

  # Import history from the zsh history file
  export extern "atuin import help zsh-hist-db" [
  ]

  # Import history from the bash history file
  export extern "atuin import help bash" [
  ]

  # Import history from the replxx history file
  export extern "atuin import help replxx" [
  ]

  # Import history from the resh history file
  export extern "atuin import help resh" [
  ]

  # Import history from the fish history file
  export extern "atuin import help fish" [
  ]

  # Import history from the nu history file
  export extern "atuin import help nu" [
  ]

  # Import history from the nu history file
  export extern "atuin import help nu-hist-db" [
  ]

  # Import history from xonsh json files
  export extern "atuin import help xonsh" [
  ]

  # Import history from xonsh sqlite db
  export extern "atuin import help xonsh-sqlite" [
  ]

  # Import history from the powershell history file
  export extern "atuin import help powershell" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin import help help" [
  ]

  def "nu-complete atuin stats filter_mode" [] {
    [ "global" "host" "session" "directory" "workspace" "session-preload" ]
  }

  # Calculate statistics for your history
  export extern "atuin stats" [
    --count(-c): string       # How many top commands to list
    --ngram-size(-n): string  # The number of consecutive commands to consider
    --filter-mode: string@"nu-complete atuin stats filter_mode" # Filter commands by scope [global, host, session, directory, workspace]
    --help(-h)                # Print help (see more with '--help')
    ...period: string         # Compute statistics for the specified period, leave blank for statistics since the beginning
  ]

  def "nu-complete atuin search filter_mode" [] {
    [ "global" "host" "session" "directory" "workspace" "session-preload" ]
  }

  def "nu-complete atuin search search_mode" [] {
    [ "prefix" "fulltext" "fuzzy" "daemon-fuzzy" "skim" ]
  }

  def "nu-complete atuin search keymap_mode" [] {
    [ "emacs" "vim-normal" "vim-insert" "auto" ]
  }

  # Interactive history search
  export extern "atuin search" [
    --cwd(-c): string         # Filter search result by directory
    --exclude-cwd: string     # Exclude directory from results
    --exit(-e): string        # Filter search result by exit code
    --exclude-exit: string    # Exclude results with this exit code
    --before(-b): string      # Only include results added before this date
    --after: string           # Only include results after this date
    --limit: string           # How many entries to return at most
    --offset: string          # Offset from the start of the results
    --interactive(-i)         # Open interactive search UI
    --filter-mode: string@"nu-complete atuin search filter_mode" # Allow overriding filter mode over config
    --search-mode: string@"nu-complete atuin search search_mode" # Allow overriding search mode over config
    --shell-up-key-binding    # Marker argument used to inform atuin that it was invoked from a shell up-key binding (hidden from help to avoid confusion)
    --keymap-mode: string@"nu-complete atuin search keymap_mode" # Notify the keymap at the shell's side
    --human                   # Use human-readable formatting for time
    --cmd-only                # Show only the text of the command
    --print0                  # Terminate the output with a null, for better multiline handling
    --delete                  # Delete anything matching this query. Will not print out the match
    --delete-it-all           # Delete EVERYTHING!
    --reverse(-r)             # Reverse the order of results, oldest first
    --timezone: string        # Display the command time in another timezone other than the configured default.
    --tz: string              # Display the command time in another timezone other than the configured default.
    --format(-f): string      # Available variables: {command}, {directory}, {duration}, {user}, {host}, {time}, {exit} and {relativetime}
    --inline-height: string   # Set the maximum number of lines Atuin's interface should take up
    --author: string          # Filter by author. Supports $all-user (non-agents), $all-agent, or literal names
    --include-duplicates      # Include duplicate commands in the output (non-interactive only)
    --result-file: string     # File name to write the result to (hidden from help as this is meant to be used from a script)
    --shell: string           # Filter by the shell that was used to run the command
    --help(-h)                # Print help (see more with '--help')
    ...query: string
  ]

  # Sync with the configured server
  export extern "atuin sync" [
    --force(-f)               # Force re-download everything
    --help(-h)                # Print help
  ]

  # Login to the configured server
  export extern "atuin login" [
    --username(-u): string
    --password(-p): string
    --key(-k): string         # The encryption key for your account
    --totp-code(-t): string   # The two-factor authentication code for your account, if any
    --from-registration
    --help(-h)                # Print help
  ]

  # Log out
  export extern "atuin logout" [
    --help(-h)                # Print help
  ]

  # Register with the configured server
  export extern "atuin register" [
    --username(-u): string
    --password(-p): string
    --email(-e): string
    --help(-h)                # Print help
  ]

  # Print the encryption key for transfer to another machine
  export extern "atuin key" [
    --base64                  # Switch to base64 output of the key
    --help(-h)                # Print help
  ]

  # Display the sync status
  export extern "atuin status" [
    --help(-h)                # Print help
  ]

  # Manage your sync account
  export extern "atuin account" [
    --help(-h)                # Print help
  ]

  # Login to the configured server
  export extern "atuin account login" [
    --username(-u): string
    --password(-p): string
    --key(-k): string         # The encryption key for your account
    --totp-code(-t): string   # The two-factor authentication code for your account, if any
    --from-registration
    --help(-h)                # Print help
  ]

  # Register a new account
  export extern "atuin account register" [
    --username(-u): string
    --password(-p): string
    --email(-e): string
    --help(-h)                # Print help
  ]

  # Log out
  export extern "atuin account logout" [
    --help(-h)                # Print help
  ]

  # Delete your account, and all synced data
  export extern "atuin account delete" [
    --password(-p): string
    --totp-code(-t): string   # The two-factor authentication code for your account, if any
    --help(-h)                # Print help
  ]

  # Change your password
  export extern "atuin account change-password" [
    --current-password(-c): string
    --new-password(-n): string
    --totp-code(-t): string   # The two-factor authentication code for your account, if any
    --help(-h)                # Print help
  ]

  # Link your CLI sync account to your Hub account
  export extern "atuin account link" [
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin account help" [
  ]

  # Login to the configured server
  export extern "atuin account help login" [
  ]

  # Register a new account
  export extern "atuin account help register" [
  ]

  # Log out
  export extern "atuin account help logout" [
  ]

  # Delete your account, and all synced data
  export extern "atuin account help delete" [
  ]

  # Change your password
  export extern "atuin account help change-password" [
  ]

  # Link your CLI sync account to your Hub account
  export extern "atuin account help link" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin account help help" [
  ]

  # Get or set small key-value pairs
  export extern "atuin kv" [
    --help(-h)                # Print help
  ]

  # Set a key-value pair
  export extern "atuin kv set" [
    --key(-k): string         # Key to set
    --namespace(-n): string   # Namespace for the key-value pair
    --help(-h)                # Print help
    value?: string            # Value to store (reads from stdin if not provided)
  ]

  # Delete one or more key-value pairs
  export extern "atuin kv delete" [
    --namespace(-n): string   # Namespace for the key-value pair
    --help(-h)                # Print help
    ...keys: string           # Keys to delete
  ]

  # Retrieve a saved value
  export extern "atuin kv get" [
    --namespace(-n): string   # Namespace for the key-value pair
    --help(-h)                # Print help
    key: string               # Key to retrieve
  ]

  # List all keys in a namespace, or in all namespaces
  export extern "atuin kv list" [
    --namespace(-n): string   # Namespace to list keys from
    --all-namespaces(-a)      # List all keys in all namespaces
    --help(-h)                # Print help
  ]

  # Rebuild the KV store
  export extern "atuin kv rebuild" [
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin kv help" [
  ]

  # Set a key-value pair
  export extern "atuin kv help set" [
  ]

  # Delete one or more key-value pairs
  export extern "atuin kv help delete" [
  ]

  # Retrieve a saved value
  export extern "atuin kv help get" [
  ]

  # List all keys in a namespace, or in all namespaces
  export extern "atuin kv help list" [
  ]

  # Rebuild the KV store
  export extern "atuin kv help rebuild" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin kv help help" [
  ]

  # Manage the atuin data store
  export extern "atuin store" [
    --help(-h)                # Print help
  ]

  # Print the current status of the record store
  export extern "atuin store status" [
    --help(-h)                # Print help
  ]

  # Rebuild a store (eg atuin store rebuild history)
  export extern "atuin store rebuild" [
    --help(-h)                # Print help
    tag: string
  ]

  # Re-encrypt the store with a new key (potential for data loss!)
  export extern "atuin store rekey" [
    --help(-h)                # Print help
    key?: string              # The new key to use for encryption. Omit for a randomly-generated key
  ]

  # Delete all records in the store that cannot be decrypted with the current key
  export extern "atuin store purge" [
    --help(-h)                # Print help
  ]

  # Verify that all records in the store can be decrypted with the current key
  export extern "atuin store verify" [
    --help(-h)                # Print help
  ]

  # Push all records to the remote sync server (one way sync)
  export extern "atuin store push" [
    --tag(-t): string         # The tag to push (eg, 'history'). Defaults to all tags
    --host: string            # The host to push, in the form of a UUID host ID. Defaults to the current host
    --force                   # Force push records
    --page: string            # Page Size
    --help(-h)                # Print help (see more with '--help')
  ]

  # Pull records from the remote sync server (one way sync)
  export extern "atuin store pull" [
    --tag(-t): string         # The tag to push (eg, 'history'). Defaults to all tags
    --force                   # Force push records
    --page: string            # Page Size
    --help(-h)                # Print help (see more with '--help')
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin store help" [
  ]

  # Print the current status of the record store
  export extern "atuin store help status" [
  ]

  # Rebuild a store (eg atuin store rebuild history)
  export extern "atuin store help rebuild" [
  ]

  # Re-encrypt the store with a new key (potential for data loss!)
  export extern "atuin store help rekey" [
  ]

  # Delete all records in the store that cannot be decrypted with the current key
  export extern "atuin store help purge" [
  ]

  # Verify that all records in the store can be decrypted with the current key
  export extern "atuin store help verify" [
  ]

  # Push all records to the remote sync server (one way sync)
  export extern "atuin store help push" [
  ]

  # Pull records from the remote sync server (one way sync)
  export extern "atuin store help pull" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin store help help" [
  ]

  # Manage your dotfiles with Atuin
  export extern "atuin dotfiles" [
    --help(-h)                # Print help
  ]

  # Manage shell aliases with Atuin
  export extern "atuin dotfiles alias" [
    --help(-h)                # Print help
  ]

  # Set an alias
  export extern "atuin dotfiles alias set" [
    --help(-h)                # Print help
    name: string
    value: string
  ]

  # Delete an alias
  export extern "atuin dotfiles alias delete" [
    --help(-h)                # Print help
    name: string
  ]

  def "nu-complete atuin dotfiles alias list sort_by" [] {
    [ "name" "value" ]
  }

  # List all aliases
  export extern "atuin dotfiles alias list" [
    --sort-by: string@"nu-complete atuin dotfiles alias list sort_by" # Sort results by field
    --reverse(-r)             # Sort in reverse (descending) order
    --name(-n): string        # Filter aliases by name (substring match)
    --value(-v): string       # Filter aliases by value (substring match)
    --help(-h)                # Print help (see more with '--help')
  ]

  # Delete all aliases
  export extern "atuin dotfiles alias clear" [
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin dotfiles alias help" [
  ]

  # Set an alias
  export extern "atuin dotfiles alias help set" [
  ]

  # Delete an alias
  export extern "atuin dotfiles alias help delete" [
  ]

  # List all aliases
  export extern "atuin dotfiles alias help list" [
  ]

  # Delete all aliases
  export extern "atuin dotfiles alias help clear" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin dotfiles alias help help" [
  ]

  # Manage shell and environment variables with Atuin
  export extern "atuin dotfiles var" [
    --help(-h)                # Print help
  ]

  # Set a variable
  export extern "atuin dotfiles var set" [
    --no-export(-n)
    --help(-h)                # Print help
    name: string
    value: string
  ]

  # Delete a variable
  export extern "atuin dotfiles var delete" [
    --help(-h)                # Print help
    name: string
  ]

  def "nu-complete atuin dotfiles var list sort_by" [] {
    [ "name" "value" ]
  }

  # List all variables
  export extern "atuin dotfiles var list" [
    --sort-by: string@"nu-complete atuin dotfiles var list sort_by" # Sort results by field
    --reverse(-r)             # Sort in reverse (descending) order
    --name(-n): string        # Filter variables by name (substring match)
    --value(-v): string       # Filter variables by value (substring match)
    --exports-only            # Show only exported variables
    --shell-only              # Show only non-exported (shell) variables
    --help(-h)                # Print help (see more with '--help')
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin dotfiles var help" [
  ]

  # Set a variable
  export extern "atuin dotfiles var help set" [
  ]

  # Delete a variable
  export extern "atuin dotfiles var help delete" [
  ]

  # List all variables
  export extern "atuin dotfiles var help list" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin dotfiles var help help" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin dotfiles help" [
  ]

  # Manage shell aliases with Atuin
  export extern "atuin dotfiles help alias" [
  ]

  # Set an alias
  export extern "atuin dotfiles help alias set" [
  ]

  # Delete an alias
  export extern "atuin dotfiles help alias delete" [
  ]

  # List all aliases
  export extern "atuin dotfiles help alias list" [
  ]

  # Delete all aliases
  export extern "atuin dotfiles help alias clear" [
  ]

  # Manage shell and environment variables with Atuin
  export extern "atuin dotfiles help var" [
  ]

  # Set a variable
  export extern "atuin dotfiles help var set" [
  ]

  # Delete a variable
  export extern "atuin dotfiles help var delete" [
  ]

  # List all variables
  export extern "atuin dotfiles help var list" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin dotfiles help help" [
  ]

  # Manage your scripts with Atuin
  export extern "atuin scripts" [
    --help(-h)                # Print help
  ]

  export extern "atuin scripts new" [
    --description(-d): string
    --tags(-t): string
    --shebang(-s): string
    --script: path
    --last: string            # Use the last command as the script content
    --no-edit                 # Skip opening editor when using --last
    --help(-h)                # Print help (see more with '--help')
    name: string
  ]

  export extern "atuin scripts run" [
    --var(-v): string         # Specify template variables in the format KEY=VALUE
    --help(-h)                # Print help (see more with '--help')
    name: string
  ]

  export extern "atuin scripts list" [
    --help(-h)                # Print help
  ]

  export extern "atuin scripts get" [
    --script(-s)              # Display only the executable script with shebang
    --help(-h)                # Print help
    name: string
  ]

  export extern "atuin scripts edit" [
    --description(-d): string
    --tags(-t): string        # Replace all existing tags with these new tags
    --no-tags                 # Remove all tags from the script
    --rename: string          # Rename the script
    --shebang(-s): string
    --script: path
    --no-edit                 # Skip opening editor
    --help(-h)                # Print help
    name: string
  ]

  export extern "atuin scripts delete" [
    --force(-f)
    --help(-h)                # Print help
    name: string
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin scripts help" [
  ]

  export extern "atuin scripts help new" [
  ]

  export extern "atuin scripts help run" [
  ]

  export extern "atuin scripts help list" [
  ]

  export extern "atuin scripts help get" [
  ]

  export extern "atuin scripts help edit" [
  ]

  export extern "atuin scripts help delete" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin scripts help help" [
  ]

  def "nu-complete atuin init shell" [] {
    [ "zsh" "bash" "fish" "nu" "xonsh" "powershell" ]
  }

  # Print Atuin's shell init script
  export extern "atuin init" [
    --disable-ctrl-r          # Disable the binding of CTRL-R to atuin
    --disable-up-arrow        # Disable the binding of the Up Arrow key to atuin
    --disable-ai              # Disable the binding of ? to Atuin AI
    --help(-h)                # Print help (see more with '--help')
    shell: string@"nu-complete atuin init shell"
  ]

  # Information about dotfiles locations and ENV vars
  export extern "atuin info" [
    --help(-h)                # Print help
  ]

  # Run the doctor to check for common issues
  export extern "atuin doctor" [
    --help(-h)                # Print help
  ]

  # Update atuin to the latest version on your release channel
  export extern "atuin update" [
    --check                   # Check whether an update is available without installing it
    --version: string         # Update (or roll back) to a specific version, e.g. "18.9.0" or "18.9.0-nightly.1", instead of the channel's latest release
    --help(-h)                # Print help
  ]

  export extern "atuin wrapped" [
    --help(-h)                # Print help
    year?: string
  ]

  # *Experimental* Manage the background daemon
  export extern "atuin daemon" [
    --daemonize               # Internal flag for daemonization
    --show-logs               # Also write daemon logs to the console (useful for debugging)
    --help(-h)                # Print help
  ]

  # Start the daemon server
  export extern "atuin daemon start" [
    --daemonize
    --show-logs               # Also write daemon logs to the console (useful for debugging)
    --force                   # Force start: kill existing daemon process and reset the socket
    --help(-h)                # Print help
  ]

  # Show the daemon's current status
  export extern "atuin daemon status" [
    --help(-h)                # Print help
  ]

  # Stop the daemon gracefully
  export extern "atuin daemon stop" [
    --help(-h)                # Print help
  ]

  # Restart the daemon (stop, then start in background)
  export extern "atuin daemon restart" [
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin daemon help" [
  ]

  # Start the daemon server
  export extern "atuin daemon help start" [
  ]

  # Show the daemon's current status
  export extern "atuin daemon help status" [
  ]

  # Stop the daemon gracefully
  export extern "atuin daemon help stop" [
  ]

  # Restart the daemon (stop, then start in background)
  export extern "atuin daemon help restart" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin daemon help help" [
  ]

  # Print the default atuin configuration (config.toml)
  export extern "atuin default-config" [
    --help(-h)                # Print help
  ]

  export extern "atuin config" [
    --help(-h)                # Print help
  ]

  # Get a configuration value from your config.toml file or after defaults and overrides are applied
  export extern "atuin config get" [
    --resolved(-r)            # Print the value after defaults and overrides are applied
    --verbose(-v)             # Print both the config file value and the resolved value
    --help(-h)                # Print help
    key: string               # The configuration key to get
  ]

  def "nu-complete atuin config set the_type" [] {
    [ "auto" "string" "boolean" "integer" "float" ]
  }

  # Set a configuration value in your config.toml file
  export extern "atuin config set" [
    --type(-t): string@"nu-complete atuin config set the_type" # Store value as an explicit type
    --help(-h)                # Print help (see more with '--help')
    key: string               # The configuration key to set
    value: string             # The value to set
  ]

  # Print all configuration values from your config.toml file in TOML format
  export extern "atuin config print" [
    --help(-h)                # Print help (see more with '--help')
    key?: string              # Print the value of a specific key and all its children
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin config help" [
  ]

  # Get a configuration value from your config.toml file or after defaults and overrides are applied
  export extern "atuin config help get" [
  ]

  # Set a configuration value in your config.toml file
  export extern "atuin config help set" [
  ]

  # Print all configuration values from your config.toml file in TOML format
  export extern "atuin config help print" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin config help help" [
  ]

  # Run the AI assistant
  export extern "atuin ai" [
    --help(-h)                # Print help
  ]

  # Initialize shell integration
  export extern "atuin ai init" [
    --help(-h)                # Print help
    shell?: string            # Shell to generate integration for; defaults to "auto"
  ]

  # Inline completion mode with small TUI overlay
  export extern "atuin ai inline" [
    --verbose(-v)             # Enable verbose logging
    --api-endpoint: string    # Custom API endpoint; defaults to reading from the `ai.endpoint` setting
    --api-token: string       # Custom API token; defaults to reading from the `ai.api_token` setting
    --hook                    # Use the hook mode
    --help(-h)                # Print help
    command?: string          # Current command line to complete
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin ai help" [
  ]

  # Initialize shell integration
  export extern "atuin ai help init" [
  ]

  # Inline completion mode with small TUI overlay
  export extern "atuin ai help inline" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin ai help help" [
  ]

  # Start an MCP server exposing history search to AI tools (stdio)
  export extern "atuin mcp" [
    --help(-h)                # Print help
  ]

  # Experimental laboratory features
  export extern "atuin lab" [
    --help(-h)                # Print help
  ]

  # Share your terminal with others (experimental)
  export extern "atuin lab share" [
    --write                   # Allow anyone with the link to send keystrokes to your shell
    --yes                     # Skip the confirmation prompt (the warning is still printed)
    --active                  # Share the session already running in this terminal (requires an atuin pty-proxy owning it; see `atuin pty-proxy init`)
    --foreground              # Run --active attached to this terminal instead of in the background (debug): the URL prints to stderr, Ctrl-C stops
    --stop                    # Stop the background --active share session
    --url                     # Print the join URL of the running background --active share
    --internal-daemon         # Run as the re-exec'd daemonized child of --active (internal: the process forks into the background before the runtime is built)
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin lab help" [
  ]

  # Share your terminal with others (experimental)
  export extern "atuin lab help share" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin lab help help" [
  ]

  # PTY proxy for atuin
  export extern "atuin pty-proxy" [
    --debug-osc133            # Highlight OSC 133 prompt, input, output, and exit-code regions
    --shell: path             # Path to the shell binary that atuin pty-proxy should spawn. Defaults to the system login shell. Only valid when no subcommand is given
    --help(-h)                # Print help
  ]

  def "nu-complete atuin pty-proxy init shell" [] {
    [ "zsh" "bash" "fish" "nu" ]
  }

  # Print shell code to initialize atuin pty-proxy on shell startup
  export extern "atuin pty-proxy init" [
    --help(-h)                # Print help (see more with '--help')
    shell?: string@"nu-complete atuin pty-proxy init shell" # Shell to generate init for. If omitted, attempt auto-detection
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin pty-proxy help" [
  ]

  # Print shell code to initialize atuin pty-proxy on shell startup
  export extern "atuin pty-proxy help init" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin pty-proxy help help" [
  ]

  # Generate a UUID
  export extern "atuin uuid" [
    --help(-h)                # Print help
  ]

  export extern "atuin contributors" [
    --help(-h)                # Print help
  ]

  def "nu-complete atuin gen-completions shell" [] {
    [ "bash" "elvish" "fish" "nushell" "powershell" "zsh" ]
  }

  # Generate shell completions
  export extern "atuin gen-completions" [
    --shell(-s): string@"nu-complete atuin gen-completions shell" # Set the shell for generating completions
    --out-dir(-o): string     # Set the output directory
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin help" [
  ]

  # Setup Atuin features
  export extern "atuin help setup" [
  ]

  # Manipulate shell history
  export extern "atuin help history" [
  ]

  # Begins a new command in the history
  export extern "atuin help history start" [
  ]

  # Finishes a new command in the history (adds time, exit code)
  export extern "atuin help history end" [
  ]

  # Stream history events from the daemon as they are received
  export extern "atuin help history tail" [
  ]

  # List all items in history
  export extern "atuin help history list" [
  ]

  # Get the last command that was run
  export extern "atuin help history last" [
  ]

  export extern "atuin help history init-store" [
  ]

  # Delete history entries matching the configured exclusion filters
  export extern "atuin help history prune" [
  ]

  # Delete duplicate history entries (that have the same command, cwd and hostname)
  export extern "atuin help history dedup" [
  ]

  # Manage AI-agent shell hooks
  export extern "atuin help hook" [
  ]

  # Install hooks for an AI agent to capture commands in atuin history
  export extern "atuin help hook install" [
  ]

  # Import shell history from file
  export extern "atuin help import" [
  ]

  # Import history for the current shell
  export extern "atuin help import auto" [
  ]

  # Import history from the zsh history file
  export extern "atuin help import zsh" [
  ]

  # Import history from the zsh history file
  export extern "atuin help import zsh-hist-db" [
  ]

  # Import history from the bash history file
  export extern "atuin help import bash" [
  ]

  # Import history from the replxx history file
  export extern "atuin help import replxx" [
  ]

  # Import history from the resh history file
  export extern "atuin help import resh" [
  ]

  # Import history from the fish history file
  export extern "atuin help import fish" [
  ]

  # Import history from the nu history file
  export extern "atuin help import nu" [
  ]

  # Import history from the nu history file
  export extern "atuin help import nu-hist-db" [
  ]

  # Import history from xonsh json files
  export extern "atuin help import xonsh" [
  ]

  # Import history from xonsh sqlite db
  export extern "atuin help import xonsh-sqlite" [
  ]

  # Import history from the powershell history file
  export extern "atuin help import powershell" [
  ]

  # Calculate statistics for your history
  export extern "atuin help stats" [
  ]

  # Interactive history search
  export extern "atuin help search" [
  ]

  # Sync with the configured server
  export extern "atuin help sync" [
  ]

  # Login to the configured server
  export extern "atuin help login" [
  ]

  # Log out
  export extern "atuin help logout" [
  ]

  # Register with the configured server
  export extern "atuin help register" [
  ]

  # Print the encryption key for transfer to another machine
  export extern "atuin help key" [
  ]

  # Display the sync status
  export extern "atuin help status" [
  ]

  # Manage your sync account
  export extern "atuin help account" [
  ]

  # Login to the configured server
  export extern "atuin help account login" [
  ]

  # Register a new account
  export extern "atuin help account register" [
  ]

  # Log out
  export extern "atuin help account logout" [
  ]

  # Delete your account, and all synced data
  export extern "atuin help account delete" [
  ]

  # Change your password
  export extern "atuin help account change-password" [
  ]

  # Link your CLI sync account to your Hub account
  export extern "atuin help account link" [
  ]

  # Get or set small key-value pairs
  export extern "atuin help kv" [
  ]

  # Set a key-value pair
  export extern "atuin help kv set" [
  ]

  # Delete one or more key-value pairs
  export extern "atuin help kv delete" [
  ]

  # Retrieve a saved value
  export extern "atuin help kv get" [
  ]

  # List all keys in a namespace, or in all namespaces
  export extern "atuin help kv list" [
  ]

  # Rebuild the KV store
  export extern "atuin help kv rebuild" [
  ]

  # Manage the atuin data store
  export extern "atuin help store" [
  ]

  # Print the current status of the record store
  export extern "atuin help store status" [
  ]

  # Rebuild a store (eg atuin store rebuild history)
  export extern "atuin help store rebuild" [
  ]

  # Re-encrypt the store with a new key (potential for data loss!)
  export extern "atuin help store rekey" [
  ]

  # Delete all records in the store that cannot be decrypted with the current key
  export extern "atuin help store purge" [
  ]

  # Verify that all records in the store can be decrypted with the current key
  export extern "atuin help store verify" [
  ]

  # Push all records to the remote sync server (one way sync)
  export extern "atuin help store push" [
  ]

  # Pull records from the remote sync server (one way sync)
  export extern "atuin help store pull" [
  ]

  # Manage your dotfiles with Atuin
  export extern "atuin help dotfiles" [
  ]

  # Manage shell aliases with Atuin
  export extern "atuin help dotfiles alias" [
  ]

  # Set an alias
  export extern "atuin help dotfiles alias set" [
  ]

  # Delete an alias
  export extern "atuin help dotfiles alias delete" [
  ]

  # List all aliases
  export extern "atuin help dotfiles alias list" [
  ]

  # Delete all aliases
  export extern "atuin help dotfiles alias clear" [
  ]

  # Manage shell and environment variables with Atuin
  export extern "atuin help dotfiles var" [
  ]

  # Set a variable
  export extern "atuin help dotfiles var set" [
  ]

  # Delete a variable
  export extern "atuin help dotfiles var delete" [
  ]

  # List all variables
  export extern "atuin help dotfiles var list" [
  ]

  # Manage your scripts with Atuin
  export extern "atuin help scripts" [
  ]

  export extern "atuin help scripts new" [
  ]

  export extern "atuin help scripts run" [
  ]

  export extern "atuin help scripts list" [
  ]

  export extern "atuin help scripts get" [
  ]

  export extern "atuin help scripts edit" [
  ]

  export extern "atuin help scripts delete" [
  ]

  # Print Atuin's shell init script
  export extern "atuin help init" [
  ]

  # Information about dotfiles locations and ENV vars
  export extern "atuin help info" [
  ]

  # Run the doctor to check for common issues
  export extern "atuin help doctor" [
  ]

  # Update atuin to the latest version on your release channel
  export extern "atuin help update" [
  ]

  export extern "atuin help wrapped" [
  ]

  # *Experimental* Manage the background daemon
  export extern "atuin help daemon" [
  ]

  # Start the daemon server
  export extern "atuin help daemon start" [
  ]

  # Show the daemon's current status
  export extern "atuin help daemon status" [
  ]

  # Stop the daemon gracefully
  export extern "atuin help daemon stop" [
  ]

  # Restart the daemon (stop, then start in background)
  export extern "atuin help daemon restart" [
  ]

  # Print the default atuin configuration (config.toml)
  export extern "atuin help default-config" [
  ]

  export extern "atuin help config" [
  ]

  # Get a configuration value from your config.toml file or after defaults and overrides are applied
  export extern "atuin help config get" [
  ]

  # Set a configuration value in your config.toml file
  export extern "atuin help config set" [
  ]

  # Print all configuration values from your config.toml file in TOML format
  export extern "atuin help config print" [
  ]

  # Run the AI assistant
  export extern "atuin help ai" [
  ]

  # Initialize shell integration
  export extern "atuin help ai init" [
  ]

  # Inline completion mode with small TUI overlay
  export extern "atuin help ai inline" [
  ]

  # Start an MCP server exposing history search to AI tools (stdio)
  export extern "atuin help mcp" [
  ]

  # Experimental laboratory features
  export extern "atuin help lab" [
  ]

  # Share your terminal with others (experimental)
  export extern "atuin help lab share" [
  ]

  # PTY proxy for atuin
  export extern "atuin help pty-proxy" [
  ]

  # Print shell code to initialize atuin pty-proxy on shell startup
  export extern "atuin help pty-proxy init" [
  ]

  # Generate a UUID
  export extern "atuin help uuid" [
  ]

  export extern "atuin help contributors" [
  ]

  # Generate shell completions
  export extern "atuin help gen-completions" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "atuin help help" [
  ]

}

export use completions *

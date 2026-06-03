# ==============================================================================
# Environment Variables
# ==============================================================================

$env.EDITOR = "zed"
$env.N_PREFIX = ($env.HOME | path join ".n")

# ==============================================================================
# Path Customization
# ==============================================================================

$env.PATH = (
    $env.PATH
    | prepend ($env.HOME | path join ".opencode" "bin") # Where 'opencode' lives
    | prepend ($env.HOME | path join ".local" "bin")    # Where 'n' lives
    | prepend ($env.N_PREFIX | path join "bin")         # Where 'node' lives
    | prepend ($env.HOME | path join ".atuin" "bin")    # Where 'atuin' lives
    | prepend ($env.HOME | path join ".cargo" "bin")    # Where 'cargo' lives
)

# Bun
let bun_bin = ($env.HOME | path join ".bun" "bin")
if ($bun_bin | path exists) {
    $env.PATH = ($env.PATH | prepend $bun_bin)
}

# Deno
let deno_bin = ($env.HOME | path join ".deno" "bin")
if ($deno_bin | path exists) {
    $env.PATH = ($env.PATH | prepend $deno_bin)
}

# SQL Server Command Line Tools
let mssql_bin = "/opt/mssql-tools18/bin"
if ($mssql_bin | path exists) {
    $env.PATH = ($env.PATH | append $mssql_bin)
}

# fnm (Fast Node Manager)
let fnm_path = ($env.HOME | path join ".local" "share" "fnm")
if ($fnm_path | path exists) {
    $env.PATH = ($env.PATH | prepend $fnm_path)
    
    # Load fnm environment variables dynamically
    let fnm_env = (fnm env --shell bash
        | lines
        | str replace "export " ""
        | str replace -a "\"" ""
        | split column "="
        | rename name value
        | where name != "PATH"
        | reduce -f {} {|it, acc| $acc | upsert $it.name $it.value })
        
    load-env $fnm_env
    
    # Add active node version path from FNM
    if ($env.FNM_MULTISHELL_PATH? | is-not-empty) {
        $env.PATH = ($env.PATH | prepend ($env.FNM_MULTISHELL_PATH | path join "bin"))
    }
}

# ==============================================================================
# External Tool Initializations & SSH Agents
# ==============================================================================

# Zoxide smart directory jumping initializer (cached for startup performance)
let zoxide_cache = ($env.HOME | path join ".zoxide.nu")
if not ($zoxide_cache | path exists) {
    zoxide init nushell | save -f $zoxide_cache
}

# Keychain SSH Key Management
let keychain_output = (^keychain --eval --quiet id_ed25519
    | lines
    | where $it =~ "setenv"
    | parse "setenv {name} {value};"
    | transpose -rd)

if not ($keychain_output | is-empty) {
    load-env $keychain_output
}

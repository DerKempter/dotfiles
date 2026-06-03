# Programmatic verification of PATH parity across all shells
# Run with: nu tests/verify_paths.nu

def get-custom-paths [path_list: list<string>] {
    $path_list
    | each { |it| $it | path expand }
    | where ($it =~ "/home/" or $it =~ "/opt/")
    | where ($it != $env.HOME)
    | uniq
    | sort
}

def check-diff [name1: string, list1: list<string>, name2: string, list2: list<string>] {
    let diff = ($list1 | where $it not-in $list2)
    if ($diff | is-not-empty) {
        print $"(ansi red)✗ Drift detected: Paths present in ($name1) but missing in ($name2):(ansi reset)"
        print $diff
        true
    } else {
        false
    }
}

def main [] {
    print "Analyzing path configurations..."

    # Gather paths from actual shell initializations
    let bash_path = (bash -i -c "echo \$PATH" | str trim | split row ":")
    let zsh_path = (zsh -i -c "echo \$PATH" | str trim | split row ":")
    let nu_path = $env.PATH
    
    let fish_path = (if (which fish | is-not-empty) {
        fish -c "echo \$PATH" | str trim | split row " "
    } else {
        []
    })

    # Filter standard systems paths to isolate user/tool chain modifications
    let bash_custom = (get-custom-paths $bash_path)
    let zsh_custom = (get-custom-paths $zsh_path)
    let nu_custom = (get-custom-paths $nu_path)
    let fish_custom = (if ($fish_path | is-empty) { [] } else { get-custom-paths $fish_path })

    mut has_drift = false

    if (check-diff "Nushell" $nu_custom "Bash" $bash_custom) { $has_drift = true }
    if (check-diff "Bash" $bash_custom "Nushell" $nu_custom) { $has_drift = true }
    
    if (check-diff "Nushell" $nu_custom "Zsh" $zsh_custom) { $has_drift = true }
    if (check-diff "Zsh" $zsh_custom "Nushell" $nu_custom) { $has_drift = true }

    if (which fish | is-not-empty) {
        if (check-diff "Nushell" $nu_custom "Fish" $fish_custom) { $has_drift = true }
        if (check-diff "Fish" $fish_custom "Nushell" $nu_custom) { $has_drift = true }
    }

    if $has_drift {
        print $"\n(ansi red)✗ Path parity check failed. Fix configurations to align custom PATH directories.(ansi reset)"
        exit 1
    } else {
        print $"\n(ansi green)✓ Path parity check passed. All shell configurations have identical custom PATH mappings.(ansi reset)"
    }
}

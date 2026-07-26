set shell := ["nu", "-c"]

# Main entry points (auto-detect OS)
link:
    if $nu.os-info.name == "windows" { just link-windows } else { just link-linux }

unlink:
    if $nu.os-info.name == "windows" { just unlink-windows } else { just unlink-linux }

# =============================================================================
# Linux Operations (GNU Stow)
# =============================================================================

link-linux:
    stow -R common --verbose
    if (sys host | get hostname) == "joshs-cachy-box" { stow -R desktop --verbose }

unlink-linux:
    stow -D common --verbose
    if (sys host | get hostname) == "joshs-cachy-box" { stow -D desktop --verbose }

diff:
    stow -n -v -R common
    if (sys host | get hostname) == "joshs-cachy-box" { stow -n -v -R desktop }

# =============================================================================
# Windows Operations (Native Nushell Symlinks)
# =============================================================================

link-windows:
    print "=== Linking Windows Targets ==="
    let appdata = $env.APPDATA; let userprofile = $env.USERPROFILE
    let win_links = [ ["common/.config/nushell", $"($appdata)/nushell"], ["common/.config/yazi", $"($appdata)/yazi"], ["common/.config/zed", $"($appdata)/Zed"], ["common/.config/starship.toml", $"($userprofile)/.config/starship.toml"], ["common/.gitconfig", $"($userprofile)/.gitconfig"] ]
    $win_links | each { |entry| let src = ($env.JUSTFILE_DIR | path join $entry.0); let target = $entry.1; if ($src | path exists) { mkdir ($target | path dirname); if ($target | path exists) { rm -rf $target }; ln -s $src $target; print $"✓ Linked ($entry.0) -> ($target)" } }

unlink-windows:
    print "=== Unlinking Windows Targets ==="
    let appdata = $env.APPDATA; let userprofile = $env.USERPROFILE
    let win_targets = [ $"($appdata)/nushell", $"($appdata)/yazi", $"($appdata)/Zed", $"($userprofile)/.config/starship.toml", $"($userprofile)/.gitconfig" ]
    $win_targets | each { |target| if ($target | path exists) { rm -rf $target; print $"✓ Removed ($target)" } }

# =============================================================================
# Validation & Utilities
# =============================================================================

# Install external package dependencies (like Yazi plugins/flavors)
install:
    ya pkg install

# Run static syntax validation and path parity tests across all shell configurations
check:
    print "=== Validating Bash ==="
    bash -n common/.bashrc
    print "✓ Bash syntax OK"

    print "=== Validating Zsh ==="
    zsh -n common/.zshrc
    print "✓ Zsh syntax OK"

    print "=== Validating Nushell ==="
    glob common/.config/nushell/**/*.nu | each { |file| nu --ide-check 10 $file }
    print "✓ Nushell syntax OK"

    print "=== Validating Fish ==="
    if (which fish | is-empty) == false { fish -n common/.config/fish/config.fish; print "✓ Fish syntax OK" } else { print "⚠ Fish is not installed on host. Static check skipped." }

    print "=== Validating PATH Parity ==="
    nu --config common/.config/nushell/config.nu --env-config common/.config/nushell/env.nu tests/verify_paths.nu

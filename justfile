# justfile
# Automation recipes for managing dotfiles, symlinks, and cross-shell testing

set shell := ["nu", "-c"]
repo_dir := justfile_directory()

# =============================================================================
# Linking & Environment Provisioning
# =============================================================================

# Apply GNU Stow symlinks across common and machine-specific configurations
link:
    if $nu.os-info.name == "windows" { just link-windows } else { just link-linux }

link-linux:
    stow -R common --target $env.HOME --verbose
    if (sys host | get hostname) == "joshs-cachy-box" { stow -R desktop --target $env.HOME --verbose }
    just bootstrap-themes

# Remove GNU Stow symlinks
unlink:
    if $nu.os-info.name == "windows" { just unlink-windows } else { just unlink-linux }

unlink-linux:
    stow -D common --target $env.HOME --verbose
    if (sys host | get hostname) == "joshs-cachy-box" { stow -D desktop --target $env.HOME --verbose }

link-windows:
    print "=== Linking Windows Targets ==="
    let appdata = $env.APPDATA; let userprofile = $env.USERPROFILE; let win_links = [ ['common/.config/nushell', $"($appdata)/nushell"], ['common/.config/yazi', $"($appdata)/yazi"], ['common/.config/zed', $"($appdata)/Zed"], ['common/.config/starship.toml', $"($userprofile)/.config/starship.toml"], ['common/.gitconfig', $"($userprofile)/.gitconfig"], ['common/.gemini/GEMINI.md', $"($userprofile)/.gemini/GEMINI.md"], ['common/.gemini/antigravity-acp/GEMINI.md', $"($userprofile)/.gemini/antigravity-acp/GEMINI.md"], ['common/.gemini/config/skills/workflow-protocol', $"($userprofile)/.gemini/config/skills/workflow-protocol"] ]; $win_links | each { |entry| let src = ('{{repo_dir}}' | path join $entry.0); let target = $entry.1; if ($src | path exists) { mkdir ($target | path dirname); if ($target | path exists) { rm -rf $target }; ln -s $src $target; print $"✓ Linked ($entry.0) -> ($target)" } }
    just bootstrap-themes

unlink-windows:
    print "=== Unlinking Windows Targets ==="
    let appdata = $env.APPDATA; let userprofile = $env.USERPROFILE; let win_targets = [ $"($appdata)/nushell", $"($appdata)/yazi", $"($appdata)/Zed", $"($userprofile)/.config/starship.toml", $"($userprofile)/.gitconfig", $"($userprofile)/.gemini/GEMINI.md", $"($userprofile)/.gemini/antigravity-acp/GEMINI.md", $"($userprofile)/.gemini/config/skills/workflow-protocol" ]; $win_targets | each { |target| if ($target | path exists) { rm -rf $target; print $"✓ Removed ($target)" } }

# Bootstrap fallback themes from matugen defaults if not already present
bootstrap-themes:
    let defs = ('{{repo_dir}}' | path join 'common/.config/matugen/defaults'); let targets = [ [($defs | path join 'ghostty-theme'), ($env.HOME | path join '.config/ghostty/themes/matugen')], [($defs | path join 'yazi-flavor.toml'), ($env.HOME | path join '.config/yazi/flavors/matugen.yazi/flavor.toml')], [($defs | path join 'atuin-theme.toml'), ($env.HOME | path join '.config/atuin/themes/matugen.toml')], [($defs | path join 'micro-colorscheme.micro'), ($env.HOME | path join '.config/micro/colorschemes/matugen.micro')], [($defs | path join 'vicinae-theme.toml'), ($env.HOME | path join '.local/share/vicinae/themes/matugen.toml')] ]; $targets | each { |pair| let src = $pair.0; let dst = $pair.1; if ($src | path exists) and not ($dst | path exists) { mkdir ($dst | path dirname); cp $src $dst; print $"✓ Bootstrapped default theme -> ($dst)" } }

# =============================================================================
# Validation & Utilities
# =============================================================================

# Install external package dependencies (like Yazi plugins/flavors)
install:
    ya pkg install --discard

# Audit and install essential CLI dependencies and apply symlinks
setup:
    nu install.nu

# Run static syntax validation and path parity tests across all shell configurations
check:
    print "=== Validating Bash ==="
    bash -n common/.bashrc
    print "✓ Bash syntax OK"

    print "=== Validating Zsh ==="
    if (which zsh | is-empty) == false { zsh -n common/.zshrc; print "✓ Zsh syntax OK" } else { print "⚠ Zsh is not installed on host. Static check skipped." }

    print "=== Validating Nushell ==="
    glob common/.config/nushell/**/*.nu | each { |file| nu --ide-check 20 $file }
    glob tests/*.nu | each { |file| nu --ide-check 20 $file }
    print "✓ Nushell syntax OK"

    print "=== Validating Fish ==="
    if (which fish | is-empty) == false { fish -n common/.config/fish/config.fish; print "✓ Fish syntax OK" } else { print "⚠ Fish is not installed on host. Static check skipped." }

    print "=== Validating PATH Parity ==="
    nu --config common/.config/nushell/config.nu --env-config common/.config/nushell/env.nu tests/verify_paths.nu

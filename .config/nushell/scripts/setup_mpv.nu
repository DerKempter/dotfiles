# ==============================================================================
# MPV Stack Bootstrapping & Setup Task
# ==============================================================================

# Bootstraps the media consumption stack (mpv, uosc, yt-dlp, ff2mpv)
export def main [] {
    setup-mpv
}

# Orchestrates the defensive setup of mpv, uosc, yt-dlp, and ff2mpv
export def setup-mpv [] {
    print $"(ansi cyan_bold)=== Starting MPV Stack Bootstrapping ===(ansi reset)"

    # 1. System Core Validation
    validate-system-deps

    # 2. Isolated Toolchain Provisioning (yt-dlp)
    provision-yt-dlp

    # 3. UI Overlay Implementation (uosc)
    provision-uosc

    # 3.5. SponsorBlock Integration (mpv_sponsorblock)
    provision-sponsorblock

    # 4. Browser-to-Host Integration (ff2mpv)
    configure-ff2mpv

    print $"(ansi green_bold)=== MPV Stack Setup Completed Successfully ===(ansi reset)"
}

# Verify system package dependencies are met
def validate-system-deps [] {
    print "Validating system dependencies..."
    let required = ["mpv" "socat" "python3"]
    let missing = ($required | where {|pkg| (which $pkg | is-empty) })

    if not ($missing | is-empty) {
        print -e $"(ansi yellow_bold)Warning: The following core dependencies are missing: ($missing | str join ', ')(ansi reset)"
        print -e "Please install them via your system package provisioner before playing media."
        print -e "Run: sudo apt install mpv socat python3"
    } else {
        print $"(ansi green)✓ System core dependencies verified.(ansi reset)"
    }
}

# Set up yt-dlp in an isolated user path
def provision-yt-dlp [] {
    let bin_dir = ($nu.home-dir | path join ".local" "bin")
    let ytdlp_path = ($bin_dir | path join "yt-dlp")

    if not ($bin_dir | path exists) {
        print $"Creating local binary directory at ($bin_dir)..."
        mkdir $bin_dir
    }

    if ($ytdlp_path | path exists) {
        print $"(ansi cyan)yt-dlp binary already exists at ($ytdlp_path). Skipping download. [Delete the file to force reinstall].(ansi reset)"
    } else {
        print "Downloading latest yt-dlp standalone binary..."
        http get --raw https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp | save -f $ytdlp_path
        print $"Setting executable permissions on ($ytdlp_path)..."
        ^chmod a+rx $ytdlp_path
        print $"(ansi green)✓ yt-dlp binary provisioned successfully.(ansi reset)"
    }
}

# Download and extract the latest uosc release layout
def provision-uosc [] {
    let mpv_dir = ($nu.home-dir | path join ".config" "mpv")
    let uosc_lua = ($mpv_dir | path join "scripts" "uosc.lua")

    if ($uosc_lua | path exists) {
        print $"(ansi cyan)uosc UI overlay is already installed in ($mpv_dir). Skipping download.(ansi reset)"
    } else {
        print "Downloading latest uosc release bundle..."
        let temp_zip = ("/tmp" | path join "uosc.zip")
        http get --raw https://github.com/tomasklaen/uosc/releases/latest/download/uosc.zip | save -f $temp_zip

        print $"Extracting uosc bundle to ($mpv_dir)..."
        if not ($mpv_dir | path exists) {
            mkdir $mpv_dir
        }

        # Portable extraction using Python's built-in zipfile module to avoid dependency on unzip CLI
        ^python3 -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" $temp_zip $mpv_dir

        if ($temp_zip | path exists) {
            rm -f $temp_zip
        }
        print $"(ansi green)✓ uosc UI overlay deployed successfully.(ansi reset)"
    }
}

# Download and configure mpv_sponsorblock scripts and configurations
def provision-sponsorblock [] {
    let mpv_dir = ($nu.home-dir | path join ".config" "mpv")
    let scripts_dir = ($mpv_dir | path join "scripts")
    let sponsorblock_lua = ($scripts_dir | path join "sponsorblock.lua")
    
    # 1. Ensure the config file is always written/verified
    let opts_dir = ($mpv_dir | path join "script-opts")
    if not ($opts_dir | path exists) {
        print $"Creating script options directory at ($opts_dir)..."
        mkdir $opts_dir
    }
    
    let conf_path = ($opts_dir | path join "sponsorblock.conf")
    print $"Deploying SponsorBlock configuration to ($conf_path)..."
    let conf_content = "# Fetch all categories from the central API database
categories=sponsor,intro,outro,interaction,selfpromo,filler

# Disable automatic skipping across all categories to allow manual user control
skip_categories=

# Crucial: Map segments to the timeline layout for manual chapter navigation via uosc
make_chapters=yes
"
    $conf_content | save --force $conf_path

    # 2. Check if sponsorblock.lua already exists. If so, skip downloading the code scripts
    if ($sponsorblock_lua | path exists) {
        print $"(ansi cyan)SponsorBlock script already exists at ($sponsorblock_lua). Skipping code download.(ansi reset)"
    } else {
        print "Downloading latest mpv_sponsorblock archive..."
        let temp_zip = ("/tmp" | path join "mpv_sponsorblock.zip")
        let extract_dir = ("/tmp" | path join "mpv_sponsorblock_extracted")
        
        # Download master zip
        http get --raw https://github.com/po5/mpv_sponsorblock/archive/refs/heads/master.zip | save -f $temp_zip
        
        print $"Extracting SponsorBlock archive to temporary directory ($extract_dir)..."
        if not ($extract_dir | path exists) {
            mkdir $extract_dir
        }
        
        # Extract via Python zipfile utility
        ^python3 -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" $temp_zip $extract_dir
        
        let extracted_root = ($extract_dir | path join "mpv_sponsorblock-master")
        let src_lua = ($extracted_root | path join "sponsorblock.lua")
        let src_shared = ($extracted_root | path join "sponsorblock_shared")
        
        print $"Moving SponsorBlock files to ($scripts_dir)..."
        if not ($scripts_dir | path exists) {
            mkdir $scripts_dir
        }
        
        # Move target file and directory to configuration scripts folder
        cp $src_lua $scripts_dir
        cp -r $src_shared $scripts_dir
        
        # Clean up temporary folders and files
        print "Cleaning up temporary extraction files..."
        rm -rf $temp_zip
        rm -rf $extract_dir
        
        print $"(ansi green)✓ SponsorBlock integration deployed successfully.(ansi reset)"
    }
}

# Create Firefox native messaging host manifest and set script permissions
def configure-ff2mpv [] {
    # Resolve the repository root defensively
    let config_real = ($nu.config-path | path expand)
    let repo_root = if ($config_real | str contains "dotfiles") {
        $config_real | path dirname | path dirname | path dirname
    } else {
        $nu.home-dir | path join "dotfiles"
    }

    let repo_script = ($repo_root | path join ".local" "bin" "ff2mpv.py")
    let dest_script = ($nu.home-dir | path join ".local" "bin" "ff2mpv.py")

    # Ensure execution bit is set on the repository script and destination script
    for script_file in [$repo_script $dest_script] {
        if ($script_file | path exists) {
            print $"Setting execution permissions on ($script_file)..."
            ^chmod +x $script_file
        }
    }

    # Generate native messaging hosts directory if it does not exist
    let hosts_dir = ($nu.home-dir | path join ".mozilla" "native-messaging-hosts")
    if not ($hosts_dir | path exists) {
        print $"Creating native messaging hosts directory at ($hosts_dir)..."
        mkdir $hosts_dir
    }

    # Generate the ff2mpv.json manifest
    print "Generating Firefox Native Messaging Host manifest..."
    let manifest = {
        name: "ff2mpv"
        description: "ff2mpv native messenger host"
        path: $"($env.HOME)/.local/bin/ff2mpv.py"
        type: "stdio"
        allowed_extensions: ["ff2mpv@yossarian.net"]
    }
    $manifest | to json | save --force $"($env.HOME)/.mozilla/native-messaging-hosts/ff2mpv.json"
    print $"(ansi green)✓ ff2mpv native messaging host configured successfully.(ansi reset)"
}

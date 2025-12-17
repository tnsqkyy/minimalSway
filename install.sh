#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Functions ---

install_dependencies() {
    dependencies="sway swaybg waybar alacritty wofi grim slurp pulseaudio-utils brightnessctl zip swayidle swaylock mako playerctl pamixer autotiling"
    echo "This script will attempt to install the following required packages:"
    echo "$dependencies"
    echo ""
    read -p "Do you want to proceed with installing these dependencies? (y/N): " choice
    case "$choice" in
      y|Y )
        echo "Updating package list and installing dependencies..."
        sudo apt update
        sudo apt install -y $dependencies
        echo "Dependencies installed successfully."
        ;;
      * )
        echo "Skipping dependency installation. Please ensure they are installed manually."
        ;;
    esac
    echo ""
}

install_fonts() {
    echo "--- Installing Fonts (System-Wide) ---"
    local fonts_source_dir="fonts/JetBrainsMono" # This is the source in the repo
    local target_font_dir="/usr/share/fonts/truetype/JetBrainsMono" # User specified target name

    if [ ! -d "$fonts_source_dir" ]; then
        echo "Font source directory '$fonts_source_dir' not found. Skipping font installation."
        return
    fi
    
    echo "Found font source directory. Installing JetBrainsMono Nerd Font to $target_font_dir..."
    
    echo "--> Clearing existing '$target_font_dir' to ensure clean installation (requires sudo)..."
    sudo rm -rf "$target_font_dir" # Remove existing folder with same name
    
    echo "--> Creating system font directory '$target_font_dir' (requires sudo)..."
    sudo mkdir -p "$target_font_dir"
    
    echo "--> Copying font files (requires sudo)..."
    # Use -n (noclobber) to avoid overwriting existing files; however, with rm -rf above, this is mostly for safety.
    sudo cp -n "$fonts_source_dir"/*.ttf "$target_font_dir"/
    
    echo "--> Updating font cache..."
    fc-cache -fv
    
    echo "Font installation complete."
    echo ""
}

create_global_backup() {
    local backup_root_dir="$HOME/Backups"
    local backup_archive_name="config_backup_$(date +%F_%H-%M-%S).zip"
    local backup_path="$backup_root_dir/$backup_archive_name"
    local config_dir="$HOME/.config"
    local base_dir=".config" # From main script

    echo "--- Creating Global Backup ---"
    mkdir -p "$backup_root_dir"

    items_to_backup=""
    for config_item in "$base_dir"/*; do
        if [ -d "$config_item" ]; then
            config_name=$(basename "$config_item")
            target_config_path="$config_dir/$config_name"
            if [ -d "$target_config_path" ]; then
                items_to_backup+=" $config_name"
            fi
        fi
    done

    if [ -n "$items_to_backup" ]; then
        echo "--> Creating $backup_archive_name containing these configs: $items_to_backup"
        # Ensure zip is installed. It's added to dependencies, but good to check.
        if ! command -v zip &> /dev/null; then
            echo "Warning: 'zip' command not found. Cannot create backup. Please install 'zip' (e.g., sudo apt install zip)."
            return
        fi
        (cd "$config_dir" && zip -r "$backup_path" $items_to_backup)
        echo "Backup created at $backup_path"
    else
        echo "No existing configurations found to backup. Skipping backup."
    fi
    echo ""
}


# --- Main Script ---

echo "--- Minimal WM Config Installer ---"
echo

# 1. Install Dependencies
install_dependencies

# 2. Install Fonts
install_fonts

# 3. Install Configurations
base_dir=".config"
config_dir="$HOME/.config"

echo "--- Installing Configurations ---"
echo "The following configurations will be installed:"
for config_item in "$base_dir"/*; do
    if [ -d "$config_item" ]; then
        echo "  - $(basename "$config_item")"
    fi
done
echo ""
echo "This will create a backup of your existing configurations in '$HOME/Backups/'."
read -p "Do you want to proceed with the configuration installation? (y/N): " choice
echo ""

if [[ ! "$choice" =~ ^[yY]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Create global backup before modifying any configs
create_global_backup

echo "Starting configuration installation..."

for source_dir in "$base_dir"/*; do
    if [ -d "$source_dir" ]; then
        config_name=$(basename "$source_dir")
        target_dir="$config_dir/$config_name"
        
        # Remove old config and create directory
        echo "--> Removing old configuration in $target_dir"
        rm -rf "$target_dir"
        echo "--> Creating directory $target_dir"
        mkdir -p "$target_dir"
        
        # Copy new config
        echo "--> Copying new configuration from $source_dir to $target_dir"
        cp -r "$source_dir"/* "$target_dir"/
    fi
done

echo ""
echo "Installation complete!"
echo "Please reload Sway (e.g., with \$mod+c) or restart your session."

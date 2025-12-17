#!/bin/bash

set -Ee

install_dependencies() {
    dependencies="sway swaybg waybar alacritty wofi grim slurp pulseaudio-utils brightnessctl zip swayidle swaylock playerctl pamixer autotiling xwayland"
    echo "This script will attempt to install the following required packages:"
    echo "$dependencies"
    echo ""
    read -p "Do you want to proceed with installing these dependencies? (y/N): " choice
    case "$choice" in
      y|Y )
        sudo apt update
        sudo apt install -y $dependencies
        ;;
      * )
        echo "Skipping dependency installation."
        ;;
    esac
    echo ""
}

install_fonts() {
    echo "--- Installing Fonts (System-Wide) ---"
    local fonts_source_dir="fonts/JetBrainsMono"
    local target_font_dir="/usr/share/fonts/truetype/JetBrainsMono"

    if [ ! -d "$fonts_source_dir" ]; then
        echo "Font source directory not found. Skipping."
        return
    fi

    sudo rm -rf "$target_font_dir"
    sudo mkdir -p "$target_font_dir"

    sudo cp "$fonts_source_dir"/*.ttf "$target_font_dir"/ || true
    fc-cache -fv || true
    echo ""
}

create_global_backup() {
    local backup_root_dir="$HOME/Backups"
    local backup_archive_name="config_backup_$(date +%F_%H-%M-%S).zip"
    local backup_path="$backup_root_dir/$backup_archive_name"
    local config_dir="$HOME/.config"

    mkdir -p "$backup_root_dir"

    if command -v zip >/dev/null; then
        (cd "$config_dir" && zip -r "$backup_path" .) || true
    fi
    echo ""
}

install_dependencies
install_fonts

base_dir=".config"
config_dir="$HOME/.config"

read -p "Proceed with config installation? (y/N): " choice
[[ "$choice" =~ ^[yY]$ ]] || exit 0

create_global_backup

for source_dir in "$base_dir"/*; do
    [ -d "$source_dir" ] || continue
    config_name=$(basename "$source_dir")
    target_dir="$config_dir/$config_name"

    rm -rf "$target_dir"
    mkdir -p "$target_dir"

    # Fix
    cp -a "$source_dir/." "$target_dir/"
done

echo "Done. Reload sway."

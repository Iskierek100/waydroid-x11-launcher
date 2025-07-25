#!/bin/bash
# Waydroid Universal X11 Launcher - Installer v2.4
# Copies scripts, creates launcher, and configures global keyboard shortcuts for KDE/GNOME.

# List of required commands
REQUIRED_CMDS=(zenity weston wmctrl xclip wl-clipboard xdotool)

MISSING_CMDS=()
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_CMDS+=("$cmd")
    fi
done

if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
    echo "ERROR: The following required programs are missing:"
    for cmd in "${MISSING_CMDS[@]}"; do
        echo "  - $cmd"
    done
    echo
    echo "Please install them using your package manager."
    echo "For example, on Ubuntu/Kubuntu:"
    echo "  sudo apt install ${MISSING_CMDS[*]}"
    echo "For example, on Fedora:"
    echo "  sudo dnf install ${MISSING_CMDS[*]}"
    echo "For example, on Arch Linux:"
    echo "  sudo pacman -Syu ${MISSING_CMDS[*]}"
    echo "For example, on openSUSE:"
    echo "  sudo zypper install ${MISSING_CMDS[*]}"
    echo
    if command -v zenity &> /dev/null; then
        zenity --error --text="The following required programs are missing:\n\n${MISSING_CMDS[*]}\n\nPlease install them and run the installer again." --width=400 --height=200
    fi
    exit 1
fi

INSTALL_DIR="$HOME/.local/share/waydroid-launcher"
APP_DIR="$HOME/.local/share/applications"
SOURCE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "--- Waydroid Launcher Installer v2.4 ---"
echo

# Step 1: Create directories
echo "1. Creating target directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$APP_DIR"
echo "   Done."
echo

# Step 2: Copy scripts
echo "2. Copying scripts..."
cp "$SOURCE_DIR/start-waydroid.sh" "$INSTALL_DIR/"
cp "$SOURCE_DIR/paste_to_waydroid.sh" "$INSTALL_DIR/"
cp "$SOURCE_DIR/paste_to_x11.sh" "$INSTALL_DIR/"
echo "   Done."
echo

# Step 3: Set execute permissions
echo "3. Setting execute permissions..."
chmod +x "$INSTALL_DIR/start-waydroid.sh"
chmod +x "$INSTALL_DIR/paste_to_waydroid.sh"
chmod +x "$INSTALL_DIR/paste_to_x11.sh"
echo "   Done."
echo

# Step 4: Create the .desktop launcher for the main script
LAUNCHER_PATH="$INSTALL_DIR/start-waydroid.sh"
DESKTOP_FILE_PATH="$APP_DIR/waydroid-launcher.desktop"

echo "4. Creating application menu launcher..."
cat > "$DESKTOP_FILE_PATH" << EOL
[Desktop Entry]
Version=1.0
Name=Waydroid Launcher
Comment=Launches Waydroid with a graphical selection menu
Exec=$LAUNCHER_PATH
Icon=waydroid
Terminal=false
Type=Application
Categories=Game;System;
EOL
echo "   Done."
echo

# Step 5: Refresh desktop database
echo "5. Refreshing desktop database..."
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$APP_DIR"
    echo "   Desktop database updated."
else
    echo "   WARNING: update-desktop-database not found. Please install desktop-file-utils."
fi
echo

# Step 6: Try to configure global keyboard shortcuts
PASTE_TO_WAYDROID_PATH="$INSTALL_DIR/paste_to_waydroid.sh"
PASTE_TO_X11_PATH="$INSTALL_DIR/paste_to_x11.sh"

configure_kde() {
    echo "   Attempting to configure shortcuts for KDE Plasma..."
    kwriteconfig5 --file kglobalshortcutsrc --group "Waydroid X11 Launcher" --key "_k_friendly_name" "Waydroid Launcher Shortcuts"
    kwriteconfig5 --file kglobalshortcutsrc --group "Waydroid X11 Launcher" --key "Paste to Waydroid" "Alt+Meta+V,none,$PASTE_TO_WAYDROID_PATH"
    kwriteconfig5 --file kglobalshortcutsrc --group "Waydroid X11 Launcher" --key "Paste to X11" "Ctrl+Meta+V,none,$PASTE_TO_X11_PATH"
    qdbus org.kde.KWin /KWin reconfigure
    echo "   KDE configuration complete."
    if command -v zenity &> /dev/null; then
        zenity --info --title="Success!" --text="Shortcuts for KDE Plasma have been configured.\n\nPaste to Waydroid: Alt+Meta+V\nPaste to X11: Ctrl+Meta+V\n\nThey should work immediately." --width=400 --height=200
    fi
}

configure_gnome() {
    echo "   Attempting to configure shortcuts for GNOME..."
    SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
    PATH_PREFIX="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
    current_list=$(gsettings get $SCHEMA custom-keybindings)
    new_paths=()
    for i in {0..20}; do
        if [[ ! "$current_list" =~ "custom$i" ]]; then
            new_paths+=("custom$i")
            if [ ${#new_paths[@]} -eq 2 ]; then break; fi
        fi
    done
    if [ ${#new_paths[@]} -lt 2 ]; then
        if command -v zenity &> /dev/null; then
            zenity --error --text="Could not find two free custom shortcut slots in GNOME. Please configure them manually." --width=400 --height=200
        fi
        return 1
    fi
    path1="$PATH_PREFIX/${new_paths[0]}/"
    gsettings set $SCHEMA.custom-keybinding:$path1 name 'Paste to Waydroid'
    gsettings set $SCHEMA.custom-keybinding:$path1 command "$PASTE_TO_WAYDROID_PATH"
    gsettings set $SCHEMA.custom-keybinding:$path1 binding '<Alt><Super>v'
    path2="$PATH_PREFIX/${new_paths[1]}/"
    gsettings set $SCHEMA.custom-keybinding:$path2 name 'Paste to X11'
    gsettings set $SCHEMA.custom-keybinding:$path2 command "$PASTE_TO_X11_PATH"
    gsettings set $SCHEMA.custom-keybinding:$path2 binding '<Control><Super>v'
    if [[ "$current_list" == *] ]]; then
    new_list="${current_list%]*}, '$path1', '$path2']"
    else
    new_list="['$path1', '$path2']"
    fi
    gsettings set $SCHEMA custom-keybindings "$new_list"
    echo "   GNOME configuration complete."
    if command -v zenity &> /dev/null; then
        zenity --info --title="Success!" --text="Shortcuts for GNOME have been configured.\n\nPaste to Waydroid: Alt+Super+V\nPaste to X11: Ctrl+Super+V\n\nYou might need to log out and log back in for them to become active." --width=400 --height=200
    fi
}

detected_de="Unknown"
if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    detected_de="KDE Plasma"
elif [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    detected_de="GNOME"
fi

if [[ "$detected_de" == "KDE Plasma" ]]; then
    configure_kde
elif [[ "$detected_de" == "GNOME" ]]; then
    configure_gnome
else
    if command -v zenity &> /dev/null; then
        zenity --info --text="Waydroid Launcher has been installed!\n\nYou can find it in your application menu.\nIf you don't see it, try logging out and logging in again.\n\nTo pin it to your panel or desktop, right-click the icon in the menu." --width=400 --height=200

        zenity --info --text="To make clipboard sharing easy, set up global keyboard shortcuts in your system settings:\n\n• Assign a shortcut (e.g. Alt+Meta+V) to:\n$PASTE_TO_WAYDROID_PATH\n\n• Assign a shortcut (e.g. Ctrl+Meta+V) to:\n$PASTE_TO_X11_PATH\n\nYou can do this in your system's keyboard shortcut settings." --width=400 --height=250
    else
        echo "Waydroid Launcher has been installed!"
        echo "You can find it in your application menu."
        echo "If you don't see it, try logging out and logging in again."
        echo "To pin it to your panel or desktop, right-click the icon in the menu."
        echo
        echo "To make clipboard sharing easy, set up global keyboard shortcuts in your system settings:"
        echo "  • Assign a shortcut (e.g. Alt+Meta+V) to:"
        echo "    $PASTE_TO_WAYDROID_PATH"
        echo "  • Assign a shortcut (e.g. Ctrl+Meta+V) to:"
        echo "    $PASTE_TO_X11_PATH"
        echo "You can do this in your system's keyboard shortcut settings."
    fi
fi

echo
echo "--- Installation Complete! ---"
echo "A 'Waydroid Launcher' has been added to your application menu."
echo

# End of script

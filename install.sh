#!/bin/bash
# Final Version: Creates a robust launcher that waits for user input before closing.

# --- Configuration ---
INSTALL_DIR="$HOME/.local/share/waydroid-launcher"
APP_DIR="$HOME/.local/share/applications"
SOURCE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "--- Waydroid Launcher Installer ---"

# 1. Create directories
echo "1. Creating target directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$APP_DIR"

# 2. Copy and set permissions
echo "2. Copying scripts..."
cp "$SOURCE_DIR/start-waydroid.sh" "$INSTALL_DIR/"
cp "$SOURCE_DIR/waydroid-clipboard-sync.sh" "$INSTALL_DIR/"

echo "3. Setting execute permissions..."
if chmod +x "$INSTALL_DIR/start-waydroid.sh" && chmod +x "$INSTALL_DIR/waydroid-clipboard-sync.sh"; then
    echo "Permissions set successfully."
else
    echo "ERROR: Failed to set execute permissions."
    echo "Please run 'chmod +x $INSTALL_DIR/start-waydroid.sh' manually."
fi

# 4. Create the .desktop launcher
LAUNCHER_PATH="$INSTALL_DIR/start-waydroid.sh"
DESKTOP_FILE_PATH="$APP_DIR/waydroid-launcher.desktop"

# This command ensures the terminal stays open after the script finishes
COMMAND_TO_RUN="bash -c '\"$LAUNCHER_PATH\"; echo -e \"\n--- Script Finished --- \nPress Enter to close this window.\"; read'"

echo "4. Creating application menu launcher..."
cat > "$DESKTOP_FILE_PATH" << EOL
[Desktop Entry]
Version=1.0
Name=Waydroid Launcher
Comment=Launches Waydroid with a graphical selection menu
Exec=$COMMAND_TO_RUN
Icon=waydroid
Terminal=true
Type=Application
Categories=Game;System;
EOL

echo "--- Installation Complete! ---"
echo "A 'Waydroid Launcher' icon should now be in your Start Menu."
echo "You may need to log out and log back in for the menu to refresh."

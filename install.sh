#!/bin/bash

# --- Configuration ---
INSTALL_DIR="$HOME/.local/share/waydroid-launcher"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

# --- Main Installer Logic ---
echo "Universal Waydroid Launcher Installer by iskierek & AI"
echo "-------------------------------------------------------------"

# Step 1: Create target directories if they don't exist
echo "Creating target directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$APP_DIR"

# Step 2: Copy the main script files
echo "Copying script files to $INSTALL_DIR..."
cp ./start-waydroid.sh "$INSTALL_DIR/"
cp ./waydroid-clipboard-sync.sh "$INSTALL_DIR/"

# Make sure they are executable
chmod +x "$INSTALL_DIR/start-waydroid.sh"
chmod +x "$INSTALL_DIR/waydroid-clipboard-sync.sh"
echo "Script files copied."

# Step 3: Create a "command" in the system
# We create a symbolic link so the user can type 'start-waydroid' in the terminal
echo "Creating system command in $BIN_DIR..."
# Remove old link if it exists
rm -f "$BIN_DIR/start-waydroid"
ln -s "$INSTALL_DIR/start-waydroid.sh" "$BIN_DIR/start-waydroid"
echo "Command 'start-waydroid' created."
echo "Please ensure that the directory $BIN_DIR is in your PATH."
echo "(In most modern systems, it is by default)."

# Step 4: Create the .desktop file (Application Menu Launcher)
echo "Creating launcher in the applications menu..."
cat > "$APP_DIR/waydroid-launcher.desktop" << EOL
[Desktop Entry]
Version=1.0
Name=Waydroid Launcher
Comment=Run Waydroid in fullscreen or windowed mode
Exec=start-waydroid
Icon=waydroid
Terminal=false
Type=Application
Categories=Game;System;
EOL
echo "Launcher 'Waydroid Launcher' created in your applications menu."

echo "-------------------------------------------------------------"
echo "Installation completed successfully!"
echo "A new icon 'Waydroid Launcher' should now be available in your application menu."
echo "You can drag it to your desktop or panel."

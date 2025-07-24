#!/bin/bash

# --- Configuration ---
INSTALL_DIR="$HOME/.local/share/waydroid-launcher"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

# --- Main Installer Logic ---
echo "Universal Waydroid Launcher Installer by iskierek & AI"
echo "-------------------------------------------------------------"

# Step 1: Create target directories
echo "Creating target directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$APP_DIR"

# Step 2: Copy the script files
echo "Copying script files to $INSTALL_DIR..."
cp ./start-waydroid.sh "$INSTALL_DIR/"
cp ./waydroid-clipboard-sync.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/start-waydroid.sh"
chmod +x "$INSTALL_DIR/waydroid-clipboard-sync.sh"
echo "Script files copied."

# Step 3: Create a system command (optional, for terminal users)
echo "Creating system command in $BIN_DIR..."
rm -f "$BIN_DIR/start-waydroid"
ln -s "$INSTALL_DIR/start-waydroid.sh" "$BIN_DIR/start-waydroid"
echo "Command 'start-waydroid' created (for terminal use)."

# =========================================================================
# === STEP 4 (THE ULTIMATE FIX) ===
# We create the .desktop file with the FULL, ABSOLUTE path.
# This bypasses any PATH issues and works on all desktop environments.
# =========================================================================
echo "Creating launcher in the applications menu..."
# Build the full path to the script
FULL_SCRIPT_PATH="$INSTALL_DIR/start-waydroid.sh"

cat > "$APP_DIR/waydroid-launcher.desktop" << EOL
[Desktop Entry]
Version=1.0
Name=Waydroid Launcher
Comment=Run Waydroid in fullscreen or windowed mode
Exec=$FULL_SCRIPT_PATH
Icon=waydroid
Terminal=false
Type=Application
Categories=Game;System;
EOL
echo "Launcher 'Waydroid Launcher' created in your applications menu."
echo "It uses an absolute path, so it should work immediately."

echo "-------------------------------------------------------------"
echo "Installation completed successfully!"
echo "A new icon 'Waydroid Launcher' should now be in your application menu."
echo "You may need to log out and log back in for the menu to refresh."

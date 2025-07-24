#!/bin/bash
# Final Version - The "Symlink Hack" to force Waydroid's connection.

# --- Step 0: Find its sibling script ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SYNC_SCRIPT_PATH="$SCRIPT_DIR/waydroid-clipboard-sync.sh"

# --- Step 1: Dependency Check Function ---
check_deps() {
    declare -A deps=(
        ["zenity"]="zenity" ["weston"]="weston" ["wmctrl"]="wmctrl"
        ["xclip"]="xclip" ["wl-copy"]="wl-clipboard"
    )
    local missing_pkgs=()
    echo "--- Checking dependencies ---"
    for cmd in "${!deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_pkgs+=("${deps[$cmd]}")
        fi
    done

    if [ ${#missing_pkgs[@]} -ne 0 ]; then
        echo "WARNING: The following packages are missing: ${missing_pkgs[*]}"
        read -p "Install them now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if ! sudo apt-get update && sudo apt-get install -y "${missing_pkgs[@]}"; then
                echo "ERROR: Installation failed. Aborting."
                exit 1
            fi
            echo "Dependencies installed successfully."
        else
            echo "Cancelled. The script cannot continue."
            exit 1
        fi
    else
        echo "All dependencies are satisfied."
    fi
}

# --- Step 2: Cleanup Function ---
cleanup() {
    echo "Exit signal received, cleaning up..."
    if [[ -n "$SYNC_PID" && $(ps -p $SYNC_PID > /dev/null) ]]; then kill -9 $SYNC_PID; fi
    if [[ -n "$WESTON_PID" && $(ps -p $WESTON_PID > /dev/null) ]]; then kill -9 $WESTON_PID; fi
    waydroid session stop &> /dev/null
    # Clean up the symlink
    rm -f "$XDG_RUNTIME_DIR/wayland-0"
    echo "Cleanup complete."
}
trap cleanup EXIT

# ==============================================================================
# --- MAIN PROGRAM LOGIC ---
# ==============================================================================

check_deps

MODE=$(zenity --list \
  --title="Select Waydroid Launch Mode" \
  --column="Mode" --column="Description" \
  "Fullscreen" "Runs in a borderless, fullscreen window." \
  "Windowed" "Runs in a standard portrait window (600x1000)." \
  "Custom Window" "Runs in a window with a custom size." \
  --height=280 --width=550)

if [ -z "$MODE" ]; then echo "Cancelled by user."; exit 0; fi

# Base Weston command, without --socket
weston_cmd=("weston" "--backend=x11-backend.so")

case "$MODE" in
  "Fullscreen")
    WESTON_CONFIG="[core]\nxwayland=true\n\n[shell]\npanel-position=none"
    MANAGE_WINDOW=true
    CONFIG_FILE="$HOME/.config/weston-fullscreen.ini"
    ;;
  "Windowed")
    weston_cmd+=("--width=600" "--height=1000")
    WESTON_CONFIG="[core]\nxwayland=true"
    MANAGE_WINDOW=false
    CONFIG_FILE="$HOME/.config/weston-windowed.ini"
    ;;
  "Custom Window")
    SIZE=$(zenity --entry \
      --title="Enter Window Size" \
      --text="Enter width and height separated by a space (e.g., 800 600):" \
      --entry-text="800 600")
    if [ -z "$SIZE" ]; then echo "Cancelled."; exit 0; fi
    WIDTH=$(echo "$SIZE" | awk '{print $1}')
    HEIGHT=$(echo "$SIZE" | awk '{print $2}')
    if ! [[ "$WIDTH" =~ ^[0-9]+$ ]] || ! [[ "$HEIGHT" =~ ^[0-9]+$ ]]; then
        zenity --error --text="Invalid format."; exit 1
    fi
    weston_cmd+=("--width=$WIDTH" "--height=$HEIGHT")
    WESTON_CONFIG="[core]\nxwayland=true"
    MANAGE_WINDOW=false
    CONFIG_FILE="$HOME/.config/weston-custom.ini"
    ;;
esac

weston_cmd+=("--config=$CONFIG_FILE")

# --- Startup Logic ---
waydroid session stop &> /dev/null
sleep 1
echo -e "$WESTON_CONFIG" > "$CONFIG_FILE"

echo "Launching Weston with options: ${weston_cmd[*]}"
"${weston_cmd[@]}" &
WESTON_PID=$!
sleep 3 # Give it time to create the socket

# --- THE SYMLINK HACK ---
REAL_SOCKET_FILE=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name "wayland-*" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)
if [ -z "$REAL_SOCKET_FILE" ]; then
    echo "CRITICAL ERROR: Failed to find the Wayland socket created by Weston."
    read -p "Press Enter to exit."
    exit 1
fi
REAL_SOCKET_NAME=$(basename "$REAL_SOCKET_FILE")
WAYDROID_EXPECTED_SOCKET="$XDG_RUNTIME_DIR/wayland-0"

echo "Real Weston socket found: $REAL_SOCKET_NAME"
echo "Creating a symlink for Waydroid at: $WAYDROID_EXPECTED_SOCKET"
# Remove old symlink if it exists, then create a new one
ln -sf "$REAL_SOCKET_NAME" "$WAYDROID_EXPECTED_SOCKET"
# --- END OF HACK ---

if [ -f "$SYNC_SCRIPT_PATH" ]; then
    # The runner still needs to know the REAL socket name
    "$SYNC_SCRIPT_PATH" "$REAL_SOCKET_NAME" &
    SYNC_PID=$!
else
    echo "WARNING: Clipboard sync script not found."
fi

if [ "$MANAGE_WINDOW" = true ]; then
    timeout 15 bash -c 'while ! /usr/bin/wmctrl -l | grep -q "Weston Compositor"; do sleep 0.5; done'
    /usr/bin/wmctrl -r "Weston Compositor" -b add,fullscreen
fi

# Launch Waydroid without any environment variables. It will find wayland-0 on its own.
waydroid show-full-ui &

echo "Waydroid ($MODE) is ready. Waiting for Weston to close..."
while ps -p $WESTON_PID > /dev/null; do
    sleep 2
done

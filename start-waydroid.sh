#!/bin/bash
# Final Version - Checks for dependencies and informs the user. Does not auto-install.

# --- Step 0: Find its sibling script ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SYNC_SCRIPT_PATH="$SCRIPT_DIR/waydroid-clipboard-sync.sh"

# --- Step 1: Dependency Check Function (Informational Only) ---
check_deps() {
    # This is the definitive list of required commands
    REQUIRED_CMDS=("zenity" "weston" "wmctrl" "xclip" "wl-copy")
    MISSING_CMDS=()
    echo "--- Checking for required commands ---"
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            MISSING_CMDS+=("$cmd")
        fi
    done

    # If anything is missing, display ONE clear error message and exit.
    if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
        ERROR_MSG="CRITICAL ERROR: Dependencies missing!\n\nThe launcher cannot start because the following commands are missing:\n\n -> ${MISSING_CMDS[*]}\n\nPlease install them according to the README.md instructions and try again."

        # Try to use zenity to show a graphical error, fallback to echo
        if command -v zenity &> /dev/null; then
            zenity --error --text="$ERROR_MSG" --width=450
        else
            echo -e "\n$ERROR_MSG\n"
        fi
        # Wait for user confirmation before exiting the terminal
        read -p "Press Enter to exit."
        exit 1
    fi
    echo "All dependencies are satisfied."
}

# --- Step 2: Cleanup Function ---
cleanup() {
    echo "Exit signal received, cleaning up..."
    if [[ -n "$SYNC_PID" && $(ps -p $SYNC_PID > /dev/null) ]]; then kill -9 $SYNC_PID; fi
    if [[ -n "$WESTON_PID" && $(ps -p $WESTON_PID > /dev/null) ]]; then kill -9 $WESTON_PID; fi
    # Clean up the symlink
    rm -f "$XDG_RUNTIME_DIR/wayland-0"
    waydroid session stop &> /dev/null
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
  --height=350 --width=550)

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
sleep 3

# --- THE SYMLINK HACK ---
REAL_SOCKET_FILE=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name "wayland-*" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)
if [ -z "$REAL_SOCKET_FILE" ]; then
    echo "CRITICAL ERROR: Failed to find the Wayland socket created by Weston."
    exit 1
fi
REAL_SOCKET_NAME=$(basename "$REAL_SOCKET_FILE")
WAYDROID_EXPECTED_SOCKET="$XDG_RUNTIME_DIR/wayland-0"
ln -sf "$REAL_SOCKET_NAME" "$WAYDROID_EXPECTED_SOCKET"
# --- END OF HACK ---

if [ -f "$SYNC_SCRIPT_PATH" ]; then
    "$SYNC_SCRIPT_PATH" "$REAL_SOCKET_NAME" &
    SYNC_PID=$!
else
    echo "WARNING: Clipboard sync script not found."
fi

if [ "$MANAGE_WINDOW" = true ]; then
    timeout 15 bash -c 'while ! /usr/bin/wmctrl -l | grep -q "Weston Compositor"; do sleep 0.5; done'
    /usr/bin/wmctrl -r "Weston Compositor" -b add,fullscreen
fi

waydroid show-full-ui &

echo "Waydroid ($MODE) is ready. Waiting for Weston to close..."
wait $WESTON_PID

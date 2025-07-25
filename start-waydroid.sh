#!/bin/bash
# Final Hybrid Version - Combines the stable "On-Demand" clipboard with the reliable "Symlink Hack" launcher.
# Co-developed by iskierek and an AI assistant.

# --- Dependency Check (informational only) ---
# We check for all dependencies for the launcher and its helpers here for a better user experience.
REQUIRED_CMDS=("zenity" "weston" "wmctrl" "xclip" "wl-copy" "wl-paste")
MISSING_CMDS=()
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_CMDS+=("$cmd")
    fi
done

if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
    ERROR_MSG="CRITICAL ERROR: Dependencies missing for the launcher!\n\nMissing commands:\n -> ${MISSING_CMDS[*]}\n\nPlease run the installer again or install them manually and try again."
    zenity --error --text="$ERROR_MSG" --width=450
    exit 1
fi

# --- Cleanup Function ---
cleanup() {
    echo "Exit signal received, cleaning up..."
    # Kill Weston process if it's still running
    if [[ -n "$WESTON_PID" && $(ps -p $WESTON_PID > /dev/null) ]]; then kill -9 $WESTON_PID; fi
    # Stop Waydroid session
    waydroid session stop &> /dev/null
    # Remove the temporary socket file (our "note in a bottle")
    rm -f /tmp/current_waydroid_socket
    # CRITICAL: Remove the symlink we created
    rm -f "$XDG_RUNTIME_DIR/wayland-0"
    echo "Cleanup complete."
}
trap cleanup EXIT

# ==============================================================================
# --- MAIN PROGRAM LOGIC ---
# ==============================================================================

MODE=$(zenity --list \
  --title="Select Waydroid Launch Mode" \
  --column="Mode" --column="Description" \
  "Fullscreen" "Runs in a borderless, fullscreen window." \
  "Windowed" "Runs in a standard portrait window (600x1000)." \
  "Custom Window" "Runs in a window with a custom size." \
  --height=350 --width=600)

if [ -z "$MODE" ]; then echo "Cancelled by user."; exit 0; fi

# Base Weston command, we DO NOT specify socket name here.
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

# Append the config file to the command
weston_cmd+=("--config=$CONFIG_FILE")

# --- Startup Logic ---
waydroid session stop &> /dev/null
# Clean up potential leftovers from a previous failed session
rm -f "$XDG_RUNTIME_DIR/wayland-0"
sleep 1
echo -e "$WESTON_CONFIG" > "$CONFIG_FILE"

# Launch Weston in the background
"${weston_cmd[@]}" &
WESTON_PID=$!
sleep 2 # Give Weston a moment to create its socket

# --- THE SYMLINK HACK (Restored & Integrated) ---
# Find the real socket file Weston created (the newest one)
REAL_SOCKET_FILE=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name "wayland-*" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)

if [ -z "$REAL_SOCKET_FILE" ]; then
    echo "CRITICAL ERROR: Failed to find the Wayland socket created by Weston."
    zenity --error --text="Failed to start Weston correctly. Could not find its Wayland socket."
    exit 1
fi
# Get just the filename
REAL_SOCKET_NAME=$(basename "$REAL_SOCKET_FILE")
# The name Waydroid always expects
WAYDROID_EXPECTED_SOCKET="$XDG_RUNTIME_DIR/wayland-0"
# Create the link to trick Waydroid
ln -sf "$REAL_SOCKET_NAME" "$WAYDROID_EXPECTED_SOCKET"
echo "Weston is running on socket: $REAL_SOCKET_NAME, linked to wayland-0"
# --- END OF HACK ---

# --- "Note in a Bottle" for our helper scripts ---
# Now we write the REAL socket name for our clipboard scripts to use.
echo "$REAL_SOCKET_NAME" > /tmp/current_waydroid_socket

# Manage fullscreen window if needed
if [ "$MANAGE_WINDOW" = true ]; then
    timeout 15 bash -c 'while ! /usr/bin/wmctrl -l | grep -q "Weston Compositor"; do sleep 0.5; done'
    /usr/bin/wmctrl -r "Weston Compositor" -b add,fullscreen
fi

# Finally, launch the Waydroid UI
waydroid show-full-ui &

echo "Waydroid ($MODE) is ready. Waiting for Weston to close..."
wait $WESTON_PID

#!/bin/bash
# Waydroid Launcher - clean socket version

# --- Dependency Check ---
REQUIRED_CMDS=("zenity" "weston" "wmctrl" "xclip" "wl-copy" "wl-paste" "waydroid" "xdotool")
MISSING_CMDS=()
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_CMDS+=("$cmd")
    fi
done

if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
    ERROR_MSG="CRITICAL ERROR: Missing programs:\n\n -> ${MISSING_CMDS[*]}\n\nPlease install them and run again."
    zenity --error --text="$ERROR_MSG" --width=400
    exit 1
fi

# --- Cleanup Function ---
cleanup() {
    echo "Cleaning up..."
    if [[ -n "$WESTON_PID" ]] && kill -0 "$WESTON_PID" 2>/dev/null; then
        kill -9 "$WESTON_PID"
    fi
    waydroid session stop &>/dev/null
    rm -f /tmp/current_waydroid_socket
    echo "Cleanup complete."
}
trap cleanup EXIT

# --- Select launch mode ---
MODE=$(zenity --list \
  --title="Select Waydroid Launch Mode" \
  --column="Mode" --column="Description" \
  "Fullscreen" "Runs in a borderless, fullscreen window." \
  "Windowed" "Runs in a 600x1000 window." \
  "Custom Window" "Runs in a custom-sized window." \
  --height=350 --width=600)

if [ -z "$MODE" ]; then echo "Cancelled."; exit 0; fi

# --- Common Weston settings ---
WAYLAND_SOCKET_NAME="wayland-wd"
weston_cmd=("weston" "--socket=$WAYLAND_SOCKET_NAME" "--backend=x11-backend.so")
CONFIG_FILE=""

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
    SIZE=$(zenity --entry --title="Enter Window Size" \
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

echo -e "$WESTON_CONFIG" > "$CONFIG_FILE"
weston_cmd+=("--config=$CONFIG_FILE")

# --- Stop leftovers ---
waydroid session stop &>/dev/null
sleep 1

# --- Start Weston ---
"${weston_cmd[@]}" &
WESTON_PID=$!
sleep 2

# Save socket name for clipboard helpers
echo "$WAYLAND_SOCKET_NAME" > /tmp/current_waydroid_socket

# --- Manage fullscreen ---
if [ "$MANAGE_WINDOW" = true ]; then
    timeout 15 bash -c 'while ! wmctrl -l | grep -q "Weston Compositor"; do sleep 0.5; done'
    wmctrl -r "Weston Compositor" -b add,fullscreen
fi

# --- Start Waydroid on same socket ---
WAYLAND_DISPLAY=$WAYLAND_SOCKET_NAME waydroid session start &
sleep 2
WAYLAND_DISPLAY=$WAYLAND_SOCKET_NAME waydroid show-full-ui &

echo "Waydroid running on socket: $WAYLAND_SOCKET_NAME"
wait $WESTON_PID

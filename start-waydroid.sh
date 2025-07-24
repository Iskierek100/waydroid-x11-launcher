#!/bin/bash
# Final Version: Stable clipboard sync, robust dependency checks.

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
            # Final check after installation attempt
            for pkg_cmd in "${!deps[@]}"; do
                if [[ " ${missing_pkgs[*]} " =~ " ${deps[$pkg_cmd]} " ]]; then
                    if ! command -v "$pkg_cmd" &> /dev/null; then
                        echo "CRITICAL ERROR: Package '${deps[$pkg_cmd]}' failed to install properly."
                        echo "Please try installing it manually: sudo apt install ${deps[$pkg_cmd]}"
                        exit 1
                    fi
                fi
            done
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
    if [ -n "$SOCKET_NAME" ]; then
        waydroid session stop &> /dev/null
    fi
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

weston_cmd=("weston" "--backend=x11-backend.so")
case "$MODE" in
  "Fullscreen")
    SOCKET_NAME="fullscreen"
    WESTON_CONFIG="[core]\nxwayland=true\n\n[shell]\npanel-position=none"
    MANAGE_WINDOW=true
    ;;
  "Windowed")
    SOCKET_NAME="windowed"
    weston_cmd+=("--width=600" "--height=1000")
    WESTON_CONFIG="[core]\nxwayland=true"
    MANAGE_WINDOW=false
    ;;
  "Custom Window")
    SOCKET_NAME="custom"
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
    ;;
esac

CONFIG_FILE="$HOME/.config/weston-${SOCKET_NAME}.ini"
weston_cmd+=("--socket=$SOCKET_NAME" "--config=$CONFIG_FILE")

# --- Startup Logic ---
waydroid session stop &> /dev/null
rm -f "/run/user/1000/$SOCKET_NAME"*
sleep 1
echo -e "$WESTON_CONFIG" > "$CONFIG_FILE"

echo "Launching Weston with options: ${weston_cmd[*]}"
"${weston_cmd[@]}" &
WESTON_PID=$!
sleep 2

if [ -f "$SYNC_SCRIPT_PATH" ]; then
    "$SYNC_SCRIPT_PATH" "$SOCKET_NAME" &
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
while ps -p $WESTON_PID > /dev/null; do
    sleep 2
done

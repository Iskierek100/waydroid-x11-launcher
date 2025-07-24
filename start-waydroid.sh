#!/bin/bash
# ==============================================================================
# Universal Launcher for Waydroid with custom window size
# Authors: iskierek & AI
# Version: 3.2 - English Translation & Refinements
# ==============================================================================

# Find the directory where the script is located
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# --- Function to check and install dependencies ---
check_and_install_deps() {
    declare -A deps=(
        ["weston"]="weston" ["wmctrl"]="wmctrl" ["xclip"]="xclip"
        ["wl-copy"]="wl-clipboard" ["zenity"]="zenity"
    )
    local missing_pkgs=()

    echo "--- Checking dependencies ---"
    for cmd in "${!deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "STATUS: Missing command '$cmd' (package: ${deps[$cmd]})"
            missing_pkgs+=("${deps[$cmd]}")
        else
            echo "STATUS: Command '$cmd' is installed."
        fi
    done

    missing_pkgs=($(printf "%s\n" "${missing_pkgs[@]}" | sort -u | tr '\n' ' '))

    if [ ${#missing_pkgs[@]} -ne 0 ]; then
        echo "------------------------------------------------------------------"
        echo "WARNING: The following packages are missing: ${missing_pkgs[*]}"
        if zenity --question --text="Some required packages are missing. Do you want to install them now?"; then
            (
                echo "# Updating package list...";
                sudo apt-get update;
                echo "# Installing missing packages: ${missing_pkgs[*]}...";
                sudo apt-get install -y "${missing_pkgs[@]}";
            ) | zenity --progress --title="Installing Dependencies" --pulsate --auto-close
            
            if [ $? -ne 0 ]; then
                zenity --error --text="Installation failed. Please check the terminal for errors."
                exit 1
            fi
        else
            zenity --info --text="Installation cancelled."
            exit 1
        fi
    else
        echo "All dependencies are satisfied."
    fi
    echo "------------------------------------------------------------------"
}

# --- START OF MAIN LOGIC ---

# Step 1: Check dependencies
check_and_install_deps

# Step 2: Ask the user to select the mode
MODE=$(zenity --list \
  --title="Select Waydroid Launch Mode" \
  --column="Mode" --column="Description" \
  "Fullscreen" "Runs in a borderless, fullscreen window." \
  "Windowed" "Runs in a standard portrait window (540x960)." \
  "Custom Window" "Runs in a window with a custom size." \
  --height=280 --width=550)

if [ -z "$MODE" ]; then echo "Cancelled by user."; exit 0; fi

# Step 3: Set variables and build the Weston command
weston_cmd=("weston" "--backend=x11-backend.so")

case "$MODE" in
  "Fullscreen")
    SOCKET_NAME="fullscreen"
    WESTON_CONFIG="[core]\nxwayland=true\n\n[shell]\npanel-position=none"
    MANAGE_WINDOW=true
    ;;
  "Windowed")
    SOCKET_NAME="windowed"
    weston_cmd+=("--width=540" "--height=960")
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
        zenity --error --text="Invalid format. Please provide two numbers separated by a space."; exit 1
    fi
    weston_cmd+=("--width=$WIDTH" "--height=$HEIGHT")
    WESTON_CONFIG="[core]\nxwayland=true"
    MANAGE_WINDOW=false
    ;;
esac

CONFIG_FILE="$HOME/.config/weston-${SOCKET_NAME}.ini"
weston_cmd+=("--socket=$SOCKET_NAME" "--config=$CONFIG_FILE")
SYNC_SCRIPT_PATH="$SCRIPT_DIR/waydroid-clipboard-sync.sh"

# --- Cleanup function ---
cleanup() {
    echo "Exit signal received, cleaning up session ($SOCKET_NAME)..."
    if [[ -n "$WESTON_PID" && $(ps -p $WESTON_PID > /dev/null) ]]; then kill -9 $WESTON_PID; fi
    if [[ -n "$SYNC_PID" && $(ps -p $SYNC_PID > /dev/null) ]]; then kill -9 $SYNC_PID; fi
    WAYLAND_DISPLAY=$SOCKET_NAME waydroid session stop &> /dev/null
}
trap cleanup EXIT

# --- Startup Logic ---
WAYLAND_DISPLAY=$SOCKET_NAME waydroid session stop &> /dev/null
rm -f "/run/user/1000/$SOCKET_NAME"*
sleep 1

echo -e "$WESTON_CONFIG" > "$CONFIG_FILE"

echo "Launching Weston with options: ${weston_cmd[*]}"
"${weston_cmd[@]}" &
WESTON_PID=$!

sleep 2 # Give it a moment to start

if [ -f "$SYNC_SCRIPT_PATH" ]; then
    SOCKET_NAME=$SOCKET_NAME "$SYNC_SCRIPT_PATH" &
    SYNC_PID=$!
fi

if [ "$MANAGE_WINDOW" = true ]; then
    # We only wait for the window in fullscreen mode
    timeout 15 bash -c 'while ! /usr/bin/wmctrl -l | grep -q "Weston Compositor"; do sleep 0.5; done'
    /usr/bin/wmctrl -r "Weston Compositor" -b add,fullscreen
fi

WAYLAND_DISPLAY=$SOCKET_NAME waydroid show-full-ui &
WAYLAND_DISPLAY=$SOCKET_NAME waydroid prop set persist.waydroid.immersive_mode true

echo "Waydroid ($MODE) is ready. The script will run as long as Weston is active."
while ps -p $WESTON_PID > /dev/null; do
    sleep 2
done

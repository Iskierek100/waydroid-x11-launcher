#!/bin/bash
# Wersja ostateczna - Tylko sprawdza zależności i uruchamia program.

# --- Krok 1: Sprawdzenie, czy wszystko jest na miejscu ---
REQUIRED_CMDS=("zenity" "weston" "wmctrl" "xclip" "wl-copy")
MISSING_CMDS=()
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_CMDS+=("$cmd")
    fi
done

# Jeśli czegoś brakuje, wyświetl JEDEN, zbiorczy komunikat i zakończ.
if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
    # Użyjemy zenity do wyświetlenia błędu, jeśli jest dostępne
    ERROR_MSG="CRITICAL ERROR: Dependencies missing!\n\nThe launcher cannot start because the following commands are missing:\n\n -> ${MISSING_CMDS[*]}\n\nPlease install them according to the README.md instructions and try again."

    if command -v zenity &> /dev/null; then
        zenity --error --text="$ERROR_MSG" --width=400
    else
        echo -e "$ERROR_MSG"
        read -p "Press Enter to exit."
    fi
    exit 1
fi

# --- Jeśli doszliśmy tutaj, to znaczy, że wszystko jest zainstalowane. ---

# Krok 2: Znajdź swoje rodzeństwo
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SYNC_SCRIPT_PATH="$SCRIPT_DIR/waydroid-clipboard-sync.sh"

# Krok 3: Funkcja sprzątająca
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
# --- GŁÓWNA LOGIKA PROGRAMU ---
# ==============================================================================

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

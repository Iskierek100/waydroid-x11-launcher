#!/bin/bash
# Clipboard synchronization script between X11 and Wayland (Weston)

# The socket name is passed as an environment variable by the main script.
# If it's not passed, it defaults to "fullscreen".
SOCKET_NAME=${SOCKET_NAME:-fullscreen}

echo "Clipboard sync started for socket: $SOCKET_NAME"

# Initialize the "memory" of our runner
last_x_clip=""
last_wl_clip=""

# Infinite loop to check for changes every second
while true; do
    # Check what is currently in the X11 clipboard
    current_x_clip=$(xclip -o -selection clipboard 2>/dev/null)

    # Check what is currently in the Wayland clipboard
    current_wl_clip=$(WAYLAND_DISPLAY=$SOCKET_NAME wl-paste 2>/dev/null)

    # --- DIRECTION 1: From X11 to Wayland ---
    # If the X11 clipboard has changed AND is not the same as the Wayland clipboard
    if [[ "$current_x_clip" != "$last_x_clip" && "$current_x_clip" != "$current_wl_clip" ]]; then
        echo "Sync: X11 -> Wayland"
        echo "$current_x_clip" | WAYLAND_DISPLAY=$SOCKET_NAME wl-copy
        last_x_clip="$current_x_clip"
        last_wl_clip="$current_x_clip" # Update both to prevent echo
    fi

    # --- DIRECTION 2: From Wayland to X11 ---
    # If the Wayland clipboard has changed AND is not the same as the X11 clipboard
    if [[ "$current_wl_clip" != "$last_wl_clip" && "$current_wl_clip" != "$current_x_clip" ]]; then
        echo "Sync: Wayland -> X11"
        echo "$current_wl_clip" | xclip -i -selection clipboard
        last_wl_clip="$current_wl_clip"
        last_x_clip="$current_wl_clip" # Update both to prevent echo
    fi

    sleep 1 # Wait a second before the next check
done

#!/bin/bash
# Final Version: "Super Lazy Runner" - for maximum stability

# This script expects the socket name as the first argument.
SOCKET_NAME=${1:-fullscreen}

# We don't need logs in the final version, but you can uncomment for debugging
# LOG_FILE="/tmp/lazy_runner_log.txt"
# echo "--- Lazy Runner started at $(date) for socket: $SOCKET_NAME ---" > "$LOG_FILE"

last_x_clip=$(xclip -o -selection clipboard 2>/dev/null)
last_wl_clip=$(WAYLAND_DISPLAY=$SOCKET_NAME wl-paste 2>/dev/null)

while true; do
    # Direction 1: From X11 to Wayland
    current_x_clip=$(xclip -o -selection clipboard 2>/dev/null)
    if [[ "$current_x_clip" != "$last_x_clip" ]]; then
        current_wl_clip_check=$(WAYLAND_DISPLAY=$SOCKET_NAME wl-paste 2>/dev/null)
        if [[ "$current_x_clip" != "$current_wl_clip_check" ]]; then
            echo "$current_x_clip" | WAYLAND_DISPLAY=$SOCKET_NAME wl-copy
        fi
        last_x_clip="$current_x_clip"
    fi

    # Direction 2: From Wayland to X11
    current_wl_clip=$(WAYLAND_DISPLAY=$SOCKET_NAME wl-paste 2>/dev/null)
    if [[ "$current_wl_clip" != "$last_wl_clip" ]]; then
        current_x_clip_check=$(xclip -o -selection clipboard 2>/dev/null)
        if [[ "$current_wl_clip" != "$current_x_clip_check" ]]; then
            echo "$current_wl_clip" | xclip -i -selection clipboard
        fi
        last_wl_clip="$current_wl_clip"
    fi
    
    # Sync the states after potential changes
    last_x_clip=$(xclip -o -selection clipboard 2>/dev/null)
    last_wl_clip=$(WAYLAND_DISPLAY=$SOCKET_NAME wl-paste 2>/dev/null)

    # A long sleep is key to stability
    sleep 3
done

#!/bin/bash
# Paste clipboard from Waydroid to X11 Desktop.

SOCKET_NAME=$(cat /tmp/current_waydroid_socket 2>/dev/null)

if [ -z "$SOCKET_NAME" ]; then
    zenity --error --text="Waydroid is not running or the socket file is missing." --width=350 --height=150
    exit 1
fi

WAYLAND_DISPLAY=$SOCKET_NAME wl-paste | xclip -i -selection clipboard
sleep 0.2
xdotool key --clearmodifiers ctrl+v

zenity --info --text="Clipboard content has been pasted into your current application!" --width=350 --height=150

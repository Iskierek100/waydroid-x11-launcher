#!/bin/bash
SOCKET_NAME=$(cat /tmp/current_waydroid_socket 2>/dev/null)

if [ -z "$SOCKET_NAME" ]; then
    zenity --error --text="Waydroid is not running or the socket file is missing." --width=350 --height=150
    exit 1
fi

xclip -o -selection clipboard | WAYLAND_DISPLAY=$SOCKET_NAME wl-copy
if [ $? -ne 0 ]; then
    zenity --error --text="Failed to copy to Waydroid clipboard!" --width=350 --height=150
    exit 2
fi

zenity --info --text="Clipboard sent to Waydroid." --width=300 --height=120

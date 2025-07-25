#!/bin/bash
SOCKET_NAME=$(cat /tmp/current_waydroid_socket 2>/dev/null)

if [ -z "$SOCKET_NAME" ]; then
    zenity --error --text="Waydroid is not running or the socket file is missing." --width=350 --height=150
    exit 1
fi

# Debug: pokaż co jest w schowku
xclip -o -selection clipboard > /tmp/waydroid_clipboard_debug.txt
cat /tmp/waydroid_clipboard_debug.txt

# Debug: spróbuj przekazać schowek i zapisz kod wyjścia
cat /tmp/waydroid_clipboard_debug.txt | WAYLAND_DISPLAY=$SOCKET_NAME wl-copy
echo $? > /tmp/waydroid_wlcopy_exitcode.txt

# Debug: sprawdź czy wl-copy się powiodło
if [ "$(cat /tmp/waydroid_wlcopy_exitcode.txt)" != "0" ]; then
    zenity --error --text="wl-copy failed! Check if Waydroid is running and the socket is correct." --width=350 --height=150
    exit 2
fi

zenity --info --text="Clipboard content has been sent to Waydroid!\n\nTo paste in an Android app:\n- Tap and hold in a text field, then select 'Paste'\n- Or use Ctrl+V if your app supports it." --width=350 --height=200

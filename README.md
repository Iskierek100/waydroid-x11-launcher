# Waydroid Universal X11 Launcher

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Works on: Linux](https://img.shields.io/badge/Works%20on-Linux-blue.svg)

A simple yet powerful script to run Waydroid seamlessly on any X11 desktop environment. It provides a user-friendly graphical menu to launch Waydroid in fullscreen, windowed, or custom-sized modes.

This project was envisioned and co-developed by **iskierek** and an AI assistant.

---

### Features

Features
* User-Friendly GUI Menu: Select your launch mode with a simple click.
* Multiple Launch Modes: Fullscreen, standard window, or custom-sized window.
* On-Demand Clipboard Sync: Uses keyboard shortcuts to sync the clipboard, avoiding background loops that cause instability on some systems (like KDE Plasma). This is the most stable method.
* Clean Session Management: Automatically starts and stops all related processes.

---

### Dependencies

⚠️ **Before using the launcher, you must manually install the required packages.**

* For the Launcher: zenity, weston, wmctrl
* For Clipboard Hotkeys: xclip, wl-clipboard, xdotool

#### Installation instructions for common distributions:

**For Debian / Ubuntu / Mint:**
```bash
sudo apt update
sudo apt install zenity weston wmctrl xclip wl-clipboard xdotool
```
For Arch Linux / Manjaro:
```bash
sudo pacman -Syu zenity weston wmctrl xclip wl-clipboard xdotool
```
For Fedora:
```bash
sudo dnf install zenity weston wmctrl xclip wl-clipboard xdotool
```
For openSUSE:
```bash
sudo zypper install zenity weston wmctrl xclip wl-clipboard xdotool
```
---
### Installation
1. Download the project files. You can do this in two ways:
   * As a ZIP file: Click the green < > Code button on this page, then select Download ZIP. Unzip the file after downloading.
   * Or using Git:
```bash
git clone https://github.com/Iskierek100/waydroid-x11-launcher.git
```
2. Navigate into the project directory:
```bash
cd waydroid-x11-launcher
```
3. Run the installer. It will copy the necessary files and create a launcher in your application menu.
```bash
chmod +x install.sh
./install.sh
```
This will copy the scripts to ~/.local/share/waydroid-launcher and create a "Waydroid Launcher" entry in your application menu.

---
### Usage
* Launch "Waydroid Launcher" from your application menu.
* Select your desired mode and Waydroid will start.

---
### IMPORTANT: Clipboard Setup (Keyboard Shortcuts)
This launcher uses on-demand scripts for clipboard sync for maximum stability.
If you use KDE Plasma or GNOME, the installer will try to set up the shortcuts automatically.
If not, you need to set up two global keyboard shortcuts in your desktop environment's settings (e.g., in KDE System Settings → Shortcuts → Custom Shortcuts).

1. Create Shortcut #1: Paste TO Waydroid
   Name: Paste to Waydroid
   Trigger (Shortcut): We suggest Alt+Meta+V (Alt+Windows+V)
   Action (Command): ~/.local/share/waydroid-launcher/paste_to_waydroid.sh

2. Create Shortcut #2: Paste TO X11 Desktop
   Name: Paste to X11
   Trigger (Shortcut): We suggest Ctrl+Meta+V (Ctrl+Windows+V)
   Action (Command): ~/.local/share/waydroid-launcher/paste_to_x11.sh

How to use the clipboard:

* To copy from desktop to Waydroid:
  First, copy text on your desktop as usual (Ctrl+C). Then, press Alt+Meta+V. Now you can paste inside Waydroid (long-press in a text field or use Ctrl+V if supported).
* To copy from Waydroid to desktop:
  First, copy text inside a Waydroid app. Then, press Ctrl+Meta+V. Now you can paste on your desktop (Ctrl+V).

---
### How to add global keyboard shortcuts in KDE Plasma (step by step):
1. Open System Settings
   Click on the application launcher (start menu) and search for System Settings. Open it.

2. Go to Shortcuts
   In the left sidebar, scroll down and click on Shortcuts.

3. Go to Custom Shortcuts
   In the Shortcuts section, click on Custom Shortcuts (sometimes called "Własne skróty" in Polish).

4. Create a new group (optional)
   Right-click in the left panel and select New Group. Name it, for example, Waydroid.

5. Add a new shortcut
   Right-click on your new group (or in the main area) and select New → Global Shortcut → Command/URL.

6. Configure the first shortcut ("Paste to Waydroid")
   Name: Paste to Waydroid
   Trigger: Click on the button and press Alt+Meta+V (Meta is usually the Windows key)
   Action: ~/.local/share/waydroid-launcher/paste_to_waydroid.sh
   Click Apply.

7. Add the second shortcut ("Paste to X11")
   Right-click again and select New → Global Shortcut → Command/URL.
   Name: Paste to X11
   Trigger: Click and press Ctrl+Meta+V
   Action: ~/.local/share/waydroid-launcher/paste_to_x11.sh
   Click Apply.

8. Test your shortcuts
   Try copying some text and use your new shortcuts.
   You should see a notification or window from the script.

---
### Tips:

* If the shortcut does not work, make sure the script files are executable (chmod +x ...).
* If you get a "command not found" error, check the path to your script.
* You can always edit or remove shortcuts from this menu.


---
### Troubleshooting
"Launcher icon does not appear in the menu"
* After running the installer, your desktop environment might need to refresh its application menu. The most reliable way to do this is to log out and log back in.

---
### ⚠️ Troubleshooting keyboard shortcuts in KDE Plasma
If your custom keyboard shortcuts do not work immediately, or you see a conflict warning, try the following steps:

1. Check for conflicts:
   If you see a message about a shortcut conflict, make sure the same key combination is not used elsewhere in your system.
   Remove or change any duplicate shortcuts in System Settings → Shortcuts → Custom Shortcuts or Global Shortcuts.

2. Restart your computer:
   Sometimes, KDE Plasma keeps "ghost" shortcuts in memory even after you remove or change them.
   A full system restart will clear these and allow your new shortcuts to work.

3. Check configuration files:
   If problems persist, check the following files for duplicate or conflicting shortcuts:

* ~/.config/khotkeysrc
* ~/.config/kglobalshortcutsrc
   You can search for your key combination with:
   grep -i "Meta+Alt+V" ~/.config/kglobalshortcutsrc

4. Re-add your shortcuts:
   If shortcuts still do not work, delete them and add them again in System Settings → Shortcuts → Custom Shortcuts.
   Click Apply after each change.

5. Make sure your scripts are executable:
***RUN:***
   
```bash
chmod +x ~/.local/share/waydroid-launcher/paste_to_waydroid.sh
chmod +x ~/.local/share/waydroid-launcher/paste_to_x11.sh
```

 ***Note:***
⚠️  After making changes to shortcuts, a full system restart is often required for KDE Plasma to fully refresh its shortcut configuration.

---
### License
This project is licensed under the MIT License - see the LICENSE file for details.

---
### Acknowledgments
* The Waydroid project team.
* The developers of Weston, wmctrl, and all the other tools that make this possible.

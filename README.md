# Waydroid Universal X11 Launcher

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Works on: Linux](https://img.shields.io/badge/Works%20on-Linux-blue.svg)

A simple yet powerful script to run Waydroid seamlessly on any X11 desktop environment. It provides a user-friendly graphical menu to launch Waydroid in fullscreen, windowed, or custom-sized modes.

This project was envisioned and co-developed by **iskierek** and an AI assistant.

---

### The Problem it Solves

Running Waydroid on a standard X11 desktop can be tricky. The Wayland environment used by Waydroid is isolated from the main X11 session, which can lead to issues with window management and a broken clipboard. This launcher solves these problems with a single, easy-to-use script.

### Features

*   **User-Friendly GUI Menu:** A simple graphical menu lets you choose how you want to run Waydroid.
*   **Multiple Launch Modes:**
    *   **Fullscreen:** True immersive fullscreen mode with no panels or borders.
    *   **Windowed:** A standard portrait-mode window, perfect for most apps.
    *   **Custom Size:** Launch in a window of any size you define.
*   **Bidirectional Clipboard Sync:** Seamlessly copy and paste text between your desktop (X11) and Waydroid (Wayland). *(Warning: This feature may be unstable on some desktop environments like KDE Plasma).*
*   **Clean Session Management:** The script ensures that all processes are started and stopped cleanly.

---

### Dependencies

Before you can use the launcher, you must manually install the required dependencies using your distribution's package manager.

**Required commands:** `zenity`, `weston`, `wmctrl`, `xclip`, `wl-clipboard`.

#### Installation instructions for common distributions:

**For Debian / Ubuntu / Mint:**
```bash
sudo apt update
sudo apt install zenity weston wmctrl xclip wl-clipboard
```
For Arch Linux / Manjaro:
```bash
sudo pacman -Syu zenity weston wmctrl xclip wl-clipboard
```
For Fedora:
```bash
sudo dnf install zenity weston wmctrl xclip wl-clipboard
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
### Usage
After installation, simply launch "Waydroid Launcher" from your application menu.
### Troubleshooting
"Launcher icon does not appear in the menu"
* After running the installer, your desktop environment might need to refresh its application menu. The most reliable way to do this is to log out and log back in.
---
### License
This project is licensed under the MIT License - see the LICENSE file for details.
### Acknowledgments
* The Waydroid project team.
* The developers of Weston, wmctrl, and all the other tools that make this possible.

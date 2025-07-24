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
*   **Bidirectional Clipboard Sync:** Seamlessly copy and paste text between your desktop (X11) and Waydroid (Wayland). *(This feature is experimental and may cause issues on some desktop environments like KDE Plasma).*
*   **Clean Session Management:** The script ensures that all processes are started and stopped cleanly.

---

### Dependencies

Before you can use the launcher, you must manually install the required dependencies using your distribution's package manager.

**Required commands:** `zenity`, `weston`, `wmctrl`, `xclip`, `wl-clipboard`, `qdbus`.

#### Installation instructions for common distributions:

**For Debian / Ubuntu / Mint:**
```bash
sudo apt update
sudo apt install zenity weston wmctrl xclip wl-clipboard qttools5-dev-tools
    
### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Acknowledgments

*   The Waydroid project team.
*   The developers of Weston, wmctrl, and all the other tools that make this possible.

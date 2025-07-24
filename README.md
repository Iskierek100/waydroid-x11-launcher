# waydroid-x11-launcher
A user-friendly launcher for running Waydroid in fullscreen or windowed mode on X11, with automatic dependency installation and clipboard sync.

# Waydroid Universal X11 Launcher

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Works on: Linux](https://img.shields.io/badge/Works%20on-Linux-blue.svg)

A simple yet powerful script to run Waydroid seamlessly on any X11 desktop environment. It provides a user-friendly graphical menu to launch Waydroid in fullscreen, windowed, or custom-sized modes, handling all the complex setup in the background.

This project was envisioned and co-developed by **iskierek** and an AI assistant.

---

### The Problem it Solves

Running Waydroid on a standard X11 desktop can be tricky. The Wayland environment used by Waydroid is isolated from the main X11 session, which leads to issues like a broken clipboard (copy/paste doesn't work) and difficulties in managing the application window. This launcher solves these problems with a single, easy-to-use script.

### Features

*   **User-Friendly GUI Menu:** A simple graphical menu lets you choose how you want to run Waydroid.
*   **Multiple Launch Modes:**
    *   **Fullscreen:** True immersive fullscreen mode with no panels or borders.
    *   **Windowed:** A standard portrait-mode window, perfect for most apps.
    *   **Custom Size:** Launch in a window of any size you define.
*   **Automatic Dependency Installation:** The script checks for required tools (`Weston`, `wmctrl`, etc.) and offers to install them for you.
*   **Bidirectional Clipboard Sync:** Seamlessly copy and paste text between your desktop (X11) and Waydroid (Wayland).
*   **Clean Session Management:** The script ensures that all processes are started and stopped cleanly, leaving no mess behind.
*   **Easy Installation:** A simple one-command installer sets everything up for you.

### Installation

1.  Download the project files. You can do this in two ways:
    *   **As a ZIP file:** Click the green `< > Code` button on this page, then select `Download ZIP`. Unzip the file after downloading.
    *   **Or using Git (for advanced users):**
        ```bash
        git clone https://github.com/Iskierek100/waydroid-x11-launcher.git
        ```
2.  Navigate into the project directory:
    ```bash
    cd waydroid-x11-launcher
    ```
3.  Make the installer executable and run it:
    ```bash
    chmod +x install.sh
    ./install.sh
    ```
4.  That's it! The installer will copy the necessary files and create a launcher in your application menu.

### Usage

After installation, you can launch Waydroid in two ways:

1.  **From your Application Menu:** Look for "Waydroid Launcher" and click it.
2.  **From your Terminal:** Simply type the command:
    ```bash
    start-waydroid
    ```

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Acknowledgments

*   The Waydroid project team.
*   The developers of Weston, wmctrl, and all the other tools that make this possible.

🖲️ KDE Plasma On/Off Switch Commands Plasmoid

A fully configurable command-based On/Off switch for KDE Plasma 6.5+.

This plasmoid allows you to run any custom shell commands when toggled ON or OFF, with visual feedback, color customization, and an optional automatic state watcher.
It’s ideal for toggling services, hardware controls, scripts, or system utilities directly from your desktop or panel.

✨ Features

⚙️ Command-based control: Assign shell commands for both ON and OFF states.

🟢 Dynamic visual feedback: Customizable text and colors for ON, OFF, and INACTIVE states.

🎨 Highly customizable UI:

Adjustable button width, height, font size, and padding

Border and background colors for each state

Opacity control for transparent buttons

🔁 Watcher mode: Periodically executes a custom command to reflect live system state.

🚀 Startup behavior: Automatically toggle ON or check state when Plasma starts.

🧩 Built for Plasma 6.5+: Uses metadata.json and QML best practices for KDE Plasma 6.

🧰 Installation
🔹 1. Clone this repository
git clone https://github.com/Intika-KDE-Plasmoids/plasmoid-on-off-switch-commands.git
cd plasmoid-on-off-switch-commands

🔹 2. Run the installer
chmod +x install.sh
./install.sh

The installer will:

Create the plasmoid structure under
~/.local/share/plasma/plasmoids/org.kde.plasma.onoffswitch/

Install metadata, QML, and configuration files

Restart the Plasma shell to apply changes

🖥️ Adding the Widget

Right-click your desktop or panel

Select “Add Widgets…”

Search for “On/Off Switch Commands”

Drag and drop it onto your panel or desktop

⚙️ Configuration

Right-click the widget → Configure On/Off Switch Commands…

Options include:

Command On / Off: Shell commands to execute when toggled

Text On / Off / Inactive: Display text for each state

Watcher Command: Automatically check external status (e.g., service state)

Watcher Interval: Interval in seconds (1–3600)

Colors: Background, border, and text colors for each state

Button Style: Width, height, border width, padding, font size, opacity

Startup Behavior: Execute ON command or check state on startup

🆕 New in v2.2.0

Added button width & height controls (0 = auto-size)

Added font size option (0 = default size)

Added background transparency control (0–100%)

Added border width & color customization for each state

Added button padding configuration

Improved Plasma 6.5+ compatibility

🧑‍💻 Example Use Cases
Task	                     Command ON	                            Command OFF
Toggle Wi-Fi	             nmcli radio wifi on	                  nmcli radio wifi off
Enable Bluetooth	         rfkill unblock bluetooth	              rfkill block bluetooth
Mount a drive	             mount /mnt/data	                      umount /mnt/data
Start/stop a service	     systemctl start nginx	                systemctl stop nginx
Enable dark mode	         plasma-apply-colorscheme BreezeDark	  plasma-apply-colorscheme BreezeLight

🔧 Uninstallation

To remove the plasmoid:
rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.onoffswitch
kquitapp6 plasmashell && kstart plasmashell &

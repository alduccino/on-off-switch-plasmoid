#!/bin/bash

# KDE Plasma 6.5 On/Off Switch Commands Plasmoid Installer
# This script installs and configures the plasmoid for KDE Plasma 6

set -e

PLASMOID_NAME="org.kde.plasma.onoffswitch"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_NAME"

echo "========================================="
echo "KDE Plasma 6.5 On/Off Switch Installer"
echo "========================================="
echo ""

# Check if running KDE Plasma
if [ -z "$KDE_SESSION_VERSION" ]; then
    echo "Warning: KDE Plasma session not detected. Continuing anyway..."
fi

# Create directory structure
echo "Creating directory structure..."
mkdir -p "$INSTALL_DIR/contents/ui"
mkdir -p "$INSTALL_DIR/contents/config"

# Create metadata.json (Plasma 6 uses JSON instead of desktop files)
echo "Creating metadata.json..."
cat > "$INSTALL_DIR/metadata.json" << 'EOF'
{
    "KPlugin": {
        "Authors": [
            {
                "Email": "intika@intika.com",
                "Name": "Intika"
            }
        ],
        "Category": "Utilities",
        "Description": "Widely configurable On/Off switch commands plasmoid",
        "Icon": "system-switch-user",
        "Id": "org.kde.plasma.onoffswitch",
        "License": "GPL-2.0+",
        "Name": "On/Off Switch Commands",
        "Version": "2.0.0",
        "Website": "https://github.com/Intika-KDE-Plasmoids/plasmoid-on-off-switch-commands"
    },
    "KPackageStructure": "Plasma/Applet",
    "X-Plasma-API-Minimum-Version": "6.0",
    "X-Plasma-Provides": [
        "org.kde.plasma.onoffswitch"
    ]
}
EOF

# Create main.qml
echo "Creating main.qml..."
cat > "$INSTALL_DIR/contents/ui/main.qml" << 'EOF'
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property bool switchState: true
    property bool isInactive: false
    property string currentStateText: ""
    property int executionType: 0 // 0=normal, 1=check, 2=watcher

    preferredRepresentation: fullRepresentation

    Component.onCompleted: {
        updateState()

        if (plasmoid.configuration.toggleOnStartup) {
            executeCommand(true)
        } else if (plasmoid.configuration.watchStateOnStartup) {
            checkCurrentState()
        }

        if (plasmoid.configuration.watcherEnabled) {
            watcherTimer.start()
        }
    }

    Timer {
        id: watcherTimer
        interval: plasmoid.configuration.watcherInterval * 1000
        running: false
        repeat: true
        onTriggered: {
            if (plasmoid.configuration.watcherCommand.trim() !== "") {
                executeWatcherCommand()
            }
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]

            disconnectSource(sourceName)

            if (executionType === 2) {
                handleWatcherResult(exitCode, stdout)
            } else if (executionType === 1) {
                handleCheckResult(exitCode)
            } else {
                handleCommandResult(exitCode, stdout, stderr)
            }

            executionType = 0
        }

        function exec(cmd, type) {
            if (cmd.trim() === "") return
            executionType = type
            connectSource(cmd)
        }
    }

    function executeCommand(newState) {
        var cmd = newState ? plasmoid.configuration.commandOn : plasmoid.configuration.commandOff

        if (cmd.trim() === "") {
            switchState = newState
            updateState()
            return
        }

        if (plasmoid.configuration.checkExecution) {
            executable.exec(cmd, 1) // check type
        } else {
            executable.exec(cmd, 0) // normal type
            switchState = newState
            updateState()
        }
    }

    function checkCurrentState() {
        var cmd = plasmoid.configuration.commandOn
        if (cmd.trim() !== "") {
            executable.exec(cmd, 1) // check type
        }
    }

    function executeWatcherCommand() {
        var cmd = plasmoid.configuration.watcherCommand
        if (cmd.trim() !== "") {
            executable.exec(cmd, 2) // watcher type
        }
    }

    function handleCommandResult(exitCode, stdout, stderr) {
        // Command executed, state remains as set
        updateState()
    }

    function handleCheckResult(exitCode) {
        switchState = (exitCode === 0)
        updateState()
    }

    function handleWatcherResult(exitCode, stdout) {
        if (exitCode === 0) {
            switchState = true
            isInactive = false
        } else {
            switchState = false
            if (plasmoid.configuration.customInactiveState) {
                isInactive = true
            }
        }
        updateState()
    }

    function updateState() {
        if (isInactive) {
            currentStateText = plasmoid.configuration.textInactive
        } else if (switchState) {
            currentStateText = plasmoid.configuration.textOn
        } else {
            currentStateText = plasmoid.configuration.textOff
        }

        toolTipMainText = plasmoid.configuration.tooltipText || "On/Off Switch"
    }

    function getBackgroundColor() {
        if (isInactive) {
            return plasmoid.configuration.colorInactive
        } else if (switchState) {
            return plasmoid.configuration.colorOn
        } else {
            return plasmoid.configuration.colorOff
        }
    }

    function getTextColor() {
        if (isInactive) {
            return plasmoid.configuration.textColorInactive
        } else if (switchState) {
            return plasmoid.configuration.textColorOn
        } else {
            return plasmoid.configuration.textColorOff
        }
    }

    toolTipMainText: plasmoid.configuration.tooltipText || "On/Off Switch"
    toolTipSubText: currentStateText

    fullRepresentation: Item {
        Layout.minimumWidth: switchButton.implicitWidth
        Layout.minimumHeight: switchButton.implicitHeight
        Layout.preferredWidth: switchButton.implicitWidth + Kirigami.Units.largeSpacing * 2
        Layout.preferredHeight: switchButton.implicitHeight + Kirigami.Units.largeSpacing

        PlasmaComponents.Button {
            id: switchButton
            anchors.centerIn: parent
            text: currentStateText
            checkable: true
            checked: switchState

            background: Rectangle {
                color: getBackgroundColor()
                radius: 4
                border.color: Qt.darker(getBackgroundColor(), 1.2)
                border.width: 1
            }

            contentItem: Text {
                text: switchButton.text
                color: getTextColor()
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font: switchButton.font
            }

            onClicked: {
                isInactive = false
                executeCommand(!switchState)
            }
        }
    }
}
EOF

# Create config.qml
echo "Creating config.qml..."
cat > "$INSTALL_DIR/contents/ui/config.qml" << 'EOF'
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_commandOn: commandOnField.text
    property alias cfg_commandOff: commandOffField.text
    property alias cfg_textOn: textOnField.text
    property alias cfg_textOff: textOffField.text
    property alias cfg_textInactive: textInactiveField.text
    property alias cfg_tooltipText: tooltipField.text
    property alias cfg_toggleOnStartup: toggleOnStartupCheck.checked
    property alias cfg_watchStateOnStartup: watchStateStartupCheck.checked
    property alias cfg_checkExecution: checkExecutionCheck.checked
    property alias cfg_customInactiveState: inactiveStateCheck.checked
    property alias cfg_colorOn: colorOnField.text
    property alias cfg_colorOff: colorOffField.text
    property alias cfg_colorInactive: colorInactiveField.text
    property alias cfg_textColorOn: textColorOnField.text
    property alias cfg_textColorOff: textColorOffField.text
    property alias cfg_textColorInactive: textColorInactiveField.text
    property alias cfg_watcherEnabled: watcherEnabledCheck.checked
    property alias cfg_watcherCommand: watcherCommandField.text
    property alias cfg_watcherInterval: watcherIntervalSpin.value

    ColumnLayout {
        spacing: 10

        GroupBox {
            Layout.fillWidth: true
            title: "Commands"

            ColumnLayout {
                anchors.fill: parent

                Label { text: "Command On:" }
                TextField {
                    id: commandOnField
                    Layout.fillWidth: true
                    placeholderText: "Command to execute when turning on"
                }

                Label { text: "Command Off:" }
                TextField {
                    id: commandOffField
                    Layout.fillWidth: true
                    placeholderText: "Command to execute when turning off"
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Display Text"

            ColumnLayout {
                anchors.fill: parent

                Label { text: "Text On:" }
                TextField {
                    id: textOnField
                    Layout.fillWidth: true
                    placeholderText: "ON"
                }

                Label { text: "Text Off:" }
                TextField {
                    id: textOffField
                    Layout.fillWidth: true
                    placeholderText: "OFF"
                }

                Label { text: "Text Inactive:" }
                TextField {
                    id: textInactiveField
                    Layout.fillWidth: true
                    placeholderText: "INACTIVE"
                }

                Label { text: "Tooltip:" }
                TextField {
                    id: tooltipField
                    Layout.fillWidth: true
                    placeholderText: "On/Off Switch"
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Colors"

            GridLayout {
                anchors.fill: parent
                columns: 2

                Label { text: "Background On:" }
                TextField {
                    id: colorOnField
                    Layout.fillWidth: true
                    placeholderText: "#4CAF50"
                }

                Label { text: "Background Off:" }
                TextField {
                    id: colorOffField
                    Layout.fillWidth: true
                    placeholderText: "#F44336"
                }

                Label { text: "Background Inactive:" }
                TextField {
                    id: colorInactiveField
                    Layout.fillWidth: true
                    placeholderText: "#9E9E9E"
                }

                Label { text: "Text Color On:" }
                TextField {
                    id: textColorOnField
                    Layout.fillWidth: true
                    placeholderText: "#FFFFFF"
                }

                Label { text: "Text Color Off:" }
                TextField {
                    id: textColorOffField
                    Layout.fillWidth: true
                    placeholderText: "#FFFFFF"
                }

                Label { text: "Text Color Inactive:" }
                TextField {
                    id: textColorInactiveField
                    Layout.fillWidth: true
                    placeholderText: "#FFFFFF"
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Behavior"

            ColumnLayout {
                anchors.fill: parent

                CheckBox {
                    id: toggleOnStartupCheck
                    text: "Execute ON command on startup"
                }

                CheckBox {
                    id: watchStateStartupCheck
                    text: "Watch state on startup"
                    enabled: !toggleOnStartupCheck.checked
                }

                CheckBox {
                    id: checkExecutionCheck
                    text: "Check execution state"
                }

                CheckBox {
                    id: inactiveStateCheck
                    text: "Enable custom inactive state"
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: "Watcher"

            ColumnLayout {
                anchors.fill: parent

                CheckBox {
                    id: watcherEnabledCheck
                    text: "Enable watcher"
                }

                Label { text: "Watcher Command:" }
                TextField {
                    id: watcherCommandField
                    Layout.fillWidth: true
                    placeholderText: "Command to check state periodically"
                    enabled: watcherEnabledCheck.checked
                }

                RowLayout {
                    Label { text: "Interval (seconds):" }
                    SpinBox {
                        id: watcherIntervalSpin
                        from: 1
                        to: 3600
                        value: 5
                        enabled: watcherEnabledCheck.checked
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
EOF

# Create config XML files
echo "Creating configuration files..."
cat > "$INSTALL_DIR/contents/config/main.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
      http://www.kde.org/standards/kcfg/1.0/kcfg.xsd" >
  <kcfgfile name=""/>

  <group name="General">
    <entry name="commandOn" type="String">
      <default></default>
    </entry>
    <entry name="commandOff" type="String">
      <default></default>
    </entry>
    <entry name="textOn" type="String">
      <default>ON</default>
    </entry>
    <entry name="textOff" type="String">
      <default>OFF</default>
    </entry>
    <entry name="textInactive" type="String">
      <default>INACTIVE</default>
    </entry>
    <entry name="tooltipText" type="String">
      <default>On/Off Switch</default>
    </entry>
    <entry name="toggleOnStartup" type="Bool">
      <default>true</default>
    </entry>
    <entry name="watchStateOnStartup" type="Bool">
      <default>false</default>
    </entry>
    <entry name="checkExecution" type="Bool">
      <default>false</default>
    </entry>
    <entry name="customInactiveState" type="Bool">
      <default>false</default>
    </entry>
    <entry name="colorOn" type="String">
      <default>#4CAF50</default>
    </entry>
    <entry name="colorOff" type="String">
      <default>#F44336</default>
    </entry>
    <entry name="colorInactive" type="String">
      <default>#9E9E9E</default>
    </entry>
    <entry name="textColorOn" type="String">
      <default>#FFFFFF</default>
    </entry>
    <entry name="textColorOff" type="String">
      <default>#FFFFFF</default>
    </entry>
    <entry name="textColorInactive" type="String">
      <default>#FFFFFF</default>
    </entry>
    <entry name="watcherEnabled" type="Bool">
      <default>false</default>
    </entry>
    <entry name="watcherCommand" type="String">
      <default></default>
    </entry>
    <entry name="watcherInterval" type="Int">
      <default>5</default>
    </entry>
  </group>
</kcfg>
EOF

cat > "$INSTALL_DIR/contents/config/config.qml" << 'EOF'
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "preferences-system"
        source: "config.qml"
    }
}
EOF

echo ""
echo "Installation completed successfully!"
echo "Installation directory: $INSTALL_DIR"
echo ""
echo "Restarting Plasma Shell..."
echo ""

# Restart Plasma Shell
if pgrep -x "plasmashell" > /dev/null; then
    echo "Killing existing plasmashell process..."
    killall plasmashell 2>/dev/null || true
    sleep 2
    echo "Starting plasmashell..."
    kstart plasmashell &
    sleep 3
    echo "Plasma Shell restarted!"
else
    echo "Plasmashell is not running. Starting it now..."
    kstart plasmashell &
    sleep 3
fi

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "To add the widget to your panel:"
echo "1. Right-click on your panel or desktop"
echo "2. Select 'Add Widgets...'"
echo "3. Search for 'On/Off Switch Commands'"
echo "4. Drag it to your panel or desktop"
echo ""
echo "To configure the widget:"
echo "1. Right-click on the widget"
echo "2. Select 'Configure On/Off Switch Commands...'"
echo ""
echo "Enjoy your upgraded KDE Plasma 6.5 plasmoid!"
echo ""

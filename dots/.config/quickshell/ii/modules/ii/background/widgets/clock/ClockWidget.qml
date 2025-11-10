import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.background.cookieClock
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Properties expected by Background.qml
    property real screenWidth: 0
    property real screenHeight: 0
    property real scaledScreenWidth: 0
    property real scaledScreenHeight: 0
    property real wallpaperScale: 1
    property bool wallpaperSafetyTriggered: false

    implicitHeight: contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth

    // Fortune quote properties
    property string fortuneQuote: "Loading quote..."
    readonly property string fallbackMessage: "Locked"

    // Timer to refresh the fortune quote periodically
    Timer {
        id: fortuneRefreshTimer
        interval: 300000 // 5 minutes
        repeat: true
        running: true
        onTriggered: getFortune()
    }

    // Get a fortune quote
    function getFortune() {
        if (!fortuneProcess.running) {
            fortuneProcess.running = true;
        }
    }

    // Process to run fortune command
    Process {
        id: fortuneProcess
        command: ["fortune", "-s"]
        stdout: StdioCollector {
            id: fortuneCollector
            onStreamFinished: {
                const output = fortuneCollector.text.trim();
                if (output.length > 0) {
                    root.fortuneQuote = output;
                } else {
                    root.fortuneQuote = root.fallbackMessage;
                }
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            // If fortune command failed and we don't have valid output, use fallback
            if (exitCode !== 0 && root.fortuneQuote === "Loading quote...") {
                root.fortuneQuote = root.fallbackMessage;
            }
        }
    }

    // Fetch fortune on lock
    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                root.getFortune();
            }
        }
    }

    Component.onCompleted: {
        root.getFortune();
    }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: 6

        // Cookie Clock from existing module
        CookieClock {
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Locked status text with fortune quote
        Item {
            id: statusText
            anchors.horizontalCenter: parent.horizontalCenter
            implicitHeight: statusTextBg.implicitHeight
            implicitWidth: statusTextBg.implicitWidth
            visible: GlobalStates.screenLocked && Config.options.lock.showLockedText

            DropShadow {
                source: statusTextBg
                anchors.fill: statusTextBg
                horizontalOffset: 0
                verticalOffset: 2
                radius: 12
                samples: radius * 2 + 1
                color: Appearance.colors.colShadow
                transparentBorder: true
            }

            Rectangle {
                id: statusTextBg
                anchors.centerIn: parent
                implicitHeight: statusTextRow.implicitHeight + 10
                implicitWidth: statusTextRow.implicitWidth + 16
                radius: Appearance.rounding.small
                color: Appearance.colors.colSecondaryContainer

                Row {
                    id: statusTextRow
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialSymbol {
                        id: quoteIcon
                        anchors.verticalCenter: parent.verticalCenter
                        iconSize: Appearance.font.pixelSize.huge
                        text: "format_quote"
                        color: Appearance.colors.colOnSecondaryContainer
                    }

                    StyledText {
                        id: statusTextWidget
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.fortuneQuote
                        color: Appearance.colors.colOnSecondaryContainer
                        font {
                            family: Appearance.font.family.reading
                            pixelSize: Appearance.font.pixelSize.large
                            weight: Font.Normal
                        }
                    }
                }
            }
        }
    }
}

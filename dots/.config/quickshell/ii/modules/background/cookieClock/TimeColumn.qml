pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: root
    property list<string> clockNumbers: DateTime.time.split(/[: ]/)
    property bool isEnabled: Config.options.background.clock.cookie.timeIndicators
    property color color: Appearance.colors.colOnSecondaryContainer

    property bool hourMarksEnabled: Config.options.background.clock.cookie.hourMarks
    property string quoteText: "Loading quote..."
    readonly property string fallbackMessage: "Fortune favors the bold"
    spacing: -16

    // Timer to refresh the quote periodically
    Timer {
        id: refreshTimer
        interval: 300000 // 5 minutes
        repeat: true
        running: GlobalStates.screenLocked
        onTriggered: getFortune()
    }

    // Get a fortune quote
    function getFortune() {
        if (!fortuneProcess.running) {
            fortuneProcess.running = true;
        }
    }

    // Fetch fortune when screen becomes locked
    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                root.getFortune();
            }
        }
    }

    Component.onCompleted: {
        if (GlobalStates.screenLocked) {
            getFortune();
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
                    root.quoteText = output;
                } else {
                    root.quoteText = root.fallbackMessage;
                }
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            // If fortune command failed and we don't have valid output, use fallback
            if (exitCode !== 0 && root.quoteText === "Loading quote...") {
                root.quoteText = root.fallbackMessage;
            }
        }
    }

    // Show quote when locked, time when unlocked
    Loader {
        anchors.horizontalCenter: root.horizontalCenter
        active: GlobalStates.screenLocked
        sourceComponent: StyledText {
            text: root.quoteText
            color: root.color
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: 200
            font {
                family: Appearance.font.family.reading
                weight: Font.Normal
                pixelSize: 16
            }
        }
    }

    Repeater {
        model: GlobalStates.screenLocked ? [] : root.clockNumbers

        delegate: StyledText {
            required property string modelData
            text: modelData.padStart(2, "0")
            property bool isAmPm: !text.match(/\d{2}/i)
            property real numberSizeWithoutGlow: isAmPm ? 26 : 68
            property real numberSizeWithGlow: isAmPm ? 20 : 40
            property real numberSize: root.hourMarksEnabled ? numberSizeWithGlow : numberSizeWithoutGlow

            anchors.horizontalCenter: root.horizontalCenter
            color: root.color
            font {
                family: Appearance.font.family.expressive
                weight: Font.Bold
                pixelSize: numberSize
            }

            Behavior on numberSize {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
        }
    }
}

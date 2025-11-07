pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Configuration properties
    readonly property string configPosition: Config.options?.background.fortune.position ?? "bottom-right"
    
    // Widget dimensions (base size, scaled by config)
    readonly property real baseWidth: 400
    readonly property real baseHeight: 150
    width: baseWidth * (Config.options?.background.fortune.scale ?? 1.0)
    height: baseHeight * (Config.options?.background.fortune.scale ?? 1.0)

    // Position the widget based on configuration
    anchors {
        bottom: configPosition.includes("bottom") ? parent.bottom : undefined
        top: configPosition.includes("top") ? parent.top : undefined
        right: configPosition.includes("right") ? parent.right : undefined
        left: configPosition.includes("left") ? parent.left : undefined
        bottomMargin: Config.options?.background.fortune.marginY ?? 20
        topMargin: Config.options?.background.fortune.marginY ?? 20
        rightMargin: Config.options?.background.fortune.marginX ?? 20
        leftMargin: Config.options?.background.fortune.marginX ?? 20
    }

    property string fortuneText: "Loading quote..."
    readonly property string fallbackMessage: "Fortune not available. Install fortune package."

    // Timer to refresh the quote periodically
    Timer {
        id: refreshTimer
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

    Component.onCompleted: {
        getFortune();
    }

    // Process to run fortune command
    Process {
        id: fortuneProcess
        command: ["fortune"]
        stdout: StdioCollector {
            id: fortuneCollector
            onStreamFinished: {
                const output = fortuneCollector.text.trim();
                if (output.length > 0) {
                    root.fortuneText = output;
                } else {
                    root.fortuneText = root.fallbackMessage;
                }
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            // Only show fallback if fortune command failed (non-zero exit code)
            // and we don't already have valid output
            if (exitCode !== 0 && root.fortuneText === "Loading quote...") {
                root.fortuneText = root.fallbackMessage;
            }
        }
    }

    // Shadow effect
    DropShadow {
        source: quoteBox
        anchors.fill: quoteBox
        horizontalOffset: 0
        verticalOffset: 2
        radius: 12
        samples: radius * 2 + 1
        color: Appearance.colors.colShadow
        transparentBorder: true
    }

    // The quote box
    Rectangle {
        id: quoteBox
        anchors.fill: parent
        radius: Config.options?.background.fortune.roundness ?? Appearance.rounding.medium
        
        readonly property color configColor: Config.options?.background.fortune.color ?? "#00000000"
        readonly property bool useDefaultColor: configColor.a === 0 // Transparent means use default
        
        color: Qt.rgba(
            useDefaultColor ? Appearance.colors.colSecondaryContainer.r : configColor.r,
            useDefaultColor ? Appearance.colors.colSecondaryContainer.g : configColor.g,
            useDefaultColor ? Appearance.colors.colSecondaryContainer.b : configColor.b,
            Config.options?.background.fortune.opacity ?? 0.7
        )

        Column {
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8

            // Icon and title
            Row {
                spacing: 6
                width: parent.width

                MaterialSymbol {
                    id: fortuneIcon
                    iconSize: Appearance.font.pixelSize.huge
                    text: "lightbulb"
                    color: Appearance.colors.colOnSecondaryContainer
                }

                StyledText {
                    text: "Random Quote"
                    color: Appearance.colors.colOnSecondaryContainer
                    font {
                        family: Appearance.font.family.expressive
                        pixelSize: Appearance.font.pixelSize.large
                        weight: Font.Medium
                    }
                }
            }

            // Quote text
            StyledText {
                id: quoteText
                width: parent.width
                wrapMode: Text.WordWrap
                text: root.fortuneText
                color: Appearance.colors.colOnSecondaryContainer
                font {
                    family: Appearance.font.family.reading
                    pixelSize: {
                        const configSize = Config.options?.background.fortune.textSize ?? 0;
                        return configSize > 0 ? configSize : Appearance.font.pixelSize.normal;
                    }
                    weight: Font.Normal
                }
            }
        }
    }
}

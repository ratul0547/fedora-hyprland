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

    // Widget dimensions
    width: 400
    height: 150

    // Position the widget in a corner (bottom-right by default)
    anchors {
        bottom: parent.bottom
        right: parent.right
        bottomMargin: 20
        rightMargin: 20
    }

    property string fortuneText: "Loading quote..."

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
        fortuneProcess.running = true;
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
                    root.fortuneText = "Fortune not available. Install fortune-mod package.";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                // If fortune fails, provide a fallback message
                root.fortuneText = "Fortune not available. Install fortune-mod package.";
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
        radius: Appearance.rounding.medium
        color: Qt.rgba(
            Appearance.colors.colSecondaryContainer.r,
            Appearance.colors.colSecondaryContainer.g,
            Appearance.colors.colSecondaryContainer.b,
            0.7
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
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Normal
                }
            }
        }
    }
}

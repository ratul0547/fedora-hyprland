import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io


Item {
    id: root

    property string quoteText: "Loading quote..."
    readonly property string fallbackMessage: Config.options.background.quote || "No quote available"

    implicitWidth: quoteBox.implicitWidth
    implicitHeight: quoteBox.implicitHeight

    anchors.bottom: parent.bottom
    anchors.bottomMargin: -24

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
    
    Rectangle {
        id: quoteBox

        implicitWidth: quoteStyledText.width + quoteIcon.width + 16 // for spacing on both sides
        implicitHeight: quoteStyledText.height + 8 
        radius: Appearance.rounding.small
        color: Appearance.colors.colSecondaryContainer

        Row {
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol {
                id: quoteIcon
                anchors.top: parent.top
                iconSize: Appearance.font.pixelSize.huge
                text: "format_quote"
                color: Appearance.colors.colOnSecondaryContainer
            }
            StyledText {
                id: quoteStyledText
                horizontalAlignment: Text.AlignLeft
                text: root.quoteText
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
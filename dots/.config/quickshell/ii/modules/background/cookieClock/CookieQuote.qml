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
    readonly property real screenWidth: root.QsWindow?.window?.screen?.width ?? 1920
    readonly property real maxQuoteWidth: Math.min(screenWidth * 0.6, 800)  // 60% of screen width, max 800px

    implicitWidth: quoteBox.width
    implicitHeight: quoteBox.height

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
        stdout: SplitParser {
            onRead: data => {
                const output = data.trim();
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

        width: root.maxQuoteWidth
        height: quoteRow.height + 16
        radius: Appearance.rounding.small
        color: Appearance.colors.colSecondaryContainer

        Row {
            id: quoteRow
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 8
            }
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
                width: parent.width - quoteIcon.width - parent.spacing
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                text: root.quoteText
                renderType: Text.QtRendering  // Better antialiasing when resizing
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
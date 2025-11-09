import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.background.cookieClock

Item {
    id: root

    required property real screenWidth
    required property real screenHeight
    required property real scaledScreenWidth
    required property real scaledScreenHeight
    required property real wallpaperScale
    required property bool wallpaperSafetyTriggered

    // Position the clock based on the screen dimensions
    property real clockSize: Math.min(screenWidth, screenHeight) * 0.2
    property real quoteBottomMargin: clockSize * 0.15

    // Main container
    Item {
        anchors.fill: parent

        // Cookie Clock
        CookieClock {
            id: cookieClock
            anchors.centerIn: parent
            implicitSize: root.clockSize
        }

        // Cookie Quote positioned below the clock
        CookieQuote {
            id: cookieQuote
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: cookieClock.bottom
                topMargin: root.quoteBottomMargin
            }
        }
    }
}

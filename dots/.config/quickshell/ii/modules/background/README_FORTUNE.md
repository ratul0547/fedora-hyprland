# Fortune Widget

A simple background widget that displays random quotes using the `fortune` program.

## Features

- Displays random quotes from the fortune database
- Automatically refreshes every 5 minutes
- Positioned in the bottom-right corner of the screen
- Semi-transparent background with drop shadow
- Gracefully handles cases where fortune is not installed

## Installation Requirements

The widget requires the `fortune` program to be installed on your system.

### Fedora/RHEL:
```bash
sudo dnf install fortune-mod
```

### Arch Linux:
```bash
sudo pacman -S fortune-mod
```

### Debian/Ubuntu:
```bash
sudo apt install fortune-mod
```

## Widget Properties

- **Position**: Bottom-right corner with 20px margins
- **Size**: 400x150 pixels
- **Refresh Rate**: 5 minutes (300000ms)
- **Fallback**: Shows a friendly message if fortune is not installed

## Usage

The FortuneWidget is automatically included in the Background module and will appear on all screens when the background is enabled.

If you want to disable it, simply comment out or remove the widget from `Background.qml`:

```qml
// Fortune Widget - displays random quotes
// FortuneWidget {
//     id: fortuneWidget
// }
```

## Customization

You can customize the widget by modifying `FortuneWidget.qml`:

- Change position by modifying the `anchors` properties
- Adjust refresh interval by changing the `Timer.interval` value
- Modify appearance by editing the styling in the `Rectangle` component
- Change the icon by modifying the `MaterialSymbol.text` property

## Implementation Details

The widget uses Quickshell's `Process` component to run the `fortune` command and capture its output. The quote is displayed in a styled rectangle with a lightbulb icon and title.

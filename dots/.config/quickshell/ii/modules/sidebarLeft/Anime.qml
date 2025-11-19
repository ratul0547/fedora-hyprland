import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.sidebarLeft.anime
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell

Item {
    id: root
    property real padding: 4

    property var inputField: tagInputField
    readonly property var responses: Booru.responses
    property string previewDownloadPath: Directories.booruPreviews
    property string downloadPath: Directories.booruDownloads
    property string nsfwPath: Directories.booruDownloadsNsfw
    property string commandPrefix: "/"
    property real scrollOnNewResponse: 100
    property int tagSuggestionDelay: 210
    property var suggestionQuery: ""
    property var suggestionList: []

    property bool pullLoading: false
    property int pullLoadingGap: 80
    property real normalizedPullDistance: Math.max(0, (1 - Math.exp(-booruResponseListView.verticalOvershoot / 50)) * booruResponseListView.dragging)

    Connections {
        target: Booru
        function onTagSuggestion(query, suggestions) {
            root.suggestionQuery = query;
            root.suggestionList = suggestions;
        }
        function onRunningRequestsChanged() {
            if (Booru.runningRequests === 0) {
                root.pullLoading = false;
            }
        }
    }

    property var allCommands: [
        {
            name: "mode",
            description: Translation.tr("Set the current API provider"),
            execute: (args) => {
                Booru.setProvider(args[0]);
            }
        },
        {
            name: "clear",
            description: Translation.tr("Clear the current list of images"),
            execute: () => {
                Booru.clearResponses();
            }
        },
        {
            name: "next",
            description: Translation.tr("Get the next page of results"),
            execute: () => {
                if (root.responses.length > 0) {
                    const lastResponse = root.responses[root.responses.length - 1];
                    // Check if this is a Reddit response by checking the provider
                    if (lastResponse.provider === "reddit") {
                        // For Reddit, set the pagination token from the last response before making the next request
                        if (lastResponse.paginationToken) {
                            Booru.redditLastAfter = lastResponse.paginationToken;
                        }
                        // Use the stored command and increment page
                        Booru.makeRedditRequest(Booru.redditLastCommand, Persistent.states.booru.allowNsfw, Config.options.sidebar.booru.limit, parseInt(lastResponse.page) + 1);
                    } else {
                        // For regular boorus, append page number to tags
                        root.handleInput(`${lastResponse.tags.join(" ")} ${parseInt(lastResponse.page) + 1}`);
                    }
                } else {
                    root.handleInput("");
                }
            }
        },
        {
            name: "safe",
            description: Translation.tr("Disable NSFW content"),
            execute: () => {
                Persistent.states.booru.allowNsfw = false;
            }
        },
        {
            name: "lewd",
            description: Translation.tr("Allow NSFW content"),
            execute: () => {
                Persistent.states.booru.allowNsfw = true;
            }
        },
    ]

    function handleInput(inputText) {
        // Check for Reddit-specific commands first (when using Reddit provider)
        if (Booru.currentProvider === "reddit") {
            if (inputText.startsWith("/s ") || inputText.startsWith("/s") ||
                inputText.startsWith("r/") || inputText.startsWith("u/")) {
                Booru.makeRedditRequest(inputText, Persistent.states.booru.allowNsfw, Config.options.sidebar.booru.limit, 1);
            return;
                }
        }

        // Handle standard commands (mode, clear, next, safe, lewd)
        if (inputText.startsWith(root.commandPrefix)) {
            // Handle special commands
            const command = inputText.split(" ")[0].substring(1);
            const args = inputText.split(" ").slice(1);
            const commandObj = root.allCommands.find(cmd => cmd.name === `${command}`);
            if (commandObj) {
                commandObj.execute(args);
            } else {
                Booru.addSystemMessage(Translation.tr("Unknown command: ") + command);
            }
        }
        else if (inputText.trim() == "+") {
            root.handleInput(`${root.commandPrefix}next`);
        }
        else if (Booru.currentProvider === "reddit") {
            // Invalid Reddit input - show help message
            Booru.addSystemMessage(Translation.tr("For Reddit, use: r/pics, r/pics /top day, /s query, r/pics /s query /new"));
        }
        else {
            // Create tag list for regular boorus
            const tagList = inputText.split(/\s+/).filter(tag => tag.length > 0);
            let pageIndex = 1;
            for (let i = 0; i < tagList.length; ++i) { // Detect page number
                if (/^\d+$/.test(tagList[i])) {
                    pageIndex = parseInt(tagList[i], 10);
                    tagList.splice(i, 1);
                    break;
                }
            }
            Booru.makeRequest(tagList, Persistent.states.booru.allowNsfw, Config.options.sidebar.booru.limit, pageIndex);
        }
    }

    onFocusChanged: (focus) => {
        if (focus) {
            tagInputField.forceActiveFocus()
        }
    }

    property real pageKeyScrollAmount: booruResponseListView.height / 2
    Keys.onPressed: (event) => {
        tagInputField.forceActiveFocus()
        if (event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageUp) {
                if (booruResponseListView.atYBeginning) return;
                booruResponseListView.contentY = Math.max(0, booruResponseListView.contentY - root.pageKeyScrollAmount)
                event.accepted = true
            } else if (event.key === Qt.Key_PageDown) {
                if (booruResponseListView.atYEnd) return;
                booruResponseListView.contentY = Math.min(booruResponseListView.contentHeight, booruResponseListView.contentY + root.pageKeyScrollAmount)
                event.accepted = true
            }
        }
        if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_O) {
            Booru.clearResponses()
        }
    }


    ColumnLayout {
        id: columnLayout
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: root.padding

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: swipeView.width
                    height: swipeView.height
                    radius: Appearance.rounding.small
                }
            }

            ScrollEdgeFade {
                z: 1
                target: booruResponseListView
                vertical: true
            }

            StyledListView { // Booru responses
                id: booruResponseListView
                z: 0
                anchors.fill: parent
                spacing: 10

                touchpadScrollFactor: Config.options.interactions.scrolling.touchpadScrollFactor * 1.4
                mouseScrollFactor: Config.options.interactions.scrolling.mouseScrollFactor * 1.4

                property int lastResponseLength: 0
                Connections {
                    target: root
                    function onResponsesChanged() {
                        if (root.responses.length > booruResponseListView.lastResponseLength) {
                            if (booruResponseListView.lastResponseLength > 0 && root.responses[booruResponseListView.lastResponseLength].provider != "system")
                                booruResponseListView.contentY = booruResponseListView.contentY + root.scrollOnNewResponse
                                booruResponseListView.lastResponseLength = root.responses.length
                        }
                    }
                }

                model: ScriptModel {
                    values: root.responses
                }
                delegate: BooruResponse {
                    responseData: modelData
                    tagInputField: root.inputField
                    previewDownloadPath: root.previewDownloadPath
                    downloadPath: root.downloadPath
                    nsfwPath: root.nsfwPath
                }

                onDragEnded: { // Pull to load more
                    const gap = booruResponseListView.verticalOvershoot
                    if (gap > root.pullLoadingGap) {
                        root.pullLoading = true
                        root.handleInput(`${root.commandPrefix}next`)
                    }
                }
            }

            PagePlaceholder {
                id: placeholderItem
                z: 2
                shown: root.responses.length === 0
                icon: "bookmark_heart"
                title: Booru.currentProvider === "reddit" ? Translation.tr("Reddit Images") : Translation.tr("Anime boorus")
                description: Booru.currentProvider === "reddit"
                ? Translation.tr("Try: r/pics /top day, r/aww /best, r/earthporn /s sunset, /s cats /new")
                : ""
                shape: MaterialShape.Shape.Bun
            }

            ScrollToBottomButton {
                z: 3
                target: booruResponseListView
            }

            MaterialLoadingIndicator {
                id: loadingIndicator
                z: 4
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 20 + (root.pullLoading ? 0 : Math.max(0, (root.normalizedPullDistance - 0.5) * 50))
                    Behavior on bottomMargin {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                        }
                    }
                }
                loading: root.pullLoading || Booru.runningRequests > 0
                pullProgress: Math.min(1, booruResponseListView.verticalOvershoot / root.pullLoadingGap * booruResponseListView.dragging)
                scale: root.pullLoading ? 1 : Math.min(1, root.normalizedPullDistance * 2)
            }
        }

        DescriptionBox { // Tag suggestion description
            text: root.suggestionList[tagSuggestions.selectedIndex]?.description ?? ""
            showArrows: root.suggestionList.length > 1
        }

        FlowButtonGroup { // Tag suggestions
            id: tagSuggestions
            visible: root.suggestionList.length > 0 && tagInputField.text.length > 0
            property int selectedIndex: 0
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                id: tagSuggestionRepeater
                model: {
                    tagSuggestions.selectedIndex = 0
                    return root.suggestionList.slice(0, 10)
                }
                delegate: ApiCommandButton {
                    id: tagButton
                    colBackground: tagSuggestions.selectedIndex === index ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer
                    bounce: false
                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        StyledText {
                            Layout.fillWidth: false
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSecondaryContainer
                            horizontalAlignment: Text.AlignRight
                            text: modelData.displayName ?? modelData.name
                        }
                        StyledText {
                            Layout.fillWidth: false
                            visible: modelData.count !== undefined
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSecondaryContainer
                            horizontalAlignment: Text.AlignLeft
                            text: modelData.count ?? ""
                        }
                    }

                    onHoveredChanged: {
                        if (tagButton.hovered) {
                            tagSuggestions.selectedIndex = index;
                        }
                    }
                    onClicked: {
                        tagSuggestions.acceptTag(modelData.name)
                    }
                }
            }

            function acceptTag(tag) {
                const words = tagInputField.text.trim().split(/\s+/);
                if (words.length > 0) {
                    words[words.length - 1] = tag;
                } else {
                    words.push(tag);
                }
                const updatedText = words.join(" ") + " ";
                tagInputField.text = updatedText;
                tagInputField.cursorPosition = tagInputField.text.length;
                tagInputField.forceActiveFocus();
            }

            function acceptSelectedTag() {
                if (tagSuggestions.selectedIndex >= 0 && tagSuggestions.selectedIndex < tagSuggestionRepeater.count) {
                    const tag = root.suggestionList[tagSuggestions.selectedIndex].name;
                    tagSuggestions.acceptTag(tag);
                }
            }
        }

        Rectangle { // Tag input area
            id: tagInputContainer
            property real columnSpacing: 5
            Layout.fillWidth: true
            radius: Appearance.rounding.normal - root.padding
            color: Appearance.colors.colLayer2
            implicitWidth: tagInputField.implicitWidth
            implicitHeight: Math.max(inputFieldRowLayout.implicitHeight + inputFieldRowLayout.anchors.topMargin
            + commandButtonsRow.implicitHeight + commandButtonsRow.anchors.bottomMargin + columnSpacing, 45)
            clip: true

            Behavior on implicitHeight {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

            RowLayout { // Input field and send button
                id: inputFieldRowLayout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 5
                spacing: 0

                StyledTextArea { // The actual TextArea
                    id: tagInputField
                    wrapMode: TextArea.Wrap
                    Layout.fillWidth: true
                    padding: 10
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    renderType: Text.NativeRendering
                    placeholderText: Booru.currentProvider === "reddit"
                    ? Translation.tr('r/pics, r/pics /top day, /s query')
                    : Translation.tr('Enter tags, or "%1" for commands').arg(root.commandPrefix)

                    background: null

                    property Timer searchTimer: Timer { // Timer for tag suggestions
                        interval: root.tagSuggestionDelay
                        repeat: false
                        onTriggered: {
                            const inputText = tagInputField.text
                            const words = inputText.trim().split(/\s+/);
                            if (words.length > 0) {
                                Booru.triggerTagSearch(words[words.length - 1]);
                            }
                        }
                    }

                    onTextChanged: { // Handle tag suggestions
                        if(tagInputField.text.length === 0) {
                            root.suggestionQuery = ""
                            root.suggestionList = []
                            searchTimer.stop();
                            return
                        }
                        if(tagInputField.text.startsWith(`${root.commandPrefix}mode`)) {
                            root.suggestionQuery = tagInputField.text.split(" ")[1] ?? ""
                            const providerResults = Fuzzy.go(root.suggestionQuery, Booru.providerList.map(provider => {
                                return {
                                    name: Fuzzy.prepare(provider),
                                                                                                          obj: provider,
                                }
                            }), {
                                all: true,
                                key: "name"
                            })
                            root.suggestionList = providerResults.map(provider => {
                                return {
                                    name: `${tagInputField.text.trim().split(" ").length == 1 ? (root.commandPrefix + "mode ") : ""}${provider.target}`,
                                                                      displayName: `${Booru.providers[provider.target].name}`,
                                                                      description: `${Booru.providers[provider.target].description}`,
                                }
                            })
                            searchTimer.stop();
                            return
                        }
                        // Reddit-specific suggestions
                        if (Booru.currentProvider === "reddit") {
                            if (tagInputField.text.startsWith("/s") || tagInputField.text.startsWith("r/") ||
                                tagInputField.text.includes(" /s") || tagInputField.text.includes(" /top") || 
                                tagInputField.text.includes(" /new") || tagInputField.text.includes(" /best") || 
                                tagInputField.text.includes(" /hot")) {
                                const parts = tagInputField.text.split(/\s+/);
                                const suggestions = [];

                                // Suggest /s for search
                                if (tagInputField.text === "/s" || tagInputField.text === "/s ") {
                                    suggestions.push({name: "/s ", description: Translation.tr("Search all of Reddit")});
                                }
                                // Suggest options when r/subreddit is typed alone
                                else if (parts[0].startsWith("r/") && parts.length === 1) {
                                    suggestions.push(
                                        {name: `${parts[0]} /s `, description: Translation.tr("Search in this subreddit")},
                                        {name: `${parts[0]} /top day`, description: Translation.tr("Top posts today")},
                                        {name: `${parts[0]} /best`, description: Translation.tr("Best posts")},
                                        {name: `${parts[0]} /hot`, description: Translation.tr("Hot posts")},
                                        {name: `${parts[0]} /new`, description: Translation.tr("New posts")}
                                    );
                                }
                                // When r/subreddit /top is typed, suggest time filters
                                else if (parts[0].startsWith("r/") && parts.length === 2 && parts[1] === "/top") {
                                    suggestions.push(
                                        {name: `${parts[0]} /top all`, description: Translation.tr("All time")},
                                        {name: `${parts[0]} /top day`, description: Translation.tr("Today")},
                                        {name: `${parts[0]} /top week`, description: Translation.tr("This week")},
                                        {name: `${parts[0]} /top month`, description: Translation.tr("This month")}
                                    );
                                }
                                // Suggest sort modifiers when there's a search query
                                else if (tagInputField.text.includes("/s ") && parts.length >= 2) {
                                    const hasTopModifier = parts.includes("/top");
                                    const hasNewModifier = parts.includes("/new");
                                    const hasHotModifier = parts.includes("/hot");
                                    
                                    if (!hasTopModifier && !hasNewModifier && !hasHotModifier) {
                                        suggestions.push(
                                            {name: `${tagInputField.text} /top all`, description: Translation.tr("Sort by top (all time)")},
                                            {name: `${tagInputField.text} /top day`, description: Translation.tr("Sort by top (today)")},
                                            {name: `${tagInputField.text} /new`, description: Translation.tr("Sort by newest")}
                                        );
                                    }
                                    // If /top exists but no time, suggest time filters
                                    else if (hasTopModifier) {
                                        const topIndex = parts.indexOf("/top");
                                        const hasTime = topIndex + 1 < parts.length && ["day", "week", "month", "year", "all"].includes(parts[topIndex + 1]);
                                        if (!hasTime) {
                                            suggestions.push(
                                                {name: `${tagInputField.text} all`, description: Translation.tr("All time")},
                                                {name: `${tagInputField.text} day`, description: Translation.tr("Today")},
                                                {name: `${tagInputField.text} week`, description: Translation.tr("This week")}
                                            );
                                        }
                                    }
                                }

                                if (suggestions.length > 0) {
                                    root.suggestionQuery = tagInputField.text;
                                    root.suggestionList = suggestions;
                                    searchTimer.stop();
                                    return;
                                }
                            }
                        }

                        if(tagInputField.text.startsWith(root.commandPrefix)) {
                            root.suggestionQuery = tagInputField.text
                            root.suggestionList = root.allCommands.filter(cmd => cmd.name.startsWith(tagInputField.text.substring(1))).map(cmd => {
                                return {
                                    name: `${root.commandPrefix}${cmd.name}`,
                                    description: `${cmd.description}`,
                                }
                            })
                            searchTimer.stop();
                            return
                        }
                        searchTimer.restart();
                    }

                    function accept() {
                        root.handleInput(text)
                        text = ""
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Tab) {
                            tagSuggestions.acceptSelectedTag();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            tagSuggestions.selectedIndex = Math.max(0, tagSuggestions.selectedIndex - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            tagSuggestions.selectedIndex = Math.min(root.suggestionList.length - 1, tagSuggestions.selectedIndex + 1);
                            event.accepted = true;
                        } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                // Insert newline
                                tagInputField.insert(tagInputField.cursorPosition, "\n")
                                event.accepted = true
                            } else { // Accept text
                                const inputText = tagInputField.text
                                root.handleInput(inputText)
                                tagInputField.clear()
                                event.accepted = true
                            }
                        }
                    }
                }

                RippleButton { // Send button
                    id: sendButton
                    Layout.alignment: Qt.AlignTop
                    Layout.rightMargin: 5
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    enabled: tagInputField.text.length > 0
                    toggled: enabled

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: sendButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            const inputText = tagInputField.text
                            root.handleInput(inputText)
                            tagInputField.clear()
                        }
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: 22
                        color: sendButton.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                        text: "arrow_upward"
                    }
                }
            }

            RowLayout { // Controls
                id: commandButtonsRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                spacing: 5

                property var commandsShown: [
                    {
                        name: "mode",
                        sendDirectly: false,
                    },
                    {
                        name: "clear",
                        sendDirectly: true,
                    },
                ]

                ApiInputBoxIndicator { // Tool indicator
                    icon: "api"
                    text: Booru.providers[Booru.currentProvider].name
                    tooltipText: Translation.tr("Current API endpoint: %1\nSet it with %2mode PROVIDER")
                    .arg(Booru.providers[Booru.currentProvider].url)
                    .arg(root.commandPrefix)
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer1
                    text: "•"
                }

                MouseArea { // NSFW toggle
                    visible: width > 0
                    implicitWidth: switchesRow.implicitWidth
                    Layout.fillHeight: true

                    hoverEnabled: true
                    PointingHandInteraction {}
                    onPressed: {
                        nsfwSwitch.checked = !nsfwSwitch.checked
                    }



                    RowLayout {
                        id: switchesRow
                        spacing: 5
                        anchors.centerIn: parent

                        StyledText {
                            Layout.fillHeight: true
                            Layout.leftMargin: 10
                            Layout.alignment: Qt.AlignVCenter
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: nsfwSwitch.enabled ? Appearance.colors.colOnLayer1 : Appearance.m3colors.m3outline
                            text: Booru.currentProvider === "reddit"
                            ? Translation.tr("NSFW Mode")
                            : Translation.tr("Allow NSFW")
                        }
                        StyledSwitch {
                            id: nsfwSwitch
                            enabled: Booru.currentProvider !== "zerochan"
                            scale: 0.6
                            Layout.alignment: Qt.AlignVCenter
                            checked: (Persistent.states.booru.allowNsfw && Booru.currentProvider !== "zerochan")
                            onCheckedChanged: {
                                if (!nsfwSwitch.enabled) return;
                                Persistent.states.booru.allowNsfw = checked;
                            }
                        }
                    }

                }

                Item { Layout.fillWidth: true }

                ButtonGroup {
                    padding: 0
                    Repeater { // Command buttons
                        id: commandRepeater
                        model: commandButtonsRow.commandsShown
                        delegate: ApiCommandButton {
                            property string commandRepresentation: `${root.commandPrefix}${modelData.name}`
                            buttonText: commandRepresentation
                            colBackground: Appearance.colors.colLayer2

                            downAction: () => {
                                if (modelData.sendDirectly) {
                                    root.handleInput(commandRepresentation)
                                } else {
                                    tagInputField.text = commandRepresentation + " "
                                    tagInputField.cursorPosition = tagInputField.text.length
                                    tagInputField.forceActiveFocus()
                                }
                                if (modelData.name === "clear") {
                                    tagInputField.text = ""
                                }
                            }
                        }
                    }
                }
            }

        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import dk.john.folderbrowser 1.0

ApplicationWindow {
    id: root
    width: 1000
    height: 620
    visible: true
    title: "folder-browser - CXX-Qt local explorer"
    color: windowBackgroundColor

    property var allRows: []
    property string sortColumn: "name"
    property bool sortAscending: true
    property bool showHidden: false
    property string filterText: ""

    property int rowHeight: 32
    property int fileIconSize: rowHeight
    property string rowFontFamily: "Maple Mono NF"

    property bool foldersFirst: true
    property bool foldersAlwaysAZ: true
    property string sizeUnit: "auto"

    property var selectedPaths: []
    property int lastSelectedIndex: -1

    property color windowBackgroundColor: "#17191d"
    property color titleTextColor: "#f9fafb"
    property color panelBackgroundColor: "#20242b"
    property color panelBorderColor: "#3b4252"
    property color panelFocusBorderColor: "#60a5fa"
    property color headerBackgroundColor: "#111827"
    property color headerTextColor: "#f9fafb"
    property color rowEvenColor: "#1f2937"
    property color rowOddColor: "#20242b"
    property color selectedRowColor: "#7f1d1d"
    property color keyboardCurrentRowColor: "#14532d"
    property color activeSortHeaderColor: "#374151"
    property color activeSortColumnColor: "#2b3544"
    property color activeSortColumnSelectedColor: "#991b1b"
    property color activeSortColumnCurrentColor: "#2A894D"
    property color activeSortBorderColor: "#60a5fa"
    property color folderTextColor: "#bfdbfe"
    property color fileTextColor: "#e5e7eb"
    property color secondaryTextColor: "#d1d5db"
    property color emptyTextColor: "#d8dee9"
    property color dateHighlightColor: "#f97316"
    property color sizeUnknownColor: "#7f1d1d"
    property color sizeScanningColor: "#9ca3af"
    property color sizeDoneColor: "#22c55e"
    property color sizeErrorColor: "#ef4444"
    property var colorDefinitions: [
        ({ key: "windowBackgroundColor", label: "Window background", defaultValue: "#17191d" }),
        ({ key: "titleTextColor", label: "Title text", defaultValue: "#f9fafb" }),
        ({ key: "panelBackgroundColor", label: "Panel background", defaultValue: "#20242b" }),
        ({ key: "panelBorderColor", label: "Panel border", defaultValue: "#3b4252" }),
        ({ key: "panelFocusBorderColor", label: "Focused panel border", defaultValue: "#60a5fa" }),
        ({ key: "headerBackgroundColor", label: "Header background", defaultValue: "#111827" }),
        ({ key: "headerTextColor", label: "Header text", defaultValue: "#f9fafb" }),
        ({ key: "rowEvenColor", label: "Even row", defaultValue: "#1f2937" }),
        ({ key: "rowOddColor", label: "Odd row", defaultValue: "#20242b" }),
        ({ key: "selectedRowColor", label: "Selected row", defaultValue: "#7f1d1d" }),
        ({ key: "keyboardCurrentRowColor", label: "Keyboard current row", defaultValue: "#14532d" }),
        ({ key: "activeSortHeaderColor", label: "Sorted header", defaultValue: "#374151" }),
        ({ key: "activeSortColumnColor", label: "Sorted column", defaultValue: "#2b3544" }),
        ({ key: "activeSortColumnSelectedColor", label: "Sorted column selected", defaultValue: "#991b1b" }),
        ({ key: "activeSortColumnCurrentColor", label: "Sorted column keyboard current", defaultValue: "#2A894D" }),
        ({ key: "activeSortBorderColor", label: "Sorted/focus border", defaultValue: "#60a5fa" }),
        ({ key: "folderTextColor", label: "Folder name text", defaultValue: "#bfdbfe" }),
        ({ key: "fileTextColor", label: "File name text", defaultValue: "#e5e7eb" }),
        ({ key: "secondaryTextColor", label: "Secondary text", defaultValue: "#d1d5db" }),
        ({ key: "emptyTextColor", label: "Empty/list message text", defaultValue: "#d8dee9" }),
        ({ key: "dateHighlightColor", label: "Date highlight", defaultValue: "#f97316" }),
        ({ key: "sizeUnknownColor", label: "Size unknown", defaultValue: "#7f1d1d" }),
        ({ key: "sizeScanningColor", label: "Size scanning", defaultValue: "#9ca3af" }),
        ({ key: "sizeDoneColor", label: "Size done", defaultValue: "#22c55e" }),
        ({ key: "sizeErrorColor", label: "Size error", defaultValue: "#ef4444" })
    ]

    function loadColorSettings() {
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            let definition = colorDefinitions[index]
            root[definition.key] = colorSettings[definition.key] || definition.defaultValue
        }
    }

    function applyColorSettings() {
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            let key = colorDefinitions[index].key
            colorSettings[key] = String(root[key])
        }
    }

    function resetColorSetting(key) {
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            if (colorDefinitions[index].key === key) {
                root[key] = colorDefinitions[index].defaultValue
                return
            }
        }
    }

    function resetAllColors() {
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            root[colorDefinitions[index].key] = colorDefinitions[index].defaultValue
        }
    }

    function localPathFromUrl(urlValue) {
        let text = String(urlValue);
        if (text.startsWith("file://")) {
            return decodeURIComponent(text.replace(/^file:\/\//, ""));
        }
        return text;
    }

    function fileUriFromPath(pathText) {
        let text = String(pathText || "");
        if (text.startsWith("file://")) {
            return text;
        }
        if (!text.startsWith("/")) {
            return text;
        }
        return "file://" + text.split("/").map(function (part) {
            return encodeURIComponent(part);
        }).join("/");
    }

    function uriListFromPath(pathText) {
        return fileUriFromPath(pathText) + "\r\n";
    }

    function htmlEscape(textValue) {
        return String(textValue || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
    }

    function highlightedFileName(fileName) {
        let escaped = htmlEscape(fileName);
        let datePattern = /(\b\d{4}[-_.]\d{2}[-_.]\d{2}\b|\b\d{8}\b|\b\d{2}[-_.]\d{2}[-_.]\d{4}\b)/g;
        return escaped.replace(datePattern, "<span style='color:" + dateHighlightColor + "'>$1</span>");
    }

    function matchesFilter(row) {
        let query = String(filterText || "").trim().toLowerCase();
        if (query.length === 0) {
            return true;
        }
        if (!row) {
            return false;
        }
        return String(row.name || "").toLowerCase().indexOf(query) >= 0 || String(row.kind || "").toLowerCase().indexOf(query) >= 0 || String(row.path || "").toLowerCase().indexOf(query) >= 0;
    }

    function fileExtension(fileName) {
        let name = String(fileName || "").toLowerCase();
        let index = name.lastIndexOf(".");
        if (index <= 0 || index === name.length - 1) {
            return "";
        }
        return name.slice(index + 1);
    }

    function fileIconName(row) {
        if (!row)
            return "text-x-generic";
        if (row.isDir)
            return "folder";
        if (row.kind === "symlink")
            return "emblem-symbolic-link";

        let ext = fileExtension(row.name);
        if (["png", "jpg", "jpeg", "gif", "webp", "bmp", "tif", "tiff", "svg", "heic", "avif"].indexOf(ext) >= 0)
            return "image-x-generic";
        if (["mp4", "mkv", "webm", "avi", "mov", "m4v", "mpg", "mpeg", "wmv"].indexOf(ext) >= 0)
            return "video-x-generic";
        if (["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac", "wma"].indexOf(ext) >= 0)
            return "audio-x-generic";
        if (ext === "pdf")
            return "application-pdf";
        if (["zip", "7z", "rar", "tar", "gz", "xz", "bz2", "zst"].indexOf(ext) >= 0)
            return "package-x-generic";
        if (["rs", "py", "sh", "bash", "fish", "js", "ts", "qml", "cpp", "c", "h", "hpp", "lua"].indexOf(ext) >= 0)
            return "text-x-script";
        if (["txt", "md", "json", "toml", "yaml", "yml", "xml", "csv", "log"].indexOf(ext) >= 0)
            return "text-x-generic";
        if (["odt", "doc", "docx", "rtf"].indexOf(ext) >= 0)
            return "x-office-document";
        if (["ods", "xls", "xlsx"].indexOf(ext) >= 0)
            return "x-office-spreadsheet";
        if (["odp", "ppt", "pptx"].indexOf(ext) >= 0)
            return "x-office-presentation";
        if (["appimage", "exe", "bin", "run"].indexOf(ext) >= 0)
            return "application-x-executable";
        if (ext === "desktop")
            return "application-x-desktop";
        return "text-x-generic";
    }

    function parentPath(pathText) {
        let text = String(pathText);
        if (text.length <= 1)
            return "/";
        if (text.endsWith("/") && text.length > 1)
            text = text.slice(0, -1);
        let index = text.lastIndexOf("/");
        return index <= 0 ? "/" : text.slice(0, index);
    }

    function pad2(value) {
        return String(value).padStart(2, "0");
    }

    function modifiedText(seconds) {
        if (seconds === null || seconds === undefined || seconds < 0)
            return "";
        let date = new Date(seconds * 1000);
        return date.getFullYear() + "-" + pad2(date.getMonth() + 1) + "-" + pad2(date.getDate()) + " " + pad2(date.getHours()) + ":" + pad2(date.getMinutes()) + ":" + pad2(date.getSeconds());
    }

    function isHiddenRow(row) {
        return row && row.name && String(row.name).startsWith(".");
    }

    function filterRows(rows) {
        let source = Array.from(rows || []);
        if (!showHidden) {
            source = source.filter(function (row) {
                return !isHiddenRow(row);
            });
        }
        return source.filter(function (row) {
            return matchesFilter(row);
        });
    }

    function compareText(left, right) {
        return String(left || "").localeCompare(String(right || ""), Qt.locale(), {
            sensitivity: "base",
            numeric: true
        });
    }

    function compareNullableNumber(left, right) {
        let leftMissing = left === null || left === undefined || left < 0;
        let rightMissing = right === null || right === undefined || right < 0;
        if (leftMissing && rightMissing)
            return 0;
        if (leftMissing)
            return 1;
        if (rightMissing)
            return -1;
        return Number(left) - Number(right);
    }

    function sortRows(rows) {
        let sorted = Array.from(rows || []);
        let column = sortColumn;

        sorted.sort(function (left, right) {
            if (foldersFirst && left.isDir !== right.isDir) {
                return left.isDir ? -1 : 1;
            }

            let result = 0;
            if (column === "name") {
                result = compareText(left.name, right.name);
                if (foldersAlwaysAZ && left.isDir && right.isDir)
                    return result;
            } else if (column === "kind") {
                result = compareText(left.kind, right.kind);
            } else if (column === "size") {
                result = compareNullableNumber(left.sizeBytes, right.sizeBytes);
            } else if (column === "modified") {
                result = compareNullableNumber(left.modifiedSecs, right.modifiedSecs);
            }

            if (result === 0) {
                result = left.isDir !== right.isDir ? (left.isDir ? -1 : 1) : compareText(left.name, right.name);
            }
            return sortAscending ? result : -result;
        });
        return sorted;
    }

    function sortLabel(columnName, title) {
        if (sortColumn !== columnName)
            return title;
        return title + (sortAscending ? " ▲" : " ▼");
    }

    function setSort(columnName) {
        if (sortColumn === columnName) {
            sortAscending = !sortAscending;
        } else {
            sortColumn = columnName;
            sortAscending = true;
        }
        refreshDisplayedRows();
        fileList.forceActiveFocus();
    }

    function setSizeUnit(unitName) {
        sizeUnit = unitName;
        refreshDisplayedRows();
    }

    function europeanNumber(value, decimals) {
        if (value === null || value === undefined || value < 0 || !isFinite(value))
            return "";
        let fixed = Number(value).toFixed(decimals);
        let parts = fixed.split(".");
        let integerPart = parts[0];
        let decimalPart = parts.length > 1 ? parts[1] : "";
        let withThousands = "";
        while (integerPart.length > 3) {
            withThousands = "." + integerPart.slice(-3) + withThousands;
            integerPart = integerPart.slice(0, -3);
        }
        withThousands = integerPart + withThousands;
        return decimals > 0 ? withThousands + "," + decimalPart : withThousands;
    }

    function displaySize(sizeBytes, row) {
        if (row && row.isDir && row.sizeStatus === "unknown")
            return "unknown";
        if (sizeBytes === null || sizeBytes === undefined || sizeBytes < 0)
            return "";

        let bytes = Number(sizeBytes);
        if (sizeUnit === "auto") {
            let units = ["B", "kB", "MB", "GB", "TB"];
            let index = 0;
            let value = bytes;
            while (value >= 1000 && index < units.length - 1) {
                value /= 1000;
                index += 1;
            }
            return europeanNumber(value, 2) + " " + units[index];
        }

        let divisor = 1;
        let suffix = "B";
        if (sizeUnit === "kb") {
            divisor = 1000;
            suffix = "kB";
        } else if (sizeUnit === "mb") {
            divisor = 1000000;
            suffix = "MB";
        } else if (sizeUnit === "gb") {
            divisor = 1000000000;
            suffix = "GB";
        } else if (sizeUnit === "tb") {
            divisor = 1000000000000;
            suffix = "TB";
        }
        return europeanNumber(bytes / divisor, 2) + " " + suffix;
    }

    function sizeColor(row) {
        if (!row || !row.isDir)
            return secondaryTextColor;
        if (row.sizeStatus === "unknown")
            return selectedRowColor;
        if (row.sizeStatus === "scanning")
            return sizeScanningColor;
        if (row.sizeStatus === "done")
            return sizeDoneColor;
        if (row.sizeStatus === "error")
            return sizeErrorColor;
        return secondaryTextColor;
    }

    function rebuildRowsFromController() {
        let rows = [];
        for (let row = 0; row < controller.rowCount; row += 1) {
            rows.push({
                name: controller.fileName(row),
                kind: controller.fileKind(row),
                sizeBytes: controller.fileSizeBytes(row),
                sizeStatus: controller.fileSizeStatus(row),
                modifiedSecs: controller.fileModifiedSecs(row),
                path: controller.filePath(row),
                isDir: controller.fileIsDir(row)
            });
        }
        allRows = rows;
        refreshDisplayedRows();
    }

    function refreshDisplayedRows() {
        let rows = sortRows(filterRows(allRows));
        fileModel.clear();
        for (let index = 0; index < rows.length; index += 1) {
            fileModel.append(rows[index]);
        }
        if (fileModel.count > 0) {
            fileList.currentIndex = Math.max(0, Math.min(fileList.currentIndex, fileModel.count - 1));
        } else {
            fileList.currentIndex = -1;
        }
    }

    function scanPath(pathText) {
        pathField.text = String(pathText);
        controller.scanPath(pathField.text);
        selectedPaths = [];
        lastSelectedIndex = -1;
        rebuildRowsFromController();
        Qt.callLater(function () {
            fileList.forceActiveFocus();
        });
    }

    function openRow(row) {
        if (!row)
            return;
        if (row.isDir)
            scanPath(row.path);
        else
            controller.statusText = "Selected file: " + row.path;
    }

    function openCurrentRow() {
        if (fileList.currentIndex >= 0 && fileList.currentIndex < fileModel.count) {
            openRow(fileModel.get(fileList.currentIndex));
        }
    }

    function rowPathAt(index) {
        if (index < 0 || index >= fileModel.count)
            return "";
        return fileModel.get(index).path;
    }

    function isPathSelected(pathText) {
        return selectedPaths.indexOf(pathText) >= 0;
    }

    function isRowSelected(index) {
        return isPathSelected(rowPathAt(index));
    }

    function setSingleSelection(index) {
        let path = rowPathAt(index);
        selectedPaths = path.length > 0 ? [path] : [];
        lastSelectedIndex = index;
    }

    function toggleSelection(index) {
        let path = rowPathAt(index);
        if (path.length === 0)
            return;
        let copy = Array.from(selectedPaths);
        let existing = copy.indexOf(path);
        if (existing >= 0)
            copy.splice(existing, 1);
        else
            copy.push(path);
        selectedPaths = copy;
        lastSelectedIndex = index;
    }

    function selectRange(index) {
        let anchor = lastSelectedIndex >= 0 ? lastSelectedIndex : fileList.currentIndex;
        if (anchor < 0)
            anchor = index;
        let first = Math.min(anchor, index);
        let last = Math.max(anchor, index);
        let paths = [];
        for (let row = first; row <= last; row += 1) {
            let path = rowPathAt(row);
            if (path.length > 0)
                paths.push(path);
        }
        selectedPaths = paths;
    }

    function handleShiftCursorSelection(direction) {
        if (fileModel.count <= 0) {
            return;
        }

        let oldIndex = fileList.currentIndex;
        if (oldIndex < 0) {
            oldIndex = 0;
        }

        let newIndex = Math.max(0, Math.min(fileModel.count - 1, oldIndex + direction));
        if (lastSelectedIndex < 0) {
            lastSelectedIndex = oldIndex;
        }

        fileList.currentIndex = newIndex;
        selectRange(newIndex);
        fileList.positionViewAtIndex(newIndex, ListView.Contain);
        fileList.forceActiveFocus();
    }

    function handleRowPress(mouse, index) {
        fileList.currentIndex = index;
        fileList.forceActiveFocus();
        if (mouse.modifiers & Qt.ShiftModifier) {
            selectRange(index);
        } else if (mouse.modifiers & Qt.ControlModifier) {
            toggleSelection(index);
        } else {
            setSingleSelection(index);
        }
    }

    FolderBrowserController {
        id: controller
        currentPath: root.localPathFromUrl(StandardPaths.writableLocation(StandardPaths.HomeLocation))
        statusText: "Ready"
        rowCount: 0
        updateGeneration: 0
        onUpdateGenerationChanged: rebuildRowsFromController()
    }

    ListModel {
        id: fileModel
    }

    Settings {
        id: colorSettings
        category: "Colors"
        property string windowBackgroundColor: "#17191d"
        property string titleTextColor: "#f9fafb"
        property string panelBackgroundColor: "#20242b"
        property string panelBorderColor: "#3b4252"
        property string panelFocusBorderColor: "#60a5fa"
        property string headerBackgroundColor: "#111827"
        property string headerTextColor: "#f9fafb"
        property string rowEvenColor: "#1f2937"
        property string rowOddColor: "#20242b"
        property string selectedRowColor: "#7f1d1d"
        property string keyboardCurrentRowColor: "#14532d"
        property string activeSortHeaderColor: "#374151"
        property string activeSortColumnColor: "#2b3544"
        property string activeSortColumnSelectedColor: "#991b1b"
        property string activeSortColumnCurrentColor: "#2A894D"
        property string activeSortBorderColor: "#60a5fa"
        property string folderTextColor: "#bfdbfe"
        property string fileTextColor: "#e5e7eb"
        property string secondaryTextColor: "#d1d5db"
        property string emptyTextColor: "#d8dee9"
        property string dateHighlightColor: "#f97316"
        property string sizeUnknownColor: "#7f1d1d"
        property string sizeScanningColor: "#9ca3af"
        property string sizeDoneColor: "#22c55e"
        property string sizeErrorColor: "#ef4444"
    }


    Timer {
        id: rowsRebuildTimer
        interval: 250
        repeat: false
        onTriggered: rebuildRowsFromController()
    }

    onShowHiddenChanged: refreshDisplayedRows()
    Component.onCompleted: {
        loadColorSettings()
        scanPath(controller.currentPath)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Label {
            text: "folder-browser"
            font.pixelSize: 24
            font.bold: true
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                text: "Up"
                onClicked: scanPath(parentPath(controller.currentPath))
            }

            TextField {
                id: pathField
                Layout.fillWidth: true
                text: controller.currentPath
                placeholderText: "Enter a directory path, e.g. /home/joc/Pictures"
                selectByMouse: true
                onAccepted: scanPath(text)
            }

            Button {
                text: "Scan"
                onClicked: scanPath(pathField.text)
            }

            Button {
                text: "Colors"
                onClicked: colorConfigPopup.open()
            }

            TextField {
                id: filterField
                Layout.preferredWidth: 220
                text: filterText
                placeholderText: "Filter/search"
                selectByMouse: true
                onTextChanged: {
                    filterText = text;
                    refreshDisplayedRows();
                }
                ToolTip.visible: hovered
                ToolTip.text: "Filter by filename, type, or path"
            }

            CheckBox {
                id: hiddenToggle
                text: "Show hidden"
                checked: showHidden
                onToggled: showHidden = checked
                ToolTip.visible: hovered
                ToolTip.text: "Show entries whose names start with a dot"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            color: panelBackgroundColor
            border.color: fileList.activeFocus ? panelFocusBorderColor : panelBorderColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    color: headerBackgroundColor
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        HeaderCell {
                            title: "Name"
                            columnName: "name"
                            Layout.fillWidth: true
                            menu: nameHeaderMenu
                        }
                        HeaderCell {
                            title: "Type"
                            columnName: "kind"
                            Layout.preferredWidth: 90
                            menu: typeHeaderMenu
                        }
                        HeaderCell {
                            title: "Size"
                            columnName: "size"
                            Layout.preferredWidth: 100
                            menu: sizeHeaderMenu
                        }
                        HeaderCell {
                            title: "Modified"
                            columnName: "modified"
                            Layout.preferredWidth: 210
                            menu: modifiedHeaderMenu
                        }
                    }
                }

                ListView {
                    id: fileList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    model: fileModel
                    focus: true
                    activeFocusOnTab: true
                    keyNavigationEnabled: true
                    highlightMoveDuration: 80

                    Keys.onReturnPressed: function (event) {
                        openCurrentRow();
                        event.accepted = true;
                    }
                    Keys.onEnterPressed: function (event) {
                        openCurrentRow();
                        event.accepted = true;
                    }
                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Backspace) {
                            scanPath(parentPath(controller.currentPath));
                            event.accepted = true;
                        } else if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && (event.modifiers & Qt.ShiftModifier)) {
                            handleShiftCursorSelection(event.key === Qt.Key_Up ? -1 : 1);
                            event.accepted = true;
                        }
                    }
                    Keys.onEscapePressed: function (event) {
                        pathField.forceActiveFocus();
                        event.accepted = true;
                    }
                    Keys.onSpacePressed: function (event) {
                        toggleSelection(fileList.currentIndex);
                        event.accepted = true;
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: false
                        propagateComposedEvents: true
                        z: 10
                        onWheel: function (wheel) {
                            let maxY = Math.max(0, fileList.contentHeight - fileList.height);
                            let step = wheel.angleDelta.y * 3.0;
                            fileList.contentY = Math.max(0, Math.min(maxY, fileList.contentY - step));
                            wheel.accepted = true;
                        }
                    }

                    delegate: RowDelegate {}
                }

                Label {
                    visible: fileList.count === 0
                    text: allRows.length > 0 && !showHidden ? "Only hidden entries are available. Enable Show hidden to display them." : "No entries to display. Choose an existing directory and press Scan."
                    color: emptyTextColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: controller.statusText + " — " + selectedPaths.length + " selected"
                elide: Text.ElideRight
            }
            Label {
                text: filterText.length > 0 ? fileList.count + " / " + allRows.length + " matches" : fileList.count + " / " + allRows.length + " items"
            }
        }
    }

    Menu {
        id: nameHeaderMenu
        MenuItem {
            text: "Folders first"
            checkable: true
            checked: foldersFirst
            onTriggered: {
                foldersFirst = checked;
                refreshDisplayedRows();
            }
        }
        MenuItem {
            text: "Folders always sorted A-B"
            checkable: true
            checked: foldersAlwaysAZ
            onTriggered: {
                foldersAlwaysAZ = checked;
                refreshDisplayedRows();
            }
        }
        MenuSeparator {}
        MenuItem {
            text: "Dummy: Natural sort"
            enabled: false
        }
        MenuItem {
            text: "Dummy: Case-sensitive sort"
            enabled: false
        }
    }

    Menu {
        id: typeHeaderMenu
        MenuItem {
            text: "Dummy: Group by type"
            enabled: false
        }
        MenuItem {
            text: "Dummy: Hide unknown types"
            enabled: false
        }
    }
    Menu {
        id: modifiedHeaderMenu
        MenuItem {
            text: "Dummy: Today only"
            enabled: false
        }
        MenuItem {
            text: "Dummy: This week"
            enabled: false
        }
        MenuItem {
            text: "Dummy: ISO UTC time"
            enabled: false
        }
    }

    Menu {
        id: sizeHeaderMenu
        MenuItem {
            text: "Auto"
            checkable: true
            checked: sizeUnit === "auto"
            onTriggered: setSizeUnit("auto")
        }
        MenuSeparator {}
        MenuItem {
            text: "B"
            checkable: true
            checked: sizeUnit === "bytes"
            onTriggered: setSizeUnit("bytes")
        }
        MenuItem {
            text: "kB"
            checkable: true
            checked: sizeUnit === "kb"
            onTriggered: setSizeUnit("kb")
        }
        MenuItem {
            text: "MB"
            checkable: true
            checked: sizeUnit === "mb"
            onTriggered: setSizeUnit("mb")
        }
        MenuItem {
            text: "GB"
            checkable: true
            checked: sizeUnit === "gb"
            onTriggered: setSizeUnit("gb")
        }
        MenuItem {
            text: "TB"
            checkable: true
            checked: sizeUnit === "tb"
            onTriggered: setSizeUnit("tb")
        }
        MenuSeparator {}
        MenuItem {
            text: "Dummy: Hide empty sizes"
            enabled: false
        }
    }

    ColorDialog {
        id: appColorDialog
        property string targetColorProperty: ""
        title: "Select color"
        selectedColor: targetColorProperty.length > 0 ? root[targetColorProperty] : "white"
        onSelectedColorChanged: {
            if (visible && targetColorProperty.length > 0) {
                root[targetColorProperty] = selectedColor
            }
        }
        onAccepted: {
            if (targetColorProperty.length > 0) {
                root[targetColorProperty] = selectedColor
            }
        }
    }

    Popup {
        id: colorConfigPopup
        modal: true
        focus: true
        width: Math.min(root.width - 48, 640)
        height: Math.min(root.height - 48, 640)
        anchors.centerIn: parent
        padding: 12
        background: Rectangle {
            color: panelBackgroundColor
            border.color: panelFocusBorderColor
            radius: 8
        }
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            Label {
                text: "Colors"
                color: titleTextColor
                font.bold: true
                font.pixelSize: 20
                Layout.fillWidth: true
            }
            Label {
                text: "Click a color rectangle to change the color immediately. Apply saves to the config file."
                color: secondaryTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ColumnLayout {
                    width: colorConfigPopup.width - 36
                    spacing: 6
                    Repeater {
                        model: colorDefinitions
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 4
                            color: index % 2 === 0 ? rowEvenColor : rowOddColor
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10
                                Label {
                                    text: modelData.label
                                    color: secondaryTextColor
                                    font.family: rowFontFamily
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    Layout.preferredWidth: 78
                                    Layout.preferredHeight: 24
                                    radius: 4
                                    color: root[modelData.key]
                                    border.color: panelFocusBorderColor
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            appColorDialog.targetColorProperty = modelData.key
                                            appColorDialog.selectedColor = root[modelData.key]
                                            appColorDialog.open()
                                        }
                                    }
                                }
                                Label {
                                    text: String(root[modelData.key])
                                    color: secondaryTextColor
                                    font.family: rowFontFamily
                                    Layout.preferredWidth: 105
                                    elide: Text.ElideRight
                                }
                                Button { text: "Reset"; onClicked: resetColorSetting(modelData.key) }
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button { text: "Reset all"; onClicked: resetAllColors() }
                Button { text: "Cancel"; onClicked: { loadColorSettings(); colorConfigPopup.close() } }
                Button { text: "Apply"; onClicked: { applyColorSettings(); colorConfigPopup.close() } }
            }
        }
    }

    component HeaderCell: Rectangle {
        property string title
        property string columnName
        property var menu
        Layout.fillHeight: true
        radius: 4
        color: sortColumn === columnName ? activeSortHeaderColor : "transparent"
        border.color: sortColumn === columnName ? activeSortBorderColor : "transparent"
        Label {
            anchors.centerIn: parent
            text: sortLabel(columnName, title)
            color: headerTextColor
            font.bold: true
            font.family: rowFontFamily
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton)
                    menu.popup();
                else
                    setSort(columnName);
            }
        }
    }

    component RowDelegate: Rectangle {
        id: rowDelegate
        required property int index
        required property string name
        required property string kind
        required property double sizeBytes
        required property string sizeStatus
        required property double modifiedSecs
        required property string path
        required property bool isDir
        width: fileList.width
        height: rowHeight
        radius: 4
        color: isRowSelected(index) && fileList.currentIndex === index
               ? keyboardCurrentRowColor
               : (isRowSelected(index)
                  ? selectedRowColor
                  : (fileList.currentIndex === index ? keyboardCurrentRowColor : (index % 2 === 0 ? "#1f2937" : panelBackgroundColor)))

        Item {
            id: dragProxy
            width: 1
            height: 1
            visible: false
            Drag.active: rowMouseArea.drag.active
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.CopyAction
            Drag.mimeData: {
                "text/uri-list": uriListFromPath(rowDelegate.path),
                "text/plain": rowDelegate.path
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 10
            Cell {
                columnName: "name"
                selected: isRowSelected(rowDelegate.index)
                current: fileList.currentIndex === rowDelegate.index
                Layout.fillWidth: true
                RowLayout {
                    anchors.fill: parent
                    spacing: 6
                    IconImage {
                        Layout.preferredWidth: fileIconSize
                        Layout.preferredHeight: fileIconSize
                        Layout.alignment: Qt.AlignVCenter
                        name: fileIconName(rowDelegate)
                        sourceSize.width: fileIconSize
                        sourceSize.height: fileIconSize
                        color: "transparent"
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: Text.AlignVCenter
                        text: highlightedFileName(rowDelegate.name)
                        textFormat: Text.RichText
                        color: rowDelegate.isDir ? folderTextColor : fileTextColor
                        elide: Text.ElideRight
                        font.family: rowFontFamily
                    }
                }
            }
            Cell {
                columnName: "kind"
                selected: isRowSelected(rowDelegate.index)
                current: fileList.currentIndex === rowDelegate.index
                Layout.preferredWidth: 90
                Label {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: rowDelegate.kind
                    color: secondaryTextColor
                    elide: Text.ElideRight
                    font.family: rowFontFamily
                }
            }
            Cell {
                columnName: "size"
                selected: isRowSelected(rowDelegate.index)
                current: fileList.currentIndex === rowDelegate.index
                Layout.preferredWidth: 100
                Label {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: displaySize(rowDelegate.sizeBytes, rowDelegate)
                    color: sizeColor(rowDelegate)
                    font.family: rowFontFamily
                }
            }
            Cell {
                columnName: "modified"
                selected: isRowSelected(rowDelegate.index)
                current: fileList.currentIndex === rowDelegate.index
                Layout.preferredWidth: 210
                Label {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: modifiedText(rowDelegate.modifiedSecs)
                    color: secondaryTextColor
                    elide: Text.ElideRight
                    font.family: rowFontFamily
                }
            }
        }

        MouseArea {
            id: rowMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            drag.target: dragProxy
            drag.axis: Drag.XAndYAxis
            drag.threshold: 8
            onPressed: function (mouse) {
                handleRowPress(mouse, index);
            }
            onClicked: function (mouse) {}
            onDoubleClicked: openRow(fileModel.get(index))
            onReleased: {
                dragProxy.x = 0;
                dragProxy.y = 0;
            }
            onCanceled: {
                dragProxy.x = 0;
                dragProxy.y = 0;
            }
        }
    }

    component Cell: Rectangle {
        property string columnName
        property bool selected: false
        property bool current: false
        Layout.fillHeight: true
        radius: 3
        color: sortColumn === columnName ? (selected ? activeSortColumnSelectedColor : (current ? activeSortColumnCurrentColor : activeSortColumnColor)) : "transparent"
    }
}

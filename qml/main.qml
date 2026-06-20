import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import dk.john.folderbrowser 1.0

ApplicationWindow {
    id: root
    width: 1000
    height: 620
    visible: true
    title: "folder-browser - CXX-Qt local explorer"

    property var fileRows: parseRows(controller.fileRowsJson)
    property string sortColumn: "name"
    property bool sortAscending: true
    property bool showHidden: false
    property var displayedFileRows: sortRows(filterRows(fileRows))

    function localPathFromUrl(urlValue) {
        let text = String(urlValue)
        if (text.startsWith("file://")) {
            return decodeURIComponent(text.replace(/^file:\/\//, ""))
        }
        return text
    }

    function fileUriFromPath(pathText) {
        let text = String(pathText || "")
        if (text.startsWith("file://")) {
            return text
        }
        if (!text.startsWith("/")) {
            return text
        }
        return "file://" + text.split("/").map(function(part) {
            return encodeURIComponent(part)
        }).join("/")
    }

    function uriListFromPath(pathText) {
        return fileUriFromPath(pathText) + "\r\n"
    }

    function parseRows(jsonText) {
        if (!jsonText || jsonText.length === 0) {
            return []
        }

        try {
            return JSON.parse(jsonText)
        } catch (error) {
            console.log("Could not parse fileRowsJson:", error)
            return []
        }
    }

    function parentPath(pathText) {
        let text = String(pathText)
        if (text.length <= 1) {
            return "/"
        }
        if (text.endsWith("/") && text.length > 1) {
            text = text.slice(0, -1)
        }
        let index = text.lastIndexOf("/")
        if (index <= 0) {
            return "/"
        }
        return text.slice(0, index)
    }

    function modifiedText(seconds) {
        if (seconds === null || seconds === undefined) {
            return ""
        }
        return new Date(seconds * 1000).toLocaleString()
    }

    function isHiddenRow(row) {
        return row && row.name && String(row.name).startsWith(".")
    }

    function filterRows(rows) {
        let source = Array.from(rows || [])
        if (root.showHidden) {
            return source
        }
        return source.filter(function(row) {
            return !isHiddenRow(row)
        })
    }

    function refreshDisplayedRows() {
        root.displayedFileRows = sortRows(filterRows(root.fileRows))
        if (fileList && root.displayedFileRows.length > 0) {
            if (fileList.currentIndex < 0 || fileList.currentIndex >= root.displayedFileRows.length) {
                fileList.currentIndex = 0
            }
        }
    }

    function scanPath(pathText) {
        pathField.text = String(pathText)
        controller.scanPath(pathField.text)
        Qt.callLater(function() {
            fileList.forceActiveFocus()
        })
    }

    function openRow(row) {
        if (!row) {
            return
        }
        if (row.isDir) {
            root.scanPath(row.path)
        } else {
            controller.statusText = "Selected file: " + row.path
        }
    }

    function openCurrentRow() {
        if (fileList.currentIndex < 0 || fileList.currentIndex >= root.displayedFileRows.length) {
            return
        }
        root.openRow(root.displayedFileRows[fileList.currentIndex])
    }

    function sortLabel(columnName, title) {
        if (root.sortColumn !== columnName) {
            return title
        }
        return title + (root.sortAscending ? " ▲" : " ▼")
    }

    function setSort(columnName) {
        if (root.sortColumn === columnName) {
            root.sortAscending = !root.sortAscending
        } else {
            root.sortColumn = columnName
            root.sortAscending = true
        }
        refreshDisplayedRows()
        fileList.forceActiveFocus()
    }

    function compareText(left, right) {
        return String(left || "").localeCompare(String(right || ""), Qt.locale(), {
            sensitivity: "base",
            numeric: true
        })
    }

    function compareNullableNumber(left, right) {
        let leftMissing = left === null || left === undefined
        let rightMissing = right === null || right === undefined

        if (leftMissing && rightMissing) {
            return 0
        }
        if (leftMissing) {
            return 1
        }
        if (rightMissing) {
            return -1
        }
        return Number(left) - Number(right)
    }

    function sortRows(rows) {
        let sorted = Array.from(rows || [])
        let column = root.sortColumn

        sorted.sort(function(left, right) {
            let result = 0

            if (column === "name") {
                result = compareText(left.name, right.name)
            } else if (column === "kind") {
                result = compareText(left.kind, right.kind)
            } else if (column === "size") {
                result = compareNullableNumber(left.sizeBytes, right.sizeBytes)
            } else if (column === "modified") {
                result = compareNullableNumber(left.modifiedSecs, right.modifiedSecs)
            }

            if (result === 0) {
                if (left.isDir !== right.isDir) {
                    result = left.isDir ? -1 : 1
                } else {
                    result = compareText(left.name, right.name)
                }
            }

            return root.sortAscending ? result : -result
        })

        return sorted
    }

    FolderBrowserController {
        id: controller
        currentPath: root.localPathFromUrl(StandardPaths.writableLocation(StandardPaths.HomeLocation))
        statusText: "Ready"
        fileRowsJson: "[]"
    }

    onFileRowsChanged: refreshDisplayedRows()
    onShowHiddenChanged: refreshDisplayedRows()

    Component.onCompleted: {
        controller.scanPath(controller.currentPath)
        Qt.callLater(function() {
            fileList.forceActiveFocus()
        })
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
                onClicked: root.scanPath(root.parentPath(controller.currentPath))
            }

            TextField {
                id: pathField
                Layout.fillWidth: true
                text: controller.currentPath
                placeholderText: "Enter a directory path, e.g. /home/joc/Pictures"
                selectByMouse: true
                onAccepted: root.scanPath(text)
            }

            Button {
                text: "Scan"
                onClicked: root.scanPath(pathField.text)
            }

            CheckBox {
                id: hiddenToggle
                text: "Show hidden"
                checked: root.showHidden
                onToggled: root.showHidden = checked
                ToolTip.visible: hovered
                ToolTip.text: "Show entries whose names start with a dot"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            color: "#20242b"
            border.color: fileList.activeFocus ? "#60a5fa" : "#3b4252"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    color: "#111827"
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        ToolButton {
                            text: root.sortLabel("name", "Name")
                            onClicked: root.setSort("name")
                            Layout.fillWidth: true
                            font.bold: true
                        }

                        ToolButton {
                            text: root.sortLabel("kind", "Type")
                            onClicked: root.setSort("kind")
                            Layout.preferredWidth: 90
                            font.bold: true
                        }

                        ToolButton {
                            text: root.sortLabel("size", "Size")
                            onClicked: root.setSort("size")
                            Layout.preferredWidth: 100
                            font.bold: true
                        }

                        ToolButton {
                            text: root.sortLabel("modified", "Modified")
                            onClicked: root.setSort("modified")
                            Layout.preferredWidth: 210
                            font.bold: true
                        }
                    }
                }

                ListView {
                    id: fileList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    model: root.displayedFileRows
                    focus: true
                    activeFocusOnTab: true
                    keyNavigationEnabled: true
                    highlightMoveDuration: 80

                    Keys.onReturnPressed: function(event) {
                        root.openCurrentRow()
                        event.accepted = true
                    }

                    Keys.onEnterPressed: function(event) {
                        root.openCurrentRow()
                        event.accepted = true
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Backspace) {
                            root.scanPath(root.parentPath(controller.currentPath))
                            event.accepted = true
                        }
                    }

                    Keys.onEscapePressed: function(event) {
                        pathField.forceActiveFocus()
                        event.accepted = true
                    }

                    Keys.onSpacePressed: function(event) {
                        fileList.currentIndex = Math.max(0, fileList.currentIndex)
                        event.accepted = true
                    }

                    onCountChanged: {
                        if (count > 0 && (currentIndex < 0 || currentIndex >= count)) {
                            currentIndex = 0
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: false
                        propagateComposedEvents: true
                        z: 10

                        onWheel: function(wheel) {
                            let maxY = Math.max(0, fileList.contentHeight - fileList.height)
                            let step = wheel.angleDelta.y * 3.0
                            fileList.contentY = Math.max(0, Math.min(maxY, fileList.contentY - step))
                            wheel.accepted = true
                        }
                    }

                    delegate: Rectangle {
                        id: rowDelegate

                        required property var modelData
                        required property int index

                        width: fileList.width
                        height: 32
                        radius: 4
                        color: fileList.currentIndex === index ? "#334155" : (index % 2 === 0 ? "#1f2937" : "#20242b")

                        Item {
                            id: dragProxy
                            width: 1
                            height: 1
                            visible: false

                            Drag.active: rowMouseArea.drag.active
                            Drag.dragType: Drag.Automatic
                            Drag.supportedActions: Qt.CopyAction
                            Drag.mimeData: {
                                "text/uri-list": root.uriListFromPath(modelData.path),
                                "text/plain": modelData.path
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            Label {
                                text: (modelData.isDir ? "[DIR] " : "") + modelData.name
                                color: modelData.isDir ? "#bfdbfe" : "#e5e7eb"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Label {
                                text: modelData.kind
                                color: "#d1d5db"
                                elide: Text.ElideRight
                                Layout.preferredWidth: 90
                            }

                            Label {
                                text: modelData.sizeText
                                color: "#d1d5db"
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: 100
                            }

                            Label {
                                text: root.modifiedText(modelData.modifiedSecs)
                                color: "#d1d5db"
                                elide: Text.ElideRight
                                Layout.preferredWidth: 210
                            }
                        }

                        MouseArea {
                            id: rowMouseArea
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            drag.target: dragProxy
                            drag.axis: Drag.XAndYAxis
                            drag.threshold: 8

                            onPressed: {
                                fileList.currentIndex = index
                                fileList.forceActiveFocus()
                            }
                            onClicked: {
                                fileList.currentIndex = index
                                fileList.forceActiveFocus()
                            }
                            onDoubleClicked: root.openRow(modelData)
                            onReleased: {
                                dragProxy.x = 0
                                dragProxy.y = 0
                            }
                            onCanceled: {
                                dragProxy.x = 0
                                dragProxy.y = 0
                            }
                        }
                    }
                }

                Label {
                    visible: fileList.count === 0
                    text: root.fileRows.length > 0 && !root.showHidden
                          ? "Only hidden entries are available. Enable Show hidden to display them."
                          : "No entries to display. Choose an existing directory and press Scan."
                    color: "#d8dee9"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                Layout.fillWidth: true
                text: controller.statusText + " — keyboard: ↑/↓ select, Enter open folder, Backspace up, Esc path field; drag rows to apps"
                elide: Text.ElideRight
            }

            Label {
                text: fileList.count + " / " + root.fileRows.length + " items"
            }
        }
    }
}

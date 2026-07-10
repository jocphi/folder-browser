import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: fileListView

    property var fileModel

    property string sortColumn: "name"
    property string columnProfileName: "Default"
    property var columnProfileColumns: []
    property var defaultColumnProfileColumns: [
        ({ key: "name", label: "Name", width: -1, fillWidth: true, menuKey: "name" }),
        ({ key: "kind", label: "Type", width: 90, fillWidth: false, menuKey: "kind" }),
        ({ key: "size", label: "Size", width: 100, fillWidth: false, menuKey: "size" }),
        ({ key: "modified", label: "Modified", width: 210, fillWidth: false, menuKey: "modified" })
    ]
    readonly property var effectiveColumnProfileColumns: columnProfileColumns && columnProfileColumns.length > 0 ? columnProfileColumns : defaultColumnProfileColumns
    property bool sortAscending: true
    property int rowHeight: 32
    property int fileIconSize: rowHeight
    property string rowFontFamily: "monospace"
    property int currentIndex: fileList.currentIndex
    readonly property int count: fileList.count

    property color panelBackgroundColor: "#20242b"
    property color panelBorderColor: "#3b4252"
    property color panelFocusBorderColor: "#60a5fa"
    property color headerBackgroundColor: "#111827"
    property color emptyTextColor: "#d8dee9"
    property color rowEvenColor: "#1f2937"
    property color rowOddColor: "#20242b"
    property color selectedRowColor: "#7f1d1d"
    property color rangeAnchorMarkerColor: "#fbbf24"
    property string rangeAnchorMarkerMode: "lighter"
    property real rangeAnchorMarkerPercent: 10
    property color keyboardCurrentRowColor: "#14532d"
    property color activeSortHeaderColor: "#374151"
    property color activeSortColumnColor: "#2b3544"
    property color activeSortColumnSelectedColor: "#991b1b"
    property color activeSortColumnCurrentColor: "#2A894D"
    property color activeSortBorderColor: "#60a5fa"
    property color headerTextColor: "#f9fafb"
    property color folderTextColor: "#bfdbfe"
    property color fileTextColor: "#e5e7eb"
    property color secondaryTextColor: "#d1d5db"

    property bool showHidden: false
    property int allRowsLength: 0

    property var nameHeaderMenu
    property var typeHeaderMenu
    property var sizeHeaderMenu
    property var modifiedHeaderMenu

    property var isRowSelectedFunction
    property var isRangeAnchorFunction
    property var fileIconNameFunction
    property var uriListFromPathFunction
    property var highlightedFileNameFunction
    property var displaySizeFunction
    property var sizeColorFunction
    property var modifiedTextFunction

    signal sortRequested(string columnName)
    signal headerMenuRequested(string columnName, real sceneX, real sceneY)

    function headerMenuForColumn(columnName) {
        if (columnName === "name") return nameHeaderMenu
        if (columnName === "kind") return typeHeaderMenu
        if (columnName === "size") return sizeHeaderMenu
        if (columnName === "modified") return modifiedHeaderMenu
        return null
    }
    signal openCurrentRequested()
    signal goParentRequested()
    signal escapeToPathRequested()
    signal toggleSelectionRequested(int rowIndex)
    signal shiftCursorRequested(int direction)
    signal pageMoveRequested(int direction, bool extendSelection)
    signal boundaryMoveRequested(int direction, bool extendSelection)
    signal keyboardMoveCurrentRequested(int direction, bool extendSelection)
    signal rowPressed(var mouse, int rowIndex)
    signal rowDoubleClicked(int rowIndex)
    signal deleteRequested()
    signal listFocusGained()

    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 8
    color: panelBackgroundColor
    border.color: fileList.activeFocus ? panelFocusBorderColor : panelBorderColor

    function forceListFocus() {
        fileList.forceActiveFocus()
    }

    function containIndex(index) {
        if (index < 0 || index >= fileList.count)
            return
        fileList.forceLayout()
        fileList.positionViewAtIndex(index, ListView.Contain)
        Qt.callLater(function() {
            if (index >= 0 && index < fileList.count) {
                fileList.forceLayout()
                fileList.positionViewAtIndex(index, ListView.Contain)
            }
            fileListView.clampListScroll()
        })
    }

    function maxContentY() {
        return Math.max(0, fileList.contentHeight - fileList.height)
    }

    function clampListScroll() {
        if (!fileList)
            return
        let maxY = maxContentY()
        if (fileList.contentY < 0)
            fileList.contentY = 0
        else if (fileList.contentY > maxY)
            fileList.contentY = maxY
    }

    function refreshLayoutAfterModelChange() {
        if (!fileList)
            return
        fileList.cancelFlick()
        fileList.forceLayout()
        clampListScroll()
    }

    function resetAfterRowsRebuilt() {
        if (!fileList)
            return

        let wantedIndex = fileList.currentIndex
        fileList.cancelFlick()
        fileList.model = null
        fileList.contentY = 0

        Qt.callLater(function() {
            if (!fileList)
                return
            fileList.model = fileListView.fileModel
            fileList.forceLayout()
            if (wantedIndex >= 0 && wantedIndex < fileList.count) {
                fileList.currentIndex = wantedIndex
                fileList.positionViewAtIndex(wantedIndex, ListView.Contain)
            } else if (fileList.count > 0 && fileList.currentIndex < 0) {
                fileList.currentIndex = 0
            }
            fileListView.clampListScroll()
        })
    }

    function pageStep() {
        return Math.max(1, Math.floor(fileList.height / Math.max(1, rowHeight)) - 1)
    }

    function durationGroupKeyAt(rowIndex) {
        if (!fileModel || rowIndex < 0 || rowIndex >= fileModel.count)
            return ""
        let row = fileModel.get(rowIndex)
        if (!row || row.isDir)
            return ""
        let seconds = Number(row.durationSecs || 0)
        if (!Number.isFinite(seconds) || seconds <= 0)
            return ""
        return String(Math.round(seconds))
    }

    function isDurationGroupRow(rowIndex) {
        let key = durationGroupKeyAt(rowIndex)
        if (key.length === 0)
            return false
        return durationGroupKeyAt(rowIndex - 1) === key || durationGroupKeyAt(rowIndex + 1) === key
    }

    function isDurationGroupStart(rowIndex) {
        let key = durationGroupKeyAt(rowIndex)
        return key.length > 0 && isDurationGroupRow(rowIndex) && durationGroupKeyAt(rowIndex - 1) !== key
    }

    function isDurationGroupEnd(rowIndex) {
        let key = durationGroupKeyAt(rowIndex)
        return key.length > 0 && isDurationGroupRow(rowIndex) && durationGroupKeyAt(rowIndex + 1) !== key
    }

    onCurrentIndexChanged: {
        let wantedIndex = currentIndex
        if (wantedIndex >= fileList.count)
            wantedIndex = fileList.count > 0 ? fileList.count - 1 : -1
        if (fileList.currentIndex !== wantedIndex) {
            fileList.currentIndex = wantedIndex
        }
    }

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

                Repeater {
                    model: fileListView.effectiveColumnProfileColumns

                    HeaderCell {
                        required property var modelData

                        title: String(modelData.label || modelData.key || "")
                        columnName: String(modelData.key || "")
                        Layout.fillWidth: Boolean(modelData.fillWidth)
                        Layout.preferredWidth: Number(modelData.width || 0) > 0 ? Number(modelData.width) : -1
                        menu: fileListView.headerMenuForColumn(columnName)
                        sortColumn: fileListView.sortColumn
                        sortAscending: fileListView.sortAscending
                        rowFontFamily: fileListView.rowFontFamily
                        activeSortHeaderColor: fileListView.activeSortHeaderColor
                        activeSortBorderColor: fileListView.activeSortBorderColor
                        headerTextColor: fileListView.headerTextColor
                        onSortRequested: function(columnName) { fileListView.sortRequested(columnName) }
                        onMenuRequested: function(columnName, sceneX, sceneY) { fileListView.headerMenuRequested(columnName, sceneX, sceneY) }
                    }
                }
            }
        }

        ListView {
            id: fileList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            boundsMovement: Flickable.StopAtBounds
            maximumFlickVelocity: 8000
            spacing: 1
            model: fileListView.fileModel
            focus: true
            activeFocusOnTab: true
            onActiveFocusChanged: if (activeFocus) fileListView.listFocusGained()
            keyNavigationEnabled: true
            highlightMoveDuration: 80
            onCurrentIndexChanged: {
                if (currentIndex >= count)
                    currentIndex = count > 0 ? count - 1 : -1
                fileListView.currentIndex = currentIndex
            }
            onContentYChanged: fileListView.clampListScroll()
            onContentHeightChanged: fileListView.refreshLayoutAfterModelChange()
            onHeightChanged: fileListView.refreshLayoutAfterModelChange()
            onCountChanged: fileListView.refreshLayoutAfterModelChange()

            Item {
                id: fileListVerticalScrollBarOverlay
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 14
                z: 80
                visible: fileList.contentHeight > fileList.height

                Rectangle {
                    id: fileListVerticalScrollTrack
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.10)
                    border.color: Qt.rgba(1, 1, 1, 0.18)
                    border.width: 1
                }

                Rectangle {
                    id: fileListVerticalScrollThumb
                    width: 10
                    x: 2
                    radius: 5
                    height: Math.max(34, fileListVerticalScrollBarOverlay.height * fileList.height / Math.max(1, fileList.contentHeight))
                    y: fileList.contentHeight <= fileList.height
                       ? 0
                       : Math.max(0, Math.min(fileListVerticalScrollBarOverlay.height - height,
                           (fileList.contentY / Math.max(1, fileList.contentHeight - fileList.height))
                           * (fileListVerticalScrollBarOverlay.height - height)))
                    color: fileListVerticalScrollMouse.pressed
                           ? fileListView.activeSortBorderColor
                           : (fileListVerticalScrollMouse.containsMouse
                              ? Qt.lighter(fileListView.activeSortBorderColor, 1.18)
                              : Qt.rgba(0.75, 0.82, 0.92, 0.72))
                    border.color: Qt.rgba(0, 0, 0, 0.30)
                    border.width: 1
                }

                MouseArea {
                    id: fileListVerticalScrollMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeVerCursor

                    function moveTo(localY) {
                        let maxContentY = Math.max(0, fileList.contentHeight - fileList.height)
                        let maxThumbY = Math.max(1, fileListVerticalScrollBarOverlay.height - fileListVerticalScrollThumb.height)
                        let thumbY = Math.max(0, Math.min(maxThumbY, localY - fileListVerticalScrollThumb.height / 2))
                        fileList.contentY = maxContentY * thumbY / maxThumbY
                    }

                    onPressed: function(mouse) { moveTo(mouse.y) }
                    onPositionChanged: function(mouse) {
                        if (pressed)
                            moveTo(mouse.y)
                    }
                }
            }


            Keys.onReturnPressed: function(event) {
                fileListView.openCurrentRequested()
                event.accepted = true
            }
            Keys.onEnterPressed: function(event) {
                fileListView.openCurrentRequested()
                event.accepted = true
            }
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Delete) {
                    fileListView.deleteRequested()
                    event.accepted = true
                    return
                }
                // Route plain Up/Down through root so selection anchor follows keyboard navigation.
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                    let extendSelection = (event.modifiers & Qt.ShiftModifier) !== 0
                    fileListView.keyboardMoveCurrentRequested(event.key === Qt.Key_Down ? 1 : -1, extendSelection)
                    event.accepted = true
                    return
                }


            if (event.key === Qt.Key_PageDown) {
                fileListView.pageMoveRequested(1, event.modifiers & Qt.ShiftModifier)
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_PageUp) {
                fileListView.pageMoveRequested(-1, event.modifiers & Qt.ShiftModifier)
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Home) {
                fileListView.boundaryMoveRequested(-1, event.modifiers & Qt.ShiftModifier)
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_End) {
                fileListView.boundaryMoveRequested(1, event.modifiers & Qt.ShiftModifier)
                event.accepted = true
                return
            }
                if (event.key === Qt.Key_Backspace) {
                    fileListView.goParentRequested()
                    event.accepted = true
                } else if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down)
                           && (event.modifiers & Qt.ShiftModifier)) {
                    fileListView.shiftCursorRequested(event.key === Qt.Key_Up ? -1 : 1)
                    event.accepted = true
                }
            }
            Keys.onEscapePressed: function(event) {
                fileListView.escapeToPathRequested()
                event.accepted = true
            }
            Keys.onSpacePressed: function(event) {
                fileListView.toggleSelectionRequested(fileList.currentIndex)
                event.accepted = true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: false
                propagateComposedEvents: true
                z: 10
                onWheel: function(wheel) {
                    fileList.cancelFlick()
                    let maxY = Math.max(0, fileList.contentHeight - fileList.height)
                    let step = wheel.angleDelta.y * 3.0
                    fileList.contentY = Math.max(0, Math.min(maxY, fileList.contentY - step))
                    wheel.accepted = true
                }
            }

            delegate: RowDelegate {
                listWidth: fileList.width
                current: fileList.currentIndex === index
                selected: fileListView.isRowSelectedFunction ? fileListView.isRowSelectedFunction(index) : false
                rangeAnchor: fileListView.isRangeAnchorFunction ? fileListView.isRangeAnchorFunction(index) : false
                rowHeight: fileListView.rowHeight
                fileIconSize: fileListView.fileIconSize
                rowFontFamily: fileListView.rowFontFamily
                sortColumn: fileListView.sortColumn
                columnProfileColumns: fileListView.effectiveColumnProfileColumns
                rowEvenColor: fileListView.rowEvenColor
                rowOddColor: fileListView.rowOddColor
                selectedRowColor: fileListView.selectedRowColor
                rangeAnchorMarkerColor: fileListView.rangeAnchorMarkerColor
                rangeAnchorMarkerMode: fileListView.rangeAnchorMarkerMode
                rangeAnchorMarkerPercent: fileListView.rangeAnchorMarkerPercent
                keyboardCurrentRowColor: fileListView.keyboardCurrentRowColor
                activeSortColumnColor: fileListView.activeSortColumnColor
                activeSortColumnSelectedColor: fileListView.activeSortColumnSelectedColor
                activeSortColumnCurrentColor: fileListView.activeSortColumnCurrentColor
                folderTextColor: fileListView.folderTextColor
                fileTextColor: fileListView.fileTextColor
                secondaryTextColor: fileListView.secondaryTextColor
                fileIconNameFunction: fileListView.fileIconNameFunction
                uriListFromPathFunction: fileListView.uriListFromPathFunction
                highlightedFileNameFunction: fileListView.highlightedFileNameFunction
                displaySizeFunction: fileListView.displaySizeFunction
                sizeColorFunction: fileListView.sizeColorFunction
                modifiedTextFunction: fileListView.modifiedTextFunction
                durationGroup: fileListView.isDurationGroupRow(index)
                durationGroupStart: fileListView.isDurationGroupStart(index)
                durationGroupEnd: fileListView.isDurationGroupEnd(index)
                onRowPressed: function(mouse, rowIndex) { fileListView.rowPressed(mouse, rowIndex) }
                onRowDoubleClicked: function(rowIndex) { fileListView.rowDoubleClicked(rowIndex) }
            }
        }

        Label {
            visible: fileList.count === 0
            text: fileListView.allRowsLength > 0 && !fileListView.showHidden
                  ? "Only hidden entries are available. Enable Show hidden to display them."
                  : "No entries to display. Choose an existing directory and press Scan."
            color: emptyTextColor
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
}

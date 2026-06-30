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

    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 8
    color: panelBackgroundColor
    border.color: fileList.activeFocus ? panelFocusBorderColor : panelBorderColor

    function forceListFocus() {
        fileList.forceActiveFocus()
    }

    function containIndex(index) {
        fileList.positionViewAtIndex(index, ListView.Contain)
    }

    function pageStep() {
        return Math.max(1, Math.floor(fileList.height / Math.max(1, rowHeight)) - 1)
    }

    onCurrentIndexChanged: {
        if (fileList.currentIndex !== currentIndex) {
            fileList.currentIndex = currentIndex
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
            spacing: 1
            model: fileListView.fileModel
            focus: true
            activeFocusOnTab: true
            keyNavigationEnabled: true
            highlightMoveDuration: 80
            onCurrentIndexChanged: fileListView.currentIndex = currentIndex

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

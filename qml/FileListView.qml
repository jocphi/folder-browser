import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: fileListView

    property var fileModel

    property string sortColumn: "name"
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
    property var fileIconNameFunction
    property var uriListFromPathFunction
    property var highlightedFileNameFunction
    property var displaySizeFunction
    property var sizeColorFunction
    property var modifiedTextFunction

    signal sortRequested(string columnName)
    signal headerMenuRequested(string columnName, real sceneX, real sceneY)
    signal openCurrentRequested()
    signal goParentRequested()
    signal escapeToPathRequested()
    signal toggleSelectionRequested(int rowIndex)
    signal shiftCursorRequested(int direction)
    signal pageMoveRequested(int direction, bool extendSelection)
    signal boundaryMoveRequested(int direction, bool extendSelection)
    signal rowPressed(var mouse, int rowIndex)
    signal rowDoubleClicked(int rowIndex)

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

                HeaderCell {
                    title: "Name"
                    columnName: "name"
                    Layout.fillWidth: true
                    menu: fileListView.nameHeaderMenu
                    sortColumn: fileListView.sortColumn
                    sortAscending: fileListView.sortAscending
                    rowFontFamily: fileListView.rowFontFamily
                    activeSortHeaderColor: fileListView.activeSortHeaderColor
                    activeSortBorderColor: fileListView.activeSortBorderColor
                    headerTextColor: fileListView.headerTextColor
                    onSortRequested: function(columnName) { fileListView.sortRequested(columnName) }
                    onMenuRequested: function(columnName, sceneX, sceneY) { fileListView.headerMenuRequested(columnName, sceneX, sceneY) }
                }

                HeaderCell {
                    title: "Type"
                    columnName: "kind"
                    Layout.preferredWidth: 90
                    menu: fileListView.typeHeaderMenu
                    sortColumn: fileListView.sortColumn
                    sortAscending: fileListView.sortAscending
                    rowFontFamily: fileListView.rowFontFamily
                    activeSortHeaderColor: fileListView.activeSortHeaderColor
                    activeSortBorderColor: fileListView.activeSortBorderColor
                    headerTextColor: fileListView.headerTextColor
                    onSortRequested: function(columnName) { fileListView.sortRequested(columnName) }
                    onMenuRequested: function(columnName, sceneX, sceneY) { fileListView.headerMenuRequested(columnName, sceneX, sceneY) }
                }

                HeaderCell {
                    title: "Size"
                    columnName: "size"
                    Layout.preferredWidth: 100
                    menu: fileListView.sizeHeaderMenu
                    sortColumn: fileListView.sortColumn
                    sortAscending: fileListView.sortAscending
                    rowFontFamily: fileListView.rowFontFamily
                    activeSortHeaderColor: fileListView.activeSortHeaderColor
                    activeSortBorderColor: fileListView.activeSortBorderColor
                    headerTextColor: fileListView.headerTextColor
                    onSortRequested: function(columnName) { fileListView.sortRequested(columnName) }
                    onMenuRequested: function(columnName, sceneX, sceneY) { fileListView.headerMenuRequested(columnName, sceneX, sceneY) }
                }

                HeaderCell {
                    title: "Modified"
                    columnName: "modified"
                    Layout.preferredWidth: 210
                    menu: fileListView.modifiedHeaderMenu
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
                rowHeight: fileListView.rowHeight
                fileIconSize: fileListView.fileIconSize
                rowFontFamily: fileListView.rowFontFamily
                sortColumn: fileListView.sortColumn
                rowEvenColor: fileListView.rowEvenColor
                rowOddColor: fileListView.rowOddColor
                selectedRowColor: fileListView.selectedRowColor
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

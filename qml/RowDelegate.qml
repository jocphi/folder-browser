import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Layouts

Rectangle {
    id: rowDelegate

    required property int index
    required property string name
    required property string kind
    required property double sizeBytes
    required property string sizeStatus
    required property double modifiedSecs
    required property string path
    required property bool isDir

    property real listWidth: 0
    property int rowHeight: 32
    property int fileIconSize: rowHeight
    property string rowFontFamily: "monospace"
    property string sortColumn: "name"
    property var columnProfileColumns: [
        ({ key: "name", label: "Name", width: -1, fillWidth: true }),
        ({ key: "kind", label: "Type", width: 90, fillWidth: false }),
        ({ key: "size", label: "Size", width: 100, fillWidth: false }),
        ({ key: "modified", label: "Modified", width: 210, fillWidth: false })
    ]
    property bool selected: false
    property bool current: false
    property bool rangeAnchor: false

    property color rowEvenColor: "#1f2937"
    property color rowOddColor: "#20242b"
    property color selectedRowColor: "#7f1d1d"
    property color rangeAnchorMarkerColor: "#fbbf24"
    property string rangeAnchorMarkerMode: "lighter"
    property real rangeAnchorMarkerPercent: 10
    property color keyboardCurrentRowColor: "#14532d"
    property color activeSortColumnColor: "#2b3544"
    property color activeSortColumnSelectedColor: "#991b1b"
    property color activeSortColumnCurrentColor: "#2A894D"
    property color folderTextColor: "#bfdbfe"
    property color fileTextColor: "#e5e7eb"
    property color secondaryTextColor: "#d1d5db"

    function tintedRowColor(baseColor) {
        return index % 2 === 0 ? baseColor : Qt.darker(baseColor, 1.10)
    }

    function rowVisualColor() {
        if (current) {
            return tintedRowColor(keyboardCurrentRowColor)
        }

        if (selected) {
            return tintedRowColor(selectedRowColor)
        }

        return tintedRowColor(rowEvenColor)
    }

    property var fileIconNameFunction
    property var uriListFromPathFunction
    property var highlightedFileNameFunction
    property var displaySizeFunction
    property var sizeColorFunction
    property var modifiedTextFunction

    signal rowPressed(var mouse, int rowIndex)
    signal rowDoubleClicked(int rowIndex)

    width: listWidth
    height: rowHeight
    radius: 4
    color: rowVisualColor()


            function rangeAnchorMarkerBaseColor() {
        // Match the row's actual visual background before calculating lighter/darker marker shades.
        // If the anchor is also the current row, use the current-row color, not the selected-row color.
        let baseColor = current ? keyboardCurrentRowColor : selectedRowColor
        return index % 2 === 0 ? baseColor : Qt.darker(baseColor, 1.10)
    }

    function rangeAnchorMarkerVisualColor() {
        let factor = 1 + Math.max(0, rangeAnchorMarkerPercent) / 100
        let baseColor = rangeAnchorMarkerBaseColor()

        if (rangeAnchorMarkerMode === "custom") {
            return rangeAnchorMarkerColor
        }

        if (rangeAnchorMarkerMode === "darker") {
            return Qt.darker(baseColor, factor)
        }

        return Qt.lighter(baseColor, factor)
    }


    function textForColumn(columnName) {
        if (columnName === "kind") return rowDelegate.kind
        if (columnName === "size") return rowDelegate.displaySizeFunction ? rowDelegate.displaySizeFunction(rowDelegate.sizeBytes, rowDelegate) : ""
        if (columnName === "modified") return rowDelegate.modifiedTextFunction ? rowDelegate.modifiedTextFunction(rowDelegate.modifiedSecs) : ""
        return ""
    }

    function textColorForColumn(columnName) {
        if (columnName === "size") return rowDelegate.sizeColorFunction ? rowDelegate.sizeColorFunction(rowDelegate) : rowDelegate.secondaryTextColor
        return rowDelegate.secondaryTextColor
    }

    function horizontalAlignmentForColumn(columnName) {
        return columnName === "size" ? Text.AlignRight : Text.AlignLeft
    }

    function callOrEmpty(fn, arg1, arg2) {
        if (fn) {
            return fn(arg1, arg2)
        }
        return ""
    }

    Rectangle {
        id: rangeAnchorMarker
        anchors.fill: parent
        anchors.margins: 0
        radius: rowDelegate.radius
        visible: rowDelegate.rangeAnchor && rowDelegate.selected

        // Draw the anchor marker as an outline, not as a filled inner background.
        // This keeps the row's selected/current fill intact and makes the marker itself visible.
        color: "transparent"
        border.color: rowDelegate.rangeAnchorMarkerVisualColor()
        border.width: visible ? 2 : 0
        opacity: 1.0
        z: 4
    }

    Item {
        id: dragProxy
        z: 2
        width: 1
        height: 1
        visible: false
        Drag.active: rowMouseArea.drag.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction
        Drag.mimeData: {
            "text/uri-list": rowDelegate.uriListFromPathFunction ? rowDelegate.uriListFromPathFunction(rowDelegate.path) : rowDelegate.path,
            "text/plain": rowDelegate.path
        }
    }

    RowLayout {
        z: 2
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Component {
            id: nameColumnComponent

            RowLayout {
                anchors.fill: parent
                spacing: 6

                FileIcon {
                    rowData: rowDelegate
                    iconSize: rowDelegate.fileIconSize
                    fileIconNameFunction: rowDelegate.fileIconNameFunction
                }

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    text: rowDelegate.highlightedFileNameFunction ? rowDelegate.highlightedFileNameFunction(rowDelegate.name) : rowDelegate.name
                    textFormat: Text.RichText
                    color: rowDelegate.isDir ? rowDelegate.folderTextColor : rowDelegate.fileTextColor
                    elide: Text.ElideRight
                    font.family: rowDelegate.rowFontFamily
                }
            }
        }

        Component {
            id: textColumnComponent

            Label {
                property string profileColumnName: ""
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: rowDelegate.horizontalAlignmentForColumn(profileColumnName)
                text: rowDelegate.textForColumn(profileColumnName)
                color: rowDelegate.textColorForColumn(profileColumnName)
                elide: Text.ElideRight
                font.family: rowDelegate.rowFontFamily
            }
        }

        Repeater {
            model: rowDelegate.columnProfileColumns

            Cell {
                required property var modelData
                property string profileColumnName: String(modelData.key || "")

                columnName: profileColumnName
                sortColumn: rowDelegate.sortColumn
                selected: rowDelegate.selected
                current: rowDelegate.current
                rangeAnchor: rowDelegate.rangeAnchor
                activeSortColumnColor: rowDelegate.activeSortColumnColor
                activeSortColumnSelectedColor: rowDelegate.activeSortColumnSelectedColor
                activeSortColumnCurrentColor: rowDelegate.activeSortColumnCurrentColor
                Layout.fillWidth: Boolean(modelData.fillWidth)
                Layout.preferredWidth: Number(modelData.width || 0) > 0 ? Number(modelData.width) : -1

                Loader {
                    anchors.fill: parent
                    sourceComponent: profileColumnName === "name" ? nameColumnComponent : textColumnComponent
                    onLoaded: {
                        if (item && item.profileColumnName !== undefined) {
                            item.profileColumnName = profileColumnName
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: rowMouseArea
        anchors.fill: parent
        z: 3
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        drag.target: dragProxy
        drag.threshold: 8
        preventStealing: false
        propagateComposedEvents: false

        onPressed: function(mouse) {
            rowDelegate.rowPressed(mouse, rowDelegate.index)
            dragProxy.x = 0
            dragProxy.y = 0
        }

        onDoubleClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                rowDelegate.rowDoubleClicked(rowDelegate.index)
            }
        }

        onPositionChanged: function(mouse) {
            if (drag.active) {
                dragProxy.x = mouse.x
                dragProxy.y = mouse.y
            }
        }

        onReleased: {
            dragProxy.x = 0
            dragProxy.y = 0
        }

        onCanceled: {
            dragProxy.x = 0
            dragProxy.y = 0
        }
    }

    component Cell: Rectangle {
        property string columnName
        property string sortColumn
        property bool selected: false
        property bool current: false
        property bool rangeAnchor: false
        property color activeSortColumnColor: "#2b3544"
        property color activeSortColumnSelectedColor: "#991b1b"
        property color activeSortColumnCurrentColor: "#2A894D"

        function tintedCellColor(baseColor) {
            return rowDelegate.index % 2 === 0 ? baseColor : Qt.darker(baseColor, 1.10)
        }

        function activeSortColumnVisualColor() {
            if (current) {
                return tintedCellColor(activeSortColumnCurrentColor)
            }

            if (selected) {
                return tintedCellColor(activeSortColumnSelectedColor)
            }

            return tintedCellColor(activeSortColumnColor)
        }

        Layout.fillHeight: true
        radius: 3
        color: rangeAnchor
               ? "transparent"
               : (sortColumn === columnName
                  ? activeSortColumnVisualColor()
                  : "transparent")
    }
}

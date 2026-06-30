import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Layouts

Rectangle {
    id: rowDelegate

    required property int index
    required property string name
    required property string kind
    required property string mimeType
    required property double sizeBytes
    required property string sizeStatus
    required property double modifiedSecs
    required property double durationSecs
    required property string codec
    required property string videoCodec
    required property string audioCodec
    required property double bitrate
    required property double fps
    required property double mediaWidth
    required property double mediaHeight
    required property string mediaStatus
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



    function displayDuration(seconds) {
        if (seconds === null || seconds === undefined || Number(seconds) < 0) return ""
        let total = Math.round(Number(seconds))
        let hours = Math.floor(total / 3600)
        let minutes = Math.floor((total % 3600) / 60)
        let secs = total % 60
        if (hours > 0) return String(hours) + ":" + String(minutes).padStart(2, "0") + ":" + String(secs).padStart(2, "0")
        return String(minutes) + ":" + String(secs).padStart(2, "0")
    }

    function displayBitrate(bitsPerSecond) {
        if (bitsPerSecond === null || bitsPerSecond === undefined || Number(bitsPerSecond) <= 0) return ""
        let kiloBits = Number(bitsPerSecond) / 1000
        if (kiloBits >= 1000) return (kiloBits / 1000).toFixed(1) + " Mbps"
        return Math.round(kiloBits) + " kbps"
    }

    function displayDecimal(value, decimals) {
        if (value === null || value === undefined || Number(value) <= 0) return ""
        return Number(value).toFixed(decimals)
    }

    function displayPositiveInteger(value) {
        if (value === null || value === undefined || Number(value) <= 0) return ""
        return String(Math.round(Number(value)))
    }

    function displayTypeText() {
        let mime = String(rowDelegate.mimeType || "")
        if (rowDelegate.isDir || mime === "inode/directory")
            return "Folder"
        if (mime === "inode/symlink")
            return "Symlink"
        if (mime.length > 0)
            return mime
        return rowDelegate.kind
    }


    function isMediaColumn(columnName) {
        return columnName === "duration"
               || columnName === "codec"
               || columnName === "videoCodec"
               || columnName === "audioCodec"
               || columnName === "bitrate"
               || columnName === "fps"
               || columnName === "width"
               || columnName === "height"
    }

    function mediaPlaceholderText(columnName) {
        if (!rowDelegate.isMediaColumn(columnName))
            return ""
        if (rowDelegate.mediaStatus === "scanning")
            return "…"
        if (rowDelegate.mediaStatus === "error")
            return "—"
        return ""
    }

    function mediaTextOrPlaceholder(columnName, valueText) {
        let placeholder = rowDelegate.mediaPlaceholderText(columnName)
        if (placeholder.length > 0)
            return placeholder
        return valueText
    }

    function textForColumn(columnName) {
        if (columnName === "kind") return rowDelegate.displayTypeText()
        if (columnName === "mimeType") return rowDelegate.displayTypeText()
        if (columnName === "size") return rowDelegate.displaySizeFunction ? rowDelegate.displaySizeFunction(rowDelegate.sizeBytes, rowDelegate) : ""
        if (columnName === "modified") return rowDelegate.modifiedTextFunction ? rowDelegate.modifiedTextFunction(rowDelegate.modifiedSecs) : ""
        if (columnName === "duration") return rowDelegate.mediaTextOrPlaceholder(columnName, rowDelegate.displayDuration(rowDelegate.durationSecs))
        if (columnName === "codec") return rowDelegate.mediaTextOrPlaceholder(columnName, rowDelegate.codec)
        if (columnName === "videoCodec") return rowDelegate.mediaTextOrPlaceholder(columnName, rowDelegate.videoCodec)
        if (columnName === "audioCodec") return rowDelegate.mediaTextOrPlaceholder(columnName, rowDelegate.audioCodec)
        if (columnName === "bitrate") return rowDelegate.mediaTextOrPlaceholder(columnName, rowDelegate.displayBitrate(rowDelegate.bitrate))
        if (columnName === "fps") return rowDelegate.mediaTextOrPlaceholder(columnName, rowDelegate.displayDecimal(rowDelegate.fps, 2))
        if (columnName === "width") return rowDelegate.mediaTextOrPlaceholder(columnName, rowDelegate.displayPositiveInteger(rowDelegate.mediaWidth))
        if (columnName === "height") return rowDelegate.mediaTextOrPlaceholder(columnName, rowDelegate.displayPositiveInteger(rowDelegate.mediaHeight))
        return ""
    }

    function textColorForColumn(columnName) {
        if (rowDelegate.isMediaColumn(columnName)) {
            return rowDelegate.mediaPlaceholderText(columnName).length > 0 ? rowDelegate.secondaryTextColor : rowDelegate.fileTextColor
        }
        if (columnName === "size") return rowDelegate.sizeColorFunction ? rowDelegate.sizeColorFunction(rowDelegate) : rowDelegate.secondaryTextColor
        return rowDelegate.secondaryTextColor
    }

    function horizontalAlignmentForColumn(columnName) {
        return columnName === "name" ? Text.AlignLeft : Text.AlignRight
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

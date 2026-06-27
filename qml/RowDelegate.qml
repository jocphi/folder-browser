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
    property bool selected: false
    property bool current: false

    property color rowEvenColor: "#1f2937"
    property color rowOddColor: "#20242b"
    property color selectedRowColor: "#7f1d1d"
    property color keyboardCurrentRowColor: "#14532d"
    property color activeSortColumnColor: "#2b3544"
    property color activeSortColumnSelectedColor: "#991b1b"
    property color activeSortColumnCurrentColor: "#2A894D"
    property color folderTextColor: "#bfdbfe"
    property color fileTextColor: "#e5e7eb"
    property color secondaryTextColor: "#d1d5db"

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
    color: selected && current
           ? keyboardCurrentRowColor
           : (selected
              ? selectedRowColor
              : (current ? keyboardCurrentRowColor : (index % 2 === 0 ? rowEvenColor : rowOddColor)))

    function callOrEmpty(fn, arg1, arg2) {
        if (fn) {
            return fn(arg1, arg2)
        }
        return ""
    }

    Item {
        id: dragProxy
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
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Cell {
            columnName: "name"
            sortColumn: rowDelegate.sortColumn
            selected: rowDelegate.selected
            current: rowDelegate.current
            activeSortColumnColor: rowDelegate.activeSortColumnColor
            activeSortColumnSelectedColor: rowDelegate.activeSortColumnSelectedColor
            activeSortColumnCurrentColor: rowDelegate.activeSortColumnCurrentColor
            Layout.fillWidth: true

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

        Cell {
            columnName: "kind"
            sortColumn: rowDelegate.sortColumn
            selected: rowDelegate.selected
            current: rowDelegate.current
            activeSortColumnColor: rowDelegate.activeSortColumnColor
            activeSortColumnSelectedColor: rowDelegate.activeSortColumnSelectedColor
            activeSortColumnCurrentColor: rowDelegate.activeSortColumnCurrentColor
            Layout.preferredWidth: 90

            Label {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: rowDelegate.kind
                color: rowDelegate.secondaryTextColor
                elide: Text.ElideRight
                font.family: rowDelegate.rowFontFamily
            }
        }

        Cell {
            columnName: "size"
            sortColumn: rowDelegate.sortColumn
            selected: rowDelegate.selected
            current: rowDelegate.current
            activeSortColumnColor: rowDelegate.activeSortColumnColor
            activeSortColumnSelectedColor: rowDelegate.activeSortColumnSelectedColor
            activeSortColumnCurrentColor: rowDelegate.activeSortColumnCurrentColor
            Layout.preferredWidth: 100

            Label {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: rowDelegate.displaySizeFunction ? rowDelegate.displaySizeFunction(rowDelegate.sizeBytes, rowDelegate) : ""
                color: rowDelegate.sizeColorFunction ? rowDelegate.sizeColorFunction(rowDelegate) : rowDelegate.secondaryTextColor
                font.family: rowDelegate.rowFontFamily
            }
        }

        Cell {
            columnName: "modified"
            sortColumn: rowDelegate.sortColumn
            selected: rowDelegate.selected
            current: rowDelegate.current
            activeSortColumnColor: rowDelegate.activeSortColumnColor
            activeSortColumnSelectedColor: rowDelegate.activeSortColumnSelectedColor
            activeSortColumnCurrentColor: rowDelegate.activeSortColumnCurrentColor
            Layout.preferredWidth: 210

            Label {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: rowDelegate.modifiedTextFunction ? rowDelegate.modifiedTextFunction(rowDelegate.modifiedSecs) : ""
                color: rowDelegate.secondaryTextColor
                elide: Text.ElideRight
                font.family: rowDelegate.rowFontFamily
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
        onPressed: function(mouse) {
            rowDelegate.rowPressed(mouse, rowDelegate.index)
        }
        onClicked: function(mouse) {}
        onDoubleClicked: rowDelegate.rowDoubleClicked(rowDelegate.index)
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
        property color activeSortColumnColor: "#2b3544"
        property color activeSortColumnSelectedColor: "#991b1b"
        property color activeSortColumnCurrentColor: "#2A894D"

        Layout.fillHeight: true
        radius: 3
        color: sortColumn === columnName
               ? (selected
                  ? activeSortColumnSelectedColor
                  : (current ? activeSortColumnCurrentColor : activeSortColumnColor))
               : "transparent"
    }
}

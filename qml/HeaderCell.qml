import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: headerCell

    property string title
    property string columnName
    property string sortColumn
    property bool sortAscending: true
    property string rowFontFamily
    property color activeSortHeaderColor: "#374151"
    property color activeSortBorderColor: "#60a5fa"
    property color headerTextColor: "#f9fafb"
    property var menu

    signal sortRequested(string columnName)

    Layout.fillHeight: true
    radius: 4
    color: sortColumn === columnName ? activeSortHeaderColor : "transparent"
    border.color: sortColumn === columnName ? activeSortBorderColor : "transparent"

    function sortLabel() {
        if (sortColumn !== columnName) {
            return title
        }
        return title + (sortAscending ? " ▲" : " ▼")
    }

    Label {
        anchors.centerIn: parent
        text: headerCell.sortLabel()
        color: headerTextColor
        font.bold: true
        font.family: rowFontFamily
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (menu) {
                    menu.popup()
                }
            } else {
                headerCell.sortRequested(columnName)
            }
        }
    }
}

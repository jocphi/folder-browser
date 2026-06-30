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

    function headerHorizontalAlignment() {
        return columnName === "name" ? Text.AlignLeft : Text.AlignRight
    }

    signal menuRequested(string columnName, real sceneX, real sceneY)

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

    function requestHeaderMenu(localX, localY) {
        let scenePoint = headerCell.mapToItem(null, localX, localY)
        headerCell.menuRequested(columnName, scenePoint.x, scenePoint.y)
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
        acceptedButtons: Qt.LeftButton
        onClicked: function(mouse) {
            headerCell.sortRequested(columnName)
            mouse.accepted = true
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        gesturePolicy: TapHandler.WithinBounds
        onTapped: function(eventPoint, button) {
            headerCell.requestHeaderMenu(eventPoint.position.x, eventPoint.position.y)
        }
    }
}

import QtQuick
import QtQuick.Controls.impl
import QtQuick.Layouts

IconImage {
    id: fileIcon

    property var rowData
    property int iconSize: 32
    property var fileIconNameFunction

    Layout.preferredWidth: iconSize
    Layout.preferredHeight: iconSize
    Layout.alignment: Qt.AlignVCenter

    name: fileIconNameFunction && rowData ? fileIconNameFunction(rowData) : "text-x-generic"
    sourceSize.width: iconSize
    sourceSize.height: iconSize
    color: "transparent"
}

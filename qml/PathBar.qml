import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: pathBar

    property alias pathText: pathField.text
    property string filterText: ""
    property bool showHidden: false

    signal goUpRequested()
    signal scanRequested(string pathText)
    signal colorsRequested()
    signal filterTextEdited(string text)
    signal showHiddenToggled(bool checked)

    spacing: 8

    function forcePathFocus() {
        pathField.forceActiveFocus()
    }

    Button { text: "Up"; onClicked: pathBar.goUpRequested() }

    TextField {
        id: pathField
        Layout.fillWidth: true
        placeholderText: "Enter a directory path, e.g. /home/joc/Pictures"
        selectByMouse: true
        onAccepted: pathBar.scanRequested(text)
    }

    Button { text: "Scan"; onClicked: pathBar.scanRequested(pathField.text) }
    Button { text: "Colors"; onClicked: pathBar.colorsRequested() }

    TextField {
        id: filterField
        Layout.preferredWidth: 220
        text: pathBar.filterText
        placeholderText: "Filter/search"
        selectByMouse: true
        onTextChanged: pathBar.filterTextEdited(text)
        ToolTip.visible: hovered
        ToolTip.text: "Filter by filename, type, or path"
    }

    CheckBox {
        id: hiddenToggle
        text: "Show hidden"
        checked: pathBar.showHidden
        onToggled: pathBar.showHiddenToggled(checked)
        ToolTip.visible: hovered
        ToolTip.text: "Show entries whose names start with a dot"
    }
}

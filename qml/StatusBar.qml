import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: statusBar

    property string statusText: ""
    property int selectedCount: 0
    property int visibleCount: 0
    property int totalCount: 0
    property string filterText: ""
    property color secondaryTextColor: "#d1d5db"

    spacing: 8

    Label {
        Layout.fillWidth: true
        text: statusBar.statusText + " — " + statusBar.selectedCount + " selected"
        color: statusBar.secondaryTextColor
        elide: Text.ElideRight
    }

    Label {
        text: statusBar.filterText.length > 0
              ? statusBar.visibleCount + " / " + statusBar.totalCount + " matches"
              : statusBar.visibleCount + " / " + statusBar.totalCount + " items"
        color: statusBar.secondaryTextColor
    }
}

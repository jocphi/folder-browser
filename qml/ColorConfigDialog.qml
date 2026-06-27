import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Item {
    id: colorConfigDialog

    property var colorTarget
    property var settingsTarget
    property var colorDefinitions: []
    property string rowFontFamily: "monospace"

    property color titleTextColor: "#f9fafb"
    property color panelBackgroundColor: "#20242b"
    property color panelFocusBorderColor: "#60a5fa"
    property color secondaryTextColor: "#d1d5db"
    property color rowEvenColor: "#1f2937"
    property color rowOddColor: "#20242b"

    width: colorTarget ? colorTarget.width : 640
    height: colorTarget ? colorTarget.height : 640
    visible: false

    function open() {
        popup.open()
    }

    function close() {
        popup.close()
    }

    function colorValue(key, fallbackValue) {
        if (colorTarget && colorTarget[key] !== undefined) {
            return colorTarget[key]
        }
        return fallbackValue || "#000000"
    }

    function setColorValue(key, value) {
        if (colorTarget && colorTarget[key] !== undefined) {
            colorTarget[key] = value
        }
    }

    function loadColorSettings() {
        if (!colorTarget || !settingsTarget) {
            return
        }
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            let definition = colorDefinitions[index]
            colorTarget[definition.key] = settingsTarget[definition.key] || definition.defaultValue
        }
    }

    function applyColorSettings() {
        if (!colorTarget || !settingsTarget) {
            return
        }
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            let key = colorDefinitions[index].key
            settingsTarget[key] = String(colorTarget[key])
        }
    }

    function resetColorSetting(key) {
        if (!colorTarget) {
            return
        }
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            let definition = colorDefinitions[index]
            if (definition.key === key) {
                colorTarget[key] = definition.defaultValue
                return
            }
        }
    }

    function resetAllColors() {
        if (!colorTarget) {
            return
        }
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            let definition = colorDefinitions[index]
            colorTarget[definition.key] = definition.defaultValue
        }
    }

    ColorDialog {
        id: appColorDialog
        property string targetColorProperty: ""
        title: "Select color"
        selectedColor: targetColorProperty.length > 0 ? colorConfigDialog.colorValue(targetColorProperty, "white") : "white"
        onSelectedColorChanged: {
            if (visible && targetColorProperty.length > 0) {
                colorConfigDialog.setColorValue(targetColorProperty, selectedColor)
            }
        }
        onAccepted: {
            if (targetColorProperty.length > 0) {
                colorConfigDialog.setColorValue(targetColorProperty, selectedColor)
            }
        }
    }

    Popup {
        id: popup
        modal: true
        focus: true
        width: Math.min(colorConfigDialog.width - 48, 640)
        height: Math.min(colorConfigDialog.height - 48, 640)
        x: Math.round((colorConfigDialog.width - width) / 2)
        y: Math.round((colorConfigDialog.height - height) / 2)
        padding: 12

        background: Rectangle {
            color: colorConfigDialog.panelBackgroundColor
            border.color: colorConfigDialog.panelFocusBorderColor
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "Colors"
                color: colorConfigDialog.titleTextColor
                font.bold: true
                font.pixelSize: 20
                Layout.fillWidth: true
            }

            Label {
                text: "Click a color rectangle to change the color immediately. Apply saves to the config file."
                color: colorConfigDialog.secondaryTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: popup.width - 36
                    spacing: 6

                    Repeater {
                        model: colorConfigDialog.colorDefinitions

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 4
                            color: index % 2 === 0 ? colorConfigDialog.rowEvenColor : colorConfigDialog.rowOddColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10

                                Label {
                                    text: modelData.label
                                    color: colorConfigDialog.secondaryTextColor
                                    font.family: colorConfigDialog.rowFontFamily
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    Layout.preferredWidth: 78
                                    Layout.preferredHeight: 24
                                    radius: 4
                                    color: colorConfigDialog.colorValue(modelData.key, modelData.defaultValue)
                                    border.color: colorConfigDialog.panelFocusBorderColor

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            appColorDialog.targetColorProperty = modelData.key
                                            appColorDialog.selectedColor = colorConfigDialog.colorValue(modelData.key, modelData.defaultValue)
                                            appColorDialog.open()
                                        }
                                    }
                                }

                                Label {
                                    text: String(colorConfigDialog.colorValue(modelData.key, modelData.defaultValue))
                                    color: colorConfigDialog.secondaryTextColor
                                    font.family: colorConfigDialog.rowFontFamily
                                    Layout.preferredWidth: 105
                                    elide: Text.ElideRight
                                }

                                Button {
                                    text: "Reset"
                                    onClicked: colorConfigDialog.resetColorSetting(modelData.key)
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "Reset all"
                    onClicked: colorConfigDialog.resetAllColors()
                }
                Button {
                    text: "Cancel"
                    onClicked: {
                        colorConfigDialog.loadColorSettings()
                        popup.close()
                    }
                }
                Button {
                    text: "Apply"
                    onClicked: {
                        colorConfigDialog.applyColorSettings()
                        popup.close()
                    }
                }
            }
        }
    }
}

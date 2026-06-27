use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new_qml_module(
        QmlModule::new("dk.john.folderbrowser")
            .version(1, 0)
            .qml_file("qml/main.qml")
            .qml_file("qml/HeaderCell.qml")
            .qml_file("qml/PathBar.qml")
            .qml_file("qml/StatusBar.qml")
            .qml_file("qml/ColorConfigDialog.qml")
            .qml_file("qml/RowDelegate.qml")
            .qml_file("qml/FileListView.qml")
            .qml_file("qml/FileIcon.qml"),
    )
    // Qt Core is always linked. The cxx-qt-lib "full" feature enables Qt GUI/QML types.
    // Qt QML commonly needs Qt Network available on some platforms.
    .qt_module("Network")
    .files(["src/cxxqt_object.rs"])
    .build();
}

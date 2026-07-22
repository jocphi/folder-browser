use cxx_qt_build::{CxxQtBuilder, QmlModule};
use std::path::PathBuf;
use std::process::Command;

fn main() {
    // cxx-qt-build 0.8.1 does not expose qobject_header(). Generate the
    // meta-object source explicitly, then compile it with the same builder.
    let out_dir = PathBuf::from(std::env::var_os("OUT_DIR").expect("OUT_DIR is set by Cargo"));
    let moc_output = out_dir.join("moc_native_file_model.cpp");
    let qmake = std::env::var_os("QMAKE").unwrap_or_else(|| "/usr/bin/qmake6".into());
    let qt_libexec = Command::new(&qmake)
        .args(["-query", "QT_HOST_LIBEXECS"])
        .output()
        .expect("failed to query Qt host libexec directory with qmake");
    if !qt_libexec.status.success() {
        panic!("qmake -query QT_HOST_LIBEXECS failed");
    }
    let moc = PathBuf::from(String::from_utf8_lossy(&qt_libexec.stdout).trim()).join("moc");
    let moc_status = Command::new(&moc)
        .arg("src/native_file_model.h")
        .arg("-o")
        .arg(&moc_output)
        .status()
        .unwrap_or_else(|error| panic!("failed to run {}: {error}", moc.display()));
    if !moc_status.success() {
        panic!("Qt moc failed for src/native_file_model.h");
    }
    println!("cargo::rerun-if-changed=src/native_file_model.h");

    // CXX-Qt compiles generated C++ against Qt headers. Clang 16 can emit
    // -Wsfinae-incomplete from the Qt/std header interaction around QChar.
    // Suppress only that known third-party warning when the compiler supports it.
    unsafe {
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
        .cpp_file("src/native_file_model.cpp")
        .cpp_file(&moc_output)
        .cc_builder(|cc| {
            cc.flag_if_supported("-Wno-sfinae-incomplete");
        })
        .build();
    }
}

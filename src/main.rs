pub mod formatting;
pub mod media_metadata;
pub mod file_size_status;
pub mod file_size_bytes;
pub mod file_size_text;
pub mod file_modified_secs;
pub mod file_path;
pub mod file_is_dir;
pub mod row;
pub mod file_row;
pub mod scanner;
pub mod dir_size_worker;
pub mod signals;
pub mod controller_accessors;
pub mod cxxqt_object;

use cxx_qt::casting::Upcast;
use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QQmlEngine, QString, QUrl};
use std::pin::Pin;

fn main() {
    let mut app = QGuiApplication::new();
    if let Some(mut app) = app.as_mut() {
        app.as_mut()
            .set_organization_name(&QString::from("John Ole Hasselbalch Clausen"));
        app.as_mut()
            .set_organization_domain(&QString::from("local.john"));
        app.as_mut()
            .set_application_name(&QString::from("folder-browser"));
    }
    let mut engine = QQmlApplicationEngine::new();

    if let Some(engine) = engine.as_mut() {
        engine.load(&QUrl::from(
            "qrc:/qt/qml/dk/john/folderbrowser/qml/main.qml",
        ));
    }

    if let Some(engine) = engine.as_mut() {
        let engine: Pin<&mut QQmlEngine> = engine.upcast_pin();
        engine
            .on_quit(|_| {
                println!("QML requested quit");
            })
            .release();
    }

    if let Some(app) = app.as_mut() {
        app.exec();
    }
}

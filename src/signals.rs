use core::pin::Pin;

use crate::cxxqt_object::qobject;

pub(crate) fn bump_update_generation(mut controller: Pin<&mut qobject::FolderBrowserController>) {
    let current = *controller.update_generation();
    let next = current.wrapping_add(1);
    controller.as_mut().set_update_generation(next);
}

# folder-browser-cxxqt-minimal

Minimal Cargo-first CXX-Qt + Qt 6 QML scaffold.

## CachyOS / Arch dependencies

```bash
sudo pacman -S --needed base-devel rust cmake qt6-base qt6-declarative qt6-tools
```

## Run

```bash
cd folder-browser-cxxqt-minimal
QMAKE=/usr/bin/qmake6 cargo run
```

If `/usr/bin/qmake6` does not exist, check:

```bash
command -v qmake qmake6
```

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import dk.john.folderbrowser 1.0

ApplicationWindow {
    id: root
    width: 1000
    height: 620
    visible: true
    title: "folder-browser - CXX-Qt local explorer"
    color: windowBackgroundColor

    property var allRows: []
    property string sortColumn: "name"
    property string activeColumnProfileName: "Default"
    property var columnProfiles: ({
        "Default": [
            ({ key: "name", label: "Name", width: -1, fillWidth: true, menuKey: "name" }),
            ({ key: "kind", label: "Type", width: 90, fillWidth: false, menuKey: "kind" }),
            ({ key: "size", label: "Size", width: 100, fillWidth: false, menuKey: "size" }),
            ({ key: "modified", label: "Modified", width: 210, fillWidth: false, menuKey: "modified" })
        ],
        "Media": [
            ({ key: "name", label: "Name", width: -1, fillWidth: true, menuKey: "name" }),
            ({ key: "kind", label: "Type", width: 120, fillWidth: false, menuKey: "kind" }),
            ({ key: "size", label: "Size", width: 110, fillWidth: false, menuKey: "size" }),
            ({ key: "modified", label: "Modified", width: 170, fillWidth: false, menuKey: "modified" }),
            ({ key: "duration", label: "Duration", width: 100, fillWidth: false, menuKey: "duration" }),
            ({ key: "videoCodec", label: "Video codec", width: 120, fillWidth: false, menuKey: "videoCodec" }),
            ({ key: "audioCodec", label: "Audio codec", width: 120, fillWidth: false, menuKey: "audioCodec" }),
            ({ key: "bitrate", label: "Bitrate", width: 110, fillWidth: false, menuKey: "bitrate" }),
            ({ key: "fps", label: "FPS", width: 70, fillWidth: false, menuKey: "fps" }),
            ({ key: "width", label: "Width", width: 80, fillWidth: false, menuKey: "width" }),
            ({ key: "height", label: "Height", width: 80, fillWidth: false, menuKey: "height" })
        ]
    })
    property bool sortAscending: true
    property bool showHidden: false
    property bool followSymlinks: false
    property string filterText: ""
    property string savedStartupPath: ""
    property int sizeScanTotal: countSizeScanTotal(allRows, controller.updateGeneration)
    property int sizeScanDone: countSizeScanDone(allRows, controller.updateGeneration)
    property bool isScanningSizes: sizeScanTotal > 0 && sizeScanDone < sizeScanTotal

    property int rowHeight: 32
    property int fileIconSize: rowHeight
    property string rowFontFamily: "Maple Mono NF"

    property bool foldersFirst: true
    property bool foldersAlwaysAZ: true
    property string sizeUnit: "auto"

    property var selectedPaths: []
    property int lastSelectedIndex: -1

    property color windowBackgroundColor: "#17191d"
    property color titleTextColor: "#f9fafb"
    property color panelBackgroundColor: "#20242b"
    property color panelBorderColor: "#3b4252"
    property color panelFocusBorderColor: "#60a5fa"
    property color headerBackgroundColor: "#111827"
    property color headerTextColor: "#f9fafb"
    property color rowEvenColor: "#1f2937"
    property color rowOddColor: "#20242b"
    property color selectedRowColor: "#7f1d1d"
    property color rangeAnchorMarkerColor: "#fbbf24"
    property string rangeAnchorMarkerMode: "lighter"
    property real rangeAnchorMarkerPercent: 10
    property color keyboardCurrentRowColor: "#14532d"
    property color activeSortHeaderColor: "#374151"
    property color activeSortColumnColor: "#2b3544"
    property color activeSortColumnSelectedColor: "#991b1b"
    property color activeSortColumnCurrentColor: "#2A894D"
    property color activeSortBorderColor: "#60a5fa"
    property color folderTextColor: "#bfdbfe"
    property color fileTextColor: "#e5e7eb"
    property color secondaryTextColor: "#d1d5db"
    property color emptyTextColor: "#d8dee9"
    property color dateHighlightColor: "#f97316"
    property color sizeUnknownColor: "#7f1d1d"
    property color sizeScanningColor: "#9ca3af"
    property color sizeDoneColor: "#22c55e"
    property color sizeErrorColor: "#ef4444"
    property var colorDefinitions: [
        ({ key: "windowBackgroundColor", label: "Window background", defaultValue: "#17191d" }),
        ({ key: "titleTextColor", label: "Title text", defaultValue: "#f9fafb" }),
        ({ key: "panelBackgroundColor", label: "Panel background", defaultValue: "#20242b" }),
        ({ key: "panelBorderColor", label: "Panel border", defaultValue: "#3b4252" }),
        ({ key: "panelFocusBorderColor", label: "Focused panel border", defaultValue: "#60a5fa" }),
        ({ key: "headerBackgroundColor", label: "Header background", defaultValue: "#111827" }),
        ({ key: "headerTextColor", label: "Header text", defaultValue: "#f9fafb" }),
        ({ key: "rowEvenColor", label: "Row", defaultValue: "#1f2937" }),
        ({ key: "rowOddColor", label: "Odd row", defaultValue: "#20242b" }),
        ({ key: "selectedRowColor", label: "Selected row", defaultValue: "#7f1d1d" }),
        ({ key: "rangeAnchorMarkerColor", label: "Range anchor marker", defaultValue: "#fbbf24" }),
        ({ key: "keyboardCurrentRowColor", label: "Current row", defaultValue: "#14532d" }),
        ({ key: "activeSortHeaderColor", label: "Sorted header", defaultValue: "#374151" }),
        ({ key: "activeSortColumnColor", label: "Sorted column", defaultValue: "#2b3544" }),
        ({ key: "activeSortColumnSelectedColor", label: "Sorted column selected", defaultValue: "#991b1b" }),
        ({ key: "activeSortColumnCurrentColor", label: "Sorted column current", defaultValue: "#2A894D" }),
        ({ key: "activeSortBorderColor", label: "Sorted/focus border", defaultValue: "#60a5fa" }),
        ({ key: "folderTextColor", label: "Folder name text", defaultValue: "#bfdbfe" }),
        ({ key: "fileTextColor", label: "File name text", defaultValue: "#e5e7eb" }),
        ({ key: "secondaryTextColor", label: "Secondary text", defaultValue: "#d1d5db" }),
        ({ key: "emptyTextColor", label: "Empty/list message text", defaultValue: "#d8dee9" }),
        ({ key: "dateHighlightColor", label: "Date highlight", defaultValue: "#f97316" }),
        ({ key: "sizeUnknownColor", label: "Size unknown", defaultValue: "#7f1d1d" }),
        ({ key: "sizeScanningColor", label: "Size scanning", defaultValue: "#9ca3af" }),
        ({ key: "sizeDoneColor", label: "Size done", defaultValue: "#22c55e" }),
        ({ key: "sizeErrorColor", label: "Size error", defaultValue: "#ef4444" })
    ]


    function loadInterfaceSettings() {
        sortColumn = uiSettings.sortColumn || "name"
        activeColumnProfileName = columnProfiles[uiSettings.columnProfileName] ? uiSettings.columnProfileName : "Default"
        sortAscending = uiSettings.sortAscending
        showHidden = uiSettings.showHidden
        followSymlinks = uiSettings.followSymlinks
        filterText = uiSettings.filterText || ""
        savedStartupPath = uiSettings.currentPath || ""
    }

    function saveInterfaceSettings() {
        uiSettings.sortColumn = sortColumn
        uiSettings.sortAscending = sortAscending
        uiSettings.showHidden = showHidden
        uiSettings.followSymlinks = followSymlinks
        uiSettings.filterText = filterText
    }

    function loadColorSettings() {
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            let definition = colorDefinitions[index]
            root[definition.key] = colorSettings[definition.key] || definition.defaultValue
        }
        root.rangeAnchorMarkerMode = colorSettings.rangeAnchorMarkerMode || "lighter"
        root.rangeAnchorMarkerPercent = Number(colorSettings.rangeAnchorMarkerPercent || 10)
    }

    function applyColorSettings() {
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            let key = colorDefinitions[index].key
            colorSettings[key] = String(root[key])
        }
        colorSettings.rangeAnchorMarkerMode = String(root.rangeAnchorMarkerMode)
        colorSettings.rangeAnchorMarkerPercent = Number(root.rangeAnchorMarkerPercent)
    }

    function resetColorSetting(key) {
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            if (colorDefinitions[index].key === key) {
                root[key] = colorDefinitions[index].defaultValue
                return
            }
        }
    }

    function resetAllColors() {
        for (let index = 0; index < colorDefinitions.length; index += 1) {
            root[colorDefinitions[index].key] = colorDefinitions[index].defaultValue
        }
    }

    function localPathFromUrl(urlValue) {
        let text = String(urlValue);
        if (text.startsWith("file://")) {
            return decodeURIComponent(text.replace(/^file:\/\//, ""));
        }
        return text;
    }

    function fileUriFromPath(pathText) {
        let text = String(pathText || "");
        if (text.startsWith("file://")) {
            return text;
        }
        if (!text.startsWith("/")) {
            return text;
        }
        return "file://" + text.split("/").map(function (part) {
            return encodeURIComponent(part);
        }).join("/");
    }

    function uriListFromPath(pathText) {
        return fileUriFromPath(pathText) + "\r\n";
    }

    function htmlEscape(textValue) {
        return String(textValue || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
    }

    function highlightedFileName(fileName) {
        let escaped = htmlEscape(fileName);
        let datePattern = /(\b\d{4}[-_.]\d{2}[-_.]\d{2}\b|\b\d{8}\b|\b\d{2}[-_.]\d{2}[-_.]\d{4}\b)/g;
        return escaped.replace(datePattern, "<span style='color:" + dateHighlightColor + "'>$1</span>");
    }


    function countSizeScanTotal(rows, generationToken) {
        let source = Array.from(rows || [])
        let total = 0
        for (let index = 0; index < source.length; index += 1) {
            let row = source[index]
            if (row && row.isDir) {
                total += 1
            }
        }
        return total
    }

    function countSizeScanDone(rows, generationToken) {
        let source = Array.from(rows || [])
        let done = 0
        for (let index = 0; index < source.length; index += 1) {
            let row = source[index]
            if (!row || !row.isDir) {
                continue
            }
            if (row.sizeStatus === "done" || row.sizeStatus === "error") {
                done += 1
            }
        }
        return done
    }

    function matchesFilter(row) {
        let query = String(filterText || "").trim().toLowerCase();
        if (query.length === 0) {
            return true;
        }
        if (!row) {
            return false;
        }
        return String(row.name || "").toLowerCase().indexOf(query) >= 0 || String(row.kind || "").toLowerCase().indexOf(query) >= 0 || String(row.path || "").toLowerCase().indexOf(query) >= 0;
    }

    function fileExtension(fileName) {
        let name = String(fileName || "").toLowerCase();
        let index = name.lastIndexOf(".");
        if (index <= 0 || index === name.length - 1) {
            return "";
        }
        return name.slice(index + 1);
    }

    function displayType(row) {
        if (!row)
            return "";
        let mime = String(row.mimeType || "");
        if (row.isDir || mime === "inode/directory")
            return "Folder";
        if (mime === "inode/symlink")
            return "Symlink";
        if (mime.length > 0)
            return mime;
        return row.kind || "";
    }

    function fileIconName(row) {
        if (!row)
            return "text-x-generic";
        if (row.isDir)
            return "folder";
        if (row.kind === "symlink")
            return "emblem-symbolic-link";

        let ext = fileExtension(row.name);
        if (["png", "jpg", "jpeg", "gif", "webp", "bmp", "tif", "tiff", "svg", "heic", "avif"].indexOf(ext) >= 0)
            return "image-x-generic";
        if (["mp4", "mkv", "webm", "avi", "mov", "m4v", "mpg", "mpeg", "wmv"].indexOf(ext) >= 0)
            return "video-x-generic";
        if (["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac", "wma"].indexOf(ext) >= 0)
            return "audio-x-generic";
        if (ext === "pdf")
            return "application-pdf";
        if (["zip", "7z", "rar", "tar", "gz", "xz", "bz2", "zst"].indexOf(ext) >= 0)
            return "package-x-generic";
        if (["rs", "py", "sh", "bash", "fish", "js", "ts", "qml", "cpp", "c", "h", "hpp", "lua"].indexOf(ext) >= 0)
            return "text-x-script";
        if (["txt", "md", "json", "toml", "yaml", "yml", "xml", "csv", "log"].indexOf(ext) >= 0)
            return "text-x-generic";
        if (["odt", "doc", "docx", "rtf"].indexOf(ext) >= 0)
            return "x-office-document";
        if (["ods", "xls", "xlsx"].indexOf(ext) >= 0)
            return "x-office-spreadsheet";
        if (["odp", "ppt", "pptx"].indexOf(ext) >= 0)
            return "x-office-presentation";
        if (["appimage", "exe", "bin", "run"].indexOf(ext) >= 0)
            return "application-x-executable";
        if (ext === "desktop")
            return "application-x-desktop";
        return "text-x-generic";
    }

    function parentPath(pathText) {
        let text = String(pathText);
        if (text.length <= 1)
            return "/";
        if (text.endsWith("/") && text.length > 1)
            text = text.slice(0, -1);
        let index = text.lastIndexOf("/");
        return index <= 0 ? "/" : text.slice(0, index);
    }

    function pad2(value) {
        return String(value).padStart(2, "0");
    }

    function modifiedText(seconds) {
        if (seconds === null || seconds === undefined || seconds < 0)
            return "";
        let date = new Date(seconds * 1000);
        return date.getFullYear() + "-" + pad2(date.getMonth() + 1) + "-" + pad2(date.getDate()) + " " + pad2(date.getHours()) + ":" + pad2(date.getMinutes()) + ":" + pad2(date.getSeconds());
    }

    function isHiddenRow(row) {
        return row && row.name && String(row.name).startsWith(".");
    }

    function filterRows(rows) {
        let source = Array.from(rows || []);
        if (!showHidden) {
            source = source.filter(function (row) {
                return !isHiddenRow(row);
            });
        }
        return source.filter(function (row) {
            return matchesFilter(row);
        });
    }

    function compareText(left, right) {
        return String(left || "").localeCompare(String(right || ""), Qt.locale(), {
            sensitivity: "base",
            numeric: true
        });
    }

    function columnProfileNames() {
        return Object.keys(columnProfiles).sort()
    }

    function activeColumnProfileColumns() {
        let columns = columnProfiles[activeColumnProfileName]
        if (!columns) {
            return columnProfiles["Default"]
        }
        return columns
    }

    function setColumnProfileName(profileName) {
        if (!columnProfiles[profileName]) {
            profileName = "Default"
        }

        if (activeColumnProfileName === profileName) {
            fileListView.forceListFocus()
            return
        }

        activeColumnProfileName = profileName
        uiSettings.columnProfileName = activeColumnProfileName
        fileListView.forceListFocus()
    }

    function compareNullableNumber(left, right) {
        let leftMissing = left === null || left === undefined || left < 0;
        let rightMissing = right === null || right === undefined || right < 0;
        if (leftMissing && rightMissing)
            return 0;
        if (leftMissing)
            return 1;
        if (rightMissing)
            return -1;
        return Number(left) - Number(right);
    }

    function sortRows(rows) {
        let sorted = Array.from(rows || []);
        let column = sortColumn;

        sorted.sort(function (left, right) {
            if (foldersFirst && left.isDir !== right.isDir) {
                return left.isDir ? -1 : 1;
            }

            let result = 0;
            if (isParentEntry(left) && !isParentEntry(right)) return -1;
            if (!isParentEntry(left) && isParentEntry(right)) return 1;
            if (column === "name") {
                result = compareText(left.name, right.name);
                if (foldersAlwaysAZ && left.isDir && right.isDir)
                    return result;
            } else if (column === "kind") {
                result = compareText(displayType(left), displayType(right));
            } else if (column === "size") {
                result = compareNullableNumber(left.sizeBytes, right.sizeBytes);
            } else if (column === "modified") {
                result = compareNullableNumber(left.modifiedSecs, right.modifiedSecs);
            } else if (column === "duration") {
                result = compareNullableNumber(left.durationSecs, right.durationSecs);
            } else if (column === "codec") {
                result = compareText(left.codec, right.codec);
            } else if (column === "videoCodec") {
                result = compareText(left.videoCodec, right.videoCodec);
            } else if (column === "audioCodec") {
                result = compareText(left.audioCodec, right.audioCodec);
            } else if (column === "bitrate") {
                result = compareNullableNumber(left.bitrate, right.bitrate);
            } else if (column === "fps") {
                result = compareNullableNumber(left.fps, right.fps);
            } else if (column === "width") {
                result = compareNullableNumber(left.mediaWidth, right.mediaWidth);
            } else if (column === "height") {
                result = compareNullableNumber(left.mediaHeight, right.mediaHeight);
            }

            if (result === 0) {
                result = left.isDir !== right.isDir ? (left.isDir ? -1 : 1) : compareText(left.name, right.name);
            }
            return sortAscending ? result : -result;
        });
        return sorted;
    }

    function sortLabel(columnName, title) {
        if (sortColumn !== columnName)
            return title;
        return title + (sortAscending ? " ▲" : " ▼");
    }

    function setSort(columnName) {
        if (sortColumn === columnName) {
            sortAscending = !sortAscending;
        } else {
            sortColumn = columnName;
            sortAscending = true;
        }
        refreshDisplayedRows();
        fileListView.forceListFocus();
    }

    function setSizeUnit(unitName) {
        sizeUnit = unitName;
        refreshDisplayedRows();
    }

    function europeanNumber(value, decimals) {
        if (value === null || value === undefined || value < 0 || !isFinite(value))
            return "";
        let fixed = Number(value).toFixed(decimals);
        let parts = fixed.split(".");
        let integerPart = parts[0];
        let decimalPart = parts.length > 1 ? parts[1] : "";
        let withThousands = "";
        while (integerPart.length > 3) {
            withThousands = "." + integerPart.slice(-3) + withThousands;
            integerPart = integerPart.slice(0, -3);
        }
        withThousands = integerPart + withThousands;
        return decimals > 0 ? withThousands + "," + decimalPart : withThousands;
    }

    function displaySize(sizeBytes, row) {
        if (row && row.isDir && row.sizeStatus === "unknown")
            return "unknown";
        if (row && row.isDir && row.sizeStatus === "scanning")
            return "scanning";
        if (row && row.isDir && row.sizeStatus === "error")
            return "error";
        if (row && row.isDir && row.sizeStatus === "stale" && (sizeBytes === null || sizeBytes === undefined || sizeBytes < 0))
            return "stale";
        if (sizeBytes === null || sizeBytes === undefined || sizeBytes < 0)
            return "";

        let bytes = Number(sizeBytes);
        if (sizeUnit === "auto") {
            let units = ["B", "kB", "MB", "GB", "TB"];
            let index = 0;
            let value = bytes;
            while (value >= 1000 && index < units.length - 1) {
                value /= 1000;
                index += 1;
            }
            return europeanNumber(value, 2) + " " + units[index];
        }

        let divisor = 1;
        let suffix = "B";
        if (sizeUnit === "kb") {
            divisor = 1000;
            suffix = "kB";
        } else if (sizeUnit === "mb") {
            divisor = 1000000;
            suffix = "MB";
        } else if (sizeUnit === "gb") {
            divisor = 1000000000;
            suffix = "GB";
        } else if (sizeUnit === "tb") {
            divisor = 1000000000000;
            suffix = "TB";
        }
        return europeanNumber(bytes / divisor, 2) + " " + suffix;
    }

    function sizeColor(row) {
        if (!row || !row.isDir)
            return secondaryTextColor;
        if (row.sizeStatus === "unknown")
            return selectedRowColor;
        if (row.sizeStatus === "stale")
            return sizeScanningColor;
        if (row.sizeStatus === "scanning")
            return sizeScanningColor;
        if (row.sizeStatus === "done")
            return sizeDoneColor;
        if (row.sizeStatus === "error")
            return sizeErrorColor;
        return secondaryTextColor;
    }

    function openHeaderMenu(columnName, sceneX, sceneY) {
        let headerMenu = null
        if (columnName === "name") {
            headerMenu = nameHeaderMenu
        } else if (columnName === "kind") {
            headerMenu = typeHeaderMenu
        } else if (columnName === "size") {
            headerMenu = sizeHeaderMenu
        } else if (columnName === "modified") {
            headerMenu = modifiedHeaderMenu
        }
        if (!headerMenu) {
            // Column profile scaffold columns do not have header menus yet.
            fileListView.forceListFocus()
            return
        }
        headerMenu.x = Math.round(sceneX)
        headerMenu.y = Math.round(sceneY)
        headerMenu.open()
    }

    function parentEntryRow() {
        let current = String(controller.currentPath || "")
        if (current.length === 0) return null
        let parent = parentPath(current)
        if (!parent || parent === current) return null
        return {
            name: "..", kind: "folder", mimeType: "inode/directory",
            sizeBytes: -1, sizeStatus: "unknown", modifiedSecs: -1,
            durationSecs: -1, codec: "", videoCodec: "", audioCodec: "",
            bitrate: -1, fps: -1, mediaWidth: -1, mediaHeight: -1,
            path: parent, isDir: true, isParentEntry: true
        }
    }

    function isParentEntry(row) { return row && row.isParentEntry === true }

    function rebuildRowsFromController() {
        let rows = [];
        let parentEntry = parentEntryRow();
        if (parentEntry) rows.push(parentEntry);
        for (let row = 0; row < controller.rowCount; row += 1) {
            rows.push({
                name: controller.fileName(row),
                kind: controller.fileKind(row),
                mimeType: controller.fileMimeType(row),
                sizeBytes: controller.fileSizeBytes(row),
                sizeStatus: controller.fileSizeStatus(row),
                modifiedSecs: controller.fileModifiedSecs(row),
                durationSecs: controller.fileDurationSecs(row),
                codec: controller.fileCodec(row),
                videoCodec: controller.fileVideoCodec(row),
                audioCodec: controller.fileAudioCodec(row),
                bitrate: controller.fileBitrate(row),
                fps: controller.fileFps(row),
                mediaWidth: controller.fileMediaWidth(row),
                mediaHeight: controller.fileMediaHeight(row),
                path: controller.filePath(row),
                isDir: controller.fileIsDir(row),
                isParentEntry: false
            });
        }
        allRows = rows;
        refreshDisplayedRows();
    }

    function restoreCurrentIndexAfterModelRefresh(preservedPath, fallbackIndex) {
        if (fileListView.count <= 0) {
            fileListView.currentIndex = -1
            return
        }

        let targetIndex = Math.max(0, Math.min(fallbackIndex, fileListView.count - 1))
        if (fileListView.currentIndex !== targetIndex) {
            fileListView.currentIndex = targetIndex
        }
    }



    function refreshDisplayedRows() {
        let rows = sortRows(filterRows(allRows))
        let sameShape = fileModel.count === rows.length

        if (sameShape) {
            for (let index = 0; index < rows.length; index += 1) {
                if (String(fileModel.get(index).path || "") !== String(rows[index].path || "")) {
                    sameShape = false
                    break
                }
            }
        }

        if (sameShape) {
            for (let index = 0; index < rows.length; index += 1) {
                let row = rows[index]
                fileModel.setProperty(index, "name", row.name)
                fileModel.setProperty(index, "kind", row.kind)
                fileModel.setProperty(index, "mimeType", row.mimeType !== undefined ? row.mimeType : "")
                fileModel.setProperty(index, "sizeBytes", row.sizeBytes)
                fileModel.setProperty(index, "sizeStatus", row.sizeStatus)
                fileModel.setProperty(index, "modifiedSecs", row.modifiedSecs)
                fileModel.setProperty(index, "durationSecs", row.durationSecs !== undefined ? row.durationSecs : -1)
                fileModel.setProperty(index, "codec", row.codec !== undefined ? row.codec : "")
                fileModel.setProperty(index, "videoCodec", row.videoCodec !== undefined ? row.videoCodec : "")
                fileModel.setProperty(index, "audioCodec", row.audioCodec !== undefined ? row.audioCodec : "")
                fileModel.setProperty(index, "bitrate", row.bitrate !== undefined ? row.bitrate : -1)
                fileModel.setProperty(index, "fps", row.fps !== undefined ? row.fps : -1)
                fileModel.setProperty(index, "mediaWidth", row.mediaWidth !== undefined ? row.mediaWidth : -1)
                fileModel.setProperty(index, "mediaHeight", row.mediaHeight !== undefined ? row.mediaHeight : -1)
                fileModel.setProperty(index, "path", row.path)
                fileModel.setProperty(index, "isDir", row.isDir)
            }
            return
        }

        let preservedIndex = fileListView.currentIndex
        fileModel.clear()
        for (let index = 0; index < rows.length; index += 1) {
            fileModel.append(rows[index])
        }

        if (fileModel.count > 0) {
            fileListView.currentIndex = Math.max(0, Math.min(preservedIndex, fileModel.count - 1))
        } else {
            fileListView.currentIndex = -1
        }
    }



    function setCurrentIndexWithOptionalRange(newIndex, extendSelection) {
        if (fileModel.count <= 0) {
            fileListView.currentIndex = -1
            return
        }

        newIndex = Math.max(0, Math.min(newIndex, fileModel.count - 1))
        let oldIndex = Math.max(0, Math.min(fileListView.currentIndex, fileModel.count - 1))

        if (extendSelection) {
            let anchor = lastSelectedIndex >= 0 ? lastSelectedIndex : oldIndex
            anchor = Math.max(0, Math.min(anchor, fileModel.count - 1))
            let fromIndex = Math.min(anchor, newIndex)
            let toIndex = Math.max(anchor, newIndex)
            let paths = []
            for (let index = fromIndex; index <= toIndex; index += 1) {
                paths.push(rowPathAt(index))
            }
            selectedPaths = paths
            lastSelectedIndex = anchor
        } else {
            selectOnlyIndexForPlainNavigation(newIndex)
        }

        fileListView.currentIndex = newIndex
        fileListView.containIndex(newIndex)
        fileListView.forceListFocus()
    }

    function pageMoveCurrent(direction, extendSelection) {
        if (fileModel.count <= 0) {
            fileListView.currentIndex = -1
            return
        }
        let startIndex = fileListView.currentIndex >= 0 ? fileListView.currentIndex : 0
        let step = fileListView.pageStep ? fileListView.pageStep() : 10
        setCurrentIndexWithOptionalRange(startIndex + direction * step, extendSelection)
    }

    function boundaryMoveCurrent(direction, extendSelection) {
        if (fileModel.count <= 0) {
            fileListView.currentIndex = -1
            return
        }
        setCurrentIndexWithOptionalRange(direction < 0 ? 0 : fileModel.count - 1, extendSelection)
    }

    function scanPath(pathText) {
        pathBar.pathText = String(pathText);
        controller.followSymlinks = root.followSymlinks
        controller.scanPath(pathBar.pathText);
        uiSettings.currentPath = pathBar.pathText
        selectedPaths = [];
        lastSelectedIndex = -1;
        rebuildRowsFromController();
        Qt.callLater(function () {
            fileListView.forceListFocus();
        });
    }

    function openRow(row) {
        if (!row)
            return;
        if (row.isDir)
            scanPath(row.path);
        else
            controller.statusText = "Selected file: " + row.path;
    }

    function openCurrentRow() {
        if (fileListView.currentIndex >= 0 && fileListView.currentIndex < fileModel.count) {
            openRow(fileModel.get(fileListView.currentIndex));
        }
    }

    function rowPathAt(index) {
        if (index < 0 || index >= fileModel.count)
            return "";
        return fileModel.get(index).path;
    }

    function selectOnlyIndexForPlainNavigation(index) {
        if (index < 0 || index >= fileModel.count) {
            selectedPaths = []
            lastSelectedIndex = -1
            return
        }

        let path = rowPathAt(index)
        selectedPaths = path.length > 0 ? [path] : []
        lastSelectedIndex = index
    }

        function keyboardMoveCurrent(direction, extendSelection) {
        if (fileModel.count <= 0) {
            fileListView.currentIndex = -1
            selectedPaths = []
            lastSelectedIndex = -1
            return
        }

        let oldIndex = fileListView.currentIndex >= 0 ? fileListView.currentIndex : 0
        let newIndex = Math.max(0, Math.min(oldIndex + direction, fileModel.count - 1))

        if (extendSelection) {
            let anchor = lastSelectedIndex >= 0 ? lastSelectedIndex : oldIndex
            anchor = Math.max(0, Math.min(anchor, fileModel.count - 1))

            let fromIndex = Math.min(anchor, newIndex)
            let toIndex = Math.max(anchor, newIndex)
            let paths = []

            for (let index = fromIndex; index <= toIndex; index += 1) {
                let path = rowPathAt(index)
                if (path.length > 0) {
                    paths.push(path)
                }
            }

            selectedPaths = paths
            lastSelectedIndex = anchor
        } else {
            selectOnlyIndexForPlainNavigation(newIndex)
        }

        fileListView.currentIndex = newIndex
        fileListView.containIndex(newIndex)
        fileListView.forceListFocus()
    }

    function isPathSelected(pathText) {
        return selectedPaths.indexOf(pathText) >= 0;
    }

    function isRowSelected(index) {
        return isPathSelected(rowPathAt(index));
    }

        function isRangeAnchorRow(index) {
        if (index < 0 || index >= fileModel.count || selectedPaths.length <= 0) {
            return false
        }

        let row = fileModel.get(index)
        let pathText = String(row.path || "")

        // The first selected path is the range pivot/anchor used for range selections.
        return pathText.length > 0 && pathText === String(selectedPaths[0] || "")
    }

    function setSingleSelection(index) {
        let path = rowPathAt(index);
        selectedPaths = path.length > 0 ? [path] : [];
        lastSelectedIndex = index;
    }

    function toggleSelection(index) {
        let path = rowPathAt(index);
        if (path.length === 0)
            return;
        let copy = Array.from(selectedPaths);
        let existing = copy.indexOf(path);
        if (existing >= 0)
            copy.splice(existing, 1);
        else
            copy.push(path);
        selectedPaths = copy;
        lastSelectedIndex = index;
    }

    function selectRange(index) {
        let anchor = lastSelectedIndex >= 0 ? lastSelectedIndex : fileListView.currentIndex;
        if (anchor < 0)
            anchor = index;
        let first = Math.min(anchor, index);
        let last = Math.max(anchor, index);
        let paths = [];
        for (let row = first; row <= last; row += 1) {
            let path = rowPathAt(row);
            if (path.length > 0)
                paths.push(path);
        }
        selectedPaths = paths;
    }

    function handleShiftCursorSelection(direction) {
        if (fileModel.count <= 0) {
            return;
        }

        let oldIndex = fileListView.currentIndex;
        if (oldIndex < 0) {
            oldIndex = 0;
        }

        let newIndex = Math.max(0, Math.min(fileModel.count - 1, oldIndex + direction));
        if (lastSelectedIndex < 0) {
            lastSelectedIndex = oldIndex;
        }

        fileListView.currentIndex = newIndex;
        selectRange(newIndex);
        fileListView.containIndex(newIndex);
        fileListView.forceListFocus();
    }

    function handleRowPress(mouse, index) {
        fileListView.currentIndex = index;
        fileListView.forceListFocus();
        if (mouse.modifiers & Qt.ShiftModifier) {
            selectRange(index);
        } else if (mouse.modifiers & Qt.ControlModifier) {
            toggleSelection(index);
        } else {
            setSingleSelection(index);
        }
    }

    FolderBrowserController {
        id: controller
        currentPath: root.localPathFromUrl(StandardPaths.writableLocation(StandardPaths.HomeLocation))
        statusText: "Ready"
        rowCount: 0
        updateGeneration: 0
        onUpdateGenerationChanged: rebuildRowsFromController()
    }

    ListModel {
        id: fileModel
    }


    Settings {
        id: uiSettings
        // Persist window size. Position is deliberately left to the Wayland compositor/session-restore protocol.
        property alias windowWidth: root.width
        property alias windowHeight: root.height
        category: "Interface"
        property string sortColumn: "name"
        property string columnProfileName: "Default"
        property bool sortAscending: true
        property bool showHidden: false
        property bool followSymlinks: false
        property string filterText: ""
        property string currentPath: ""
    }

    Settings {
        id: colorSettings
        category: "Colors"
        property string windowBackgroundColor: "#17191d"
        property string titleTextColor: "#f9fafb"
        property string panelBackgroundColor: "#20242b"
        property string panelBorderColor: "#3b4252"
        property string panelFocusBorderColor: "#60a5fa"
        property string headerBackgroundColor: "#111827"
        property string headerTextColor: "#f9fafb"
        property string rowEvenColor: "#1f2937"
        property string rowOddColor: "#20242b"
        property string selectedRowColor: "#7f1d1d"
        property string keyboardCurrentRowColor: "#14532d"
        property string activeSortHeaderColor: "#374151"
        property string activeSortColumnColor: "#2b3544"
        property string activeSortColumnSelectedColor: "#991b1b"
        property string activeSortColumnCurrentColor: "#2A894D"
        property string activeSortBorderColor: "#60a5fa"
        property string folderTextColor: "#bfdbfe"
        property string fileTextColor: "#e5e7eb"
        property string secondaryTextColor: "#d1d5db"
        property string emptyTextColor: "#d8dee9"
        property string dateHighlightColor: "#f97316"
        property string sizeUnknownColor: "#7f1d1d"
        property string sizeScanningColor: "#9ca3af"
        property string sizeDoneColor: "#22c55e"
        property string sizeErrorColor: "#ef4444"
    }


    Timer {
        id: rowsRebuildTimer
        interval: 250
        repeat: false
        onTriggered: rebuildRowsFromController()
    }

    onSortColumnChanged: saveInterfaceSettings()
    onSortAscendingChanged: saveInterfaceSettings()
    onFilterTextChanged: saveInterfaceSettings()
    onShowHiddenChanged: {
        saveInterfaceSettings()
        refreshDisplayedRows()
    }
    onFollowSymlinksChanged: saveInterfaceSettings()
    Component.onCompleted: {
        loadColorSettings()
        loadInterfaceSettings()
        scanPath(savedStartupPath.length > 0 ? savedStartupPath : controller.currentPath)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Label {
            text: "folder-browser"
            font.pixelSize: 24
            font.bold: true
            Layout.fillWidth: true
        }

        PathBar {
            id: pathBar
            Layout.fillWidth: true
            pathText: controller.currentPath
            filterText: root.filterText
            showHidden: root.showHidden
            followSymlinks: root.followSymlinks
            onGoUpRequested: root.scanPath(root.parentPath(controller.currentPath))
            onScanRequested: function(pathText) { root.scanPath(pathText) }
            onColorsRequested: colorConfigPopup.open()
            onFilterTextEdited: function(text) {
                root.filterText = text
                root.refreshDisplayedRows()
            }
            onShowHiddenToggled: function(checked) { root.showHidden = checked }
            onFollowSymlinksToggled: function(checked) {
                root.followSymlinks = checked
                root.scanPath(controller.currentPath)
            }
        }

        RowLayout {
            id: columnProfileBar
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Column profile"
                color: root.secondaryTextColor
                font.family: root.rowFontFamily
                verticalAlignment: Text.AlignVCenter
            }

            ComboBox {
                id: columnProfileComboBox
                model: root.columnProfileNames()
                currentIndex: Math.max(0, root.columnProfileNames().indexOf(root.activeColumnProfileName))
                Layout.preferredWidth: 160
                onActivated: function(index) {
                    let names = root.columnProfileNames()
                    if (index >= 0 && index < names.length) {
                        root.setColumnProfileName(names[index])
                    }
                }
            }

            Label {
                text: root.activeColumnProfileName === "Default"
                      ? "Current columns"
                      : "Profile scaffold; metadata columns will be enabled in later patches"
                color: root.secondaryTextColor
                font.family: root.rowFontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        FileListView {
            id: fileListView
            fileModel: fileModel
            sortColumn: root.sortColumn
            sortAscending: root.sortAscending
            columnProfileName: root.activeColumnProfileName
            columnProfileColumns: root.activeColumnProfileColumns()
            rowHeight: root.rowHeight
            fileIconSize: root.fileIconSize
            rowFontFamily: root.rowFontFamily
            panelBackgroundColor: root.panelBackgroundColor
            panelBorderColor: root.panelBorderColor
            panelFocusBorderColor: root.panelFocusBorderColor
            headerBackgroundColor: root.headerBackgroundColor
            emptyTextColor: root.emptyTextColor
            rowEvenColor: root.rowEvenColor
            rowOddColor: root.rowOddColor
            selectedRowColor: root.selectedRowColor
            rangeAnchorMarkerColor: root.rangeAnchorMarkerColor
            rangeAnchorMarkerMode: root.rangeAnchorMarkerMode
            rangeAnchorMarkerPercent: root.rangeAnchorMarkerPercent
            keyboardCurrentRowColor: root.keyboardCurrentRowColor
            activeSortHeaderColor: root.activeSortHeaderColor
            activeSortColumnColor: root.activeSortColumnColor
            activeSortColumnSelectedColor: root.activeSortColumnSelectedColor
            activeSortColumnCurrentColor: root.activeSortColumnCurrentColor
            activeSortBorderColor: root.activeSortBorderColor
            headerTextColor: root.headerTextColor
            folderTextColor: root.folderTextColor
            fileTextColor: root.fileTextColor
            secondaryTextColor: root.secondaryTextColor
            showHidden: root.showHidden
            allRowsLength: root.allRows.length
            nameHeaderMenu: root.nameHeaderMenu
            typeHeaderMenu: root.typeHeaderMenu
            sizeHeaderMenu: root.sizeHeaderMenu
            modifiedHeaderMenu: root.modifiedHeaderMenu
            isRowSelectedFunction: root.isRowSelected
            isRangeAnchorFunction: root.isRangeAnchorRow
            fileIconNameFunction: root.fileIconName
            uriListFromPathFunction: root.uriListFromPath
            highlightedFileNameFunction: root.highlightedFileName
            displaySizeFunction: root.displaySize
            sizeColorFunction: root.sizeColor
            modifiedTextFunction: root.modifiedText
            onSortRequested: function(columnName) { root.setSort(columnName) }
            onHeaderMenuRequested: function(columnName, sceneX, sceneY) { root.openHeaderMenu(columnName, sceneX, sceneY) }
            onOpenCurrentRequested: root.openCurrentRow()
            onGoParentRequested: root.scanPath(root.parentPath(controller.currentPath))
            onEscapeToPathRequested: pathBar.forcePathFocus()
            onToggleSelectionRequested: function(rowIndex) { root.toggleSelection(rowIndex) }
            onShiftCursorRequested: function(direction) { root.handleShiftCursorSelection(direction) }

            onKeyboardMoveCurrentRequested: function(direction, extendSelection) {
                root.keyboardMoveCurrent(direction, extendSelection)
            }

            onPageMoveRequested: function(direction, extendSelection) { root.pageMoveCurrent(direction, extendSelection) }
            onBoundaryMoveRequested: function(direction, extendSelection) { root.boundaryMoveCurrent(direction, extendSelection) }
            onRowPressed: function(mouse, rowIndex) { root.handleRowPress(mouse, rowIndex) }
            onRowDoubleClicked: function(rowIndex) { root.openRow(fileModel.get(rowIndex)) }
        }

        StatusBar {
            Layout.fillWidth: true
            statusText: controller.statusText
            selectedCount: selectedPaths.length
            visibleCount: fileListView.count
            totalCount: allRows.length
            filterText: root.filterText
            isScanning: root.isScanningSizes
            scanDone: root.sizeScanDone
            scanTotal: root.sizeScanTotal
            secondaryTextColor: root.secondaryTextColor
        }
    }

    Menu {
        id: nameHeaderMenu
        MenuItem {
            text: "Folders first"
            checkable: true
            checked: foldersFirst
            onTriggered: {
                foldersFirst = checked;
                refreshDisplayedRows();
            }
        }
        MenuItem {
            text: "Folders always sorted A-B"
            checkable: true
            checked: foldersAlwaysAZ
            onTriggered: {
                foldersAlwaysAZ = checked;
                refreshDisplayedRows();
            }
        }
        MenuSeparator {}
        MenuItem {
            text: "Dummy: Natural sort"
            enabled: false
        }
        MenuItem {
            text: "Dummy: Case-sensitive sort"
            enabled: false
        }
    }

    Menu {
        id: typeHeaderMenu
        MenuItem {
            text: "Dummy: Group by type"
            enabled: false
        }
        MenuItem {
            text: "Dummy: Hide unknown types"
            enabled: false
        }
    }
    Menu {
        id: modifiedHeaderMenu
        MenuItem {
            text: "Dummy: Today only"
            enabled: false
        }
        MenuItem {
            text: "Dummy: This week"
            enabled: false
        }
        MenuItem {
            text: "Dummy: ISO UTC time"
            enabled: false
        }
    }

    Menu {
        id: sizeHeaderMenu
        MenuItem {
            text: "Auto"
            checkable: true
            checked: sizeUnit === "auto"
            onTriggered: setSizeUnit("auto")
        }
        MenuSeparator {}
        MenuItem {
            text: "B"
            checkable: true
            checked: sizeUnit === "bytes"
            onTriggered: setSizeUnit("bytes")
        }
        MenuItem {
            text: "kB"
            checkable: true
            checked: sizeUnit === "kb"
            onTriggered: setSizeUnit("kb")
        }
        MenuItem {
            text: "MB"
            checkable: true
            checked: sizeUnit === "mb"
            onTriggered: setSizeUnit("mb")
        }
        MenuItem {
            text: "GB"
            checkable: true
            checked: sizeUnit === "gb"
            onTriggered: setSizeUnit("gb")
        }
        MenuItem {
            text: "TB"
            checkable: true
            checked: sizeUnit === "tb"
            onTriggered: setSizeUnit("tb")
        }
        MenuSeparator {}
        MenuItem {
            text: "Dummy: Hide empty sizes"
            enabled: false
        }
    }

        ColorConfigDialog {
        id: colorConfigPopup
        colorTarget: root
        settingsTarget: colorSettings
        colorDefinitions: root.colorDefinitions
        rowFontFamily: root.rowFontFamily
        titleTextColor: root.titleTextColor
        panelBackgroundColor: root.panelBackgroundColor
        panelFocusBorderColor: root.panelFocusBorderColor
        secondaryTextColor: root.secondaryTextColor
        rowEvenColor: root.rowEvenColor
        rowOddColor: root.rowOddColor
    }



}

#include "native_file_model.h"
#include <QMetaObject>
#include <QQmlEngine>
#include <QtQml/qqml.h>
#include <algorithm>
#include <cstdint>

NativeFileModel::NativeFileModel(QObject* p):QAbstractListModel(p){}
int NativeFileModel::rowCount(const QModelIndex& p) const { return p.isValid()?0:m_rows.size(); }
QHash<int,QByteArray> NativeFileModel::roleNames() const { return {
 {NameRole,"name"},{FamilyDescriptorRole,"familyDescriptor"},{KindRole,"kind"},
 {MimeTypeRole,"mimeType"},{MimeStatusRole,"mimeStatus"},{LiveStatusRole,"liveStatus"},
 {SizeBytesRole,"sizeBytes"},{SizeStatusRole,"sizeStatus"},{ModifiedSecsRole,"modifiedSecs"},
 {DurationSecsRole,"durationSecs"},{CodecRole,"codec"},{VideoCodecRole,"videoCodec"},
 {AudioCodecRole,"audioCodec"},{BitrateRole,"bitrate"},{FpsRole,"fps"},
 {MediaWidthRole,"mediaWidth"},{MediaHeightRole,"mediaHeight"},{MediaStatusRole,"mediaStatus"},
 {PathRole,"path"},{IsDirRole,"isDir"},{IsParentEntryRole,"isParentEntry"}}; }
QVariant NativeFileModel::data(const QModelIndex& i,int role) const {
 if(!i.isValid()||i.row()<0||i.row()>=m_rows.size()) return {};
 const auto names=roleNames(); return m_rows[i.row()].value(QString::fromUtf8(names.value(role))); }
void NativeFileModel::setController(QObject* v){ if(m_controller==v)return; m_controller=v; emit controllerChanged(); reload(); }
#define SETTER(name,field,type) void NativeFileModel::name(type v){if(field==v)return;field=v;emit optionsChanged();}
SETTER(setShowHidden,m_showHidden,bool) SETTER(setFamiliesOnly,m_familiesOnly,bool)
SETTER(setSortAscending,m_sortAscending,bool) SETTER(setFoldersFirst,m_foldersFirst,bool)
SETTER(setFoldersAlwaysAZ,m_foldersAlwaysAZ,bool)
void NativeFileModel::setFilterText(const QString&v){if(m_filterText==v)return;m_filterText=v;emit optionsChanged();}
void NativeFileModel::setSortColumn(const QString&v){if(m_sortColumn==v)return;m_sortColumn=v;emit optionsChanged();}
namespace {
QVariant invokeString(QObject* controller, const char* method, int row)
{
    if (!controller) {
        return {};
    }
    QString value;
    const bool ok = QMetaObject::invokeMethod(
        controller, method, Qt::DirectConnection,
        Q_RETURN_ARG(QString, value),
        Q_ARG(std::int32_t, static_cast<std::int32_t>(row)));
    return ok ? QVariant(value) : QVariant();
}

QVariant invokeInt64(QObject* controller, const char* method, int row)
{
    if (!controller) {
        return {};
    }
    std::int64_t value = 0;
    const bool ok = QMetaObject::invokeMethod(
        controller, method, Qt::DirectConnection,
        Q_RETURN_ARG(std::int64_t, value),
        Q_ARG(std::int32_t, static_cast<std::int32_t>(row)));
    return ok ? QVariant::fromValue<qlonglong>(static_cast<qlonglong>(value)) : QVariant();
}

QVariant invokeInt32(QObject* controller, const char* method, int row)
{
    if (!controller) {
        return {};
    }
    std::int32_t value = 0;
    const bool ok = QMetaObject::invokeMethod(
        controller, method, Qt::DirectConnection,
        Q_RETURN_ARG(std::int32_t, value),
        Q_ARG(std::int32_t, static_cast<std::int32_t>(row)));
    return ok ? QVariant::fromValue<int>(static_cast<int>(value)) : QVariant();
}

QVariant invokeDouble(QObject* controller, const char* method, int row)
{
    if (!controller) {
        return {};
    }
    double value = 0.0;
    const bool ok = QMetaObject::invokeMethod(
        controller, method, Qt::DirectConnection,
        Q_RETURN_ARG(double, value),
        Q_ARG(std::int32_t, static_cast<std::int32_t>(row)));
    return ok ? QVariant(value) : QVariant();
}

QVariant invokeBool(QObject* controller, const char* method, int row)
{
    if (!controller) {
        return {};
    }
    bool value = false;
    const bool ok = QMetaObject::invokeMethod(
        controller, method, Qt::DirectConnection,
        Q_RETURN_ARG(bool, value),
        Q_ARG(std::int32_t, static_cast<std::int32_t>(row)));
    return ok ? QVariant(value) : QVariant();
}
} // namespace

QVariantMap NativeFileModel::readRow(int r) const
{
    QVariantMap x;
    x["name"] = invokeString(m_controller, "fileName", r);
    x["familyDescriptor"] = invokeString(m_controller, "fileFamilyDescriptor", r);
    x["kind"] = invokeString(m_controller, "fileKind", r);
    x["mimeType"] = invokeString(m_controller, "fileMimeType", r);
    x["mimeStatus"] = invokeString(m_controller, "fileMimeStatus", r);
    x["liveStatus"] = invokeString(m_controller, "fileLiveStatus", r);
    x["sizeBytes"] = invokeInt64(m_controller, "fileSizeBytes", r);
    x["sizeStatus"] = invokeString(m_controller, "fileSizeStatus", r);
    x["modifiedSecs"] = invokeInt64(m_controller, "fileModifiedSecs", r);
    x["durationSecs"] = invokeDouble(m_controller, "fileDurationSecs", r);
    x["codec"] = invokeString(m_controller, "fileCodec", r);
    x["videoCodec"] = invokeString(m_controller, "fileVideoCodec", r);
    x["audioCodec"] = invokeString(m_controller, "fileAudioCodec", r);
    x["bitrate"] = invokeInt64(m_controller, "fileBitrate", r);
    x["fps"] = invokeDouble(m_controller, "fileFps", r);
    x["mediaWidth"] = invokeInt32(m_controller, "fileMediaWidth", r);
    x["mediaHeight"] = invokeInt32(m_controller, "fileMediaHeight", r);
    x["mediaStatus"] = invokeString(m_controller, "fileMediaStatus", r);
    x["path"] = invokeString(m_controller, "filePath", r);
    x["isDir"] = invokeBool(m_controller, "fileIsDir", r);
    x["isParentEntry"] = false;
    x["__sourceRow"] = r;
    return x;
}
QVariantMap NativeFileModel::parentRow() const {
 if (!m_controller) {
  return {};
 }
 QString current = m_controller->property("currentPath").toString();
 if (current.isEmpty() || current == "/") {
  return {};
 }
 while (current.size() > 1 && current.endsWith('/')) {
  current.chop(1);
 }
 const int slash = current.lastIndexOf('/');
 const QString parent = slash <= 0 ? "/" : current.left(slash);
 return {{"name",".."},{"familyDescriptor",""},{"kind","folder"},{"mimeType","inode/directory"},{"mimeStatus","done"},
 {"liveStatus","live"},{"sizeBytes",-1},{"sizeStatus","unknown"},{"modifiedSecs",-1},{"durationSecs",-1.0},
 {"codec",""},{"videoCodec",""},{"audioCodec",""},{"bitrate",-1},{"fps",-1.0},{"mediaWidth",-1},{"mediaHeight",-1},
 {"mediaStatus","none"},{"path",parent},{"isDir",true},{"isParentEntry",true}};
}
bool NativeFileModel::accepts(const QVariantMap&r) const {
 if (r.value("isParentEntry").toBool()) {
  return true;
 }
 const QString name = r.value("name").toString();
 if(!m_showHidden&&name.startsWith('.'))return false;
 if(m_familiesOnly&&(!r.value("isDir").toBool()||r.value("familyDescriptor").toString().isEmpty()))return false;
 QString q=m_filterText.trimmed(); if(q.isEmpty())return true;
 for(const char*k:{"name","familyDescriptor","kind","mimeType","path"}) if(r.value(k).toString().contains(q,Qt::CaseInsensitive))return true;
 return false;
}
int NativeFileModel::compare(const QVariantMap&a,const QVariantMap&b,const QString&c,bool ff,bool faz){
 bool ap=a.value("isParentEntry").toBool(),bp=b.value("isParentEntry").toBool(); if(ap!=bp)return ap?-1:1;
 bool ad=a.value("isDir").toBool(),bd=b.value("isDir").toBool(); if(ff&&ad!=bd)return ad?-1:1;
 auto txt=[&](const char*k){return QString::localeAwareCompare(a.value(k).toString(),b.value(k).toString());};
 int v=0; if(c=="size"||c=="modified"||c=="duration"||c=="bitrate"||c=="fps"||c=="width"||c=="height"){
  const char*k=c=="size"?"sizeBytes":c=="modified"?"modifiedSecs":c=="duration"?"durationSecs":c=="width"?"mediaWidth":c=="height"?"mediaHeight":c.toUtf8().constData();
  double av=a.value(k).toDouble(),bv=b.value(k).toDouble(); v=av<bv?-1:av>bv?1:0;
 } else { QByteArray k=(c=="live"?"liveStatus":c=="familyDescriptor"?"familyDescriptor":c=="kind"?"kind":c=="codec"?"codec":c=="videoCodec"?"videoCodec":c=="audioCodec"?"audioCodec":"name"); v=txt(k.constData()); }
 if (faz && ad && bd && c != "name") {
  v = txt("name");
 }
 if (v == 0) {
  v = txt("name");
 }
 return v;
}
void NativeFileModel::reload(){
 QVector<QVariantMap> rows; if(m_controller){ QVariantMap p=parentRow(); if(!p.isEmpty())rows.push_back(p); int n=m_controller->property("rowCount").toInt(); rows.reserve(n+1); for(int i=0;i<n;++i){auto r=readRow(i);if(accepts(r))rows.push_back(std::move(r));}}
 auto begin=rows.begin()+(rows.size()>0&&rows[0].value("isParentEntry").toBool()?1:0);
 std::stable_sort(begin,rows.end(),[&](const auto&a,const auto&b){int v=compare(a,b,m_sortColumn,m_foldersFirst,m_foldersAlwaysAZ);return m_sortAscending?v<0:v>0;});
 beginResetModel();
 m_rows=std::move(rows);
 m_sourceToVisibleRow.clear();
 for (int visibleRow = 0; visibleRow < m_rows.size(); ++visibleRow) {
  const int sourceRow = m_rows[visibleRow].value("__sourceRow", -1).toInt();
  if (sourceRow >= 0) {
   m_sourceToVisibleRow.insert(sourceRow, visibleRow);
  }
 }
 endResetModel(); emit countChanged();
}

bool NativeFileModel::refreshSourceRow(int sourceRow)
{
 const QVariantList oneRow{sourceRow};
 return refreshSourceRows(oneRow) > 0;
}

int NativeFileModel::refreshSourceRows(const QVariantList& sourceRows)
{
 static const QList<int> roles = {
  MimeTypeRole, MimeStatusRole, DurationSecsRole, CodecRole,
  VideoCodecRole, AudioCodecRole, BitrateRole, FpsRole,
  MediaWidthRole, MediaHeightRole, MediaStatusRole
 };
 const auto names = roleNames();
 int changedRows = 0;
 int firstVisible = m_rows.size();
 int lastVisible = -1;
 for (const QVariant& sourceValue : sourceRows) {
  const int sourceRow = sourceValue.toInt();
  const auto found = m_sourceToVisibleRow.constFind(sourceRow);
  if (found == m_sourceToVisibleRow.constEnd()) {
   continue;
  }
  const int visibleRow = found.value();
  if (visibleRow < 0 || visibleRow >= m_rows.size()) {
   continue;
  }
  const QVariantMap fresh = readRow(sourceRow);
  bool changed = false;
  for (const int role : roles) {
   const QString key = QString::fromUtf8(names.value(role));
   const QVariant value = fresh.value(key);
   if (m_rows[visibleRow].value(key) != value) {
    m_rows[visibleRow][key] = value;
    changed = true;
   }
  }
  if (changed) {
   ++changedRows;
   firstVisible = qMin(firstVisible, visibleRow);
   lastVisible = qMax(lastVisible, visibleRow);
  }
 }
 if (changedRows > 0) {
  emit dataChanged(index(firstVisible), index(lastVisible), roles);
 }
 return changedRows;
}
QVariantMap NativeFileModel::get(int r) const{return r>=0&&r<m_rows.size()?m_rows[r]:QVariantMap{};}
void NativeFileModel::setProperty(int r,const QString&role,const QVariant&v){if(r<0||r>=m_rows.size()||m_rows[r].value(role)==v)return;m_rows[r][role]=v;auto names=roleNames();int found=-1;for(auto it=names.begin();it!=names.end();++it)if(QString::fromUtf8(it.value())==role){found=it.key();break;}emit dataChanged(index(r),index(r),found<0?QList<int>{}:QList<int>{found});}
void registerNativeFileModel()
{
    static const int typeId = qmlRegisterType<NativeFileModel>(
        "dk.john.folderbrowser.native", 1, 0, "NativeFileModel");
    Q_UNUSED(typeId);
}

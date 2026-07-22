#pragma once

#include <QAbstractListModel>
#include <QPointer>
#include <QVariantMap>
#include <QVariantList>
#include <QVector>

void registerNativeFileModel();

class NativeFileModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QObject* controller READ controller WRITE setController NOTIFY controllerChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY optionsChanged)
    Q_PROPERTY(bool familiesOnly READ familiesOnly WRITE setFamiliesOnly NOTIFY optionsChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY optionsChanged)
    Q_PROPERTY(QString sortColumn READ sortColumn WRITE setSortColumn NOTIFY optionsChanged)
    Q_PROPERTY(bool sortAscending READ sortAscending WRITE setSortAscending NOTIFY optionsChanged)
    Q_PROPERTY(bool foldersFirst READ foldersFirst WRITE setFoldersFirst NOTIFY optionsChanged)
    Q_PROPERTY(bool foldersAlwaysAZ READ foldersAlwaysAZ WRITE setFoldersAlwaysAZ NOTIFY optionsChanged)
public:
    enum Roles { NameRole=Qt::UserRole+1, FamilyDescriptorRole, KindRole, MimeTypeRole,
        MimeStatusRole, LiveStatusRole, SizeBytesRole, SizeStatusRole, ModifiedSecsRole,
        DurationSecsRole, CodecRole, VideoCodecRole, AudioCodecRole, BitrateRole, FpsRole,
        MediaWidthRole, MediaHeightRole, MediaStatusRole, PathRole, IsDirRole, IsParentEntryRole };
    explicit NativeFileModel(QObject* parent=nullptr);
    int rowCount(const QModelIndex& parent=QModelIndex()) const override;
    QVariant data(const QModelIndex& index,int role) const override;
    QHash<int,QByteArray> roleNames() const override;
    QObject* controller() const { return m_controller; }
    void setController(QObject* value);
    bool showHidden() const { return m_showHidden; } void setShowHidden(bool v);
    bool familiesOnly() const { return m_familiesOnly; } void setFamiliesOnly(bool v);
    QString filterText() const { return m_filterText; } void setFilterText(const QString& v);
    QString sortColumn() const { return m_sortColumn; } void setSortColumn(const QString& v);
    bool sortAscending() const { return m_sortAscending; } void setSortAscending(bool v);
    bool foldersFirst() const { return m_foldersFirst; } void setFoldersFirst(bool v);
    bool foldersAlwaysAZ() const { return m_foldersAlwaysAZ; } void setFoldersAlwaysAZ(bool v);
    Q_INVOKABLE void reload();
    Q_INVOKABLE bool refreshSourceRow(int sourceRow);
    Q_INVOKABLE int refreshSourceRows(const QVariantList& sourceRows);
    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE void setProperty(int row,const QString& role,const QVariant& value);
signals:
    void controllerChanged(); void countChanged(); void optionsChanged();
private:
    QVariant invoke(const char* method,int row) const;
    QVariantMap readRow(int sourceRow) const;
    QVariantMap parentRow() const;
    bool accepts(const QVariantMap& row) const;
    static int compare(const QVariantMap& a,const QVariantMap& b,const QString& column,
                       bool foldersFirst,bool foldersAlwaysAZ);
    QPointer<QObject> m_controller;
    QVector<QVariantMap> m_rows;
    QHash<int, int> m_sourceToVisibleRow;
    bool m_showHidden=false, m_familiesOnly=false, m_sortAscending=true,
         m_foldersFirst=true, m_foldersAlwaysAZ=true;
    QString m_filterText, m_sortColumn=QStringLiteral("name");
};

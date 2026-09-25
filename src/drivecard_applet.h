#pragma once
#include <Plasma/Applet>
#include <PlasmaQuick/AppletQuickItem>
#include <QPointer>
#include <QTimer>

namespace Solid {
    class StorageAccess;
}

class DriveCardApplet : public Plasma::Applet
{
    Q_OBJECT

    Q_PROPERTY(int driveCount READ driveCount WRITE setDriveCount NOTIFY driveCountChanged)
    Q_PROPERTY(bool suspended READ suspended NOTIFY suspendedChanged)

public:
    DriveCardApplet(QObject *parent, const KPluginMetaData &data, const QVariantList &args);

    void init() override;

    int  driveCount() const;
    void setDriveCount(int count);
    bool suspended() const;

    // Вызывается из QML: root.applet.setPreferredSize(w, h)
    // Напрямую меняет физический размер виджета через AppletQuickItem.
    Q_INVOKABLE void setPreferredSize(int width, int height);

    Q_INVOKABLE void reportResult(bool ok);

Q_SIGNALS:
    void driveCountChanged();
    void suspendedChanged();
    void deviceMounted();
    void deviceRemoved();

private Q_SLOTS:
    void onDeviceAdded(const QString &udi);
    void onDeviceRemoved(const QString &udi);
    void tryResume();

private:
    void startSolidWatcher();
    void enterFallbackMode();

    int  m_driveCount  = 0;
    int  m_errorCount  = 0;
    bool m_suspended   = false;
    bool m_useFallback = false;
    bool m_initialized = false;

    QTimer *m_debounceTimer = nullptr;
    QTimer *m_fallbackTimer = nullptr;

    static constexpr int kMaxErrors  = 5;
    static constexpr int kDebounceMs = 500;
    static constexpr int kFallbackMs = 2000;
    static constexpr int kResumeMs   = 30000;
};

#pragma once
#include <Plasma/Applet>
#include <QPointer>
#include <QTimer>

namespace Solid {
    class StorageAccess;
}

class DriveCardApplet : public Plasma::Applet
{
    Q_OBJECT

    // QML пишет количество дисков, C++ хранит для будущего авторазмера
    Q_PROPERTY(int driveCount READ driveCount WRITE setDriveCount NOTIFY driveCountChanged)

    // QML читает чтобы показать/скрыть watchdog overlay
    Q_PROPERTY(bool suspended READ suspended NOTIFY suspendedChanged)

public:
    DriveCardApplet(QObject *parent, const KPluginMetaData &data, const QVariantList &args);

    // Shell вызывает после полной загрузки окружения.
    // Единственное безопасное место для подписок на Solid.
    void init() override;

    int  driveCount() const;
    void setDriveCount(int count);
    bool suspended() const;

    // Вызывается из QML: Plasmoid.nativeInterface.setPreferredSize(w, h)
    Q_INVOKABLE void setPreferredSize(int width, int height);

    // Вызывается из QML после каждого rebuild() — ok=true/false
    Q_INVOKABLE void reportResult(bool ok);

Q_SIGNALS:
    void driveCountChanged();
    void suspendedChanged();
    void deviceMounted();   // QML: запустить refresh(0)
    void deviceRemoved();   // QML: запустить refresh(0)

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
    bool m_initialized = false;  // guard для reportResult до init()

    QTimer *m_debounceTimer = nullptr;
    QTimer *m_fallbackTimer = nullptr;

    static constexpr int kMaxErrors  = 5;
    static constexpr int kDebounceMs = 500;
    static constexpr int kFallbackMs = 2000;
    static constexpr int kResumeMs   = 30000;
};

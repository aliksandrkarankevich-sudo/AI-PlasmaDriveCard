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

    // Количество дисков — QML пишет, C++ читает для авторазмера
    Q_PROPERTY(int driveCount READ driveCount WRITE setDriveCount NOTIFY driveCountChanged)

    // QML читает это свойство чтобы показать/скрыть предупреждение
    Q_PROPERTY(bool suspended READ suspended NOTIFY suspendedChanged)

public:
    DriveCardApplet(QObject *parent, const KPluginMetaData &data, const QVariantList &args);

    // Вызывается Shell после полной загрузки окружения — безопасное место
    // для подписок на Solid. НЕ делаем это в конструкторе.
    void init() override;

    int  driveCount() const;
    void setDriveCount(int count);
    bool suspended() const;

    // Вызывается из QML: Plasmoid.nativeInterface.setPreferredSize(w, h)
    Q_INVOKABLE void setPreferredSize(int width, int height);

    // Вызывается из QML когда reload() завершился успешно/с ошибкой
    Q_INVOKABLE void reportResult(bool ok);

Q_SIGNALS:
    void driveCountChanged();
    void suspendedChanged();

    // QML подключается к этим сигналам вместо hotplugPoll таймера
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

    // Debounce: один reload после серии событий вместо N подряд
    QTimer *m_debounceTimer  = nullptr;
    // Fallback-таймер когда Solid недоступен
    QTimer *m_fallbackTimer  = nullptr;

    static constexpr int kMaxErrors    = 5;
    static constexpr int kDebounceMs   = 500;
    static constexpr int kFallbackMs   = 2000;
    static constexpr int kResumeMs     = 30000;
};

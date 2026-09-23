#include "drivecard_applet.h"
#include <KPluginFactory>
#include <Solid/DeviceNotifier>
#include <Solid/Device>
#include <Solid/StorageAccess>

// Путь передаётся через -DPLUGIN_METADATA_FILE из CMakeLists.txt
// чтобы он был абсолютным и не зависел от рабочей директории сборки
K_PLUGIN_CLASS_WITH_JSON(DriveCardApplet, PLUGIN_METADATA_FILE)

// ─────────────────────────────────────────────────────────────────────────────
// Конструктор: только инициализация базового класса.
// Shell может вызвать конструктор до готовности D-Bus/UDisks2.
// ─────────────────────────────────────────────────────────────────────────────
DriveCardApplet::DriveCardApplet(QObject *parent,
                                 const KPluginMetaData &data,
                                 const QVariantList &args)
    : Plasma::Applet(parent, data, args)
{
}

// ─────────────────────────────────────────────────────────────────────────────
// init() — вызывается Shell после полной загрузки рабочего стола.
// Здесь безопасно подписываться на Solid и создавать таймеры.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::init()
{
    Plasma::Applet::init();
    m_initialized = true;

    m_debounceTimer = new QTimer(this);
    m_debounceTimer->setSingleShot(true);
    m_debounceTimer->setInterval(kDebounceMs);
    // По истечении debounce — сигнал QML: нужен reload
    connect(m_debounceTimer, &QTimer::timeout,
            this, &DriveCardApplet::deviceMounted);

    startSolidWatcher();
}

// ─────────────────────────────────────────────────────────────────────────────
// Подписка на Solid. Если DeviceNotifier == nullptr — входим в fallback.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::startSolidWatcher()
{
    auto *notifier = Solid::DeviceNotifier::instance();
    if (!notifier) {
        enterFallbackMode();
        return;
    }
    connect(notifier, &Solid::DeviceNotifier::deviceAdded,
            this, &DriveCardApplet::onDeviceAdded);
    connect(notifier, &Solid::DeviceNotifier::deviceRemoved,
            this, &DriveCardApplet::onDeviceRemoved);
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback: Solid недоступен — таймер каждые 2 с имитирует hotplug-опрос.
// Таймер НЕ запускается сразу (no start) — QML сам делает первый refresh
// через Component.onCompleted. Первый тик через 2 с — не лишний reload.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::enterFallbackMode()
{
    m_useFallback = true;
    m_fallbackTimer = new QTimer(this);
    m_fallbackTimer->setInterval(kFallbackMs);
    connect(m_fallbackTimer, &QTimer::timeout,
            this, &DriveCardApplet::deviceMounted);
    // Запуск с задержкой — даём QML завершить первый rebuild
    QTimer::singleShot(kFallbackMs, m_fallbackTimer,
                       qOverload<>(&QTimer::start));
}

// ─────────────────────────────────────────────────────────────────────────────
// Устройство появилось (udev). Монтирование ещё не произошло.
// Подписываемся на accessibilityChanged именно этого устройства.
//
// ИСПРАВЛЕНО: Qt::SingleShotConnection — соединение удаляется автоматически
// после первого срабатывания. Без этого каждое подключение USB создавало
// новое висящее соединение (утечка).
//
// QPointer защищает от dangling pointer при быстром отключении устройства
// до момента монтирования.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::onDeviceAdded(const QString &udi)
{
    Solid::Device device(udi);
    auto *access = device.as<Solid::StorageAccess>();
    if (!access) return;

    QPointer<Solid::StorageAccess> safeAccess = access;

    connect(access, &Solid::StorageAccess::accessibilityChanged,
            this, [this, safeAccess](bool accessible, const QString &) {
                if (!safeAccess) return;
                if (accessible)
                    m_debounceTimer->start();
            },
            Qt::SingleShotConnection);  // ← устраняет утечку соединений
}

// ─────────────────────────────────────────────────────────────────────────────
// Устройство отключено — немедленный сигнал QML без debounce.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::onDeviceRemoved(const QString &)
{
    Q_EMIT deviceRemoved();
}

// ─────────────────────────────────────────────────────────────────────────────
// Авторазмер: QML сообщает размер после каждого изменения drives.count.
// Сохраняем в конфиг — Shell читает при следующей отрисовке виджета.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::setPreferredSize(int width, int height)
{
    if (m_suspended) return;
    config().writeEntry("preferredWidth",  width);
    config().writeEntry("preferredHeight", height);
    Q_EMIT configNeedsSaving();
}

// ─────────────────────────────────────────────────────────────────────────────
// Watchdog: считает ошибки rebuild(). 5 подряд → приостановка на 30 с.
// ИСПРАВЛЕНО: guard m_initialized — QML не может вызвать это до init().
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::reportResult(bool ok)
{
    if (!m_initialized) return;  // защита от вызова до init()

    if (ok) {
        m_errorCount = 0;
        return;
    }
    if (m_suspended) return;

    if (++m_errorCount >= kMaxErrors) {
        m_suspended = true;
        Q_EMIT suspendedChanged();
        QTimer::singleShot(kResumeMs, this, &DriveCardApplet::tryResume);
    }
}

void DriveCardApplet::tryResume()
{
    m_suspended  = false;
    m_errorCount = 0;
    Q_EMIT suspendedChanged();
    Q_EMIT deviceMounted(); // один пробный reload
}

// ─────────────────────────────────────────────────────────────────────────────
int  DriveCardApplet::driveCount() const { return m_driveCount; }
bool DriveCardApplet::suspended()  const { return m_suspended;  }

void DriveCardApplet::setDriveCount(int count)
{
    if (count == m_driveCount) return;
    m_driveCount = count;
    Q_EMIT driveCountChanged();
}

#include "drivecard_applet.moc"

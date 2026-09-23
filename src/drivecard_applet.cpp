#include "drivecard_applet.h"
#include <KPluginFactory>
#include <Solid/DeviceNotifier>
#include <Solid/Device>
#include <Solid/StorageAccess>

K_PLUGIN_CLASS_WITH_JSON(DriveCardApplet, "../package/metadata.json")

// ─────────────────────────────────────────────────────────────────────────────
// Конструктор: только базовая инициализация, без Solid.
// Shell может вызвать конструктор до того как D-Bus и UDisks2 готовы.
// ─────────────────────────────────────────────────────────────────────────────
DriveCardApplet::DriveCardApplet(QObject *parent,
                                 const KPluginMetaData &data,
                                 const QVariantList &args)
    : Plasma::Applet(parent, data, args)
{
}

// ─────────────────────────────────────────────────────────────────────────────
// init() — Shell вызывает этот метод после полной загрузки рабочего стола.
// Здесь безопасно подписываться на Solid и запускать таймеры.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::init()
{
    Plasma::Applet::init();

    // Инициализируем debounce-таймер один раз здесь
    m_debounceTimer = new QTimer(this);
    m_debounceTimer->setSingleShot(true);
    m_debounceTimer->setInterval(kDebounceMs);
    // Когда таймер срабатывает — сообщаем QML что нужен reload
    connect(m_debounceTimer, &QTimer::timeout,
            this, &DriveCardApplet::deviceMounted);

    startSolidWatcher();
}

// ─────────────────────────────────────────────────────────────────────────────
// Подписка на Solid. Если DeviceNotifier недоступен — fallback.
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
// Fallback: Solid недоступен — имитируем hotplug таймером каждые 2 с.
// QML увидит deviceMounted() и сделает reload как обычно.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::enterFallbackMode()
{
    m_useFallback = true;
    m_fallbackTimer = new QTimer(this);
    m_fallbackTimer->setInterval(kFallbackMs);
    connect(m_fallbackTimer, &QTimer::timeout,
            this, &DriveCardApplet::deviceMounted);
    m_fallbackTimer->start();
}

// ─────────────────────────────────────────────────────────────────────────────
// Устройство появилось в системе (udev-событие).
// Монтирование ещё не произошло — подписываемся на accessibilityChanged
// конкретно этого устройства и ждём mounted = true.
// QPointer защищает от dangling pointer если устройство исчезнет раньше
// чем успеет смонтироваться (быстрое подключение/отключение).
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::onDeviceAdded(const QString &udi)
{
    Solid::Device device(udi);
    auto *access = device.as<Solid::StorageAccess>();
    if (!access) return; // не файловая система — игнорируем

    QPointer<Solid::StorageAccess> safeAccess = access;

    connect(access, &Solid::StorageAccess::accessibilityChanged,
            this, [this, safeAccess](bool accessible, const QString &) {
                if (!safeAccess) return; // устройство уже удалено — безопасный выход
                if (accessible)
                    m_debounceTimer->start(); // перезапускает таймер при шторме событий
            });
}

// ─────────────────────────────────────────────────────────────────────────────
// Устройство отключено — сообщаем QML немедленно, без ожидания.
// Debounce здесь не нужен: отключение одно, не серия.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::onDeviceRemoved(const QString &)
{
    Q_EMIT deviceRemoved();
}

// ─────────────────────────────────────────────────────────────────────────────
// Авторазмер: QML сообщает свои текущие размеры после изменения drives.count.
// Сохраняем в конфиг — Shell читает его при следующей отрисовке.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::setPreferredSize(int width, int height)
{
    if (m_suspended) return;
    config().writeEntry("preferredWidth",  width);
    config().writeEntry("preferredHeight", height);
    Q_EMIT configNeedsSaving();
}

// ─────────────────────────────────────────────────────────────────────────────
// Watchdog: QML вызывает reportResult(true/false) после каждого reload.
// 5 ошибок подряд → suspended = true, QML показывает предупреждение.
// Через 30 с автоматически пробуем восстановиться.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::reportResult(bool ok)
{
    if (ok) {
        m_errorCount = 0;
        return;
    }
    if (m_suspended) return;

    ++m_errorCount;
    if (m_errorCount >= kMaxErrors) {
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
    // Один пробный reload — если снова упадёт, watchdog запустится заново
    Q_EMIT deviceMounted();
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

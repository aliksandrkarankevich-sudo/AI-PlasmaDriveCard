#include "drivecard_applet.h"
#include <KPluginFactory>
#include <Solid/DeviceNotifier>
#include <Solid/Device>
#include <Solid/StorageAccess>

K_PLUGIN_CLASS_WITH_JSON(DriveCardApplet, PLUGIN_METADATA_FILE)

DriveCardApplet::DriveCardApplet(QObject *parent,
                                 const KPluginMetaData &data,
                                 const QVariantList &args)
    : Plasma::Applet(parent, data, args)
{
}

void DriveCardApplet::init()
{
    Plasma::Applet::init();
    m_initialized = true;

    m_debounceTimer = new QTimer(this);
    m_debounceTimer->setSingleShot(true);
    m_debounceTimer->setInterval(kDebounceMs);
    connect(m_debounceTimer, &QTimer::timeout,
            this, &DriveCardApplet::deviceMounted);

    startSolidWatcher();
}

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

void DriveCardApplet::enterFallbackMode()
{
    m_useFallback = true;
    m_fallbackTimer = new QTimer(this);
    m_fallbackTimer->setInterval(kFallbackMs);
    connect(m_fallbackTimer, &QTimer::timeout,
            this, &DriveCardApplet::deviceMounted);
    QTimer::singleShot(kFallbackMs, m_fallbackTimer,
                       qOverload<>(&QTimer::start));
}

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
            Qt::SingleShotConnection);
}

void DriveCardApplet::onDeviceRemoved(const QString &)
{
    Q_EMIT deviceRemoved();
}

// ─────────────────────────────────────────────────────────────────────────────
// Авторазмер: напрямую меняем физический размер виджета через
// PlasmaQuick::AppletQuickItem. Работает и при увеличении и при уменьшении.
// item->setSize() обходит ограничение Desktop containment, который
// игнорирует Layout.preferredHeight при уменьшении.
// ─────────────────────────────────────────────────────────────────────────────
void DriveCardApplet::setPreferredSize(int width, int height)
{
    if (m_suspended) return;
    auto *item = PlasmaQuick::AppletQuickItem::itemForApplet(this);
    if (!item) return;
    item->setSize(QSizeF(width, height));
}

void DriveCardApplet::reportResult(bool ok)
{
    if (!m_initialized) return;

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
    Q_EMIT deviceMounted();
}

int  DriveCardApplet::driveCount() const { return m_driveCount; }
bool DriveCardApplet::suspended()  const { return m_suspended;  }

void DriveCardApplet::setDriveCount(int count)
{
    if (count == m_driveCount) return;
    m_driveCount = count;
    Q_EMIT driveCountChanged();
}

#include "drivecard_applet.moc"

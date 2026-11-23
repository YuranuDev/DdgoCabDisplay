#include "cablink.h"
#include "demosource.h"
#include <QUdpSocket>
#include <QNetworkInterface>
#include <QNetworkDatagram>
#include <QJsonDocument>
#include <QJsonObject>
#include <QHostInfo>

CabLink::CabLink(int port, QObject *parent)
    : QObject(parent), m_port(port)
{
    m_since.start();
    m_rx = new QUdpSocket(this);
    if (!m_rx->bind(QHostAddress::AnyIPv4, quint16(port), QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
        m_error = QStringLiteral("UDP %1 を開けません: %2").arg(port).arg(m_rx->errorString());
        qWarning("%s", qPrintable(m_error));
    }
    connect(m_rx, &QUdpSocket::readyRead, this, &CabLink::readPending);

    m_tx = new QUdpSocket(this);
    m_tx->bind(QHostAddress::AnyIPv4, 0);

    connect(&m_hello, &QTimer::timeout, this, &CabLink::sendHello);
    m_hello.start(2000);
    QTimer::singleShot(200, this, &CabLink::sendHello);

    connect(&m_stale, &QTimer::timeout, this, &CabLink::checkStale);
    m_stale.start(250);
}

CabLink::~CabLink() = default;

void CabLink::setDemo(bool on)
{
    if (on == m_demo) return;
    m_demo = on;
    if (on) {
        if (!m_demoSrc) {
            m_demoSrc = new DemoSource(this);
            connect(m_demoSrc, &DemoSource::frame, this, [this](const QVariantMap &d) {
                if (m_demo) inject(d, QStringLiteral("デモ走行"));
            });
        }
        m_demoSrc->start();
    } else {
        if (m_demoSrc) m_demoSrc->stop();
        setOnline(false);
    }
    emit demoChanged();
}

void CabLink::inject(const QVariantMap &d, const QString &source)
{
    m_data = d;
    m_lastMs = m_since.elapsed();
    if (source != m_source) { m_source = source; emit sourceChanged(); }
    setOnline(true);
    ++m_countWindow;
    emit dataChanged();
}

void CabLink::readPending()
{
    while (m_rx->hasPendingDatagrams()) {
        QNetworkDatagram dg = m_rx->receiveDatagram(65536);
        QJsonParseError err{};
        auto doc = QJsonDocument::fromJson(dg.data(), &err);
        if (err.error != QJsonParseError::NoError || !doc.isObject()) continue;
        auto obj = doc.object();
        if (obj.contains(QStringLiteral("hello"))) continue;      // ほかの表示機の名乗り
        m_lastSender = dg.senderAddress();
        if (m_demo) continue;                                     // デモ中は実データを無視
        QString src = m_lastSender.toString();
        if (src.startsWith(QStringLiteral("::ffff:"))) src = src.mid(7);
        inject(obj.toVariantMap(), src);
    }
}

void CabLink::sendHello()
{
    QJsonObject o{
        {QStringLiteral("hello"), QStringLiteral("DdgoCabDisplay")},
        {QStringLiteral("name"), QHostInfo::localHostName()},
        {QStringLiteral("port"), m_port},
        {QStringLiteral("v"), 1},
    };
    const QByteArray msg = QJsonDocument(o).toJson(QJsonDocument::Compact);
    const quint16 dst = quint16(m_port + 1);
    QList<QHostAddress> targets{QHostAddress::Broadcast};
    for (const auto &iface : QNetworkInterface::allInterfaces()) {
        if (!(iface.flags() & QNetworkInterface::IsUp) || (iface.flags() & QNetworkInterface::IsLoopBack)) continue;
        for (const auto &e : iface.addressEntries())
            if (e.ip().protocol() == QAbstractSocket::IPv4Protocol && !e.broadcast().isNull() && !targets.contains(e.broadcast()))
                targets << e.broadcast();
    }
    if (!m_lastSender.isNull()) targets << m_lastSender;   // 一度届いた相手には直接も送る
    for (const auto &t : targets) m_tx->writeDatagram(msg, t, dst);
}

void CabLink::checkStale()
{
    const qint64 now = m_since.elapsed();
    if (!m_demo && now - m_lastMs > 1500) setOnline(false);
    if (now - m_rateMs >= 1000) {
        double r = m_countWindow * 1000.0 / qMax<qint64>(1, now - m_rateMs);
        m_countWindow = 0; m_rateMs = now;
        if (qAbs(r - m_rate) > 0.05) { m_rate = r; emit rateChanged(); }
    }
}

void CabLink::setOnline(bool on)
{
    if (on == m_online) return;
    m_online = on;
    emit onlineChanged();
}

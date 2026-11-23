#pragma once
#include <QObject>
#include <QVariantMap>
#include <QHostAddress>
#include <QElapsedTimer>
#include <QTimer>

class QUdpSocket;
class DemoSource;

// DdgoMascon (Windows / C#) から UDP の JSON を受け取って QML に渡す。
//  ・受信: ポート 24680 (既定)。1 パケット = 1 JSON オブジェクト (CabLinkSender が送る形)
//  ・名乗り: 2 秒ごとに {"hello":"DdgoCabDisplay","name":..,"port":..} を ポート+1 へブロードキャスト。
//    DdgoMascon はこれで表示機を見つけて送り始めるので、IP の設定はいらない。
class CabLink : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap d READ data NOTIFY dataChanged)
    Q_PROPERTY(bool online READ online NOTIFY onlineChanged)
    Q_PROPERTY(QString source READ source NOTIFY sourceChanged)
    Q_PROPERTY(double rate READ rate NOTIFY rateChanged)
    Q_PROPERTY(int port READ port CONSTANT)
    Q_PROPERTY(bool demo READ demo WRITE setDemo NOTIFY demoChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
public:
    explicit CabLink(int port, QObject *parent = nullptr);
    ~CabLink() override;

    QVariantMap data() const { return m_data; }
    bool online() const { return m_online; }
    QString source() const { return m_source; }
    double rate() const { return m_rate; }
    int port() const { return m_port; }
    bool demo() const { return m_demo; }
    void setDemo(bool on);
    QString lastError() const { return m_error; }

    // デモ (または外部) からの値の差し込み
    void inject(const QVariantMap &d, const QString &source);

signals:
    void dataChanged();
    void onlineChanged();
    void sourceChanged();
    void rateChanged();
    void demoChanged();
    void lastErrorChanged();

private:
    void readPending();
    void sendHello();
    void checkStale();
    void setOnline(bool on);

    QUdpSocket *m_rx = nullptr;
    QUdpSocket *m_tx = nullptr;
    DemoSource *m_demoSrc = nullptr;
    QTimer m_hello, m_stale;
    QElapsedTimer m_since;
    qint64 m_lastMs = -100000;
    int m_port;
    bool m_online = false;
    bool m_demo = false;
    QVariantMap m_data;
    QString m_source;
    QString m_error;
    QHostAddress m_lastSender;
    int m_countWindow = 0;
    qint64 m_rateMs = 0;
    double m_rate = 0;
};

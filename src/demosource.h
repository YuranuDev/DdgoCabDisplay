#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantMap>

// 受信が無くても画面を確かめられるよう、駅間を走って止まる列車をまねて
// DdgoMascon と同じ形の値を作る。
class DemoSource : public QObject
{
    Q_OBJECT
public:
    explicit DemoSource(QObject *parent = nullptr);
    void start();
    void stop();
    void fastForward(double sec);   // 画像検証用: 指定秒だけ一気に進める
signals:
    void frame(const QVariantMap &d);
private:
    void step(double dt);
    QVariantMap build() const;

    QTimer m_timer;
    double m_t = 0;
    double m_x = 0;        // 位置 (m)
    double m_v = 0;        // 速度 (km/h)
    double m_acc = 0;      // 加速度 (km/h/s)
    int m_p = 0, m_b = 0;  // ノッチ
    int m_station = 0;     // 次に止まる駅
    double m_dwell = 6;    // 停車の残り秒
    double m_bc = 300, m_mr = 840;
    bool m_cp = false;
    qint64 m_seq = 0;
};

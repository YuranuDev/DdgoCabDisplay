#include "demosource.h"
#include <QDateTime>
#include <QVariantList>
#include <cmath>
#include <algorithm>

namespace {
struct Station { const char *name; double pos; };
const Station kStations[] = {
    {"新井口", 0}, {"梅卿", 1650}, {"尾羽原", 3300}, {"港前", 5150}, {"東浜", 6900},
};
constexpr int kCount = int(sizeof(kStations) / sizeof(kStations[0]));
constexpr int kMaxP = 5, kMaxB = 8;
constexpr double kBcService = 440, kBcEmerg = 500;
double stationPos(int i) { return kStations[((i % kCount) + kCount) % kCount].pos + (i / kCount) * 8600.0; }
QString stationName(int i) { return QString::fromUtf8(kStations[((i % kCount) + kCount) % kCount].name); }
}

DemoSource::DemoSource(QObject *parent) : QObject(parent)
{
    m_timer.setInterval(33);
    connect(&m_timer, &QTimer::timeout, this, [this] { step(0.033); emit frame(build()); });
}

void DemoSource::start() { m_timer.start(); emit frame(build()); }
void DemoSource::stop() { m_timer.stop(); }

void DemoSource::fastForward(double sec)
{
    for (double s = 0; s < sec; s += 0.033) step(0.033);
    emit frame(build());
}

void DemoSource::step(double dt)
{
    m_t += dt;
    const double target = stationPos(m_station);
    const double dist = target - m_x;               // 停止位置まで (m)
    const double limit = dist < 300 ? 60 : 90;

    if (m_dwell > 0) {                              // 停車中
        m_dwell -= dt;
        m_p = 0; m_b = 4;
        if (m_dwell <= 0) { m_station++; m_b = 0; }
    } else {
        const double vms = m_v / 3.6;
        const double brakeDecel = 3.0 / 3.6;        // B5 程度で 3 km/h/s
        const double need = vms * vms / (2 * brakeDecel) + 8;
        if (dist <= need && m_v > 0.5) {
            // 止まるのに要る減速度からブレーキ段を決める(最後は少し緩める)
            double req = vms * vms / std::max(1.0, 2 * (dist - 1.0)) * 3.6;   // km/h/s
            int b = int(std::ceil(req / 4.2 * kMaxB));
            if (m_v < 8 && dist < 6) b = std::min(b, 3);
            m_b = std::clamp(b, 1, kMaxB - 1); m_p = 0;
        } else if (m_v < limit - 12) { m_p = m_v < 30 ? 5 : 4; m_b = 0; }
        else if (m_v > limit + 1) { m_p = 0; m_b = 2; }
        else { m_p = 0; m_b = 0; }                  // 惰行
        if (dist < 0.4 && m_v < 0.6) { m_v = 0; m_dwell = 10; m_x = target - 0.2; }
    }

    // 運動
    double a = 0;
    if (m_p > 0) a = 3.0 * m_p / kMaxP * std::clamp(1.25 - m_v / 110.0, 0.15, 1.0);
    a -= 4.2 * m_b / kMaxB * (m_v > 0.1 ? 1 : 0);
    a -= 0.08 + m_v * m_v * 0.00003;                 // 走行抵抗
    if (m_v <= 0 && a < 0) a = 0;
    m_acc += (a - m_acc) * std::min(1.0, dt / 0.4);
    m_v = std::max(0.0, m_v + a * dt);
    m_x += m_v / 3.6 * dt;

    // 空気
    double bcTarget = m_b > kMaxB ? kBcEmerg : kBcService * m_b / kMaxB * (m_v > 12 ? 0.35 : 1.0);
    double prev = m_bc;
    m_bc += (bcTarget - m_bc) * std::min(1.0, dt / 0.5);
    if (m_bc > prev) m_mr -= (m_bc - prev) * 0.25;
    m_mr -= 0.4 * dt;
    if (m_mr < 780) m_cp = true;
    if (m_mr > 880) m_cp = false;
    if (m_cp) m_mr += 9 * dt;
}

QVariantMap DemoSource::build() const
{
    const double target = stationPos(m_station);
    const double dist = target - m_x;
    const bool stopped = m_dwell > 0;
    const double regenShare = (m_b > 0 && m_v > 8) ? 0.85 : 0.0;
    double current = 0;
    if (m_p > 0) current = 520.0 * m_p / kMaxP * std::clamp(1.3 - m_v / 120.0, 0.25, 1.0);
    if (regenShare > 0) current = -380.0 * m_b / kMaxB * std::clamp(m_v / 40.0, 0.2, 1.0);

    QVariantMap notch{
        {"p", m_p}, {"b", m_b}, {"maxP", kMaxP}, {"maxB", kMaxB},
        {"sentP", m_p}, {"sentB", m_b}, {"pending", 0},
        {"name", m_b > 0 ? QStringLiteral("B%1").arg(m_b) : m_p > 0 ? QStringLiteral("P%1").arg(m_p) : QStringLiteral("N")},
        {"rev", 1},
    };
    QVariantList ahead;
    for (int i = m_station - 1; i <= m_station + 2; ++i) {
        if (i < 0) continue;
        ahead << QVariantMap{{"kind", "station"}, {"label", stationName(i)}, {"dist", std::round((stationPos(i) - m_x) * 10) / 10}};
    }
    const double swPos = stationPos(m_station) - 420;
    if (swPos - m_x > -150)
        ahead << QVariantMap{{"kind", "switch"}, {"label", "straight"}, {"dist", std::round((swPos - m_x) * 10) / 10}};

    QVariantMap d{
        {"v", 1}, {"seq", m_seq}, {"t", QDateTime::currentMSecsSinceEpoch()},
        {"connected", true}, {"output", true}, {"rx", true},
        {"speed", std::round(m_v * 100) / 100}, {"speedMax", 120}, {"limit", dist < 300 && !stopped ? 60 : 90},
        {"accel", std::round(m_acc * 100) / 100},
        {"notch", notch},
        {"bc", std::round(m_bc * 10) / 10}, {"mr", std::round(m_mr * 10) / 10}, {"bcTarget", 0},
        {"bcService", kBcService}, {"bcEmergency", kBcEmerg}, {"mrMin", 780}, {"mrMax", 880},
        {"current", std::round(current)}, {"currentMax", 600},
        {"volt", std::round(1500 - current * 1500 * 0.00017)}, {"voltNominal", 1500},
        {"regen", regenShare},
        {"mode", m_p > 0 ? "力行" : regenShare > 0 ? "回生" : m_b > 0 ? "制動" : m_v > 0.5 ? "惰行" : "停止"},
        {"cp", m_cp}, {"emergency", false},
        {"train", "1024M 普通"}, {"cars", 6}, {"cab", "main"},
        {"line", "本線"},
        {"next", stationName(m_station)}, {"prev", stationName(m_station - 1)},
        {"nextDist", std::round(std::max(0.0, dist))},
        {"stop", QVariantMap{{"station", stationName(m_station)}, {"marker", "6両"}, {"dist", std::round(dist * 100) / 100}, {"tol", 0.5}}},
        {"ahead", ahead},
    };
    if (stopped) d["at"] = stationName(m_station);
    if (swPos - m_x > 0 && swPos - m_x < 900)
        d["switch"] = QVariantMap{{"dist", std::round(swPos - m_x)}, {"way", "直進"}, {"conflict", false}};
    return d;
}

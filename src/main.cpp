// DdgoCabDisplay — DdgoMascon の外部表示 (Linux / Raspberry Pi 向け Qt6 + QML)
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QCommandLineParser>
#include <QSettings>
#include <QTimer>
#include <QFont>
#include <QFontDatabase>
#include "cablink.h"
#include "demosource.h"

// QML から設定を読み書きする小さな入れ物 (~/.config/DdgoMascon/DdgoCabDisplay.conf)
class Prefs : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;
    Q_INVOKABLE QVariant get(const QString &key, const QVariant &def = {}) const { return m_s.value(key, def); }
    Q_INVOKABLE void set(const QString &key, const QVariant &v) { m_s.setValue(key, v); }
private:
    QSettings m_s{QStringLiteral("DdgoMascon"), QStringLiteral("DdgoCabDisplay")};
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("DdgoCabDisplay"));
    app.setOrganizationName(QStringLiteral("DdgoMascon"));

    QCommandLineParser cli;
    cli.setApplicationDescription(QStringLiteral("DdgoMascon の外部表示"));
    cli.addHelpOption();
    QCommandLineOption portOpt({"p", "port"}, QStringLiteral("受信ポート (既定 24680)"), "port", "24680");
    QCommandLineOption themeOpt({"t", "theme"}, QStringLiteral("tims / glass / west / panel / simple"), "name");
    QCommandLineOption windowOpt({"w", "windowed"}, QStringLiteral("全画面にしない"));
    QCommandLineOption demoOpt({"d", "demo"}, QStringLiteral("受信なしでデモ走行を表示"));
    QCommandLineOption shotOpt("screenshot", QStringLiteral("画像を保存して終了 (検証用)"), "file");
    QCommandLineOption demoTimeOpt("demo-time", QStringLiteral("デモを指定秒進めてから表示 (--screenshot 用)"), "sec");
    QCommandLineOption shotDelayOpt("screenshot-delay", QStringLiteral("撮るまでの時間 (ms)"), "ms", "1800");
    QCommandLineOption sizeOpt("size", QStringLiteral("ウィンドウの大きさ WxH"), "WxH", "1600x900");
    QCommandLineOption pageOpt("page", QStringLiteral("最初に出す画面 (TIMS 風のみ: 0=運転情報 1=車両状態 2=運転記録 3=路線)"), "n", "0");
    cli.addOptions({portOpt, themeOpt, windowOpt, demoOpt, shotOpt, demoTimeOpt, shotDelayOpt, sizeOpt, pageOpt});
    cli.process(app);

    // フォント: 埋め込みの IBM Plex Sans JP を使う(Linux 側にフォントを入れなくてよい)
    QString family;
    for (const char *f : {":/fonts/IBMPlexSansJP-Regular.ttf", ":/fonts/IBMPlexSansJP-Bold.ttf"}) {
        const int id = QFontDatabase::addApplicationFont(QString::fromLatin1(f));
        if (id >= 0 && family.isEmpty()) family = QFontDatabase::applicationFontFamilies(id).value(0);
    }
    if (family.isEmpty()) {
        qWarning("埋め込みフォントを読めませんでした。システムのフォントを使います");
        for (const QString &fam : {QStringLiteral("Noto Sans CJK JP"), QStringLiteral("IPAexGothic")})
            if (QFontDatabase::families().contains(fam)) { family = fam; break; }
    }
    if (!family.isEmpty()) {
        QFont f(family);
        f.setHintingPreference(QFont::PreferVerticalHinting);
        qInfo("フォント: %s", qPrintable(family));
        app.setFont(f);
    }

    Prefs prefs;
    CabLink link(cli.value(portOpt).toInt());
    const bool shot = cli.isSet(shotOpt);
    if (cli.isSet(demoOpt) || prefs.get("demo", false).toBool()) link.setDemo(true);

    QString theme = cli.value(themeOpt);
    if (theme.isEmpty()) theme = prefs.get("theme", "tims").toString();
    const QStringList sz = cli.value(sizeOpt).split('x');

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("link", &link);
    engine.rootContext()->setContextProperty("prefs", &prefs);
    engine.rootContext()->setContextProperty("startTheme", theme);
    engine.rootContext()->setContextProperty("startPage", cli.value(pageOpt).toInt());
    engine.rootContext()->setContextProperty("startFullscreen", !cli.isSet(windowOpt) && !shot);
    engine.rootContext()->setContextProperty("startWidth", sz.value(0).toInt() > 0 ? sz.value(0).toInt() : 1600);
    engine.rootContext()->setContextProperty("startHeight", sz.value(1).toInt() > 0 ? sz.value(1).toInt() : 900);
    engine.rootContext()->setContextProperty("screenshotMode", shot);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    if (engine.rootObjects().isEmpty()) return 1;

    if (shot) {
        // デモを進めてから、描画が落ち着くのを待って保存
        // --demo-time があればデモを進めて撮る。無ければ実際の受信を待って撮る(通信の確認用)
        if (cli.isSet(demoTimeOpt)) {
            link.setDemo(true);
            if (auto *demo = link.findChild<DemoSource *>()) { demo->stop(); demo->fastForward(cli.value(demoTimeOpt).toDouble()); if (cli.isSet(shotDelayOpt)) demo->start(); }
        }
        auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        const QString file = cli.value(shotOpt);
        QTimer::singleShot(qMax(500, cli.value(shotDelayOpt).toInt()), &app, [win, file] {
            win->grabWindow().save(file);
            QCoreApplication::quit();
        });
    }
    return app.exec();
}

#include "main.moc"

import QtQuick
import QtQuick.Window
import "parts"
import "parts/Util.js" as U

// DdgoCabDisplay: 見やすさと操作しやすさを優先した表示。
// キーボードが無くても、右上の「メニュー」から全部の設定と操作ができる。
Window {
    id: win
    width: startWidth
    height: startHeight
    visible: true
    color: Pal.bg
    title: "DdgoCabDisplay"
    visibility: startFullscreen ? Window.FullScreen : Window.Windowed

    property string layout: startLayout === "gauges" ? "gauges" : "standard"
    property bool menuOpen: startMenu
    readonly property bool full: visibility === Window.FullScreen
    readonly property var d: link.d
    readonly property var n: d.notch || ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    readonly property real speed: Math.abs(U.num(d.speed))
    readonly property bool over: U.has(d.limit) && speed > d.limit + 0.5
    readonly property real stopDist: d.stop ? U.num(d.stop.dist, NaN) : NaN

    Component.onCompleted: {
        Pal.scheme = startPalette === "light" ? "light" : "dark";
        Pal.textSize = startTextSize === "large" ? "large" : "normal";
    }

    function setScheme(s) { Pal.scheme = s; prefs.set("palette", s); }
    function setTextSize(s) { Pal.textSize = s; prefs.set("text", s); }
    function setLayout(l) { layout = l; prefs.set("layout", l); }
    function setFull(f) { visibility = f ? Window.FullScreen : Window.Windowed; prefs.set("fullscreen", f); }
    function setDemo(on) { link.demo = on; prefs.set("demo", on); }

    // 設定画面の 1 行: 左に名前と説明、右に操作
    component SettingRow: Item {
        id: sr
        property string label: ""
        property string help: ""
        default property alias control: holder.data
        width: parent ? parent.width : 0; height: 84
        Column {
            anchors.verticalCenter: parent.verticalCenter; width: 300
            Text { text: sr.label; color: Pal.text; font.pixelSize: 22 * Pal.ts; font.weight: Font.DemiBold }
            Text { visible: sr.help.length > 0; width: parent.width; wrapMode: Text.Wrap; text: sr.help; color: Pal.sub; font.pixelSize: 15 * Pal.ts }
        }
        Item { id: holder; x: 320; width: parent.width - 320; height: parent.height }
    }


    // ---- 注意 (優先度の高い順に 1 つだけ上の帯に出す) ----
    readonly property var alert: {
        if (!link.online && !link.demo) return { t: "受信を待っています", c: Pal.yellow };
        if (d.emergency) return { t: "非常ブレーキ", c: Pal.red };
        if (over) return { t: "速度超過  制限 " + Math.round(d.limit) + " km/h", c: Pal.red };
        if (d.switch && d.switch.conflict) return { t: "分岐の開通方向に注意", c: Pal.red };
        if (!isNaN(stopDist) && stopDist < -0.5 && stopDist > -30) return { t: "停止位置を " + Math.abs(stopDist).toFixed(1) + " m 行き過ぎ", c: Pal.red };
        if (d.connected === false) return { t: "マスコン未接続", c: Pal.yellow };
        if (d.output === false) return { t: "キー出力がオフ", c: Pal.yellow };
        return null;
    }

    // 1600×900 の配置を、画面に合わせて縦横比を保ったまま拡大縮小する
    Item {
        id: stage
        width: 1600; height: 900
        anchors.centerIn: parent
        scale: Math.min(win.width / width, win.height / height)

        // ================= 上の帯 =================
        Item {
            id: header
            x: 24; y: 12; width: 1552; height: 64
            Column {
                anchors.verticalCenter: parent.verticalCenter; width: 420
                Text { width: parent.width; elide: Text.ElideRight; text: U.str(d.line, "DdgoCabDisplay"); color: Pal.text; font.pixelSize: 22 * Pal.ts; font.weight: Font.DemiBold }
                Text { width: parent.width; elide: Text.ElideRight; text: U.str(d.train, "") + (d.cars ? "  ·  " + d.cars + "両" : ""); color: Pal.sub; font.pixelSize: 16 * Pal.ts }
            }
            // 中央: 注意があれば注意、無ければ次の駅
            Rectangle {
                visible: win.alert !== null
                anchors.centerIn: parent; height: 52; width: at.implicitWidth + 64; radius: 26
                color: win.alert ? Qt.rgba(win.alert.c.r, win.alert.c.g, win.alert.c.b, Pal.dark ? 0.2 : 0.14) : "transparent"
                border.color: win.alert ? win.alert.c : "transparent"; border.width: 2
                Rectangle { x: 22; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: win.alert ? win.alert.c : "transparent" }
                Text { id: at; x: 44; anchors.verticalCenter: parent.verticalCenter; text: win.alert ? win.alert.t : ""; color: Pal.text; font.pixelSize: 22 * Pal.ts; font.weight: Font.DemiBold }
            }
            Row {
                visible: win.alert === null
                anchors.centerIn: parent; spacing: 12
                Text { text: d.at ? "停車中" : "次"; color: Pal.sub; font.pixelSize: 19 * Pal.ts; anchors.baseline: ns.baseline }
                Text { id: ns; text: U.str(d.at || d.next); color: Pal.text; font.pixelSize: 28 * Pal.ts; font.weight: Font.DemiBold }
                Text { text: d.at ? "" : U.dist(d.nextDist); color: Pal.blue; font.pixelSize: 20 * Pal.ts; anchors.baseline: ns.baseline }
            }
            Row {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 20
                Clock { anchors.verticalCenter: parent.verticalCenter; color: Pal.text; font.pixelSize: 28 * Pal.ts; font.weight: Font.DemiBold; seconds: false }
                TouchButton {
                    width: 150; height: 56; text: "≡  メニュー"
                    onClicked: win.menuOpen = true
                }
            }
        }

        // ================= 本体 =================
        Loader {
            id: page
            x: 24; y: 88; width: 1552; height: 796
            source: win.layout === "gauges" ? "views/Gauges.qml" : "views/Standard.qml"
        }

        // ================= 受信待ち =================
        Rectangle {
            visible: !link.online && !link.demo && !win.menuOpen
            anchors.fill: parent
            color: Qt.rgba(Pal.bg.r, Pal.bg.g, Pal.bg.b, 0.78)
            MouseArea { anchors.fill: parent }
            Card {
                anchors.centerIn: parent; width: 900; height: 400
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter; y: 40; spacing: 16; width: 800
                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "DdgoMascon からの受信を待っています"; color: Pal.text; font.pixelSize: 32 * Pal.ts; font.weight: Font.DemiBold }
                    Text {
                        width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; color: Pal.sub; font.pixelSize: 20 * Pal.ts; lineHeight: 1.3
                        text: link.lastError.length ? link.lastError
                              : "DdgoMascon の設定「外部表示 (Linux)」で送信をオンにすると、同じネットワークなら自動でつながります。"
                    }
                    Text {
                        width: parent.width; horizontalAlignment: Text.AlignHCenter; color: Pal.sub; font.pixelSize: 18 * Pal.ts
                        text: "この表示機: " + link.hostName + "   " + link.addresses.join(" / ") + "   受信ポート " + link.port
                    }
                    Item { width: 1; height: 24 }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 20
                        TouchButton { width: 300; height: 84; text: "デモ走行を見る"; sub: "受信なしで画面を確かめる"; onClicked: win.setDemo(true) }
                        TouchButton { width: 300; height: 84; text: "メニュー"; sub: "表示・通信の設定"; onClicked: win.menuOpen = true }
                    }
                }
            }
        }

        // ================= メニュー (設定) =================
        Rectangle {
            visible: win.menuOpen
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, Pal.dark ? 0.6 : 0.35)
            MouseArea { anchors.fill: parent; onClicked: win.menuOpen = false }
            Card {
                id: sheet
                anchors.centerIn: parent; width: 1260; height: 820
                MouseArea { anchors.fill: parent }
                property bool confirmQuit: false
                onVisibleChanged: confirmQuit = false
                Text { x: 36; y: 26; text: "メニュー"; color: Pal.text; font.pixelSize: 32 * Pal.ts; font.weight: Font.DemiBold }
                TouchButton { x: sheet.width - 236; y: 20; width: 200; height: 60; text: "閉じる"; checked: true; onClicked: win.menuOpen = false }

                Column {
                    x: 36; y: 104; width: sheet.width - 72; spacing: 14
                    SettingRow {
                        label: "配色"; help: "暗い部屋や夜は「暗い」"
                        Segmented {
                            anchors.verticalCenter: parent.verticalCenter; itemWidth: 260
                            options: [{ key: "dark", label: "暗い" }, { key: "light", label: "明るい" }]
                            current: Pal.scheme; onPicked: function (k) { win.setScheme(k); }
                        }
                    }
                    SettingRow {
                        label: "並び"; help: "計器重視は速度計を大きく"
                        Segmented {
                            anchors.verticalCenter: parent.verticalCenter; itemWidth: 260
                            options: [{ key: "standard", label: "標準", sub: "情報と計器を両方" }, { key: "gauges", label: "計器重視", sub: "速度計が大きい" }]
                            current: win.layout; onPicked: function (k) { win.setLayout(k); }
                        }
                    }
                    SettingRow {
                        label: "文字の大きさ"
                        Segmented {
                            anchors.verticalCenter: parent.verticalCenter; itemWidth: 260
                            options: [{ key: "normal", label: "標準" }, { key: "large", label: "大きい" }]
                            current: Pal.textSize; onPicked: function (k) { win.setTextSize(k); }
                        }
                    }
                    SettingRow {
                        label: "画面"
                        Row {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 12
                            TouchButton { width: 260; height: 76; text: win.full ? "全画面: オン" : "全画面: オフ"; checked: win.full; onClicked: win.setFull(!win.full) }
                            TouchButton { width: 260; height: 76; text: link.demo ? "デモ走行: オン" : "デモ走行: オフ"; sub: "受信なしで画面を確認"; checked: link.demo; onClicked: win.setDemo(!link.demo) }
                        }
                    }
                    SettingRow {
                        label: "受信ポート"; help: "DdgoMascon の設定と同じ番号に"
                        Row {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 12
                            TouchButton { width: 110; height: 76; text: "−10"; onClicked: { link.port = link.port - 10; prefs.set("port", link.port); } }
                            TouchButton { width: 110; height: 76; text: "−1"; onClicked: { link.port = link.port - 1; prefs.set("port", link.port); } }
                            Rectangle {
                                width: 200; height: 76; radius: 14; color: Pal.bg; border.color: Pal.line
                                Text { anchors.centerIn: parent; text: link.port; color: Pal.text; font.pixelSize: 30 * Pal.ts; font.weight: Font.DemiBold }
                            }
                            TouchButton { width: 110; height: 76; text: "+1"; onClicked: { link.port = link.port + 1; prefs.set("port", link.port); } }
                            TouchButton { width: 110; height: 76; text: "+10"; onClicked: { link.port = link.port + 10; prefs.set("port", link.port); } }
                            TouchButton { width: 150; height: 76; text: "既定"; sub: "24680"; onClicked: { link.port = 24680; prefs.set("port", 24680); } }
                        }
                    }
                    SettingRow {
                        label: "接続の状態"
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 6
                            Row {
                                spacing: 10
                                Rectangle { width: 12; height: 12; radius: 6; anchors.verticalCenter: parent.verticalCenter; color: link.online ? Pal.green : Pal.mute }
                                Text { text: link.online ? "受信中: " + link.source + "  (" + link.rate.toFixed(0) + " 回/秒)" : "受信なし"; color: Pal.text; font.pixelSize: 20 * Pal.ts }
                            }
                            Text { text: "この表示機: " + link.hostName + "   " + (link.addresses.length ? link.addresses.join(" / ") : "ネットワーク未接続"); color: Pal.sub; font.pixelSize: 18 * Pal.ts }
                            Text { visible: link.lastError.length > 0; text: link.lastError; color: Pal.red; font.pixelSize: 18 * Pal.ts }
                        }
                    }
                }
                TouchButton {
                    x: 36; y: sheet.height - 104; width: 340; height: 76; danger: true
                    text: sheet.confirmQuit ? "もう一度押すと終了" : "アプリを終了"
                    checked: sheet.confirmQuit
                    onClicked: { if (sheet.confirmQuit) Qt.quit(); else sheet.confirmQuit = true; }
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 36; y: sheet.height - 80
                    text: "画面の外側をタップしても閉じます"; color: Pal.mute; font.pixelSize: 16 * Pal.ts
                }
            }
        }
    }

    // キーボードがあるときの近道 (無くても全部メニューから操作できる)
    Item {
        focus: true
        Keys.onPressed: function (e) {
            if (e.key === Qt.Key_F11) win.setFull(!win.full);
            else if (e.key === Qt.Key_M || e.key === Qt.Key_Tab) win.menuOpen = !win.menuOpen;
            else if (e.key === Qt.Key_Escape) { if (win.menuOpen) win.menuOpen = false; else if (win.full) win.setFull(false); }
            else if (e.key === Qt.Key_D) win.setDemo(!link.demo);
            else if (e.key === Qt.Key_Q && (e.modifiers & Qt.ControlModifier)) Qt.quit();
        }
    }
}

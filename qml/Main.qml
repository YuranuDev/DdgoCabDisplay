import QtQuick
import QtQuick.Window
import "parts/Util.js" as U

Window {
    id: win
    width: startWidth
    height: startHeight
    visible: true
    color: "black"
    title: "DdgoCabDisplay"
    visibility: startFullscreen ? Window.FullScreen : Window.Windowed

    readonly property var themes: [
        { key: "tims",  file: "Tims.qml",  name: "TIMS 風",            note: "JR東日本 E233 系などの運転台モニター" },
        { key: "glass", file: "Glass.qml", name: "グラスコックピット", note: "速度計も液晶 (E235 / 新幹線 E7 風)" },
        { key: "west",  file: "West.qml",  name: "私鉄・JR西 風",      note: "白地と紺の帯の表示 (225 系 / N700S 風)" },
        { key: "panel", file: "Panel.qml", name: "計器盤",             note: "DdgoMascon の別モニター表示と同じ並び" },
    ]
    property string theme: themes.some(function (t) { return t.key === startTheme; }) ? startTheme : "tims"
    property bool menuOpen: false

    function themeFile(k) { for (var i = 0; i < themes.length; i++) if (themes[i].key === k) return themes[i].file; return "Tims.qml"; }
    function setTheme(k) { theme = k; prefs.set("theme", k); }
    function toggleFull() { visibility = visibility === Window.FullScreen ? Window.Windowed : Window.FullScreen; }

    // 1600×900 の固定の配置を、画面に合わせて縦横比を保ったまま拡大縮小する
    Item {
        id: stage
        width: 1600; height: 900
        anchors.centerIn: parent
        scale: Math.min(win.width / width, win.height / height)

        Loader {
            id: page
            anchors.fill: parent
            source: "themes/" + win.themeFile(win.theme)
        }

        // ---- 受信なし ----
        Rectangle {
            visible: !link.online && !screenshotMode
            anchors.horizontalCenter: parent.horizontalCenter
            y: 360; width: 880; height: 180; radius: 10
            color: Qt.rgba(0, 0, 0, 0.82)
            border.color: "#ffb000"; border.width: 3
            Column {
                anchors.centerIn: parent; spacing: 10
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "DdgoMascon からの受信待ち"; color: "#ffb000"; font.pixelSize: 44; font.bold: true }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: link.lastError.length ? link.lastError
                          : "UDP " + link.port + " で待っています。DdgoMascon の「外部表示 (Linux)」で送信をオンにしてください"
                    color: "#ffffff"; font.pixelSize: 22
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "M キー / 右上をタップでメニュー(デモ走行・デザイン切替)"; color: "#9aa4ae"; font.pixelSize: 20 }
            }
        }

        // ---- メニュー ----
        Rectangle {
            id: menu
            visible: win.menuOpen
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.78)
            MouseArea { anchors.fill: parent; onClicked: win.menuOpen = false }
            Rectangle {
                anchors.centerIn: parent
                width: 1100; height: 700; radius: 12
                color: "#141a22"; border.color: "#3a4a5c"; border.width: 2
                MouseArea { anchors.fill: parent }
                Column {
                    anchors.fill: parent; anchors.margins: 36; spacing: 18
                    Text { text: "表示の設定"; color: "white"; font.pixelSize: 40; font.bold: true }
                    Grid {
                        columns: 2; spacing: 16
                        Repeater {
                            model: win.themes
                            Rectangle {
                                width: 506; height: 120; radius: 8
                                color: win.theme === modelData.key ? "#1f6fb5" : "#222b36"
                                border.color: win.theme === modelData.key ? "#7fc4ff" : "#3a4654"; border.width: 2
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter; x: 22; spacing: 6
                                    Text { text: (index + 1) + "  " + modelData.name; color: "white"; font.pixelSize: 32; font.bold: true }
                                    Text { text: modelData.note; color: "#c6d2de"; font.pixelSize: 20 }
                                }
                                MouseArea { anchors.fill: parent; onClicked: win.setTheme(modelData.key) }
                            }
                        }
                    }
                    Row {
                        spacing: 16
                        Repeater {
                            model: [
                                { label: link.demo ? "デモ走行: オン" : "デモ走行: オフ", act: function () { link.demo = !link.demo; prefs.set("demo", link.demo); } },
                                { label: win.visibility === Window.FullScreen ? "全画面を抜ける" : "全画面にする", act: function () { win.toggleFull(); } },
                                { label: "閉じる", act: function () { win.menuOpen = false; } },
                                { label: "終了", act: function () { Qt.quit(); } },
                            ]
                            Rectangle {
                                width: 245; height: 90; radius: 8; color: "#2a3542"; border.color: "#4c5d70"; border.width: 2
                                Text { anchors.centerIn: parent; text: modelData.label; color: "white"; font.pixelSize: 26; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: modelData.act() }
                            }
                        }
                    }
                    Text {
                        width: parent.width; wrapMode: Text.Wrap; color: "#9aa4ae"; font.pixelSize: 20
                        text: "受信: " + (link.online ? link.source + "  " + link.rate.toFixed(0) + " 回/秒" : "なし") + "   ポート " + link.port +
                              "\nキー: 1〜4 デザイン / D デモ / F11 全画面 / M メニュー / Esc 閉じる / Ctrl+Q 終了"
                    }
                }
            }
        }
    }

    // 右上の角をタップでメニュー(タッチパネル用)
    MouseArea {
        width: 120; height: 120; anchors.right: parent.right; anchors.top: parent.top
        visible: !win.menuOpen
        onClicked: win.menuOpen = true
    }

    Item {
        focus: true
        Keys.onPressed: function (e) {
            if (e.key >= Qt.Key_1 && e.key <= Qt.Key_4) win.setTheme(win.themes[e.key - Qt.Key_1].key);
            else if (e.key === Qt.Key_D) { link.demo = !link.demo; prefs.set("demo", link.demo); }
            else if (e.key === Qt.Key_F11 || e.key === Qt.Key_F) win.toggleFull();
            else if (e.key === Qt.Key_M || e.key === Qt.Key_Tab) win.menuOpen = !win.menuOpen;
            else if (e.key === Qt.Key_Escape) { if (win.menuOpen) win.menuOpen = false; else if (win.visibility === Window.FullScreen) win.visibility = Window.Windowed; }
            else if (e.key === Qt.Key_Q && (e.modifiers & Qt.ControlModifier)) Qt.quit();
            else if (page.item && page.item.key) page.item.key(e.key);
        }
    }
}

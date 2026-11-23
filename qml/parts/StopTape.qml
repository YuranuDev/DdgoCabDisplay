import QtQuick
import "Util.js" as U

// 停止位置までの距離の帯。中央が停止位置、左が手前(残り)、右が行き過ぎ
Item {
    id: t
    property real dist: NaN           // + 手前 / - 行き過ぎ (m)
    property real range: 10           // 帯の片側 (m)
    property real tol: 0.5
    property color bg: "#10161e"
    property color tickColor: "#7d8a99"
    property color okColor: "#2ee06a"
    property color nearColor: "#ffd23f"
    property color overColor: "#ff3b30"
    property color markerColor: "#ffffff"
    property real fontSize: 16
    property bool showLabels: true

    property real shown: isNaN(dist) ? range * 1.2 : dist
    Behavior on shown { NumberAnimation { duration: 140 } }
    onShownChanged: cv.requestPaint()
    onRangeChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()

    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            var c = getContext("2d"); c.reset();
            var w = width, h = height, lab = t.showLabels ? t.fontSize + 4 : 0;
            var bh = h - lab, mid = w / 2;
            c.fillStyle = t.bg; c.fillRect(0, 0, w, bh);
            // 許容範囲
            var px = w / 2 / t.range;
            c.fillStyle = Qt.rgba(0.18, 0.88, 0.42, 0.22);
            c.fillRect(mid - t.tol * px, 0, t.tol * 2 * px, bh);
            // 目盛
            c.fillStyle = t.tickColor; c.font = t.fontSize + "px '" + Qt.application.font.family + "'";
            c.textAlign = "center"; c.textBaseline = "top";
            for (var m = -t.range; m <= t.range + 1e-6; m += 1) {
                var x = mid - m * px;
                var major = Math.round(m) % 5 === 0;
                c.fillRect(x - 1, bh - (major ? bh * 0.45 : bh * 0.22), 2, major ? bh * 0.45 : bh * 0.22);
                if (major && t.showLabels) { c.textAlign = x < 12 ? "left" : x > w - 12 ? "right" : "center"; c.fillText(m === 0 ? "停止位置" : (m > 0 ? "手前 " : "過ぎ ") + Math.abs(m), x, bh + 2); }
            }
            c.fillStyle = t.markerColor; c.fillRect(mid - 2, 0, 4, bh);
            // 現在位置(先頭)
            if (!isNaN(t.dist) && Math.abs(t.shown) <= t.range * 1.05) {
                var d = t.shown, xx = mid - d * px;
                var col = Math.abs(d) <= t.tol ? t.okColor : d < 0 ? t.overColor : t.nearColor;
                c.fillStyle = col;
                c.beginPath(); c.moveTo(xx, bh * 0.62); c.lineTo(xx - bh * 0.32, 2); c.lineTo(xx + bh * 0.32, 2); c.closePath(); c.fill();
                c.fillRect(xx - 2, 0, 4, bh);
            }
        }
    }
}

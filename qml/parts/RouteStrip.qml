import QtQuick
import "Util.js" as U

// 前方の路線(縦の帯)。下が自分、上が前方。駅・分岐・停止位置を距離に応じて置く
Item {
    id: r
    property var items: []            // [{kind, label, dist, side, conflict}]
    property real stopDist: NaN
    property real range: 2000         // 上端までの距離 (m)
    property real behind: 150         // 下端より後ろ (m)
    property real selfAt: 0.86        // 自分の位置 (高さの割合)
    property color bg: "transparent"
    property color railColor: "#5b6b7d"
    property color passedColor: "#2a3440"
    property color stationColor: "#2fd0ff"
    property color stationText: "#ffffff"
    property color distText: "#9fb0c2"
    property color switchColor: "#ffd23f"
    property color conflictColor: "#ff3b30"
    property color selfColor: "#2ee06a"
    property color stopColor: "#ffffff"
    property real fontSize: 22
    onItemsChanged: cv.requestPaint()
    onStopDistChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()

    // 0〜range を上へ。手前ほど広くとる(平方根の目盛)
    function yOf(m) {
        var h = height, base = h * selfAt;
        if (m >= 0) return base - Math.sqrt(Math.min(m, range) / range) * (base - fontSize);
        return base + Math.min(1, -m / behind) * (h - base - 4);
    }

    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            var c = getContext("2d"); c.reset();
            var w = width, h = height, x = w * 0.26;
            if (r.bg.a > 0) { c.fillStyle = r.bg; c.fillRect(0, 0, w, h); }
            var base = r.yOf(0);
            c.fillStyle = r.railColor; c.fillRect(x - 3, 0, 6, base);
            c.fillStyle = r.passedColor; c.fillRect(x - 3, base, 6, h - base);
            // 距離目盛 (100 / 500 / 1000 m)
            c.font = Math.round(r.fontSize * 0.62) + "px '" + Qt.application.font.family + "'";
            c.textAlign = "right"; c.textBaseline = "middle";
            var marks = [100, 250, 500, 1000, 1500, 2000, 3000];
            for (var i = 0; i < marks.length; i++) {
                if (marks[i] > r.range) continue;
                var y = r.yOf(marks[i]);
                c.fillStyle = Qt.rgba(1, 1, 1, 0.18); c.fillRect(x - 14, y, 28, 1);
                c.fillStyle = Qt.rgba(1, 1, 1, 0.35);
                c.fillText(marks[i] >= 1000 ? (marks[i] / 1000) + "k" : String(marks[i]), x - 18, y);
            }
            // 駅・分岐
            var list = r.items || [];
            for (var k = 0; k < list.length; k++) {
                var it = list[k];
                if (!U.has(it.dist) || it.dist > r.range || it.dist < -r.behind) continue;
                var yy = r.yOf(it.dist);
                if (it.kind === "station") {
                    c.fillStyle = r.stationColor; c.fillRect(x - 22, yy - 5, 44, 10);
                    c.textAlign = "left"; c.fillStyle = r.stationText;
                    c.font = "bold " + r.fontSize + "px '" + Qt.application.font.family + "'";
                    c.fillText(it.label, x + 32, yy - r.fontSize * 0.45);
                    c.fillStyle = r.distText; c.font = Math.round(r.fontSize * 0.7) + "px '" + Qt.application.font.family + "'";
                    c.fillText(U.dist(it.dist), x + 32, yy + r.fontSize * 0.55);
                } else if (it.kind === "switch") {
                    var col = it.conflict ? r.conflictColor : r.switchColor;
                    c.strokeStyle = col; c.lineWidth = 4;
                    c.beginPath(); c.moveTo(x, yy + 18); c.lineTo(x + (it.side === "左" || it.label === "left" ? -26 : 26), yy - 16); c.stroke();
                    c.fillStyle = col; c.beginPath(); c.arc(x, yy, 6, 0, Math.PI * 2); c.fill();
                }
            }
            // 停止位置
            if (!isNaN(r.stopDist) && r.stopDist < r.range && r.stopDist > -r.behind) {
                var ys = r.yOf(r.stopDist);
                c.fillStyle = r.stopColor; c.fillRect(x - 30, ys - 2, 60, 4);
            }
            // 自分
            c.fillStyle = r.selfColor;
            c.beginPath(); c.moveTo(x, base - 22); c.lineTo(x - 15, base + 8); c.lineTo(x + 15, base + 8); c.closePath(); c.fill();
        }
    }
}

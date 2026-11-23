import QtQuick
import "Util.js" as U

// 運転記録: 直近の速度・制限速度・ノッチを時間で並べたグラフ (TIMS の運転状況記録のような表示)
Item {
    id: h
    property var d: ({})
    property real seconds: 120          // 横軸の長さ (秒)
    property real speedMax: 120
    property color bg: "#050c16"
    property color gridColor: Qt.rgba(0.4, 0.6, 0.8, 0.16)
    property color textColor: "#8fa6bd"
    property color speedColor: "#5fd8ff"
    property color limitColor: "#ffd23f"
    property color powerColor: "#36e36f"
    property color brakeColor: "#ff9a2e"
    property real fontSize: 16
    property var samples: []            // [{t, v, lim, p, b, maxP, maxB}]
    property real startMs: Date.now()

    Timer {
        interval: 250; running: true; repeat: true
        onTriggered: {
            var dd = h.d || {}, n = dd.notch || {};
            var s = h.samples;
            s.push({ t: Date.now(), v: Math.abs(U.num(dd.speed)), lim: U.has(dd.limit) ? dd.limit : NaN,
                     p: n.p || 0, b: n.b || 0, maxP: n.maxP || 5, maxB: n.maxB || 8 });
            var cut = Date.now() - h.seconds * 1000 - 1000;
            while (s.length && s[0].t < cut) s.shift();
            h.samples = s;
            cv.requestPaint();
        }
    }

    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            var c = getContext("2d"); c.reset();
            var w = width, H = height;
            var left = 52, right = 10, top = 10, notchH = H * 0.24, gap = 14;
            var plotH = H - notchH - gap - top - h.fontSize - 8;
            var pw = w - left - right;
            c.fillStyle = h.bg; c.fillRect(0, 0, w, H);
            var now = Date.now();
            function X(t) { return left + pw * (1 - (now - t) / (h.seconds * 1000)); }
            function Y(v) { return top + plotH * (1 - Math.min(1, v / h.speedMax)); }
            // 格子と目盛
            c.font = h.fontSize + "px '" + Qt.application.font.family + "'";
            c.textAlign = "right"; c.textBaseline = "middle";
            for (var v = 0; v <= h.speedMax; v += 20) {
                var y = Y(v);
                c.fillStyle = h.gridColor; c.fillRect(left, y, pw, 1);
                c.fillStyle = h.textColor; c.fillText(String(v), left - 8, y);
            }
            c.textAlign = "center"; c.textBaseline = "top";
            for (var s = 0; s <= h.seconds; s += 30) {
                var x = left + pw * (1 - s / h.seconds);
                c.fillStyle = h.gridColor; c.fillRect(x, top, 1, plotH + gap + notchH);
                c.fillStyle = h.textColor; c.fillText(s === 0 ? "今" : "-" + s + "秒", x, H - h.fontSize - 2);
            }
            var a = h.samples;
            if (a.length < 2) return;
            // 制限速度 (階段)
            c.beginPath();
            var started = false;
            for (var i = 0; i < a.length; i++) {
                if (isNaN(a[i].lim)) { started = false; continue; }
                var xx = X(a[i].t), yy = Y(a[i].lim);
                if (!started) { c.moveTo(xx, yy); started = true; } else { c.lineTo(xx, Y(a[i - 1].lim)); c.lineTo(xx, yy); }
            }
            c.lineWidth = 2; c.strokeStyle = h.limitColor; c.stroke();
            // 速度 (塗り + 線)
            var g = c.createLinearGradient(0, top, 0, top + plotH);
            g.addColorStop(0, Qt.rgba(0.37, 0.85, 1, 0.38)); g.addColorStop(1, Qt.rgba(0.37, 0.85, 1, 0.02));
            c.beginPath(); c.moveTo(X(a[0].t), Y(0));
            for (var j = 0; j < a.length; j++) c.lineTo(X(a[j].t), Y(a[j].v));
            c.lineTo(X(a[a.length - 1].t), Y(0)); c.closePath();
            c.fillStyle = g; c.fill();
            c.beginPath();
            for (var j2 = 0; j2 < a.length; j2++) { if (j2 === 0) c.moveTo(X(a[j2].t), Y(a[j2].v)); else c.lineTo(X(a[j2].t), Y(a[j2].v)); }
            c.lineWidth = 3; c.strokeStyle = h.speedColor; c.stroke();
            // ノッチ (中央が N、上が力行、下がブレーキ)
            var ny = top + plotH + gap, mid = ny + notchH / 2;
            c.fillStyle = Qt.rgba(1, 1, 1, 0.25); c.fillRect(left, mid, pw, 1);
            c.textAlign = "right"; c.textBaseline = "middle"; c.fillStyle = h.textColor;
            c.fillText("P", left - 8, ny + notchH * 0.2); c.fillText("B", left - 8, ny + notchH * 0.8);
            for (var k2 = 1; k2 < a.length; k2++) {
                var x0 = X(a[k2 - 1].t), x1 = X(a[k2].t), sm = a[k2];
                if (sm.b > 0) {
                    var hb = notchH / 2 * Math.min(1, sm.b / (sm.maxB + 1));
                    c.fillStyle = sm.b > sm.maxB ? "#ff3b30" : h.brakeColor; c.fillRect(x0, mid + 1, x1 - x0 + 0.5, hb);
                } else if (sm.p > 0) {
                    var hp = notchH / 2 * Math.min(1, sm.p / sm.maxP);
                    c.fillStyle = h.powerColor; c.fillRect(x0, mid - hp, x1 - x0 + 0.5, hp);
                }
            }
            // 今の点
            var last = a[a.length - 1];
            c.beginPath(); c.arc(X(last.t), Y(last.v), 6, 0, Math.PI * 2); c.fillStyle = "#ffffff"; c.fill();
        }
    }
}

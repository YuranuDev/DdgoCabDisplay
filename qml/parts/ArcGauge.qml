import QtQuick

// 円形メーター。style = "dial"(実物の計器盤の文字盤) / "lcd"(グラスコックピットの液晶描画)
Item {
    id: g
    property real minValue: 0
    property real maxValue: 120
    property real value: 0
    property real value2: NaN            // 2 本目の針 (空気圧計の MR など)
    property real limit: NaN             // 制限速度などの三角マーカー
    property real startDeg: 135          // 0 = 右, 時計回り
    property real sweepDeg: 270
    property real majorStep: 20
    property real minorStep: 5
    property real labelDivisor: 1
    property int labelDecimals: 0
    property var zones: []               // [{from, to, color}]
    property string style: "dial"
    property string title: ""
    property string unit: ""
    property string digital: ""          // 中央の数字 (空なら出さない)
    property string subText: ""
    property bool dim: false

    property color faceColor: "#f4f1e8"
    property color rimColor: "#1a1a1a"
    property color tickColor: "#111111"
    property color labelColor: "#111111"
    property color needleColor: "#d01818"
    property color needle2Color: "#202020"
    property color trackColor: "#24324a"
    property color fillColor: "#2fd0ff"
    property color fillColorHigh: "#ffb020"
    property color limitColor: "#ffa000"
    property color pointerColor: "#ffffff"   // 液晶の針
    property color digitalColor: style === "lcd" ? "#ffffff" : "#111111"
    property bool fillArc: style === "lcd"
    property string fontFamily: Qt.application.font.family
    property real labelScale: 1.0

    // 針は少しだけ追従を遅らせる(実物の針の動き)
    property real shown: value
    property real shown2: value2
    Behavior on shown { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
    Behavior on shown2 { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

    onShownChanged: cv.requestPaint()
    onShown2Changed: cv.requestPaint()
    onLimitChanged: cv.requestPaint()
    onMaxValueChanged: cv.requestPaint()
    onDigitalChanged: cv.requestPaint()
    onSubTextChanged: cv.requestPaint()
    onDimChanged: cv.requestPaint()
    onStyleChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()

    Canvas {
        id: cv
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        function ang(v) {
            var t = (Math.max(g.minValue, Math.min(g.maxValue, v)) - g.minValue) / (g.maxValue - g.minValue);
            return (g.startDeg + g.sweepDeg * t) * Math.PI / 180;
        }

        onPaint: {
            var c = getContext("2d");
            c.reset();
            var w = width, h = height;
            var R = Math.min(w, h) / 2 - 2;
            var cx = w / 2, cy = h / 2;
            var k = R / 200;                       // 半径 200 を基準にした倍率
            var lcd = g.style === "lcd";
            var f = g.fontFamily;

            // ---- 文字盤 ----
            if (!lcd) {
                // 外枠(黒い縁と銀のリング)
                c.beginPath(); c.arc(cx, cy, R, 0, Math.PI * 2);
                c.fillStyle = g.rimColor; c.fill();
                var rg = c.createLinearGradient(cx, cy - R, cx, cy + R);
                rg.addColorStop(0, "#d9d9d9"); rg.addColorStop(0.5, "#6d6d6d"); rg.addColorStop(1, "#cfcfcf");
                c.beginPath(); c.arc(cx, cy, R - 6 * k, 0, Math.PI * 2);
                c.lineWidth = 5 * k; c.strokeStyle = rg; c.stroke();
                c.beginPath(); c.arc(cx, cy, R - 10 * k, 0, Math.PI * 2);
                c.fillStyle = g.faceColor; c.fill();
            } else {
                // 液晶: うっすら丸い背景とトラック
                var bg = c.createRadialGradient(cx, cy, R * 0.1, cx, cy, R);
                bg.addColorStop(0, Qt.rgba(1, 1, 1, 0.05)); bg.addColorStop(1, Qt.rgba(1, 1, 1, 0.0));
                c.beginPath(); c.arc(cx, cy, R, 0, Math.PI * 2); c.fillStyle = bg; c.fill();
                c.beginPath(); c.arc(cx, cy, R - 14 * k, ang(g.minValue), ang(g.maxValue));
                c.lineWidth = 20 * k; c.strokeStyle = g.trackColor; c.stroke();
            }

            // ---- 色帯(ゾーン) ----
            for (var z = 0; z < g.zones.length; z++) {
                var zn = g.zones[z];
                c.beginPath();
                c.arc(cx, cy, lcd ? R - 2 * k : R - 26 * k, ang(zn.from), ang(zn.to));
                c.lineWidth = lcd ? 5 * k : 9 * k;
                c.strokeStyle = zn.color; c.stroke();
            }

            // ---- 値の帯 (液晶) ----
            if (lcd && g.fillArc) {
                var a0 = ang(Math.max(g.minValue, Math.min(0, g.maxValue))), a1 = ang(g.shown);
                var over = !isNaN(g.limit) && g.shown > g.limit + 0.5;
                c.beginPath();
                if (a1 >= a0) c.arc(cx, cy, R - 14 * k, a0, a1); else c.arc(cx, cy, R - 14 * k, a1, a0);
                c.lineWidth = 20 * k;
                c.strokeStyle = over ? "#ff3b30" : (g.shown >= 0 ? g.fillColor : g.fillColorHigh);
                c.globalAlpha = g.dim ? 0.3 : 0.92;
                c.stroke();
                c.globalAlpha = 1;
            }

            // ---- 目盛 ----
            var rTick = lcd ? R - 30 * k : R - 14 * k;
            var tc = g.dim ? Qt.rgba(0.5, 0.5, 0.5, 1) : g.tickColor;
            var n = Math.round((g.maxValue - g.minValue) / g.minorStep);
            for (var i = 0; i <= n; i++) {
                var v = g.minValue + i * g.minorStep;
                var major = Math.abs((v - g.minValue) / g.majorStep - Math.round((v - g.minValue) / g.majorStep)) < 1e-6;
                var half = !major && Math.abs((v - g.minValue) / (g.majorStep / 2) - Math.round((v - g.minValue) / (g.majorStep / 2))) < 1e-6;
                var a = ang(v);
                var len = (major ? 22 : half ? 15 : 9) * k;
                c.beginPath();
                c.moveTo(cx + Math.cos(a) * rTick, cy + Math.sin(a) * rTick);
                c.lineTo(cx + Math.cos(a) * (rTick - len), cy + Math.sin(a) * (rTick - len));
                c.lineWidth = (major ? 4 : 2) * k;
                c.strokeStyle = tc; c.stroke();
            }

            // ---- 数字 ----
            c.fillStyle = g.dim ? Qt.rgba(0.55, 0.55, 0.55, 1) : g.labelColor;
            c.textAlign = "center"; c.textBaseline = "middle";
            var fs = Math.round(30 * k * g.labelScale);
            c.font = (lcd ? "" : "bold ") + fs + "px '" + f + "'";
            var rLab = rTick - 48 * k;
            var m = Math.round((g.maxValue - g.minValue) / g.majorStep);
            for (var j = 0; j <= m; j++) {
                var lv = g.minValue + j * g.majorStep;
                var la = ang(lv);
                var txt = (lv / g.labelDivisor).toFixed(g.labelDecimals);
                c.fillText(txt, cx + Math.cos(la) * rLab, cy + Math.sin(la) * rLab);
            }

            // ---- 題名と単位 ----
            c.font = Math.round(22 * k) + "px '" + f + "'";
            c.fillStyle = g.dim ? Qt.rgba(0.5, 0.5, 0.5, 1) : (lcd ? Qt.rgba(1, 1, 1, 0.7) : g.labelColor);
            if (g.title.length) c.fillText(g.title, cx, cy - R * (g.digital.length ? 0.52 : 0.36));
            if (g.unit.length) c.fillText(g.unit, cx, cy + R * (lcd ? 0.34 : (g.digital.length ? 0.62 : 0.40)));

            // ---- 制限マーカー ----
            if (!isNaN(g.limit) && g.limit > g.minValue) {
                var al = ang(g.limit);
                var r1 = lcd ? R + 1 * k : R - 12 * k, r2 = r1 - 26 * k;
                c.beginPath();
                c.moveTo(cx + Math.cos(al) * r2, cy + Math.sin(al) * r2);
                c.lineTo(cx + Math.cos(al - 0.06) * r1, cy + Math.sin(al - 0.06) * r1);
                c.lineTo(cx + Math.cos(al + 0.06) * r1, cy + Math.sin(al + 0.06) * r1);
                c.closePath();
                c.fillStyle = g.limitColor; c.fill();
            }

            // ---- 中央の数字 ----
            if (g.digital.length) {
                c.fillStyle = g.dim ? Qt.rgba(0.5, 0.5, 0.5, 1) : g.digitalColor;
                c.font = "bold " + Math.round((lcd ? 86 : 44) * k) + "px '" + f + "'";
                c.fillText(g.digital, cx, lcd ? cy + 6 * k : cy + R * 0.36);
            }
            if (g.subText.length) {
                c.fillStyle = lcd ? Qt.rgba(1, 1, 1, 0.75) : g.labelColor;
                c.font = Math.round(20 * k) + "px '" + f + "'";
                c.fillText(g.subText, cx, cy + R * (lcd ? 0.62 : (g.digital.length ? 0.80 : 0.62)));
            }

            // ---- 針 ----
            function needle(val, col, len, wid) {
                var na = ang(val);
                var tipX = cx + Math.cos(na) * len, tipY = cy + Math.sin(na) * len;
                var bx = cx - Math.cos(na) * 34 * k, by = cy - Math.sin(na) * 34 * k;
                var px = -Math.sin(na) * wid, py = Math.cos(na) * wid;
                c.beginPath();
                c.moveTo(tipX, tipY);
                c.lineTo(cx + px, cy + py);
                c.lineTo(bx + px * 1.6, by + py * 1.6);
                c.lineTo(bx - px * 1.6, by - py * 1.6);
                c.lineTo(cx - px, cy - py);
                c.closePath();
                c.fillStyle = col; c.fill();
            }
            if (!lcd) {
                if (!isNaN(g.shown2)) needle(g.shown2, g.needle2Color, R - 34 * k, 5 * k);
                needle(g.shown, g.dim ? "#888888" : g.needleColor, R - 26 * k, 5.5 * k);
                // 中心のキャップ
                var hub = c.createRadialGradient(cx - 6 * k, cy - 6 * k, 2 * k, cx, cy, 22 * k);
                hub.addColorStop(0, "#5a5a5a"); hub.addColorStop(1, "#0c0c0c");
                c.beginPath(); c.arc(cx, cy, 20 * k, 0, Math.PI * 2); c.fillStyle = hub; c.fill();
            } else {
                // 液晶の細い針(先だけ)
                var na2 = ang(g.shown);
                c.beginPath();
                c.moveTo(cx + Math.cos(na2) * (R - 2 * k), cy + Math.sin(na2) * (R - 2 * k));
                c.lineTo(cx + Math.cos(na2) * (R - 64 * k), cy + Math.sin(na2) * (R - 64 * k));
                c.lineWidth = 7 * k; c.lineCap = "round";
                c.strokeStyle = g.dim ? "#777777" : g.pointerColor; c.stroke();
                if (!isNaN(g.shown2)) {
                    var nb = ang(g.shown2);
                    c.beginPath();
                    c.moveTo(cx + Math.cos(nb) * (R - 6 * k), cy + Math.sin(nb) * (R - 6 * k));
                    c.lineTo(cx + Math.cos(nb) * (R - 50 * k), cy + Math.sin(nb) * (R - 50 * k));
                    c.lineWidth = 6 * k; c.strokeStyle = g.needle2Color; c.stroke();
                }
            }
        }
    }
}

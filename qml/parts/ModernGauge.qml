import QtQuick

// すっきりしたアナログメーター: 丸い端の細い弧・控えめな目盛・細い針、数字は下の切れ目に
Item {
    id: g
    property real minValue: 0
    property real maxValue: 100
    property real value: 0
    property real value2: NaN           // 2 つ目の値 (弧の上の白い点)
    property real limit: NaN
    property real target: NaN           // 目標値 (加速度計の目標など)。外側の三角で示す
    property color targetColor: "#ffffff"
    property real majorStep: 20
    property real minorStep: 10
    property real labelDivisor: 1
    property int labelDecimals: 0
    property real sweepDeg: 240
    property var zones: []              // [{from, to, color}] 弧の外側の細い色帯
    property color accent: "#4c9dff"
    property color negAccent: "#ff9f43"
    property color track: "#252b34"
    property color tickColor: "#59626f"
    property color labelColor: "#8b94a1"
    property color needleColor: "#f2f4f7"
    property color limitColor: "#ffb020"
    property color hubInner: "#0e1116"
    property string valueText: ""
    property color valueColor: "#f2f4f7"
    property string unit: ""
    property string caption: ""
    property real valueSize: 0.30       // 数字の大きさ (半径に対する割合)
    property bool dim: false
    property real thickness: 0.075      // 弧の太さ (半径に対する割合)
    property bool showLabels: true      // 目盛の数字 (小さい計器では消す)

    property real shown: value
    Behavior on shown { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    onShownChanged: cv.requestPaint()
    onValue2Changed: cv.requestPaint()
    onLimitChanged: cv.requestPaint()
    onTargetChanged: cv.requestPaint()
    onMaxValueChanged: cv.requestPaint()
    onMinValueChanged: cv.requestPaint()
    onZonesChanged: cv.requestPaint()
    onDimChanged: cv.requestPaint()
    onAccentChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()

    readonly property real startDeg: 90 + (360 - sweepDeg) / 2
    function ang(v) {
        var t = (Math.max(minValue, Math.min(maxValue, v)) - minValue) / (maxValue - minValue);
        return (startDeg + sweepDeg * t) * Math.PI / 180;
    }

    Canvas {
        id: cv
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative
        onPaint: {
            var c = getContext("2d"); c.reset();
            var R = Math.min(width, height) / 2 - 4, cx = width / 2, cy = height / 2;
            var th = R * g.thickness, rA = R - th / 2 - 4;
            var f = "'" + Qt.application.font.family + "'";
            c.lineCap = "round";

            // 色帯 (外側の細い線)
            for (var z = 0; z < g.zones.length; z++) {
                c.beginPath(); c.arc(cx, cy, R - 1, g.ang(g.zones[z].from), g.ang(g.zones[z].to));
                c.lineWidth = 3; c.lineCap = "butt"; c.strokeStyle = g.zones[z].color; c.stroke();
            }
            c.lineCap = "round";
            // トラック
            c.beginPath(); c.arc(cx, cy, rA, g.ang(g.minValue), g.ang(g.maxValue));
            c.lineWidth = th; c.strokeStyle = g.track; c.stroke();
            // 値の弧 (0 から)
            var zero = Math.max(g.minValue, Math.min(0, g.maxValue));
            var a0 = g.ang(zero), a1 = g.ang(g.shown);
            if (Math.abs(a1 - a0) > 0.01) {
                var over = !isNaN(g.limit) && g.shown > g.limit + 0.5;
                c.beginPath(); c.arc(cx, cy, rA, Math.min(a0, a1), Math.max(a0, a1));
                c.lineWidth = th;
                c.strokeStyle = g.dim ? "#3a414b" : over ? "#ff5a4f" : g.shown < 0 ? g.negAccent : g.accent;
                c.stroke();
            }
            // 目盛と数字
            var rT = rA - th / 2 - R * 0.05;
            var n = Math.round((g.maxValue - g.minValue) / g.minorStep);
            for (var i = 0; i <= n; i++) {
                var v = g.minValue + i * g.minorStep;
                var major = Math.abs((v - g.minValue) / g.majorStep - Math.round((v - g.minValue) / g.majorStep)) < 1e-6;
                var a = g.ang(v), len = major ? R * 0.07 : R * 0.035;
                c.beginPath();
                c.moveTo(cx + Math.cos(a) * rT, cy + Math.sin(a) * rT);
                c.lineTo(cx + Math.cos(a) * (rT - len), cy + Math.sin(a) * (rT - len));
                c.lineWidth = major ? 2 : 1.2; c.lineCap = "butt";
                c.strokeStyle = major ? g.labelColor : g.tickColor; c.stroke();
                if (major && g.showLabels) {
                    var fsL = Math.max(12, Math.round(R * 0.105));
                    var rL = rT - len - fsL * 1.25;
                    c.fillStyle = g.labelColor; c.textAlign = "center"; c.textBaseline = "middle";
                    c.font = fsL + "px " + f;
                    c.fillText((v / g.labelDivisor).toFixed(g.labelDecimals), cx + Math.cos(a) * rL, cy + Math.sin(a) * rL);
                }
            }
            c.lineCap = "round";
            // 制限
            if (!isNaN(g.limit) && g.limit > g.minValue) {
                var al = g.ang(g.limit);
                c.beginPath();
                c.moveTo(cx + Math.cos(al) * (rA - th / 2 - 2), cy + Math.sin(al) * (rA - th / 2 - 2));
                c.lineTo(cx + Math.cos(al) * (R + 2), cy + Math.sin(al) * (R + 2));
                c.lineWidth = 4; c.strokeStyle = g.limitColor; c.stroke();
            }
            // 目標 (外側の三角と、弧の上の細い線)
            if (!isNaN(g.target)) {
                var at = g.ang(Math.max(g.minValue, Math.min(g.maxValue, g.target)));
                var ca = Math.cos(at), sa = Math.sin(at), tw = R * 0.055;
                c.beginPath();
                c.moveTo(cx + ca * (rA + th / 2 + 1), cy + sa * (rA + th / 2 + 1));
                c.lineTo(cx + ca * (R + 3) - sa * tw, cy + sa * (R + 3) + ca * tw);
                c.lineTo(cx + ca * (R + 3) + sa * tw, cy + sa * (R + 3) - ca * tw);
                c.closePath();
                c.fillStyle = g.targetColor; c.fill();
                c.beginPath();
                c.moveTo(cx + ca * (rA - th / 2), cy + sa * (rA - th / 2));
                c.lineTo(cx + ca * (rA + th / 2), cy + sa * (rA + th / 2));
                c.lineWidth = 3; c.lineCap = "butt"; c.strokeStyle = g.targetColor; c.stroke(); c.lineCap = "round";
            }
            // 2 つ目の値
            if (!isNaN(g.value2)) {
                var a2 = g.ang(g.value2);
                c.beginPath(); c.arc(cx + Math.cos(a2) * rA, cy + Math.sin(a2) * rA, th * 0.62, 0, Math.PI * 2);
                c.fillStyle = "#ffffff"; c.fill();
                c.lineWidth = 2; c.strokeStyle = "#0e1116"; c.stroke();
            }
            // 針
            var an = g.ang(g.shown);
            c.beginPath();
            c.moveTo(cx - Math.cos(an) * R * 0.10, cy - Math.sin(an) * R * 0.10);
            c.lineTo(cx + Math.cos(an) * (rA + th / 2), cy + Math.sin(an) * (rA + th / 2));
            c.lineWidth = Math.max(2.5, R * 0.022); c.strokeStyle = g.dim ? "#555" : g.needleColor; c.stroke();
            c.beginPath(); c.arc(cx, cy, R * 0.055, 0, Math.PI * 2); c.fillStyle = g.needleColor; c.fill();
            c.beginPath(); c.arc(cx, cy, R * 0.025, 0, Math.PI * 2); c.fillStyle = g.hubInner; c.fill();

            // 下の切れ目: 数字・単位・見出し
            c.textAlign = "center"; c.textBaseline = "alphabetic";
            if (g.valueText.length) {
                c.fillStyle = g.dim ? "#5a626d" : g.valueColor;
                c.font = "600 " + Math.round(R * g.valueSize) + "px " + f;
                c.fillText(g.valueText, cx, cy + R * 0.60);
            }
            c.font = Math.max(12, Math.round(R * 0.10)) + "px " + f;
            c.fillStyle = g.labelColor;
            if (g.unit.length) c.fillText(g.unit, cx, cy + R * 0.78);
            if (g.caption.length) { c.textBaseline = "middle"; c.fillText(g.caption, cx, cy - R * 0.34); }
        }
    }
}

import QtQuick

// 棒グラフのメーター。segmented = true で TIMS のような区切りのある棒
Item {
    id: b
    property real minValue: 0
    property real maxValue: 100
    property real value: 0
    property bool vertical: false
    property bool segmented: false
    property int segments: 20
    property color barColor: "#2fd0ff"
    property color negColor: "#ff9a2e"
    property color trackColor: "#1c2533"
    property color tickColor: "#8090a0"
    property color textColor: "#ffffff"
    property var marks: []                 // [{v, color}] 目標値などの線
    property real majorStep: 0             // 0 なら目盛なし
    property real labelDivisor: 1
    property bool showLabels: true
    property real fontSize: 16
    property string fontFamily: Qt.application.font.family

    property real shown: value
    Behavior on shown { NumberAnimation { duration: 140 } }
    onShownChanged: cv.requestPaint()
    onMaxValueChanged: cv.requestPaint()
    onMarksChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()

    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            var c = getContext("2d"); c.reset();
            var labelSpace = b.majorStep > 0 && b.showLabels ? b.fontSize + 6 : 0;
            var L = b.vertical ? height - labelSpace * 0 : width;
            var thick = b.vertical ? width - (labelSpace ? b.fontSize * 2.6 : 0) : height - labelSpace;
            function pos(v) { return (Math.max(b.minValue, Math.min(b.maxValue, v)) - b.minValue) / (b.maxValue - b.minValue) * L; }
            function rect(p0, p1, col) {
                c.fillStyle = col;
                if (b.vertical) c.fillRect(0, height - Math.max(p0, p1), thick, Math.abs(p1 - p0));
                else c.fillRect(Math.min(p0, p1), 0, Math.abs(p1 - p0), thick);
            }
            rect(0, L, b.trackColor);
            var zero = pos(Math.max(b.minValue, 0)), cur = pos(b.shown);
            var col = b.shown >= 0 ? b.barColor : b.negColor;
            if (b.segmented) {
                var segL = L / b.segments, gap = Math.max(2, segL * 0.18);
                for (var i = 0; i < b.segments; i++) {
                    var s0 = i * segL, s1 = s0 + segL - gap;
                    var on = (cur >= zero) ? (s1 <= cur + 0.5 && s0 >= zero - 0.5) : (s0 >= cur - 0.5 && s1 <= zero + 0.5);
                    rect(s0, s1, on ? col : Qt.rgba(1, 1, 1, 0.07));
                }
            } else {
                rect(zero, cur, col);
            }
            for (var m = 0; m < b.marks.length; m++) {
                var mp = pos(b.marks[m].v);
                c.fillStyle = b.marks[m].color;
                if (b.vertical) c.fillRect(-3, height - mp - 2, thick + 6, 4);
                else c.fillRect(mp - 2, -4, 4, thick + 8);
            }
            if (b.majorStep > 0) {
                c.fillStyle = b.tickColor; c.font = b.fontSize + "px '" + b.fontFamily + "'";
                c.textAlign = b.vertical ? "left" : "center"; c.textBaseline = b.vertical ? "middle" : "top";
                for (var v = b.minValue; v <= b.maxValue + 1e-6; v += b.majorStep) {
                    var p = pos(v);
                    if (b.vertical) {
                        c.fillRect(thick + 2, height - p - 1, 8, 2);
                        if (b.showLabels) c.fillText(String(Math.round(v / b.labelDivisor * 10) / 10), thick + 13, Math.min(height - 8, Math.max(8, height - p)));
                    } else {
                        c.fillRect(p - 1, thick + 1, 2, 6);
                        if (b.showLabels) { c.textAlign = p < 10 ? "left" : p > width - 10 ? "right" : "center"; c.fillText(String(Math.round(v / b.labelDivisor * 10) / 10), p, thick + 6); }
                    }
                }
            }
        }
    }
}

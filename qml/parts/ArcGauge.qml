import QtQuick

// 円形メーター。style = "dial"(実物の計器盤の文字盤) / "lcd"(グラスコックピットの液晶描画)
// 描画は 3 層: 文字盤(値が変わっても描き直さない)・針と数字(値で描き直す)・ガラスの反射(固定)
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
    property var zones: []               // [{from, to, color}] 文字盤の色帯
    property var bands: []               // [{from, to, color}] 値と一緒に変わる色帯 (動的層に描く)
    property string style: "dial"
    property string title: ""
    property string unit: ""
    property string digital: ""          // 中央の数字 (空なら出さない)
    property string ghost: ""            // 液晶の消えたセグメント (例 "888")
    property string subText: ""
    property bool dim: false

    // 見た目
    property string bezel: style === "lcd" ? "none" : "chrome"   // none / chrome / black / brass
    property bool screws: false          // ベゼルのねじ (計器盤)
    property bool flat: false            // 文字盤を陰影なしの平らな色で塗る (シンプル)
    property bool glass: style !== "lcd" // ガラスの映り込み
    property bool glow: false            // 液晶の発光 (既定はしない)
    property bool brightPassed: style === "lcd"   // 液晶: 針より下の目盛を明るく
    property color faceColor: "#f4f1e8"
    property color faceColor2: Qt.darker(faceColor, 1.12)        // 文字盤の外側 (グラデーション)
    property color rimColor: "#1a1a1a"
    property color tickColor: "#111111"
    property color labelColor: "#111111"
    property color needleColor: "#d01818"
    property color needle2Color: "#202020"
    property color trackColor: "#24324a"
    property color fillColor: "#2fd0ff"
    property color fillColor2: Qt.lighter(fillColor, 1.35)      // 帯の先端側の色
    property color fillColorHigh: "#ffb020"
    property color limitColor: "#ffa000"
    property color pointerColor: "#ffffff"   // 液晶の針
    property color digitalColor: style === "lcd" ? "#ffffff" : "#111111"
    property color hubColor: "#151515"
    property bool fillArc: style === "lcd"
    property string fontFamily: Qt.application.font.family
    property real labelScale: 1.0
    property real digitalScale: 1.0

    // 針は少しだけ追従を遅らせる(実物の針の動き)
    property real shown: value
    property real shown2: value2
    Behavior on shown { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
    Behavior on shown2 { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

    onShownChanged: dyn.requestPaint()
    onShown2Changed: dyn.requestPaint()
    onLimitChanged: dyn.requestPaint()
    onDigitalChanged: dyn.requestPaint()
    onSubTextChanged: dyn.requestPaint()
    onBandsChanged: dyn.requestPaint()
    onDimChanged: { face.requestPaint(); dyn.requestPaint(); }
    onMaxValueChanged: { face.requestPaint(); dyn.requestPaint(); }
    onMinValueChanged: { face.requestPaint(); dyn.requestPaint(); }
    onZonesChanged: face.requestPaint()
    onStyleChanged: { face.requestPaint(); dyn.requestPaint(); }
    onWidthChanged: { face.requestPaint(); dyn.requestPaint(); glassLayer.requestPaint(); }
    onHeightChanged: { face.requestPaint(); dyn.requestPaint(); glassLayer.requestPaint(); }

    function ang(v) {
        var t = (Math.max(minValue, Math.min(maxValue, v)) - minValue) / (maxValue - minValue);
        return (startDeg + sweepDeg * t) * Math.PI / 180;
    }
    function geo(w, h) { var R = Math.min(w, h) / 2 - 2; return { R: R, cx: w / 2, cy: h / 2, k: R / 200 }; }
    function faceR(G) { return bezel === "none" ? G.R : G.R - 15 * G.k; }

    // ============ 文字盤 ============
    Canvas {
        id: face
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative
        onPaint: {
            var c = getContext("2d"); c.reset();
            var G = g.geo(width, height), R = G.R, cx = G.cx, cy = G.cy, k = G.k;
            var lcd = g.style === "lcd", f = g.fontFamily;
            var FR = g.faceR(G);

            // ---- ベゼル ----
            if (g.bezel !== "none") {
                // 外側の影
                var sh = c.createRadialGradient(cx, cy + 4 * k, R * 0.9, cx, cy + 4 * k, R + 2);
                sh.addColorStop(0, Qt.rgba(0, 0, 0, 0.55)); sh.addColorStop(1, Qt.rgba(0, 0, 0, 0));
                c.beginPath(); c.arc(cx, cy + 4 * k, R + 2, 0, Math.PI * 2); c.fillStyle = sh; c.fill();
                var bz = c.createLinearGradient(cx - R, cy - R, cx + R, cy + R);
                if (g.bezel === "chrome") {
                    bz.addColorStop(0, "#f4f4f4"); bz.addColorStop(0.35, "#8a8d91"); bz.addColorStop(0.5, "#d6d8db");
                    bz.addColorStop(0.75, "#5d6064"); bz.addColorStop(1, "#c9cbce");
                } else if (g.bezel === "brass") {
                    bz.addColorStop(0, "#f3dc98"); bz.addColorStop(0.4, "#9a7a32"); bz.addColorStop(0.6, "#e6c870"); bz.addColorStop(1, "#6e5420");
                } else {
                    bz.addColorStop(0, "#4a4d52"); bz.addColorStop(0.5, "#16181a"); bz.addColorStop(1, "#383b3f");
                }
                c.beginPath(); c.arc(cx, cy, R, 0, Math.PI * 2); c.fillStyle = bz; c.fill();
                // 内側の段差
                var bz2 = c.createLinearGradient(cx, cy - R, cx, cy + R);
                bz2.addColorStop(0, Qt.rgba(0, 0, 0, 0.55)); bz2.addColorStop(1, Qt.rgba(1, 1, 1, 0.35));
                c.beginPath(); c.arc(cx, cy, R - 8 * k, 0, Math.PI * 2); c.lineWidth = 6 * k; c.strokeStyle = bz2; c.stroke();
                c.beginPath(); c.arc(cx, cy, FR + 1, 0, Math.PI * 2); c.fillStyle = g.rimColor; c.fill();
            }

            // ---- 文字盤の面 ----
            if (!lcd) {
                var fg = c.createRadialGradient(cx, cy - FR * 0.25, FR * 0.05, cx, cy, FR);
                fg.addColorStop(0, Qt.lighter(g.faceColor, 1.06)); fg.addColorStop(0.7, g.faceColor); fg.addColorStop(1, g.faceColor2);
                c.beginPath(); c.arc(cx, cy, FR - 2 * k, 0, Math.PI * 2); c.fillStyle = g.flat ? g.faceColor : fg; c.fill();
                // 縁の内側の影
                if (!g.flat) {
                    var ins = c.createRadialGradient(cx, cy, FR * 0.82, cx, cy, FR);
                    ins.addColorStop(0, Qt.rgba(0, 0, 0, 0)); ins.addColorStop(1, Qt.rgba(0, 0, 0, 0.35));
                    c.beginPath(); c.arc(cx, cy, FR - 2 * k, 0, Math.PI * 2); c.fillStyle = ins; c.fill();
                }
                // 目盛の内側の細い輪 (チャプターリング)
                c.beginPath(); c.arc(cx, cy, FR - 14 * k, g.ang(g.minValue), g.ang(g.maxValue));
                c.lineWidth = 1.6 * k; c.strokeStyle = g.dim ? "#777" : g.tickColor; c.stroke();
            } else {
                var bg = c.createRadialGradient(cx, cy, R * 0.15, cx, cy, R);
                bg.addColorStop(0, Qt.rgba(0.3, 0.6, 1, 0.07)); bg.addColorStop(0.8, Qt.rgba(0.3, 0.6, 1, 0.02)); bg.addColorStop(1, Qt.rgba(0, 0, 0, 0));
                c.beginPath(); c.arc(cx, cy, R, 0, Math.PI * 2); c.fillStyle = bg; c.fill();
                // 外周の細い 2 重線
                c.lineWidth = 1.5 * k; c.strokeStyle = Qt.rgba(0.6, 0.8, 1, 0.28);
                c.beginPath(); c.arc(cx, cy, R - 1, g.ang(g.minValue) - 0.04, g.ang(g.maxValue) + 0.04); c.stroke();
                c.beginPath(); c.arc(cx, cy, R - 30 * k, g.ang(g.minValue), g.ang(g.maxValue)); c.stroke();
                // トラック
                c.beginPath(); c.arc(cx, cy, R - 15 * k, g.ang(g.minValue), g.ang(g.maxValue));
                c.lineWidth = 22 * k; c.strokeStyle = g.trackColor; c.stroke();
                // トラックの区切り (目盛ごと)
                var nn = Math.round((g.maxValue - g.minValue) / g.minorStep);
                c.strokeStyle = Qt.rgba(0, 0, 0, 0.45); c.lineWidth = 2 * k;
                for (var s = 1; s < nn; s++) {
                    var sa = g.ang(g.minValue + s * g.minorStep);
                    c.beginPath(); c.moveTo(cx + Math.cos(sa) * (R - 26 * k), cy + Math.sin(sa) * (R - 26 * k));
                    c.lineTo(cx + Math.cos(sa) * (R - 4 * k), cy + Math.sin(sa) * (R - 4 * k)); c.stroke();
                }
            }

            // ---- 色帯 ----
            for (var z = 0; z < g.zones.length; z++) {
                var zn = g.zones[z];
                c.beginPath();
                c.arc(cx, cy, lcd ? R + 3 * k : FR - 22 * k, g.ang(zn.from), g.ang(zn.to));
                c.lineWidth = lcd ? 5 * k : 11 * k;
                c.strokeStyle = zn.color; c.stroke();
            }

            // ---- 目盛 ----
            var rTick = lcd ? R - 36 * k : FR - 16 * k;
            var tc = g.dim ? Qt.rgba(0.5, 0.5, 0.5, 1) : g.tickColor;
            var n = Math.round((g.maxValue - g.minValue) / g.minorStep);
            for (var i = 0; i <= n; i++) {
                var v = g.minValue + i * g.minorStep;
                var major = Math.abs((v - g.minValue) / g.majorStep - Math.round((v - g.minValue) / g.majorStep)) < 1e-6;
                var half = !major && Math.abs((v - g.minValue) / (g.majorStep / 2) - Math.round((v - g.minValue) / (g.majorStep / 2))) < 1e-6;
                var a = g.ang(v);
                var len = (major ? 24 : half ? 16 : 9) * k;
                c.beginPath();
                c.moveTo(cx + Math.cos(a) * rTick, cy + Math.sin(a) * rTick);
                c.lineTo(cx + Math.cos(a) * (rTick - len), cy + Math.sin(a) * (rTick - len));
                c.lineWidth = (major ? 4.5 : half ? 3 : 2) * k;
                c.lineCap = "butt";
                c.strokeStyle = tc; c.stroke();
            }

            // ---- 数字 ----
            c.fillStyle = g.dim ? Qt.rgba(0.55, 0.55, 0.55, 1) : g.labelColor;
            c.textAlign = "center"; c.textBaseline = "middle";
            var fs = Math.round(30 * k * g.labelScale);
            c.font = (lcd ? "" : "bold ") + fs + "px '" + f + "'";
            var rLab = rTick - (lcd ? 60 : 48) * k;
            var m = Math.round((g.maxValue - g.minValue) / g.majorStep);
            for (var j = 0; j <= m; j++) {
                var lv = g.minValue + j * g.majorStep;
                var la = g.ang(lv);
                c.fillText((lv / g.labelDivisor).toFixed(g.labelDecimals), cx + Math.cos(la) * rLab, cy + Math.sin(la) * rLab);
            }

            // ---- 題名と単位 ----
            c.font = Math.round(22 * k) + "px '" + f + "'";
            c.fillStyle = g.dim ? Qt.rgba(0.5, 0.5, 0.5, 1) : (lcd ? Qt.rgba(0.75, 0.85, 1, 0.75) : g.labelColor);
            if (g.title.length) c.fillText(g.title, cx, cy - R * (g.digital.length ? 0.52 : 0.36));
            if (g.unit.length) c.fillText(g.unit, cx, cy + R * (lcd ? 0.34 : (g.digital.length ? 0.62 : 0.40)));

            // ---- 液晶の消えたセグメント / 計器の数字窓 ----
            if (g.digital.length && !lcd) {
                var ww = 108 * k * g.digitalScale, hh = 46 * k * g.digitalScale, wy = cy + R * 0.36 - hh / 2;
                c.fillStyle = "#0b0d0c"; c.fillRect(cx - ww / 2, wy, ww, hh);
                c.lineWidth = 2 * k; c.strokeStyle = Qt.rgba(1, 1, 1, 0.25); c.strokeRect(cx - ww / 2, wy, ww, hh);
            }
            if (lcd && g.ghost.length) {
                c.fillStyle = Qt.rgba(1, 1, 1, 0.045);
                c.font = "bold " + Math.round(86 * k * g.digitalScale) + "px '" + f + "'";
                c.fillText(g.ghost, cx, cy + 6 * k);
            }
        }
    }

    // ============ 針と数字 ============
    Canvas {
        id: dyn
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative
        onPaint: {
            var c = getContext("2d"); c.reset();
            var G = g.geo(width, height), R = G.R, cx = G.cx, cy = G.cy, k = G.k;
            var lcd = g.style === "lcd", f = g.fontFamily;
            var FR = g.faceR(G);

            // 値と一緒に変わる帯
            for (var z = 0; z < g.bands.length; z++) {
                var bn = g.bands[z];
                if (bn.to <= bn.from) continue;
                c.beginPath(); c.arc(cx, cy, lcd ? R - 15 * k : FR - 22 * k, g.ang(bn.from), g.ang(bn.to));
                c.lineWidth = lcd ? 22 * k : 11 * k; c.strokeStyle = bn.color; c.stroke();
            }

            // ---- 値の帯 (液晶) ----
            if (lcd && g.fillArc) {
                var zero = Math.max(g.minValue, Math.min(0, g.maxValue));
                var a0 = g.ang(zero), a1 = g.ang(g.shown);
                var over = !isNaN(g.limit) && g.shown > g.limit + 0.5;
                var col = over ? "#ff3b30" : (g.shown >= 0 ? g.fillColor : g.fillColorHigh);
                var lo = Math.min(a0, a1), hi = Math.max(a0, a1);
                if (hi - lo > 0.002) {
                    var grad = c.createConicalGradient(cx, cy, -lo);
                    // 円錐グラデーションは反時計回りに進むので、帯の根元→先端で色を変える
                    var span = (hi - lo) / (Math.PI * 2);
                    grad.addColorStop(0, col);
                    grad.addColorStop(Math.max(0, 1 - span), over ? "#ff8a80" : (g.shown >= 0 ? g.fillColor2 : Qt.lighter(g.fillColorHigh, 1.3)));
                    grad.addColorStop(1, col);
                    if (g.glow && !g.dim) {
                        c.beginPath(); c.arc(cx, cy, R - 15 * k, lo, hi);
                        c.lineWidth = 36 * k; c.strokeStyle = col; c.globalAlpha = 0.16; c.stroke(); c.globalAlpha = 1;
                    }
                    c.beginPath(); c.arc(cx, cy, R - 15 * k, lo, hi);
                    c.lineWidth = 22 * k;
                    c.strokeStyle = col;
                    c.globalAlpha = g.dim ? 0.3 : 0.95;
                    c.stroke();
                    // 帯の外側の明るい縁
                    c.beginPath(); c.arc(cx, cy, R - 5 * k, lo, hi);
                    c.lineWidth = 2.5 * k; c.strokeStyle = "#ffffff"; c.globalAlpha = g.dim ? 0.15 : 0.55; c.stroke();
                    c.globalAlpha = 1;
                }
            }

            // ---- 液晶: 針より下の目盛を明るく ----
            if (lcd && g.brightPassed && !g.dim) {
                var rTick = R - 36 * k;
                var n = Math.round((g.maxValue - g.minValue) / g.minorStep);
                c.strokeStyle = "#ffffff"; c.lineCap = "butt";
                for (var i = 0; i <= n; i++) {
                    var v = g.minValue + i * g.minorStep;
                    if (v > g.shown + 1e-6 || v < Math.min(0, g.shown) - 1e-6) continue;
                    var major = Math.abs((v - g.minValue) / g.majorStep - Math.round((v - g.minValue) / g.majorStep)) < 1e-6;
                    var a = g.ang(v), len = (major ? 24 : 9) * k;
                    c.beginPath();
                    c.moveTo(cx + Math.cos(a) * rTick, cy + Math.sin(a) * rTick);
                    c.lineTo(cx + Math.cos(a) * (rTick - len), cy + Math.sin(a) * (rTick - len));
                    c.lineWidth = (major ? 4.5 : 2) * k; c.stroke();
                }
            }

            // ---- 制限マーカー ----
            if (!isNaN(g.limit) && g.limit > g.minValue) {
                var al = g.ang(g.limit);
                var r1 = lcd ? R + 6 * k : FR - 6 * k, r2 = r1 - 30 * k;
                c.beginPath();
                c.moveTo(cx + Math.cos(al) * r2, cy + Math.sin(al) * r2);
                c.lineTo(cx + Math.cos(al - 0.07) * r1, cy + Math.sin(al - 0.07) * r1);
                c.lineTo(cx + Math.cos(al + 0.07) * r1, cy + Math.sin(al + 0.07) * r1);
                c.closePath();
                c.fillStyle = g.limitColor; c.fill();
                c.lineWidth = 1.5 * k; c.strokeStyle = Qt.rgba(0, 0, 0, 0.5); c.stroke();
            }

            // ---- 中央の数字 ----
            c.textAlign = "center"; c.textBaseline = "middle";
            if (g.digital.length) {
                c.fillStyle = g.dim ? Qt.rgba(0.5, 0.5, 0.5, 1) : g.digitalColor;
                if (lcd) {
                    c.font = "bold " + Math.round(86 * k * g.digitalScale) + "px '" + f + "'";
                    if (g.glow && !g.dim) { c.shadowColor = Qt.rgba(0.4, 0.8, 1, 0.55); c.shadowBlur = 18 * k; }
                    c.fillText(g.digital, cx, cy + 6 * k);
                    c.shadowBlur = 0; c.shadowColor = "transparent";
                } else {
                    c.font = "bold " + Math.round(40 * k * g.digitalScale) + "px '" + f + "'";
                    c.fillStyle = g.dim ? "#666" : (g.digitalColor === "#111111" ? "#ffb020" : g.digitalColor);
                    c.fillText(g.digital, cx, cy + R * 0.36 + 2 * k);
                }
            }
            if (g.subText.length) {
                c.fillStyle = lcd ? Qt.rgba(0.8, 0.9, 1, 0.8) : g.labelColor;
                c.font = Math.round(20 * k) + "px '" + f + "'";
                c.fillText(g.subText, cx, cy + R * (lcd ? 0.62 : (g.digital.length ? 0.80 : 0.62)));
            }

            // ---- 針 ----
            function needle(val, col, len, wid, shadow) {
                var na = g.ang(val);
                var ca = Math.cos(na), sa = Math.sin(na);
                var px = -sa * wid, py = ca * wid;
                function path(ox, oy) {
                    var tipX = cx + ca * len + ox, tipY = cy + sa * len + oy;
                    var bx = cx - ca * 44 * k + ox, by = cy - sa * 44 * k + oy;
                    c.beginPath();
                    c.moveTo(tipX, tipY);
                    c.lineTo(cx + px * 0.9 + ox, cy + py * 0.9 + oy);
                    c.lineTo(bx + px * 2.2 + ox, by + py * 2.2 + oy);
                    c.lineTo(bx - px * 2.2 + ox, by - py * 2.2 + oy);
                    c.lineTo(cx - px * 0.9 + ox, cy - py * 0.9 + oy);
                    c.closePath();
                }
                if (shadow && !g.flat) { path(4 * k, 6 * k); c.fillStyle = Qt.rgba(0, 0, 0, 0.32); c.fill(); }
                path(0, 0); c.fillStyle = col; c.fill();
                // 針の稜線(片側を少し明るく)
                c.beginPath();
                c.moveTo(cx + ca * len, cy + sa * len); c.lineTo(cx + px * 0.9, cy + py * 0.9); c.lineTo(cx, cy); c.closePath();
                if (!g.flat) { c.fillStyle = Qt.rgba(1, 1, 1, 0.22); c.fill(); }
            }
            if (!lcd) {
                if (!isNaN(g.shown2)) needle(g.shown2, g.needle2Color, FR - 30 * k, 4.5 * k, true);
                needle(g.shown, g.dim ? "#888888" : g.needleColor, FR - 20 * k, 5 * k, true);
                // 中心のキャップ
                if (g.flat) {
                    c.beginPath(); c.arc(cx, cy, 18 * k, 0, Math.PI * 2); c.fillStyle = g.hubColor; c.fill();
                    c.beginPath(); c.arc(cx, cy, 18 * k, 0, Math.PI * 2); c.lineWidth = 4 * k; c.strokeStyle = g.needleColor; c.stroke();
                    return;
                }
                var hub = c.createRadialGradient(cx - 7 * k, cy - 7 * k, 2 * k, cx, cy, 24 * k);
                hub.addColorStop(0, Qt.lighter(g.hubColor, 3.2)); hub.addColorStop(0.6, g.hubColor); hub.addColorStop(1, "#000000");
                c.beginPath(); c.arc(cx, cy, 22 * k, 0, Math.PI * 2); c.fillStyle = hub; c.fill();
                c.beginPath(); c.arc(cx, cy, 22 * k, 0, Math.PI * 2); c.lineWidth = 1.5 * k; c.strokeStyle = Qt.rgba(1, 1, 1, 0.25); c.stroke();
                c.beginPath(); c.arc(cx, cy, 6 * k, 0, Math.PI * 2); c.fillStyle = g.needleColor; c.fill();
            } else {
                // 液晶の針: 外周に沿った細い指針
                function pointer(val, col, r0, r1, wid, glowOn) {
                    var na = g.ang(val);
                    if (glowOn && g.glow && !g.dim) { c.shadowColor = col; c.shadowBlur = 14 * k; }
                    c.beginPath();
                    c.moveTo(cx + Math.cos(na) * r0, cy + Math.sin(na) * r0);
                    c.lineTo(cx + Math.cos(na) * r1, cy + Math.sin(na) * r1);
                    c.lineWidth = wid; c.lineCap = "round";
                    c.strokeStyle = g.dim ? "#777777" : col; c.stroke();
                    c.shadowBlur = 0; c.shadowColor = "transparent";
                }
                if (!isNaN(g.shown2)) pointer(g.shown2, g.needle2Color, R + 2 * k, R - 52 * k, 6 * k, false);
                pointer(g.shown, g.pointerColor, R + 4 * k, R - 70 * k, 7 * k, true);
            }
        }
    }

    // ============ ガラスの映り込み ============
    Canvas {
        id: glassLayer
        anchors.fill: parent
        visible: g.glass
        renderStrategy: Canvas.Cooperative
        onPaint: {
            var c = getContext("2d"); c.reset();
            var G = g.geo(width, height), R = G.R, cx = G.cx, cy = G.cy, k = G.k;
            var FR = g.faceR(G) - 2 * k;
            c.save();
            c.beginPath(); c.arc(cx, cy, FR, 0, Math.PI * 2); c.clip();
            // 左上からの斜めの映り込み
            var gl = c.createLinearGradient(cx - FR, cy - FR, cx + FR * 0.2, cy + FR * 0.4);
            gl.addColorStop(0, Qt.rgba(1, 1, 1, 0.20)); gl.addColorStop(0.45, Qt.rgba(1, 1, 1, 0.05)); gl.addColorStop(0.46, Qt.rgba(1, 1, 1, 0.0));
            c.beginPath();
            c.ellipse(cx - FR * 1.25, cy - FR * 1.45, FR * 2.1, FR * 1.75);
            c.fillStyle = gl; c.fill();
            c.restore();
            // ねじ
            if (g.screws) {
                for (var i = 0; i < 4; i++) {
                    var a = Math.PI / 4 + i * Math.PI / 2;
                    var sx = cx + Math.cos(a) * (R - 7.5 * k), sy = cy + Math.sin(a) * (R - 7.5 * k);
                    var sg = c.createRadialGradient(sx - 1.5 * k, sy - 1.5 * k, 0.5, sx, sy, 5 * k);
                    sg.addColorStop(0, "#f0f0f0"); sg.addColorStop(1, "#4a4a4a");
                    c.beginPath(); c.arc(sx, sy, 4.5 * k, 0, Math.PI * 2); c.fillStyle = sg; c.fill();
                    c.beginPath(); c.moveTo(sx - 3 * k * Math.cos(a + 0.8), sy - 3 * k * Math.sin(a + 0.8));
                    c.lineTo(sx + 3 * k * Math.cos(a + 0.8), sy + 3 * k * Math.sin(a + 0.8));
                    c.lineWidth = 1.2 * k; c.strokeStyle = "#222"; c.stroke();
                }
            }
        }
    }
}

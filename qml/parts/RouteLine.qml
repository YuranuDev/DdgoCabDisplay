import QtQuick
import "Util.js" as U

// 横向きの路線図 (車内案内表示のような駅の丸と線)。左が後ろの駅、右へ進む
Item {
    id: r
    property var items: []             // ahead の駅だけ使う
    property string prev: ""
    property string at: ""
    property color lineColor: "#25407e"
    property color passedColor: "#b6c0cf"
    property color stationFill: "white"
    property color nextColor: "#f07a12"
    property color textColor: "#14213d"
    property color subColor: "#5c6a80"
    property color trainColor: "#f07a12"
    property real fontSize: 26
    onItemsChanged: cv.requestPaint()
    onAtChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()

    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            var c = getContext("2d"); c.reset();
            var w = width, H = height;
            var st = (r.items || []).filter(function (a) { return a.kind === "station"; }).sort(function (a, b) { return a.dist - b.dist; });
            // 後ろの駅 1 つ + 前の駅 3 つ
            var back = st.filter(function (a) { return a.dist < -1; }).slice(-1);
            var ahead = st.filter(function (a) { return a.dist >= -1; }).slice(0, 3);
            var list = back.concat(ahead);
            if (list.length === 0) return;
            var n = list.length, padL = 70, padR = 70;
            var y = H * 0.42, step = (w - padL - padR) / Math.max(1, n - 1);
            function xs(i) { return n === 1 ? w / 2 : padL + step * i; }
            // 自分の位置: 後ろの駅と次の駅の間を距離で割り振る
            var selfX = padL;
            for (var i = 0; i < n - 1; i++) {
                if (list[i].dist <= 0 && list[i + 1].dist >= 0) {
                    var span = list[i + 1].dist - list[i].dist;
                    selfX = xs(i) + step * (span > 0 ? -list[i].dist / span : 0);
                }
            }
            if (list[0].dist >= 0) selfX = xs(0) - 30;
            // 線 (通過済みは灰色)
            c.lineCap = "round";
            c.lineWidth = 16; c.strokeStyle = r.passedColor;
            c.beginPath(); c.moveTo(xs(0) - 40, y); c.lineTo(selfX, y); c.stroke();
            c.strokeStyle = r.lineColor;
            c.beginPath(); c.moveTo(selfX, y); c.lineTo(xs(n - 1) + 40, y); c.stroke();
            // 進行方向の矢印
            c.fillStyle = r.lineColor;
            c.beginPath(); c.moveTo(xs(n - 1) + 62, y); c.lineTo(xs(n - 1) + 36, y - 18); c.lineTo(xs(n - 1) + 36, y + 18); c.closePath(); c.fill();
            // 駅
            var nextIdx = -1;
            for (var j = 0; j < n; j++) if (list[j].dist >= -1) { nextIdx = j; break; }
            for (var k = 0; k < n; k++) {
                var x = xs(k), passed = list[k].dist < -1, isNext = k === nextIdx;
                c.beginPath(); c.arc(x, y, isNext ? 20 : 15, 0, Math.PI * 2);
                c.fillStyle = r.stationFill; c.fill();
                c.lineWidth = isNext ? 8 : 6; c.strokeStyle = passed ? r.passedColor : isNext ? r.nextColor : r.lineColor; c.stroke();
                c.textAlign = "center"; c.textBaseline = "top";
                c.font = (isNext ? "bold " : "") + Math.round(r.fontSize * (isNext ? 1.15 : 1)) + "px '" + Qt.application.font.family + "'";
                c.fillStyle = passed ? r.subColor : isNext ? r.nextColor : r.textColor;
                c.fillText(list[k].label, x, y + 28);
                if (!passed) {
                    c.font = Math.round(r.fontSize * 0.62) + "px '" + Qt.application.font.family + "'";
                    c.fillStyle = r.subColor; c.textBaseline = "bottom";
                    c.fillText(U.dist(list[k].dist), x, y - 26);
                }
            }
            // 列車
            c.fillStyle = r.trainColor;
            c.beginPath();
            c.moveTo(selfX + 22, y); c.lineTo(selfX - 4, y - 16); c.lineTo(selfX - 4, y + 16); c.closePath(); c.fill();
            c.lineWidth = 3; c.strokeStyle = "white"; c.stroke();
        }
    }
}

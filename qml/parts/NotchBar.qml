import QtQuick

// ノッチの横一列: 左から 非常・B…B1・N・P1…P。入っている段まで色が付き、下に段の名前
Item {
    id: nb
    property var n: ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    property real labelSize: 15 * Pal.ts
    readonly property int maxP: n && n.maxP ? n.maxP : 5
    readonly property int maxB: n && n.maxB ? n.maxB : 8
    readonly property var cells: {
        var a = [{ k: "E", i: maxB + 1, l: "EB" }];
        for (var j = maxB; j >= 1; j--) a.push({ k: "B", i: j, l: "B" + j });
        a.push({ k: "N", i: 0, l: "N" });
        for (var i = 1; i <= maxP; i++) a.push({ k: "P", i: i, l: "P" + i });
        return a;
    }
    function on(c) {
        var p = n ? n.p : 0, b = n ? n.b : 0;
        if (c.k === "N") return p === 0 && b === 0;
        if (c.k === "P") return b === 0 && p >= c.i;
        if (c.k === "E") return b > maxB;
        return b >= c.i;
    }
    function cur(c) {
        var p = n ? n.p : 0, b = n ? n.b : 0;
        if (c.k === "N") return p === 0 && b === 0;
        if (c.k === "P") return b === 0 && p === c.i;
        if (c.k === "E") return b > maxB;
        return b === c.i && b <= maxB;
    }
    function col(c) { return c.k === "P" ? Pal.green : c.k === "N" ? Pal.text : c.k === "E" ? Pal.red : Pal.orange; }
    readonly property real cw: (width - 4 * (cells.length - 1)) / cells.length
    Row {
        spacing: 4
        Repeater {
            model: nb.cells
            Column {
                spacing: 6
                Rectangle {
                    width: nb.cw; height: nb.height - nb.labelSize - 8
                    radius: 6
                    color: nb.on(modelData) ? nb.col(modelData) : Pal.raised
                    border.color: nb.cur(modelData) ? Pal.text : "transparent"; border.width: 2
                }
                Text {
                    width: nb.cw; horizontalAlignment: Text.AlignHCenter
                    text: modelData.l; color: nb.cur(modelData) ? Pal.text : Pal.mute
                    font.pixelSize: nb.labelSize; font.weight: nb.cur(modelData) ? Font.DemiBold : Font.Normal
                }
            }
        }
    }
}

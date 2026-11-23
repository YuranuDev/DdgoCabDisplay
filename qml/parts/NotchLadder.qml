import QtQuick

// ノッチ表示。上(左)から P最大…P1・N・B1…B最大・EB の段を並べ、入っている段を光らせる
Item {
    id: nl
    property var n: ({ p: 0, b: 0, maxP: 5, maxB: 8, sentP: 0, sentB: 0, pending: 0 })
    property bool vertical: true
    property bool growFromCenter: true      // N から外側へ光る(TIMS 風)。false で今の段だけ
    property color powerColor: "#2ee06a"
    property color brakeColor: "#ff9a2e"
    property color ebColor: "#ff2d2d"
    property color neutralColor: "#e8e8e8"
    property color offColor: "#1d232b"
    property color offText: "#56606c"
    property color litText: "#0a0a0a"
    property color frameColor: "transparent"
    property real gap: 4
    property real fontSize: 18
    property real radius: 3
    property bool showSent: true
    property bool glow: false
    property bool gloss: false            // つや・立体感 (既定は平ら)
    property string ebLabel: "非常"
    property string part: "all"            // "all" / "power"(P…N) / "brake"(B…EB)

    readonly property int maxP: n && n.maxP ? n.maxP : 5
    readonly property int maxB: n && n.maxB ? n.maxB : 8
    readonly property var cells: {
        var a = [];
        if (part !== "brake") {
            for (var i = maxP; i >= 1; i--) a.push({ k: "P", i: i, label: "P" + i });
            a.push({ k: "N", i: 0, label: "N" });
        }
        if (part !== "power") {
            if (part === "brake") a.push({ k: "R", i: 0, label: "切" });
            for (var j = 1; j <= maxB; j++) a.push({ k: "B", i: j, label: "B" + j });
            a.push({ k: "E", i: maxB + 1, label: ebLabel });
        }
        return vertical ? a : a.slice().reverse();
    }

    function active(c) {
        var p = n ? n.p : 0, b = n ? n.b : 0;
        if (c.k === "N") return p === 0 && b === 0;
        if (c.k === "R") return b === 0;
        if (c.k === "P") return b === 0 && (growFromCenter ? p >= c.i : p === c.i);
        if (c.k === "E") return b > maxB;
        return growFromCenter ? b >= c.i : b === c.i;
    }
    function sent(c) {
        if (!n || !showSent) return false;
        var sp = n.sentP, sb = n.sentB;
        if (sp === n.p && sb === n.b) return false;
        if (c.k === "N") return sp === 0 && sb === 0;
        if (c.k === "R") return sb === 0;
        if (c.k === "P") return sb === 0 && sp === c.i;
        if (c.k === "E") return sb > maxB;
        return sb === c.i;
    }
    // いま入っている段 (光らせる段のうち一番外側)
    function isCurrent(c) {
        var p = n ? n.p : 0, b = n ? n.b : 0;
        if (c.k === "N") return p === 0 && b === 0;
        if (c.k === "R") return b === 0;
        if (c.k === "P") return b === 0 && p === c.i;
        if (c.k === "E") return b > maxB;
        return b === c.i;
    }
    function colorOf(c) { return c.k === "P" ? powerColor : c.k === "N" || c.k === "R" ? neutralColor : c.k === "E" ? ebColor : brakeColor; }

    Grid {
        id: grid
        anchors.fill: parent
        columns: nl.vertical ? 1 : nl.cells.length
        rows: nl.vertical ? nl.cells.length : 1
        spacing: nl.gap
        Repeater {
            model: nl.cells
            Item {
                id: cell
                width: nl.vertical ? grid.width : (grid.width - nl.gap * (nl.cells.length - 1)) / nl.cells.length
                height: nl.vertical ? (grid.height - nl.gap * (nl.cells.length - 1)) / nl.cells.length : grid.height
                readonly property bool on: nl.active(modelData)
                readonly property bool cur: on && nl.isCurrent(modelData)
                readonly property color col: nl.colorOf(modelData)
                // 今の段は外側に光を漏らす
                Rectangle {
                    anchors.fill: parent; anchors.margins: -4; radius: nl.radius + 4
                    color: cell.col; opacity: cell.cur && nl.glow ? 0.35 : 0
                }
                Rectangle {
                    anchors.fill: parent
                    radius: nl.radius
                    border.width: nl.sent(modelData) ? 3 : (nl.frameColor.a > 0 && !cell.on ? 1 : 0)
                    border.color: nl.sent(modelData) ? "#ffffff" : cell.on ? Qt.lighter(cell.col, 1.25) : nl.frameColor.a > 0 ? nl.frameColor : Qt.rgba(1, 1, 1, 0.06)
                    color: cell.on ? cell.col : nl.offColor
                    gradient: nl.gloss ? cellGrad : null
                    Gradient {
                        id: cellGrad
                        GradientStop { position: 0; color: cell.on ? Qt.lighter(cell.col, 1.28) : Qt.lighter(nl.offColor, 1.15) }
                        GradientStop { position: 0.5; color: cell.on ? cell.col : nl.offColor }
                        GradientStop { position: 1; color: cell.on ? Qt.darker(cell.col, 1.22) : Qt.darker(nl.offColor, 1.15) }
                    }
                    Rectangle {
                        visible: nl.gloss
                        x: 2; y: 2; width: parent.width - 4; height: parent.height * 0.42; radius: Math.max(0, nl.radius - 1)
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, cell.on ? 0.38 : 0.06) }
                            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: cell.on ? nl.litText : nl.offText
                        font.pixelSize: Math.min(nl.fontSize, parent.height * 0.8)
                        font.bold: true
                    }
                }
            }
        }
    }
}

import QtQuick
import "../parts"
import "../parts/Util.js" as U

// シンプル・モダン: 落ち着いた暗い面に角丸のカード。計器はアナログ、文字は控えめに
Rectangle {
    id: root
    color: "#0d1014"
    readonly property var d: link.d
    readonly property var n: d.notch || ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    readonly property real speed: Math.abs(U.num(d.speed))
    readonly property bool rx: link.online
    readonly property bool over: U.has(d.limit) && speed > d.limit + 0.5
    readonly property real stopDist: d.stop ? U.num(d.stop.dist, NaN) : NaN

    readonly property color cCard: "#161a20"
    readonly property color cLine: "#232931"
    readonly property color cText: "#eef1f5"
    readonly property color cSub: "#8a93a0"
    readonly property color cMute: "#59626e"
    readonly property color cBlue: "#4c9dff"
    readonly property color cGreen: "#3ccf7a"
    readonly property color cOrange: "#ff9f43"
    readonly property color cRed: "#ff5a4f"
    readonly property color cYellow: "#ffc940"
    readonly property color notchColor: n.b > n.maxB ? cRed : n.b > 0 ? cOrange : n.p > 0 ? cGreen : cText
    readonly property color stopColor: isNaN(stopDist) ? cMute : Math.abs(stopDist) <= 0.5 ? cGreen : stopDist < 0 ? cRed : stopDist < 10 ? cYellow : cText

    property bool blinkPhase: true
    Timer { interval: 450; running: true; repeat: true; onTriggered: root.blinkPhase = !root.blinkPhase }

    component Card: Rectangle {
        id: cd
        property string title: ""
        property string note: ""
        default property alias content: body.data
        color: root.cCard; radius: 14
        Text { visible: cd.title.length > 0; x: 20; y: 16; text: cd.title; color: root.cSub; font.pixelSize: 16; font.letterSpacing: 1 }
        Text { visible: cd.note.length > 0; anchors.right: parent.right; anchors.rightMargin: 20; y: 16; text: cd.note; color: root.cSub; font.pixelSize: 16 }
        Item { id: body; anchors.fill: parent }
    }
    // 小さな計器のカード
    component GaugeCard: Card {
        id: gcard
        property alias gauge: mg
        ModernGauge {
            id: mg
            anchors.horizontalCenter: parent.horizontalCenter; y: 30
            width: Math.min(gcard.width - 24, gcard.height - 34); height: width
            valueSize: 0.26; dim: !root.rx
        }
    }
    // 1 行の項目
    component KV: Item {
        id: kv
        property string label: ""
        property string value: "—"
        property string unit: ""
        property color valueColor: root.cText
        height: 56
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.cLine }
        Text { anchors.verticalCenter: parent.verticalCenter; text: kv.label; color: root.cSub; font.pixelSize: 17 }
        Text {
            id: kvv; anchors.right: kvu.left; anchors.rightMargin: kvu.text.length ? 6 : 0; anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, kv.width - 130); elide: Text.ElideLeft; horizontalAlignment: Text.AlignRight
            text: kv.value; color: kv.valueColor; font.pixelSize: 24; font.weight: Font.DemiBold
        }
        Text { id: kvu; anchors.right: parent.right; anchors.baseline: kvv.baseline; text: kv.unit; color: root.cSub; font.pixelSize: 15 }
    }

    // ================= 上の帯 =================
    Item {
        x: 24; y: 16; width: 1552; height: 48
        Row {
            anchors.verticalCenter: parent.verticalCenter; spacing: 14
            Rectangle { width: 10; height: 10; radius: 5; anchors.verticalCenter: parent.verticalCenter; color: !rx ? root.cRed : !d.output ? root.cYellow : root.cGreen }
            Text { text: U.str(d.line, "—"); color: root.cText; font.pixelSize: 20; font.weight: Font.DemiBold }
            Text { text: U.str(d.train, "") + (d.cars ? "  ·  " + d.cars + "両" : ""); color: root.cSub; font.pixelSize: 18; anchors.baseline: parent.children[1].baseline }
        }
        Row {
            anchors.centerIn: parent; spacing: 10
            Text { text: d.at ? "停車中" : "次"; color: root.cSub; font.pixelSize: 18; anchors.baseline: ns.baseline }
            Text { id: ns; text: U.str(d.at || d.next); color: root.cText; font.pixelSize: 24; font.weight: Font.DemiBold }
            Text { text: d.at ? "" : U.dist(d.nextDist); color: root.cBlue; font.pixelSize: 18; anchors.baseline: ns.baseline }
        }
        Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 18
            Text { text: !rx ? "受信なし" : !d.output ? "出力OFF" : ""; color: !rx ? root.cRed : root.cYellow; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
            Clock { color: root.cText; font.pixelSize: 24; font.weight: Font.DemiBold }
        }
    }

    // ================= 速度 =================
    Card {
        title: "速度"; note: "km/h"
        x: 24; y: 80; width: 520; height: 500
        ModernGauge {
            anchors.horizontalCenter: parent.horizontalCenter; y: 40
            width: 440; height: 440
            minValue: 0; maxValue: U.num(d.speedMax, 120)
            majorStep: maxValue > 160 ? 40 : 20; minorStep: maxValue > 160 ? 10 : 5
            value: root.speed; limit: U.has(d.limit) ? d.limit : NaN
            zones: U.has(d.limit) ? [{ from: d.limit, to: maxValue, color: Qt.rgba(1, 0.35, 0.3, 0.6) }] : []
            valueText: rx && U.has(d.speed) ? Math.round(root.speed).toString() : "--"
            unit: "km/h"; accent: root.cBlue; valueSize: 0.28; thickness: 0.06
            dim: !rx
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; y: 452; height: 30; width: lim.implicitWidth + 28; radius: 15
            color: root.over ? Qt.rgba(1, 0.35, 0.3, 0.18) : Qt.rgba(1, 0.69, 0.13, 0.12)
            Text { id: lim; anchors.centerIn: parent; text: "制限 " + (U.has(d.limit) ? Math.round(d.limit) : "—"); color: root.over ? root.cRed : root.cYellow; font.pixelSize: 16; font.weight: Font.DemiBold }
        }
    }

    // ================= ノッチ =================
    Card {
        title: "ノッチ"; note: root.n.pending ? "送信待ち " + root.n.pending : "レバーサ " + U.revName(root.n.rev)
        x: 560; y: 80; width: 476; height: 242
        Text { x: 20; y: 46; text: U.notchName(root.n); color: root.notchColor; font.pixelSize: 54; font.weight: Font.DemiBold }
        Text { x: 20; y: 116; text: U.str(d.mode); color: root.cSub; font.pixelSize: 17 }
        // 段の並び (左が非常、右が力行)
        Row {
            x: 20; y: 164; spacing: 4
            Repeater {
                model: {
                    var a = [], maxP = root.n.maxP || 5, maxB = root.n.maxB || 8;
                    a.push({ k: "E", i: maxB + 1 });
                    for (var j = maxB; j >= 1; j--) a.push({ k: "B", i: j });
                    a.push({ k: "N", i: 0 });
                    for (var i = 1; i <= maxP; i++) a.push({ k: "P", i: i });
                    return a;
                }
                Rectangle {
                    readonly property int cnt: (root.n.maxP || 5) + (root.n.maxB || 8) + 2
                    readonly property bool on: modelData.k === "N" ? (root.n.p === 0 && root.n.b === 0)
                                             : modelData.k === "P" ? (root.n.b === 0 && root.n.p >= modelData.i)
                                             : modelData.k === "E" ? root.n.b > root.n.maxB
                                             : root.n.b >= modelData.i
                    width: (436 - 4 * (cnt - 1)) / cnt; height: modelData.k === "N" ? 34 : 26
                    y: modelData.k === "N" ? 0 : 4
                    radius: 4
                    color: on ? (modelData.k === "P" ? root.cGreen : modelData.k === "N" ? root.cText : modelData.k === "E" ? root.cRed : root.cOrange) : root.cLine
                }
            }
        }
        Item {
            x: 20; y: 206; width: 436; height: 18
            Text { text: "EB"; color: root.cMute; font.pixelSize: 13 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.horizontalCenterOffset: ((root.n.maxP || 5) - (root.n.maxB || 8) - 1) * 436 / ((root.n.maxP || 5) + (root.n.maxB || 8) + 2) / 2; text: "N"; color: root.cMute; font.pixelSize: 13 }
            Text { anchors.right: parent.right; text: "P" + (root.n.maxP || 5); color: root.cMute; font.pixelSize: 13 }
        }
    }

    // ================= 停止位置 =================
    Card {
        title: "停止位置まで"; note: d.stop ? U.str(d.stop.station) + (d.stop.marker ? "  " + d.stop.marker : "") : ""
        x: 560; y: 338; width: 476; height: 242
        Row {
            x: 20; y: 44; spacing: 8
            Text { id: sdv; text: U.distNum(root.stopDist); color: root.stopColor; font.pixelSize: 54; font.weight: Font.DemiBold }
            Text { text: U.distUnit(root.stopDist); color: root.cSub; font.pixelSize: 18; anchors.baseline: sdv.baseline }
        }
        StopTape {
            x: 20; y: 132; width: 436; height: 72
            dist: root.stopDist; range: 10; fontSize: 13
            bg: "#1c2128"; tickColor: root.cMute; markerColor: root.cText
            okColor: root.cGreen; nearColor: root.cYellow; overColor: root.cRed
        }
    }

    // ================= 小さな計器 (2 × 2) =================
    GaugeCard {
        title: "空気圧"; note: "BC / MR kPa"
        x: 1052; y: 80; width: 254; height: 242
        gauge.minValue: 0; gauge.maxValue: Math.max(1000, Math.ceil((U.num(d.mrMax, 880) + 50) / 200) * 200)
        gauge.majorStep: 200; gauge.minorStep: 100
        gauge.value: U.num(d.bc); gauge.value2: U.num(d.mr)
        gauge.accent: root.cOrange
        gauge.zones: [{ from: U.num(d.mrMin, 780), to: U.num(d.mrMax, 880), color: Qt.rgba(1, 1, 1, 0.45) }]
        gauge.valueText: Math.round(U.num(d.bc)).toString()
        gauge.unit: "MR " + Math.round(U.num(d.mr))
    }
    GaugeCard {
        title: U.num(d.current) < -1 ? "回生電流" : "電流"; note: "A"
        x: 1322; y: 80; width: 254; height: 242
        gauge.minValue: -U.num(d.currentMax, 600); gauge.maxValue: U.num(d.currentMax, 600)
        gauge.majorStep: gauge.maxValue > 400 ? 300 : 200; gauge.minorStep: gauge.majorStep / 2
        gauge.value: U.num(d.current)
        gauge.accent: root.cGreen; gauge.negAccent: root.cBlue
        gauge.valueText: Math.round(U.num(d.current)).toString()
        gauge.unit: U.num(d.regen) > 0.01 ? "回生 " + Math.round(U.num(d.regen) * 100) + "%" : ""
    }
    GaugeCard {
        title: "架線電圧"; note: "kV"
        x: 1052; y: 338; width: 254; height: 242
        gauge.minValue: 0; gauge.maxValue: Math.ceil(U.num(d.voltNominal, 1500) * 4 / 3 / 100) * 100
        gauge.majorStep: 500; gauge.minorStep: 250; gauge.labelDivisor: 1000; gauge.labelDecimals: 1
        gauge.value: U.num(d.volt)
        gauge.accent: "#8f7bff"
        gauge.valueText: (U.num(d.volt) / 1000).toFixed(2)
    }
    GaugeCard {
        title: "加速度"; note: "km/h/s"
        x: 1322; y: 338; width: 254; height: 242
        gauge.minValue: -5; gauge.maxValue: 5; gauge.majorStep: 5; gauge.minorStep: 1
        gauge.value: U.num(d.accel)
        gauge.accent: root.cGreen; gauge.negAccent: root.cOrange
        gauge.valueText: U.sign(d.accel, 1)
    }

    // ================= 運行情報 =================
    Card {
        title: "運行情報"
        x: 24; y: 596; width: 1012; height: 284
        Grid {
            x: 20; y: 44; columns: 2; columnSpacing: 40; rowSpacing: 0
            KV { width: 466; label: d.at ? "停車中" : "次駅"; value: U.str(d.at || d.next); unit: d.at ? "" : U.dist(d.nextDist) }
            KV { width: 466; label: "現在地"; value: d.at ? d.at + " 構内" : (d.prev && d.next ? d.prev + " → " + d.next : "—") }
            KV { width: 466; label: "制限速度"; value: U.has(d.limit) ? Math.round(d.limit) : "—"; unit: U.has(d.limit) ? "km/h" : ""; valueColor: root.over ? root.cRed : root.cYellow }
            KV { width: 466; label: "分岐"; value: d.switch ? d.switch.way : "—"; unit: d.switch ? Math.round(d.switch.dist) + " m" : ""; valueColor: d.switch && d.switch.conflict ? root.cRed : root.cText }
            KV { width: 466; label: "運転モード"; value: U.str(d.mode); valueColor: root.notchColor }
            KV { width: 466; label: "回生"; value: U.num(d.regen) > 0.01 ? Math.round(U.num(d.regen) * 100) : "—"; unit: U.num(d.regen) > 0.01 ? "%" : ""; valueColor: root.cBlue }
            KV { width: 466; label: "編成"; value: U.str(d.train ? String(d.train).split(" ")[0] : null); unit: (d.cars ? d.cars + "両" : "") + (d.cab === "secondary" ? " B側" : d.cab === "main" ? " A側" : "") }
            KV { width: 466; label: "停止目標"; value: d.stop ? U.str(d.stop.station) + (d.stop.marker ? " " + d.stop.marker : "") : "—" }
        }
    }

    // ================= 状態 =================
    Card {
        title: "状態"
        x: 1052; y: 596; width: 524; height: 284
        Grid {
            id: st
            x: 20; y: 48; columns: 2; columnSpacing: 12; rowSpacing: 10
            readonly property bool ph: root.blinkPhase
            Repeater {
                model: [
                    { t: "力行", on: root.n.p > 0 && root.n.b === 0, c: root.cGreen },
                    { t: "回生", on: U.num(d.regen) > 0.01, c: root.cBlue },
                    { t: "ブレーキ", on: U.num(d.bc) > 20, c: root.cOrange },
                    { t: "非常", on: !!d.emergency, c: root.cRed, b: true },
                    { t: "CP 運転", on: !!d.cp, c: root.cYellow },
                    { t: "速度超過", on: root.over, c: root.cRed, b: true },
                    { t: "定位置", on: !isNaN(root.stopDist) && Math.abs(root.stopDist) <= 0.5 && root.speed < 0.5, c: root.cGreen },
                    { t: "受信", on: root.rx, c: root.cBlue },
                ]
                Rectangle {
                    width: 236; height: 46; radius: 10
                    readonly property bool lit: modelData.on && (!modelData.b || st.ph)
                    color: lit ? Qt.rgba(modelData.c.r, modelData.c.g, modelData.c.b, 0.16) : "#1c2128"
                    border.color: lit ? Qt.rgba(modelData.c.r, modelData.c.g, modelData.c.b, 0.55) : "transparent"
                    Rectangle { x: 16; anchors.verticalCenter: parent.verticalCenter; width: 10; height: 10; radius: 5; color: parent.lit ? modelData.c : root.cMute }
                    Text { x: 38; anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: parent.lit ? root.cText : root.cMute; font.pixelSize: 18; font.weight: parent.lit ? Font.DemiBold : Font.Normal }
                }
            }
        }
    }
}

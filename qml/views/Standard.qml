import QtQuick
import "../parts"
import "../parts/Util.js" as U

// 標準: 上段に 速度計・ノッチと停止位置・小さな計器 4 つ、下段に運行情報と状態
Item {
    id: v
    readonly property var d: link.d
    readonly property var n: d.notch || ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    readonly property real speed: Math.abs(U.num(d.speed))
    readonly property bool rx: link.online
    readonly property bool over: U.has(d.limit) && speed > d.limit + 0.5
    readonly property real stopDist: d.stop ? U.num(d.stop.dist, NaN) : NaN
    readonly property color notchColor: n.b > n.maxB ? Pal.red : n.b > 0 ? Pal.orange : n.p > 0 ? Pal.green : Pal.text
    readonly property color stopColor: isNaN(stopDist) ? Pal.mute : Math.abs(stopDist) <= 0.5 ? Pal.green : stopDist < 0 ? Pal.red : stopDist < 10 ? Pal.yellow : Pal.text
    property bool phase: true
    Timer { interval: 500; running: true; repeat: true; onTriggered: v.phase = !v.phase }

    // ================= 速度 =================
    Card {
        title: "速度"; note: "km/h"
        x: 0; y: 0; width: 552; height: 476
        ModernGauge {
            anchors.horizontalCenter: parent.horizontalCenter; y: 36
            width: 410; height: 410
            minValue: 0; maxValue: U.num(d.speedMax, 120)
            majorStep: maxValue > 160 ? 40 : 20; minorStep: maxValue > 160 ? 10 : 5
            value: v.speed; limit: U.has(d.limit) ? d.limit : NaN
            zones: U.has(d.limit) ? [{ from: d.limit, to: maxValue, color: Qt.rgba(Pal.red.r, Pal.red.g, Pal.red.b, 0.7) }] : []
            valueText: rx && U.has(d.speed) ? Math.round(v.speed).toString() : "--"
            unit: "km/h"; valueColor: v.over ? Pal.red : Pal.text
            accent: Pal.blue; track: Pal.track; tickColor: Pal.tick; labelColor: Pal.sub; needleColor: Pal.needle; hubInner: Pal.card; limitColor: Pal.yellow
            valueSize: 0.27; thickness: 0.06; dim: !rx
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; y: 424; height: 38; width: lim.implicitWidth + 36; radius: 19
            color: v.over ? Qt.rgba(Pal.red.r, Pal.red.g, Pal.red.b, 0.16) : Pal.raised
            Text { id: lim; anchors.centerIn: parent; text: "制限  " + (U.has(d.limit) ? Math.round(d.limit) + " km/h" : "—"); color: v.over ? Pal.red : Pal.yellow; font.pixelSize: 19 * Pal.ts; font.weight: Font.DemiBold }
        }
    }

    // ================= ノッチ =================
    Card {
        title: "ノッチ"; note: n.pending ? "送信待ち " + n.pending : "レバーサ " + U.revName(n.rev)
        noteColor: n.pending ? Pal.yellow : Pal.sub
        x: 568; y: 0; width: 452; height: 230
        Row {
            x: 22; y: 48; spacing: 14
            Text { id: nn; text: U.notchName(v.n); color: v.notchColor; font.pixelSize: 50 * Pal.ts; font.weight: Font.DemiBold }
            Text { text: U.str(d.mode); color: Pal.sub; font.pixelSize: 20 * Pal.ts; anchors.baseline: nn.baseline }
        }
        NotchBar { x: 22; y: 128; width: 408; height: 82; n: v.n }
    }

    // ================= 停止位置 =================
    Card {
        title: "停止位置まで"; note: d.stop ? U.str(d.stop.station) + (d.stop.marker ? "  " + d.stop.marker : "") : ""
        x: 568; y: 246; width: 452; height: 230
        Row {
            x: 22; y: 46; spacing: 8
            Text { id: sd; text: U.distNum(v.stopDist); color: v.stopColor; font.pixelSize: 50 * Pal.ts; font.weight: Font.DemiBold }
            Text { text: U.distUnit(v.stopDist); color: Pal.sub; font.pixelSize: 20 * Pal.ts; anchors.baseline: sd.baseline }
        }
        StopTape {
            x: 22; y: 128; width: 408; height: 76
            dist: v.stopDist; range: 10; fontSize: 15 * Pal.ts
            bg: Pal.raised; tickColor: Pal.tick; markerColor: Pal.text
            okColor: Pal.green; nearColor: Pal.yellow; overColor: Pal.red
        }
    }

    // ================= 小さな計器 (2 × 2) =================
    GaugeCard {
        title: "空気圧 kPa"; note: "BC"
        x: 1036; y: 0; width: 250; height: 230
        gauge.minValue: 0; gauge.maxValue: Math.max(1000, Math.ceil((U.num(d.mrMax, 880) + 50) / 200) * 200)
        gauge.majorStep: 500; gauge.minorStep: 100
        gauge.value: U.num(d.bc); gauge.value2: U.num(d.mr)
        gauge.accent: Pal.orange
        gauge.zones: [{ from: U.num(d.mrMin, 780), to: U.num(d.mrMax, 880), color: Pal.sub }]
        gauge.valueText: rx ? Math.round(U.num(d.bc)).toString() : "--"
        gauge.unit: "MR " + Math.round(U.num(d.mr))
        gauge.dim: !rx
    }
    GaugeCard {
        title: U.num(d.current) < -1 ? "回生電流 A" : "電流 A"
        x: 1302; y: 0; width: 250; height: 230
        gauge.minValue: -U.num(d.currentMax, 600); gauge.maxValue: U.num(d.currentMax, 600)
        gauge.majorStep: gauge.maxValue; gauge.minorStep: gauge.maxValue / 3
        gauge.value: U.num(d.current)
        gauge.accent: Pal.green; gauge.negAccent: Pal.blue
        gauge.valueText: rx ? Math.round(U.num(d.current)).toString() : "--"
        gauge.dim: !rx
    }
    GaugeCard {
        title: "架線電圧 kV"
        x: 1036; y: 246; width: 250; height: 230
        gauge.minValue: 0; gauge.maxValue: Math.ceil(U.num(d.voltNominal, 1500) * 4 / 3 / 100) * 100
        gauge.majorStep: 1000; gauge.minorStep: 250; gauge.labelDivisor: 1000; gauge.labelDecimals: 0
        gauge.value: U.num(d.volt)
        gauge.accent: Pal.purple
        gauge.valueText: rx ? (U.num(d.volt) / 1000).toFixed(2) : "--"
        gauge.dim: !rx
    }
    GaugeCard {
        title: "加速度"
        x: 1302; y: 246; width: 250; height: 230
        gauge.minValue: -5; gauge.maxValue: 5; gauge.majorStep: 5; gauge.minorStep: 1
        note: "km/h/s"
        gauge.value: U.num(d.accel)
        gauge.accent: Pal.green; gauge.negAccent: Pal.orange
        gauge.valueText: U.sign(d.accel, 1)
        gauge.dim: !rx
    }

    // ================= 運行情報 =================
    Card {
        title: "運行情報"
        x: 0; y: 492; width: 1020; height: 304
        Grid {
            x: 22; y: 50; columns: 2; columnSpacing: 40
            KV { width: 466; label: d.at ? "停車中" : "次駅"; value: U.str(d.at || d.next); unit: d.at ? "" : U.dist(d.nextDist) }
            KV { width: 466; label: "現在地"; value: d.at ? d.at + " 構内" : (d.prev && d.next ? d.prev + " → " + d.next : "—") }
            KV { width: 466; label: "制限速度"; value: U.has(d.limit) ? Math.round(d.limit) : "—"; unit: U.has(d.limit) ? "km/h" : ""; valueColor: v.over ? Pal.red : Pal.yellow }
            KV { width: 466; label: "分岐"; value: d.switch ? d.switch.way : "—"; unit: d.switch ? Math.round(d.switch.dist) + " m" : ""; valueColor: d.switch && d.switch.conflict ? Pal.red : Pal.text }
            KV { width: 466; label: "架線電圧"; value: rx ? (U.num(d.volt) / 1000).toFixed(2) : "—"; unit: "kV" }
            KV { width: 466; label: "回生"; value: U.num(d.regen) > 0.01 ? Math.round(U.num(d.regen) * 100) : "—"; unit: U.num(d.regen) > 0.01 ? "%" : ""; valueColor: Pal.blue }
            KV { width: 466; last: true; label: "編成"; value: U.str(d.train ? String(d.train).split(" ")[0] : null); unit: (d.cars ? d.cars + "両" : "") + (d.cab === "secondary" ? " B側" : d.cab === "main" ? " A側" : "") }
            KV { width: 466; last: true; label: "停止目標"; value: d.stop ? U.str(d.stop.station) + (d.stop.marker ? " " + d.stop.marker : "") : "—" }
        }
    }

    // ================= 状態 =================
    Card {
        title: "状態"
        x: 1036; y: 492; width: 516; height: 304
        Grid {
            x: 18; y: 52; columns: 2; columnSpacing: 12; rowSpacing: 10
            StatusChip { width: 234; height: 50; text: "力行"; on: n.p > 0 && n.b === 0; lit: Pal.green }
            StatusChip { width: 234; height: 50; text: "回生"; on: U.num(d.regen) > 0.01; lit: Pal.blue }
            StatusChip { width: 234; height: 50; text: "ブレーキ"; on: U.num(d.bc) > 20; lit: Pal.orange }
            StatusChip { width: 234; height: 50; text: "非常"; on: !!d.emergency; lit: Pal.red; blink: true }
            StatusChip { width: 234; height: 50; text: "CP 運転"; on: !!d.cp; lit: Pal.yellow }
            StatusChip { width: 234; height: 50; text: "速度超過"; on: v.over; lit: Pal.red; blink: true }
            StatusChip { width: 234; height: 50; text: "定位置"; on: !isNaN(v.stopDist) && Math.abs(v.stopDist) <= 0.5 && v.speed < 0.5; lit: Pal.green }
            StatusChip { width: 234; height: 50; text: link.demo ? "デモ走行" : "受信"; on: v.rx; lit: Pal.blue }
        }
    }
}

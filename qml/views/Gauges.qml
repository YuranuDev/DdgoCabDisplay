import QtQuick
import "../parts"
import "../parts/Util.js" as U

// 計器重視: 中央に大きな速度計、左にノッチ、右に空気圧・電流と停止位置・次駅
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

    // ================= ノッチ (縦) =================
    Card {
        title: "ノッチ"
        x: 0; y: 0; width: 280; height: 796
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; y: 50
            text: U.notchName(v.n); color: v.notchColor; font.pixelSize: 52 * Pal.ts; font.weight: Font.DemiBold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; y: 122
            text: U.str(d.mode); color: Pal.sub; font.pixelSize: 19 * Pal.ts
        }
        NotchLadder {
            x: 44; y: 166; width: 192; height: 540
            n: v.n; gap: 5; radius: 8; fontSize: 18 * Pal.ts
            powerColor: Pal.green; brakeColor: Pal.orange; ebColor: Pal.red; neutralColor: Pal.text
            offColor: Pal.raised; offText: Pal.mute; litText: Pal.onAccent; frameColor: "transparent"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 26
            text: n.pending ? "送信待ち " + n.pending : "レバーサ  " + U.revName(n.rev)
            color: n.pending ? Pal.yellow : Pal.sub; font.pixelSize: 19 * Pal.ts
        }
    }

    // ================= 速度計 (大) =================
    Card {
        title: "速度"; note: "km/h"
        x: 296; y: 0; width: 660; height: 796
        ModernGauge {
            anchors.horizontalCenter: parent.horizontalCenter; y: 60
            width: 600; height: 600
            minValue: 0; maxValue: U.num(d.speedMax, 120)
            majorStep: maxValue > 160 ? 40 : 20; minorStep: maxValue > 160 ? 10 : 5
            value: v.speed; limit: U.has(d.limit) ? d.limit : NaN
            zones: U.has(d.limit) ? [{ from: d.limit, to: maxValue, color: Qt.rgba(Pal.red.r, Pal.red.g, Pal.red.b, 0.7) }] : []
            valueText: rx && U.has(d.speed) ? Math.round(v.speed).toString() : "--"
            unit: "km/h"; valueColor: v.over ? Pal.red : Pal.text
            accent: Pal.blue; track: Pal.track; tickColor: Pal.tick; labelColor: Pal.sub; needleColor: Pal.needle; hubInner: Pal.card; limitColor: Pal.yellow
            valueSize: 0.25; thickness: 0.055; dim: !rx
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; y: 688; spacing: 16
            Rectangle {
                height: 64; width: 260; radius: 14; color: v.over ? Qt.rgba(Pal.red.r, Pal.red.g, Pal.red.b, 0.16) : Pal.raised
                Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: "制限"; color: Pal.sub; font.pixelSize: 18 * Pal.ts }
                Text { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; text: U.has(d.limit) ? Math.round(d.limit) + " km/h" : "—"; color: v.over ? Pal.red : Pal.yellow; font.pixelSize: 26 * Pal.ts; font.weight: Font.DemiBold }
            }
            Rectangle {
                height: 64; width: 280; radius: 14; color: Pal.raised
                Column {
                    x: 20; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "加速度"; color: Pal.sub; font.pixelSize: 18 * Pal.ts }
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter
                    text: U.sign(d.accel, 1) + " km/h/s"
                    color: U.num(d.accel) < -0.05 ? Pal.orange : U.num(d.accel) > 0.05 ? Pal.green : Pal.text; font.pixelSize: 26 * Pal.ts; font.weight: Font.DemiBold
                }
            }
        }
    }

    // ================= 右: 空気圧・電流 =================
    GaugeCard {
        title: "空気圧 kPa"; note: "BC"
        x: 972; y: 0; width: 282; height: 330
        gauge.minValue: 0; gauge.maxValue: Math.max(1000, Math.ceil((U.num(d.mrMax, 880) + 50) / 200) * 200)
        gauge.majorStep: 200; gauge.minorStep: 100
        gauge.value: U.num(d.bc); gauge.value2: U.num(d.mr)
        gauge.accent: Pal.orange
        gauge.zones: [{ from: U.num(d.mrMin, 780), to: U.num(d.mrMax, 880), color: Pal.sub }]
        gauge.valueText: rx ? Math.round(U.num(d.bc)).toString() : "--"
        gauge.unit: "MR " + Math.round(U.num(d.mr))
        gauge.dim: !rx
    }
    GaugeCard {
        title: U.num(d.current) < -1 ? "回生電流 A" : "電流 A"; note: (U.num(d.volt) / 1000).toFixed(2) + " kV"
        x: 1270; y: 0; width: 282; height: 330
        gauge.minValue: -U.num(d.currentMax, 600); gauge.maxValue: U.num(d.currentMax, 600)
        gauge.majorStep: gauge.maxValue > 400 ? 300 : 200; gauge.minorStep: gauge.majorStep / 2
        gauge.value: U.num(d.current)
        gauge.accent: Pal.green; gauge.negAccent: Pal.blue
        gauge.valueText: rx ? Math.round(U.num(d.current)).toString() : "--"
        gauge.dim: !rx
    }

    // ================= 右: 停止位置 =================
    Card {
        title: "停止位置まで"; note: d.stop ? U.str(d.stop.station) + (d.stop.marker ? "  " + d.stop.marker : "") : ""
        x: 972; y: 346; width: 580; height: 220
        Row {
            x: 22; y: 44; spacing: 8
            Text { id: sd; text: U.distNum(v.stopDist); color: v.stopColor; font.pixelSize: 48 * Pal.ts; font.weight: Font.DemiBold }
            Text { text: U.distUnit(v.stopDist); color: Pal.sub; font.pixelSize: 20 * Pal.ts; anchors.baseline: sd.baseline }
        }
        StopTape {
            x: 22; y: 124; width: 536; height: 72
            dist: v.stopDist; range: 10; fontSize: 15 * Pal.ts
            bg: Pal.raised; tickColor: Pal.tick; markerColor: Pal.text
            okColor: Pal.green; nearColor: Pal.yellow; overColor: Pal.red
        }
    }

    // ================= 右: 運行情報 =================
    Card {
        title: "運行情報"
        x: 972; y: 582; width: 580; height: 214
        Column {
            x: 22; y: 44; width: 536
            KV { width: parent.width; label: d.at ? "停車中" : "次駅"; value: U.str(d.at || d.next); unit: d.at ? "" : U.dist(d.nextDist) }
            KV { width: parent.width; label: "分岐"; value: d.switch ? d.switch.way : "—"; unit: d.switch ? Math.round(d.switch.dist) + " m" : ""; valueColor: d.switch && d.switch.conflict ? Pal.red : Pal.text }
            KV { width: parent.width; last: true; label: "状態"; value: d.cp ? "CP 運転" : U.num(d.regen) > 0.01 ? "回生 " + Math.round(U.num(d.regen) * 100) + "%" : "—" }
        }
    }
}

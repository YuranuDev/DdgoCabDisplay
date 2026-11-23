import QtQuick
import "../parts"
import "../parts/Util.js" as U

// グラスコックピット風 (E235 系 / 新幹線 E7 系のように速度計も液晶で描く)
Rectangle {
    id: root
    readonly property var d: link.d
    readonly property var n: d.notch || ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    readonly property real speed: Math.abs(U.num(d.speed))
    readonly property bool rx: link.online
    readonly property bool over: U.has(d.limit) && speed > d.limit + 0.5
    readonly property color cCyan: "#38d6ff"
    readonly property color cPower: "#3cf08a"
    readonly property color cBrake: "#ffa23a"
    readonly property color cSub: "#8ea3b8"

    color: "#070c14"

    component Panel: Rectangle {
        id: pnl
        property string title: ""
        radius: 14
        color: "#0e1623"
        border.color: "#1c2a3d"; border.width: 1
        Text { visible: pnl.title.length > 0; x: 20; y: 14; text: pnl.title; color: root.cSub; font.pixelSize: 15; font.letterSpacing: 2 }
    }
    component Chip: Rectangle {
        property string text: ""
        property bool on: false
        property color lit: root.cCyan
        height: 34; width: Math.max(76, label.implicitWidth + 28); radius: 17
        color: on ? Qt.rgba(lit.r, lit.g, lit.b, 0.18) : "transparent"
        border.color: on ? Qt.rgba(lit.r, lit.g, lit.b, 0.6) : Qt.rgba(1, 1, 1, 0.12); border.width: 1

        Text { id: label; anchors.centerIn: parent; text: parent.text; color: parent.on ? parent.lit : Qt.rgba(1, 1, 1, 0.3); font.pixelSize: 16; font.weight: Font.DemiBold }
    }

    // ================= 上の帯 =================
    Item {
        width: parent.width; height: 70
        Row {
            x: 26; anchors.verticalCenter: parent.verticalCenter; spacing: 18
            Text { text: U.str(d.train, "----"); color: "white"; font.pixelSize: 24; font.weight: Font.DemiBold }
            Text { text: U.str(d.line, ""); color: root.cSub; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            anchors.centerIn: parent; spacing: 10
            Chip { text: "力行"; on: root.n.p > 0 && root.n.b === 0; lit: root.cPower }
            Chip { text: "回生"; on: U.num(d.regen) > 0.01; lit: "#66b8ff" }
            Chip { text: "ブレーキ"; on: U.num(d.bc) > 20; lit: root.cBrake }
            Chip { text: "非常"; on: !!d.emergency; lit: "#ff3b30" }
            Chip { text: "CP"; on: !!d.cp; lit: "#ffe14d" }
            Chip { text: "ATC"; on: U.has(d.limit); lit: root.cCyan }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 26; anchors.verticalCenter: parent.verticalCenter; spacing: 20
            Text { text: rx ? (d.output ? "● 受信中" : "● 出力OFF") : "● 受信なし"; color: rx ? (d.output ? root.cPower : "#ffc040") : "#ff5050"; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
            Clock { color: "white"; font.pixelSize: 26; font.weight: Font.DemiBold }
        }
        Rectangle { anchors.bottom: parent.bottom; x: 24; width: parent.width - 48; height: 1; color: "#1c2a3d" }
    }

    // ================= ノッチ =================
    Panel {
        title: "MASCON"
        x: 22; y: 88; width: 250; height: 790
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; y: 42
            text: U.notchName(root.n)
            color: root.n.b > root.n.maxB ? "#ff3b30" : root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : "white"
            font.pixelSize: 52; font.weight: Font.DemiBold
        }
        NotchLadder {
            x: 56; y: 140; width: parent.width - 112; height: 560
            n: root.n; gap: 5; radius: 6; fontSize: 16
            powerColor: root.cPower; brakeColor: root.cBrake; neutralColor: "#dfe9f3"
            offColor: Qt.rgba(1, 1, 1, 0.05); offText: Qt.rgba(1, 1, 1, 0.28)
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 26
            text: "REV  " + U.revName(root.n.rev); color: root.cSub; font.pixelSize: 18 }
    }

    // ================= 速度計 =================
    Item {
        x: 290; y: 80; width: 640; height: 640
        ModernGauge {
            anchors.fill: parent
            minValue: 0; maxValue: U.num(d.speedMax, 120)
            majorStep: maxValue > 160 ? 40 : 20; minorStep: maxValue > 160 ? 10 : 5
            value: root.speed; limit: U.has(d.limit) ? d.limit : NaN
            zones: U.has(d.limit) ? [{ from: d.limit, to: maxValue, color: Qt.rgba(1, 0.3, 0.25, 0.7) }] : []
            valueText: rx && U.has(d.speed) ? Math.round(root.speed).toString() : "--"
            unit: "km/h   制限 " + (U.has(d.limit) ? Math.round(d.limit) : "--")
            accent: root.cCyan; track: "#132036"; tickColor: "#33465f"; labelColor: "#8ea3b8"; limitColor: "#ffa000"
            valueSize: 0.27; thickness: 0.065; dim: !rx
        }
    }

    // ================= 停止位置 =================
    Panel {
        title: "停止位置"
        x: 290; y: 730; width: 640; height: 148
        Text { x: 18; y: 42; text: U.str(d.stop ? d.stop.station : null) + (d.stop && d.stop.marker ? "  " + d.stop.marker : ""); color: "white"; font.pixelSize: 20; font.weight: Font.DemiBold }
        Text {
            id: sdv
            readonly property real v: d.stop ? U.num(d.stop.dist, NaN) : NaN
            anchors.right: parent.right; anchors.rightMargin: 60; y: 14
            text: U.distNum(v)
            color: isNaN(v) ? "#55606c" : Math.abs(v) <= 0.5 ? root.cPower : v < 0 ? "#ff3b30" : v < 10 ? "#ffe14d" : "white"
            font.pixelSize: 52; font.weight: Font.DemiBold
        }
        Text { anchors.left: sdv.right; anchors.leftMargin: 8; anchors.baseline: sdv.baseline; text: U.distUnit(sdv.v); color: root.cSub; font.pixelSize: 24 }
        StopTape {
            x: 18; y: 92; width: parent.width - 36; height: 46
            dist: sdv.v; range: 10; showLabels: false
            bg: Qt.rgba(1, 1, 1, 0.05); tickColor: Qt.rgba(1, 1, 1, 0.4); okColor: root.cPower
        }
    }

    // ================= 空気圧・電流 =================
    Panel {
        title: "BRAKE  kPa"
        x: 950; y: 88; width: 370; height: 390
        ModernGauge {
            x: 35; y: 50; width: 300; height: 300
            minValue: 0; maxValue: Math.max(1000, Math.ceil((U.num(d.mrMax, 880) + 50) / 200) * 200)
            majorStep: 200; minorStep: 100
            value: U.num(d.bc); value2: U.num(d.mr)
            accent: root.cBrake; track: "#16233a"; tickColor: "#33465f"; labelColor: "#7f93aa"
            zones: [{ from: U.num(d.mrMin, 780), to: U.num(d.mrMax, 880), color: Qt.rgba(1, 1, 1, 0.45) }]
            valueText: rx ? Math.round(U.num(d.bc)).toString() : "--"
            unit: "BC   MR " + Math.round(U.num(d.mr))
            valueSize: 0.24; dim: !rx
        }
    }
    Panel {
        title: "MOTOR  A"
        x: 950; y: 490; width: 370; height: 388
        ModernGauge {
            x: 35; y: 50; width: 300; height: 300
            minValue: -U.num(d.currentMax, 600); maxValue: U.num(d.currentMax, 600)
            majorStep: maxValue > 400 ? 300 : 200; minorStep: majorStep / 2
            value: U.num(d.current)
            accent: root.cPower; negAccent: "#66b8ff"; track: "#16233a"; tickColor: "#33465f"; labelColor: "#7f93aa"
            valueText: rx ? Math.round(U.num(d.current)).toString() : "--"
            unit: (U.num(d.current) < -1 ? "回生" : "力行") + "   " + (U.num(d.volt) / 1000).toFixed(2) + " kV"
            valueSize: 0.24; dim: !rx
        }
    }

    // ================= 次駅・路線 =================
    Panel {
        title: d.at ? "停車中" : "NEXT"
        x: 1338; y: 88; width: 240; height: 790
        Text { x: 18; y: 40; width: parent.width - 36; text: U.str(d.at || d.next); color: "white"; font.pixelSize: 34; font.weight: Font.DemiBold; elide: Text.ElideRight }
        Text { x: 18; y: 102; text: d.at ? "" : U.dist(d.nextDist); color: root.cCyan; font.pixelSize: 22 }
        RouteStrip {
            x: 6; y: 150; width: parent.width - 12; height: 600
            items: d.ahead || []; stopDist: d.stop ? U.num(d.stop.dist, NaN) : NaN
            stationColor: root.cCyan; railColor: Qt.rgba(0.5, 0.75, 1, 0.5); fontSize: 18
        }
        Text { x: 18; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; text: "加速度 " + U.sign(d.accel, 1) + " km/h/s"; color: root.cSub; font.pixelSize: 16 }
    }
}

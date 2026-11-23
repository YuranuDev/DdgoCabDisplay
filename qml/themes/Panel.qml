import QtQuick
import "../parts"
import "../parts/Util.js" as U

// 計器盤: DdgoMascon の別モニター表示 (CabDisplayWindow) と同じ並び。
// ヘアライン仕上げの金属パネルに、クロームの縁の計器・宝石形の表示灯・彫り込みの銘板・運転情報モニター
Rectangle {
    id: root
    color: "#15181c"
    readonly property var d: link.d
    readonly property var n: d.notch || ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    readonly property real speed: Math.abs(U.num(d.speed))
    readonly property bool rx: link.online
    readonly property bool over: U.has(d.limit) && speed > d.limit + 0.5
    readonly property color cScreen: "#03101a"
    readonly property color cAccent: "#1aa260"
    readonly property color cPower: "#33dd66"
    readonly property color cBrake: "#ff9a2e"
    readonly property color cLabel: "#9fb4c8"

    // 計器の名前
    component Plate: Item {
        id: pl
        property string text: ""
        height: 28
        Text { anchors.centerIn: parent; text: pl.text; color: "#aeb7c2"; font.pixelSize: 16 }
    }
    // 運転情報モニターの欄
    component Tile: Rectangle {
        id: tl
        property string label: ""
        property string value: "—"
        property string note: ""
        property color valueColor: "white"
        height: 72; radius: 8
        color: "#1b2027"
        Text { x: 14; y: 8; text: tl.label; color: root.cLabel; font.pixelSize: 15 }
        Text {
            x: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 3; width: tl.width - 24; elide: Text.ElideRight
            textFormat: Text.StyledText
            text: tl.value + (tl.note.length ? " <font color='#8a93a0' size='2'>" + tl.note + "</font>" : "")
            color: tl.valueColor; font.pixelSize: 24; font.weight: Font.DemiBold
        }
    }
    // 計器 + 銘板
    component Meter: Column {
        id: mt
        property alias gauge: g
        property string plate: ""
        property real size: 200
        property real slot: 300
        spacing: 6
        Item { width: 1; height: (mt.slot - mt.size) / 2 }
        ArcGauge {
            id: g
            anchors.horizontalCenter: parent.horizontalCenter
            width: mt.size; height: mt.size
            bezel: "none"; screws: false; glass: false; flat: true
            faceColor: "#1b2027"; rimColor: "#1b2027"
            tickColor: "#c9d0d8"; labelColor: "#c9d0d8"; needleColor: "#ff6a3d"; needle2Color: "#e8ecf0"; hubColor: "#1b2027"
            labelScale: 0.85
            dim: !root.rx
        }
        Item { width: 1; height: Math.max(0, (mt.slot - mt.size) / 2 - 6) }
        Plate { width: Math.max(150, mt.size); anchors.horizontalCenter: parent.horizontalCenter; text: mt.plate }
    }

    // ================= 上の帯 =================
    Rectangle {
        width: parent.width; height: 88; color: "#101317"
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 3; color: root.cAccent }
        Column {
            x: 22; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -2; width: 400
            Text { width: parent.width; elide: Text.ElideRight; text: U.str(d.line, "路線 —"); color: "white"; font.pixelSize: 24; font.weight: Font.DemiBold }
            Text { width: parent.width; elide: Text.ElideRight; text: U.str(d.train, "") + (d.cars ? "   " + d.cars + "両" : ""); color: "#9aa4af"; font.pixelSize: 16 }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.horizontalCenterOffset: 10; y: 14; spacing: 16
            Repeater {
                model: [
                    { t: "力行", on: root.n.p > 0 && root.n.b === 0, c: root.cPower },
                    { t: "ブレーキ", on: U.num(d.bc) > 20, c: root.cBrake },
                    { t: "回生", on: U.num(d.regen) > 0.01, c: "#5fb0ff" },
                    { t: "非常", on: !!d.emergency, c: "#ff3b30", b: true },
                    { t: "CP", on: !!d.cp, c: "#ffd23f" },
                    { t: "速度超過", on: root.over, c: "#ff3b30", b: true },
                    { t: "定位置", on: !!d.stop && U.has(d.stop.dist) && Math.abs(d.stop.dist) <= 0.5 && root.speed < 0.5, c: root.cPower },
                    { t: "受信", on: root.rx, c: "#2fd0ff" },
                    { t: "出力", on: !!d.connected && !!d.output, c: "#2fd0ff" },
                ]
                Lamp { shape: "round"; width: 62; height: 60; text: modelData.t; on: modelData.on; litColor: modelData.c; blink: !!modelData.b; fontSize: 13; offColor: "#2a3038"; labelColor: "#aeb7c2" }
            }
        }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -2
            width: 140; height: 56; color: "transparent"
            Clock { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; color: "white"; font.pixelSize: 26; font.weight: Font.DemiBold }
        }
    }

    // ================= ノッチ (2 ハンドル) =================
    Rectangle {
        x: 14; y: 100; width: 232; height: 788; radius: 12; color: "#1b2027"
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 8; text: "主幹制御器"; color: root.cLabel; font.pixelSize: 20 }
        Rectangle {
            x: 16; y: 36; width: parent.width - 32; height: 70; radius: 8; color: "#13171c"
            Text {
                anchors.centerIn: parent
                text: U.notchName(root.n)
                color: root.n.b > root.n.maxB ? "#ff3b30" : root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : "white"
                font.pixelSize: 42; font.weight: Font.DemiBold
            }
        }
        Text { x: 26; y: 116; text: "力行"; color: root.cPower; font.pixelSize: 20; font.bold: true }
        Text { x: 128; y: 116; text: "ブレーキ"; color: root.cBrake; font.pixelSize: 20; font.bold: true }
        NotchLadder {
            x: 16; y: 148; width: 92; height: 370
            part: "power"; n: root.n; gap: 6
            powerColor: root.cPower; neutralColor: "#e0e0e0"; offColor: "#252b33"; offText: "#5d6670"; fontSize: 17; radius: 6
        }
        NotchLadder {
            x: 124; y: 148; width: 92; height: 620
            part: "brake"; n: root.n; gap: 6
            brakeColor: root.cBrake; neutralColor: "#e0e0e0"; offColor: "#252b33"; offText: "#5d6670"; fontSize: 17; radius: 6
        }
        Rectangle {
            x: 16; y: 540; width: 92; height: 112; radius: 8; color: "#13171c"
            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 8; text: "レバーサ"; color: root.cLabel; font.pixelSize: 17 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 38; text: U.revName(root.n.rev); color: "white"; font.pixelSize: 36; font.weight: Font.DemiBold }
        }
        Text { x: 18; y: 672; width: 96; wrapMode: Text.Wrap; text: root.n.pending ? "送信待ち\n" + root.n.pending : ""; color: "#ffd23f"; font.pixelSize: 20 }
    }

    // ================= 丸い計器の段 =================
    Row {
        x: 258; y: 98; spacing: 4
        Meter {
            size: 166; slot: 300; plate: "架線電圧"
            gauge.minValue: 0; gauge.maxValue: Math.ceil(U.num(d.voltNominal, 1500) * 4 / 3 / 100) * 100
            gauge.majorStep: 500; gauge.minorStep: 100; gauge.labelDivisor: 1000; gauge.labelDecimals: 1; gauge.unit: "kV"
            gauge.value: U.num(d.volt)
        }
        Meter {
            size: 232; slot: 300; plate: "空気圧  赤 BC / 白 MR"
            gauge.minValue: 0; gauge.maxValue: Math.max(1000, Math.ceil((Math.max(U.num(d.mrMax, 880), U.num(d.bcEmergency, 500)) + 50) / 200) * 200)
            gauge.majorStep: 200; gauge.minorStep: 50; gauge.unit: "kPa"
            gauge.value: U.num(d.bc); gauge.value2: U.num(d.mr)
            gauge.zones: [{ from: U.num(d.mrMin, 780), to: U.num(d.mrMax, 880), color: "#e8c020" }]
        }
        Meter {
            size: 300; slot: 300; plate: "速度計  km/h"
            gauge.minValue: 0; gauge.maxValue: U.num(d.speedMax, 120)
            gauge.majorStep: gauge.maxValue > 160 ? 40 : 20; gauge.minorStep: gauge.maxValue > 160 ? 10 : 5
            gauge.value: root.speed; gauge.limit: U.has(d.limit) ? d.limit : NaN
            gauge.digital: rx && U.has(d.speed) ? Math.round(root.speed).toString() : "--"
            gauge.digitalColor: root.over ? "#ff5040" : "#e8ecf0"
            gauge.zones: U.has(d.limit) ? [{ from: d.limit, to: gauge.maxValue, color: "#e8c020" }] : []
        }
        Meter {
            size: 232; slot: 300; plate: "電流計  A"
            gauge.minValue: -U.num(d.currentMax, 600); gauge.maxValue: U.num(d.currentMax, 600)
            gauge.majorStep: gauge.maxValue > 400 ? 200 : 100; gauge.minorStep: gauge.majorStep / 4
            gauge.value: U.num(d.current)
            gauge.zones: [{ from: gauge.minValue, to: 0, color: "#3a8fff" }, { from: 0, to: gauge.maxValue, color: "#30c060" }]
        }
        Meter {
            size: 150; slot: 300; plate: "加速度"
            gauge.minValue: -5; gauge.maxValue: 5; gauge.majorStep: 5; gauge.minorStep: 1; gauge.unit: "km/h/s"
            gauge.value: U.num(d.accel)
            gauge.zones: [{ from: -5, to: 0, color: "#ff9a2e" }, { from: 0, to: 5, color: "#30c060" }]
        }
    }

    // ================= 運転情報モニター =================
    Rectangle {
        x: 258; y: 454; width: 1096; height: 434; radius: 12; color: "#1b2027"
        Rectangle {
            id: screen
            anchors.fill: parent; anchors.margins: 6; radius: 8; color: "transparent"
            // 停止位置
            Item {
                x: 16; y: 12; width: 380; height: 380
                Text { text: "停止位置まで"; color: root.cLabel; font.pixelSize: 21 }
                Text { y: 28; text: U.str(d.stop ? d.stop.station : null) + (d.stop && d.stop.marker ? "  " + d.stop.marker : ""); color: "white"; font.pixelSize: 22; font.weight: Font.DemiBold }
                Text {
                    id: sd
                    readonly property real v: d.stop ? U.num(d.stop.dist, NaN) : NaN
                    anchors.right: sdu.left; anchors.rightMargin: 6; y: 92
                    text: U.distNum(v)
                    color: isNaN(v) ? "#55606c" : Math.abs(v) <= 0.5 ? root.cPower : v < 0 ? "#ff3b30" : v < 10 ? "#ffd23f" : "white"
                    font.pixelSize: 76; font.weight: Font.DemiBold
                }
                Text { id: sdu; anchors.right: parent.right; anchors.baseline: sd.baseline; text: U.distUnit(sd.v); color: root.cLabel; font.pixelSize: 28 }
                StopTape { y: 222; width: parent.width; height: 68; dist: sd.v; range: 10; fontSize: 13; bg: "#13171c"; tickColor: "#59626e" }
                Text { y: 316; text: "次駅"; color: root.cLabel; font.pixelSize: 19 }
                Text { y: 340; text: U.str(d.at ? d.at + " 構内" : d.next) + (d.at ? "" : "  " + U.dist(d.nextDist)); color: "white"; font.pixelSize: 22; font.weight: Font.DemiBold }
            }
            Grid {
                x: 424; y: 8; columns: 2; spacing: 8
                Tile { width: 322; color: "#13171c"; label: "現在地"; value: d.at ? d.at + " 構内" : (d.prev && d.next ? d.prev + " → " + d.next : "—") }
                Tile { width: 322; color: "#13171c"; label: "ノッチ"; value: U.notchName(root.n); valueColor: root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : "white"; note: root.n.pending ? "送信待ち " + root.n.pending : "" }
                Tile { width: 322; color: "#13171c"; label: "制限"; value: U.has(d.limit) ? Math.round(d.limit) : "—"; note: U.has(d.limit) ? "km/h" : ""; valueColor: root.over ? "#ff5040" : "#ffd23f" }
                Tile { width: 322; color: "#13171c"; label: "BC / MR"; value: Math.round(U.num(d.bc)) + " / " + Math.round(U.num(d.mr)); note: "kPa" }
                Tile { width: 322; color: "#13171c"; label: "分岐"; value: d.switch ? d.switch.way : "—"; note: d.switch ? Math.round(d.switch.dist) + " m" : ""; valueColor: d.switch && d.switch.conflict ? "#ff5040" : "white" }
                Tile { width: 322; color: "#13171c"; label: "電流"; value: Math.round(U.num(d.current)); note: "A"; valueColor: U.num(d.current) < -1 ? "#7fc4ff" : "white" }
                Tile { width: 322; color: "#13171c"; label: "回生"; value: U.num(d.regen) > 0.01 ? Math.round(U.num(d.regen) * 100) : "—"; note: U.num(d.regen) > 0.01 ? "%" : "" }
                Tile { width: 322; color: "#13171c"; label: "状態"; value: !d.connected ? "未接続" : !d.output ? "出力OFF" : !rx ? "受信なし" : d.cp ? "CP運転" : "正常"; valueColor: !d.connected || !d.output || !rx ? "#ffd23f" : root.cPower }
                Tile { width: 322; color: "#13171c"; label: "編成"; value: U.str(d.train); note: (d.cars ? d.cars + "両 " : "") + (d.cab === "secondary" ? "B" : d.cab === "main" ? "A" : "") }
                Tile { width: 322; color: "#13171c"; label: "運転モード"; value: U.str(d.mode) }
            }
        }
    }

    // ================= 路線 =================
    Rectangle {
        x: 1366; y: 100; width: 220; height: 788; radius: 12; color: "#1b2027"
        Rectangle {
            anchors.fill: parent; anchors.margins: 6; radius: 8; color: "transparent"
            Text { x: 12; y: 8; text: "前方"; color: root.cLabel; font.pixelSize: 20 }
            RouteStrip {
                x: 2; y: 36; width: parent.width - 4; height: parent.height - 44
                items: d.ahead || []; stopDist: d.stop ? U.num(d.stop.dist, NaN) : NaN; fontSize: 18
            }
        }
    }
}

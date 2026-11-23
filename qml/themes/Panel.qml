import QtQuick
import "../parts"
import "../parts/Util.js" as U

// 計器盤: DdgoMascon の別モニター表示 (CabDisplayWindow) と同じ並び。
// 上に路線・列番・表示灯・時刻の帯、左に 2 ハンドルのノッチ、上段に丸い計器、下段に運転情報モニター、右に路線
Rectangle {
    id: root
    readonly property var d: link.d
    readonly property var n: d.notch || ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    readonly property real speed: Math.abs(U.num(d.speed))
    readonly property bool rx: link.online
    readonly property bool over: U.has(d.limit) && speed > d.limit + 0.5
    readonly property color cPanel: "#2a2d31"
    readonly property color cScreen: "#03101a"
    readonly property color cAccent: "#1aa260"
    readonly property color cPower: "#33dd66"
    readonly property color cBrake: "#ff9a2e"
    readonly property color cLabel: "#9fb4c8"
    gradient: Gradient {
        GradientStop { position: 0; color: "#34383d" }
        GradientStop { position: 1; color: "#212427" }
    }

    // 計器の下の銘板
    component Plate: Rectangle {
        property string text: ""
        height: 34; radius: 3; color: "#0c0d0e"; border.color: "#55595e"; border.width: 1
        Text { anchors.centerIn: parent; text: parent.text; color: "#e8e8e8"; font.pixelSize: 20; font.bold: true }
    }
    component Tile: Rectangle {
        property string label: ""
        property string value: "—"
        property string note: ""
        property color valueColor: "white"
        height: 74; color: "#071a28"; border.color: "#18384f"; border.width: 1; radius: 3
        Text { x: 12; y: 6; text: parent.label; color: root.cLabel; font.pixelSize: 18 }
        Text {
            x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 4; width: parent.width - 24; elide: Text.ElideRight
            textFormat: Text.StyledText
            text: "<b>" + parent.value + "</b>" + (parent.note.length ? " <font color='#8aa0b4' size='3'>" + parent.note + "</font>" : "")
            color: parent.valueColor; font.pixelSize: 32
        }
    }

    // ================= 上の帯 =================
    Rectangle {
        width: parent.width; height: 64; color: "#141618"
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 5; color: root.cAccent }
        Text {
            x: 22; width: 420; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -2
            elide: Text.ElideRight; textFormat: Text.StyledText
            text: "<b>" + U.str(d.line, "路線 —") + "</b>  <font color='#c9d2db' size='4'>" + U.str(d.train, "") + (d.cars ? " " + d.cars + "両" : "") + "</font>"
            color: "white"; font.pixelSize: 30
        }
        Row {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -2; spacing: 6
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
                Lamp { width: 70; height: 40; text: modelData.t; on: modelData.on; litColor: modelData.c; blink: !!modelData.b; fontSize: modelData.t.length > 3 ? 14 : 18; offColor: "#1f2328" }
            }
        }
        Clock { anchors.right: parent.right; anchors.rightMargin: 22; anchors.verticalCenter: parent.verticalCenter; color: "white"; font.pixelSize: 34; font.bold: true }
    }

    // ================= ノッチ (2 ハンドル) =================
    Rectangle {
        x: 14; y: 78; width: 232; height: 808; radius: 6; color: "#1a1c1f"; border.color: "#46494e"
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 8; text: "主幹制御器"; color: root.cLabel; font.pixelSize: 20 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; y: 36
            text: U.notchName(root.n)
            color: root.n.b > root.n.maxB ? "#ff3b30" : root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : "white"
            font.pixelSize: 58; font.bold: true
        }
        Text { x: 22; y: 112; text: "力行"; color: root.cPower; font.pixelSize: 20; font.bold: true }
        Text { x: 128; y: 112; text: "ブレーキ"; color: root.cBrake; font.pixelSize: 20; font.bold: true }
        NotchLadder {
            x: 16; y: 146; width: 92; height: 382
            part: "power"; n: root.n; gap: 6; fontSize: 22
            powerColor: root.cPower; neutralColor: "#e0e0e0"; offColor: "#26292d"; offText: "#5d636a"; frameColor: "#3a3e44"
        }
        NotchLadder {
            x: 124; y: 146; width: 92; height: 640
            part: "brake"; n: root.n; gap: 6; fontSize: 22
            brakeColor: root.cBrake; neutralColor: "#e0e0e0"; offColor: "#26292d"; offText: "#5d636a"; frameColor: "#3a3e44"
        }
        Text { x: 22; y: 560; text: "レバーサ"; color: root.cLabel; font.pixelSize: 20 }
        Text { x: 22; y: 588; text: U.revName(root.n.rev); color: "white"; font.pixelSize: 44; font.bold: true }
        Text { x: 22; y: 660; width: 96; wrapMode: Text.Wrap; text: root.n.pending ? "送信待ち\n" + root.n.pending : ""; color: "#ffd23f"; font.pixelSize: 20 }
    }

    // ================= 丸い計器の段 =================
    Item {
        x: 260; y: 78; width: 1092; height: 350
        Row {
            spacing: 4
            Column {
                spacing: 6
                Item { width: 1; height: 70 }
                ArcGauge {
                    width: 160; height: 160
                    minValue: 0; maxValue: Math.ceil(U.num(d.voltNominal, 1500) * 4 / 3 / 100) * 100
                    majorStep: 500; minorStep: 100; labelDivisor: 1000; labelDecimals: 1; unit: "kV"
                    value: U.num(d.volt)
                    faceColor: "#111214"; tickColor: "#f0f0f0"; labelColor: "#f0f0f0"; needleColor: "#f03030"
                    labelScale: 1.2; dim: !rx
                }
                Item { width: 1; height: 64 }
                Plate { width: 160; text: "架線電圧" }
            }
            Column {
                spacing: 6
                Item { width: 1; height: 35 }
                ArcGauge {
                    width: 230; height: 230
                    minValue: 0; maxValue: Math.max(1000, Math.ceil((Math.max(U.num(d.mrMax, 880), U.num(d.bcEmergency, 500)) + 50) / 200) * 200)
                    majorStep: 200; minorStep: 50; unit: "kPa"
                    value: U.num(d.bc); value2: U.num(d.mr)
                    faceColor: "#111214"; tickColor: "#f0f0f0"; labelColor: "#f0f0f0"; needleColor: "#f03030"; needle2Color: "#f0f0f0"
                    subText: "BC " + Math.round(U.num(d.bc)) + "  MR " + Math.round(U.num(d.mr))
                    zones: [{ from: U.num(d.mrMin, 780), to: U.num(d.mrMax, 880), color: "#e8c020" }]
                    labelScale: 1.05; dim: !rx
                }
                Item { width: 1; height: 29 }
                Plate { width: 230; text: "空気圧計  赤 BC / 白 MR" }
            }
            Column {
                spacing: 6
                Item { width: 1; height: 0 }
                ArcGauge {
                    width: 300; height: 300
                    minValue: 0; maxValue: U.num(d.speedMax, 120)
                    majorStep: maxValue > 160 ? 40 : 20; minorStep: maxValue > 160 ? 10 : 5; unit: "km/h"
                    value: root.speed; limit: U.has(d.limit) ? d.limit : NaN
                    digital: rx && U.has(d.speed) ? Math.round(root.speed).toString() : "--"
                    faceColor: "#111214"; tickColor: "#f0f0f0"; labelColor: "#f0f0f0"; needleColor: "#f03030"; digitalColor: root.over ? "#ff5040" : "#f0f0f0"
                    zones: U.has(d.limit) ? [{ from: d.limit, to: maxValue, color: "#e8c020" }] : []
                    labelScale: 1.0; dim: !rx
                }
                Item { width: 1; height: 0 }
                Plate { width: 300; text: "速度計" }
            }
            Column {
                spacing: 6
                Item { width: 1; height: 35 }
                ArcGauge {
                    width: 230; height: 230
                    minValue: -U.num(d.currentMax, 600); maxValue: U.num(d.currentMax, 600)
                    majorStep: maxValue > 400 ? 200 : 100; minorStep: majorStep / 4; unit: "A"
                    value: U.num(d.current)
                    faceColor: "#111214"; tickColor: "#f0f0f0"; labelColor: "#f0f0f0"; needleColor: "#f03030"
                    zones: [{ from: minValue, to: 0, color: "#3a8fff" }, { from: 0, to: maxValue, color: "#30c060" }]
                    labelScale: 1.05; dim: !rx
                }
                Item { width: 1; height: 29 }
                Plate { width: 230; text: "電流計" }
            }
            Column {
                spacing: 6
                Item { width: 1; height: 75 }
                ArcGauge {
                    width: 150; height: 150
                    minValue: -5; maxValue: 5; majorStep: 5; minorStep: 1; unit: "km/h/s"
                    value: U.num(d.accel)
                    faceColor: "#111214"; tickColor: "#f0f0f0"; labelColor: "#f0f0f0"; needleColor: "#f03030"
                    zones: [{ from: -5, to: 0, color: "#ff9a2e" }, { from: 0, to: 5, color: "#30c060" }]
                    labelScale: 1.2; dim: !rx
                }
                Item { width: 1; height: 69 }
                Plate { width: 150; text: "加速度" }
            }
        }
    }

    // ================= 運転情報モニター =================
    Rectangle {
        x: 260; y: 442; width: 1092; height: 444; radius: 8
        color: "#0b0c0d"; border.color: "#55595e"; border.width: 2
        Rectangle {
            anchors.fill: parent; anchors.margins: 12; radius: 4; color: root.cScreen
            // 停止位置
            Item {
                x: 14; y: 12; width: 380; height: 396
                Text { text: "停止位置まで"; color: root.cLabel; font.pixelSize: 22 }
                Text { y: 30; text: U.str(d.stop ? d.stop.station : null) + (d.stop && d.stop.marker ? "  " + d.stop.marker : ""); color: "white"; font.pixelSize: 26; font.bold: true }
                Text {
                    id: sd
                    readonly property real v: d.stop ? U.num(d.stop.dist, NaN) : NaN
                    anchors.right: sdu.left; anchors.rightMargin: 6; y: 70
                    text: U.distNum(v)
                    color: isNaN(v) ? "#55606c" : Math.abs(v) <= 0.5 ? root.cPower : v < 0 ? "#ff3b30" : v < 10 ? "#ffd23f" : "white"
                    font.pixelSize: 110; font.bold: true
                }
                Text { id: sdu; anchors.right: parent.right; anchors.baseline: sd.baseline; text: U.distUnit(sd.v); color: root.cLabel; font.pixelSize: 28 }
                StopTape { y: 232; width: parent.width; height: 70; dist: sd.v; range: 10; fontSize: 15 }
                Text { y: 330; text: "次駅"; color: root.cLabel; font.pixelSize: 20 }
                Text { y: 354; text: U.str(d.at ? d.at + " 構内" : d.next) + (d.at ? "" : "  " + U.dist(d.nextDist)); color: "white"; font.pixelSize: 30; font.bold: true }
            }
            Grid {
                x: 410; y: 12; columns: 2; spacing: 8
                Tile { width: 320; label: "現在地"; value: d.at ? d.at + " 構内" : (d.prev && d.next ? d.prev + " → " + d.next : "—") }
                Tile { width: 320; label: "ノッチ"; value: U.notchName(root.n); valueColor: root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : "white"; note: root.n.pending ? "送信待ち " + root.n.pending : "" }
                Tile { width: 320; label: "制限"; value: U.has(d.limit) ? Math.round(d.limit) : "—"; note: U.has(d.limit) ? "km/h" : ""; valueColor: root.over ? "#ff5040" : "#ffd23f" }
                Tile { width: 320; label: "BC / MR"; value: Math.round(U.num(d.bc)) + " / " + Math.round(U.num(d.mr)); note: "kPa" }
                Tile { width: 320; label: "分岐"; value: d.switch ? d.switch.way : "—"; note: d.switch ? Math.round(d.switch.dist) + " m" : ""; valueColor: d.switch && d.switch.conflict ? "#ff5040" : "white" }
                Tile { width: 320; label: "電流"; value: Math.round(U.num(d.current)); note: "A" }
                Tile { width: 320; label: "回生"; value: U.num(d.regen) > 0.01 ? Math.round(U.num(d.regen) * 100) : "—"; note: U.num(d.regen) > 0.01 ? "%" : "" }
                Tile { width: 320; label: "状態"; value: !d.connected ? "未接続" : !d.output ? "出力OFF" : !rx ? "受信なし" : d.cp ? "CP運転" : "正常"; valueColor: !d.connected || !d.output || !rx ? "#ffd23f" : root.cPower }
                Tile { width: 320; label: "編成"; value: U.str(d.train); note: (d.cars ? d.cars + "両 " : "") + (d.cab === "secondary" ? "B" : d.cab === "main" ? "A" : "") }
                Tile { width: 320; label: "運転モード"; value: U.str(d.mode) }
            }
        }
    }

    // ================= 路線 =================
    Rectangle {
        x: 1366; y: 78; width: 220; height: 808; radius: 6; color: root.cScreen; border.color: "#46494e"
        Text { x: 14; y: 10; text: "前方"; color: root.cLabel; font.pixelSize: 20 }
        RouteStrip {
            x: 4; y: 40; width: parent.width - 8; height: parent.height - 50
            items: d.ahead || []; stopDist: d.stop ? U.num(d.stop.dist, NaN) : NaN; fontSize: 22
        }
    }
}

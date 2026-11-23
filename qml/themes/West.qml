import QtQuick
import "../parts"
import "../parts/Util.js" as U

// 私鉄・JR西 風: 明るい地に紺の帯、白いカードと橙のアクセント (225 系 / N700S のモニター風)
Rectangle {
    id: root
    color: "#e9edf2"
    readonly property var d: link.d
    readonly property var n: d.notch || ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    readonly property real speed: Math.abs(U.num(d.speed))
    readonly property bool rx: link.online
    readonly property bool over: U.has(d.limit) && speed > d.limit + 0.5
    readonly property color cNavy: "#13285a"
    readonly property color cNavy2: "#25407e"
    readonly property color cOrange: "#f07a12"
    readonly property color cText: "#14213d"
    readonly property color cSub: "#5c6a80"
    readonly property color cPower: "#13a34a"
    readonly property color cBrake: "#e0611a"

    component Card: Rectangle {
        property string title: ""
        default property alias content: body.data
        color: "white"; radius: 6
        border.color: "#c5ccd6"; border.width: 1
        Rectangle {
            id: cap; visible: parent.title.length > 0
            width: parent.width; height: 44; radius: 6; color: root.cNavy
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 6; color: root.cNavy }
            Rectangle { x: 0; y: 0; width: 8; height: parent.height; color: root.cOrange; radius: 2 }
            Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: parent.parent.title; color: "white"; font.pixelSize: 24; font.bold: true }
        }
        Item { id: body; y: cap.visible ? 44 : 0; width: parent.width; height: parent.height - y }
    }
    component RowVal: Item {
        property string label: ""
        property string value: "--"
        property string unit: ""
        property color valueColor: root.cText
        height: 62; width: parent ? parent.width : 400
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#dde2e9" }
        Text { x: 18; anchors.verticalCenter: parent.verticalCenter; text: parent.label; color: root.cSub; font.pixelSize: 24 }
        Text { id: v; anchors.right: u.left; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: parent.value; color: parent.valueColor; font.pixelSize: 36; font.bold: true }
        Text { id: u; anchors.right: parent.right; anchors.rightMargin: 18; anchors.baseline: v.baseline; width: 66; text: parent.unit; color: root.cSub; font.pixelSize: 20 }
    }

    // ================= 上の帯 =================
    Rectangle {
        width: parent.width; height: 96; color: root.cNavy
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 6; color: root.cOrange }
        Row {
            x: 24; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -3; spacing: 16
            Rectangle {
                width: 116; height: 56; radius: 4; color: root.cOrange
                Text { anchors.centerIn: parent; text: d.train && String(d.train).split(" ").length > 1 ? String(d.train).split(" ")[1] : "普通"; color: "white"; font.pixelSize: 30; font.bold: true }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: U.str(d.train ? String(d.train).split(" ")[0] : null, "----"); color: "white"; font.pixelSize: 34; font.bold: true }
            Text { anchors.verticalCenter: parent.verticalCenter; text: U.str(d.line, ""); color: "#b9c6e2"; font.pixelSize: 26 }
        }
        Row {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -3; spacing: 14
            Text { text: d.at ? "ただいま" : "次は"; color: "#b9c6e2"; font.pixelSize: 28; anchors.baseline: nx.baseline }
            Text { id: nx; text: U.str(d.at || d.next); color: "white"; font.pixelSize: 52; font.bold: true }
            Text { text: d.at ? "" : U.dist(d.nextDist); color: "#ffcf9a"; font.pixelSize: 30; anchors.baseline: nx.baseline }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 24; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -3; spacing: 18
            Rectangle {
                width: 134; height: 44; radius: 22; anchors.verticalCenter: parent.verticalCenter
                color: !rx ? "#c62828" : !d.output ? "#b77900" : "#1d7a3e"
                Text { anchors.centerIn: parent; text: !rx ? "受信なし" : !d.output ? "出力OFF" : "通信正常"; color: "white"; font.pixelSize: 22; font.bold: true }
            }
            Clock { color: "white"; font.pixelSize: 40; font.bold: true; seconds: false }
        }
    }

    // ================= 速度 =================
    Card {
        title: "速度"
        x: 20; y: 116; width: 540; height: 500
        ArcGauge {
            x: 40; y: 12; width: 460; height: 460
            style: "lcd"
            minValue: 0; maxValue: U.num(d.speedMax, 120)
            majorStep: maxValue > 160 ? 40 : 20; minorStep: maxValue > 160 ? 10 : 5
            value: root.speed; limit: U.has(d.limit) ? d.limit : NaN
            digital: rx && U.has(d.speed) ? Math.round(root.speed).toString() : "--"
            digitalColor: root.over ? "#d32f2f" : root.cNavy
            unit: "km/h"
            fillColor: root.cNavy2; trackColor: "#dfe5ee"
            tickColor: root.cNavy; labelColor: root.cNavy; limitColor: root.cOrange; pointerColor: root.cOrange
            zones: U.has(d.limit) ? [{ from: d.limit, to: maxValue, color: "#e85a4f" }] : []
            dim: !rx
            labelScale: 1.1
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; y: 398; width: 168; height: 50; radius: 4
            color: root.over ? "#d32f2f" : "white"; border.color: root.cOrange; border.width: 3
            Text { anchors.centerIn: parent; text: "制限 " + (U.has(d.limit) ? Math.round(d.limit) : "--"); color: root.over ? "white" : root.cOrange; font.pixelSize: 28; font.bold: true }
        }
    }

    // ================= 停止位置 =================
    Card {
        title: "停止位置" + (d.stop && d.stop.marker ? "  (" + d.stop.marker + ")" : "")
        x: 576; y: 116; width: 520; height: 500
        Text { x: 22; y: 18; text: U.str(d.stop ? d.stop.station : null); color: root.cText; font.pixelSize: 40; font.bold: true }
        Text { x: 22; y: 84; text: "停止位置まで"; color: root.cSub; font.pixelSize: 24 }
        Text {
            id: sd
            readonly property real v: d.stop ? U.num(d.stop.dist, NaN) : NaN
            anchors.right: sdu.left; anchors.rightMargin: 8; y: 110
            text: U.distNum(v)
            color: isNaN(v) ? "#9aa5b4" : Math.abs(v) <= 0.5 ? root.cPower : v < 0 ? "#d32f2f" : v < 10 ? root.cOrange : root.cNavy
            font.pixelSize: 120; font.bold: true
        }
        Text { id: sdu; anchors.right: parent.right; anchors.rightMargin: 28; anchors.baseline: sd.baseline; text: U.distUnit(sd.v); color: root.cSub; font.pixelSize: 32 }
        StopTape {
            x: 22; y: 290; width: parent.width - 44; height: 80
            dist: sd.v; range: 10; fontSize: 18
            bg: "#f1f4f8"; tickColor: "#64738a"; markerColor: root.cNavy
            okColor: root.cPower; nearColor: root.cOrange; overColor: "#d32f2f"
        }
        Row {
            x: 22; y: 396; spacing: 12
            Rectangle {
                width: 230; height: 46; radius: 4; color: d.switch ? (d.switch.conflict ? "#d32f2f" : "#fff4e5") : "#f1f4f8"; border.color: "#d9c2a3"
                Text { anchors.centerIn: parent; text: d.switch ? "分岐 " + d.switch.way + " " + Math.round(d.switch.dist) + "m" : "分岐なし"; color: d.switch && d.switch.conflict ? "white" : root.cText; font.pixelSize: 22 }
            }
            Rectangle {
                width: 230; height: 46; radius: 4; color: "#f1f4f8"; border.color: "#d0d7e1"
                Text { anchors.centerIn: parent; text: "加速度 " + U.sign(d.accel, 1) + " km/h/s"; color: root.cText; font.pixelSize: 22 }
            }
        }
    }

    // ================= 情報欄 =================
    Card {
        title: "車両情報"
        x: 1112; y: 116; width: 468; height: 500
        Column {
            width: parent.width; y: 4
            RowVal { label: "架線電圧"; value: rx ? (U.num(d.volt) / 1000).toFixed(2) : "--"; unit: "kV" }
            RowVal { label: "主電動機電流"; value: rx ? Math.round(U.num(d.current)) : "--"; unit: "A"; valueColor: U.num(d.current) < -1 ? root.cNavy2 : U.num(d.current) > 1 ? root.cPower : root.cText }
            RowVal { label: "ブレーキシリンダ"; value: rx ? Math.round(U.num(d.bc)) : "--"; unit: "kPa"; valueColor: root.cBrake }
            RowVal { label: "元空気だめ"; value: rx ? Math.round(U.num(d.mr)) : "--"; unit: "kPa" }
            RowVal { label: "回生"; value: U.num(d.regen) > 0.01 ? Math.round(U.num(d.regen) * 100) : "--"; unit: "%" }
            RowVal { label: "運転モード"; value: U.str(d.mode); unit: "" }
            RowVal { label: "編成"; value: d.cars ? d.cars + "両" : "--"; unit: d.cab === "secondary" ? "B側" : "A側" }
        }
    }

    // ================= ノッチ (横一列) =================
    Card {
        x: 20; y: 632; width: 1560; height: 160
        Text { x: 24; y: 14; text: "主幹制御器"; color: root.cSub; font.pixelSize: 22 }
        Text {
            x: 24; y: 46
            text: U.notchName(root.n)
            color: root.n.b > root.n.maxB ? "#d32f2f" : root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : root.cNavy
            font.pixelSize: 80; font.bold: true
        }
        NotchLadder {
            x: 230; y: 24; width: parent.width - 254; height: 112
            vertical: false; n: root.n; gap: 6; radius: 4; fontSize: 28
            powerColor: root.cPower; brakeColor: root.cBrake; ebColor: "#d32f2f"; neutralColor: root.cNavy2
            litText: "white"; offColor: "#eef1f5"; offText: "#a6b0be"; frameColor: "#d3d9e2"
        }
    }

    // ================= 表示灯 =================
    Row {
        x: 20; y: 808; spacing: 10
        Repeater {
            model: [
                { t: "力行", on: root.n.p > 0 && root.n.b === 0, c: root.cPower },
                { t: "回生", on: U.num(d.regen) > 0.01, c: root.cNavy2 },
                { t: "ブレーキ", on: U.num(d.bc) > 20, c: root.cBrake },
                { t: "非常", on: !!d.emergency, c: "#d32f2f", blink: true },
                { t: "CP", on: !!d.cp, c: "#c9a400" },
                { t: "速度超過", on: root.over, c: "#d32f2f", blink: true },
                { t: "定位置", on: !!d.stop && U.has(d.stop.dist) && Math.abs(d.stop.dist) <= 0.5 && root.speed < 0.5, c: root.cPower },
                { t: "レバーサ " + U.revName(root.n.rev), on: root.n.rev === 1 || root.n.rev === -1, c: root.cNavy },
            ]
            Lamp {
                width: (1560 - 70) / 8; height: 72; text: modelData.t; on: modelData.on; litColor: modelData.c; blink: !!modelData.blink
                litText: "white"; offColor: "white"; offText: "#a6b0be"; fontSize: 26; radius: 6
                border.color: on ? modelData.c : "#c5ccd6"
            }
        }
    }
}

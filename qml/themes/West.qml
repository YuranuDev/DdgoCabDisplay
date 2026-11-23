import QtQuick
import "../parts"
import "../parts/Util.js" as U

// 私鉄・JR西 風: 明るい地に紺の帯、白いカードと橙のアクセント (225 系 / N700S のモニター風)
Rectangle {
    id: root
    color: "#eef1f5"
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

    // 白いカード。見出しは紺の文字と橙の短い線
    component Card: Rectangle {
        id: card
        property string title: ""
        property string badge: ""
        default property alias content: body.data
        color: "white"; radius: 12; border.color: "#dde2ea"; border.width: 1
        Item {
            id: cap; visible: card.title.length > 0
            x: 20; width: card.width - 40; height: 48
            Rectangle { y: 16; width: 4; height: 18; radius: 2; color: root.cOrange }
            Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: card.title; color: root.cNavy; font.pixelSize: 18; font.weight: Font.DemiBold }
            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: card.badge; color: root.cSub; font.pixelSize: 16 }
        }
        Item { id: body; y: cap.visible ? 48 : 0; width: parent.width; height: parent.height - y }
    }
    component RowVal: Rectangle {
        id: rv
        property string label: ""
        property string value: "--"
        property string unit: ""
        property color valueColor: root.cText
        property color mark: root.cNavy2
        height: 48; width: parent ? parent.width : 400
        color: "transparent"
        Rectangle { x: 20; anchors.bottom: parent.bottom; width: parent.width - 40; height: 1; color: "#edf0f4" }
        Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: rv.label; color: root.cSub; font.pixelSize: 17 }
        Text { id: v; anchors.right: u.left; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: rv.value; color: rv.valueColor; font.pixelSize: 24; font.weight: Font.DemiBold }
        Text { id: u; anchors.right: parent.right; anchors.rightMargin: 20; anchors.baseline: v.baseline; width: 44; text: rv.unit; color: root.cSub; font.pixelSize: 14 }
    }

    // ================= 上の帯 =================
    Rectangle {
        width: parent.width; height: 80; color: root.cNavy
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 4; color: root.cOrange }
        Row {
            x: 24; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -2; spacing: 14
            Rectangle {
                width: 76; height: 36; radius: 6; color: root.cOrange; anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: d.train && String(d.train).split(" ").length > 1 ? String(d.train).split(" ")[1] : "普通"; color: "white"; font.pixelSize: 19; font.weight: Font.DemiBold }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: U.str(d.train ? String(d.train).split(" ")[0] : null, "----"); color: "white"; font.pixelSize: 22; font.weight: Font.DemiBold }
                Text { text: U.str(d.line, "") + (d.cars ? "  ·  " + d.cars + "両" : ""); color: "#b9c6e2"; font.pixelSize: 14 }
            }
        }
        Row {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -2; spacing: 12
            Text { text: d.at ? "ただいま" : "次は"; color: "#b9c6e2"; font.pixelSize: 18; anchors.baseline: nx.baseline }
            Text { id: nx; text: U.str(d.at || d.next); color: "white"; font.pixelSize: 34; font.weight: Font.DemiBold }
            Text { text: d.at ? "" : U.dist(d.nextDist); color: "#ffcf9a"; font.pixelSize: 20; anchors.baseline: nx.baseline }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 24; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -2; spacing: 20
            Row {
                anchors.verticalCenter: parent.verticalCenter; spacing: 8
                Rectangle { width: 10; height: 10; radius: 5; anchors.verticalCenter: parent.verticalCenter; color: !rx ? "#ff6b5f" : !d.output ? "#ffc940" : "#4ad98a" }
                Text { text: !rx ? "受信なし" : !d.output ? "出力OFF" : "通信正常"; color: "#d7e0f0"; font.pixelSize: 16 }
            }
            Clock { color: "white"; font.pixelSize: 28; font.weight: Font.DemiBold; seconds: false }
        }
    }

    // ================= 路線図の帯 =================
    Card {
        x: 20; y: 96; width: 1560; height: 112
        RouteLine {
            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
            items: d.ahead || []; at: d.at || ""
            lineColor: root.cNavy2; nextColor: root.cOrange; trainColor: root.cOrange; textColor: root.cText; subColor: root.cSub
            fontSize: 20
        }
    }

    // ================= 速度 =================
    Card {
        title: "速度"; badge: "km/h"
        x: 20; y: 222; width: 520; height: 398
        ModernGauge {
            x: 166; y: 0; width: 330; height: 330
            minValue: 0; maxValue: U.num(d.speedMax, 120)
            majorStep: maxValue > 160 ? 40 : 20; minorStep: maxValue > 160 ? 10 : 5
            value: root.speed; limit: U.has(d.limit) ? d.limit : NaN
            zones: U.has(d.limit) ? [{ from: d.limit, to: maxValue, color: "#e85a4f" }] : []
            valueText: rx && U.has(d.speed) ? Math.round(root.speed).toString() : "--"
            unit: "km/h"
            accent: root.cNavy2; track: "#e6eaf0"; tickColor: "#b7c0cc"; labelColor: "#5c6a80"
            needleColor: root.cNavy; hubInner: "white"; valueColor: root.over ? "#d32f2f" : root.cNavy; limitColor: root.cOrange; valueSize: 0.27; thickness: 0.07
            dim: !rx
        }
        Rectangle {
            x: 22; y: 10; width: 84; height: 84; radius: 42
            color: "white"; border.color: "#d9362b"; border.width: 6
            Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -3; text: U.has(d.limit) ? Math.round(d.limit) : "--"; color: root.cText; font.pixelSize: 26; font.weight: Font.DemiBold }
            Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; text: "制限"; color: root.cSub; font.pixelSize: 11 }
        }
        Column {
            x: 22; y: 130; spacing: 2
            Text { text: "加速度"; color: root.cSub; font.pixelSize: 14 }
            Text { text: U.sign(d.accel, 1); color: U.num(d.accel) < -0.05 ? root.cBrake : U.num(d.accel) > 0.05 ? root.cPower : root.cText; font.pixelSize: 24; font.weight: Font.DemiBold }
            Text { text: "km/h/s"; color: root.cSub; font.pixelSize: 12 }
            Item { width: 1; height: 16 }
            Text { text: "運転"; color: root.cSub; font.pixelSize: 14 }
            Text { text: U.str(d.mode); color: root.cText; font.pixelSize: 24; font.weight: Font.DemiBold }
        }
    }

    // ================= 停止位置 =================
    Card {
        title: "停止位置"; badge: d.stop && d.stop.marker ? d.stop.marker + " 停目" : ""
        x: 556; y: 222; width: 540; height: 398
        Text { x: 22; y: 6; text: U.str(d.stop ? d.stop.station : null); color: root.cText; font.pixelSize: 28; font.weight: Font.DemiBold }
        Text { x: 22; y: 50; text: "停止位置まで"; color: root.cSub; font.pixelSize: 16 }
        Item {
            x: 22; y: 70; width: parent.width - 44; height: 130
            Text {
                id: sd
                readonly property real v: d.stop ? U.num(d.stop.dist, NaN) : NaN
                anchors.right: sdu.left; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                text: U.distNum(v)
                color: isNaN(v) ? "#9aa5b4" : Math.abs(v) <= 0.5 ? root.cPower : v < 0 ? "#d32f2f" : v < 10 ? root.cOrange : root.cNavy
                font.pixelSize: 72; font.weight: Font.DemiBold
            }
            Text { id: sdu; anchors.right: parent.right; anchors.baseline: sd.baseline; text: U.distUnit(sd.v); color: root.cSub; font.pixelSize: 20 }
        }
        StopTape {
            x: 22; y: 212; width: parent.width - 44; height: 66
            dist: sd.v; range: 10; fontSize: 16
            bg: "#eef2f7"; tickColor: "#64738a"; markerColor: root.cNavy
            okColor: root.cPower; nearColor: root.cOrange; overColor: "#d32f2f"
        }
        Row {
            x: 22; y: 290; spacing: 12
            Rectangle {
                width: 240; height: 40; radius: 20; color: d.switch ? (d.switch.conflict ? "#d32f2f" : "#fff2e2") : "#eef2f7"; border.color: d.switch ? "#f0b070" : "#d0d7e1"
                Text { anchors.centerIn: parent; text: d.switch ? "分岐 " + d.switch.way + "  " + Math.round(d.switch.dist) + " m" : "分岐なし"; color: d.switch && d.switch.conflict ? "white" : root.cText; font.pixelSize: 16; font.weight: d.switch ? Font.DemiBold : Font.Normal }
            }
            Rectangle {
                width: 244; height: 40; radius: 20; color: "#eef2f7"; border.color: "#d0d7e1"
                Text { anchors.centerIn: parent; text: d.at ? d.at + " 停車中" : U.str(d.prev, "") + " → " + U.str(d.next, ""); color: root.cText; font.pixelSize: 16 }
            }
        }
    }

    // ================= 情報欄 =================
    Card {
        title: "車両情報"
        x: 1112; y: 222; width: 468; height: 398
        Column {
            width: parent.width
            RowVal { label: "架線電圧"; value: rx ? (U.num(d.volt) / 1000).toFixed(2) : "--"; unit: "kV" }
            RowVal { label: "主電動機電流"; value: rx ? Math.round(U.num(d.current)) : "--"; unit: "A"; mark: U.num(d.current) < -1 ? root.cNavy2 : root.cPower; valueColor: U.num(d.current) < -1 ? root.cNavy2 : U.num(d.current) > 1 ? root.cPower : root.cText }
            RowVal { label: "ブレーキシリンダ"; value: rx ? Math.round(U.num(d.bc)) : "--"; unit: "kPa"; mark: root.cBrake; valueColor: root.cBrake }
            RowVal { label: "元空気だめ"; value: rx ? Math.round(U.num(d.mr)) : "--"; unit: "kPa"; mark: "#7d8899" }
            RowVal { label: "回生"; value: U.num(d.regen) > 0.01 ? Math.round(U.num(d.regen) * 100) : "--"; unit: "%" }
            RowVal { label: "運転モード"; value: U.str(d.mode); unit: ""; mark: root.cOrange }
            RowVal { label: "編成"; value: d.cars ? d.cars + "両" : "--"; unit: d.cab === "secondary" ? "B側" : "A側" }
        }
    }

    // ================= ノッチ (横一列) =================
    Card {
        x: 20; y: 634; width: 1560; height: 150
        Text { x: 24; y: 14; text: "主幹制御器"; color: root.cSub; font.pixelSize: 16 }
        Text {
            x: 24; y: 38
            text: U.notchName(root.n)
            color: root.n.b > root.n.maxB ? "#d32f2f" : root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : root.cNavy
            font.pixelSize: 56; font.weight: Font.DemiBold
        }
        Text { x: 140; y: 12; text: root.n.pending ? "送信待ち " + root.n.pending : ""; color: root.cOrange; font.pixelSize: 18 }
        NotchLadder {
            x: 230; y: 22; width: parent.width - 254; height: 106
            vertical: false; n: root.n; gap: 6; radius: 8; fontSize: 20; glow: false
            powerColor: root.cPower; brakeColor: root.cBrake; ebColor: "#d32f2f"; neutralColor: root.cNavy2
            litText: "white"; offColor: "#f1f4f8"; offText: "#a6b0be"; frameColor: "transparent"
        }
    }

    // ================= 表示灯 =================
    Row {
        x: 20; y: 806; spacing: 10
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
                litText: "white"; offColor: "white"; offText: "#a6b0be"; fontSize: 18; radius: 10
            }
        }
    }
}

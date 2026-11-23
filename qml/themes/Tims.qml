import QtQuick
import "../parts"
import "../parts/Util.js" as U

// JR東日本 TIMS 風: 黒地・水色の見出し・枠で区切った情報欄・下に画面切替ボタン
Rectangle {
    id: root
    color: "#000000"
    readonly property var d: link.d
    readonly property var n: d.notch || ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    readonly property real speed: U.num(d.speed)
    readonly property bool rx: link.online
    readonly property int carCount: Math.max(2, Math.min(15, U.num(d.cars, 6)))
    property int pageNo: startPage

    readonly property color cLabel: "#6fd3ff"
    readonly property color cFrame: "#3d5d7e"
    readonly property color cPanel: "#06101c"
    readonly property color cValue: "#ffffff"
    readonly property color cYellow: "#ffe14d"
    readonly property color cPower: "#36e36f"
    readonly property color cBrake: "#ff9a2e"
    readonly property var pages: ["運転情報", "車両状態", "路線"]

    function key(k) {
        if (k === Qt.Key_Right) pageNo = (pageNo + 1) % pages.length;
        else if (k === Qt.Key_Left) pageNo = (pageNo + pages.length - 1) % pages.length;
    }

    // 見出し付きの枠
    component Box: Rectangle {
        property string title: ""
        default property alias content: inner.data
        color: root.cPanel
        border.color: root.cFrame; border.width: 2
        Rectangle {
            id: cap
            visible: parent.title.length > 0
            x: 2; y: 2; width: parent.width - 4; height: 36
            color: "#0f2742"
            Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: parent.parent.title; color: root.cLabel; font.pixelSize: 22; font.bold: true }
        }
        Item { id: inner; x: 2; y: cap.visible ? 40 : 2; width: parent.width - 4; height: parent.height - y - 2 }
    }
    // ラベル + 大きな値 + 単位
    component Val: Item {
        property string label: ""
        property string value: "--"
        property string unit: ""
        property color valueColor: root.cValue
        property real size: 46
        Text { id: lb; text: parent.label; color: root.cLabel; font.pixelSize: 20; anchors.left: parent.left; anchors.top: parent.top }
        Text {
            id: vv; text: parent.value; color: parent.valueColor; font.pixelSize: parent.size; font.bold: true
            anchors.right: un.left; anchors.rightMargin: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: -4
        }
        Text { id: un; text: parent.unit; color: "#b8c6d4"; font.pixelSize: 20; anchors.right: parent.right; anchors.baseline: vv.baseline }
    }

    // ================= 上の帯 =================
    Rectangle {
        id: header
        width: parent.width; height: 78
        gradient: Gradient { GradientStop { position: 0; color: "#163a66" } GradientStop { position: 1; color: "#0a1d36" } }
        Rectangle { width: parent.width; height: 2; anchors.bottom: parent.bottom; color: "#5b86b3" }
        Text { x: 24; anchors.verticalCenter: parent.verticalCenter; text: root.pages[root.pageNo]; color: "white"; font.pixelSize: 36; font.bold: true }
        Row {
            x: 330; anchors.verticalCenter: parent.verticalCenter; spacing: 14
            Rectangle {
                width: 200; height: 54; color: "black"; border.color: "white"; border.width: 2
                Text { anchors.centerIn: parent; text: U.str(d.train ? String(d.train).split(" ")[0] : null, "----"); color: root.cYellow; font.pixelSize: 34; font.bold: true }
            }
            Rectangle {
                width: 120; height: 54; radius: 4; color: "#0d7a3a"
                Text { anchors.centerIn: parent; text: d.train && String(d.train).split(" ").length > 1 ? String(d.train).split(" ")[1] : "普通"; color: "white"; font.pixelSize: 30; font.bold: true }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: U.str(d.line, "") + (d.cars ? "  " + d.cars + " 両" : ""); color: "white"; font.pixelSize: 28 }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 24; anchors.verticalCenter: parent.verticalCenter; spacing: 22
            Rectangle {
                width: 150; height: 48; radius: 4
                color: !rx ? "#5a1010" : !d.output ? "#6a4a00" : "#0f3d22"
                border.color: !rx ? "#ff5050" : !d.output ? "#ffc040" : "#40e080"; border.width: 2
                Text { anchors.centerIn: parent; text: !rx ? "受信なし" : !d.output ? "出力OFF" : "正常"; color: "white"; font.pixelSize: 24; font.bold: true }
            }
            Clock { color: "white"; font.pixelSize: 40; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ================= 画面 1: 運転情報 =================
    Item {
        id: pDrive
        visible: root.pageNo === 0
        x: 0; y: 86; width: parent.width; height: 740

        // ノッチ
        Box {
            title: "ノッチ"
            x: 16; y: 0; width: 300; height: 720
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; y: 6
                text: U.notchName(root.n)
                color: root.n.b > 0 ? (root.n.b > root.n.maxB ? "#ff3b30" : root.cBrake) : root.n.p > 0 ? root.cPower : "white"
                font.pixelSize: 64; font.bold: true
            }
            NotchLadder {
                x: 40; y: 92; width: parent.width - 80; height: parent.height - 150
                n: root.n; powerColor: root.cPower; brakeColor: root.cBrake; fontSize: 22; gap: 5
                offColor: "#141c26"; offText: "#4f5c6a"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                text: "レバーサ " + U.revName(root.n.rev) + (root.n.pending ? "   送信待ち " + root.n.pending : "")
                color: "#b8c6d4"; font.pixelSize: 22
            }
        }

        // 速度
        Box {
            title: "速度"
            x: 332; y: 0; width: 660; height: 400
            Text {
                id: spd
                anchors.right: parent.right; anchors.rightMargin: 150; y: 4
                text: rx && U.has(d.speed) ? Math.round(Math.abs(root.speed)).toString() : "--"
                color: U.has(d.limit) && root.speed > d.limit + 0.5 ? "#ff3b30" : "white"
                font.pixelSize: 170; font.bold: true
            }
            Text { anchors.left: spd.right; anchors.leftMargin: 14; anchors.baseline: spd.baseline; text: "km/h"; color: "#b8c6d4"; font.pixelSize: 34 }
            Column {
                x: 24; y: 22; spacing: 8
                Text { text: "制限"; color: root.cLabel; font.pixelSize: 22 }
                Rectangle {
                    width: 120; height: 76; radius: 6; color: "black"; border.color: root.cYellow; border.width: 3
                    Text { anchors.centerIn: parent; text: U.has(d.limit) ? Math.round(d.limit) : "--"; color: root.cYellow; font.pixelSize: 46; font.bold: true }
                }
                Text { text: "加速度"; color: root.cLabel; font.pixelSize: 22; topPadding: 2 }
                Row {
                    spacing: 6
                    Text { text: U.sign(d.accel, 1); color: "white"; font.pixelSize: 34; font.bold: true }
                    Text { text: "km/h/s"; color: "#b8c6d4"; font.pixelSize: 18; anchors.baseline: parent.children[0].baseline }
                }
            }
            BarMeter {
                x: 24; y: 262; width: parent.width - 48; height: 64
                minValue: 0; maxValue: U.num(d.speedMax, 120); value: Math.abs(root.speed)
                segmented: true; segments: 48
                barColor: U.has(d.limit) && root.speed > d.limit + 0.5 ? "#ff3b30" : "#5fd8ff"
                trackColor: "#0b1622"; majorStep: 20; fontSize: 18; tickColor: "#b8c6d4"
                marks: U.has(d.limit) ? [{ v: d.limit, color: root.cYellow }] : []
            }
        }

        // 次駅・停止位置
        Box {
            title: "次駅・停止位置"
            x: 1008; y: 0; width: 576; height: 400
            Text { x: 22; y: 6; text: d.at ? "停車中" : "次は"; color: root.cLabel; font.pixelSize: 24 }
            Text { x: 22; y: 34; text: U.str(d.at || d.next); color: "white"; font.pixelSize: 64; font.bold: true; width: parent.width - 44; elide: Text.ElideRight }
            Text { anchors.right: parent.right; anchors.rightMargin: 22; y: 12; text: d.at ? "" : U.dist(d.nextDist); color: "#d0dbe6"; font.pixelSize: 30 }
            Text { x: 22; y: 130; text: "停止位置まで" + (d.stop && d.stop.marker ? "  (" + d.stop.marker + ")" : ""); color: root.cLabel; font.pixelSize: 22 }
            Text {
                id: sd
                anchors.right: sdu.left; anchors.rightMargin: 8; y: 140
                readonly property real v: d.stop ? U.num(d.stop.dist, NaN) : NaN
                text: U.distNum(v)
                color: isNaN(v) ? "#6b7886" : Math.abs(v) <= 0.5 ? root.cPower : v < 0 ? "#ff3b30" : v < 10 ? root.cYellow : "white"
                font.pixelSize: 96; font.bold: true
            }
            Text { id: sdu; anchors.right: parent.right; anchors.rightMargin: 24; anchors.baseline: sd.baseline; text: U.distUnit(sd.v); color: "#b8c6d4"; font.pixelSize: 30 }
            StopTape {
                x: 22; y: 278; width: parent.width - 44; height: 66
                dist: d.stop ? U.num(d.stop.dist, NaN) : NaN; range: 10; tol: 0.5; fontSize: 16
            }
        }

        // 電気・空気
        Box {
            title: "架線電圧・電流"
            x: 332; y: 414; width: 620; height: 196
            Val { x: 20; y: 6; width: 250; height: 80; label: "架線電圧"; value: rx ? (U.num(d.volt) / 1000).toFixed(2) : "--"; unit: "kV" }
            Val { x: 320; y: 6; width: 270; height: 80; label: "主回路電流"; value: rx ? Math.round(U.num(d.current)) : "--"; unit: "A"; valueColor: U.num(d.current) < -1 ? "#7fc4ff" : "white" }
            BarMeter {
                x: 320; y: 100; width: 270; height: 40; minValue: -U.num(d.currentMax, 600); maxValue: U.num(d.currentMax, 600)
                value: U.num(d.current); segmented: true; segments: 24; barColor: root.cPower; negColor: "#5fb0ff"; trackColor: "#0b1622"
            }
            BarMeter {
                x: 20; y: 100; width: 250; height: 40; minValue: 0; maxValue: U.num(d.voltNominal, 1500) * 4 / 3
                value: U.num(d.volt); segmented: true; segments: 20; barColor: "#5fd8ff"; trackColor: "#0b1622"
                marks: [{ v: U.num(d.voltNominal, 1500), color: "#ffffff" }]
            }
        }
        Box {
            title: "空気圧"
            x: 964; y: 414; width: 620; height: 196
            Val { x: 20; y: 6; width: 260; height: 80; label: "BC (ブレーキシリンダ)"; value: rx ? Math.round(U.num(d.bc)) : "--"; unit: "kPa"; valueColor: root.cBrake }
            Val { x: 320; y: 6; width: 270; height: 80; label: "MR (元空気だめ)"; value: rx ? Math.round(U.num(d.mr)) : "--"; unit: "kPa" }
            BarMeter {
                x: 20; y: 100; width: 260; height: 40; minValue: 0; maxValue: Math.max(600, U.num(d.bcEmergency, 500) + 100)
                value: U.num(d.bc); segmented: true; segments: 20; barColor: root.cBrake; trackColor: "#0b1622"
                marks: [{ v: U.num(d.bcService, 440), color: "#ffffff" }, { v: U.num(d.bcEmergency, 500), color: "#ff3b30" }]
            }
            BarMeter {
                x: 320; y: 100; width: 270; height: 40; minValue: 600; maxValue: 1000
                value: U.num(d.mr, 600); segmented: true; segments: 20; barColor: "#e8e8e8"; trackColor: "#0b1622"
                marks: [{ v: U.num(d.mrMin, 780), color: root.cYellow }, { v: U.num(d.mrMax, 880), color: root.cYellow }]
            }
        }

        // 表示灯
        Box {
            x: 332; y: 624; width: 1252; height: 96
            Row {
                anchors.centerIn: parent; spacing: 10
                Repeater {
                    model: [
                        { t: "力行", on: root.n.p > 0 && root.n.b === 0, c: root.cPower },
                        { t: "回生", on: U.num(d.regen) > 0.01, c: "#5fb0ff" },
                        { t: "ブレーキ", on: U.num(d.bc) > 20, c: root.cBrake },
                        { t: "非常", on: !!d.emergency, c: "#ff3b30", blink: true },
                        { t: "CP", on: !!d.cp, c: root.cYellow },
                        { t: "速度超過", on: U.has(d.limit) && root.speed > d.limit + 0.5, c: "#ff3b30", blink: true },
                        { t: "定位置", on: !!d.stop && U.has(d.stop.dist) && Math.abs(d.stop.dist) <= 0.5 && Math.abs(root.speed) < 0.5, c: root.cPower },
                        { t: "分岐 " + (d.switch ? d.switch.way : ""), on: !!d.switch, c: d.switch && d.switch.conflict ? "#ff3b30" : "#d9d9d9" },
                    ]
                    Lamp { width: 142; height: 62; text: modelData.t; on: modelData.on; litColor: modelData.c; blink: !!modelData.blink; fontSize: 22; radius: 3; offColor: "#141c26" }
                }
            }
        }
    }

    // ================= 画面 2: 車両状態 =================
    Item {
        visible: root.pageNo === 1
        x: 16; y: 86; width: parent.width - 32; height: 740
        Box {
            title: "編成 (" + root.carCount + " 両)   ← 前   " + U.str(d.train, "")
            anchors.fill: parent
            Row {
                id: carsRow
                x: 30; y: 60; spacing: 10
                Repeater {
                    model: root.carCount
                    Item {
                        width: (1500 - 10 * (root.carCount - 1)) / root.carCount; height: 520
                        readonly property int carCount: root.carCount
                        readonly property bool head: index === 0 || index === carCount - 1
                        readonly property bool motor: !head && (index % 3 !== 0)
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: (index + 1) + "号車"; color: "white"; font.pixelSize: 24; font.bold: true }
                        Rectangle {
                            y: 40; width: parent.width; height: 110; radius: head ? 0 : 4
                            color: "#0f2742"; border.color: "#7fa7d0"; border.width: 2
                            Text { anchors.centerIn: parent; text: parent.parent.head ? "Tc" : parent.parent.motor ? (index % 3 === 1 ? "M" : "M'") : "T"; color: "white"; font.pixelSize: 40; font.bold: true }
                        }
                        Column {
                            y: 170; width: parent.width; spacing: 10
                            Lamp { width: parent.width; height: 54; text: "力行"; on: parent.parent.motor && root.n.p > 0 && root.n.b === 0; litColor: root.cPower; fontSize: 20; offColor: "#141c26" }
                            Lamp { width: parent.width; height: 54; text: "回生"; on: parent.parent.motor && U.num(d.regen) > 0.01; litColor: "#5fb0ff"; fontSize: 20; offColor: "#141c26" }
                            Lamp { width: parent.width; height: 54; text: "ブレーキ"; on: U.num(d.bc) > 20; litColor: root.cBrake; fontSize: 20; offColor: "#141c26" }
                            Lamp { width: parent.width; height: 54; text: "CP"; on: parent.parent.head && !!d.cp; litColor: root.cYellow; fontSize: 20; offColor: "#141c26" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "BC " + Math.round(U.num(d.bc) * (parent.parent.motor && U.num(d.regen) > 0.01 ? 1 - U.num(d.regen) : 1)); color: "white"; font.pixelSize: 22 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "戸 閉"; color: root.cPower; font.pixelSize: 22 }
                        }
                    }
                }
            }
            Text {
                x: 30; anchors.bottom: parent.bottom; anchors.bottomMargin: 20
                text: "運転モード " + U.str(d.mode) + "    MR " + Math.round(U.num(d.mr)) + " kPa    架線 " + (U.num(d.volt) / 1000).toFixed(2) + " kV    電流 " + Math.round(U.num(d.current)) + " A"
                color: "#d0dbe6"; font.pixelSize: 26
            }
        }
    }

    // ================= 画面 3: 路線 =================
    Item {
        visible: root.pageNo === 2
        x: 16; y: 86; width: parent.width - 32; height: 740
        Box {
            title: "前方の路線"
            x: 0; y: 0; width: 560; height: 720
            RouteStrip {
                anchors.fill: parent; anchors.margins: 10
                items: d.ahead || []; stopDist: d.stop ? U.num(d.stop.dist, NaN) : NaN
                stationColor: "#6fd3ff"; fontSize: 28
            }
        }
        Box {
            title: "駅と分岐"
            x: 576; y: 0; width: 992; height: 720
            Column {
                x: 20; y: 10; width: parent.width - 40; spacing: 0
                Repeater {
                    model: (d.ahead || []).filter(function (a) { return a.dist > -50; }).sort(function (a, b) { return a.dist - b.dist; }).slice(0, 8)
                    Rectangle {
                        width: parent.width; height: 76; color: index % 2 ? "#08131f" : "transparent"
                        Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: modelData.kind === "station" ? "駅" : "分岐"; color: modelData.kind === "station" ? root.cLabel : root.cYellow; font.pixelSize: 26; width: 90 }
                        Text { x: 110; anchors.verticalCenter: parent.verticalCenter; text: modelData.kind === "station" ? modelData.label : (modelData.label === "straight" ? "直進" : modelData.label); color: "white"; font.pixelSize: 38; font.bold: true }
                        Text { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: U.dist(modelData.dist); color: "#d0dbe6"; font.pixelSize: 34 }
                    }
                }
            }
        }
    }

    // ================= 下の画面切替ボタン =================
    Row {
        x: 16; y: 834; spacing: 10
        Repeater {
            model: root.pages.concat(["戸閉", "空調", "案内", "設定"])
            Rectangle {
                width: (1568 - 10 * 6) / 7; height: 56; radius: 3
                readonly property bool sel: index === root.pageNo
                readonly property bool live: index < root.pages.length
                gradient: Gradient {
                    GradientStop { position: 0; color: sel ? "#ffe680" : live ? "#cfd6de" : "#59616a" }
                    GradientStop { position: 1; color: sel ? "#e0b800" : live ? "#8f99a4" : "#3c434a" }
                }
                border.color: sel ? "#fff3b0" : "#2a3038"; border.width: 2
                Text { anchors.centerIn: parent; text: modelData; color: live ? "#0a0f14" : "#9aa1a8"; font.pixelSize: 26; font.bold: true }
                MouseArea { anchors.fill: parent; enabled: parent.live; onClicked: root.pageNo = index }
            }
        }
    }
}

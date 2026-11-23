import QtQuick
import "../parts"
import "../parts/Util.js" as U

// JR東日本 TIMS 風: 黒地・水色の見出し・枠で区切った情報欄・下に画面切替ボタン
Rectangle {
    id: root
    gradient: Gradient {
        GradientStop { position: 0; color: "#01060d" }
        GradientStop { position: 1; color: "#000000" }
    }
    readonly property var d: link.d
    readonly property var n: d.notch || ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    readonly property real speed: U.num(d.speed)
    readonly property bool rx: link.online
    readonly property bool over: U.has(d.limit) && Math.abs(speed) > d.limit + 0.5
    readonly property int carCount: Math.max(2, Math.min(15, U.num(d.cars, 6)))
    property int pageNo: startPage

    readonly property color cLabel: "#6fd3ff"
    readonly property color cFrame: "#3d5d7e"
    readonly property color cPanel: "#050e19"
    readonly property color cValue: "#ffffff"
    readonly property color cYellow: "#ffe14d"
    readonly property color cPower: "#36e36f"
    readonly property color cBrake: "#ff9a2e"
    readonly property color cRegen: "#5fb0ff"
    readonly property var pages: ["運転情報", "車両状態", "運転記録", "路線"]

    function key(k) {
        if (k === Qt.Key_Right) pageNo = (pageNo + 1) % pages.length;
        else if (k === Qt.Key_Left) pageNo = (pageNo + pages.length - 1) % pages.length;
    }

    // 見出し付きの枠 (角に明るい鉤、見出しは帯)
    component Box: Rectangle {
        id: box
        property string title: ""
        property string badge: ""
        default property alias content: inner.data
        color: root.cPanel
        border.color: root.cFrame; border.width: 2
        Rectangle {
            id: cap
            visible: box.title.length > 0
            x: 2; y: 2; width: box.width - 4; height: 38
            gradient: Gradient { GradientStop { position: 0; color: "#1a3d66" } GradientStop { position: 1; color: "#0c223b" } }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.18) }
            Rectangle { x: 10; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 18; color: root.cLabel }
            Text { x: 26; anchors.verticalCenter: parent.verticalCenter; text: box.title; color: "white"; font.pixelSize: 22; font.bold: true }
            Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: box.badge; color: root.cLabel; font.pixelSize: 18 }
        }
        // 角の鉤
        Repeater {
            model: 4
            Item {
                x: index % 2 ? box.width - 16 : 0; y: index < 2 ? 0 : box.height - 16; width: 16; height: 16
                Rectangle { x: index % 2 ? 0 : 0; y: index < 2 ? 0 : 14; width: 16; height: 2; color: "#8fc8ff" }
                Rectangle { x: index % 2 ? 14 : 0; y: 0; width: 2; height: 16; color: "#8fc8ff" }
            }
        }
        Item { id: inner; x: 2; y: cap.visible ? 42 : 2; width: box.width - 4; height: box.height - y - 2 }
    }
    // ラベル + 大きな値 + 単位
    component Val: Item {
        id: val
        property string label: ""
        property string value: "--"
        property string unit: ""
        property color valueColor: root.cValue
        property real size: 46
        Text { text: val.label; color: root.cLabel; font.pixelSize: 20; anchors.left: parent.left; anchors.top: parent.top }
        Text {
            id: vv; text: val.value; color: val.valueColor; font.pixelSize: val.size; font.bold: true
            anchors.right: un.left; anchors.rightMargin: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: -4
        }
        Text { id: un; text: val.unit; color: "#b8c6d4"; font.pixelSize: 20; anchors.right: parent.right; anchors.baseline: vv.baseline }
    }
    // 情報帯の 1 区画
    component Cell: Rectangle {
        id: cl
        property string label: ""
        property string value: ""
        property color valueColor: "white"
        height: 34; color: "#071526"; border.color: "#24476b"; border.width: 1
        Rectangle { width: lb.implicitWidth + 20; height: parent.height; color: "#16365a"
            Text { id: lb; anchors.centerIn: parent; text: cl.label; color: root.cLabel; font.pixelSize: 18 } }
        Text { x: lb.implicitWidth + 32; anchors.verticalCenter: parent.verticalCenter; width: parent.width - x - 8; elide: Text.ElideRight
            text: cl.value; color: cl.valueColor; font.pixelSize: 21; font.bold: true }
    }

    // ================= 上の帯 =================
    Rectangle {
        id: header
        width: parent.width; height: 72
        gradient: Gradient { GradientStop { position: 0; color: "#1d4a80" } GradientStop { position: 0.5; color: "#123562" } GradientStop { position: 1; color: "#091b33" } }
        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.3) }
        Rectangle { width: parent.width; height: 2; anchors.bottom: parent.bottom; color: "#6aa0d8" }
        Text { x: 24; anchors.verticalCenter: parent.verticalCenter; text: root.pages[root.pageNo]; color: "white"; font.pixelSize: 34; font.bold: true; style: Text.Raised; styleColor: "#000" }
        Row {
            x: 300; anchors.verticalCenter: parent.verticalCenter; spacing: 12
            Rectangle {
                width: 196; height: 52; color: "black"; border.color: "#dfe7ef"; border.width: 2
                Rectangle { anchors.fill: parent; anchors.margins: 4; color: "transparent"; border.color: "#2a3a4a" }
                Text { anchors.centerIn: parent; text: U.str(d.train ? String(d.train).split(" ")[0] : null, "----"); color: root.cYellow; font.pixelSize: 32; font.bold: true }
            }
            Rectangle {
                width: 112; height: 52; radius: 4
                gradient: Gradient { GradientStop { position: 0; color: "#19a352" } GradientStop { position: 1; color: "#0a6b33" } }
                border.color: "#5fe08f"
                Text { anchors.centerIn: parent; text: d.train && String(d.train).split(" ").length > 1 ? String(d.train).split(" ")[1] : "普通"; color: "white"; font.pixelSize: 28; font.bold: true }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: U.str(d.line, "") + (d.cars ? "  " + d.cars + "両編成" : ""); color: "white"; font.pixelSize: 26 }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 18
            Lamp {
                width: 140; height: 46; radius: 4; fontSize: 22
                text: !rx ? "受信なし" : !d.output ? "出力OFF" : "伝送正常"; on: true
                litColor: !rx ? "#c62828" : !d.output ? "#b77900" : "#13803d"; litText: "white"
                blink: !rx
            }
            Rectangle {
                width: 190; height: 52; color: "#02070d"; border.color: "#3b5f86"
                Clock { anchors.centerIn: parent; color: "white"; font.pixelSize: 36; font.bold: true }
            }
        }
    }

    // ================= 情報帯 =================
    Row {
        x: 16; y: 78; spacing: 6
        Cell { width: 330; label: d.at ? "停車中" : "次停車"; value: U.str(d.at || d.next) + (d.at ? "" : "  " + U.dist(d.nextDist)) }
        Cell { width: 380; label: "現在地"; value: d.at ? d.at + " 構内" : (d.prev && d.next ? d.prev + " → " + d.next : "—") }
        Cell { width: 250; label: "運転"; value: U.str(d.mode); valueColor: root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : "white" }
        Cell { width: 300; label: "保安"; value: U.has(d.limit) ? "ATC  制限 " + Math.round(d.limit) + " km/h" : "—"; valueColor: root.over ? "#ff5a50" : root.cYellow }
        Cell { width: 280; label: "分岐"; value: d.switch ? d.switch.way + "  " + Math.round(d.switch.dist) + " m" : "—"; valueColor: d.switch && d.switch.conflict ? "#ff5a50" : "white" }
    }

    // ================= 画面 1: 運転情報 =================
    Item {
        visible: root.pageNo === 0
        x: 0; y: 120; width: parent.width; height: 700

        // ノッチ
        Box {
            title: "ノッチ"; badge: root.n.pending ? "送信待ち " + root.n.pending : ""
            x: 16; y: 0; width: 290; height: 700
            Rectangle {
                x: 24; y: 8; width: parent.width - 48; height: 84; color: "#02070d"; border.color: "#24476b"
                Text {
                    anchors.centerIn: parent
                    text: U.notchName(root.n)
                    color: root.n.b > 0 ? (root.n.b > root.n.maxB ? "#ff3b30" : root.cBrake) : root.n.p > 0 ? root.cPower : "white"
                    font.pixelSize: 64; font.bold: true
                }
            }
            NotchLadder {
                x: 44; y: 106; width: parent.width - 88; height: parent.height - 162
                n: root.n; powerColor: root.cPower; brakeColor: root.cBrake; fontSize: 22; gap: 5; radius: 3
                offColor: "#111a25"; offText: "#4a5868"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                text: "レバーサ  " + U.revName(root.n.rev); color: "#c6d4e2"; font.pixelSize: 22
            }
        }

        // 速度
        Box {
            title: "速度"; badge: "km/h"
            x: 322; y: 0; width: 670; height: 380
            Column {
                x: 22; y: 14; spacing: 6
                Text { text: "制限速度"; color: root.cLabel; font.pixelSize: 20 }
                Rectangle {
                    width: 128; height: 80; color: "black"; border.color: root.over ? "#ff3b30" : root.cYellow; border.width: 3
                    Rectangle { anchors.fill: parent; anchors.margins: 5; color: "transparent"; border.color: Qt.rgba(1, 0.88, 0.3, 0.3) }
                    Text { anchors.centerIn: parent; text: U.has(d.limit) ? Math.round(d.limit) : "--"; color: root.over ? "#ff5a50" : root.cYellow; font.pixelSize: 50; font.bold: true }
                }
                Item { width: 1; height: 6 }
                Text { text: "加速度 km/h/s"; color: root.cLabel; font.pixelSize: 20 }
                Text { text: U.sign(d.accel, 1); color: U.num(d.accel) < -0.05 ? root.cBrake : U.num(d.accel) > 0.05 ? root.cPower : "white"; font.pixelSize: 38; font.bold: true }
            }
            Text {
                x: 196; y: 6; width: 430; height: 190; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                text: rx && U.has(d.speed) ? Math.round(Math.abs(root.speed)).toString() : "--"
                color: root.over ? "#ff3b30" : "white"
                font.pixelSize: 176; font.bold: true
                style: Text.Outline; styleColor: root.over ? "#5a0b08" : "#0d2a45"
            }
            // 速度の帯 (制限まで緑、超えると赤)
            BarMeter {
                x: 22; y: 236; width: parent.width - 44; height: 60
                minValue: 0; maxValue: U.num(d.speedMax, 120); value: Math.abs(root.speed)
                segmented: true; segments: 60
                barColor: root.over ? "#ff3b30" : "#5fd8ff"
                trackColor: "#07111c"; majorStep: 20; fontSize: 18; tickColor: "#b8c6d4"
                marks: U.has(d.limit) ? [{ v: d.limit, color: root.cYellow }] : []
            }
            Canvas {
                // 制限速度の旗
                x: 22; y: 214; width: parent.width - 44; height: 22
                property real lim: U.has(d.limit) ? d.limit : -1
                property real mx: U.num(d.speedMax, 120)
                onLimChanged: requestPaint(); onMxChanged: requestPaint()
                onPaint: {
                    var c = getContext("2d"); c.reset();
                    if (lim < 0) return;
                    var x = width * Math.min(1, lim / mx);
                    c.fillStyle = "#ffe14d";
                    c.beginPath(); c.moveTo(x, height); c.lineTo(x - 11, 2); c.lineTo(x + 11, 2); c.closePath(); c.fill();
                }
            }
        }

        // 次駅・停止位置
        Box {
            title: "停止位置"; badge: d.stop && d.stop.marker ? "目標 " + d.stop.marker : ""
            x: 1008; y: 0; width: 576; height: 380
            Text { x: 22; y: 8; text: U.str(d.stop ? d.stop.station : (d.at || d.next)); color: "white"; font.pixelSize: 52; font.bold: true; width: parent.width - 44; elide: Text.ElideRight }
            Text { x: 22; y: 82; text: "停止位置まで"; color: root.cLabel; font.pixelSize: 22 }
            Item {
                x: 22; y: 92; width: parent.width - 44; height: 140
                Text {
                    id: sd
                    readonly property real v: d.stop ? U.num(d.stop.dist, NaN) : NaN
                    anchors.right: sdu.left; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                    text: U.distNum(v)
                    color: isNaN(v) ? "#6b7886" : Math.abs(v) <= 0.5 ? root.cPower : v < 0 ? "#ff3b30" : v < 10 ? root.cYellow : "white"
                    font.pixelSize: 104; font.bold: true
                }
                Text { id: sdu; anchors.right: parent.right; anchors.baseline: sd.baseline; text: U.distUnit(sd.v); color: "#b8c6d4"; font.pixelSize: 30 }
            }
            StopTape {
                x: 22; y: 246; width: parent.width - 44; height: 74
                dist: sd.v; range: 10; tol: 0.5; fontSize: 16
            }
        }

        // 電気・空気
        Box {
            title: "架線電圧・主回路電流"
            x: 322; y: 394; width: 620; height: 190
            Val { x: 20; y: 6; width: 250; height: 80; label: "架線電圧"; value: rx ? (U.num(d.volt) / 1000).toFixed(2) : "--"; unit: "kV" }
            Val { x: 320; y: 6; width: 270; height: 80; label: U.num(d.current) < -1 ? "回生電流" : "力行電流"; value: rx ? Math.round(U.num(d.current)) : "--"; unit: "A"; valueColor: U.num(d.current) < -1 ? root.cRegen : "white" }
            BarMeter {
                x: 320; y: 98; width: 270; height: 36; minValue: -U.num(d.currentMax, 600); maxValue: U.num(d.currentMax, 600)
                value: U.num(d.current); segmented: true; segments: 24; barColor: root.cPower; negColor: root.cRegen; trackColor: "#07111c"
                marks: [{ v: 0, color: "#ffffff" }]
            }
            BarMeter {
                x: 20; y: 98; width: 250; height: 36; minValue: 0; maxValue: U.num(d.voltNominal, 1500) * 4 / 3
                value: U.num(d.volt); segmented: true; segments: 20; barColor: "#5fd8ff"; trackColor: "#07111c"
                marks: [{ v: U.num(d.voltNominal, 1500), color: "#ffffff" }]
            }
        }
        Box {
            title: "空気圧"; badge: d.cp ? "CP 運転中" : ""
            x: 964; y: 394; width: 620; height: 190
            Val { x: 20; y: 6; width: 260; height: 80; label: "BC ブレーキシリンダ"; value: rx ? Math.round(U.num(d.bc)) : "--"; unit: "kPa"; valueColor: root.cBrake }
            Val { x: 320; y: 6; width: 270; height: 80; label: "MR 元空気だめ"; value: rx ? Math.round(U.num(d.mr)) : "--"; unit: "kPa" }
            BarMeter {
                x: 20; y: 98; width: 260; height: 36; minValue: 0; maxValue: Math.max(600, U.num(d.bcEmergency, 500) + 100)
                value: U.num(d.bc); segmented: true; segments: 20; barColor: root.cBrake; trackColor: "#07111c"
                marks: [{ v: U.num(d.bcService, 440), color: "#ffffff" }, { v: U.num(d.bcEmergency, 500), color: "#ff3b30" }]
            }
            BarMeter {
                x: 320; y: 98; width: 270; height: 36; minValue: 600; maxValue: 1000
                value: U.num(d.mr, 600); segmented: true; segments: 20; barColor: "#e8e8e8"; trackColor: "#07111c"
                marks: [{ v: U.num(d.mrMin, 780), color: root.cYellow }, { v: U.num(d.mrMax, 880), color: root.cYellow }]
            }
        }

        // 表示灯
        Box {
            x: 322; y: 598; width: 1262; height: 102
            Row {
                anchors.centerIn: parent; spacing: 10
                Repeater {
                    model: [
                        { t: "力行", on: root.n.p > 0 && root.n.b === 0, c: root.cPower },
                        { t: "回生", on: U.num(d.regen) > 0.01, c: root.cRegen },
                        { t: "ブレーキ", on: U.num(d.bc) > 20, c: root.cBrake },
                        { t: "非常", on: !!d.emergency, c: "#ff3b30", blink: true },
                        { t: "CP", on: !!d.cp, c: root.cYellow },
                        { t: "速度超過", on: root.over, c: "#ff3b30", blink: true },
                        { t: "定位置", on: !!d.stop && U.has(d.stop.dist) && Math.abs(d.stop.dist) <= 0.5 && Math.abs(root.speed) < 0.5, c: root.cPower },
                        { t: "戸閉", on: rx, c: "#e8f0f8" },
                    ]
                    Lamp { width: 143; height: 64; text: modelData.t; on: modelData.on; litColor: modelData.c; blink: !!modelData.blink; fontSize: 22; radius: 3; offColor: "#111a25"; offText: "#4a5868" }
                }
            }
        }
    }

    // ================= 画面 2: 車両状態 =================
    Item {
        visible: root.pageNo === 1
        x: 16; y: 120; width: parent.width - 32; height: 700
        Box {
            title: "編成"; badge: root.carCount + " 両   ← 進行方向"
            anchors.fill: parent
            // 車体
            Row {
                id: carsRow
                x: 30; y: 40; spacing: 8
                Repeater {
                    model: root.carCount
                    Item {
                        id: car
                        width: (1500 - 8 * (root.carCount - 1)) / root.carCount; height: 600
                        readonly property bool head: index === 0 || index === root.carCount - 1
                        readonly property bool motor: !head && (index % 3 !== 0)
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: (index + 1) + "号車"; color: "white"; font.pixelSize: 24; font.bold: true }
                        Canvas {
                            y: 36; width: parent.width; height: 120
                            onPaint: {
                                var c = getContext("2d"); c.reset();
                                var w = width, h = height, nose = 26;
                                c.beginPath();
                                if (index === 0) { c.moveTo(nose, 0); c.lineTo(w, 0); c.lineTo(w, h - 18); c.lineTo(0, h - 18); c.lineTo(0, 30); c.closePath(); }
                                else if (index === root.carCount - 1) { c.moveTo(0, 0); c.lineTo(w - nose, 0); c.lineTo(w, 30); c.lineTo(w, h - 18); c.lineTo(0, h - 18); c.closePath(); }
                                else { c.rect(0, 0, w, h - 18); }
                                var g = c.createLinearGradient(0, 0, 0, h);
                                g.addColorStop(0, "#21486f"); g.addColorStop(1, "#0d2338");
                                c.fillStyle = g; c.fill();
                                c.lineWidth = 2; c.strokeStyle = "#8fb8e0"; c.stroke();
                                // 窓と帯
                                c.fillStyle = "#081420";
                                for (var i = 0; i < 3; i++) c.fillRect(16 + i * (w - 32) / 3, 22, (w - 32) / 3 - 10, 26);
                                c.fillStyle = "#19a352"; c.fillRect(2, h - 40, w - 4, 6);
                                // 台車
                                c.fillStyle = "#6f8396";
                                c.fillRect(14, h - 16, 40, 12); c.fillRect(w - 54, h - 16, 40, 12);
                                c.beginPath(); c.arc(24, h - 4, 4, 0, Math.PI * 2); c.arc(44, h - 4, 4, 0, Math.PI * 2); c.fill();
                                c.beginPath(); c.arc(w - 44, h - 4, 4, 0, Math.PI * 2); c.arc(w - 24, h - 4, 4, 0, Math.PI * 2); c.fill();
                                // パンタグラフ (M 車)
                                if (car.motor && index % 3 === 1) {
                                    c.strokeStyle = "#cfd8e2"; c.lineWidth = 2;
                                    c.beginPath(); c.moveTo(w / 2 - 22, 0); c.lineTo(w / 2, -14); c.lineTo(w / 2 + 22, 0); c.stroke();
                                }
                            }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 74; text: car.head ? "Tc" : car.motor ? (index % 3 === 1 ? "M" : "M'") : "T"; color: "white"; font.pixelSize: 30; font.bold: true }
                        Column {
                            y: 176; width: parent.width; spacing: 8
                            Lamp { width: parent.width; height: 50; text: "力行"; on: car.motor && root.n.p > 0 && root.n.b === 0; litColor: root.cPower; fontSize: 20; offColor: "#111a25"; offText: "#4a5868" }
                            Lamp { width: parent.width; height: 50; text: "回生"; on: car.motor && U.num(d.regen) > 0.01; litColor: root.cRegen; fontSize: 20; offColor: "#111a25"; offText: "#4a5868" }
                            Lamp { width: parent.width; height: 50; text: "ブレーキ"; on: U.num(d.bc) > 20; litColor: root.cBrake; fontSize: 20; offColor: "#111a25"; offText: "#4a5868" }
                            Lamp { width: parent.width; height: 50; text: "CP"; on: car.head && !!d.cp; litColor: root.cYellow; fontSize: 20; offColor: "#111a25"; offText: "#4a5868" }
                            Lamp { width: parent.width; height: 50; text: "SIV"; on: car.head && rx; litColor: "#cfe3ff"; fontSize: 20; offColor: "#111a25"; offText: "#4a5868" }
                            Rectangle {
                                width: parent.width; height: 62; color: "#02070d"; border.color: "#24476b"
                                Text { x: 8; y: 4; text: "BC"; color: root.cLabel; font.pixelSize: 16 }
                                Text {
                                    anchors.right: parent.right; anchors.rightMargin: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                                    text: Math.round(U.num(d.bc) * (car.motor && U.num(d.regen) > 0.01 ? 1 - U.num(d.regen) : 1)); color: "white"; font.pixelSize: 32; font.bold: true
                                }
                            }
                        }
                    }
                }
            }
            Text {
                x: 30; anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                text: "運転モード " + U.str(d.mode) + "     MR " + Math.round(U.num(d.mr)) + " kPa     架線 " + (U.num(d.volt) / 1000).toFixed(2) + " kV     電流 " + Math.round(U.num(d.current)) + " A"
                color: "#d0dbe6"; font.pixelSize: 24
            }
        }
    }

    // ================= 画面 3: 運転記録 =================
    Item {
        visible: root.pageNo === 2
        x: 16; y: 120; width: parent.width - 32; height: 700
        Box {
            title: "運転記録 (直近 2 分)"; badge: "青 速度   黄 制限   緑 力行 / 橙 ブレーキ"
            anchors.fill: parent
            HistoryChart {
                anchors.fill: parent; anchors.margins: 14
                d: root.d; speedMax: U.num(d.speedMax, 120); fontSize: 18
                powerColor: root.cPower; brakeColor: root.cBrake; limitColor: root.cYellow
            }
        }
    }

    // ================= 画面 4: 路線 =================
    Item {
        visible: root.pageNo === 3
        x: 16; y: 120; width: parent.width - 32; height: 700
        Box {
            title: "前方の路線"
            x: 0; y: 0; width: 560; height: 700
            RouteStrip {
                anchors.fill: parent; anchors.margins: 10
                items: d.ahead || []; stopDist: d.stop ? U.num(d.stop.dist, NaN) : NaN
                stationColor: "#6fd3ff"; fontSize: 28
            }
        }
        Box {
            title: "駅と分岐"
            x: 576; y: 0; width: 992; height: 700
            Column {
                x: 20; y: 10; width: parent.width - 40; spacing: 0
                Repeater {
                    model: (d.ahead || []).filter(function (a) { return a.dist > -50; }).sort(function (a, b) { return a.dist - b.dist; }).slice(0, 8)
                    Rectangle {
                        width: parent.width; height: 76; color: index % 2 ? "#08131f" : "transparent"
                        Rectangle { width: 6; height: parent.height - 16; anchors.verticalCenter: parent.verticalCenter; color: modelData.kind === "station" ? root.cLabel : root.cYellow }
                        Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: modelData.kind === "station" ? "駅" : "分岐"; color: modelData.kind === "station" ? root.cLabel : root.cYellow; font.pixelSize: 26; width: 90 }
                        Text { x: 110; anchors.verticalCenter: parent.verticalCenter; text: modelData.kind === "station" ? modelData.label : (modelData.label === "straight" ? "直進" : modelData.label); color: "white"; font.pixelSize: 38; font.bold: true }
                        Text { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: U.dist(modelData.dist); color: "#d0dbe6"; font.pixelSize: 34 }
                    }
                }
            }
        }
    }

    // ================= 下の画面切替ボタン =================
    Rectangle {
        x: 0; y: 828; width: parent.width; height: 72; color: "#0a0f16"
        Rectangle { width: parent.width; height: 1; color: "#2b3c50" }
    }
    Row {
        x: 16; y: 836; spacing: 10
        Repeater {
            model: root.pages.concat(["戸閉", "空調", "設定"])
            Item {
                id: btn
                width: (1568 - 10 * 6) / 7; height: 56
                readonly property bool sel: index === root.pageNo
                readonly property bool live: index < root.pages.length
                Rectangle { anchors.fill: parent; anchors.topMargin: 4; radius: 4; color: "#000" ; opacity: 0.6 }
                Rectangle {
                    width: parent.width; height: parent.height - (parent.sel ? 0 : 3); y: parent.sel ? 3 : 0; radius: 4
                    gradient: Gradient {
                        GradientStop { position: 0; color: btn.sel ? "#fff1a0" : btn.live ? "#e6ebf0" : "#5d656e" }
                        GradientStop { position: 0.5; color: btn.sel ? "#f2c919" : btn.live ? "#b6c0ca" : "#474e56" }
                        GradientStop { position: 1; color: btn.sel ? "#c79b00" : btn.live ? "#8a96a2" : "#363c42" }
                    }
                    border.color: parent.sel ? "#fff6c0" : "#20262d"; border.width: 2
                    Text { anchors.centerIn: parent; text: modelData; color: btn.live ? "#0a0f14" : "#a2a9b0"; font.pixelSize: 25; font.bold: true }
                }
                MouseArea { anchors.fill: parent; enabled: parent.live; onClicked: root.pageNo = index }
            }
        }
    }
}

import QtQuick
import "../parts"
import "../parts/Util.js" as U

// JR東日本 TIMS 風: 黒地・水色の見出し・枠で区切った情報欄・下に画面切替ボタン
Rectangle {
    id: root
    color: "#04090f"
    readonly property var d: link.d
    readonly property var n: d.notch || ({ p: 0, b: 0, maxP: 5, maxB: 8 })
    readonly property real speed: U.num(d.speed)
    readonly property bool rx: link.online
    readonly property bool over: U.has(d.limit) && Math.abs(speed) > d.limit + 0.5
    readonly property int carCount: Math.max(2, Math.min(15, U.num(d.cars, 6)))
    property int pageNo: startPage

    readonly property color cLabel: "#6cc8f5"
    readonly property color cFrame: "#1f3a57"
    readonly property color cPanel: "#0a1622"
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

    // 見出し付きの枠 (平ら。見出しは水色の文字と細い線)
    component Box: Rectangle {
        id: box
        property string title: ""
        property string badge: ""
        default property alias content: inner.data
        color: root.cPanel; radius: 6
        border.color: root.cFrame; border.width: 1
        Item {
            id: cap
            visible: box.title.length > 0
            x: 16; y: 0; width: box.width - 32; height: 40
            Text { anchors.verticalCenter: parent.verticalCenter; text: box.title; color: root.cLabel; font.pixelSize: 18; font.weight: Font.DemiBold }
            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: box.badge; color: "#7f97b0"; font.pixelSize: 16 }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.cFrame }
        }
        Item { id: inner; x: 0; y: cap.visible ? 40 : 0; width: box.width; height: box.height - y }
    }
    // ラベル + 大きな値 + 単位
    component Val: Item {
        id: val
        property string label: ""
        property string value: "--"
        property string unit: ""
        property color valueColor: root.cValue
        property real size: 34
        Text { text: val.label; color: root.cLabel; font.pixelSize: 16; anchors.left: parent.left; anchors.top: parent.top }
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
        height: 36; radius: 6; color: root.cPanel; border.color: root.cFrame; border.width: 1
        Text { id: lb; x: 14; anchors.verticalCenter: parent.verticalCenter; text: cl.label; color: root.cLabel; font.pixelSize: 15 }
        Text { x: lb.implicitWidth + 26; anchors.verticalCenter: parent.verticalCenter; width: parent.width - x - 10; elide: Text.ElideRight
            text: cl.value; color: cl.valueColor; font.pixelSize: 18; font.weight: Font.DemiBold }
    }

    // ================= 上の帯 =================
    Rectangle {
        id: header
        width: parent.width; height: 64; color: "#0d2138"
        Rectangle { width: parent.width; height: 2; anchors.bottom: parent.bottom; color: "#2f6ea8" }
        Text { x: 24; anchors.verticalCenter: parent.verticalCenter; text: root.pages[root.pageNo]; color: "white"; font.pixelSize: 26; font.weight: Font.DemiBold }
        Row {
            x: 260; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Rectangle {
                width: 150; height: 40; radius: 6; color: "#04090f"; border.color: "#3d5a78"
                Text { anchors.centerIn: parent; text: U.str(d.train ? String(d.train).split(" ")[0] : null, "----"); color: root.cYellow; font.pixelSize: 22; font.weight: Font.DemiBold }
            }
            Rectangle {
                width: 80; height: 40; radius: 6; color: "#16824a"
                Text { anchors.centerIn: parent; text: d.train && String(d.train).split(" ").length > 1 ? String(d.train).split(" ")[1] : "普通"; color: "white"; font.pixelSize: 20; font.weight: Font.DemiBold }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: U.str(d.line, "") + (d.cars ? "   " + d.cars + "両編成" : ""); color: "#c9d6e3"; font.pixelSize: 19 }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 24; anchors.verticalCenter: parent.verticalCenter; spacing: 20
            Row {
                anchors.verticalCenter: parent.verticalCenter; spacing: 8
                Rectangle { width: 10; height: 10; radius: 5; anchors.verticalCenter: parent.verticalCenter; color: !rx ? "#ff5a4f" : !d.output ? root.cYellow : root.cPower }
                Text { text: !rx ? "受信なし" : !d.output ? "出力OFF" : "伝送正常"; color: "#c9d6e3"; font.pixelSize: 17 }
            }
            Clock { color: "white"; font.pixelSize: 26; font.weight: Font.DemiBold }
        }
    }

    // ================= 情報帯 =================
    Row {
        x: 16; y: 74; spacing: 8
        Cell { width: 324; label: d.at ? "停車中" : "次停車"; value: U.str(d.at || d.next) + (d.at ? "" : "  " + U.dist(d.nextDist)) }
        Cell { width: 372; label: "現在地"; value: d.at ? d.at + " 構内" : (d.prev && d.next ? d.prev + " → " + d.next : "—") }
        Cell { width: 244; label: "運転"; value: U.str(d.mode); valueColor: root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : "white" }
        Cell { width: 300; label: "保安"; value: U.has(d.limit) ? "ATC  制限 " + Math.round(d.limit) + " km/h" : "—"; valueColor: root.over ? "#ff5a50" : root.cYellow }
        Cell { width: 280; label: "分岐"; value: d.switch ? d.switch.way + "  " + Math.round(d.switch.dist) + " m" : "—"; valueColor: d.switch && d.switch.conflict ? "#ff5a50" : "white" }
    }

    // ================= 画面 1: 運転情報 =================
    Item {
        visible: root.pageNo === 0
        x: 0; y: 122; width: parent.width; height: 698

        // ノッチ
        Box {
            title: "ノッチ"; badge: root.n.pending ? "送信待ち " + root.n.pending : ""
            x: 16; y: 0; width: 260; height: 698
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; y: 12
                text: U.notchName(root.n)
                color: root.n.b > 0 ? (root.n.b > root.n.maxB ? "#ff5a4f" : root.cBrake) : root.n.p > 0 ? root.cPower : "white"
                font.pixelSize: 48; font.weight: Font.DemiBold
            }
            NotchLadder {
                x: 40; y: 86; width: parent.width - 80; height: parent.height - 172
                n: root.n; powerColor: root.cPower; brakeColor: root.cBrake; fontSize: 17; gap: 4; radius: 4
                offColor: "#122130"; offText: "#4a6078"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                text: "レバーサ  " + U.revName(root.n.rev); color: "#c6d4e2"; font.pixelSize: 17
            }
        }

        // 速度 (アナログ)
        Box {
            title: "速度"; badge: "km/h"
            x: 292; y: 0; width: 610; height: 430
            ModernGauge {
                x: 210; y: 4; width: 380; height: 380
                minValue: 0; maxValue: U.num(d.speedMax, 120)
                majorStep: maxValue > 160 ? 40 : 20; minorStep: maxValue > 160 ? 10 : 5
                value: Math.abs(root.speed); limit: U.has(d.limit) ? d.limit : NaN
                zones: U.has(d.limit) ? [{ from: d.limit, to: maxValue, color: Qt.rgba(1, 0.35, 0.3, 0.6) }] : []
                valueText: rx && U.has(d.speed) ? Math.round(Math.abs(root.speed)).toString() : "--"
                unit: "km/h"; accent: "#5fc6ff"; track: "#16273a"; tickColor: "#3e5670"; labelColor: "#8fa8c2"
                limitColor: root.cYellow; valueSize: 0.26; thickness: 0.06; dim: !rx
            }
            Column {
                x: 20; y: 16; spacing: 6
                Text { text: "制限速度"; color: root.cLabel; font.pixelSize: 16 }
                Rectangle {
                    width: 112; height: 64; radius: 6; color: "#04090f"; border.color: root.over ? "#ff5a4f" : root.cYellow; border.width: 2
                    Text { anchors.centerIn: parent; text: U.has(d.limit) ? Math.round(d.limit) : "--"; color: root.over ? "#ff5a4f" : root.cYellow; font.pixelSize: 34; font.weight: Font.DemiBold }
                }
                Item { width: 1; height: 14 }
                Text { text: "加速度"; color: root.cLabel; font.pixelSize: 16 }
                Row {
                    spacing: 6
                    Text { id: acc; text: U.sign(d.accel, 1); color: U.num(d.accel) < -0.05 ? root.cBrake : U.num(d.accel) > 0.05 ? root.cPower : "white"; font.pixelSize: 30; font.weight: Font.DemiBold }
                    Text { text: "km/h/s"; color: "#8fa8c2"; font.pixelSize: 14; anchors.baseline: acc.baseline }
                }
                Item { width: 1; height: 14 }
                Text { text: "運転"; color: root.cLabel; font.pixelSize: 16 }
                Text { text: U.str(d.mode); color: root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : "white"; font.pixelSize: 26; font.weight: Font.DemiBold }
            }
        }

        // 停止位置
        Box {
            title: "停止位置"; badge: d.stop && d.stop.marker ? "目標 " + d.stop.marker : ""
            x: 918; y: 0; width: 666; height: 430
            Text { x: 24; y: 18; text: U.str(d.stop ? d.stop.station : (d.at || d.next)); color: "white"; font.pixelSize: 34; font.weight: Font.DemiBold; width: parent.width - 48; elide: Text.ElideRight }
            Text { x: 24; y: 78; text: "停止位置まで"; color: root.cLabel; font.pixelSize: 16 }
            Row {
                x: 24; y: 104; spacing: 8
                Text {
                    id: sd
                    readonly property real v: d.stop ? U.num(d.stop.dist, NaN) : NaN
                    text: U.distNum(v)
                    color: isNaN(v) ? "#5a6c80" : Math.abs(v) <= 0.5 ? root.cPower : v < 0 ? "#ff5a4f" : v < 10 ? root.cYellow : "white"
                    font.pixelSize: 80; font.weight: Font.DemiBold
                }
                Text { text: U.distUnit(sd.v); color: "#8fa8c2"; font.pixelSize: 22; anchors.baseline: sd.baseline }
            }
            StopTape {
                x: 24; y: 236; width: parent.width - 48; height: 70
                dist: sd.v; range: 10; tol: 0.5; fontSize: 14
                bg: "#0f1e2e"; tickColor: "#4f6a86"
            }
            Row {
                x: 24; y: 330; spacing: 40
                Column { spacing: 4
                    Text { text: "次駅"; color: root.cLabel; font.pixelSize: 16 }
                    Text { text: U.str(d.at ? d.at + " 構内" : d.next) + (d.at ? "" : "  " + U.dist(d.nextDist)); color: "white"; font.pixelSize: 22; font.weight: Font.DemiBold } }
                Column { spacing: 4
                    Text { text: "分岐"; color: root.cLabel; font.pixelSize: 16 }
                    Text { text: d.switch ? d.switch.way + "  " + Math.round(d.switch.dist) + " m" : "—"; color: d.switch && d.switch.conflict ? "#ff5a4f" : "white"; font.pixelSize: 22; font.weight: Font.DemiBold } }
            }
        }

        // 電気・空気 (アナログ 4 つ)
        Box {
            title: "電気・空気"; badge: d.cp ? "CP 運転中" : ""
            x: 292; y: 446; width: 1292; height: 180
            Row {
                x: 16; y: 4; spacing: 0
                Repeater {
                    model: [
                        { l: "架線電圧", u: "kV", min: 0, max: Math.ceil(U.num(d.voltNominal, 1500) * 4 / 3 / 100) * 100, st: 500, div: 1000, dec: 1, v: U.num(d.volt), t: (U.num(d.volt) / 1000).toFixed(2), c: "#5fc6ff" },
                        { l: U.num(d.current) < -1 ? "回生電流" : "主回路電流", u: "A", min: -U.num(d.currentMax, 600), max: U.num(d.currentMax, 600), st: 300, div: 1, dec: 0, v: U.num(d.current), t: Math.round(U.num(d.current)).toString(), c: root.cPower },
                        { l: "BC ブレーキシリンダ", u: "kPa", min: 0, max: Math.max(600, Math.ceil((U.num(d.bcEmergency, 500) + 50) / 100) * 100), st: 200, div: 1, dec: 0, v: U.num(d.bc), t: Math.round(U.num(d.bc)).toString(), c: root.cBrake },
                        { l: "MR 元空気だめ", u: "kPa", min: 0, max: 1000, st: 200, div: 1, dec: 0, v: U.num(d.mr), t: Math.round(U.num(d.mr)).toString(), c: "#d8e2ec" },
                    ]
                    Item {
                        width: 315; height: 134
                        ModernGauge {
                            x: 0; y: 0; width: 134; height: 134
                            minValue: modelData.min; maxValue: modelData.max; majorStep: modelData.st; minorStep: modelData.st / 2
                            labelDivisor: modelData.div; labelDecimals: modelData.dec
                            value: modelData.v; accent: modelData.c; negAccent: "#5fb0ff"
                            track: "#16273a"; tickColor: "#3e5670"; labelColor: "#7f97b0"; thickness: 0.09; showLabels: false
                            dim: !rx
                        }
                        Column {
                            x: 148; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Text { text: modelData.l; color: root.cLabel; font.pixelSize: 16 }
                            Row {
                                spacing: 6
                                Text { id: gv; text: rx ? modelData.t : "--"; color: "white"; font.pixelSize: 34; font.weight: Font.DemiBold }
                                Text { text: modelData.u; color: "#8fa8c2"; font.pixelSize: 15; anchors.baseline: gv.baseline }
                            }
                        }
                    }
                }
            }
        }

        // 表示灯
        Row {
            x: 292; y: 642; spacing: 8
            Repeater {
                model: [
                    { t: "力行", on: root.n.p > 0 && root.n.b === 0, c: root.cPower },
                    { t: "回生", on: U.num(d.regen) > 0.01, c: root.cRegen },
                    { t: "ブレーキ", on: U.num(d.bc) > 20, c: root.cBrake },
                    { t: "非常", on: !!d.emergency, c: "#ff5a4f", blink: true },
                    { t: "CP", on: !!d.cp, c: root.cYellow },
                    { t: "速度超過", on: root.over, c: "#ff5a4f", blink: true },
                    { t: "定位置", on: !!d.stop && U.has(d.stop.dist) && Math.abs(d.stop.dist) <= 0.5 && Math.abs(root.speed) < 0.5, c: root.cPower },
                    { t: "戸閉", on: rx, c: "#d8e2ec" },
                ]
                Lamp { width: (1292 - 56) / 8; height: 56; text: modelData.t; on: modelData.on; litColor: modelData.c; blink: !!modelData.blink; fontSize: 18; radius: 6; offColor: "#0f1e2e"; offText: "#4a6078"; litText: "#04090f" }
            }
        }
    }

    // ================= 画面 2: 車両状態 =================
    Item {
        visible: root.pageNo === 1
        x: 16; y: 122; width: parent.width - 32; height: 698
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
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: (index + 1) + "号車"; color: "#c9d6e3"; font.pixelSize: 19; font.weight: Font.DemiBold }
                        Canvas {
                            y: 36; width: parent.width; height: 120
                            onPaint: {
                                var c = getContext("2d"); c.reset();
                                var w = width, h = height, nose = 26;
                                c.beginPath();
                                if (index === 0) { c.moveTo(nose, 0); c.lineTo(w, 0); c.lineTo(w, h - 18); c.lineTo(0, h - 18); c.lineTo(0, 30); c.closePath(); }
                                else if (index === root.carCount - 1) { c.moveTo(0, 0); c.lineTo(w - nose, 0); c.lineTo(w, 30); c.lineTo(w, h - 18); c.lineTo(0, h - 18); c.closePath(); }
                                else { c.rect(0, 0, w, h - 18); }
                                c.fillStyle = "#183450"; c.fill();
                                c.lineWidth = 1.5; c.strokeStyle = "#4f7aa3"; c.stroke();
                                // 窓と帯
                                c.fillStyle = "#0c1a29";
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
                        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 74; text: car.head ? "Tc" : car.motor ? (index % 3 === 1 ? "M" : "M'") : "T"; color: "white"; font.pixelSize: 24; font.weight: Font.DemiBold }
                        Column {
                            y: 176; width: parent.width; spacing: 8
                            Lamp { width: parent.width; height: 50; text: "力行"; on: car.motor && root.n.p > 0 && root.n.b === 0; litColor: root.cPower; fontSize: 17; radius: 6; offColor: "#0f1e2e"; offText: "#4a6078"; litText: "#04090f" }
                            Lamp { width: parent.width; height: 50; text: "回生"; on: car.motor && U.num(d.regen) > 0.01; litColor: root.cRegen; fontSize: 17; radius: 6; offColor: "#0f1e2e"; offText: "#4a6078"; litText: "#04090f" }
                            Lamp { width: parent.width; height: 50; text: "ブレーキ"; on: U.num(d.bc) > 20; litColor: root.cBrake; fontSize: 17; radius: 6; offColor: "#0f1e2e"; offText: "#4a6078"; litText: "#04090f" }
                            Lamp { width: parent.width; height: 50; text: "CP"; on: car.head && !!d.cp; litColor: root.cYellow; fontSize: 17; radius: 6; offColor: "#0f1e2e"; offText: "#4a6078"; litText: "#04090f" }
                            Lamp { width: parent.width; height: 50; text: "SIV"; on: car.head && rx; litColor: "#cfe3ff"; fontSize: 17; radius: 6; offColor: "#0f1e2e"; offText: "#4a6078"; litText: "#04090f" }
                            Rectangle {
                                width: parent.width; height: 62; radius: 6; color: "#0f1e2e"
                                Text { x: 10; y: 6; text: "BC kPa"; color: root.cLabel; font.pixelSize: 14 }
                                Text {
                                    anchors.right: parent.right; anchors.rightMargin: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                                    text: Math.round(U.num(d.bc) * (car.motor && U.num(d.regen) > 0.01 ? 1 - U.num(d.regen) : 1)); color: "white"; font.pixelSize: 26; font.weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }
            }
            Text {
                x: 30; anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                text: "運転モード " + U.str(d.mode) + "     MR " + Math.round(U.num(d.mr)) + " kPa     架線 " + (U.num(d.volt) / 1000).toFixed(2) + " kV     電流 " + Math.round(U.num(d.current)) + " A"
                color: "#9fb2c6"; font.pixelSize: 18
            }
        }
    }

    // ================= 画面 3: 運転記録 =================
    Item {
        visible: root.pageNo === 2
        x: 16; y: 122; width: parent.width - 32; height: 698
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
        x: 16; y: 122; width: parent.width - 32; height: 698
        Box {
            title: "前方の路線"
            x: 0; y: 0; width: 560; height: 700
            RouteStrip {
                anchors.fill: parent; anchors.margins: 10
                items: d.ahead || []; stopDist: d.stop ? U.num(d.stop.dist, NaN) : NaN
                stationColor: "#6cc8f5"; fontSize: 22
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
                        width: parent.width; height: 64; color: index % 2 ? "#0d1b29" : "transparent"; radius: 6
                        Rectangle { width: 6; height: parent.height - 16; anchors.verticalCenter: parent.verticalCenter; color: modelData.kind === "station" ? root.cLabel : root.cYellow }
                        Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: modelData.kind === "station" ? "駅" : "分岐"; color: modelData.kind === "station" ? root.cLabel : root.cYellow; font.pixelSize: 18; width: 90 }
                        Text { x: 110; anchors.verticalCenter: parent.verticalCenter; text: modelData.kind === "station" ? modelData.label : (modelData.label === "straight" ? "直進" : modelData.label); color: "white"; font.pixelSize: 26; font.weight: Font.DemiBold }
                        Text { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: U.dist(modelData.dist); color: "#c9d6e3"; font.pixelSize: 24 }
                    }
                }
            }
        }
    }

    // ================= 下の画面切替ボタン =================
    Rectangle { x: 0; y: 832; width: parent.width; height: 68; color: "#0a1522"
        Rectangle { width: parent.width; height: 1; color: root.cFrame } }
    Row {
        x: 16; y: 842; spacing: 8
        Repeater {
            model: root.pages.concat(["戸閉", "空調", "設定"])
            Rectangle {
                id: btn
                width: (1568 - 8 * 6) / 7; height: 48; radius: 8
                readonly property bool sel: index === root.pageNo
                readonly property bool live: index < root.pages.length
                color: sel ? "#e8c21c" : live ? "#1b2f45" : "#111d2a"
                border.color: sel ? "transparent" : live ? "#2f4b68" : "transparent"
                Text { anchors.centerIn: parent; text: modelData; color: btn.sel ? "#0a0f14" : btn.live ? "#e3ecf4" : "#4a5e72"; font.pixelSize: 19; font.weight: Font.DemiBold }
                MouseArea { anchors.fill: parent; enabled: btn.live; onClicked: root.pageNo = index }
            }
        }
    }
}

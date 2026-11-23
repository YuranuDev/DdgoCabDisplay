import QtQuick
import "../parts"
import "../parts/Util.js" as U

// 計器盤: DdgoMascon の別モニター表示 (CabDisplayWindow) と同じ並び。
// ヘアライン仕上げの金属パネルに、クロームの縁の計器・宝石形の表示灯・彫り込みの銘板・運転情報モニター
Rectangle {
    id: root
    color: "#2b2e32"
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

    // ---- ヘアライン仕上げ (1 回だけ描く) ----
    Canvas {
        anchors.fill: parent
        onPaint: {
            var c = getContext("2d");
            var g = c.createLinearGradient(0, 0, 0, height);
            g.addColorStop(0, "#3d4146"); g.addColorStop(0.5, "#2c2f33"); g.addColorStop(1, "#1e2023");
            c.fillStyle = g; c.fillRect(0, 0, width, height);
            // 細い横筋をランダムに
            var seed = 7;
            function rnd() { seed = (seed * 16807) % 2147483647; return seed / 2147483647; }
            for (var i = 0; i < 1400; i++) {
                var y = rnd() * height, x = rnd() * width, w = 80 + rnd() * 420;
                c.fillStyle = rnd() > 0.5 ? Qt.rgba(1, 1, 1, 0.018 + rnd() * 0.03) : Qt.rgba(0, 0, 0, 0.03 + rnd() * 0.04);
                c.fillRect(x, y, w, 1);
            }
        }
    }

    // 彫り込みの銘板 (黒い樹脂に白い文字、両端にねじ)
    component Plate: Rectangle {
        id: pl
        property string text: ""
        height: 34; radius: 3
        gradient: Gradient { GradientStop { position: 0; color: "#050506" } GradientStop { position: 1; color: "#1a1b1d" } }
        border.color: "#6b7076"; border.width: 1
        Rectangle { x: 1; y: 1; width: pl.width - 2; height: 1; color: Qt.rgba(0, 0, 0, 0.8) }
        Rectangle { x: 1; y: pl.height - 2; width: pl.width - 2; height: 1; color: Qt.rgba(1, 1, 1, 0.18) }
        Repeater {
            model: 2
            Rectangle {
                x: index ? pl.width - 13 : 5; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4
                gradient: Gradient { GradientStop { position: 0; color: "#d8d8d8" } GradientStop { position: 1; color: "#4a4a4a" } }
                Rectangle { anchors.centerIn: parent; width: 6; height: 1; rotation: 35 + index * 50; color: "#222" }
            }
        }
        Text { anchors.centerIn: parent; text: pl.text; color: "#eceff2"; font.pixelSize: 19; font.bold: true; style: Text.Sunken; styleColor: "#000" }
    }
    // 運転情報モニターの欄
    component Tile: Rectangle {
        id: tl
        property string label: ""
        property string value: "—"
        property string note: ""
        property color valueColor: "white"
        height: 72; radius: 3
        gradient: Gradient { GradientStop { position: 0; color: "#0b2233" } GradientStop { position: 1; color: "#06151f" } }
        border.color: "#1c4560"; border.width: 1
        Rectangle { x: 0; y: 0; width: 4; height: tl.height; color: "#2f7fb5" }
        Text { x: 14; y: 5; text: tl.label; color: root.cLabel; font.pixelSize: 17 }
        Text {
            x: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 3; width: tl.width - 24; elide: Text.ElideRight
            textFormat: Text.StyledText
            text: "<b>" + tl.value + "</b>" + (tl.note.length ? " <font color='#8aa0b4' size='3'>" + tl.note + "</font>" : "")
            color: tl.valueColor; font.pixelSize: 31
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
            bezel: "chrome"; screws: true; glass: true
            faceColor: "#16181b"; faceColor2: "#050506"
            tickColor: "#f2f2f2"; labelColor: "#f2f2f2"; needleColor: "#ff3a2a"; needle2Color: "#f2f2f2"; hubColor: "#2a2a2a"
            dim: !root.rx
        }
        Item { width: 1; height: Math.max(0, (mt.slot - mt.size) / 2 - 6) }
        Plate { width: Math.max(150, mt.size); anchors.horizontalCenter: parent.horizontalCenter; text: mt.plate }
    }

    // ================= 上の帯 =================
    Rectangle {
        width: parent.width; height: 88
        gradient: Gradient { GradientStop { position: 0; color: "#1c1e21" } GradientStop { position: 1; color: "#0c0d0e" } }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 5
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#0d6e3f" } GradientStop { position: 0.5; color: root.cAccent } GradientStop { position: 1; color: "#0d6e3f" } } }
        Column {
            x: 22; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -2; width: 400
            Text { width: parent.width; elide: Text.ElideRight; text: U.str(d.line, "路線 —"); color: "white"; font.pixelSize: 32; font.bold: true }
            Text { width: parent.width; elide: Text.ElideRight; text: U.str(d.train, "") + (d.cars ? "   " + d.cars + "両" : ""); color: "#b8c2cc"; font.pixelSize: 20 }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.horizontalCenterOffset: 10; y: 8; spacing: 16
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
                Lamp { shape: "round"; width: 62; height: 70; text: modelData.t; on: modelData.on; litColor: modelData.c; blink: !!modelData.b; fontSize: 14; offColor: "#2a2d31" }
            }
        }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -2
            width: 200; height: 56; radius: 4; color: "#020405"; border.color: "#4a4f55"
            Clock { anchors.centerIn: parent; color: "#7dffb0"; font.pixelSize: 36; font.bold: true; style: Text.Outline; styleColor: "#0c3a22" }
        }
    }

    // ================= ノッチ (2 ハンドル) =================
    Rectangle {
        x: 14; y: 100; width: 232; height: 788; radius: 8
        gradient: Gradient { GradientStop { position: 0; color: "#1d1f22" } GradientStop { position: 1; color: "#121315" } }
        border.color: "#55595f"
        Rectangle { x: 1; y: 1; width: parent.width - 2; height: 1; color: Qt.rgba(1, 1, 1, 0.12) }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 8; text: "主幹制御器"; color: root.cLabel; font.pixelSize: 20 }
        Rectangle {
            x: 16; y: 36; width: parent.width - 32; height: 70; radius: 4; color: "#050607"; border.color: "#3b3f44"
            Text {
                anchors.centerIn: parent
                text: U.notchName(root.n)
                color: root.n.b > root.n.maxB ? "#ff3b30" : root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : "white"
                font.pixelSize: 54; font.bold: true
            }
        }
        Text { x: 26; y: 116; text: "力行"; color: root.cPower; font.pixelSize: 20; font.bold: true }
        Text { x: 128; y: 116; text: "ブレーキ"; color: root.cBrake; font.pixelSize: 20; font.bold: true }
        NotchLadder {
            x: 16; y: 148; width: 92; height: 370
            part: "power"; n: root.n; gap: 6; fontSize: 22
            powerColor: root.cPower; neutralColor: "#e0e0e0"; offColor: "#26292d"; offText: "#5d636a"; frameColor: "#3a3e44"
        }
        NotchLadder {
            x: 124; y: 148; width: 92; height: 620
            part: "brake"; n: root.n; gap: 6; fontSize: 22
            brakeColor: root.cBrake; neutralColor: "#e0e0e0"; offColor: "#26292d"; offText: "#5d636a"; frameColor: "#3a3e44"
        }
        Rectangle {
            x: 16; y: 540; width: 92; height: 112; radius: 4; color: "#050607"; border.color: "#3b3f44"
            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 8; text: "レバーサ"; color: root.cLabel; font.pixelSize: 17 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 38; text: U.revName(root.n.rev); color: "white"; font.pixelSize: 48; font.bold: true }
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
            gauge.value: U.num(d.volt); gauge.labelScale: 1.25
        }
        Meter {
            size: 232; slot: 300; plate: "空気圧  赤 BC / 白 MR"
            gauge.minValue: 0; gauge.maxValue: Math.max(1000, Math.ceil((Math.max(U.num(d.mrMax, 880), U.num(d.bcEmergency, 500)) + 50) / 200) * 200)
            gauge.majorStep: 200; gauge.minorStep: 50; gauge.unit: "kPa"
            gauge.value: U.num(d.bc); gauge.value2: U.num(d.mr)
            gauge.zones: [{ from: U.num(d.mrMin, 780), to: U.num(d.mrMax, 880), color: "#e8c020" }]
            gauge.labelScale: 1.05
        }
        Meter {
            size: 300; slot: 300; plate: "速度計  km/h"
            gauge.minValue: 0; gauge.maxValue: U.num(d.speedMax, 120)
            gauge.majorStep: gauge.maxValue > 160 ? 40 : 20; gauge.minorStep: gauge.maxValue > 160 ? 10 : 5
            gauge.value: root.speed; gauge.limit: U.has(d.limit) ? d.limit : NaN
            gauge.digital: rx && U.has(d.speed) ? Math.round(root.speed).toString() : "--"
            gauge.digitalColor: root.over ? "#ff5040" : "#7dffb0"
            gauge.zones: U.has(d.limit) ? [{ from: d.limit, to: gauge.maxValue, color: "#e8c020" }] : []
        }
        Meter {
            size: 232; slot: 300; plate: "電流計  A"
            gauge.minValue: -U.num(d.currentMax, 600); gauge.maxValue: U.num(d.currentMax, 600)
            gauge.majorStep: gauge.maxValue > 400 ? 200 : 100; gauge.minorStep: gauge.majorStep / 4
            gauge.value: U.num(d.current)
            gauge.zones: [{ from: gauge.minValue, to: 0, color: "#3a8fff" }, { from: 0, to: gauge.maxValue, color: "#30c060" }]
            gauge.labelScale: 1.05
        }
        Meter {
            size: 150; slot: 300; plate: "加速度"
            gauge.minValue: -5; gauge.maxValue: 5; gauge.majorStep: 5; gauge.minorStep: 1; gauge.unit: "km/h/s"
            gauge.value: U.num(d.accel)
            gauge.zones: [{ from: -5, to: 0, color: "#ff9a2e" }, { from: 0, to: 5, color: "#30c060" }]
            gauge.labelScale: 1.3
        }
    }

    // ================= 運転情報モニター =================
    Rectangle {
        x: 258; y: 454; width: 1096; height: 434; radius: 10
        gradient: Gradient { GradientStop { position: 0; color: "#3a3e43" } GradientStop { position: 0.08; color: "#16181a" } GradientStop { position: 1; color: "#0c0d0e" } }
        border.color: "#61666c"; border.width: 1
        Repeater {
            model: 4
            Rectangle {
                x: index % 2 ? parent.width - 14 : 6; y: index < 2 ? 6 : parent.height - 14; width: 8; height: 8; radius: 4
                gradient: Gradient { GradientStop { position: 0; color: "#cfcfcf" } GradientStop { position: 1; color: "#3d3d3d" } }
            }
        }
        Rectangle {
            id: screen
            anchors.fill: parent; anchors.margins: 16; radius: 4; color: root.cScreen
            border.color: "#000"; border.width: 2
            // 停止位置
            Item {
                x: 16; y: 12; width: 380; height: 380
                Text { text: "停止位置まで"; color: root.cLabel; font.pixelSize: 21 }
                Text { y: 28; text: U.str(d.stop ? d.stop.station : null) + (d.stop && d.stop.marker ? "  " + d.stop.marker : ""); color: "white"; font.pixelSize: 26; font.bold: true }
                Text {
                    id: sd
                    readonly property real v: d.stop ? U.num(d.stop.dist, NaN) : NaN
                    anchors.right: sdu.left; anchors.rightMargin: 6; y: 62
                    text: U.distNum(v)
                    color: isNaN(v) ? "#55606c" : Math.abs(v) <= 0.5 ? root.cPower : v < 0 ? "#ff3b30" : v < 10 ? "#ffd23f" : "white"
                    font.pixelSize: 108; font.bold: true
                }
                Text { id: sdu; anchors.right: parent.right; anchors.baseline: sd.baseline; text: U.distUnit(sd.v); color: root.cLabel; font.pixelSize: 28 }
                StopTape { y: 222; width: parent.width; height: 68; dist: sd.v; range: 10; fontSize: 15 }
                Text { y: 316; text: "次駅"; color: root.cLabel; font.pixelSize: 19 }
                Text { y: 340; text: U.str(d.at ? d.at + " 構内" : d.next) + (d.at ? "" : "  " + U.dist(d.nextDist)); color: "white"; font.pixelSize: 29; font.bold: true }
            }
            Rectangle { x: 410; y: 12; width: 1; height: parent.height - 24; color: "#1c4560" }
            Grid {
                x: 424; y: 12; columns: 2; spacing: 7
                Tile { width: 316; label: "現在地"; value: d.at ? d.at + " 構内" : (d.prev && d.next ? d.prev + " → " + d.next : "—") }
                Tile { width: 316; label: "ノッチ"; value: U.notchName(root.n); valueColor: root.n.b > 0 ? root.cBrake : root.n.p > 0 ? root.cPower : "white"; note: root.n.pending ? "送信待ち " + root.n.pending : "" }
                Tile { width: 316; label: "制限"; value: U.has(d.limit) ? Math.round(d.limit) : "—"; note: U.has(d.limit) ? "km/h" : ""; valueColor: root.over ? "#ff5040" : "#ffd23f" }
                Tile { width: 316; label: "BC / MR"; value: Math.round(U.num(d.bc)) + " / " + Math.round(U.num(d.mr)); note: "kPa" }
                Tile { width: 316; label: "分岐"; value: d.switch ? d.switch.way : "—"; note: d.switch ? Math.round(d.switch.dist) + " m" : ""; valueColor: d.switch && d.switch.conflict ? "#ff5040" : "white" }
                Tile { width: 316; label: "電流"; value: Math.round(U.num(d.current)); note: "A"; valueColor: U.num(d.current) < -1 ? "#7fc4ff" : "white" }
                Tile { width: 316; label: "回生"; value: U.num(d.regen) > 0.01 ? Math.round(U.num(d.regen) * 100) : "—"; note: U.num(d.regen) > 0.01 ? "%" : "" }
                Tile { width: 316; label: "状態"; value: !d.connected ? "未接続" : !d.output ? "出力OFF" : !rx ? "受信なし" : d.cp ? "CP運転" : "正常"; valueColor: !d.connected || !d.output || !rx ? "#ffd23f" : root.cPower }
                Tile { width: 316; label: "編成"; value: U.str(d.train); note: (d.cars ? d.cars + "両 " : "") + (d.cab === "secondary" ? "B" : d.cab === "main" ? "A" : "") }
                Tile { width: 316; label: "運転モード"; value: U.str(d.mode) }
            }
            // 画面のガラスの映り込み
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var c = getContext("2d");
                    var g = c.createLinearGradient(0, 0, width * 0.6, height);
                    g.addColorStop(0, Qt.rgba(1, 1, 1, 0.07)); g.addColorStop(0.35, Qt.rgba(1, 1, 1, 0.02)); g.addColorStop(0.36, Qt.rgba(1, 1, 1, 0));
                    c.fillStyle = g; c.fillRect(0, 0, width, height);
                }
            }
        }
    }

    // ================= 路線 =================
    Rectangle {
        x: 1366; y: 100; width: 220; height: 788; radius: 8
        gradient: Gradient { GradientStop { position: 0; color: "#3a3e43" } GradientStop { position: 0.04; color: "#16181a" } GradientStop { position: 1; color: "#0c0d0e" } }
        border.color: "#61666c"
        Rectangle {
            anchors.fill: parent; anchors.margins: 10; radius: 4; color: root.cScreen; border.color: "#000"; border.width: 2
            Text { x: 12; y: 8; text: "前方"; color: root.cLabel; font.pixelSize: 20 }
            RouteStrip {
                x: 2; y: 36; width: parent.width - 4; height: parent.height - 44
                items: d.ahead || []; stopDist: d.stop ? U.num(d.stop.dist, NaN) : NaN; fontSize: 21
            }
        }
    }
}

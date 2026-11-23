import QtQuick

// 表示灯。点灯すると色付きのレンズが光り、周りにうっすら光が漏れる。
// shape = "rect"(パネルの表示灯) / "round"(計器盤の丸い宝石形の表示灯。文字は下に出す)
Item {
    id: l
    property string text: ""
    property bool on: false
    property color litColor: "#ffb000"
    property color offColor: "#262a30"
    property color litText: "#111111"
    property color offText: "#5f6670"
    property bool blink: false
    property real fontSize: 20
    property real radius: 4
    property string shape: "rect"
    property color labelColor: "#d8dde3"
    property bool phase: true
    property bool halo: false            // 点灯時に周りへ光を漏らす (既定はしない)
    property alias border: lens.border
    readonly property bool lit: on && (!blink || phase)

    // 光の漏れ
    Rectangle {
        anchors.centerIn: lens
        width: lens.width + 16; height: lens.height + 16
        radius: l.shape === "round" ? width / 2 : l.radius + 8
        color: l.litColor; opacity: l.lit && l.halo ? 0.22 : 0
        Behavior on opacity { NumberAnimation { duration: 90 } }
    }
    Rectangle {
        anchors.centerIn: lens
        width: lens.width + 7; height: lens.height + 7
        radius: l.shape === "round" ? width / 2 : l.radius + 3
        color: l.litColor; opacity: l.lit && l.halo ? 0.35 : 0
    }
    // 枠 (金属の縁)
    Rectangle {
        visible: l.shape === "round"
        anchors.centerIn: lens
        width: lens.width + 8; height: width; radius: width / 2
        gradient: Gradient { GradientStop { position: 0; color: "#cfd2d6" } GradientStop { position: 1; color: "#3c3f43" } }
    }
    Rectangle {
        id: lens
        width: l.shape === "round" ? Math.min(l.width, l.height - l.fontSize - 8) : l.width
        height: l.shape === "round" ? width : l.height
        anchors.horizontalCenter: parent.horizontalCenter
        radius: l.shape === "round" ? width / 2 : l.radius
        border.width: 1
        border.color: l.lit ? Qt.lighter(l.litColor, 1.4) : Qt.rgba(1, 1, 1, 0.10)
        gradient: Gradient {
            GradientStop { position: 0.0; color: l.lit ? Qt.lighter(l.litColor, 1.35) : Qt.lighter(l.offColor, 1.25) }
            GradientStop { position: 0.55; color: l.lit ? l.litColor : l.offColor }
            GradientStop { position: 1.0; color: l.lit ? Qt.darker(l.litColor, 1.25) : Qt.darker(l.offColor, 1.3) }
        }
        // つやの反射
        Rectangle {
            x: parent.width * 0.08; y: parent.height * 0.06
            width: parent.width * 0.84; height: parent.height * 0.42
            radius: l.shape === "round" ? height / 2 : Math.max(0, l.radius - 1)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, l.lit ? 0.45 : 0.12) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
        Text {
            visible: l.shape !== "round"
            anchors.centerIn: parent
            text: l.text
            color: l.lit ? l.litText : l.offText
            font.pixelSize: l.fontSize; font.bold: true
        }
    }
    Text {
        visible: l.shape === "round"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: lens.bottom; anchors.topMargin: 5
        text: l.text; color: l.labelColor
        font.pixelSize: l.fontSize; font.bold: true
    }
    Timer { running: l.blink && l.on; repeat: true; interval: 450; onTriggered: l.phase = !l.phase; onRunningChanged: l.phase = true }
}

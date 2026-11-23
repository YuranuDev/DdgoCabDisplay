import QtQuick

// 状態の札: 点と文字。点灯中は色の付いた面になる (光らせない)
Rectangle {
    id: ch
    property string text: ""
    property bool on: false
    property color lit: Pal.blue
    property bool blink: false
    property bool phase: true
    readonly property bool shown: on && (!blink || phase)
    radius: 12
    color: shown ? Qt.rgba(lit.r, lit.g, lit.b, Pal.dark ? 0.18 : 0.12) : Pal.raised
    border.color: shown ? Qt.rgba(lit.r, lit.g, lit.b, 0.7) : "transparent"; border.width: 1.5
    Rectangle { x: 18; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: ch.shown ? ch.lit : Pal.mute }
    Text {
        x: 42; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 52; elide: Text.ElideRight
        text: ch.text; color: ch.shown ? Pal.text : Pal.mute
        font.pixelSize: 19 * Pal.ts; font.weight: ch.shown ? Font.DemiBold : Font.Normal
    }
    Timer { running: ch.blink && ch.on; repeat: true; interval: 500; onTriggered: ch.phase = !ch.phase; onRunningChanged: ch.phase = true }
}

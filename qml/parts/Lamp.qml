import QtQuick

// 表示灯。消灯時は暗い色、点灯で色が付き光る
Rectangle {
    id: l
    property string text: ""
    property bool on: false
    property color litColor: "#ffb000"
    property color offColor: "#262a30"
    property color litText: "#111111"
    property color offText: "#5f6670"
    property bool blink: false
    property real fontSize: 20
    property bool phase: true
    radius: 4
    color: on && (!blink || phase) ? litColor : offColor
    border.color: on ? Qt.lighter(litColor, 1.3) : Qt.rgba(1, 1, 1, 0.08)
    border.width: 1
    Text {
        anchors.centerIn: parent
        text: l.text
        color: l.on && (!l.blink || l.phase) ? l.litText : l.offText
        font.pixelSize: l.fontSize; font.bold: true
    }
    Timer { running: l.blink && l.on; repeat: true; interval: 450; onTriggered: l.phase = !l.phase; onRunningChanged: l.phase = true }
}

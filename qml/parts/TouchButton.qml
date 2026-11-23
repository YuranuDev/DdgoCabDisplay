import QtQuick

// 指で押しやすい大きなボタン。押している間は少し沈む
Rectangle {
    id: b
    property string text: ""
    property string sub: ""
    property bool checked: false
    property bool danger: false
    property color accent: danger ? Pal.red : Pal.blue
    signal clicked()
    implicitHeight: 76; implicitWidth: 220
    radius: 14
    color: checked ? accent : ma.pressed ? Qt.darker(Pal.raised, Pal.dark ? 0.85 : 1.06) : Pal.raised
    border.color: checked ? accent : danger ? Qt.rgba(accent.r, accent.g, accent.b, 0.6) : Pal.line; border.width: 1.5
    scale: ma.pressed ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: 80 } }
    Column {
        anchors.centerIn: parent; spacing: 2
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: b.text; color: b.checked ? Pal.onAccent : b.danger ? b.accent : Pal.text; font.pixelSize: 22 * Pal.ts; font.weight: Font.DemiBold }
        Text { visible: b.sub.length > 0; anchors.horizontalCenter: parent.horizontalCenter; text: b.sub; color: b.checked ? Pal.onAccent : Pal.sub; font.pixelSize: 15 * Pal.ts }
    }
    MouseArea { id: ma; anchors.fill: parent; onClicked: b.clicked() }
}

import QtQuick

// 角丸のカード。左上に見出し、右上に補足
Rectangle {
    id: cd
    property string title: ""
    property string note: ""
    property color noteColor: Pal.sub
    default property alias content: body.data
    color: Pal.card; radius: 16
    border.color: Pal.dark ? "transparent" : Pal.line; border.width: 1
    Text { visible: cd.title.length > 0; x: 22; y: 16; text: cd.title; color: Pal.sub; font.pixelSize: 18 * Pal.ts; font.weight: Font.Medium }
    Text { visible: cd.note.length > 0; anchors.right: parent.right; anchors.rightMargin: 22; y: 16; text: cd.note; color: cd.noteColor; font.pixelSize: 18 * Pal.ts }
    Item { id: body; anchors.fill: parent }
}

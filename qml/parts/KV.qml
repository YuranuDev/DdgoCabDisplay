import QtQuick

// 1 行の項目: 左に名前、右に値と単位
Item {
    id: kv
    property string label: ""
    property string value: "—"
    property string unit: ""
    property color valueColor: Pal.text
    property bool last: false
    height: 58
    Rectangle { visible: !kv.last; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Pal.line }
    Text { anchors.verticalCenter: parent.verticalCenter; text: kv.label; color: Pal.sub; font.pixelSize: 19 * Pal.ts }
    Text {
        id: kvv
        anchors.right: kvu.left; anchors.rightMargin: kvu.text.length ? 6 : 0; anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, kv.width * 0.66); elide: Text.ElideLeft; horizontalAlignment: Text.AlignRight
        text: kv.value; color: kv.valueColor; font.pixelSize: 25 * Pal.ts; font.weight: Font.DemiBold
    }
    Text { id: kvu; anchors.right: parent.right; anchors.baseline: kvv.baseline; text: kv.unit; color: Pal.sub; font.pixelSize: 16 * Pal.ts }
}

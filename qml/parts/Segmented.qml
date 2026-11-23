import QtQuick

// 選択肢を横に並べた切り替え。選んでいるものが色付きになる
Row {
    id: sg
    property var options: []          // [{key, label, sub}]
    property string current: ""
    property real itemWidth: 220
    property real itemHeight: 76
    signal picked(string key)
    spacing: 12
    Repeater {
        model: sg.options
        TouchButton {
            width: sg.itemWidth; height: sg.itemHeight
            text: modelData.label; sub: modelData.sub || ""
            checked: modelData.key === sg.current
            onClicked: sg.picked(modelData.key)
        }
    }
}

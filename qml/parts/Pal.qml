pragma Singleton
import QtQuick

// 配色と文字の大きさ。設定画面で切り替えると、すべての画面にすぐ反映される
QtObject {
    property string scheme: "dark"      // dark / light
    property string textSize: "normal"  // normal / large
    readonly property bool dark: scheme !== "light"
    readonly property real ts: textSize === "large" ? 1.18 : 1.0

    readonly property color bg:       dark ? "#0e1116" : "#eceff3"
    readonly property color card:     dark ? "#171b21" : "#ffffff"
    readonly property color line:     dark ? "#252c35" : "#dde2e9"
    readonly property color raised:   dark ? "#1f252d" : "#f1f3f6"
    readonly property color text:     dark ? "#eef1f5" : "#151e29"
    readonly property color sub:      dark ? "#a0a9b5" : "#556170"
    readonly property color mute:     dark ? "#5f6873" : "#a4aebb"
    readonly property color track:    dark ? "#272e37" : "#e3e7ed"
    readonly property color tick:     dark ? "#55606c" : "#b0b9c4"
    readonly property color blue:     dark ? "#5aa8ff" : "#1f6fd6"
    readonly property color green:    dark ? "#43d17f" : "#12904a"
    readonly property color orange:   dark ? "#ffa04a" : "#d5600a"
    readonly property color red:      dark ? "#ff5a4f" : "#d22f2a"
    readonly property color yellow:   dark ? "#ffc940" : "#a87c00"
    readonly property color purple:   dark ? "#a592ff" : "#6046d0"
    readonly property color needle:   dark ? "#f2f4f7" : "#151e29"
    readonly property color onAccent: dark ? "#0e1116" : "#ffffff"   // 色の付いた面の上の文字
}

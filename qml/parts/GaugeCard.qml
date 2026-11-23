import QtQuick

// 小さな計器のカード: 見出し・アナログ計・数字
Card {
    id: gcard
    property alias gauge: mg
    ModernGauge {
        id: mg
        anchors.horizontalCenter: parent.horizontalCenter
        y: 44 * Pal.ts
        width: Math.min(gcard.width - 28, gcard.height - y - 8); height: width
        track: Pal.track; tickColor: Pal.tick; labelColor: Pal.sub; needleColor: Pal.needle; hubInner: Pal.card; valueColor: Pal.text
        valueSize: 0.27; thickness: 0.085
    }
}

import QtQuick
import "Util.js" as U

Text {
    property bool seconds: true
    function upd() { var n = new Date(); text = U.pad2(n.getHours()) + ":" + U.pad2(n.getMinutes()) + (seconds ? ":" + U.pad2(n.getSeconds()) : ""); }
    Timer { interval: 250; running: true; repeat: true; triggeredOnStart: true; onTriggered: parent.upd() }
}

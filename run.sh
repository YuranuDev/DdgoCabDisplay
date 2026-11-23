#!/bin/sh
# 起動: ./run.sh            全画面で受信待ち
#       ./run.sh --demo     受信なしでデモ走行
#       ./run.sh -w -t glass  ウィンドウで、グラスコックピット風
cd "$(dirname "$0")"
# Raspberry Pi のコンソール (デスクトップなし) から直接出すときは eglfs を使う
if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ] && [ -z "$QT_QPA_PLATFORM" ]; then
    export QT_QPA_PLATFORM=eglfs
fi
exec ./build/ddgo-cabdisplay "$@"

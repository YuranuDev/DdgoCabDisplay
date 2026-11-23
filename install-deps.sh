#!/bin/sh
# Raspberry Pi OS (bookworm) / Debian 12 / Ubuntu 24.04 で必要なパッケージを入れる
set -e
sudo apt-get update
sudo apt-get install -y cmake g++ \
    qt6-base-dev qt6-declarative-dev \
    qml6-module-qtquick qml6-module-qtquick-window qml6-module-qtqml-workerscript \
    libgl1-mesa-dev

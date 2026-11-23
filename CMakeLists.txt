cmake_minimum_required(VERSION 3.16)
project(DdgoCabDisplay VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Qt 6.4 以降 (Raspberry Pi OS bookworm / Ubuntu 24.04 の標準パッケージで OK)
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Network Qml Quick)

# IBM Plex Sans JP (SIL OFL 1.1) を実行ファイルに埋め込む。大きいので big resources で
qt_add_big_resources(FONT_RES fonts.qrc)

add_executable(ddgo-cabdisplay
    ${FONT_RES}
    src/main.cpp
    src/cablink.h src/cablink.cpp
    src/demosource.h src/demosource.cpp
    qml.qrc
)
target_link_libraries(ddgo-cabdisplay PRIVATE Qt6::Core Qt6::Gui Qt6::Network Qt6::Qml Qt6::Quick)

install(TARGETS ddgo-cabdisplay RUNTIME DESTINATION bin)

cmake_minimum_required(VERSION 3.16)
project(drivecard VERSION 0.96)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

# Qt::Qml и Qt::Quick не нужны — плагин не регистрирует QML-типы напрямую
find_package(Qt6 REQUIRED COMPONENTS Core)

# Plasma живёт в своём cmake-пространстве (libplasma → /usr/lib/cmake/Plasma/)
# а не в KF6-umbrella, поэтому ищем напрямую
find_package(Plasma REQUIRED)
find_package(KF6 REQUIRED COMPONENTS CoreAddons Solid)

kcoreaddons_add_plugin(io.github.cachyos.drivecard
    SOURCES src/drivecard_applet.cpp src/drivecard_applet.h
    INSTALL_NAMESPACE "plasma/applets"
)

target_link_libraries(io.github.cachyos.drivecard
    Qt::Core
    Plasma::Plasma
    KF6::CoreAddons
    KF6::Solid
)

# Абсолютный путь к metadata.json — относительный ломается при сборке в build/
target_compile_definitions(io.github.cachyos.drivecard PRIVATE
    PLUGIN_METADATA_FILE="${CMAKE_SOURCE_DIR}/package/metadata.json"
)

plasma_install_package(package io.github.cachyos.drivecard)

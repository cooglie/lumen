# CMakeLists.txt — Lumen für Windows (DirectX 11, MSVC)
cmake_minimum_required(VERSION 3.20)
project(Lumen LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Unicode-WinMain (wWinMain) statt Standard-main.
set(CMAKE_WIN32_EXECUTABLE TRUE)

add_executable(Lumen WIN32
    src/main.cpp
    src/aurora.cpp
    src/mosaic.cpp
    resource.rc
)

target_include_directories(Lumen PRIVATE src)

# DirectX 11 + Compiler libs liegen im Windows SDK; nur linken.
target_link_libraries(Lumen PRIVATE
    d3d11
    d3dcompiler
    dxgi
    shell32
    user32
    gdi32
)

# Shader-Dateien + Icon ins Build-Verzeichnis neben die .exe kopieren,
# damit D3DCompileFromFile und LoadIcon sie zur Laufzeit finden.
add_custom_command(TARGET Lumen POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_CURRENT_SOURCE_DIR}/shaders
            $<TARGET_FILE_DIR:Lumen>/shaders
    COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_CURRENT_SOURCE_DIR}/lumen.ico
            $<TARGET_FILE_DIR:Lumen>/lumen.ico
)

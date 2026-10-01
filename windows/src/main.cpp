// main.cpp — Lumen für Windows (Win32 + DirectX 11)
// Tray-Icon + Kontextmenü, Aurora-Render-Loop via Timer, Mosaic-Choreografien.
#include <windows.h>
#include <shellapi.h>
#include <string>
#include "aurora.h"
#include "mosaic.h"

#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "user32.lib")

#define IDM_QUIT        9000
#define IDM_TOGGLE      9001
#define IDM_SHADER_BASE 9100   // 9100+i
#define IDM_MOSAIC_BASE 9200   // 9200+i

#define WM_TRAYICON (WM_APP + 1)
#define ID_TIMER_RENDER 1

static const wchar_t* kTrayClass = L"LumenTray";
static UINT WM_TASKBARCREATED = 0;

static AuroraRenderer gAurora;
static Mosaic gMosaic;
static HWND gMsgHwnd = nullptr;
static HMENU gMenu = nullptr;
static UINT_PTR gRenderTimer = 0;

static void RebuildMenu() {
    if (gMenu) DestroyMenu(gMenu);
    gMenu = CreatePopupMenu();

    AppendMenuW(gMenu, MF_STRING, IDM_TOGGLE,
                gAurora.IsRunning() ? L"Pause Aurora" : L"Start Aurora");
    AppendMenuW(gMenu, MF_SEPARATOR, 0, nullptr);

    AppendMenuW(gMenu, MF_DISABLED | MF_STRING, 0, L"-- Shader --");
    const auto& shaders = gAurora.Shaders();
    for (size_t i = 0; i < shaders.size(); ++i) {
        UINT flags = MF_STRING;
        if ((int)i == gAurora.ActiveShaderIndex()) flags |= MF_CHECKED;
        AppendMenuW(gMenu, flags, IDM_SHADER_BASE + (UINT)i, shaders[i].name.c_str());
    }

    AppendMenuW(gMenu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(gMenu, MF_DISABLED | MF_STRING, 0, L"-- Mosaic --");
    const wchar_t* layouts[] = { L"Grid", L"Spiral", L"Fan", L"Cascade", L"Orbit" };
    for (int i = 0; i < 5; ++i) {
        AppendMenuW(gMenu, MF_STRING, IDM_MOSAIC_BASE + i, layouts[i]);
    }

    AppendMenuW(gMenu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(gMenu, MF_STRING, IDM_QUIT, L"Quit Lumen");
}

static void ShowTrayMenu() {
    RebuildMenu();
    POINT pt;
    GetCursorPos(&pt);
    SetForegroundWindow(gMsgHwnd);
    TrackPopupMenu(gMenu, TPM_RIGHTALIGN | TPM_BOTTOMALIGN | TPM_RETURNCMD,
                   pt.x, pt.y, 0, gMsgHwnd, nullptr);
}

static void HandleCommand(WPARAM w) {
    if (w == IDM_QUIT) {
        if (gRenderTimer) KillTimer(gMsgHwnd, ID_TIMER_RENDER);
        gAurora.Shutdown();
        NOTIFYICONDATAW nid = {};
        nid.cbSize = sizeof(nid);
        nid.hWnd = gMsgHwnd;
        nid.uID = 1;
        Shell_NotifyIconW(NIM_DELETE, &nid);
        PostQuitMessage(0);
        return;
    }
    if (w == IDM_TOGGLE) {
        gAurora.Toggle();
        return;
    }
    if (w >= IDM_SHADER_BASE && w < IDM_SHADER_BASE + 100) {
        int idx = (int)(w - IDM_SHADER_BASE);
        const auto& shaders = gAurora.Shaders();
        if (idx >= 0 && idx < (int)shaders.size()) {
            gAurora.SelectShader(shaders[idx].file);
        }
        return;
    }
    if (w >= IDM_MOSAIC_BASE && w < IDM_MOSAIC_BASE + 10) {
        int idx = (int)(w - IDM_MOSAIC_BASE);
        Layout lays[] = { Layout::Grid, Layout::Spiral, Layout::Fan, Layout::Cascade, Layout::Orbit };
        if (idx >= 0 && idx < 5) gMosaic.Perform(lays[idx]);
        return;
    }
}

static LRESULT CALLBACK WndProc(HWND h, UINT msg, WPARAM w, LPARAM l) {
    if (msg == WM_TASKBARCREATED) {
        // Explorer-Neustart: Tray-Icon neu anmelden.
        NOTIFYICONDATAW nid = {};
        nid.cbSize = sizeof(nid);
        nid.hWnd = h; nid.uID = 1;
        nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
        nid.uCallbackMessage = WM_TRAYICON;
        nid.hIcon = LoadIconW(GetModuleHandle(nullptr), MAKEINTRESOURCEW(101));
        wcscpy_s(nid.szTip, L"Lumen");
        Shell_NotifyIconW(NIM_ADD, &nid);
        return 0;
    }
    if (msg == WM_TRAYICON) {
        if (l == WM_RBUTTONUP || l == WM_LBUTTONUP) {
            ShowTrayMenu();
        }
        return 0;
    }
    if (msg == WM_COMMAND) {
        HandleCommand(w);
        return 0;
    }
    if (msg == WM_TIMER && w == ID_TIMER_RENDER) {
        gAurora.RenderFrame();
        if (gMosaic.IsAnimating()) gMosaic.Tick();
        return 0;
    }
    return DefWindowProc(h, msg, w, l);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, LPWSTR, int) {
    WM_TASKBARCREATED = RegisterWindowMessageW(L"TaskbarCreated");

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.lpszClassName = kTrayClass;
    RegisterClassExW(&wc);

    // Verstecktes Nachrichten-Fenster für Tray + Timer.
    gMsgHwnd = CreateWindowExW(0, kTrayClass, L"Lumen", 0, 0, 0, 0, 0,
                               HWND_MESSAGE, nullptr, hInst, nullptr);

    // Tray-Icon.
    NOTIFYICONDATAW nid = {};
    nid.cbSize = sizeof(nid);
    nid.hWnd = gMsgHwnd; nid.uID = 1;
    nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    nid.uCallbackMessage = WM_TRAYICON;
    nid.hIcon = LoadIconW(hInst, MAKEINTRESOURCEW(101));
    wcscpy_s(nid.szTip, L"Lumen");
    Shell_NotifyIconW(NIM_ADD, &nid);

    // Aurora initialisieren + starten.
    if (!gAurora.Init()) {
        MessageBoxW(nullptr, L"Aurora (DirectX 11) konnte nicht initialisiert werden.",
                    L"Lumen", MB_ICONERROR);
    } else {
        gAurora.Start();
    }

    // Render- + Animations-Timer (~60 FPS, native Win32-Timer-Auflösung).
    gRenderTimer = SetTimer(gMsgHwnd, ID_TIMER_RENDER, 16, nullptr);

    MSG m;
    while (GetMessage(&m, nullptr, 0, 0)) {
        TranslateMessage(&m);
        DispatchMessage(&m);
    }

    if (gRenderTimer) KillTimer(gMsgHwnd, ID_TIMER_RENDER);
    gAurora.Shutdown();
    return 0;
}

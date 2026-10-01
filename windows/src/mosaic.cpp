// mosaic.cpp — Mosaic Fenster-Choreografie (Win32) Implementation
#define NOMINMAX
#include "mosaic.h"
#include <cmath>
#include <cstdio>

#ifndef _USE_MATH_DEFINES
#define _USE_MATH_DEFINES
#endif
#include <math.h>

static Mosaic* gMosaic = nullptr;

static double Smoothstep(double t) { return t * t * (3.0 - 2.0 * t); }
static double Lerp(double a, double b, double t) { return a + (b - a) * t; }

static RECT ScreenWorkArea() {
    RECT r;
    SystemParametersInfoW(SPI_GETWORKAREA, 0, &r, 0);
    return r;
}

Mosaic::Mosaic() { gMosaic = this; }
Mosaic::~Mosaic() { if (timerId_) KillTimer(nullptr, timerId_); }

// Sammle sichtbare, verschiebbare Top-Level-Fenster (keine Toolwindows).
BOOL CALLBACK Mosaic::EnumProc(HWND hwnd, LPARAM lParam) {
    if (!IsWindowVisible(hwnd)) return TRUE;
    if (IsIconic(hwnd)) return TRUE;
    LONG_PTR ex = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    if (ex & WS_EX_TOOLWINDOW) return TRUE;
    // Ohne Titel/Caption überspringen.
    wchar_t title[64] = {};
    if (GetWindowTextW(hwnd, title, 64) == 0) return TRUE;
    RECT r;
    if (!GetWindowRect(hwnd, &r)) return TRUE;
    if ((r.right - r.left) < 50 || (r.bottom - r.top) < 50) return TRUE;

    auto* self = reinterpret_cast<Mosaic*>(lParam);
    // Eigenes Tray-Fenster ausschließen (LumenAuroraOverlay etc.).
    wchar_t cls[64] = {};
    GetClassNameW(hwnd, cls, 64);
    if (wcscmp(cls, L"LumenAuroraOverlay") == 0) return TRUE;

    TargetWin tw;
    tw.hwnd = hwnd;
    tw.start = r;
    tw.target = r;
    self->wins_.push_back(tw);
    return TRUE;
}

void Mosaic::ComputeTargets(Layout layout) {
    RECT scr = ScreenWorkArea();
    double sw = scr.right - scr.left;
    double sh = scr.bottom - scr.top;
    int count = (int)wins_.size();
    if (count == 0) count = 1;

    for (int i = 0; i < (int)wins_.size(); ++i) {
        double x, y, w, h;
        switch (layout) {
        case Layout::Grid: {
            int cols = (int)ceil(sqrt((double)count));
            int rows = (int)ceil((double)count / cols);
            double cw = sw / cols, ch = sh / rows;
            int col = i % cols, row = i / cols;
            x = scr.left + col * cw; y = scr.top + row * ch; w = cw; h = ch;
            break;
        }
        case Layout::Spiral: {
            double cx = scr.left + sw / 2.0, cy = scr.top + sh / 2.0;
            double base = std::min(sw, sh) * 0.15;
            double angle = i * 2.4;
            double radius = base * pow(1.618, i * 0.25);
            double size = base * 0.8;
            x = cx + cos(angle) * radius - size / 2;
            y = cy + sin(angle) * radius - size / 2;
            w = h = size;
            break;
        }
        case Layout::Fan: {
            double cx = scr.left + sw / 2.0;
            double baseY = scr.top + 40;
            double radius = sh * 0.45;
            double spread = M_PI / 2.2;
            double size = std::min(sw, sh) * 0.25;
            double t = (count == 1) ? 0.5 : (double)i / (count - 1);
            double angle = (M_PI / 2) - spread * t + spread / 2;
            x = cx + cos(angle) * radius - size / 2;
            y = baseY + sin(angle) * radius - size / 2;
            w = h = size;
            break;
        }
        case Layout::Cascade: {
            double off = i * 30.0;
            w = sw * 0.55; h = sh * 0.75;
            x = scr.left + off; y = scr.top + off;
            break;
        }
        case Layout::Orbit: {
            double cx = scr.left + sw / 2.0, cy = scr.top + sh / 2.0;
            double radius = std::min(sw, sh) * 0.3;
            double size = std::min(sw, sh) * 0.18;
            double angle = ((double)i / count) * 2.0 * M_PI;
            x = cx + cos(angle) * radius - size / 2;
            y = cy + sin(angle) * radius - size / 2;
            w = h = size;
            break;
        }
        }
        wins_[i].target = {
            (LONG)lround(x), (LONG)lround(y),
            (LONG)lround(x + w), (LONG)lround(y + h)
        };
    }
}

void Mosaic::Perform(Layout layout) {
    if (timerId_) { KillTimer(nullptr, timerId_); timerId_ = 0; }
    wins_.clear();
    layout_ = layout;
    EnumWindows(EnumProc, reinterpret_cast<LPARAM>(this));
    if (wins_.empty()) return;
    ComputeTargets(layout);
    steps_ = 0;
    // Timer ca. 16ms für ~30 Steps => ~0.5s Animation.
    timerId_ = SetTimer(nullptr, 0, 16, [](HWND, UINT, UINT_PTR id, DWORD) {
        if (gMosaic) gMosaic->Tick();
    });
}

void Mosaic::Tick() {
    if (steps_ >= totalSteps_) {
        if (timerId_) { KillTimer(nullptr, timerId_); timerId_ = 0; }
        steps_ = 0;
        return;
    }
    steps_++;
    double t = (double)steps_ / totalSteps_;
    double e = Smoothstep(t);
    for (auto& w : wins_) {
        RECT r;
        r.left   = (LONG)Lerp(w.start.left,   w.target.left,   e);
        r.top    = (LONG)Lerp(w.start.top,    w.target.top,    e);
        r.right  = (LONG)Lerp(w.start.right,  w.target.right,  e);
        r.bottom = (LONG)Lerp(w.start.bottom, w.target.bottom, e);
        SetWindowPos(w.hwnd, nullptr, r.left, r.top,
                     r.right - r.left, r.bottom - r.top,
                     SWP_NOZORDER | SWP_NOACTIVATE);
    }
}

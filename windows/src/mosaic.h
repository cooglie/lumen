// mosaic.h — Mosaic Fenster-Choreografie (Win32)
#pragma once
#include <windows.h>
#include <vector>
#include <string>

enum class Layout { Grid, Spiral, Fan, Cascade, Orbit };

struct TargetWin {
    HWND hwnd;
    RECT start;
    RECT target;
};

// Führt animierte Fenster-Choreografien via EnumWindows/SetWindowPos aus.
class Mosaic {
public:
    Mosaic();
    ~Mosaic();

    void Perform(Layout layout);

    // Animations-Step (vom Message-Loop per Timer aufgerufen).
    void Tick();

    bool IsAnimating() const { return steps_ > 0; }

private:
    void ComputeTargets(Layout layout);
    static BOOL CALLBACK EnumProc(HWND hwnd, LPARAM lParam);

    std::vector<TargetWin> wins_;
    int   steps_ = 0;
    int   totalSteps_ = 30;
    UINT_PTR timerId_ = 0;
    Layout layout_ = Layout::Grid;
};

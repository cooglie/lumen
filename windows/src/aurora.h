// aurora.h — Aurora Shader-Engine (DirectX 11)
#pragma once
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <d3d11.h>
#include <string>
#include <vector>

struct ShaderEntry {
    std::wstring name;        // Anzeigename
    std::string file;         // Dateiname in shaders/
};

// Rendert animierte HLSL-Shader als klick-durchlässiges Desktop-Overlay.
class AuroraRenderer {
public:
    AuroraRenderer();
    ~AuroraRenderer();

    bool Init();                       // Device + Swapchain + Overlay-Window anlegen
    void Shutdown();

    void Start();
    void Stop();
    void Toggle();
    bool IsRunning() const { return running_; }

    // Render einen Frame (vom Message-Loop per Timer aufgerufen).
    void RenderFrame();

    // Shader wechseln (liefert false, wenn Kompilierung scheitert).
    bool SelectShader(const std::string& file);
    const std::vector<ShaderEntry>& Shaders() const { return shaders_; }
    int ActiveShaderIndex() const { return activeIndex_; }

private:
    bool CreateOverlayWindow();
    bool CreateDeviceAndSwapChain();
    bool BuildPipeline(const std::string& file);
    void ReleasePipeline();

    static LRESULT CALLBACK WndProcThunk(HWND, UINT, WPARAM, LPARAM);

    HWND                 hwnd_ = nullptr;
    ID3D11Device*        device_ = nullptr;
    ID3D11DeviceContext* ctx_ = nullptr;
    IDXGISwapChain*      swap_ = nullptr;
    ID3D11RenderTargetView* rtv_ = nullptr;
    ID3D11VertexShader*  vs_ = nullptr;
    ID3D11PixelShader*   ps_ = nullptr;
    ID3D11Buffer*        timeCB_ = nullptr;

    std::vector<ShaderEntry> shaders_;
    int  activeIndex_ = 0;
    bool running_ = false;
    double startTime_ = 0.0;
};
